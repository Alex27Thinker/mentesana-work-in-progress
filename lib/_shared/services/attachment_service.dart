// Mentesana — attachment file-picker and compression service.
//
// All attachment data stays on-device as base64 data URLs (the app's
// existing storage shape). Images selected from the camera roll are
// compressed below the 2.5 MB cap before being stored, keeping memory
// usage low even with the per-page limit of 3.
//
// The compression target is ~2 MB raw, with a progressive quality ladder
// so large source images are squeezed down without becoming illegible.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

/// Max raw-byte ceiling for a single attachment. The README documents a
/// 2.5 MB cap; we target 2 MB here so that base64 inflation still stays
/// comfortably inside that envelope.
const int kMaxAttachmentBytes = 2 * 1024 * 1024;

/// Limit per page — checked by the caller (the journal editor).
const int kAttachmentCap = 3;

/// Result returned by [AttachmentService.pickAndCompress].
class AttachmentPickResult {
  const AttachmentPickResult({
    required this.name,
    required this.mime,
    required this.dataUrl,
    required this.byteSize,
  });

  final String name;
  final String mime;
  final String dataUrl;
  final int byteSize;
}

class AttachmentService {
  const AttachmentService({required this.imagePicker});

  final ImagePicker imagePicker;

  /// Pick one image from [source] (gallery / camera), compress it below
  /// [kMaxAttachmentBytes], and return a data URL with metadata.
  ///
  /// Returns `null` when the user cancels the picker — callers should
  /// treat that as a no-op. Throws on unexpected I/O errors.
  Future<AttachmentPickResult?> pickAndCompress(ImageSource source) async {
    final XFile? picked = await imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return null;

    final String name = picked.name;
    final String mime = picked.mimeType ?? 'image/jpeg';
    final File sourceFile = File(picked.path);

    // Read raw bytes once, then compress entirely in memory.
    final Uint8List rawBytes = await sourceFile.readAsBytes();
    final Uint8List compressed = await compressToBytes(
      rawBytes,
      quality: _estimateQuality(rawBytes.length),
    );

    final String dataUrl = 'data:$mime;base64,${base64Encode(compressed)}';

    // Camera picker writes a temp copy — clean it up.
    if (source == ImageSource.camera) {
      try {
        await sourceFile.delete();
      } catch (_) {}
    }

    return AttachmentPickResult(
      name: name,
      mime: mime,
      dataUrl: dataUrl,
      byteSize: compressed.length,
    );
  }

  /// Compress buffer with a progressive quality ladder until the byte
  /// ceiling is met or 45 % quality is reached.
  static Future<Uint8List> compressToBytes(
    Uint8List bytes, {
    int quality = 75,
  }) async {
    if (bytes.length <= kMaxAttachmentBytes) return bytes;

    int q = quality;
    Uint8List result = bytes;

    while (q >= 45 && result.length > kMaxAttachmentBytes) {
      result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 800,
        minHeight: 800,
        quality: q,
        format: CompressFormat.jpeg,
      );
      q -= 10;
    }

    return result;
  }

  /// Derive a starting quality from the byte count — big images go in
  /// lower to avoid wasting passes through the compression ladder.
  static int _estimateQuality(int byteCount) {
    if (byteCount <= kMaxAttachmentBytes) return 92;
    if (byteCount <= 3 * 1024 * 1024) return 75;
    if (byteCount <= 6 * 1024 * 1024) return 60;
    return 50;
  }
}