# Local Database with SQLite and Migrations

This example demonstrates a complete SQLite database implementation with schema migrations, including a todo application with categories, tags, and full-text search capabilities.

## Database Schema

The database consists of multiple related tables with foreign key constraints:

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TodoDatabase {
  static final TodoDatabase instance = TodoDatabase._init();
  static Database? _database;

  TodoDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Create tables for latest version
    await _createCategoriesTable(db);
    await _createTodosTable(db);
    await _createTagsTable(db);
    await _createTodoTagsTable(db);
    await _createTodosFTSTable(db);
    await _createIndexes(db);
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL,
        icon TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createTodosTable(Database db) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category_id INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        completed_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
          ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createTodoTagsTable(Database db) async {
    await db.execute('''
      CREATE TABLE todo_tags (
        todo_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (todo_id, tag_id),
        FOREIGN KEY (todo_id) REFERENCES todos (id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTodosFTSTable(Database db) async {
    await db.execute('''
      CREATE VIRTUAL TABLE todos_fts USING fts5(
        title,
        description,
        content=todos,
        content_rowid=id
      )
    ''');

    // Triggers to keep FTS table synchronized
    await db.execute('''
      CREATE TRIGGER todos_fts_insert AFTER INSERT ON todos BEGIN
        INSERT INTO todos_fts(rowid, title, description)
        VALUES (new.id, new.title, new.description);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER todos_fts_delete AFTER DELETE ON todos BEGIN
        DELETE FROM todos_fts WHERE rowid = old.id;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER todos_fts_update AFTER UPDATE ON todos BEGIN
        DELETE FROM todos_fts WHERE rowid = old.id;
        INSERT INTO todos_fts(rowid, title, description)
        VALUES (new.id, new.title, new.description);
      END
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    // Index for category lookups
    await db.execute(
      'CREATE INDEX idx_todos_category ON todos(category_id)',
    );

    // Index for completed status queries
    await db.execute(
      'CREATE INDEX idx_todos_completed ON todos(is_completed)',
    );

    // Index for due date queries
    await db.execute(
      'CREATE INDEX idx_todos_due_date ON todos(due_date)',
    );

    // Composite index for common query pattern
    await db.execute('''
      CREATE INDEX idx_todos_category_completed
      ON todos(category_id, is_completed, due_date)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _upgradeToV2(db);
    }
    if (oldVersion < 3) {
      await _upgradeToV3(db);
    }
  }

  Future<void> _upgradeToV2(Database db) async {
    // Version 2: Added priority and tags
    await db.execute('ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 0');
    await _createTagsTable(db);
    await _createTodoTagsTable(db);
  }

  Future<void> _upgradeToV3(Database db) async {
    // Version 3: Added full-text search and indexes
    await _createTodosFTSTable(db);
    await _createIndexes(db);

    // Populate FTS table with existing data
    await db.execute('''
      INSERT INTO todos_fts(rowid, title, description)
      SELECT id, title, description FROM todos
    ''');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
```

## Model Classes

Define model classes for type-safe data handling:

```dart
class Category {
  final int? id;
  final String name;
  final int color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: map['color'] as int,
      icon: map['icon'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Category copyWith({
    int? id,
    String? name,
    int? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Todo {
  final int? id;
  final String title;
  final String? description;
  final int? categoryId;
  final bool isCompleted;
  final int priority;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    this.id,
    required this.title,
    this.description,
    this.categoryId,
    this.isCompleted = false,
    this.priority = 0,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as int?,
      isCompleted: (map['is_completed'] as int) == 1,
      priority: map['priority'] as int? ?? 0,
      dueDate: map['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    int? categoryId,
    bool? isCompleted,
    int? priority,
    DateTime? dueDate,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Tag {
  final int? id;
  final String name;
  final DateTime createdAt;

  Tag({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
```

## Repository Implementation

Create repositories for each entity:

```dart
class TodoRepository {
  final TodoDatabase _database;

  TodoRepository(this._database);

  // Create
  Future<int> createTodo(Todo todo) async {
    final db = await _database.database;
    return await db.insert('todos', todo.toMap());
  }

  // Read
  Future<Todo?> getTodoById(int id) async {
    final db = await _database.database;
    final results = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Todo.fromMap(results.first);
  }

  Future<List<Todo>> getAllTodos({
    bool? isCompleted,
    int? categoryId,
    String? orderBy,
  }) async {
    final db = await _database.database;

    String? where;
    List<dynamic>? whereArgs;

    if (isCompleted != null && categoryId != null) {
      where = 'is_completed = ? AND category_id = ?';
      whereArgs = [isCompleted ? 1 : 0, categoryId];
    } else if (isCompleted != null) {
      where = 'is_completed = ?';
      whereArgs = [isCompleted ? 1 : 0];
    } else if (categoryId != null) {
      where = 'category_id = ?';
      whereArgs = [categoryId];
    }

    final results = await db.query(
      'todos',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy ?? 'created_at DESC',
    );

    return results.map((map) => Todo.fromMap(map)).toList();
  }

  Future<List<Todo>> getTodosDueSoon(Duration within) async {
    final db = await _database.database;
    final cutoff = DateTime.now().add(within);

    final results = await db.query(
      'todos',
      where: 'is_completed = 0 AND due_date <= ? AND due_date >= ?',
      whereArgs: [
        cutoff.millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch,
      ],
      orderBy: 'due_date ASC',
    );

    return results.map((map) => Todo.fromMap(map)).toList();
  }

  // Update
  Future<int> updateTodo(Todo todo) async {
    final db = await _database.database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<void> toggleComplete(int id) async {
    final db = await _database.database;
    final todo = await getTodoById(id);

    if (todo == null) return;

    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    await updateTodo(updatedTodo);
  }

  // Delete
  Future<int> deleteTodo(int id) async {
    final db = await _database.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCompletedTodos() async {
    final db = await _database.database;
    await db.delete(
      'todos',
      where: 'is_completed = 1',
    );
  }

  // Search with full-text search
  Future<List<Todo>> searchTodos(String query) async {
    final db = await _database.database;

    final results = await db.rawQuery('''
      SELECT t.*
      FROM todos t
      JOIN todos_fts fts ON t.id = fts.rowid
      WHERE todos_fts MATCH ?
      ORDER BY rank
    ''', [query]);

    return results.map((map) => Todo.fromMap(map)).toList();
  }

  // Get todos with category
  Future<List<Map<String, dynamic>>> getTodosWithCategory() async {
    final db = await _database.database;

    final results = await db.rawQuery('''
      SELECT
        t.*,
        c.name as category_name,
        c.color as category_color,
        c.icon as category_icon
      FROM todos t
      LEFT JOIN categories c ON t.category_id = c.id
      ORDER BY t.created_at DESC
    ''');

    return results;
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    final db = await _database.database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN is_completed = 0 THEN 1 ELSE 0 END) as pending,
        SUM(CASE WHEN is_completed = 0 AND due_date < ? THEN 1 ELSE 0 END) as overdue
      FROM todos
    ''', [DateTime.now().millisecondsSinceEpoch]);

    final row = result.first;
    return {
      'total': row['total'] as int? ?? 0,
      'completed': row['completed'] as int? ?? 0,
      'pending': row['pending'] as int? ?? 0,
      'overdue': row['overdue'] as int? ?? 0,
    };
  }

  // Batch operations
  Future<void> batchCreateTodos(List<Todo> todos) async {
    final db = await _database.database;
    final batch = db.batch();

    for (final todo in todos) {
      batch.insert('todos', todo.toMap());
    }

    await batch.commit(noResult: true);
  }
}

class CategoryRepository {
  final TodoDatabase _database;

  CategoryRepository(this._database);

  Future<int> createCategory(Category category) async {
    final db = await _database.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _database.database;
    final results = await db.query('categories', orderBy: 'name ASC');
    return results.map((map) => Category.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>> getCategoryWithTodoCount(int id) async {
    final db = await _database.database;

    final result = await db.rawQuery('''
      SELECT
        c.*,
        COUNT(t.id) as todo_count
      FROM categories c
      LEFT JOIN todos t ON c.id = t.category_id
      WHERE c.id = ?
      GROUP BY c.id
    ''', [id]);

    return result.first;
  }

  Future<int> updateCategory(Category category) async {
    final db = await _database.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _database.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class TagRepository {
  final TodoDatabase _database;

  TagRepository(this._database);

  Future<int> createTag(Tag tag) async {
    final db = await _database.database;
    return await db.insert('tags', tag.toMap());
  }

  Future<void> addTagToTodo(int todoId, int tagId) async {
    final db = await _database.database;
    await db.insert('todo_tags', {
      'todo_id': todoId,
      'tag_id': tagId,
    });
  }

  Future<void> removeTagFromTodo(int todoId, int tagId) async {
    final db = await _database.database;
    await db.delete(
      'todo_tags',
      where: 'todo_id = ? AND tag_id = ?',
      whereArgs: [todoId, tagId],
    );
  }

  Future<List<Tag>> getTagsForTodo(int todoId) async {
    final db = await _database.database;

    final results = await db.rawQuery('''
      SELECT t.*
      FROM tags t
      JOIN todo_tags tt ON t.id = tt.tag_id
      WHERE tt.todo_id = ?
    ''', [todoId]);

    return results.map((map) => Tag.fromMap(map)).toList();
  }

  Future<List<Tag>> getAllTags() async {
    final db = await _database.database;
    final results = await db.query('tags', orderBy: 'name ASC');
    return results.map((map) => Tag.fromMap(map)).toList();
  }
}
```

## Usage Example

Putting it all together:

```dart
void main() async {
  final database = TodoDatabase.instance;
  final todoRepo = TodoRepository(database);
  final categoryRepo = CategoryRepository(database);
  final tagRepo = TagRepository(database);

  // Create category
  final workCategory = Category(
    name: 'Work',
    color: 0xFF2196F3,
    icon: 'work',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  final categoryId = await categoryRepo.createCategory(workCategory);

  // Create tags
  final urgentTag = Tag(name: 'urgent', createdAt: DateTime.now());
  final urgentTagId = await tagRepo.createTag(urgentTag);

  // Create todo
  final todo = Todo(
    title: 'Complete project proposal',
    description: 'Draft and submit Q1 proposal',
    categoryId: categoryId,
    priority: 2,
    dueDate: DateTime.now().add(Duration(days: 7)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  final todoId = await todoRepo.createTodo(todo);

  // Add tag to todo
  await tagRepo.addTagToTodo(todoId, urgentTagId);

  // Get all pending todos
  final pendingTodos = await todoRepo.getAllTodos(isCompleted: false);

  // Search todos
  final searchResults = await todoRepo.searchTodos('proposal');

  // Get statistics
  final stats = await todoRepo.getStatistics();
  print('Total: ${stats['total']}, Completed: ${stats['completed']}');

  // Mark as complete
  await todoRepo.toggleComplete(todoId);

  // Close database
  await database.close();
}
```

This example demonstrates a production-ready database implementation with proper migrations, foreign keys, full-text search, and repository patterns for clean architecture.
