/// Backup and export boundary.
///
/// All operations are asynchronous to keep the public surface
/// compatible with isolate, filesystem, and database work in the
/// future. The legacy adapter delegates to the existing synchronous
/// AppStore methods inside async wrappers.
abstract interface class BackupService {
  /// Encode the current journal + tide experiments to a JSON document.
  Future<String> exportJson();

  /// Restore from a [raw] JSON document produced by [exportJson] or
  /// an encrypted backup. Returns the number of pages after restore,
  /// or `null` if the payload could not be read.
  Future<int?> importJson(String raw);

  /// Produce a passphrase-locked backup (MSNA1 envelope).
  Future<String> exportEncrypted(String passphrase);

  /// Restore a passphrase-locked backup. Returns the page count after
  /// restore, or `null` on a wrong passphrase or unreadable payload.
  Future<int?> importEncrypted(String blob, String passphrase);

  /// Render a plain-text export newest-first.
  Future<String> exportText();

  /// Estimated storage footprint in bytes (key + value, like the
  /// prototype's localStorage estimate).
  Future<int> storageBytes();
}
