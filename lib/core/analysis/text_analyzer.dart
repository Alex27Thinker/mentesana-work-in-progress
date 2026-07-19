// Mentesana — lightweight on-device NLP (TextAnalyzer).
// No external APIs. Uses a sentiment lexicon, stop-word filtering,
// keyword extraction, and simple theme clustering.

import '../../features/journal/domain/models.dart';
import 'analysis_models.dart';
import 'sentiment_lexicon.dart';
import 'stop_words.dart';
import 'theme_lexicon.dart';

class TextAnalyzer {
  const TextAnalyzer(this.entries);
  final List<JournalEntry> entries;

  /// Tokenize text into lowercase words, stripped of punctuation.
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
    if (withText.isEmpty) return TextAnalysis(hasData: false, count: 0);
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
