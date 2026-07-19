import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/core/backup/backup_service.dart';

/// Adapter that delegates the asynchronous [BackupService] API to the
/// existing synchronous AppStore methods. The envelope format (MSNA1
/// + JSON) and import semantics are preserved.
class LegacyBackupService implements BackupService {
  const LegacyBackupService(this._store);

  final AppStore _store;

  @override
  Future<String> exportJson() async => _store.exportJson();

  @override
  Future<int?> importJson(String raw) async => _store.importJson(raw);

  @override
  Future<String> exportEncrypted(String passphrase) async =>
      _store.exportEncrypted(passphrase);

  @override
  Future<int?> importEncrypted(String blob, String passphrase) async =>
      _store.importEncrypted(blob, passphrase);

  @override
  Future<String> exportText() async => _store.exportText();

  @override
  Future<int> storageBytes() async => _store.storageBytes();
}
