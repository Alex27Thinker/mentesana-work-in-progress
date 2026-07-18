# SQLite with sqflite in Flutter

sqflite is Flutter's primary plugin for SQLite database access, providing a self-contained, high-reliability, embedded SQL database engine for mobile and desktop applications. It brings ACID-compliant transactional database capabilities to Flutter with support for complex queries, relationships, and data integrity.

## Core Concepts

SQLite is a relational database that stores structured data in tables with defined schemas. Unlike client-server databases, SQLite is embedded directly in the application, requiring no separate database process. This makes it perfect for mobile apps where data needs structure, relationships, and complex querying capabilities.

sqflite provides a Dart wrapper around SQLite's native implementations, handling platform differences while exposing a consistent async API. It supports iOS, Android, and macOS natively, with Windows and Linux support through sqflite_common_ffi using Foreign Function Interface.

## Installation and Setup

Add sqflite and path to your pubspec.yaml:

```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.9.0  # For database path handling
```

For Windows and Linux desktop support, also add:

```yaml
dependencies:
  sqflite_common_ffi: ^2.3.0
```

Initialize desktop support in your main function:

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI for desktop platforms
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}
```

## Database Initialization

### Opening a Database

Create and open a database with version management:

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<Database> initDatabase() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'app_database.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: _createDb,
    onUpgrade: _upgradeDb,
  );
}

Future<void> _createDb(Database db, int version) async {
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      created_at INTEGER NOT NULL
    )
  ''');
}
```

### Database Configuration

Configure database behavior during opening:

```dart
Future<Database> openConfiguredDatabase() async {
  final path = join(await getDatabasesPath(), 'app.db');

  return await openDatabase(
    path,
    version: 1,
    onCreate: _createDb,
    onConfigure: (db) async {
      // Enable foreign keys (disabled by default in SQLite)
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onOpen: (db) async {
      // Run on every open
      print('Database opened');
    },
  );
}
```

### Read-Only Access

Open a database in read-only mode:

```dart
final db = await openReadOnlyDatabase(path);
```

## CRUD Operations

### Insert

Insert data with automatic ID generation:

```dart
Future<int> insertUser(Database db, Map<String, dynamic> user) async {
  return await db.insert(
    'users',
    user,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

// Usage
final userId = await insertUser(db, {
  'name': 'John Doe',
  'email': 'john@example.com',
  'created_at': DateTime.now().millisecondsSinceEpoch,
});
```

The `conflictAlgorithm` parameter controls behavior when constraints are violated:
- `ConflictAlgorithm.replace` - Replace existing row
- `ConflictAlgorithm.ignore` - Ignore the insert
- `ConflictAlgorithm.abort` - Abort transaction (default)
- `ConflictAlgorithm.fail` - Fail the operation
- `ConflictAlgorithm.rollback` - Rollback the transaction

### Query

Retrieve data with optional filtering and ordering:

```dart
Future<List<Map<String, dynamic>>> getAllUsers(Database db) async {
  return await db.query('users');
}

Future<List<Map<String, dynamic>>> getUsersByName(
  Database db,
  String name,
) async {
  return await db.query(
    'users',
    where: 'name LIKE ?',
    whereArgs: ['%$name%'],
    orderBy: 'created_at DESC',
    limit: 10,
  );
}

Future<Map<String, dynamic>?> getUserById(Database db, int id) async {
  final results = await db.query(
    'users',
    where: 'id = ?',
    whereArgs: [id],
    limit: 1,
  );
  return results.isNotEmpty ? results.first : null;
}
```

### Update

Modify existing records:

```dart
Future<int> updateUser(
  Database db,
  int id,
  Map<String, dynamic> updates,
) async {
  return await db.update(
    'users',
    updates,
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Usage
final rowsAffected = await updateUser(db, userId, {
  'name': 'Jane Doe',
});
```

### Delete

Remove records from the database:

```dart
Future<int> deleteUser(Database db, int id) async {
  return await db.delete(
    'users',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> deleteOldUsers(Database db, DateTime cutoff) async {
  return await db.delete(
    'users',
    where: 'created_at < ?',
    whereArgs: [cutoff.millisecondsSinceEpoch],
  );
}
```

## Raw SQL Queries

Execute arbitrary SQL for complex queries:

```dart
// Raw query
Future<List<Map<String, dynamic>>> getUsersWithPosts(Database db) async {
  return await db.rawQuery('''
    SELECT u.*, COUNT(p.id) as post_count
    FROM users u
    LEFT JOIN posts p ON u.id = p.user_id
    GROUP BY u.id
    HAVING post_count > 0
    ORDER BY post_count DESC
  ''');
}

// Raw insert/update/delete
Future<int> rawInsert(Database db) async {
  return await db.rawInsert(
    'INSERT INTO users (name, email, created_at) VALUES (?, ?, ?)',
    ['John Doe', 'john@example.com', DateTime.now().millisecondsSinceEpoch],
  );
}

// Raw execute (no return value)
Future<void> createIndex(Database db) async {
  await db.execute('CREATE INDEX idx_user_email ON users(email)');
}
```

## Transactions

Transactions ensure multiple operations succeed or fail atomically:

```dart
Future<void> transferPoints(
  Database db,
  int fromUserId,
  int toUserId,
  int points,
) async {
  await db.transaction((txn) async {
    // Deduct points from sender
    await txn.rawUpdate(
      'UPDATE users SET points = points - ? WHERE id = ?',
      [points, fromUserId],
    );

    // Add points to receiver
    await txn.rawUpdate(
      'UPDATE users SET points = points + ? WHERE id = ?',
      [points, toUserId],
    );

    // Record transaction
    await txn.insert('transactions', {
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'points': points,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  });
}
```

Transactions automatically roll back if any operation fails:

```dart
try {
  await db.transaction((txn) async {
    await txn.insert('users', userData);
    throw Exception('Simulated error');
    await txn.insert('posts', postData); // Never executes
  });
} catch (e) {
  // All changes rolled back
  print('Transaction failed: $e');
}
```

## Batch Operations

Batch multiple operations for better performance:

```dart
Future<void> batchInsertUsers(
  Database db,
  List<Map<String, dynamic>> users,
) async {
  final batch = db.batch();

  for (final user in users) {
    batch.insert('users', user);
  }

  // Execute all operations
  await batch.commit(noResult: true);
}

Future<List<Object?>> batchWithResults(Database db) async {
  final batch = db.batch();

  batch.insert('users', {'name': 'User 1', 'email': 'user1@example.com'});
  batch.insert('users', {'name': 'User 2', 'email': 'user2@example.com'});
  batch.query('users', where: 'name LIKE ?', whereArgs: ['User%']);

  // Returns results for each operation
  final results = await batch.commit();
  return results;
}
```

Batches within transactions combine benefits of both:

```dart
await db.transaction((txn) async {
  final batch = txn.batch();

  for (final user in users) {
    batch.insert('users', user);
  }

  await batch.commit();
});
```

## Database Migrations

Handle schema changes across app versions:

```dart
Future<Database> openDatabaseWithMigrations() async {
  final path = join(await getDatabasesPath(), 'app.db');

  return await openDatabase(
    path,
    version: 3,
    onCreate: (db, version) async {
      // Create latest schema
      await _createDbV3(db);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Handle incremental upgrades
      if (oldVersion < 2) {
        await _upgradeToV2(db);
      }
      if (oldVersion < 3) {
        await _upgradeToV3(db);
      }
    },
    onDowngrade: (db, oldVersion, newVersion) async {
      // Handle version rollback (rare)
      await _handleDowngrade(db, oldVersion, newVersion);
    },
  );
}

Future<void> _createDbV3(Database db) async {
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      phone TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
  ''');
}

Future<void> _upgradeToV2(Database db) async {
  // Add phone column
  await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
}

Future<void> _upgradeToV3(Database db) async {
  // Add updated_at column with default value
  await db.execute('''
    ALTER TABLE users ADD COLUMN updated_at INTEGER
    DEFAULT (strftime('%s', 'now') * 1000)
  ''');

  // Create posts table
  await db.execute('''
    CREATE TABLE posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
  ''');
}
```

## Advanced Migration Patterns

### Preserving Data During Column Changes

SQLite doesn't support all ALTER TABLE operations. To modify columns, use a temporary table:

```dart
Future<void> changeColumnType(Database db) async {
  await db.transaction((txn) async {
    // Create new table with desired schema
    await txn.execute('''
      CREATE TABLE users_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        age INTEGER  -- Changed from TEXT to INTEGER
      )
    ''');

    // Copy data with type conversion
    await txn.execute('''
      INSERT INTO users_new (id, name, email, age)
      SELECT id, name, email, CAST(age AS INTEGER)
      FROM users
    ''');

    // Drop old table
    await txn.execute('DROP TABLE users');

    // Rename new table
    await txn.execute('ALTER TABLE users_new RENAME TO users');

    // Recreate indexes
    await txn.execute('CREATE INDEX idx_user_email ON users(email)');
  });
}
```

### Migration with Data Transformation

Transform data during migration:

```dart
Future<void> migrateWithTransformation(Database db) async {
  // Add normalized_email column
  await db.execute('ALTER TABLE users ADD COLUMN normalized_email TEXT');

  // Populate with normalized values
  final users = await db.query('users');
  for (final user in users) {
    final email = user['email'] as String;
    await db.update(
      'users',
      {'normalized_email': email.toLowerCase()},
      where: 'id = ?',
      whereArgs: [user['id']],
    );
  }

  // Add unique constraint (requires recreating table)
  // ... use temporary table pattern
}
```

## Repository Pattern

Encapsulate database operations in repository classes:

```dart
class UserRepository {
  final Database _db;

  UserRepository(this._db);

  Future<int> insert(User user) async {
    return await _db.insert('users', user.toMap());
  }

  Future<User?> findById(int id) async {
    final results = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  Future<List<User>> findAll({int? limit, int? offset}) async {
    final results = await _db.query(
      'users',
      limit: limit,
      offset: offset,
      orderBy: 'created_at DESC',
    );

    return results.map((map) => User.fromMap(map)).toList();
  }

  Future<int> update(User user) async {
    return await _db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<User>> search(String query) async {
    final results = await _db.query(
      'users',
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );

    return results.map((map) => User.fromMap(map)).toList();
  }
}

// Model class
class User {
  final int? id;
  final String name;
  final String email;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }
}
```

## Database Singleton

Ensure a single database instance across the app:

```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create tables
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

// Usage
final db = await DatabaseHelper.instance.database;
```

## Performance Optimization

### Indexing

Create indexes on frequently queried columns:

```dart
Future<void> createIndexes(Database db) async {
  await db.execute('CREATE INDEX idx_user_email ON users(email)');
  await db.execute('CREATE INDEX idx_post_user_id ON posts(user_id)');
  await db.execute('CREATE INDEX idx_post_created_at ON posts(created_at)');

  // Composite index for common query patterns
  await db.execute('''
    CREATE INDEX idx_post_user_created
    ON posts(user_id, created_at DESC)
  ''');
}
```

### Query Optimization

Use EXPLAIN QUERY PLAN to understand query execution:

```dart
Future<void> analyzeQuery(Database db) async {
  final plan = await db.rawQuery('''
    EXPLAIN QUERY PLAN
    SELECT * FROM users WHERE email = ?
  ''', ['test@example.com']);

  print('Query plan: $plan');
}
```

Optimize common patterns:

```dart
// Inefficient: Loading all rows then filtering in Dart
final allUsers = await db.query('users');
final active = allUsers.where((u) => u['active'] == 1).toList();

// Efficient: Filter in SQL
final active = await db.query('users', where: 'active = 1');
```

### Batch Loading

Load large datasets in batches to avoid memory issues:

```dart
Future<List<Map<String, dynamic>>> loadInBatches(
  Database db,
  int batchSize,
) async {
  final allData = <Map<String, dynamic>>[];
  var offset = 0;

  while (true) {
    final batch = await db.query(
      'users',
      limit: batchSize,
      offset: offset,
    );

    if (batch.isEmpty) break;

    allData.addAll(batch);
    offset += batchSize;
  }

  return allData;
}
```

## Full-Text Search

Implement full-text search using FTS5:

```dart
Future<void> createFTSTable(Database db) async {
  await db.execute('''
    CREATE VIRTUAL TABLE posts_fts USING fts5(
      title,
      content,
      content=posts,
      content_rowid=id
    )
  ''');

  // Create triggers to keep FTS table in sync
  await db.execute('''
    CREATE TRIGGER posts_fts_insert AFTER INSERT ON posts BEGIN
      INSERT INTO posts_fts(rowid, title, content)
      VALUES (new.id, new.title, new.content);
    END
  ''');

  await db.execute('''
    CREATE TRIGGER posts_fts_delete AFTER DELETE ON posts BEGIN
      DELETE FROM posts_fts WHERE rowid = old.id;
    END
  ''');

  await db.execute('''
    CREATE TRIGGER posts_fts_update AFTER UPDATE ON posts BEGIN
      DELETE FROM posts_fts WHERE rowid = old.id;
      INSERT INTO posts_fts(rowid, title, content)
      VALUES (new.id, new.title, new.content);
    END
  ''');
}

Future<List<Map<String, dynamic>>> searchPosts(
  Database db,
  String query,
) async {
  return await db.rawQuery('''
    SELECT p.*
    FROM posts p
    JOIN posts_fts fts ON p.id = fts.rowid
    WHERE posts_fts MATCH ?
    ORDER BY rank
  ''', [query]);
}
```

## Error Handling

Handle common database errors gracefully:

```dart
Future<void> safeInsert(Database db, Map<String, dynamic> data) async {
  try {
    await db.insert('users', data);
  } on DatabaseException catch (e) {
    if (e.isUniqueConstraintError()) {
      print('Email already exists');
      // Handle duplicate
    } else if (e.isNotNullConstraintError()) {
      print('Required field missing');
      // Handle missing required field
    } else {
      print('Database error: ${e.result}');
      rethrow;
    }
  }
}
```

## Testing

Test database operations using in-memory databases:

```dart
void main() {
  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve user', () async {
    final id = await db.insert('users', {'name': 'Test User'});
    final users = await db.query('users', where: 'id = ?', whereArgs: [id]);

    expect(users.length, 1);
    expect(users.first['name'], 'Test User');
  });
}
```

## Platform-Specific Considerations

### Mobile (iOS/Android)
sqflite uses native SQLite implementations, providing optimal performance. Databases are stored in the app's private directory, protected by OS-level security.

### macOS
Native SQLite support with sandboxed storage. Works identically to iOS implementation.

### Windows/Linux Desktop
Requires sqflite_common_ffi for FFI-based SQLite access. Performance is comparable to native implementations but requires explicit initialization.

### Web
sqflite does not support web. For web apps, use Drift with drift_web, which uses IndexedDB as the backend.

## Best Practices

Use transactions for related operations to ensure atomicity. Always enable foreign keys with `PRAGMA foreign_keys = ON` in onConfigure. Close databases when no longer needed to free resources. Use parameterized queries (?) to prevent SQL injection. Version databases incrementally and test migrations thoroughly.

Create indexes on columns used in WHERE, ORDER BY, and JOIN clauses. Use EXPLAIN QUERY PLAN to verify index usage. Batch operations when inserting or updating multiple rows. Keep database schemas normalized to avoid data redundancy.

Store DateTime as INTEGER milliseconds since epoch for consistent cross-platform behavior. Use TEXT for JSON when structured data doesn't require querying. Implement the repository pattern to encapsulate database logic.

Never perform long-running database operations on the main isolate. For large operations, use compute() or Isolate.spawn(). Cache frequently accessed data in memory to reduce database queries.

## Common Pitfalls

Not enabling foreign keys leads to orphaned records and data integrity issues. Forgetting to await database operations causes race conditions and data loss. Using string concatenation instead of parameterized queries enables SQL injection.

Loading large result sets into memory causes out-of-memory errors. Creating too many indexes slows down inserts and updates. Not using transactions for multi-step operations results in partial updates on errors.

Storing dates as strings prevents proper sorting and comparison. Opening multiple database instances causes locking issues. Not handling migration errors gracefully breaks the app for existing users.

## Migration Tools

For complex migrations, consider using migration packages:

```yaml
dependencies:
  sqflite_migration: ^1.0.0
```

```dart
import 'package:sqflite_migration/sqflite_migration.dart';

final config = MigrationConfig(
  initializationScript: [
    'CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)',
  ],
  migrationScripts: [
    'ALTER TABLE users ADD COLUMN email TEXT',
    'ALTER TABLE users ADD COLUMN age INTEGER',
  ],
);

final db = await openDatabaseWithMigration(
  path,
  config,
);
```

sqflite provides a robust foundation for relational data storage in Flutter applications. Combined with proper architecture patterns and migration strategies, it enables building scalable, maintainable apps with complex data requirements.
