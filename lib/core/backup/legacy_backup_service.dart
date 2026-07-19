import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/core/backup/backup_service.dart';

class LegacyBackupService implements BackupService {
  final AppStore _store;

  LegacyBackupService(this._store);

  @override
  String exportJson() => _store.exportJson();

  @override
  int? importJson(String raw) => _store.importJson(raw);

  @override
  String exportEncrypted(String passphrase) =>
      _store.exportEncrypted(passphrase);

  @override
  int? importEncrypted(String blob, String passphrase) =>
      _store.importEncrypted(blob, passphrase);

  @override
  String exportText() => _store.exportText();

  @override
  int storageBytes() => _store.storageBytes();
}
