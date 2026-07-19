abstract class BackupService {
  String exportJson();
  int? importJson(String raw);
  String exportEncrypted(String passphrase);
  int? importEncrypted(String blob, String passphrase);
  String exportText();
  int storageBytes();
}
