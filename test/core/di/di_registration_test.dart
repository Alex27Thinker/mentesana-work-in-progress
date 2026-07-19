import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/core/attachment_storage.dart';
import 'package:mentesana_mood_selector/core/backup/backup_service.dart';
import 'package:mentesana_mood_selector/core/backup/legacy_backup_service.dart';
import 'package:mentesana_mood_selector/core/locator.dart';
import 'package:mentesana_mood_selector/features/journal/data/legacy_attachment_storage.dart';
import 'package:mentesana_mood_selector/features/journal/data/legacy_currents_repository.dart';
import 'package:mentesana_mood_selector/features/journal/data/legacy_journal_repository.dart';
import 'package:mentesana_mood_selector/features/journal/domain/currents_repository.dart';
import 'package:mentesana_mood_selector/features/journal/domain/journal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock SharedPreferences before any getInstance call.
    SharedPreferences.setMockInitialValues({});
    // Reset the singleton between tests.
    if (di.isRegistered<AppStore>()) {
      await di.reset();
    }
    configureDependencies();
    // configureDependencies registers SettingsRepository as an async
    // singleton. Wait for allReady to complete so dependent lookups
    // succeed in the tests.
    await di.allReady();
  });

  test('JournalRepository resolves to LegacyJournalRepository', () {
    expect(di<JournalRepository>(), isA<LegacyJournalRepository>());
  });

  test('CurrentsRepository resolves to LegacyCurrentsRepository', () {
    expect(di<CurrentsRepository>(), isA<LegacyCurrentsRepository>());
  });

  test('AttachmentStorage resolves to LegacyAttachmentStorage', () {
    expect(di<AttachmentStorage>(), isA<LegacyAttachmentStorage>());
  });

  test('BackupService resolves to LegacyBackupService', () {
    expect(di<BackupService>(), isA<LegacyBackupService>());
  });

  test('adapters share the registered AppStore instance', () async {
    final store = di<AppStore>();
    final journalRepo = di<JournalRepository>();
    await journalRepo.add(JournalEntry(ts: 77, text: 'shared'));
    expect(store.findByTs(77)?.text, 'shared');
  });

  test('reset disposes instantiated repository adapters', () async {
    di<JournalRepository>();
    di<CurrentsRepository>();
    await di.reset();
    expect(di.isRegistered<JournalRepository>(), isFalse);
    expect(di.isRegistered<CurrentsRepository>(), isFalse);
  });
}
