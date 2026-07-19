import 'package:mentesana_mood_selector/features/journal/domain/attachment.dart';
import 'package:mentesana_mood_selector/core/attachment_storage.dart';

class LegacyAttachmentStorage implements AttachmentStorage {
  const LegacyAttachmentStorage();

  @override
  Future<Attachment?> storeAttachment(
      String name, String mime, List<int> bytes) async {
    return Attachment(name: name, type: mime, size: bytes.length, data: '');
  }

  @override
  Future<void> deleteAttachment(Attachment attachment) async {}

  @override
  Future<List<int>?> readAttachment(Attachment attachment) async => null;

  @override
  Future<void> cleanupUnreferenced(Iterable<String> referencedPaths) async {}
}
