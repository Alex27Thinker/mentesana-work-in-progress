// Mentesana — the local Analysis Engine.
// 1:1 port of MoodAnalyzer, TextAnalyzer and PromptEngine from the Vite
// prototype (src/main.js). No external APIs — everything runs on device.
//
// Strings keep the prototype's `<em>…</em>` markers; screens render them
// with a small parser (see richText in insight_screen.dart). The web app
// escaped HTML at this boundary — Flutter text widgets need no escaping.

import 'dart:math' as math;

import 'app_store.dart';
import 'currents_engine.dart';
import 'text_lexicons.dart';

/// Month labels local to this file (kept here so the engine has no UI deps).
const _kMonthsShortAE = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

/// Canonical on-device crisis phrase detector, shared by every surface
/// (journal editor, weekly insight, and the AI post-check) so screening is
/// consistent and never depends on the AI layer being reachable. Broadened
/// from the prototype's original short list.
final kCrisisRe = RegExp(
  r"\b(kill(ing)? myself|suicide|suicidal|self[- ]?harm|hurt myself|harm myself|end my life|end it all|want to die|wanna die|better off dead|no reason to (live|go on)|can'?t go on|don'?t want to (be here|live|wake up)|give up on everything|nothing left for me)\b",
  caseSensitive: false,
);

/// True when any of the given texts contains crisis language.
bool containsCrisisLanguage(Iterable<String> texts) =>
    texts.any((t) => t.isNotEmpty && kCrisisRe.hasMatch(t));

/// A month-level aggregate — a "season" the weekly letter can compare across
/// time, so month six reads deeper than week two instead of identically.
class SeasonSummary {
  const SeasonSummary({
    required this.year,
    required this.month,
    required this.entryCount,
    this.dominantQuadrant,
    this.topTheme,
    this.avgSentiment = 0,
    this.topWord,
  });

  final int year;
  final int month; // 1-12
  final int entryCount;
  final String? dominantQuadrant;
  final String? topTheme;
  final double avgSentiment;
  final String? topWord;

  String get label => '${_kMonthsShortAE[month - 1]} $year';
}

// ---------- shared result shapes ----------

class WordCount {
  const WordCount(this.word, this.count);
  final String word;
  final int count;
}

class ThemeHits {
  const ThemeHits(this.theme, this.hits, this.weight);
  final String theme;
  final int hits;
  final double weight;
}

class MoodTrajectory {
  const MoodTrajectory(this.vDir, this.aDir, this.description);
  final double vDir;
  final double aDir;
  final String description;
}

class MoodShift {
  const MoodShift(this.vShift, this.aShift, this.description);
  final double vShift;
  final double aShift;
  final String description;
}

class TimePattern {
  const TimePattern(this.slots, this.dominant);
  final Map<String, int> slots;
  final String? dominant;
}

class MoodAnalysis {
  const MoodAnalysis({
    required this.hasData,
    required this.count,
    this.totalEntries = 0,
    required this.days,
    this.avgV = 0,
    this.avgA = 0,
    this.volatility = 0,
    this.quadrantDistribution = const {},
    this.dominantQuadrant,
    this.trajectory,
    this.frequentWords = const [],
    this.timePattern,
    this.shift,
  });

  final bool hasData;
  final int count;
  final int totalEntries;
  final int days;
  final double avgV;
  final double avgA;
  final double volatility;
  final Map<String, double> quadrantDistribution;
  final String? dominantQuadrant;
  final MoodTrajectory? trajectory;
  final List<WordCount> frequentWords;
  final TimePattern? timePattern;
  final MoodShift? shift;
}

class Sentiment {
  const Sentiment(
      this.score, this.positive, this.negative, this.total, this.label);
  final double score;
  final int positive;
  final int negative;
  final int total;
  final String label;
}

class TextEntryAnalysis {
  const TextEntryAnalysis(
      this.keywords, this.sentiment, this.themes, this.wordCount);
  final List<WordCount> keywords;
  final Sentiment sentiment;
  final List<ThemeHits> themes;
  final int wordCount;
}

class TextAnalysis {
  const TextAnalysis({
    required this.hasData,
    required this.count,
    this.totalWords = 0,
    this.avgWordsPerEntry = 0,
    this.topKeywords = const [],
    this.topThemes = const [],
    this.avgSentiment = 0,
    this.sentimentLabel = 'mixed',
  });

  final bool hasData;
  final int count;
  final int totalWords;
  final int avgWordsPerEntry;
  final List<WordCount> topKeywords;
  final List<ThemeHits> topThemes;
  final double avgSentiment;
  final String sentimentLabel;
}

/// The weekly-insight shape (JS `parts`), plus the AI crisis extension.
class InsightParts {
  InsightParts({
    this.headline = '',
    this.count = '',
    List<String>? patterns,
    this.question = '',
    this.thin = false,
    this.crisis = false,
    this.crisisMessage,
    this.fromAI = false,
  }) : patterns = patterns ?? [];

  String headline;
  String count;
  List<String> patterns;
  String question;
  bool thin;
  bool crisis;
  String? crisisMessage;
  bool fromAI;
}

/// Stable sort (JS Array.sort is stable; Dart's List.sort is not).
List<T> stableSortedByDesc<T>(Iterable<T> items, num Function(T) key) {
  final indexed = items.toList().asMap().entries.toList()
    ..sort((a, b) {
      final c = key(b.value).compareTo(key(a.value));
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return indexed.map((e) => e.value).toList();
}

class _MaPoint {
  const _MaPoint(this.ts, this.avgV, this.avgA);
  final int ts;
  final double avgV;
  final double avgA;
}

// ───────────────────────────────────────────────────────────────
// MoodAnalyzer: statistical analysis of mood check-ins
// ───────────────────────────────────────────────────────────────
class MoodAnalyzer {
  const MoodAnalyzer(this.entries);
  final List<JournalEntry> entries;

  /// Quadrant labels for internal use (never shown as labels to the user).
  static String quadrantOf(double v, double a) {
    if (v >= 0 && a >= 0) return 'pleasant-activated';
    if (v >= 0 && a < 0) return 'pleasant-calm';
    if (v < 0 && a >= 0) return 'unpleasant-activated';
    return 'unpleasant-calm';
  }

  /// All mood entries (real entries only, not demo data), oldest first.
  List<JournalEntry> moodEntries() {
    final list = entries.where((e) => e.isMoodEntry).toList()
      ..sort((a, b) => a.ts.compareTo(b.ts));
    return list;
  }

  /// Entries within a time window (default: last 7 days).
  List<JournalEntry> recentMood([int days = 7]) {
    final cutoff =
        DateTime.now().millisecondsSinceEpoch - days * 24 * 60 * 60 * 1000;
    return moodEntries().where((e) => e.ts >= cutoff).toList();
  }

  /// Moving average of valence and arousal over a window.
  static List<_MaPoint> _movingAverage(List<JournalEntry> data,
      [int windowSize = 3]) {
    if (data.isEmpty) return [];
    final result = <_MaPoint>[];
    for (var i = 0; i < data.length; i++) {
      final start = math.max(0, i - windowSize + 1);
      final slice = data.sublist(start, i + 1);
      final avgV = slice.fold<double>(0, (s, e) => s + e.v!) / slice.length;
      final avgA = slice.fold<double>(0, (s, e) => s + e.a!) / slice.length;
      result.add(_MaPoint(data[i].ts, avgV, avgA));
    }
    return result;
  }

  /// Volatility: average distance between consecutive mood points.
  static double volatilityOf(List<JournalEntry> data) {
    if (data.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < data.length; i++) {
      total += math.sqrt(math.pow(data[i].v! - data[i - 1].v!, 2) +
          math.pow(data[i].a! - data[i - 1].a!, 2));
    }
    return total / (data.length - 1);
  }

  /// Quadrant distribution: proportion of entries in each quadrant.
  static Map<String, double> quadrantDistribution(List<JournalEntry> data) {
    final dist = <String, double>{
      'pleasant-activated': 0,
      'pleasant-calm': 0,
      'unpleasant-activated': 0,
      'unpleasant-calm': 0,
    };
    if (data.isEmpty) return dist;
    for (final e in data) {
      final q = quadrantOf(e.v!, e.a!);
      dist[q] = dist[q]! + 1;
    }
    for (final k in dist.keys) {
      dist[k] = dist[k]! / data.length;
    }
    return dist;
  }

  /// Dominant quadrant (the one with the most entries).
  static String? dominantQuadrant(List<JournalEntry> data) {
    final dist = quadrantDistribution(data);
    var max = 0.0;
    String? dom;
    for (final k in dist.keys) {
      if (dist[k]! > max) {
        max = dist[k]!;
        dom = k;
      }
    }
    return dom;
  }

  /// Trajectory: is the mood trending in a direction?
  static MoodTrajectory trajectoryOf(List<JournalEntry> data) {
    if (data.length < 3) {
      return const MoodTrajectory(
          0, 0, 'not enough weather to read a direction yet');
    }
    final ma = _movingAverage(data, math.min(3, (data.length / 2).ceil()));
    final first = ma.first, last = ma.last;
    final vDir = last.avgV - first.avgV;
    final aDir = last.avgA - first.avgA;
    var desc = '';
    const threshold = 0.25;
    if (vDir > threshold && aDir > threshold) {
      desc = 'moving toward brighter, more awake weather';
    } else if (vDir > threshold && aDir < -threshold) {
      desc = 'moving toward calmer, gentler weather';
    } else if (vDir < -threshold && aDir > threshold) {
      desc = 'moving toward heavier, more turbulent weather';
    } else if (vDir < -threshold && aDir < -threshold) {
      desc = 'moving toward quieter, lower weather';
    } else if (vDir > threshold) {
      desc = 'a gentle lift in valence';
    } else if (vDir < -threshold) {
      desc = 'a gentle dip in valence';
    } else if (aDir > threshold) {
      desc = 'slightly more activated';
    } else if (aDir < -threshold) {
      desc = 'slightly calmer';
    } else {
      desc = 'the weather has been holding steady';
    }
    return MoodTrajectory(vDir, aDir, desc);
  }

  /// Most frequent mood words.
  static List<WordCount> frequentWordsOf(List<JournalEntry> data,
      [int topN = 3]) {
    final counts = <String, int>{};
    for (final e in data) {
      final w = e.word;
      if (w != null && w.isNotEmpty) counts[w] = (counts[w] ?? 0) + 1;
    }
    final sorted = stableSortedByDesc(counts.entries, (e) => e.value);
    return sorted.take(topN).map((e) => WordCount(e.key, e.value)).toList();
  }

  /// Time-of-day pattern: when does the user most often check in?
  static TimePattern timeOfDayPattern(List<JournalEntry> data) {
    final slots = <String, int>{
      'morning': 0,
      'afternoon': 0,
      'evening': 0,
      'night': 0,
    };
    for (final e in data) {
      final h = e.date.hour;
      if (h < 6) {
        slots['night'] = slots['night']! + 1;
      } else if (h < 12) {
        slots['morning'] = slots['morning']! + 1;
      } else if (h < 18) {
        slots['afternoon'] = slots['afternoon']! + 1;
      } else {
        slots['evening'] = slots['evening']! + 1;
      }
    }
    var max = 0;
    String? dom;
    for (final k in slots.keys) {
      if (slots[k]! > max) {
        max = slots[k]!;
        dom = k;
      }
    }
    return TimePattern(slots, dom);
  }

  /// Full analysis summary.
  MoodAnalysis analyze([int days = 7]) {
    final all = moodEntries();
    final recent = recentMood(days);
    if (recent.isEmpty) {
      return MoodAnalysis(hasData: false, count: 0, days: days);
    }
    final ma = _movingAverage(recent);
    final vol = volatilityOf(recent);
    final dist = quadrantDistribution(recent);
    final dom = dominantQuadrant(recent);
    final traj = trajectoryOf(recent);
    final words = frequentWordsOf(recent);
    final timePattern = timeOfDayPattern(recent);
    // Shift detection: compare last 3 entries vs the 3 before that.
    MoodShift? shift;
    if (recent.length >= 6) {
      final recent3 = recent.sublist(recent.length - 3);
      final prior3 = recent.sublist(recent.length - 6, recent.length - 3);
      final rAvgV = recent3.fold<double>(0, (s, e) => s + e.v!) / 3;
      final pAvgV = prior3.fold<double>(0, (s, e) => s + e.v!) / 3;
      final rAvgA = recent3.fold<double>(0, (s, e) => s + e.a!) / 3;
      final pAvgA = prior3.fold<double>(0, (s, e) => s + e.a!) / 3;
      final vShift = rAvgV - pAvgV, aShift = rAvgA - pAvgA;
      if (vShift.abs() > 0.3 || aShift.abs() > 0.3) {
        shift = MoodShift(
            vShift,
            aShift,
            vShift > 0.3
                ? 'the weather has been brighter in the last few check-ins'
                : vShift < -0.3
                    ? 'the weather has been heavier in the last few check-ins'
                    : aShift > 0.3
                        ? 'things have felt more activated recently'
                        : 'things have felt calmer recently');
      }
    }
    return MoodAnalysis(
      hasData: true,
      count: recent.length,
      totalEntries: all.length,
      days: days,
      avgV: ma.isNotEmpty ? ma.last.avgV : 0,
      avgA: ma.isNotEmpty ? ma.last.avgA : 0,
      volatility: vol,
      quadrantDistribution: dist,
      dominantQuadrant: dom,
      trajectory: traj,
      frequentWords: words,
      timePattern: timePattern,
      shift: shift,
    );
  }
}

// ───────────────────────────────────────────────────────────────
// TextAnalyzer: lightweight on-device NLP
// No external APIs. Uses a sentiment lexicon, stop-word filtering,
// keyword extraction, and simple theme clustering.
// ───────────────────────────────────────────────────────────────
class TextAnalyzer {
  const TextAnalyzer(this.entries);
  final List<JournalEntry> entries;

  /// Tokenize text into lowercase words, stripped of punctuation.
  /// JS: `text.toLowerCase().replace(/[^\w\s']/g, ' ').split(/\s+/)`.
  static List<String> tokenize(String? text) {
    return (text ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// Extract keywords: frequent words that aren't stop words or too short.
  static List<WordCount> extractKeywords(String? text, [int topN = 8]) {
    final tokens = tokenize(text);
    if (tokens.isEmpty) return [];
    final counts = <String, int>{};
    for (final w in tokens) {
      if (w.length < 3 || kStopWords.contains(w)) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final sorted = stableSortedByDesc(
        counts.entries.where((e) => e.value >= 1), (e) => e.value);
    return sorted.take(topN).map((e) => WordCount(e.key, e.value)).toList();
  }

  /// Sentiment score: ratio of positive to negative words.
  static Sentiment sentimentScore(String? text) {
    final tokens = tokenize(text);
    if (tokens.isEmpty) return const Sentiment(0, 0, 0, 0, 'neutral');
    var pos = 0, neg = 0;
    for (final w in tokens) {
      if (kPositiveWords.contains(w)) pos++;
      if (kNegativeWords.contains(w)) neg++;
    }
    final total = pos + neg;
    final score = total == 0 ? 0.0 : (pos - neg) / total;
    var label = 'neutral';
    if (score > 0.3) {
      label = 'warm';
    } else if (score > 0.1) {
      label = 'gentle';
    } else if (score < -0.3) {
      label = 'heavy';
    } else if (score < -0.1) {
      label = 'clouded';
    }
    return Sentiment(score, pos, neg, total, label);
  }

  /// Detect themes: which theme categories appear most in the text.
  static List<ThemeHits> detectThemes(String? text) {
    final tokens = tokenize(text).toSet();
    if (tokens.isEmpty) return [];
    final results = <ThemeHits>[];
    for (final entry in kThemes.entries) {
      var hits = 0;
      for (final w in entry.value) {
        if (tokens.contains(w)) hits++;
      }
      if (hits > 0) {
        results.add(ThemeHits(entry.key, hits, hits / entry.value.length));
      }
    }
    return stableSortedByDesc(results, (t) => t.hits);
  }

  /// Analyze a single journal entry's text.
  static TextEntryAnalysis analyzeText(String? text) {
    return TextEntryAnalysis(
      extractKeywords(text),
      sentimentScore(text),
      detectThemes(text),
      tokenize(text).length,
    );
  }

  /// Analyze all journal entries with text within a time window.
  TextAnalysis analyzeEntries([int days = 7]) {
    final cutoff =
        DateTime.now().millisecondsSinceEpoch - days * 24 * 60 * 60 * 1000;
    final withText = entries
        .where(
            (e) => e.text.trim().length > 10 && (days == 0 || e.ts >= cutoff))
        .toList();
    if (withText.isEmpty) return const TextAnalysis(hasData: false, count: 0);
    final allKeywords = <String, int>{};
    final allThemes = <String, int>{};
    var totalSentiment = 0.0;
    var sentimentCount = 0;
    var totalWords = 0;
    for (final e in withText) {
      final a = analyzeText(e.text);
      totalWords += a.wordCount;
      if (a.sentiment.total > 0) {
        totalSentiment += a.sentiment.score;
        sentimentCount++;
      }
      for (final kw in a.keywords) {
        allKeywords[kw.word] = (allKeywords[kw.word] ?? 0) + kw.count;
      }
      for (final th in a.themes) {
        allThemes[th.theme] = (allThemes[th.theme] ?? 0) + th.hits;
      }
    }
    final topKeywords = stableSortedByDesc(allKeywords.entries, (e) => e.value)
        .take(10)
        .map((e) => WordCount(e.key, e.value))
        .toList();
    final topThemes = stableSortedByDesc(allThemes.entries, (e) => e.value)
        .take(5)
        .map((e) => ThemeHits(e.key, e.value, 0))
        .toList();
    final avgSentiment =
        sentimentCount > 0 ? totalSentiment / sentimentCount : 0.0;
    return TextAnalysis(
      hasData: true,
      count: withText.length,
      totalWords: totalWords,
      avgWordsPerEntry: (totalWords / withText.length).round(),
      topKeywords: topKeywords,
      topThemes: topThemes,
      avgSentiment: avgSentiment,
      sentimentLabel: avgSentiment > 0.2
          ? 'warm'
          : avgSentiment < -0.2
              ? 'heavy'
              : 'mixed',
    );
  }
}

// ───────────────────────────────────────────────────────────────
// PromptEngine: context-aware prompts from mood + text analysis.
// Composes gentle, non-diagnostic invitations to write.
// ───────────────────────────────────────────────────────────────
class PromptEngine {
  const PromptEngine(this.entries);
  final List<JournalEntry> entries;

  /// Context-aware daily prompts drawing from mood patterns, journal themes,
  /// and temporal context. All output is gentle invitation.
  List<String> generateContextPrompts() {
    final mood = MoodAnalyzer(entries).analyze();
    final text = TextAnalyzer(entries).analyzeEntries();
    final prompts = <String>[];

    // 1. Mood-aware prompts (from recent mood patterns)
    if (mood.hasData && mood.count >= 2) {
      final traj = mood.trajectory!;
      if (traj.vDir > 0.3) {
        prompts.add(
            'Something has been lifting in the weather. What would you like to keep close from this?');
      } else if (traj.vDir < -0.3) {
        prompts.add(
            'The weather has been heavier lately. What would help you feel held right now?');
      }
      if (mood.shift != null) {
        prompts.add(
            'Things have shifted in the last few check-ins. What does the shift feel like from inside it?');
      }
      if (mood.volatility > 0.5) {
        prompts.add(
            'The weather has been moving quickly. What would it be like to sit with it for a moment?');
      }
      if (mood.frequentWords.isNotEmpty && mood.frequentWords[0].count >= 2) {
        prompts.add(
            'You have called the weather <em>${mood.frequentWords[0].word}</em> a few times. What does that word know that you do not?');
      }
      // Time-of-day awareness
      if (mood.timePattern?.dominant == 'evening' && mood.count >= 3) {
        prompts.add(
            'You have been arriving here in the evenings. What is it like to land here at this hour?');
      } else if (mood.timePattern?.dominant == 'morning' && mood.count >= 3) {
        prompts.add(
            'Mornings have been your time. What would you like to set down before the day begins?');
      }
    }

    // 2. Text-aware prompts (from journal content analysis)
    if (text.hasData && text.count >= 1) {
      // Theme-aware prompts
      if (text.topThemes.isNotEmpty) {
        final topTheme = text.topThemes[0].theme;
        const themePrompts = {
          'work':
              'Work has been present in your pages. What part of it is still with you, even now?',
          'relationships':
              'People have been in your pages. What connection would you like to name?',
          'body':
              'Your body has been in your pages. What does it need right now?',
          'nature':
              'The outside has been in your pages. What would it be like to step back into it?',
          'creativity':
              'Making things has been in your pages. What is asking to be created?',
          'self':
              'You have been writing about yourself. What would you like to tell the you from a few days ago?',
        };
        final p = themePrompts[topTheme];
        if (p != null) prompts.add(p);
      }
      // Keyword-aware prompts
      if (text.topKeywords.length >= 2) {
        final kw1 = text.topKeywords[0].word;
        final kw2 = text.topKeywords[1].word;
        if (kw1 != kw2) {
          prompts.add(
              '<em>$kw1</em> and <em>$kw2</em> have been in your pages. What connects them?');
        }
      }
      // Sentiment-aware prompts
      if (text.avgSentiment < -0.2 && text.count >= 2) {
        prompts.add(
            'Your pages have been carrying something heavy. What would it be like to set part of it down?');
      } else if (text.avgSentiment > 0.2 && text.count >= 2) {
        prompts.add(
            'Your pages have been warm lately. What would you like to remember about this?');
      }
    }

    // 3. Cross-domain prompts (mood + text interaction)
    if (mood.hasData && text.hasData) {
      // Mood-text dissonance: mood says one thing, text says another
      final moodV = mood.avgV;
      final textSent = text.avgSentiment;
      if (moodV > 0.3 && textSent < -0.2) {
        prompts.add(
            'The weather has been bright, but your pages carry something else. What would it be like to let both be true?');
      } else if (moodV < -0.3 && textSent > 0.2) {
        prompts.add(
            'The weather has been heavy, but your pages have been warm. What is keeping you held?');
      }
    }

    return prompts;
  }

  /// A richer weekly insight using both mood and text analysis.
  InsightParts generateWeeklyInsight(
      {TideExperiment? experiment, Anchor? anchor}) {
    final mood = MoodAnalyzer(entries).analyze();
    final text = TextAnalyzer(entries).analyzeEntries();
    final parts = InsightParts();

    if (!mood.hasData && !text.hasData) {
      parts.thin = true;
      parts.headline = 'What the water held this week';
      return parts;
    }

    final written = text.hasData ? text.count : 0;
    final moodCount = mood.hasData ? mood.count : 0;
    parts.count =
        '$moodCount check-in${moodCount == 1 ? '' : 's'} this week; $written became a page.';

    // Mood patterns
    if (mood.hasData) {
      if (mood.frequentWords.isNotEmpty && mood.frequentWords[0].count >= 2) {
        parts.patterns.add(
            'The word <em>${mood.frequentWords[0].word}</em> returned more than once. It may be worth sitting with, not solving.');
        parts.headline = 'A week with ${mood.frequentWords[0].word} in it';
      }
      if (mood.trajectory != null && mood.trajectory!.vDir != 0) {
        final d = mood.trajectory!.description;
        parts.patterns.add('${d[0].toUpperCase()}${d.substring(1)}.');
      }
      if (mood.shift != null) {
        final d = mood.shift!.description;
        parts.patterns.add('${d[0].toUpperCase()}${d.substring(1)}.');
      }
      if (mood.volatility > 0.5 && mood.count >= 4) {
        parts.patterns.add(
            'The weather has been moving quickly this week — many states in a short time.');
      }
    }

    // Text patterns
    if (text.hasData) {
      if (text.topThemes.isNotEmpty) {
        const themeNames = {
          'work': 'work and study',
          'relationships': 'people and connection',
          'body': 'the body',
          'nature': 'the outside world',
          'creativity': 'making things',
          'self': 'yourself',
        };
        final themeName =
            themeNames[text.topThemes[0].theme] ?? text.topThemes[0].theme;
        parts.patterns.add(
            'Your pages kept returning to <em>$themeName</em>. Not proof of a cause — simply something you may want to keep near.');
        if (parts.headline.isEmpty) {
          parts.headline = 'A week with $themeName in it';
        }
      }
      if (text.topKeywords.length >= 2) {
        final kwStr = text.topKeywords.take(3).map((k) => k.word).join(', ');
        parts.patterns.add(
            'The words <em>$kwStr</em> appeared across your pages. They may be worth holding.');
      }
      if (text.avgSentiment < -0.2 && text.count >= 2) {
        parts.patterns.add(
            'Your pages have been carrying something heavy. That is worth noticing — not fixing.');
      } else if (text.avgSentiment > 0.2 && text.count >= 2) {
        parts.patterns.add(
            'Your pages have been warm. Something has been holding you well.');
      }
    }

    // Cross-domain: mood-text interaction
    if (mood.hasData && text.hasData) {
      final moodV = mood.avgV;
      final textSent = text.avgSentiment;
      if (moodV > 0.3 && textSent < -0.2) {
        parts.patterns.add(
            'The weather has been bright, but your pages carry something heavier. Both can be true at once.');
      } else if (moodV < -0.3 && textSent > 0.2) {
        parts.patterns.add(
            'The weather has been heavy, but your pages have been warm. Something has been keeping you held.');
      }
    }

    // Point back to a specific earlier page when this week echoes it, so the
    // letter names a season returning rather than staying abstract.
    final echoWord = mood.hasData && mood.frequentWords.isNotEmpty
        ? mood.frequentWords.first.word
        : null;
    final echoTheme = text.hasData && text.topThemes.isNotEmpty
        ? text.topThemes.first.theme
        : null;
    final echo = findEcho(word: echoWord, theme: echoTheme);
    if (echo != null) {
      final d = echo.date;
      parts.patterns.add(
          'This is not the first time — a page from <em>${_kMonthsShortAE[d.month - 1]} ${d.day}</em> held something close to this. It may be a season returning, not only a day.');
    }

    // Close the loop: if a small experiment is underway, let the letter look
    // back at it — as observation, never a verdict, count, or score.
    if (experiment != null) {
      if (experiment.observations.isNotEmpty) {
        parts.patterns.add(
            'You have been trying <em>${experiment.action}</em>. On the days it found you, these pages simply held what the weather was like around it.');
      } else {
        parts.patterns.add(
            'You set out to try <em>${experiment.action}</em>. Whenever it happens, there is nothing to measure — only what the day feels like near it.');
      }
    }

    // The almanac line — one leading pattern from the user's own longer
    // record, so the letter can look further back than a single week.
    final almanac = almanacRead(entries);
    if (almanac.leading != null) {
      parts.patterns.add(
          'Your almanac, for what it is worth: ${almanac.leading!.text} Your pattern, not a rule.');
    }

    // Anchors — close the loop as observation, never a verdict.
    if (anchor != null) {
      final weekAgoAnchor =
          DateTime.now().millisecondsSinceEpoch - 7 * 24 * 60 * 60 * 1000;
      if (anchor.reflectedAt != null && anchor.reflectedAt! >= weekAgoAnchor) {
        parts.patterns.add(anchor.outcome == 'passed'
            ? 'An anchor — <em>${anchor.text}</em> — came and went without happening. The sea does not count; it only keeps.'
            : 'You set a small anchor — <em>${anchor.text}</em> — and gave it a few lines afterwards. Loops closed this gently tend to hold.');
      } else if (anchor.reflectedAt == null) {
        parts.patterns.add(
            'A small anchor is still out — <em>${anchor.text}</em>. Whenever it happens is soon enough.');
      }
    }

    // Thin evidence check — count unique entries, not mood+text separately
    final uniqueEntries = <int>{};
    final cutoff7 =
        DateTime.now().millisecondsSinceEpoch - 7 * 24 * 60 * 60 * 1000;
    for (final e in entries) {
      if (e.ts >= cutoff7) uniqueEntries.add(e.ts);
    }
    if (uniqueEntries.length < 3) {
      parts.thin = true;
      parts.headline = 'Not enough weather for a pattern yet';
    }

    // Question
    if (text.hasData && text.topThemes.isNotEmpty) {
      const questions = {
        'work': 'When work comes up again, what would you like to remember?',
        'relationships':
            'When someone comes to mind again, what would you like to say?',
        'body': 'What does your body know that your mind has not named yet?',
        'nature':
            'What would it be like to step outside and let the weather be the weather?',
        'creativity': 'What is asking to be made, even if it is small?',
        'self': 'What would you tell the you from a few days ago?',
      };
      parts.question = questions[text.topThemes[0].theme] ??
          'What is one small thing you would like to carry into next week?';
    } else {
      parts.question =
          'What is one small thing you would like to carry into next week?';
    }

    if (parts.headline.isEmpty) {
      parts.headline = 'What the water held this week';
    }
    return parts;
  }

  /// Deep-analysis summary (last 30 days) for the patterns view.
  (MoodAnalysis, TextAnalysis) generateDeepAnalysis() {
    return (
      MoodAnalyzer(entries).analyze(30),
      TextAnalyzer(entries).analyzeEntries(30),
    );
  }

  /// Month-level history so the weekly letter can reference seasons across
  /// months, not only a rolling window. Newest month last.
  List<SeasonSummary> generateSeasons({int maxMonths = 12}) {
    final byMonth = <String, List<JournalEntry>>{};
    for (final e in entries) {
      final d = e.date;
      (byMonth['${d.year}-${d.month}'] ??= []).add(e);
    }
    final summaries = <SeasonSummary>[];
    for (final group in byMonth.values) {
      final d = group.first.date;
      final moods = group.where((e) => e.isMoodEntry).toList();
      final text = TextAnalyzer(group).analyzeEntries(0);
      final words = MoodAnalyzer.frequentWordsOf(moods);
      summaries.add(SeasonSummary(
        year: d.year,
        month: d.month,
        entryCount: group.length,
        dominantQuadrant:
            moods.isNotEmpty ? MoodAnalyzer.dominantQuadrant(moods) : null,
        topTheme: text.hasData && text.topThemes.isNotEmpty
            ? text.topThemes.first.theme
            : null,
        avgSentiment: text.hasData ? text.avgSentiment : 0,
        topWord: words.isNotEmpty ? words.first.word : null,
      ));
    }
    summaries.sort(
        (a, b) => (a.year * 12 + a.month).compareTo(b.year * 12 + b.month));
    return summaries.length > maxMonths
        ? summaries.sublist(summaries.length - maxMonths)
        : summaries;
  }

  /// Finds a specific earlier page (older than the current week) that echoes
  /// the given word or theme, so the letter can point back to it by date.
  JournalEntry? findEcho({String? word, String? theme}) {
    final weekAgo =
        DateTime.now().millisecondsSinceEpoch - 7 * 24 * 60 * 60 * 1000;
    final older = entries.where((e) => e.ts < weekAgo).toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    for (final e in older) {
      if (word != null && word.isNotEmpty && e.word == word) return e;
      if (theme != null && theme.isNotEmpty && e.text.isNotEmpty) {
        if (TextAnalyzer.detectThemes(e.text).any((t) => t.theme == theme)) {
          return e;
        }
      }
    }
    return null;
  }

  /// A pre-filled small experiment drawn from the week's dominant theme — an
  /// invitation to gently try something, never a prescription. The user edits
  /// and confirms it; nothing begins on its own.
  TideExperiment? suggestExperiment() {
    // Evidence first: when the user's own record already points at something
    // that co-occurs with gentler water, seed the experiment from that
    // instead of a generic theme (behavioural activation, n-of-1).
    final mined = mineAnchors(entries);
    if (mined.isNotEmpty) {
      final m = mined.first;
      return TideExperiment(
        id: 'tide-${DateTime.now().millisecondsSinceEpoch}',
        title: 'a little more of ${m.label}',
        hypothesis:
            'Your own pages hint that ${m.label} sits near gentler water — ${m.days} days say so. This is only to notice, never to fix.',
        action: m.action,
        theme: m.theme,
        startedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
    final text = TextAnalyzer(entries).analyzeEntries();
    if (!text.hasData || text.topThemes.isEmpty) return null;
    final theme = text.topThemes.first.theme;
    const seeds = <String, List<String>>{
      'work': [
        'a small pause inside the workday',
        'stepping away for two quiet minutes when work gets loud',
      ],
      'relationships': [
        'reaching toward one person',
        'sending one small message to someone who came to mind',
      ],
      'body': [
        'listening to the body once a day',
        'a slow stretch or a short walk when you notice tension',
      ],
      'nature': [
        'a little time outside',
        'stepping outdoors for a few minutes when you can',
      ],
      'creativity': [
        'making one small thing',
        'a few unhurried minutes with something unfinished',
      ],
      'self': [
        'a gentler inner voice',
        'writing one kind line to yourself before the day closes',
      ],
    };
    final seed = seeds[theme];
    if (seed == null) return null;
    return TideExperiment(
      id: 'tide-${DateTime.now().millisecondsSinceEpoch}',
      title: seed[0],
      hypothesis:
          'Something around $theme has been present lately. This is a small thing to try — only to notice what the weather is like near it, not to fix anything.',
      action: seed[1],
      theme: theme,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
