# File Uploads and Storage

Complete guide to handling file uploads in Serverpod including upload permissions, storage backends (S3, Google Cloud Storage, PostgreSQL), file verification, and access control.

## Overview

Serverpod provides a secure file upload system with support for multiple storage backends, configurable validation, and access control mechanisms.

### File Upload Features

**Multiple Storage Backends**: Amazon S3, Google Cloud Storage, or PostgreSQL database storage

**Security**: Upload descriptions grant temporary upload permission, verification confirms completion, and signed URLs provide controlled access

**Validation**: Configure file size limits, MIME type restrictions, and custom validation logic

**Flexibility**: Store files directly in the database for testing or use cloud storage for production scale

## Storage Configuration

Configure storage backend in your server's configuration files.

### Database Storage (Default)

The default configuration uses PostgreSQL for file storage:

```yaml
# config/development.yaml
apiServer:
  port: 8080
  publicHost: localhost
  publicPort: 8080
  publicScheme: http

# No additional storage configuration needed
```

**Use Cases**:
- Local development and testing
- Small files (< 1MB)
- Prototyping
- Low-volume applications

**Limitations**:
- Not suitable for large files or high volume
- Increased database size
- Slower than cloud storage

### Amazon S3 Storage

Configure S3 for production file storage:

```yaml
# config/production.yaml
storage:
  s3:
    bucket: 'your-bucket-name'
    region: 'us-east-1'
    publicHost: 'your-bucket-name.s3.amazonaws.com'
```

**AWS Credentials**:

Add to `config/passwords.yaml`:

```yaml
production:
  s3AccessKeyId: 'YOUR_AWS_ACCESS_KEY'
  s3SecretAccessKey: 'YOUR_AWS_SECRET_KEY'
```

Or use environment variables:

```bash
export SERVERPOD_PASSWORD_S3_ACCESS_KEY_ID='your_key_id'
export SERVERPOD_PASSWORD_S3_SECRET_ACCESS_KEY='your_secret_key'
```

**S3 Bucket Setup**:

1. Create S3 bucket in AWS Console
2. Configure CORS policy:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"]
  }
]
```

3. Create IAM user with permissions:
   - `s3:PutObject`
   - `s3:GetObject`
   - `s3:DeleteObject`
   - `s3:ListBucket`

### Google Cloud Storage

Configure GCS for file storage:

```yaml
# config/production.yaml
storage:
  gcs:
    bucket: 'your-bucket-name'
    publicHost: 'storage.googleapis.com/your-bucket-name'
```

**GCS Credentials**:

1. Create service account in Google Cloud Console
2. Generate HMAC keys (Interoperability settings)
3. Add to `passwords.yaml`:

```yaml
production:
  gcsAccessKeyId: 'YOUR_GCS_ACCESS_KEY'
  gcsSecretAccessKey: 'YOUR_GCS_SECRET'
```

**GCS Bucket Setup**:

1. Create bucket in Google Cloud Console
2. Configure CORS:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "PUT", "POST"],
    "responseHeader": ["Content-Type"],
    "maxAgeSeconds": 3600
  }
]
```

3. Set bucket permissions for service account

### CloudFront CDN (Optional)

Use CloudFront with S3 for better performance:

```yaml
# config/production.yaml
storage:
  s3:
    bucket: 'your-bucket-name'
    region: 'us-east-1'
    publicHost: 'your-distribution.cloudfront.net'
    cloudFront:
      distributionId: 'YOUR_DISTRIBUTION_ID'
      publicKeyId: 'YOUR_KEY_ID'
      privateKey: |
        -----BEGIN PRIVATE KEY-----
        Your private key
        -----END PRIVATE KEY-----
```

CloudFront provides:
- Global content delivery
- HTTPS support
- Custom domain names
- Edge caching

## Upload Workflow

The secure three-step upload process.

### Step 1: Create Upload Description

Server creates an upload description granting permission:

```dart
// lib/src/endpoints/upload_endpoint.dart
import 'package:serverpod/serverpod.dart';

class UploadEndpoint extends Endpoint {
  Future<String> createUploadUrl(
    Session session,
    String fileName,
  ) async {
    // Authenticate user
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Authentication required');
    }

    var userId = session.auth!.userId!;

    // Create upload description
    var uploadDescription = await session.storage.createDirectFileUploadDescription(
      storageId: 'public',
      path: 'uploads/$userId/$fileName',
    );

    return uploadDescription.url;
  }
}
```

**Storage ID**: Identifies which storage backend to use. Common values:
- `'public'`: Publicly accessible files
- `'private'`: Private files requiring authentication
- Custom storage IDs for different buckets/purposes

**Path**: File path in storage. Best practices:
- Avoid leading slashes: `uploads/user/file.jpg` (not `/uploads/user/file.jpg`)
- Include user ID for organization: `uploads/$userId/avatar.jpg`
- Include timestamps for uniqueness: `uploads/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName`

### Step 2: Client Upload

Client uploads file to the provided URL:

```dart
// Flutter client
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  final Client client;

  FileUploadService(this.client);

  Future<void> uploadImage() async {
    // Pick image
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery);

    if (imageFile == null) return;

    try {
      // Get upload URL from server
      var uploadUrl = await client.upload.createUploadUrl(imageFile.name);

      // Read file bytes
      var bytes = await imageFile.readAsBytes();

      // Upload to storage
      var response = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {
          'Content-Type': 'image/jpeg',
        },
      );

      if (response.statusCode == 200) {
        // Verify upload with server
        await client.upload.verifyUpload(imageFile.name);
        print('Upload successful');
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }
}
```

**Using Streams for Large Files**:

```dart
Future<void> uploadLargeFile(File file) async {
  var uploadUrl = await client.upload.createUploadUrl(file.path.split('/').last);

  var request = http.StreamedRequest('PUT', Uri.parse(uploadUrl));
  request.headers['Content-Type'] = 'application/octet-stream';
  request.contentLength = await file.length();

  // Stream file to avoid loading entire file in memory
  var fileStream = file.openRead();
  fileStream.pipe(request.sink);

  var response = await request.send();

  if (response.statusCode == 200) {
    await client.upload.verifyUpload(file.path.split('/').last);
  }
}
```

### Step 3: Verify Upload

Server verifies upload completion:

```dart
class UploadEndpoint extends Endpoint {
  Future<void> verifyUpload(Session session, String fileName) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Authentication required');
    }

    var userId = session.auth!.userId!;
    var filePath = 'uploads/$userId/$fileName';

    // Verify upload
    var verified = await session.storage.verifyDirectFileUpload(
      storageId: 'public',
      path: filePath,
    );

    if (!verified) {
      throw Exception('Upload verification failed');
    }

    // Save file metadata to database
    var fileRecord = UploadedFile(
      userId: userId,
      fileName: fileName,
      filePath: filePath,
      uploadedAt: DateTime.now(),
    );

    await UploadedFile.db.insertRow(session, fileRecord);
  }
}
```

**Verification Importance**:
- Confirms file was actually uploaded
- Prevents orphaned upload descriptions
- Enables tracking in database
- Allows cleanup of failed uploads

## File Access

Retrieve and serve uploaded files.

### Checking File Existence

```dart
Future<bool> checkFileExists(Session session, String filePath) async {
  return await session.storage.fileExists(
    storageId: 'public',
    path: filePath,
  );
}
```

### Getting Public URLs

For public files, generate access URLs:

```dart
Future<String> getFileUrl(Session session, String filePath) async {
  var url = await session.storage.getPublicUrl(
    storageId: 'public',
    path: filePath,
  );

  return url ?? '';
}
```

**Client Usage**:

```dart
class ProfileImageWidget extends StatelessWidget {
  final Client client;
  final int userId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: client.upload.getUserProfileImageUrl(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        return Image.network(snapshot.data!);
      },
    );
  }
}
```

### Retrieving File Content

Download file content directly:

```dart
Future<ByteData?> downloadFile(Session session, String filePath) async {
  return await session.storage.retrieveFile(
    storageId: 'public',
    path: filePath,
  );
}
```

### Signed URLs for Private Files

Generate time-limited access URLs for private files:

```dart
Future<String> getPrivateFileUrl(
  Session session,
  int fileId,
) async {
  if (!session.isUserSignedIn) {
    throw UnauthorizedException('Authentication required');
  }

  var userId = session.auth!.userId!;

  // Verify user owns file
  var file = await UploadedFile.db.findById(session, fileId);

  if (file == null || file.userId != userId) {
    throw ForbiddenException('Access denied');
  }

  // Generate signed URL valid for 1 hour
  var signedUrl = await session.storage.getSignedUrl(
    storageId: 'private',
    path: file.filePath,
    expiresIn: Duration(hours: 1),
  );

  return signedUrl;
}
```

## File Validation

Validate files before and after upload.

### Size Limits

Restrict file sizes:

```dart
Future<String> createUploadUrl(
  Session session,
  String fileName,
  int fileSize,
) async {
  // Validate size (10MB limit)
  const maxSize = 10 * 1024 * 1024;
  if (fileSize > maxSize) {
    throw ValidationException('File too large (max 10MB)');
  }

  // Create upload description
  var uploadDescription = await session.storage.createDirectFileUploadDescription(
    storageId: 'public',
    path: 'uploads/${session.auth!.userId!}/$fileName',
  );

  return uploadDescription.url;
}
```

### MIME Type Validation

Restrict file types:

```dart
Future<String> createImageUploadUrl(
  Session session,
  String fileName,
  String mimeType,
) async {
  // Validate MIME type
  const allowedTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  if (!allowedTypes.contains(mimeType)) {
    throw ValidationException('Invalid file type. Only images allowed.');
  }

  var uploadDescription = await session.storage.createDirectFileUploadDescription(
    storageId: 'public',
    path: 'images/${session.auth!.userId!}/$fileName',
  );

  return uploadDescription.url;
}
```

### File Extension Validation

```dart
bool isAllowedExtension(String fileName) {
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

  return allowedExtensions.any((ext) =>
      fileName.toLowerCase().endsWith(ext));
}

Future<String> createUploadUrl(
  Session session,
  String fileName,
) async {
  if (!isAllowedExtension(fileName)) {
    throw ValidationException('File type not allowed');
  }

  // Create upload
}
```

### Content Validation After Upload

Validate file content after upload:

```dart
Future<void> verifyUpload(Session session, String fileName) async {
  var filePath = 'uploads/${session.auth!.userId!}/$fileName';

  // Verify upload
  var verified = await session.storage.verifyDirectFileUpload(
    storageId: 'public',
    path: filePath,
  );

  if (!verified) {
    throw Exception('Upload verification failed');
  }

  // Download and validate content
  var content = await session.storage.retrieveFile(
    storageId: 'public',
    path: filePath,
  );

  if (content == null) {
    throw Exception('Failed to retrieve uploaded file');
  }

  // Validate image dimensions (example)
  if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
    var image = img.decodeImage(content.buffer.asUint8List());

    if (image == null) {
      // Invalid image, delete it
      await session.storage.deleteFile(
        storageId: 'public',
        path: filePath,
      );
      throw ValidationException('Invalid image file');
    }

    if (image.width > 4096 || image.height > 4096) {
      await session.storage.deleteFile(
        storageId: 'public',
        path: filePath,
      );
      throw ValidationException('Image dimensions too large (max 4096x4096)');
    }
  }

  // Save metadata
  await UploadedFile.db.insertRow(
    session,
    UploadedFile(
      userId: session.auth!.userId!,
      fileName: fileName,
      filePath: filePath,
      uploadedAt: DateTime.now(),
    ),
  );
}
```

## File Management

Organize and manage uploaded files.

### Deleting Files

```dart
Future<void> deleteFile(Session session, int fileId) async {
  if (!session.isUserSignedIn) {
    throw UnauthorizedException('Authentication required');
  }

  var userId = session.auth!.userId!;

  // Get file record
  var file = await UploadedFile.db.findById(session, fileId);

  if (file == null) {
    throw NotFoundException('File not found');
  }

  if (file.userId != userId) {
    throw ForbiddenException('Cannot delete another user\'s file');
  }

  // Delete from storage
  await session.storage.deleteFile(
    storageId: 'public',
    path: file.filePath,
  );

  // Delete from database
  await UploadedFile.db.deleteRow(session, file);
}
```

### Listing User Files

```dart
Future<List<UploadedFile>> getUserFiles(Session session) async {
  if (!session.isUserSignedIn) {
    throw UnauthorizedException('Authentication required');
  }

  var userId = session.auth!.userId!;

  return await UploadedFile.db.find(
    session,
    where: (t) => t.userId.equals(userId),
    orderBy: (t) => -t.uploadedAt,
  );
}
```

### Moving Files

```dart
Future<void> moveFile(
  Session session,
  String sourcePath,
  String destinationPath,
) async {
  // Download file
  var content = await session.storage.retrieveFile(
    storageId: 'public',
    path: sourcePath,
  );

  if (content == null) {
    throw NotFoundException('Source file not found');
  }

  // Upload to new location
  // Note: Direct copy not supported, must download and re-upload
  var uploadDesc = await session.storage.createDirectFileUploadDescription(
    storageId: 'public',
    path: destinationPath,
  );

  // Upload content to new path
  // (Would be done via client in real scenario)

  // Delete original
  await session.storage.deleteFile(
    storageId: 'public',
    path: sourcePath,
  );
}
```

## Complete Upload Example

Full implementation with progress tracking:

```dart
// Server endpoint
class FileUploadEndpoint extends Endpoint {
  Future<UploadDescriptionResponse> requestUpload(
    Session session,
    String fileName,
    int fileSize,
    String mimeType,
  ) async {
    // Authenticate
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Authentication required');
    }

    // Validate
    if (fileSize > 10 * 1024 * 1024) {
      throw ValidationException('File too large (max 10MB)');
    }

    if (!mimeType.startsWith('image/')) {
      throw ValidationException('Only images allowed');
    }

    var userId = session.auth!.userId!;
    var timestamp = DateTime.now().millisecondsSinceEpoch;
    var filePath = 'uploads/$userId/${timestamp}_$fileName';

    // Create upload description
    var description = await session.storage.createDirectFileUploadDescription(
      storageId: 'public',
      path: filePath,
    );

    return UploadDescriptionResponse(
      uploadUrl: description.url,
      filePath: filePath,
    );
  }

  Future<FileInfo> completeUpload(
    Session session,
    String filePath,
  ) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Authentication required');
    }

    // Verify
    var verified = await session.storage.verifyDirectFileUpload(
      storageId: 'public',
      path: filePath,
    );

    if (!verified) {
      throw Exception('Upload verification failed');
    }

    // Save record
    var file = UploadedFile(
      userId: session.auth!.userId!,
      fileName: filePath.split('/').last,
      filePath: filePath,
      uploadedAt: DateTime.now(),
    );

    file = await UploadedFile.db.insertRow(session, file);

    // Get public URL
    var url = await session.storage.getPublicUrl(
      storageId: 'public',
      path: filePath,
    );

    return FileInfo(
      id: file.id!,
      url: url ?? '',
      fileName: file.fileName,
    );
  }
}

// Flutter client with progress
class FileUploadWidget extends StatefulWidget {
  final Client client;

  @override
  _FileUploadWidgetState createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  double _uploadProgress = 0.0;
  bool _uploading = false;

  Future<void> _uploadFile() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Get file info
      var fileSize = await image.length();
      var mimeType = 'image/jpeg';

      // Request upload
      var uploadInfo = await widget.client.fileUpload.requestUpload(
        image.name,
        fileSize,
        mimeType,
      );

      // Upload file with progress
      var bytes = await image.readAsBytes();
      var request = http.StreamedRequest('PUT', Uri.parse(uploadInfo.uploadUrl));
      request.headers['Content-Type'] = mimeType;
      request.contentLength = bytes.length;

      // Track progress
      var bytesUploaded = 0;
      request.sink.addStream(
        Stream.fromIterable(bytes.map((byte) => [byte])).transform(
          StreamTransformer.fromHandlers(
            handleData: (chunk, sink) {
              bytesUploaded += chunk.length;
              setState(() {
                _uploadProgress = bytesUploaded / bytes.length;
              });
              sink.add(chunk);
            },
          ),
        ),
      );

      await request.sink.close();
      var response = await request.send();

      if (response.statusCode == 200) {
        // Complete upload
        var fileInfo = await widget.client.fileUpload.completeUpload(
          uploadInfo.filePath,
        );

        print('Upload complete: ${fileInfo.url}');
      }
    } catch (e) {
      print('Upload failed: $e');
    } finally {
      setState(() {
        _uploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_uploading)
          LinearProgressIndicator(value: _uploadProgress)
        else
          ElevatedButton(
            onPressed: _uploadFile,
            child: Text('Upload Image'),
          ),
      ],
    );
  }
}
```

Serverpod's file upload system provides enterprise-grade file handling with flexibility to use the storage backend that best fits your application's needs.
