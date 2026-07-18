# Hive NoSQL Database in Flutter

Hive is a lightweight, blazing-fast NoSQL database written in pure Dart for Flutter applications. Unlike SQLite, Hive requires no native dependencies and works seamlessly across mobile, desktop, and web platforms. It stores data in boxes—key-value stores that can hold primitives, lists, maps, or custom Dart objects with type safety through code-generated adapters.

## Core Concepts

Hive organizes data into boxes, which are persistent key-value stores. Think of boxes as tables, but without schemas or relationships. Each box can store values of the same or different types, accessed by unique keys. Hive excels at fast read/write operations, offline-first applications, and scenarios where relational queries aren't needed.

The pure Dart implementation eliminates platform-specific build issues and ensures consistent behavior across all Flutter targets. Hive's binary format provides compact storage and fast serialization, making it ideal for caching API responses, storing user preferences, and managing app state.

## Installation and Setup

Add Hive and code generation dependencies:

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
```

Initialize Hive before use:

```dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters for custom types
  Hive.registerAdapter(PersonAdapter());

  // Open boxes
  await Hive.openBox('settings');
  await Hive.openBox<Person>('people');

  runApp(const MyApp());
}
```

For desktop platforms, use a custom path:

```dart
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  await Hive.openBox('myBox');
  runApp(const MyApp());
}
```

## Working with Boxes

### Opening Boxes

Open boxes before accessing data:

```dart
// Open a box (creates if doesn't exist)
final box = await Hive.openBox('myBox');

// Open a type-safe box
final peopleBox = await Hive.openBox<Person>('people');

// Open in lazy mode (loads values on demand)
final lazyBox = await Hive.openLazyBox('lazyBox');
```

### Accessing Boxes

Retrieve previously opened boxes:

```dart
// Get an already open box
final box = Hive.box('myBox');

// Check if box is open
if (!Hive.isBoxOpen('myBox')) {
  await Hive.openBox('myBox');
}
```

### Closing Boxes

Close boxes to free resources:

```dart
// Close a specific box
await box.close();

// Close all boxes
await Hive.close();
```

## Basic CRUD Operations

### Writing Data

Store values with put operations:

```dart
final box = Hive.box('myBox');

// Put with auto-generated key
await box.add('value'); // Returns generated key

// Put with custom key
await box.put('name', 'John Doe');
await box.put('age', 30);
await box.put('settings', {'theme': 'dark', 'notifications': true});

// Put multiple values
await box.putAll({
  'username': 'johndoe',
  'email': 'john@example.com',
  'verified': true,
});
```

### Reading Data

Retrieve values using keys:

```dart
// Get a value
final name = box.get('name'); // Returns dynamic
final age = box.get('age', defaultValue: 0); // With default

// Get with type safety
final String? username = box.get('username') as String?;

// Check if key exists
if (box.containsKey('name')) {
  print('Name exists');
}

// Get all keys
final keys = box.keys; // Iterable<dynamic>

// Get all values
final values = box.values; // Iterable<dynamic>

// Get all entries
final entries = box.toMap(); // Map<dynamic, dynamic>
```

### Updating Data

Update existing values:

```dart
// Update overwrites existing value
await box.put('name', 'Jane Doe');

// Update nested values (for maps)
final settings = box.get('settings') as Map;
settings['theme'] = 'light';
await box.put('settings', settings);
```

### Deleting Data

Remove data from boxes:

```dart
// Delete a single key
await box.delete('name');

// Delete multiple keys
await box.deleteAll(['name', 'age', 'email']);

// Clear all data in box
await box.clear();

// Delete box from disk
await box.deleteFromDisk();
```

## Type Adapters

Type adapters enable storing custom Dart objects in Hive with type safety and efficient serialization.

### Defining Custom Types

Annotate your classes with `@HiveType`:

```dart
import 'package:hive/hive.dart';

part 'person.g.dart'; // Generated file

@HiveType(typeId: 0)
class Person extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int age;

  @HiveField(2)
  String? email;

  Person({
    required this.name,
    required this.age,
    this.email,
  });
}
```

TypeId must be unique across your app (0-223). Field numbers must be unique within the class.

### Generating Adapters

Run the build runner to generate adapters:

```bash
flutter packages pub run build_runner build
# Or watch for changes
flutter packages pub run build_runner watch
```

This generates `person.g.dart` with the PersonAdapter class.

### Registering Adapters

Register adapters before opening boxes:

```dart
void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PersonAdapter());

  await Hive.openBox<Person>('people');
  runApp(const MyApp());
}
```

### Using Custom Types

Store and retrieve custom objects:

```dart
final peopleBox = Hive.box<Person>('people');

// Add person
final person = Person(name: 'John', age: 30);
await peopleBox.add(person);

// Add with custom key
await peopleBox.put('john_doe', person);

// Retrieve person
final retrieved = peopleBox.get('john_doe');
print(retrieved?.name); // John

// List all people
final allPeople = peopleBox.values.toList();
```

### HiveObject Extension

Extending HiveObject provides convenience methods:

```dart
@HiveType(typeId: 0)
class Person extends HiveObject {
  @HiveField(0)
  String name;

  Person({required this.name});
}

// Usage
final person = Person(name: 'John');
await peopleBox.add(person);

// Update using save()
person.name = 'Jane';
await person.save(); // Automatically saves to box

// Delete using delete()
await person.delete(); // Removes from box

// Get key
final key = person.key; // Auto-assigned key
```

## Advanced Type Adapters

### Nested Objects

Create adapters for nested custom types:

```dart
@HiveType(typeId: 1)
class Address {
  @HiveField(0)
  String street;

  @HiveField(1)
  String city;

  Address({required this.street, required this.city});
}

@HiveType(typeId: 2)
class Person {
  @HiveField(0)
  String name;

  @HiveField(1)
  Address address; // Nested custom type

  Person({required this.name, required this.address});
}

// Register both adapters
Hive.registerAdapter(AddressAdapter());
Hive.registerAdapter(PersonAdapter());
```

### Enums

Store enums using type adapters:

```dart
@HiveType(typeId: 3)
enum Role {
  @HiveField(0)
  admin,

  @HiveField(1)
  user,

  @HiveField(2)
  guest,
}

// Register adapter
Hive.registerAdapter(RoleAdapter());

// Usage
await box.put('role', Role.admin);
final role = box.get('role') as Role;
```

### Custom Adapters

Write custom adapters for types you don't control:

```dart
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final typeId = 10;

  @override
  DateTime read(BinaryReader reader) {
    final milliseconds = reader.readInt();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}

// Register
Hive.registerAdapter(DateTimeAdapter());
```

## Encryption

Secure sensitive data with AES-256 encryption:

```dart
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Generate or retrieve encryption key
Future<List<int>> getEncryptionKey() async {
  const secureStorage = FlutterSecureStorage();
  var key = await secureStorage.read(key: 'hive_encryption_key');

  if (key == null) {
    final newKey = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key',
      value: base64Url.encode(newKey),
    );
    return newKey;
  }

  return base64Url.decode(key);
}

// Open encrypted box
Future<void> openSecureBox() async {
  final encryptionKey = await getEncryptionKey();
  final encryptedBox = await Hive.openBox(
    'secureBox',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
}
```

Store encryption keys securely using flutter_secure_storage or platform keychain/keystore.

## Lazy Boxes

Lazy boxes load values on demand, reducing memory usage for large datasets:

```dart
// Open lazy box
final lazyBox = await Hive.openLazyBox('largeData');

// Put operations are the same
await lazyBox.put('key', 'value');

// Get requires await
final value = await lazyBox.get('key'); // Returns Future

// Check keys without loading values
final keys = lazyBox.keys;

// Close when done
await lazyBox.close();
```

Use lazy boxes when:
- Box contains large objects
- Not all values are accessed frequently
- Memory efficiency is critical

## Watching for Changes

Listen to box changes reactively:

```dart
final box = Hive.box('settings');

// Listen to all changes
box.watch().listen((event) {
  print('Key: ${event.key}');
  print('Value: ${event.value}');
  print('Deleted: ${event.deleted}');
});

// Listen to specific key
box.watch(key: 'theme').listen((event) {
  print('Theme changed to: ${event.value}');
});
```

### Integration with State Management

Use box watchers with Provider:

```dart
class SettingsProvider extends ChangeNotifier {
  final Box box;
  StreamSubscription? _subscription;

  SettingsProvider(this.box) {
    _subscription = box.watch().listen((_) {
      notifyListeners();
    });
  }

  String get theme => box.get('theme', defaultValue: 'light');

  Future<void> setTheme(String theme) async {
    await box.put('theme', theme);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## Box Compaction

Hive automatically compacts boxes, but manual compaction improves performance:

```dart
// Compact box (removes deleted entries)
await box.compact();

// Compaction happens automatically when:
// - Box size grows significantly
// - Many deletions occur
```

## Performance Optimization

### Use Appropriate Box Types

```dart
// Regular box: All values in memory
final regularBox = await Hive.openBox('regular');

// Lazy box: Values loaded on demand
final lazyBox = await Hive.openLazyBox('lazy');
```

### Batch Operations

Group operations for better performance:

```dart
// Inefficient: Multiple put operations
for (var i = 0; i < 1000; i++) {
  await box.put('key$i', 'value$i');
}

// Efficient: Single putAll operation
final entries = {
  for (var i = 0; i < 1000; i++) 'key$i': 'value$i'
};
await box.putAll(entries);
```

### Box Organization

Split data into multiple boxes by domain:

```dart
// Instead of one box for everything
await Hive.openBox('data');

// Use separate boxes
await Hive.openBox('users');
await Hive.openBox('posts');
await Hive.openBox('settings');
```

### Indexed Access

Access values by index for ordered data:

```dart
final box = await Hive.openBox('items');

// Add items (returns auto-generated key)
await box.add('item1');
await box.add('item2');

// Access by index
final firstItem = box.getAt(0);
final lastItem = box.getAt(box.length - 1);

// Update by index
await box.putAt(0, 'updated_item1');

// Delete by index
await box.deleteAt(0);
```

## Migration Strategies

### Version-Based Migration

Handle schema changes with versioning:

```dart
class MigrationService {
  static const _versionKey = 'schema_version';
  static const _currentVersion = 2;

  static Future<void> migrate(Box box) async {
    final version = box.get(_versionKey, defaultValue: 0);

    if (version < 1) {
      await _migrateToV1(box);
    }
    if (version < 2) {
      await _migrateToV2(box);
    }

    await box.put(_versionKey, _currentVersion);
  }

  static Future<void> _migrateToV1(Box box) async {
    // Add default settings
    await box.put('theme', 'light');
  }

  static Future<void> _migrateToV2(Box box) async {
    // Convert old data format
    final oldValue = box.get('old_key');
    if (oldValue != null) {
      await box.put('new_key', transformData(oldValue));
      await box.delete('old_key');
    }
  }
}

// Apply migration
final box = await Hive.openBox('settings');
await MigrationService.migrate(box);
```

### Type Adapter Versioning

Support multiple versions in type adapters:

```dart
class PersonAdapterV2 extends TypeAdapter<Person> {
  @override
  final typeId = 0;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++)
        reader.readByte(): reader.read(),
    };

    return Person(
      name: fields[0] as String,
      age: fields[1] as int,
      email: fields[2] as String?, // New field
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(3) // Number of fields
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.email);
  }
}
```

## Repository Pattern with Hive

Encapsulate Hive operations in repositories:

```dart
class UserRepository {
  static const _boxName = 'users';
  Box<User>? _box;

  Future<Box<User>> get box async {
    _box ??= await Hive.openBox<User>(_boxName);
    return _box!;
  }

  Future<void> save(User user) async {
    final b = await box;
    await b.put(user.id, user);
  }

  Future<User?> findById(String id) async {
    final b = await box;
    return b.get(id);
  }

  Future<List<User>> findAll() async {
    final b = await box;
    return b.values.toList();
  }

  Future<void> delete(String id) async {
    final b = await box;
    await b.delete(id);
  }

  Stream<BoxEvent> watch() async* {
    final b = await box;
    yield* b.watch();
  }
}
```

## Testing

Test Hive operations using in-memory boxes:

```dart
void main() {
  setUp(() async {
    // Use temporary directory
    final tempDir = await getTemporaryDirectory();
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteBoxFromDisk('testBox');
  });

  test('save and retrieve user', () async {
    final box = await Hive.openBox<User>('testBox');
    final user = User(id: '1', name: 'Test');

    await box.put(user.id, user);
    final retrieved = box.get(user.id);

    expect(retrieved?.name, 'Test');
  });
}
```

## Common Patterns

### Cache with Expiration

Implement TTL-based caching:

```dart
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  CacheEntry(this.data, this.timestamp);
}

class HiveCache {
  final Box _box;
  final Duration ttl;

  HiveCache(this._box, {this.ttl = const Duration(hours: 1)});

  Future<void> put(String key, dynamic data) async {
    final entry = CacheEntry(data, DateTime.now());
    await _box.put(key, entry);
  }

  dynamic get(String key) {
    final entry = _box.get(key) as CacheEntry?;
    if (entry == null) return null;

    final age = DateTime.now().difference(entry.timestamp);
    if (age > ttl) {
      _box.delete(key);
      return null;
    }

    return entry.data;
  }
}
```

### Offline-First Storage

Store API responses for offline access:

```dart
class ApiRepository {
  final Box _cache;
  final ApiClient _client;

  ApiRepository(this._cache, this._client);

  Future<List<Post>> getPosts() async {
    try {
      final posts = await _client.fetchPosts();
      await _cache.put('posts', posts);
      return posts;
    } catch (e) {
      // Return cached data on network error
      final cached = _cache.get('posts') as List<Post>?;
      return cached ?? [];
    }
  }
}
```

## Platform Considerations

### Web Support
Hive uses IndexedDB on web with identical API. Performance characteristics differ from mobile due to IndexedDB limitations.

### Desktop Support
Works on Windows, Linux, and macOS with identical behavior to mobile. Use `Hive.init(path)` to set storage location.

### Mobile Support
Native performance on iOS and Android with file-based storage in app documents directory.

## Best Practices

Use type-safe boxes (`Box<T>`) instead of dynamic boxes for compile-time safety. Register all type adapters before opening boxes. Close boxes when not needed to free resources. Use lazy boxes for large datasets.

Organize data into multiple boxes by domain rather than one monolithic box. Implement versioning for schema changes. Use encryption for sensitive data with secure key storage.

Batch operations with `putAll` instead of individual `put` calls. Compact boxes periodically to reclaim space. Watch boxes for reactive updates rather than polling.

## Common Pitfalls

Forgetting to register type adapters before opening boxes causes runtime errors. Using the same typeId for different classes corrupts data. Not handling migration causes crashes on schema changes.

Opening too many boxes simultaneously increases memory usage. Storing very large objects in regular boxes causes memory issues. Not closing boxes leads to resource leaks.

Using dynamic keys inconsistently makes data hard to query. Storing relational data that should use SQLite. Not implementing proper error handling for disk I/O operations.

## When to Choose Hive

Choose Hive when:
- You need fast key-value storage across all platforms including web
- Data doesn't require complex relational queries
- You want pure Dart solution without native dependencies
- Offline-first functionality is priority
- Type safety with custom objects is important

Avoid Hive when:
- Data has complex relationships requiring joins
- You need full SQL query capabilities
- Dataset is extremely large (millions of records)
- You require ACID transactions across multiple operations

Hive provides an excellent balance of performance, ease of use, and cross-platform compatibility for most Flutter persistence needs that don't require relational databases.
