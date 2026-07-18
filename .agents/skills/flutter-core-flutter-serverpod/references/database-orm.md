# Database and ORM Operations

Complete guide to Serverpod's type-safe ORM including model definitions, CRUD operations, queries, filtering, relations, and database migrations for PostgreSQL.

## Model Definition

Models are the foundation of Serverpod's ORM, defined in YAML files with the `.spy.yaml` extension for IDE support.

### Creating a Model

Create model files anywhere in your server's `lib/` directory:

```yaml
# lib/src/models/user.spy.yaml
class: User
table: user
fields:
  name: String
  email: String
  age: int?
  createdAt: DateTime
  isActive: bool, default=true
```

**Key Elements**:
- `class`: The Dart class name to generate
- `table`: Database table name (omit for non-persisted models)
- `fields`: Column definitions with types

### Supported Field Types

**Primitive Types**:
```yaml
fields:
  flag: bool
  count: int
  price: double
  description: String
```

**Special Types**:
```yaml
fields:
  id: UuidValue          # UUID identifiers
  createdAt: DateTime    # Timestamps (stored as UTC)
  duration: Duration     # Time intervals
  website: Uri           # URLs
  largeNumber: BigInt    # Arbitrary precision integers
  data: ByteData         # Binary data
```

**Vector Types** (for embeddings/similarity search):
```yaml
fields:
  embedding: Vector             # Float vector
  compactEmbedding: HalfVector  # Half-precision vector
  sparseEmbedding: SparseVector # Sparse vector
  binaryVector: Bit             # Bit vector
```

**Collections**:
```yaml
fields:
  tags: List<String>
  metadata: Map<String, String>
  categories: Set<int>
```

**Other Models**:
```yaml
fields:
  address: Address      # Another serializable class
  status: OrderStatus   # Enum
```

### Null Safety

Mark fields as nullable with `?`:

```yaml
fields:
  name: String          # Required, non-null
  nickname: String?     # Optional, nullable
  age: int?             # Optional, nullable
```

### Default Values

Provide default values using keywords:

```yaml
fields:
  # Default for both code and database
  isActive: bool, default=true

  # Default only in code (not in database schema)
  createdAt: DateTime, defaultModel=DateTime.now()

  # Default only in database (e.g., using SQL function)
  id: int, defaultPersist='nextval("user_id_seq")'
```

### Indexing

Create database indexes for performance:

```yaml
fields:
  email: String, !dbindex        # Single column index
  userId: int, !dbindex          # Foreign key index
```

For composite indexes or advanced options, use migration SQL.

## Code Generation

Generate Dart classes and database code:

```bash
cd my_app_server
serverpod generate
```

**Generated Files**:
- `lib/src/generated/user.dart` - Server-side class with database methods
- `../my_app_client/lib/src/protocol/user.dart` - Client-side class

**Generated Class**:
```dart
class User extends TableRow {
  int? id;
  String name;
  String email;
  int? age;
  DateTime createdAt;
  bool isActive;

  User({
    this.id,
    required this.name,
    required this.email,
    this.age,
    required this.createdAt,
    required this.isActive,
  });

  // Database operations via static db property
  static UserDbOperations db = UserDbOperations();

  // Serialization methods
  @override
  Map<String, dynamic> toJson() { /* ... */ }

  // copyWith method for immutability
  User copyWith({ /* ... */ }) { /* ... */ }
}
```

## CRUD Operations

All models with a `table` property get generated database operation methods.

### Create (Insert)

Insert a single row:

```dart
Future<User> createUser(Session session, String name, String email) async {
  var user = User(
    name: name,
    email: email,
    createdAt: DateTime.now(),
    isActive: true,
  );

  // Insert and get object with id field set
  var inserted = await User.db.insertRow(session, user);

  print('Created user with ID: ${inserted.id}');
  return inserted;
}
```

Batch insert multiple rows atomically:

```dart
Future<List<User>> createUsers(
  Session session,
  List<User> users,
) async {
  // All rows inserted or none (atomic operation)
  return await User.db.insert(session, users);
}
```

**Atomicity**: If any row fails validation or constraints, no rows are inserted.

### Read (Query)

Find by primary key:

```dart
Future<User?> getUserById(Session session, int id) async {
  // Returns User or null if not found
  return await User.db.findById(session, id);
}
```

Find first matching row:

```dart
Future<User?> getUserByEmail(Session session, String email) async {
  return await User.db.findFirstRow(
    session,
    where: (t) => t.email.equals(email),
  );
}
```

Find all matching rows:

```dart
Future<List<User>> getActiveUsers(Session session) async {
  return await User.db.find(
    session,
    where: (t) => t.isActive.equals(true),
  );
}
```

Find with pagination:

```dart
Future<List<User>> getUsersPage(
  Session session,
  int page,
  int pageSize,
) async {
  return await User.db.find(
    session,
    limit: pageSize,
    offset: page * pageSize,
    orderBy: (t) => t.createdAt,
  );
}
```

### Update

Update a fetched object:

```dart
Future<User> updateUser(Session session, User user) async {
  // Update entire row
  return await User.db.updateRow(session, user);
}
```

Update specific columns by ID without fetching:

```dart
Future<User?> updateUserEmail(
  Session session,
  int userId,
  String newEmail,
) async {
  return await User.db.updateById(
    session,
    userId,
    User(email: newEmail),  // Only email is updated
  );
}
```

Update all rows matching criteria:

```dart
Future<List<User>> deactivateOldUsers(Session session) async {
  var cutoffDate = DateTime.now().subtract(Duration(days: 365));

  return await User.db.updateWhere(
    session,
    where: (t) => t.createdAt < cutoffDate,
    values: User(isActive: false),
  );
}
```

### Delete

Delete a specific row:

```dart
Future<void> deleteUser(Session session, User user) async {
  await User.db.deleteRow(session, user);
}
```

Batch delete multiple rows:

```dart
Future<void> deleteUsers(Session session, List<User> users) async {
  await User.db.delete(session, users);
}
```

Delete rows matching criteria:

```dart
Future<int> deleteInactiveUsers(Session session) async {
  var deleted = await User.db.deleteWhere(
    session,
    where: (t) => t.isActive.equals(false),
  );

  print('Deleted $deleted users');
  return deleted;
}
```

### Count

Count rows matching criteria:

```dart
Future<int> countActiveUsers(Session session) async {
  return await User.db.count(
    session,
    where: (t) => t.isActive.equals(true),
  );
}
```

## Filtering and Queries

Serverpod provides a type-safe query builder through filter expressions.

### Equality Operators

```dart
// Exact match
where: (t) => t.name.equals('Alice')

// Not equal (includes null rows)
where: (t) => t.name.notEquals('Alice')
```

### Comparison Operators

```dart
// Greater than
where: (t) => t.age > 18

// Greater than or equal
where: (t) => t.age >= 18

// Less than
where: (t) => t.createdAt < DateTime.now()

// Less than or equal
where: (t) => t.price <= 100.0
```

### Range Operators

```dart
// Between (inclusive)
where: (t) => t.age.between(18, 65)

// Not between (inclusive)
where: (t) => t.age.notBetween(18, 65)
```

### Set Membership

```dart
// In set
where: (t) => t.status.inSet({'active', 'pending'})

// Not in set
where: (t) => t.status.notInSet({'deleted', 'banned'})
```

### String Matching

```dart
// Like (case-sensitive)
where: (t) => t.email.like('%@gmail.com')

// iLike (case-insensitive)
where: (t) => t.name.ilike('john%')

// Not like
where: (t) => t.email.notLike('%@spam.com')

// Not iLike
where: (t) => t.name.notIlike('admin%')
```

**Wildcards**:
- `%` matches any sequence of characters
- `_` matches a single character

### Logical Operators

Combine conditions using `&` (AND), `|` (OR), and `~` (NOT):

```dart
// AND
where: (t) => t.isActive.equals(true) & t.age >= 18

// OR
where: (t) => t.role.equals('admin') | t.role.equals('moderator')

// NOT
where: (t) => ~t.isActive.equals(false)

// Complex combinations
where: (t) =>
  (t.isActive.equals(true) & t.age >= 18) |
  t.role.equals('admin')
```

**Precedence**: Use parentheses to control evaluation order.

### Vector Similarity

Search by vector similarity:

```dart
// L2 (Euclidean) distance
where: (t) => t.embedding.distanceL2([1.0, 2.0, 3.0]) < 0.5

// Cosine distance
where: (t) => t.embedding.distanceCosine(queryVector) < 0.3

// Inner product
where: (t) => t.embedding.distanceInnerProduct(queryVector) < 0.2

// L1 (Manhattan) distance
where: (t) => t.embedding.distanceL1(queryVector) < 1.0
```

For bit vectors:

```dart
// Hamming distance
where: (t) => t.binaryVector.distanceHamming(queryBits) < 10

// Jaccard distance
where: (t) => t.binaryVector.distanceJaccard(queryBits) < 0.2
```

### Sorting

Order results by fields:

```dart
// Ascending order
orderBy: (t) => t.createdAt

// Descending order (use negative)
orderBy: (t) => -t.createdAt

// Multiple fields
orderBy: (t) => (t.isActive, -t.createdAt)
```

## Relations

Define relationships between models for complex queries and data loading.

### One-to-One Relations

Define in the model with a foreign key:

```yaml
# lib/src/models/employee.spy.yaml
class: Employee
table: employee
fields:
  name: String
  addressId: int, !dbindex

  # Relation definition
  address: Address?, relation(field=addressId, parent=address)
```

The related model:

```yaml
# lib/src/models/address.spy.yaml
class: Address
table: address
fields:
  street: String
  city: String
  zipCode: String
```

**Loading Related Data**:

```dart
// Without relation (two queries)
var employee = await Employee.db.findById(session, employeeId);
var address = await Address.db.findById(session, employee.addressId);

// With relation (single query)
var employee = await Employee.db.findById(
  session,
  employeeId,
  include: Employee.include(
    address: Address.include(),
  ),
);

// Access directly
print('Street: ${employee.address?.street}');
```

### One-to-Many Relations

Define the "many" side with a foreign key:

```yaml
# lib/src/models/order.spy.yaml
class: Order
table: order
fields:
  userId: int, !dbindex
  total: double
  createdAt: DateTime

  # Many-to-one relation
  user: User?, relation(field=userId, parent=user)
```

Define the "one" side with a back-reference:

```yaml
# lib/src/models/user.spy.yaml
class: User
table: user
fields:
  name: String
  email: String

  # One-to-many relation
  orders: List<Order>?, relation(field=userId)
```

**Loading Collections**:

```dart
// Load user with all orders
var user = await User.db.findById(
  session,
  userId,
  include: User.include(
    orders: Order.includeList(),
  ),
);

// Access orders
for (var order in user.orders ?? []) {
  print('Order total: ${order.total}');
}
```

**Filtering Related Lists**:

```dart
// Load only recent orders
var user = await User.db.findById(
  session,
  userId,
  include: User.include(
    orders: Order.includeList(
      where: (t) => t.createdAt > DateTime.now().subtract(Duration(days: 30)),
      orderBy: (t) => -t.createdAt,
      limit: 10,
    ),
  ),
);
```

### Nested Relations

Load relations of relations:

```dart
// Load company with employees and their addresses
var company = await Company.db.findById(
  session,
  companyId,
  include: Company.include(
    employees: Employee.includeList(
      include: Employee.include(
        address: Address.include(),
      ),
    ),
  ),
);

// Access nested data
for (var employee in company.employees ?? []) {
  print('${employee.name} lives at ${employee.address?.street}');
}
```

### Filtering on Relations

Filter parent by related data (one-to-one):

```dart
// Find employees in a specific city
var employees = await Employee.db.find(
  session,
  where: (t) => t.address.city.equals('San Francisco'),
  include: Employee.include(
    address: Address.include(),
  ),
);
```

Filter parent by related collection (one-to-many):

```dart
// Users with any orders
where: (t) => t.orders.any((o) => o.total > 0)

// Users with no orders
where: (t) => t.orders.none((o) => o.total > 0)

// Users where all orders are shipped
where: (t) => t.orders.every((o) => o.status.equals('shipped'))

// Users with at least 5 orders
where: (t) => t.orders.count() >= 5

// Users with expensive orders
where: (t) => t.orders.count((o) => o.total > 100) > 0
```

### Managing Relations

Attach related objects:

```dart
// Attach employee to company
await Company.db.attach.employees(
  session,
  companyId,
  [employee1, employee2],
);

// Objects must have id field set
```

Detach related objects:

```dart
// Remove employees from company
await Company.db.detach.employees(
  session,
  companyId,
  [employee1, employee2],
);
```

## Model Inheritance

Create model hierarchies with inheritance.

### Defining Inheritance

Base class:

```yaml
# lib/src/models/animal.spy.yaml
class: Animal
table: animal
fields:
  name: String
  age: int
```

Derived classes:

```yaml
# lib/src/models/dog.spy.yaml
class: Dog
table: dog
extends: Animal
fields:
  breed: String
  isGoodBoy: bool, default=true
```

```yaml
# lib/src/models/cat.spy.yaml
class: Cat
table: cat
extends: Animal
fields:
  color: String
  livesRemaining: int, default=9
```

### Polymorphic Queries

Return parent type that can be any subclass:

```dart
Future<Animal> getAnimal(Session session, int id) async {
  // Runtime type preserved (Dog or Cat)
  return await Animal.db.findById(session, id);
}

// Client receives correct subclass
var animal = await client.animal.getAnimal(1);

if (animal is Dog) {
  print('Breed: ${animal.breed}');
} else if (animal is Cat) {
  print('Color: ${animal.color}');
}
```

### Sealed Classes

Enforce exhaustive type checking:

```yaml
class: PaymentMethod
sealed: true
fields:
  amount: double
```

Subclasses:

```yaml
class: CreditCard
extends: PaymentMethod
fields:
  cardNumber: String
  expiryDate: String
```

```yaml
class: BankTransfer
extends: PaymentMethod
fields:
  accountNumber: String
  routingNumber: String
```

**Usage**:

```dart
String processPayment(PaymentMethod payment) {
  // Compiler ensures all cases handled
  return switch (payment) {
    CreditCard card => 'Charging card ${card.cardNumber}',
    BankTransfer transfer => 'Transferring from ${transfer.accountNumber}',
  };
}
```

## Field Visibility

Control which fields are sent to clients.

### Server-Only Fields

Mark entire class as server-only:

```yaml
class: InternalConfig
serverOnly: true
fields:
  apiKey: String
  databaseUrl: String
```

Mark individual fields:

```yaml
class: User
table: user
fields:
  name: String
  email: String
  passwordHash: String, scope=serverOnly  # Not sent to client
  salt: String, scope=serverOnly
```

### Scopes

Fine-grained visibility control:

```yaml
fields:
  publicField: String, scope=all        # Sent to all clients (default)
  serverField: String, scope=serverOnly # Server only
  hiddenField: String, scope=none       # Not generated at all
```

## Immutable Models

Create immutable value objects:

```yaml
class: Money
immutable: true
fields:
  amount: double
  currency: String
```

**Benefits**:
- All fields are final
- Automatic `==` and `hashCode` implementation
- Generated `copyWith` method for updates

**Usage**:

```dart
var price = Money(amount: 99.99, currency: 'USD');

// Cannot modify (compilation error)
// price.amount = 100.00;

// Create modified copy
var discountedPrice = price.copyWith(amount: 79.99);
```

## Database Migrations

Manage schema evolution through migrations.

### Creating Migrations

After modifying models, create a migration:

```bash
cd my_app_server
serverpod create-migration
```

Serverpod compares your models with the database schema and generates migration files in `migrations/`.

**Migration Files**:
```
migrations/
└── 20240115123456789/
    ├── migration.json     # Parsed migration actions
    ├── migration.sql      # SQL to apply changes
    ├── definition.json    # Complete schema definition
    ├── definition.sql     # SQL to create schema from scratch
    └── definition_project.json  # Your project schema only
```

### Tagged Migrations

Add meaningful tags to migrations:

```bash
serverpod create-migration --tag "add-user-roles"
```

Generates: `migrations/20240115123456789-add-user-roles/`

### Forcing Migrations

Override safety checks when needed:

```bash
# Create migration even if no changes detected
serverpod create-migration --force

# Create migration that might lose data
serverpod create-migration --force
```

**Use Caution**: Force flag bypasses data loss warnings.

### Applying Migrations

Apply during server startup:

```bash
dart run bin/main.dart --apply-migrations
```

Serverpod applies pending migrations in order and tracks which migrations have been applied.

**Maintenance Mode**:

```bash
# Apply migrations then exit (useful for CI/CD)
dart run bin/main.dart --role maintenance --apply-migrations
```

### Repair Migrations

Synchronize schema after manual database changes:

```bash
# Connect to development database
serverpod create-repair-migration

# Connect to production database
serverpod create-repair-migration --mode production

# Repair to specific migration version
serverpod create-repair-migration --version 20240115123456789
```

Repair migrations reset the schema definition without modifying data.

### Rolling Back

Revert to a previous schema version:

1. Create repair migration targeting the old version:
   ```bash
   serverpod create-repair-migration --version 20240101000000000
   ```

2. Apply the repair migration:
   ```bash
   dart run bin/main.dart --apply-migrations
   ```

**Note**: Schema reverts but data remains. Handle data migration manually if needed.

## Best Practices

### Index Strategically

Add indexes for frequently queried fields:

```yaml
fields:
  email: String, !dbindex       # Frequent lookups
  userId: int, !dbindex          # Foreign key
  createdAt: DateTime            # No index (range queries less common)
```

Over-indexing slows writes. Profile queries to identify bottlenecks.

### Use Pagination

Always paginate large result sets:

```dart
// Good
Future<List<User>> getUsers(Session session, int page) async {
  return await User.db.find(
    session,
    limit: 50,
    offset: page * 50,
  );
}

// Avoid
Future<List<User>> getAllUsers(Session session) async {
  return await User.db.find(session);  // Could return millions
}
```

### Eager Load Relations

Fetch related data in a single query:

```dart
// Inefficient - N+1 queries
var users = await User.db.find(session);
for (var user in users) {
  user.orders = await Order.db.find(
    session,
    where: (t) => t.userId.equals(user.id),
  );
}

// Efficient - 1 query
var users = await User.db.find(
  session,
  include: User.include(
    orders: Order.includeList(),
  ),
);
```

### Validate Before Insert

Check constraints before database operations:

```dart
Future<User> createUser(Session session, User user) async {
  // Validate email format
  if (!user.email.contains('@')) {
    throw ValidationException('Invalid email');
  }

  // Check uniqueness
  var existing = await User.db.findFirstRow(
    session,
    where: (t) => t.email.equals(user.email),
  );

  if (existing != null) {
    throw DuplicateException('Email already exists');
  }

  return await User.db.insertRow(session, user);
}
```

### Use Transactions

For operations that must succeed or fail together, wrap in transactions (future Serverpod feature - currently automatic per request).

### Review Migration SQL

Always review generated migration SQL before applying to production:

```bash
cat migrations/20240115123456789/migration.sql
```

Check for unexpected DROP statements or data loss scenarios.

Serverpod's ORM provides a powerful, type-safe layer over PostgreSQL, enabling productive development while maintaining performance and correctness.
