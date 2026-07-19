import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppStore> freshStore(Map<String, Object> mock) async {
    SharedPreferences.setMockInitialValues(mock);
    final prefs = await SharedPreferences.getInstance();
    final r = SettingsRepository.createFromPrefs(prefs);
    return AppStore.fromRepository(r);
  }

  group('startup migration', () {
    test("legacy word 'journal' becomes null after loading", () async {
      final store = await freshStore({
        'mentesana-entries':
            '[{"ts":1,"v":0.3,"a":-0.1,"word":"journal","text":""}]',
      });
      expect(store.entries.first.word, isNull);
    });

    test('pendingTranscription flag and path are cleared on startup', () async {
      final store = await freshStore({
        'mentesana-entries':
            '[{"ts":1,"pendingTranscription":true,"pendingAudioPath":"/tmp/a.webm","text":""}]',
      });
      expect(store.entries.first.pendingTranscription, isFalse);
      expect(store.entries.first.pendingAudioPath, isNull);
    });
  });

  group('transcription lifecycle', () {
    late AppStore store;

    setUp(() async {
      store = await freshStore({});
      store.addEntry(JournalEntry(ts: 1000, text: 'before'));
    });

    test('beginPendingTranscription sets the path and flag', () {
      final e = store.entries.first;
      store.beginPendingTranscription(e, '/tmp/a.webm');
      final updated = store.findByTs(1000)!;
      expect(updated.pendingTranscription, isTrue);
      expect(updated.pendingAudioPath, '/tmp/a.webm');
    });

    test('completeTranscription clears pendingAudioPath', () {
      final e = store.entries.first;
      store.beginPendingTranscription(e, '/tmp/a.webm');
      store.completeTranscription(1000, 'the transcript');
      final updated = store.findByTs(1000)!;
      expect(updated.pendingTranscription, isFalse);
      expect(updated.pendingAudioPath, isNull);
      expect(updated.text, contains('the transcript'));
    });

    test('failTranscription clears pendingAudioPath', () {
      final e = store.entries.first;
      store.beginPendingTranscription(e, '/tmp/a.webm');
      store.failTranscription(1000);
      final updated = store.findByTs(1000)!;
      expect(updated.pendingTranscription, isFalse);
      expect(updated.pendingAudioPath, isNull);
    });
  });

  group('tide-line and cleared values survive persistence', () {
    test('clearing a tide line clears tideAt', () async {
      // Use a shared mock so persistence across the two store instances
      // works correctly within the same test.
      final mock = <String, Object>{};
      SharedPreferences.setMockInitialValues(mock);
      final prefs1 = await SharedPreferences.getInstance();
      final repo1 = SettingsRepository.createFromPrefs(prefs1);
      final store1 = AppStore.fromRepository(repo1);
      store1.addEntry(JournalEntry(
        ts: 2000,
        text: 't',
        tideLine: 'next time',
        tideAt: 5000,
      ));
      final e = store1.findByTs(2000)!;
      final cleared = e.copyWith(tideLine: '', tideAt: null);
      store1.updateEntry(e, cleared);

      // Reuse the same mock backing so the second store sees the writes.
      final prefs2 = await SharedPreferences.getInstance();
      final repo2 = SettingsRepository.createFromPrefs(prefs2);
      final store2 = AppStore.fromRepository(repo2);
      final loaded = store2.findByTs(2000);
      expect(loaded, isNotNull);
      expect(loaded!.tideLine, '');
      expect(loaded.tideAt, isNull);
    });
  });

  group('updateEntry replacement', () {
    late AppStore store;

    setUp(() async {
      store = await freshStore({});
    });

    test('preserves order and creates no duplicate', () {
      store.addEntry(JournalEntry(ts: 1, text: 'a'));
      store.addEntry(JournalEntry(ts: 2, text: 'b'));
      store.addEntry(JournalEntry(ts: 3, text: 'c'));
      final e = store.findByTs(2)!;
      store.updateEntry(e, e.copyWith(text: 'B'));
      expect(store.entries.map((x) => x.ts).toList(), [1, 2, 3]);
      expect(store.entries.length, 3);
      expect(store.findByTs(2)!.text, 'B');
    });

    test('throws StateError when ts is missing', () {
      expect(
        () => store.updateEntry(
            JournalEntry(ts: 9999), JournalEntry(ts: 9999, text: 'x')),
        throwsStateError,
      );
    });

    test('throws StateError when ts identity is changed', () {
      store.addEntry(JournalEntry(ts: 1, text: 'a'));
      expect(
        () => store.updateEntry(
            store.findByTs(1)!, JournalEntry(ts: 2, text: 'b')),
        throwsStateError,
      );
    });
  });
}
