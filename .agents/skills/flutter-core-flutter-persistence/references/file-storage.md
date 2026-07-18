# File Storage in Flutter

File storage provides direct access to the device's file system, enabling Flutter applications to read and write files for documents, media, custom data formats, and large binary data. The path_provider package delivers platform-agnostic directory paths, while Dart's dart:io library handles file operations on mobile and desktop platforms.

## Core Concepts

File storage offers maximum flexibility and control over data persistence. Unlike SharedPreferences (limited to primitives) or databases (structured data), file storage handles any data format—text files, JSON, images, videos, PDF documents, or custom binary formats. Applications fully control serialization, file naming, and directory organization.

The path_provider package abstracts platform differences, providing consistent APIs to access commonly used directories across iOS, Android, macOS, Windows, and Linux. Each platform has specific conventions for where apps should store different types of data, and path_provider handles these nuances automatically.

## Installation

Add path_provider to your pubspec.yaml:

```yaml
dependencies:
  path_provider: ^2.1.0
  path: ^1.9.0  # For path manipulation utilities
```

No additional platform-specific configuration is required. The package works out of the box on all supported platforms.

## Directory Types

### Application Documents Directory

Stores user-generated content and important app data that should persist across app sessions and survive app updates. This directory is backed up on iOS and included in user backups on Android:

```dart
import 'package:path_provider/path_provider.dart';
import 'dart:io';

Future<Directory> getAppDocumentsDirectory() async {
  return await getApplicationDocumentsDirectory();
}

// Usage
final dir = await getApplicationDocumentsDirectory();
final file = File('${dir.path}/user_data.json');
```

**Use for**: User documents, saved files, important app data, databases
**Backed up**: Yes (iOS and Android)
**Persists**: Survives app updates and reinstalls (if backed up)

### Temporary Directory

Stores temporary files that can be deleted by the system at any time to free space. The system may clear this directory when the device runs low on storage:

```dart
Future<Directory> getTempDirectory() async {
  return await getTemporaryDirectory();
}

// Usage
final tempDir = await getTemporaryDirectory();
final tempFile = File('${tempDir.path}/temp_download.dat');
```

**Use for**: Caches, temporary downloads, image processing intermediates
**Backed up**: No
**Persists**: May be deleted by system at any time

### Application Support Directory

Stores app-specific files that shouldn't be visible to users but should persist. Not backed up on iOS:

```dart
Future<Directory> getAppSupportDirectory() async {
  return await getApplicationSupportDirectory();
}

// Usage
final supportDir = await getApplicationSupportDirectory();
final logFile = File('${supportDir.path}/app.log');
```

**Use for**: Databases, configuration files, downloaded resources
**Backed up**: No (iOS), Yes (Android)
**Persists**: Survives app updates

### External Storage (Android Only)

Access external storage directories on Android:

```dart
// External storage directory (may be SD card)
final externalDir = await getExternalStorageDirectory();

// External storage directories for specific types
final downloads = await getExternalStorageDirectories(
  type: StorageDirectory.downloads,
);
final pictures = await getExternalStorageDirectories(
  type: StorageDirectory.pictures,
);
```

**Use for**: Large files, media that should be accessible to other apps
**Platform**: Android only (returns null on other platforms)
**Persists**: Survives app uninstall

## Basic File Operations

### Writing Files

Write text to files:

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> writeTextFile(String filename, String content) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  // Write string to file
  return await file.writeAsString(content);
}

// Usage
await writeTextFile('notes.txt', 'My important notes');
```

Write binary data:

```dart
Future<File> writeBinaryFile(String filename, List<int> bytes) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  // Write bytes to file
  return await file.writeAsBytes(bytes);
}

// Usage
final imageBytes = await networkImage.readAsBytes();
await writeBinaryFile('profile.jpg', imageBytes);
```

Append to existing files:

```dart
Future<File> appendToFile(String filename, String content) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  // Append to file (creates if doesn't exist)
  return await file.writeAsString(
    content,
    mode: FileMode.append,
  );
}
```

### Reading Files

Read text files:

```dart
Future<String> readTextFile(String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  // Read file as string
  return await file.readAsString();
}

// Usage
final content = await readTextFile('notes.txt');
print(content);
```

Read binary files:

```dart
Future<List<int>> readBinaryFile(String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  // Read file as bytes
  return await file.readAsBytes();
}

// Usage
final imageBytes = await readBinaryFile('profile.jpg');
final image = Image.memory(Uint8List.fromList(imageBytes));
```

Read files line by line (for large files):

```dart
Future<List<String>> readFileLines(String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  // Read all lines
  return await file.readAsLines();
}

// Stream large files
Stream<String> streamFileLines(String filename) async* {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  final lines = file.openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter());

  await for (var line in lines) {
    yield line;
  }
}
```

### Checking File Existence

Verify files exist before reading:

```dart
Future<bool> fileExists(String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  return await file.exists();
}

// Usage
if (await fileExists('config.json')) {
  final config = await readTextFile('config.json');
  // Process config
} else {
  // Create default config
  await writeTextFile('config.json', defaultConfig);
}
```

### Deleting Files

Remove files from storage:

```dart
Future<void> deleteFile(String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  if (await file.exists()) {
    await file.delete();
  }
}

// Delete recursively (for directories)
Future<void> deleteDirectory(String dirname) async {
  final directory = await getApplicationDocumentsDirectory();
  final dir = Directory('${directory.path}/$dirname');

  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
```

### Copying and Moving Files

Copy files to different locations:

```dart
Future<File> copyFile(String source, String destination) async {
  final directory = await getApplicationDocumentsDirectory();
  final sourceFile = File('${directory.path}/$source');
  final destFile = File('${directory.path}/$destination');

  return await sourceFile.copy(destFile.path);
}

// Move file (rename)
Future<File> moveFile(String source, String destination) async {
  final directory = await getApplicationDocumentsDirectory();
  final sourceFile = File('${directory.path}/$source');

  return await sourceFile.rename('${directory.path}/$destination');
}
```

### File Metadata

Get file information:

```dart
Future<Map<String, dynamic>> getFileInfo(String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');

  if (!await file.exists()) {
    throw FileSystemException('File not found');
  }

  final stat = await file.stat();

  return {
    'size': stat.size,
    'modified': stat.modified,
    'accessed': stat.accessed,
    'type': stat.type,
  };
}

// Usage
final info = await getFileInfo('large_file.dat');
print('File size: ${info['size']} bytes');
print('Last modified: ${info['modified']}');
```

## Working with Directories

### Creating Directories

Create directory structures:

```dart
Future<Directory> createDirectory(String dirname) async {
  final baseDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${baseDir.path}/$dirname');

  // Create directory (and parents if needed)
  return await dir.create(recursive: true);
}

// Create nested directories
await createDirectory('data/cache/images');
```

### Listing Directory Contents

List files and subdirectories:

```dart
Future<List<FileSystemEntity>> listDirectoryContents(
  String dirname,
) async {
  final baseDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${baseDir.path}/$dirname');

  if (!await dir.exists()) {
    return [];
  }

  // List all entities
  return await dir.list().toList();
}

// Filter by type
Future<List<File>> listFiles(String dirname) async {
  final baseDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${baseDir.path}/$dirname');

  if (!await dir.exists()) {
    return [];
  }

  return await dir
      .list()
      .where((entity) => entity is File)
      .cast<File>()
      .toList();
}

// List recursively
Future<List<File>> listAllFiles(String dirname) async {
  final baseDir = await getApplicationDocumentsDirectory();
  final dir = Directory('${baseDir.path}/$dirname');

  if (!await dir.exists()) {
    return [];
  }

  return await dir
      .list(recursive: true)
      .where((entity) => entity is File)
      .cast<File>()
      .toList();
}
```

## JSON File Storage

Store and retrieve JSON data:

```dart
import 'dart:convert';

class JsonStorage {
  final String filename;

  JsonStorage(this.filename);

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$filename');
  }

  Future<Map<String, dynamic>> read() async {
    final file = await _getFile();

    if (!await file.exists()) {
      return {};
    }

    final contents = await file.readAsString();
    return jsonDecode(contents) as Map<String, dynamic>;
  }

  Future<void> write(Map<String, dynamic> data) async {
    final file = await _getFile();
    final jsonString = jsonEncode(data);
    await file.writeAsString(jsonString);
  }

  Future<void> update(Map<String, dynamic> updates) async {
    final data = await read();
    data.addAll(updates);
    await write(data);
  }

  Future<void> delete() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

// Usage
final storage = JsonStorage('user_settings.json');
await storage.write({
  'theme': 'dark',
  'notifications': true,
  'language': 'en',
});

final settings = await storage.read();
print(settings['theme']); // dark
```

## Image Storage

Save and load images from files:

```dart
import 'package:flutter/material.dart';
import 'dart:typed_data';

class ImageStorage {
  Future<File> saveImage(String filename, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/images/$filename');

    // Ensure directory exists
    await file.parent.create(recursive: true);

    return await file.writeAsBytes(bytes);
  }

  Future<File?> saveImageFromNetwork(String filename, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return await saveImage(filename, response.bodyBytes);
      }
    } catch (e) {
      print('Failed to download image: $e');
    }
    return null;
  }

  Future<Image?> loadImage(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/images/$filename');

    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      return Image.memory(bytes);
    }

    return null;
  }

  Future<void> deleteImage(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/images/$filename');

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<String>> listImages() async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/images');

    if (!await imageDir.exists()) {
      return [];
    }

    final files = await imageDir.list().toList();
    return files
        .where((entity) => entity is File)
        .map((entity) => entity.path.split('/').last)
        .toList();
  }
}
```

## Cache Management

Implement file-based caching with expiration:

```dart
class FileCache {
  final Duration ttl;

  FileCache({this.ttl = const Duration(hours: 24)});

  Future<File> _getCacheFile(String key) async {
    final directory = await getTemporaryDirectory();
    return File('${directory.path}/cache/$key');
  }

  Future<File> _getMetadataFile(String key) async {
    final directory = await getTemporaryDirectory();
    return File('${directory.path}/cache/$key.meta');
  }

  Future<void> put(String key, String data) async {
    final file = await _getCacheFile(key);
    final metaFile = await _getMetadataFile(key);

    await file.parent.create(recursive: true);
    await file.writeAsString(data);

    // Write timestamp
    await metaFile.writeAsString(
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<String?> get(String key) async {
    final file = await _getCacheFile(key);
    final metaFile = await _getMetadataFile(key);

    if (!await file.exists() || !await metaFile.exists()) {
      return null;
    }

    // Check expiration
    final timestampStr = await metaFile.readAsString();
    final timestamp = int.parse(timestampStr);
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final age = DateTime.now().difference(cacheTime);

    if (age > ttl) {
      await delete(key);
      return null;
    }

    return await file.readAsString();
  }

  Future<void> delete(String key) async {
    final file = await _getCacheFile(key);
    final metaFile = await _getMetadataFile(key);

    if (await file.exists()) {
      await file.delete();
    }
    if (await metaFile.exists()) {
      await metaFile.delete();
    }
  }

  Future<void> clearExpired() async {
    final directory = await getTemporaryDirectory();
    final cacheDir = Directory('${directory.path}/cache');

    if (!await cacheDir.exists()) {
      return;
    }

    final files = await cacheDir.list().toList();

    for (final entity in files) {
      if (entity is File && entity.path.endsWith('.meta')) {
        final key = entity.path.split('/').last.replaceAll('.meta', '');
        final cached = await get(key); // Will auto-delete if expired
      }
    }
  }

  Future<void> clearAll() async {
    final directory = await getTemporaryDirectory();
    final cacheDir = Directory('${directory.path}/cache');

    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }
}
```

## Large File Handling

Handle large files efficiently with streams:

```dart
class LargeFileHandler {
  // Download large file with progress
  Future<void> downloadLargeFile(
    String url,
    String filename,
    void Function(int received, int total)? onProgress,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');

    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();

    final contentLength = response.contentLength;
    var received = 0;

    final sink = file.openWrite();

    await response.forEach((chunk) {
      sink.add(chunk);
      received += chunk.length;
      onProgress?.call(received, contentLength);
    });

    await sink.close();
  }

  // Read large file in chunks
  Future<void> processLargeFile(
    String filename,
    Future<void> Function(List<int> chunk) processor,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');

    final stream = file.openRead();

    await for (var chunk in stream) {
      await processor(chunk);
    }
  }

  // Copy large file with progress
  Future<void> copyLargeFile(
    String source,
    String destination,
    void Function(int transferred, int total)? onProgress,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final sourceFile = File('${directory.path}/$source');
    final destFile = File('${directory.path}/$destination');

    final fileSize = await sourceFile.length();
    var transferred = 0;

    final sourceStream = sourceFile.openRead();
    final sink = destFile.openWrite();

    await for (var chunk in sourceStream) {
      sink.add(chunk);
      transferred += chunk.length;
      onProgress?.call(transferred, fileSize);
    }

    await sink.close();
  }
}
```

## Platform-Specific Paths

Access platform-specific directories:

```dart
class PlatformPaths {
  // Downloads directory (Android only)
  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return await getDownloadsDirectory();
    }
    return null;
  }

  // Pictures directory
  Future<List<Directory>?> getPicturesDirectories() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      );
    }
    return null;
  }

  // Application library directory (iOS only)
  Future<Directory?> getLibraryDirectory() async {
    if (Platform.isIOS) {
      return await getLibraryDirectory();
    }
    return null;
  }

  // Get appropriate directory for file type
  Future<Directory> getDirectoryForType(FileType type) async {
    switch (type) {
      case FileType.document:
        return await getApplicationDocumentsDirectory();
      case FileType.cache:
        return await getTemporaryDirectory();
      case FileType.config:
        return await getApplicationSupportDirectory();
      default:
        return await getApplicationDocumentsDirectory();
    }
  }
}

enum FileType { document, cache, config }
```

## Error Handling

Handle file operation errors gracefully:

```dart
class SafeFileStorage {
  Future<String?> safeRead(String filename) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');

      if (!await file.exists()) {
        return null;
      }

      return await file.readAsString();
    } on FileSystemException catch (e) {
      print('File system error: ${e.message}');
      return null;
    } on PathNotFoundException catch (e) {
      print('Path not found: ${e.path}');
      return null;
    } catch (e) {
      print('Unexpected error: $e');
      return null;
    }
  }

  Future<bool> safeWrite(String filename, String content) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');

      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return true;
    } on FileSystemException catch (e) {
      print('Failed to write file: ${e.message}');
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      return false;
    }
  }
}
```

## Best Practices

### File Naming

Use consistent, safe file naming:

```dart
String sanitizeFilename(String filename) {
  // Remove invalid characters
  return filename.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
}

String generateUniqueFilename(String base, String extension) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${base}_$timestamp.$extension';
}
```

### Directory Organization

Organize files into logical directories:

```dart
class FileOrganizer {
  static const userDocuments = 'documents';
  static const userImages = 'images';
  static const cache = 'cache';
  static const logs = 'logs';

  Future<File> getFile(String category, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final categoryDir = Directory('${directory.path}/$category');
    await categoryDir.create(recursive: true);
    return File('${categoryDir.path}/$filename');
  }
}
```

### Memory Management

Avoid loading large files entirely into memory:

```dart
// Bad: Loads entire file into memory
final largeFile = await file.readAsString();

// Good: Process file in chunks
final stream = file.openRead();
await for (var chunk in stream) {
  // Process chunk
}
```

### Atomic Writes

Ensure file writes are atomic:

```dart
Future<void> atomicWrite(String filename, String content) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$filename');
  final tempFile = File('${directory.path}/$filename.tmp');

  // Write to temporary file
  await tempFile.writeAsString(content);

  // Rename (atomic operation)
  await tempFile.rename(file.path);
}
```

## Testing

Test file operations using temporary directories:

```dart
void main() {
  late Directory testDir;

  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('test_');
  });

  tearDown(() async {
    if (await testDir.exists()) {
      await testDir.delete(recursive: true);
    }
  });

  test('write and read file', () async {
    final file = File('${testDir.path}/test.txt');
    await file.writeAsString('test content');

    final content = await file.readAsString();
    expect(content, 'test content');
  });
}
```

File storage provides the most flexibility for persisting data in Flutter applications. Combined with proper error handling, directory organization, and cache management, it enables robust handling of documents, media files, and custom data formats across all Flutter platforms.
