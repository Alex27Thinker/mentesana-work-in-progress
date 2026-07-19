import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/features/journal/domain/_copy_with_helpers.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';

void main() {
  // Sentinel-based copyWith must distinguish:
  //   1. argument omitted → preserve
  //   2. explicit null    → clear
  //   3. non-null         → replace

  group('JournalEntry copyWith nullable semantics', () {
    final base = JournalEntry(
      ts: 1,
      v: 0.5,
      a: -0.3,
      word: 'hopeful',
      wordCount: 5,
      tideAt: 1000,
      moodTs: 500,
      afterV: 0.4,
      afterA: -0.2,
      afterWord: 'content',
      afterTs: 600,
      pendingAudioPath: '/tmp/a.webm',
    );

    test('omitted argument preserves value', () {
      final r = base.copyWith();
      expect(r.v, 0.5);
      expect(r.a, -0.3);
      expect(r.word, 'hopeful');
      expect(r.wordCount, 5);
      expect(r.tideAt, 1000);
      expect(r.moodTs, 500);
      expect(r.afterV, 0.4);
      expect(r.afterA, -0.2);
      expect(r.afterWord, 'content');
      expect(r.afterTs, 600);
      expect(r.pendingAudioPath, '/tmp/a.webm');
    });

    test('explicit null clears value', () {
      final r = base.copyWith(
        v: null,
        a: null,
        word: null,
        wordCount: null,
        tideAt: null,
        moodTs: null,
        afterV: null,
        afterA: null,
        afterWord: null,
        afterTs: null,
        pendingAudioPath: null,
      );
      expect(r.v, isNull);
      expect(r.a, isNull);
      expect(r.word, isNull);
      expect(r.wordCount, isNull);
      expect(r.tideAt, isNull);
      expect(r.moodTs, isNull);
      expect(r.afterV, isNull);
      expect(r.afterA, isNull);
      expect(r.afterWord, isNull);
      expect(r.afterTs, isNull);
      expect(r.pendingAudioPath, isNull);
    });

    test('non-null argument replaces value', () {
      final r = base.copyWith(
        v: 0.9,
        a: 0.8,
        word: 'bright',
        wordCount: 12,
        tideAt: 2000,
        moodTs: 1500,
        afterV: 0.7,
        afterA: 0.6,
        afterWord: 'joyful',
        afterTs: 1600,
        pendingAudioPath: '/tmp/b.webm',
      );
      expect(r.v, 0.9);
      expect(r.a, 0.8);
      expect(r.word, 'bright');
      expect(r.wordCount, 12);
      expect(r.tideAt, 2000);
      expect(r.moodTs, 1500);
      expect(r.afterV, 0.7);
      expect(r.afterA, 0.6);
      expect(r.afterWord, 'joyful');
      expect(r.afterTs, 1600);
      expect(r.pendingAudioPath, '/tmp/b.webm');
    });
  });

  group('JournalDraft copyWith nullable semantics', () {
    final base = JournalDraft(
      ts: 1,
      prompt: 'reflect',
      activeEntryTs: 100,
      v: 0.3,
      a: -0.1,
      word: 'calm',
    );

    test('omitted argument preserves value', () {
      final r = base.copyWith();
      expect(r.prompt, 'reflect');
      expect(r.activeEntryTs, 100);
      expect(r.v, 0.3);
      expect(r.a, -0.1);
      expect(r.word, 'calm');
    });

    test('explicit null clears value', () {
      final r = base.copyWith(
        prompt: null,
        activeEntryTs: null,
        v: null,
        a: null,
        word: null,
      );
      expect(r.prompt, isNull);
      expect(r.activeEntryTs, isNull);
      expect(r.v, isNull);
      expect(r.a, isNull);
      expect(r.word, isNull);
    });

    test('non-null argument replaces value', () {
      final r = base.copyWith(
        prompt: 'go deeper',
        activeEntryTs: 200,
        v: 0.7,
        a: 0.6,
        word: 'grateful',
      );
      expect(r.prompt, 'go deeper');
      expect(r.activeEntryTs, 200);
      expect(r.v, 0.7);
      expect(r.a, 0.6);
      expect(r.word, 'grateful');
    });
  });

  group('TideExperiment copyWith nullable semantics', () {
    final base = TideExperiment(
      id: 'e1',
      title: 'walk',
      hypothesis: 'h',
      action: 'a',
      theme: 't',
      startedAt: 1,
      completedAt: 100,
    );

    test('omitted preserves completedAt', () {
      final r = base.copyWith();
      expect(r.completedAt, 100);
    });

    test('explicit null clears completedAt', () {
      final r = base.copyWith(completedAt: null);
      expect(r.completedAt, isNull);
      expect(r.isComplete, isFalse);
    });

    test('non-null replaces completedAt', () {
      final r = base.copyWith(completedAt: 200);
      expect(r.completedAt, 200);
    });
  });

  group('Anchor copyWith nullable semantics', () {
    const base = Anchor(
      setAt: 1,
      text: 'a',
      theme: 't',
      forDay: '2026-07-19',
      reflectedAt: 100,
      outcome: 'written',
    );

    test('omitted preserves reflectedAt', () {
      final r = base.copyWith();
      expect(r.reflectedAt, 100);
    });

    test('explicit null clears reflectedAt', () {
      final r = base.copyWith(reflectedAt: null);
      expect(r.reflectedAt, isNull);
      expect(r.isOpen, isTrue);
    });

    test('non-null replaces reflectedAt', () {
      final r = base.copyWith(reflectedAt: 200);
      expect(r.reflectedAt, 200);
      expect(r.isOpen, isFalse);
    });
  });

  // The sentinel helper is exposed for domain code to use as
  // copyWith defaults.
  test('sentinel helper isUnset', () {
    expect(isUnset(unset), isTrue);
    expect(isUnset(null), isFalse);
    expect(isUnset('value'), isFalse);
  });
}
