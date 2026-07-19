import 'dart:convert';
import 'dart:typed_data';

import 'package:mentesana_mood_selector/core/attachment_storage.dart';
import 'package:mentesana_mood_selector/features/journal/domain/attachment.dart';

/// Legacy adapter that preserves the current base64 data-URL
/// representation of journal attachments. Bytes are stored inside the
/// [Attachment] model so the parent entry remains a self-contained
/// JSON document.
///
/// This adapter does NOT silently drop data. The [storeAttachment]
/// method encodes the supplied bytes and the [readAttachment] method
/// decodes the model back into the original bytes. Empty payloads
/// and missing MIME types raise [FormatException] explicitly.
class LegacyAttachmentStorage implements AttachmentStorage {
  const LegacyAttachmentStorage();

  @override
  Future<Attachment> storeAttachment({
    required String name,
    required String mime,
    required Uint8List bytes,
  }) async {
    if (mime.isEmpty) {
      throw const FormatException('storeAttachment: mime is required');
    }
    if (bytes.isEmpty) {
      throw const FormatException('storeAttachment: bytes are empty');
    }
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    return Attachment(
      name: name,
      type: mime,
      size: bytes.length,
      data: dataUrl,
    );
  }

  @override
  Future<Uint8List?> readAttachment(Attachment attachment) async {
    final data = attachment.data;
    if (data.isEmpty) return null;
    final prefix = 'data:${attachment.type};base64,';
    if (!data.startsWith(prefix)) return null;
    try {
      return Uint8List.fromList(base64Decode(data.substring(prefix.length)));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteAttachment(Attachment attachment) async {
    // Legacy embedded attachments are removed together with the parent
    // entry; orphan cleanup is performed by the entry store.
  }

  @override
  Future<void> cleanupUnreferenced(Iterable<String> referencedIds) async {
    // Legacy attachments are embedded in the entry JSON; no filesystem
    // cleanup is required.
  }
}
