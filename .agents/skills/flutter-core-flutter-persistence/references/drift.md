# Drift - Type-Safe SQL for Flutter

Drift is a reactive persistence library for Dart and Flutter that builds on SQLite with compile-time type safety, reactive streams, and modern Dart features. Unlike raw SQLite, Drift generates type-safe Dart classes from table definitions and catches SQL errors at compile time, dramatically reducing runtime bugs while maintaining full SQL power.

## Core Concepts

Drift transforms your database schema written as Dart classes into generated code that provides type-safe queries, automatic data class generation, and reactive streams. Every query returns properly typed results, and the compiler validates your SQL at build time. Drift works seamlessly across Android, iOS, macOS, Windows, Linux, and web platforms.

The library embraces a DAO (Data Access Object) pattern, organizing related queries into reusable components. Tables are defined as Dart classes, queries can be written in both Dart and SQL, and results automatically update through streams when underlying data changes. This reactive nature eliminates manual refresh logic and ensures UI stays synchronized with data.

## Installation and Setup

Add Drift dependencies to pubspec.yaml:

```yaml
dependencies:
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0

dev_dependencies:
  drift_dev: ^2.14.0
  build_runner: ^2.4.0
```

For web support, add:

```yaml
dependencies:
  drift_web: ^2.14.0
```

## Database Definition

### Defining Tables

Create table definitions as Dart classes:

```dart
import 'package:drift/drift.dart';

part 'database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get email => text().unique()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get title => text().withLength(max: 200)();
  TextColumn get content => text()();
  DateTimeColumn get publishedAt => dateTime().nullable()();
}
```

### Database Class

Define your database with tables and version:

```dart
@DriftDatabase(tables: [Users, Posts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(join(dbFolder.path, 'app.db'));
      return NativeDatabase(file);
    });
  }
}
```

### Generate Code

Run build_runner to generate database code:

```bash
flutter pub run build_runner build
# Or watch for changes
flutter pub run build_runner watch --delete-conflicting-outputs
```

This generates `database.g.dart` containing typed data classes and query builders.

## Column Types and Constraints

### Supported Column Types

```dart
class Examples extends Table {
  // Numeric types
  IntColumn get intValue => integer()();
  Int64Column get bigIntValue => int64()();
  RealColumn get doubleValue => real()();

  // Text
  TextColumn get textValue => text()();

  // Boolean
  BoolColumn get boolValue => boolean()();

  // Date and time
  DateTimeColumn get dateValue => dateTime()();

  // Binary data
  BlobColumn get binaryData => blob()();
}
```

### Constraints

Apply constraints to columns:

```dart
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();

  // NOT NULL (default for non-nullable columns)
  TextColumn get name => text()();

  // NULLABLE
  TextColumn get bio => text().nullable()();

  // UNIQUE
  TextColumn get email => text().unique()();

  // DEFAULT value
  BoolColumn get verified => boolean().withDefault(const Constant(false))();

  // CHECK constraint
  IntColumn get age => integer().check(age.isBiggerOrEqualValue(0))();

  // Length constraints
  TextColumn get username => text().withLength(min: 3, max: 20)();

  // Custom column name
  TextColumn get firstName => text().named('first_name')();
}
```

### Foreign Keys

Define relationships between tables:

```dart
class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Simple foreign key
  IntColumn get userId => integer().references(Users, #id)();

  // Foreign key with cascade delete
  IntColumn get categoryId => integer().references(
    Categories,
    #id,
    onDelete: KeyAction.cascade,
    onUpdate: KeyAction.cascade,
  )();
}
```

### Composite Keys

Define multi-column primary keys:

```dart
class UserRoles extends Table {
  IntColumn get userId => integer()();
  IntColumn get roleId => integer()();

  @override
  Set<Column> get primaryKey => {userId, roleId};
}
```

## CRUD Operations

### Insert

Insert data using generated data classes:

```dart
final db = AppDatabase();

// Insert single user
final user = UsersCompanion(
  name: Value('John Doe'),
  email: Value('john@example.com'),
);
final userId = await db.into(db.users).insert(user);

// Insert with returning clause (gets full object back)
final insertedUser = await db.into(db.users).insertReturning(user);

// Insert or replace
await db.into(db.users).insert(
  user,
  mode: InsertMode.replace,
);

// Insert multiple
await db.batch((batch) {
  batch.insertAll(db.users, [user1, user2, user3]);
});
```

### Query

Query with type-safe results:

```dart
// Get all users
final allUsers = await db.select(db.users).get();

// Filter with where clause
final activeUsers = await (db.select(db.users)
      ..where((u) => u.isActive.equals(true)))
    .get();

// Order results
final orderedUsers = await (db.select(db.users)
      ..orderBy([(u) => OrderingTerm.desc(u.createdAt)]))
    .get();

// Limit and offset
final limitedUsers = await (db.select(db.users)
      ..limit(10, offset: 20))
    .get();

// Single result
final user = await (db.select(db.users)
      ..where((u) => u.id.equals(1)))
    .getSingleOrNull();

// Get stream for reactive updates
final userStream = db.select(db.users).watch();
```

### Update

Update existing records:

```dart
// Update single user
await (db.update(db.users)..where((u) => u.id.equals(1)))
    .write(UsersCompanion(name: Value('Jane Doe')));

// Update multiple
await (db.update(db.users)..where((u) => u.isActive.equals(false)))
    .write(UsersCompanion(isActive: Value(true)));

// Update using data class
final user = await db.getUserById(1);
await db.update(db.users).replace(user.copyWith(name: 'New Name'));
```

### Delete

Remove records from database:

```dart
// Delete single user
await (db.delete(db.users)..where((u) => u.id.equals(1))).go();

// Delete with condition
await (db.delete(db.users)..where((u) => u.isActive.equals(false))).go();

// Delete all
await db.delete(db.users).go();
```

## Complex Queries

### Joins

Query across multiple tables:

```dart
// Simple join
final query = db.select(db.posts).join([
  innerJoin(db.users, db.users.id.equalsExp(db.posts.userId)),
]);

final results = await query.get();
for (final row in results) {
  final post = row.readTable(db.posts);
  final user = row.readTable(db.users);
  print('${post.title} by ${user.name}');
}

// Left outer join
final query = db.select(db.users).join([
  leftOuterJoin(db.posts, db.posts.userId.equalsExp(db.users.id)),
]);
```

### Aggregates

Use aggregate functions:

```dart
// Count
final countQuery = db.selectOnly(db.users)
  ..addColumns([db.users.id.count()]);
final count = await countQuery.getSingle();

// Group by with aggregates
final query = db.selectOnly(db.posts)
  ..addColumns([
    db.posts.userId,
    db.posts.id.count(),
  ])
  ..groupBy([db.posts.userId]);

final results = await query.get();
for (final row in results) {
  final userId = row.read(db.posts.userId);
  final postCount = row.read(db.posts.id.count());
  print('User $userId has $postCount posts');
}
```

### Custom Expressions

Build complex SQL expressions:

```dart
// Computed columns
final query = db.selectOnly(db.users)
  ..addColumns([
    db.users.id,
    db.users.name,
    (db.users.name.length).as('name_length'),
  ]);

// CASE expressions
final isPopular = db.posts.id.count().isBiggerOrEqualValue(10);
final query = db.selectOnly(db.users)
  ..addColumns([
    db.users.name,
    Case<bool>()
        .when(isPopular, then: const Constant(true))
        .otherwise(const Constant(false))
        .as('is_popular'),
  ]);
```

## DAOs (Data Access Objects)

Organize related queries into DAOs:

```dart
@DriftAccessor(tables: [Users, Posts])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  // Get user by ID
  Future<User?> getUserById(int id) {
    return (select(users)..where((u) => u.id.equals(id)))
        .getSingleOrNull();
  }

  // Get users with post count
  Future<List<UserWithPostCount>> getUsersWithPostCounts() {
    final query = select(users).join([
      leftOuterJoin(posts, posts.userId.equalsExp(users.id)),
    ]);

    return query.map((row) {
      return UserWithPostCount(
        user: row.readTable(users),
        postCount: row.readTable(posts).id,
      );
    }).get();
  }

  // Watch active users
  Stream<List<User>> watchActiveUsers() {
    return (select(users)..where((u) => u.isActive.equals(true)))
        .watch();
  }

  // Create user
  Future<int> createUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  // Update user
  Future<bool> updateUser(User user) {
    return update(users).replace(user);
  }

  // Delete user
  Future<int> deleteUser(int id) {
    return (delete(users)..where((u) => u.id.equals(id))).go();
  }
}

// Update database class
@DriftDatabase(tables: [Users, Posts], daos: [UserDao])
class AppDatabase extends _$AppDatabase {
  // ... existing code
}

// Usage
final db = AppDatabase();
final userDao = db.userDao;
final users = await userDao.getUsersWithPostCounts();
```

## Custom Queries with SQL

Write SQL directly for complex queries:

```dart
@DriftAccessor(tables: [Users, Posts])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(AppDatabase db) : super(db);

  @DriftQuery('SELECT * FROM users WHERE email = ?')
  Future<User?> findByEmail(String email);

  @DriftQuery('''
    SELECT u.*, COUNT(p.id) as post_count
    FROM users u
    LEFT JOIN posts p ON u.id = p.user_id
    GROUP BY u.id
    HAVING post_count > :minPosts
    ORDER BY post_count DESC
  ''')
  Future<List<UserWithPostCount>> getUsersByPostCount(int minPosts);

  @DriftQuery('SELECT * FROM users WHERE created_at > :since')
  Stream<List<User>> watchRecentUsers(DateTime since);
}
```

After adding queries, regenerate code with build_runner.

## Transactions

Execute multiple operations atomically:

```dart
Future<void> transferPoints(int fromId, int toId, int points) async {
  await db.transaction(() async {
    // Deduct from sender
    final sender = await db.getUserById(fromId);
    await db.update(db.users).replace(
      sender!.copyWith(points: sender.points - points),
    );

    // Add to receiver
    final receiver = await db.getUserById(toId);
    await db.update(db.users).replace(
      receiver!.copyWith(points: receiver.points + points),
    );

    // Log transaction
    await db.into(db.transactions).insert(
      TransactionsCompanion(
        fromUserId: Value(fromId),
        toUserId: Value(toId),
        amount: Value(points),
      ),
    );
  });
}
```

Transactions automatically roll back on errors.

## Migrations

Handle schema changes across versions:

```dart
@DriftDatabase(tables: [Users, Posts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(users, users.bio);
        }
        if (from < 3) {
          await m.createTable(posts);
          await m.createIndex(
            Index('post_user_idx', 'CREATE INDEX post_user_idx ON posts(user_id)'),
          );
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
```

### Complex Migrations

Transform data during migration:

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Add new column
        await m.addColumn(users, users.fullName);

        // Migrate data
        final allUsers = await select(users).get();
        for (final user in allUsers) {
          await (update(users)..where((u) => u.id.equals(user.id)))
              .write(UsersCompanion(
            fullName: Value('${user.firstName} ${user.lastName}'),
          ));
        }

        // Drop old columns (requires recreating table)
        await m.deleteTable('users');
        await m.createTable(users);
      }
    },
  );
}
```

### Migration Testing

Test migrations with multiple schema versions:

```dart
import 'package:drift_dev/api/migrations.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('upgrade from v1 to v2', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase.connect(connection);

    await verifier.migrateAndValidate(db, 2);
  });
}
```

## Reactive Streams

Watch queries for automatic updates:

```dart
// Watch single query
Stream<List<User>> watchUsers() {
  return select(users).watch();
}

// Use in UI
StreamBuilder<List<User>>(
  stream: db.watchUsers(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final users = snapshot.data!;
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(users[index].name));
      },
    );
  },
);

// Watch with filters
Stream<List<User>> watchSearchResults(String query) {
  return (select(users)
        ..where((u) => u.name.like('%$query%')))
      .watch();
}
```

## Custom Types

Store custom Dart types:

```dart
// Define type converter
class UriConverter extends TypeConverter<Uri, String> {
  const UriConverter();

  @override
  Uri fromSql(String fromDb) => Uri.parse(fromDb);

  @override
  String toSql(Uri value) => value.toString();
}

// Use in table
class Links extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().map(const UriConverter())();
}

// Usage - Drift handles conversion automatically
await db.into(db.links).insert(
  LinksCompanion(url: Value(Uri.parse('https://example.com'))),
);

final links = await db.select(db.links).get();
final Uri url = links.first.url; // Typed as Uri, not String
```

## Batch Operations

Execute multiple operations efficiently:

```dart
await db.batch((batch) {
  // Insert multiple rows
  batch.insertAll(
    db.users,
    [user1, user2, user3],
    mode: InsertMode.insertOrReplace,
  );

  // Update
  batch.update(
    db.users,
    UsersCompanion(isActive: Value(false)),
    where: (u) => u.id.equals(1),
  );

  // Delete
  batch.delete(db.posts, where: (p) => p.id.equals(5));

  // Custom statement
  batch.customStatement('DELETE FROM users WHERE created_at < ?', [
    DateTime.now().subtract(Duration(days: 365)).millisecondsSinceEpoch,
  ]);
});
```

## Platform-Specific Setup

### Web Configuration

Configure Drift for web using IndexedDB:

```dart
import 'package:drift/drift.dart';
import 'package:drift/web.dart';

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return WebDatabase('app_db', logStatements: true);
  }
}
```

### Desktop Configuration

Use native database on desktop:

```dart
import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

static QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.db'));
    return NativeDatabase(file, logStatements: true);
  });
}
```

## Testing

Test database operations using in-memory databases:

```dart
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('insert and retrieve user', () async {
    final userId = await db.into(db.users).insert(
      UsersCompanion(
        name: Value('Test User'),
        email: Value('test@example.com'),
      ),
    );

    final user = await db.getUserById(userId);
    expect(user?.name, 'Test User');
  });

  test('update user', () async {
    final userId = await db.into(db.users).insert(
      UsersCompanion(name: Value('Old Name'), email: Value('test@example.com')),
    );

    await (db.update(db.users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(name: Value('New Name')));

    final user = await db.getUserById(userId);
    expect(user?.name, 'New Name');
  });
}
```

## Best Practices

### Organize with DAOs

Split database logic into focused DAOs by domain:

```dart
@DriftDatabase(
  tables: [Users, Posts, Comments],
  daos: [UserDao, PostDao, CommentDao],
)
class AppDatabase extends _$AppDatabase {
  // ...
}
```

### Use Companions for Inserts

Always use Companion classes for inserts to avoid unintentional nulls:

```dart
// Good - explicit about which fields to set
final user = UsersCompanion(
  name: Value('John'),
  email: Value('john@example.com'),
);

// Avoid - easy to miss required fields
final user = User(
  id: 0, // Will this work?
  name: 'John',
  email: 'john@example.com',
  createdAt: DateTime.now(),
);
```

### Stream Queries for Reactive UI

Use `.watch()` instead of `.get()` for data that changes:

```dart
// One-time read
final users = await db.select(db.users).get();

// Reactive stream - updates automatically
final userStream = db.select(db.users).watch();
```

### Leverage Type Safety

Let Drift's compiler catch errors:

```dart
// Compiler error - typo in column name
final query = select(users)..where((u) => u.namee.equals('John'));

// Compiler error - wrong type
final query = select(users)..where((u) => u.id.equals('not a number'));
```

### Index Frequently Queried Columns

Add indexes for performance:

```dart
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text()();

  @override
  List<Index> get indexes => [
    Index('email_idx', email),
  ];
}
```

## Common Patterns

### Repository with Drift

```dart
class UserRepository {
  final AppDatabase _db;

  UserRepository(this._db);

  Future<User?> findById(int id) => _db.userDao.getUserById(id);

  Stream<List<User>> watchAll() => _db.userDao.watchActiveUsers();

  Future<int> create(String name, String email) {
    return _db.into(_db.users).insert(
      UsersCompanion(name: Value(name), email: Value(email)),
    );
  }
}
```

### Singleton Database

```dart
class DatabaseProvider {
  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }
}

// Usage
final db = DatabaseProvider.instance;
```

## Performance Optimization

Enable query logging during development:

```dart
NativeDatabase(file, logStatements: true);
```

Use indexes strategically:

```dart
// Index for common WHERE clauses
Index('active_users_idx', 'CREATE INDEX active_users_idx ON users(is_active)'),

// Composite index for complex queries
Index(
  'post_search_idx',
  'CREATE INDEX post_search_idx ON posts(user_id, published_at DESC)',
),
```

Batch inserts for bulk operations:

```dart
await db.batch((batch) {
  batch.insertAll(db.users, manyUsers);
});
```

## When to Choose Drift

Choose Drift when you need:
- Type-safe SQL queries with compile-time validation
- Reactive streams for automatic UI updates
- Cross-platform support including web
- Complex queries with joins and aggregates
- Strong migration support
- Modern Dart patterns (DAOs, code generation)

Drift combines SQLite's power with Dart's type safety, making it ideal for applications requiring robust relational data storage with excellent developer experience and runtime reliability.
