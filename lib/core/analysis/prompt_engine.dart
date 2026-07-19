// Mentesana — context-aware prompts from mood + text analysis.
// Composes gentle, non-diagnostic invitations to write.

import '../../currents_engine.dart';
import '../../features/journal/domain/models.dart';
import 'analysis_models.dart';
import 'mood_analyzer.dart';
import 'text_analyzer.dart';

/// Finds a specific earlier page (older than the current week) that echoes
/// the given word or theme, so the letter can point back to it by date.
JournalEntry? findEcho(List<JournalEntry> entries,
    {String? word, String? theme}) {
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

    // Point back to a specific earlier page when this week echoes it
    final echoWord = mood.hasData && mood.frequentWords.isNotEmpty
        ? mood.frequentWords.first.word
        : null;
    final echoTheme = text.hasData && text.topThemes.isNotEmpty
        ? text.topThemes.first.theme
        : null;
    final echo = findEcho(entries, word: echoWord, theme: echoTheme);
    if (echo != null) {
      final d = echo.date;
      parts.patterns.add(
          'This is not the first time — a page from <em>${kMonthsShortAE[d.month - 1]} ${d.day}</em> held something close to this. It may be a season returning, not only a day.');
    }

    // Close the loop: if a small experiment is underway
    if (experiment != null) {
      if (experiment.observations.isNotEmpty) {
        parts.patterns.add(
            'You have been trying <em>${experiment.action}</em>. On the days it found you, these pages simply held what the weather was like around it.');
      } else {
        parts.patterns.add(
            'You set out to try <em>${experiment.action}</em>. Whenever it happens, there is nothing to measure — only what the day feels like near it.');
      }
    }

    // The almanac line
    final almanac = almanacRead(entries);
    if (almanac.leading != null) {
      parts.patterns.add(
          'Your almanac, for what it is worth: ${almanac.leading!.text} Your pattern, not a rule.');
    }

    // Anchors
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

    // Thin evidence check
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

  /// A pre-filled small experiment drawn from the week's dominant theme.
  TideExperiment? suggestExperiment() {
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
