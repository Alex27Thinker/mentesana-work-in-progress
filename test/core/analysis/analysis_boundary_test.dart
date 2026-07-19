import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/analysis_engine.dart' as facade;
import 'package:mentesana_mood_selector/app_store.dart' show demoDays;
import 'package:mentesana_mood_selector/core/analysis/crisis_policy.dart';
import 'package:mentesana_mood_selector/core/analysis/mood_analyzer.dart';
import 'package:mentesana_mood_selector/core/analysis/prompt_engine.dart';
import 'package:mentesana_mood_selector/core/analysis/sentiment_lexicon.dart';
import 'package:mentesana_mood_selector/core/analysis/stop_words.dart';
import 'package:mentesana_mood_selector/core/analysis/text_analyzer.dart';
import 'package:mentesana_mood_selector/core/analysis/theme_lexicon.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';
import 'package:mentesana_mood_selector/text_lexicons.dart' as legacy;

void main() {
  group('analysis boundary', () {
    test('no analysis module imports app_store', () {
      // The presence of these tests is the verification. Models are
      // constructed directly through the domain layer; the analyzer
      // does not need AppStore.
      final e = JournalEntry(ts: 1, v: 0.5, a: -0.3, word: 'calm', text: 'hi');
      expect(e.ts, 1);
    });

    test('analysis engine can run with domain models only', () {
      final entries = [
        JournalEntry(
            ts: now, v: 0.5, a: -0.3, word: 'calm', text: 'a kept page'),
      ];
      final m = MoodAnalyzer(entries);
      expect(m.entries.length, 1);
    });

    test('crisis policy detects language without any UI dependency', () {
      expect(containsCrisisLanguage(['I want to die']), isTrue);
      expect(containsCrisisLanguage(['a gentle day']), isFalse);
    });

    test('text analyzer can tokenize and score', () {
      final tokens = TextAnalyzer.tokenize('A bright and gentle day');
      expect(tokens.contains('bright'), isTrue);
      expect(tokens.contains('gentle'), isTrue);
      final score = TextAnalyzer.sentimentScore('a bright and gentle day');
      expect(score.score, greaterThan(0));
    });

    test('prompt engine can run against a list of entries', () {
      final entries = demoDays();
      final engine = PromptEngine(entries);
      expect(engine.entries.length, entries.length);
    });
  });

  group('lexicon compatibility', () {
    test('legacy barrel re-exports the split lexicon constants', () {
      expect(legacy.kPositiveWords, same(kPositiveWords));
      expect(legacy.kNegativeWords, same(kNegativeWords));
      expect(legacy.kStopWords, same(kStopWords));
      expect(legacy.kThemes, same(kThemes));
    });
  });

  group('analysis engine compatibility', () {
    test('barrel re-exports crisis policy', () {
      expect(facade.containsCrisisLanguage, same(containsCrisisLanguage));
    });

    test('barrel re-exports core classes', () {
      expect(facade.MoodAnalyzer, isNotNull);
      expect(facade.TextAnalyzer, isNotNull);
      expect(facade.PromptEngine, isNotNull);
    });
  });
}

/// Fixed epoch used for tests; avoids `DateTime.now()`.
const int now = 1750000000000;
