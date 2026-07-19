import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/core/attachment_storage.dart';
import 'package:mentesana_mood_selector/features/journal/data/legacy_attachment_storage.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';

void main() {
  late AttachmentStorage storage;

  setUp(() {
    storage = const LegacyAttachmentStorage();
  });

  group('LegacyAttachmentStorage', () {
    test('storeAttachment preserves bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final a = await storage.storeAttachment(
        name: 'a.jpg',
        mime: 'image/jpeg',
        bytes: bytes,
      );
      expect(a.name, 'a.jpg');
      expect(a.type, 'image/jpeg');
      expect(a.size, 5);
      expect(a.data, startsWith('data:image/jpeg;base64,'));
    });

    test('readAttachment returns the original bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final a = await storage.storeAttachment(
        name: 'a.jpg',
        mime: 'image/jpeg',
        bytes: bytes,
      );
      final read = await storage.readAttachment(a);
      expect(read, isNotNull);
      expect(read!.length, 5);
      expect(read.toList(), [1, 2, 3, 4, 5]);
    });

    test('readAttachment returns null for empty data', () async {
      const a = Attachment(name: 'a.jpg', type: 'image/jpeg');
      final r = await storage.readAttachment(a);
      expect(r, isNull);
    });

    test('readAttachment returns null for malformed data', () async {
      const a =
          Attachment(name: 'a.jpg', type: 'image/jpeg', data: 'not-a-data-url');
      final r = await storage.readAttachment(a);
      expect(r, isNull);
    });

    test('storeAttachment rejects empty bytes', () async {
      expect(
        () => storage.storeAttachment(
          name: 'a.jpg',
          mime: 'image/jpeg',
          bytes: Uint8List(0),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('storeAttachment rejects missing mime', () async {
      expect(
        () => storage.storeAttachment(
          name: 'a.jpg',
          mime: '',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('deleteAttachment is a no-op for legacy embedded storage', () async {
      const a = Attachment(name: 'a.jpg', type: 'image/jpeg');
      // Should not throw.
      await storage.deleteAttachment(a);
    });

    test('cleanupUnreferenced is a no-op for legacy embedded storage',
        () async {
      // Should not throw.
      await storage.cleanupUnreferenced(<String>{});
    });
  });
}
