import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../helpers/fixtures.dart';

void main() {
  group('AppStore persistence', () {
    late SharedPreferences prefs;
    late SettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = SettingsRepository.createFromPrefs(prefs);
    });

    test('settings defaults are correct', () {
      final store = AppStore.fromRepository(repo);
      expect(store.welcomed, isFalse);
      expect(store.room, 'night');
      expect(store.moodAtmosphereOn, isTrue);
      expect(store.textSize, 'regular');
      expect(store.reducedMotionOn, isFalse);
      expect(store.language, 'en');
      expect(store.reminderOn, isFalse);
      expect(store.pinLockOn, isFalse);
      expect(store.aiEnabled, isFalse);
      expect(store.currentsOn, isTrue);
      expect(store.almanacOn, isTrue);
      expect(store.entries, isEmpty);
    });

    test('addEntry serializes and deserializes round-trip', () {
      final store = AppStore.fromRepository(repo);
      final entry = fixtureEntry(
          ts: 1000, v: 0.5, a: -0.3, word: 'calm', text: 'Hello world');

      store.addEntry(entry);

      final store2 = AppStore.fromRepository(repo);
      expect(store2.entries.length, 1);
      expect(store2.entries.first.text, 'Hello world');
      expect(store2.entries.first.word, 'calm');
    });

    test('multiple entries persist round-trip', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000, text: 'First'));
      store.addEntry(fixtureEntry(ts: 2000, text: 'Second'));

      final store2 = AppStore.fromRepository(repo);
      expect(store2.entries.length, 2);
    });

    test('deleteEntry removes from persistence', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000, text: 'To delete'));
      final entry = store.entries.first;
      store.deleteEntry(entry);

      final store2 = AppStore.fromRepository(repo);
      expect(store2.entries, isEmpty);
    });

    test('settings persist through store recreation', () {
      final store = AppStore.fromRepository(repo);
      store.setRoom('day');
      store.setLanguage('it');
      store.setReducedMotion(true);
      store.setAiEnabled(true);

      final store2 = AppStore.fromRepository(repo);
      expect(store2.room, 'day');
      expect(store2.language, 'it');
      expect(store2.reducedMotionOn, isTrue);
      expect(store2.aiEnabled, isTrue);
    });

    test('importJson merges entries by timestamp', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000, text: 'Original'));
      store.addEntry(fixtureEntry(ts: 2000, text: 'Original 2'));

      final importData = jsonEncode({
        'entries': [
          fixtureEntryJson(ts: 2000, text: 'Updated'),
          fixtureEntryJson(ts: 3000, text: 'New'),
        ],
      });

      final count = store.importJson(importData);
      expect(count, 3);
      final updated = store.findByTs(2000);
      expect(updated!.text, 'Updated');
    });

    test('importJson returns null for invalid input', () {
      final store = AppStore.fromRepository(repo);
      expect(store.importJson('not json'), isNull);
      expect(store.importJson('{}'), 0);
    });

    test('encrypted backup round-trip', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000, text: 'Secret page'));

      final encrypted = store.exportEncrypted('test-passphrase');
      expect(encrypted.startsWith('MSNA1:'), isTrue);

      final store2 = AppStore.fromRepository(repo);
      store2.resetEntries();
      final count = store2.importEncrypted(encrypted, 'test-passphrase');
      expect(count, 1);
      expect(store2.entries.first.text, 'Secret page');
    });

    test('encrypted backup rejects wrong passphrase', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000, text: 'Secret'));

      final encrypted = store.exportEncrypted('correct-passphrase');
      final store2 = AppStore.fromRepository(repo);
      final result = store2.importEncrypted(encrypted, 'wrong-passphrase');
      expect(result, isNull);
    });

    test('exportJson produces valid export', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000, text: 'Export test'));

      final exported = store.exportJson();
      expect(exported, contains('entries'));
      expect(exported, contains('Export test'));
    });

    test('exportText produces readable format', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000000, text: 'Beautiful day'));

      final text = store.exportText();
      expect(text, contains('Beautiful day'));
      expect(text, contains('calm'));
    });

    test('storageBytes estimates usage', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 1000, text: 'Storage test'));
      final bytes = store.storageBytes();
      expect(bytes, greaterThan(0));
    });
  });

  group('JournalDraft persistence', () {
    late SharedPreferences prefs;
    late SettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = SettingsRepository.createFromPrefs(prefs);
    });

    test('save and read draft round-trip', () {
      final store = AppStore.fromRepository(repo);
      final draft = fixtureDraft(text: 'My ongoing draft...', ts: 5000);

      store.saveJournalDraft(draft);
      final restored = store.readJournalDraft();

      expect(restored, isNotNull);
      expect(restored!.text, 'My ongoing draft...');
      expect(restored.ts, 5000);
    });

    test('clear draft sets empty draft', () {
      final store = AppStore.fromRepository(repo);
      store.saveJournalDraft(fixtureDraft(text: 'Temporary'));
      store.clearJournalDraft();

      final restored = store.readJournalDraft();
      expect(restored, isNotNull);
      expect(restored!.text, '');
    });

    test('default draft is empty object', () {
      final store = AppStore.fromRepository(repo);
      final restored = store.readJournalDraft();
      expect(restored, isNotNull);
      expect(restored!.text, '');
      expect(restored.ts, 0);
    });
  });

  group('AppStore derived values', () {
    late SettingsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepository.createFromPrefs(prefs);
    });

    test('activeTideExperiment returns null when empty', () {
      final store = AppStore.fromRepository(repo);
      expect(store.activeTideExperiment, isNull);
    });

    test('effectiveRoom uses autoRoom toggle', () {
      final store = AppStore.fromRepository(repo);
      store.autoRoomOn = false;
      store.room = 'day';
      expect(store.effectiveRoom, 'day');
    });

    test('textScale returns correct multiplier', () {
      final store = AppStore.fromRepository(repo);
      store.textSize = 'small';
      expect(store.textScale, closeTo(0.92, 0.01));
      store.textSize = 'regular';
      expect(store.textScale, 1.0);
      store.textSize = 'large';
      expect(store.textScale, closeTo(1.08, 0.01));
    });

    test('latestMoodToday returns correct entry', () {
      final store = AppStore.fromRepository(repo);
      final now = DateTime.now();
      final todayTs =
          DateTime(now.year, now.month, now.day, 12).millisecondsSinceEpoch;

      store.addEntry(
          fixtureMoodEntry(ts: todayTs, v: 0.5, a: -0.3, word: 'today-mood'));
      store.addEntry(fixtureMoodEntry(ts: 1000, v: 0.1, a: 0.1, word: 'old'));

      final latest = store.latestMoodToday();
      expect(latest, isNotNull);
      expect(latest!.word, 'today-mood');
    });

    test('findByTs returns correct entry', () {
      final store = AppStore.fromRepository(repo);
      store.addEntry(fixtureEntry(ts: 42, text: 'Found me'));
      expect(store.findByTs(42), isNotNull);
      expect(store.findByTs(99), isNull);
    });
  });
}
