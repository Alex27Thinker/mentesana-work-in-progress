import '../../features/journal/domain/attachment.dart';

abstract class AttachmentStorage {
  Future<Attachment?> storeAttachment(String name, String mime, List<int> bytes);
  Future<void> deleteAttachment(Attachment attachment);
  Future<List<int>?> readAttachment(Attachment attachment);
  Future<void> cleanupUnreferenced(Iterable<String> referencedPaths);
}
