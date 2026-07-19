import 'dart:typed_data';

import '../../features/journal/domain/attachment.dart';

/// Storage boundary for journal attachments.
///
/// The legacy implementation preserves the current base64/data-URL
/// behaviour: attachments are encoded as `data:<mime>;base64,...` and
/// stored inside the journal entry JSON. File-backed persistence is a
/// target-state concern and is not implemented in the legacy adapter.
abstract interface class AttachmentStorage {
  /// Encode [bytes] for the supplied [name] and [mime] type and return
  /// a model [Attachment]. The legacy implementation returns a data
  /// URL representation; a future file-backed implementation will
  /// return a model with a relative path and metadata only.
  ///
  /// Throws [FormatException] when [bytes] is empty or [mime] is
  /// missing.
  Future<Attachment> storeAttachment({
    required String name,
    required String mime,
    required Uint8List bytes,
  });

  /// Read the binary payload referenced by [attachment]. Returns the
  /// raw bytes the model was created with. The legacy adapter
  /// decodes the embedded data URL; a future file-backed
  /// implementation will read the referenced file.
  ///
  /// Returns `null` when the legacy data is missing or malformed.
  Future<Uint8List?> readAttachment(Attachment attachment);

  /// Mark [attachment] for removal. The legacy adapter treats this as
  /// a no-op because the attachment is removed together with its
  /// parent entry — orphan cleanup is performed by the entry store.
  Future<void> deleteAttachment(Attachment attachment);

  /// Remove any attachment files no longer referenced by [referencedIds].
  /// The legacy adapter treats this as a no-op; file-backed
  /// implementations perform filesystem cleanup.
  Future<void> cleanupUnreferenced(Iterable<String> referencedIds);
}
