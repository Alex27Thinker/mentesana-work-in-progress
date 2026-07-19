import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/analysis_engine.dart';
import 'package:mentesana_mood_selector/currents_engine.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import '../../../helpers/fixtures.dart';

void main() {
  final now = DateTime.now().millisecondsSinceEpoch;

  group('containsCrisisLanguage', () {
    test('detects explicit crisis phrases', () {
      expect(containsCrisisLanguage(['I want to kill myself']), isTrue);
      expect(containsCrisisLanguage(['feeling suicidal']), isTrue);
      expect(containsCrisisLanguage(['self-harm thoughts']), isTrue);
      expect(containsCrisisLanguage(['end my life']), isTrue);
      expect(containsCrisisLanguage(['better off dead']), isTrue);
    });

    test('returns false for safe text', () {
      expect(containsCrisisLanguage(['Today was tough but okay.']), isFalse);
      expect(containsCrisisLanguage(['I feel sad']), isFalse);
      expect(containsCrisisLanguage(['']), isFalse);
    });

    test('is case insensitive', () {
      expect(containsCrisisLanguage(['Kill Myself']), isTrue);
      expect(containsCrisisLanguage(['SUICIDAL']), isTrue);
    });
  });

  group('MoodAnalyzer', () {
    test('empty entries produce no-data analysis', () {
      final analyzer = MoodAnalyzer([]);
      final result = analyzer.analyze();
      expect(result.hasData, isFalse);
      expect(result.count, 0);
      expect(result.dominantQuadrant, isNull);
    });

    test('recent mood entry produces basic analysis', () {
      final ts = now - 3600000;
      final entries = [
        fixtureMoodEntry(ts: ts, v: 0.5, a: -0.3, word: 'hopeful')
      ];
      final analyzer = MoodAnalyzer(entries);
      final result = analyzer.analyze();

      expect(result.hasData, isTrue);
      expect(result.count, 1);
      expect(result.avgV, closeTo(0.5, 0.01));
      expect(result.avgA, closeTo(-0.3, 0.01));
    });
  });

  group('TextAnalyzer', () {
    test('empty entries produce no-data analysis', () {
      final analyzer = TextAnalyzer([]);
      final result = analyzer.analyzeEntries();
      expect(result.count, 0);
      expect(result.hasData, isFalse);
    });

    test('analyzes keyword frequency from recent entries', () {
      final ts = now - 3600000;
      final entries = [
        JournalEntry(
            ts: ts, text: 'Today was a good day. A very good day indeed.'),
        JournalEntry(
            ts: ts - 1000,
            text: 'Another day, another walk. The good walk helped.'),
      ];
      final analyzer = TextAnalyzer(entries);
      final result = analyzer.analyzeEntries();

      expect(result.count, 2);
      expect(result.topKeywords, isNotEmpty);
    });
  });

  group('PromptEngine', () {
    test('empty entries produce basic weekly insight with thin evidence', () {
      final engine = PromptEngine([]);
      final insight = engine.generateWeeklyInsight();
      expect(insight.headline, isNotEmpty);
      expect(insight.thin, isTrue);
    });

    test('demo days produce insight', () {
      final engine = PromptEngine(demoDays());
      final insight = engine.generateWeeklyInsight();
      expect(insight.headline, isNotEmpty);
    });

    test('generateSeasons returns monthly summaries', () {
      final engine = PromptEngine(demoDays());
      final seasons = engine.generateSeasons();
      expect(seasons, isNotEmpty);
    });
  });

  group('CurrentsEngine', () {
    test('undertowScan returns null for short text', () {
      final result = undertowScan('Hello.');
      expect(result, isNull);
    });

    test('undertowScan detects worry patterns in long brooding text', () {
      final text =
          'Why does this always happen to me? What if I never figure it out? '
          'I keep asking why and I keep getting nowhere with these thoughts. '
          'What if everything goes wrong next week? Why can I not stop thinking about this?';
      final result = undertowScan(text);
      expect(result, isNotNull);
      expect(result!.kind, isNotEmpty);
    });

    test('almanacRead returns empty reading for no data', () {
      final result = almanacRead([]);
      expect(result.lines, isEmpty);
    });

    test('almanacRead returns reading for demo data', () {
      final result = almanacRead(demoDays());
      expect(result, isNotNull);
    });

    test('mineAnchors returns suggestions from demo data', () {
      final result = mineAnchors(demoDays());
      expect(result, isNotNull);
    });
  });
}
