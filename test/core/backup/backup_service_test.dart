import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/core/backup/backup_service.dart';
import 'package:mentesana_mood_selector/core/backup/legacy_backup_service.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppStore store;
  late BackupService service;

  Future<void> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final r = SettingsRepository.createFromPrefs(prefs);
    store = AppStore.fromRepository(r);
    service = LegacyBackupService(store);
  }

  setUp(fresh);

  group('LegacyBackupService async delegation', () {
    test('exportJson and importJson round-trip', () async {
      store.addEntry(JournalEntry(ts: 1, text: 'a page'));
      final raw = await service.exportJson();
      expect(raw, contains('a page'));
      store.resetEntries();
      final count = await service.importJson(raw);
      expect(count, 1);
    });

    test('exportEncrypted and importEncrypted round-trip', () async {
      store.addEntry(JournalEntry(ts: 1, text: 'a page'));
      final blob = await service.exportEncrypted('test');
      expect(blob.startsWith('MSNA1:'), isTrue);
      final store2 = AppStore.fromRepository(
        SettingsRepository.createFromPrefs(
            await SharedPreferences.getInstance()),
      );
      store2.resetEntries();
      final count =
          await LegacyBackupService(store2).importEncrypted(blob, 'test');
      expect(count, 1);
    });

    test('wrong passphrase returns null', () async {
      store.addEntry(JournalEntry(ts: 1, text: 'a page'));
      final blob = await service.exportEncrypted('correct');
      expect(await service.importEncrypted(blob, 'wrong'), isNull);
    });

    test('exportText returns readable content', () async {
      store.addEntry(JournalEntry(ts: 1000, text: 'plain text'));
      final text = await service.exportText();
      expect(text, contains('plain text'));
    });

    test('storageBytes reports positive value', () async {
      store.addEntry(JournalEntry(ts: 1, text: 'x'));
      final n = await service.storageBytes();
      expect(n, greaterThan(0));
    });
  });
}
