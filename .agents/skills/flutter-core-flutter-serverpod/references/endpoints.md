# Creating and Working with Endpoints

Comprehensive guide to creating server endpoints in Serverpod, handling parameters and return types, implementing error handling, using streaming endpoints, and following best practices for API design.

## Endpoint Fundamentals

Endpoints serve as the connection points between your Flutter client and Serverpod backend. They define the API surface that clients can call, similar to REST controllers or GraphQL resolvers, but with automatic type safety and code generation.

### Creating an Endpoint

Create an endpoint by extending the `Endpoint` class anywhere under the `lib/` directory of your server package:

```dart
// lib/src/endpoints/product_endpoint.dart
import 'package:serverpod/serverpod.dart';

class ProductEndpoint extends Endpoint {
  Future<String> getProductName(Session session, int productId) async {
    return 'Product $productId';
  }
}
```

**Key Requirements**:
- Extend `Endpoint` class from serverpod package
- Methods must return a typed `Future` or `Stream`
- First parameter must always be `Session`
- Additional parameters follow the session parameter

### Endpoint Naming

Serverpod automatically removes the "Endpoint" suffix when generating client code:

```dart
// Server: ProductEndpoint
// Client access: client.product.getProductName()

// Server: UserManagementEndpoint
// Client access: client.userManagement.getUser()
```

Use descriptive endpoint names that indicate their domain or feature area.

### File Organization

Organize endpoints by feature or domain:

```
lib/src/endpoints/
├── user_endpoint.dart          # User management
├── product_endpoint.dart       # Product operations
├── order_endpoint.dart         # Order processing
└── analytics_endpoint.dart     # Analytics queries
```

This structure scales better than grouping all endpoints in a single file.

## Code Generation

After creating or modifying endpoints, regenerate client code:

```bash
cd my_app_server
serverpod generate
```

**What Gets Generated**:
- Client-side method stubs in `my_app_client/`
- Protocol definitions for serialization
- Endpoint registration in server code
- Type-safe parameter and return type handling

**When to Regenerate**:
- After creating new endpoints or methods
- After changing method signatures
- After modifying model definitions used in endpoints
- Before running your Flutter app with endpoint changes

## Supported Parameter Types

Endpoint methods accept specific Dart types that can be serialized over the network.

### Primitive Types

```dart
Future<void> exampleMethod(
  Session session,
  bool flag,           // Boolean values
  int count,           // Integer numbers
  double amount,       // Floating-point numbers
  String name,         // Text strings
) async {
  // Implementation
}
```

### Special Types

```dart
Future<void> advancedTypes(
  Session session,
  DateTime timestamp,   // Date and time (converted to UTC)
  Duration timeout,     // Time spans
  UuidValue userId,     // UUID identifiers
  Uri website,          // URLs and URIs
  BigInt largeNumber,   // Arbitrary precision integers
  ByteData binary,      // Raw binary data
) async {
  // Implementation
}
```

**DateTime Handling**: All `DateTime` values are automatically converted to UTC during transmission, preventing timezone-related bugs.

### Collection Types

Collections must be strictly typed with supported element types:

```dart
Future<void> collections(
  Session session,
  List<String> names,              // Typed lists
  Map<String, int> scores,         // Typed maps
  Set<int> uniqueIds,              // Typed sets
  ({String name, int age}) record, // Records (Dart 3.0+)
) async {
  // Implementation
}
```

**Type Safety**: Generic types like `List<dynamic>` or `Map` without type parameters are not supported. All collections must specify their element types.

### Serializable Models

Use generated model classes as parameters:

```dart
Future<User> updateUser(Session session, User user) async {
  // user parameter is a generated model class
  await User.db.updateRow(session, user);
  return user;
}

Future<List<Product>> searchProducts(
  Session session,
  ProductFilter filter,
) async {
  // filter is a serializable model
  return await Product.db.find(
    session,
    where: (t) => t.category.equals(filter.category),
  );
}
```

Models are defined in YAML files and generated with `serverpod generate`.

### Null Safety

All parameter types support null safety:

```dart
Future<String?> getUserName(Session session, int? userId) async {
  if (userId == null) return null;

  var user = await User.db.findById(session, userId);
  return user?.name;
}
```

Nullable parameters and return types work seamlessly across the client-server boundary.

## Return Types

Endpoint methods must return `Future` or `Stream` with a supported value type.

### Future Return Types

Most endpoint methods return `Future`:

```dart
// Return primitive types
Future<String> getMessage(Session session) async {
  return 'Hello World';
}

// Return model objects
Future<User> getUser(Session session, int id) async {
  return await User.db.findById(session, id);
}

// Return collections
Future<List<Product>> getAllProducts(Session session) async {
  return await Product.db.find(session);
}

// Return void (no return value)
Future<void> logEvent(Session session, String event) async {
  session.log('Event: $event');
}
```

### Stream Return Types

For real-time data, return `Stream`:

```dart
Stream<Message> chatMessages(Session session, String roomId) async* {
  // Subscribe to message stream
  await for (var message in messageStream(roomId)) {
    yield message;
  }
}

Stream<int> countdown(Session session, int seconds) async* {
  for (var i = seconds; i >= 0; i--) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}
```

Streams enable server-to-client data push without polling.

### Polymorphic Types

Use parent classes in return types to return different subclasses:

```dart
// Base class and subclasses defined in YAML
Future<Animal> getAnimal(Session session, int id) async {
  // Can return Dog, Cat, or any Animal subclass
  var animal = await Animal.db.findById(session, id);
  return animal; // Runtime type is preserved
}
```

Serverpod maintains runtime type information during serialization.

## Session Object

The `Session` parameter provides access to server functionality and request context.

### Database Access

Access the database through the session:

```dart
Future<List<User>> getActiveUsers(Session session) async {
  return await User.db.find(
    session,
    where: (t) => t.isActive.equals(true),
  );
}
```

The session manages database connections and transaction state.

### Logging

Log messages during endpoint execution:

```dart
Future<void> processOrder(Session session, Order order) async {
  session.log('Processing order ${order.id}');

  try {
    // Process order
    session.log('Order ${order.id} completed', level: LogLevel.info);
  } catch (e, stackTrace) {
    session.log(
      'Order processing failed',
      level: LogLevel.error,
      exception: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}
```

**Log Levels**:
- `LogLevel.debug`: Detailed debugging information
- `LogLevel.info`: General information (default)
- `LogLevel.warning`: Warning messages
- `LogLevel.error`: Error conditions
- `LogLevel.fatal`: Critical errors

### Authentication

Check authentication status and access user information:

```dart
Future<UserProfile> getMyProfile(Session session) async {
  // Check if user is authenticated
  if (!session.isUserSignedIn) {
    throw UnauthorizedException('User not signed in');
  }

  // Get authenticated user ID
  var userId = session.auth?.userId;

  // Retrieve and return user profile
  return await UserProfile.db.findById(session, userId!);
}
```

Authentication is provided by the `serverpod_auth_idp` module.

### Caching

Access caching functionality:

```dart
Future<Configuration> getConfig(Session session) async {
  // Try cache first
  var config = await session.caches.local.get<Configuration>('config');

  if (config == null) {
    // Load from database if not cached
    config = await Configuration.db.findFirstRow(session);

    // Cache for 5 minutes
    await session.caches.local.put(
      'config',
      config,
      lifetime: Duration(minutes: 5),
    );
  }

  return config;
}
```

Three cache types: `local`, `localPriority`, and `global` (Redis).

## Error Handling

Proper error handling ensures clients receive meaningful error information.

### Throwing Exceptions

Throw standard Dart exceptions or custom serializable exceptions:

```dart
Future<Product> getProduct(Session session, int id) async {
  var product = await Product.db.findById(session, id);

  if (product == null) {
    throw NotFoundException('Product not found: $id');
  }

  return product;
}
```

### Custom Serializable Exceptions

Define custom exceptions in YAML:

```yaml
# lib/src/models/exceptions.spy.yaml
exception: InsufficientInventoryException
fields:
  productId: int
  requested: int
  available: int
  message: String
```

Generate and use:

```dart
Future<Order> createOrder(Session session, OrderRequest request) async {
  var product = await Product.db.findById(session, request.productId);

  if (product.inventory < request.quantity) {
    throw InsufficientInventoryException(
      productId: product.id!,
      requested: request.quantity,
      available: product.inventory,
      message: 'Not enough inventory',
    );
  }

  // Create order
}
```

**Client Handling**:
```dart
try {
  await client.order.createOrder(orderRequest);
} on InsufficientInventoryException catch (e) {
  print('Need ${e.requested}, only ${e.available} available');
} on ServerpodClientException catch (e) {
  print('Request failed: $e');
}
```

### Validation

Validate input parameters early:

```dart
Future<User> createUser(Session session, String email, String name) async {
  // Validate email format
  if (!email.contains('@')) {
    throw ValidationException('Invalid email format');
  }

  // Validate name length
  if (name.isEmpty || name.length > 100) {
    throw ValidationException('Name must be 1-100 characters');
  }

  // Check for existing user
  var existing = await User.db.findFirstRow(
    session,
    where: (t) => t.email.equals(email),
  );

  if (existing != null) {
    throw DuplicateUserException('Email already registered');
  }

  // Create user
  return await User.db.insertRow(
    session,
    User(email: email, name: name),
  );
}
```

## Streaming Endpoints

Streaming endpoints enable real-time bidirectional communication.

### Server-to-Client Streaming

Return a `Stream` to push data to clients:

```dart
Stream<StockPrice> watchStock(Session session, String symbol) async* {
  // Subscribe to price updates
  await for (var price in stockPriceStream(symbol)) {
    yield price;
  }
}
```

**Client Usage**:
```dart
// Subscribe to stream
var subscription = client.stock.watchStock('AAPL').listen((price) {
  print('New price: ${price.value}');
});

// Cancel when done
await subscription.cancel();
```

### Client-to-Server Streaming

Accept `Stream` parameters to receive data from clients:

```dart
Future<UploadResult> uploadData(
  Session session,
  Stream<DataChunk> dataStream,
) async {
  var totalBytes = 0;

  await for (var chunk in dataStream) {
    // Process each chunk
    await processChunk(chunk);
    totalBytes += chunk.data.length;
  }

  return UploadResult(bytesReceived: totalBytes);
}
```

**Client Usage**:
```dart
// Create stream of data chunks
Stream<DataChunk> dataStream() async* {
  for (var i = 0; i < 10; i++) {
    yield DataChunk(data: generateData());
  }
}

// Upload stream to server
var result = await client.data.uploadData(dataStream());
```

### Bidirectional Streaming

Combine stream parameters and return types:

```dart
Stream<ChatMessage> chatRoom(
  Session session,
  String roomId,
  Stream<ChatMessage> messageStream,
) async* {
  // Start listening to room messages
  var subscription = roomMessageBroadcast(roomId).listen((msg) {
    // Messages from other users
  });

  // Process incoming messages from this client
  messageStream.listen((msg) {
    broadcastToRoom(roomId, msg);
  });

  // Yield messages to this client
  await for (var msg in roomMessageBroadcast(roomId)) {
    yield msg;
  }

  await subscription.cancel();
}
```

This pattern is ideal for chat, multiplayer games, or collaborative editing.

### Stream Lifecycle

Serverpod manages stream lifecycle automatically:

- Creates new `Session` for each streaming method call
- Keeps connection alive while stream is active
- Closes session when stream completes or client disconnects
- Handles network interruptions gracefully

## Endpoint Inheritance

Use inheritance to share common functionality across endpoints.

### Abstract Base Endpoints

Create abstract base classes for shared logic:

```dart
// lib/src/endpoints/base/authenticated_endpoint.dart
abstract class AuthenticatedEndpoint extends Endpoint {
  Future<int> requireAuthenticatedUserId(Session session) async {
    if (!session.isUserSignedIn) {
      throw UnauthorizedException('Authentication required');
    }
    return session.auth!.userId!;
  }

  Future<User> getCurrentUser(Session session) async {
    var userId = await requireAuthenticatedUserId(session);
    return await User.db.findById(session, userId);
  }
}
```

**Concrete Implementation**:
```dart
class ProfileEndpoint extends AuthenticatedEndpoint {
  Future<UserProfile> getMyProfile(Session session) async {
    var user = await getCurrentUser(session);
    return await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(user.id),
    );
  }

  Future<void> updateProfile(Session session, UserProfile profile) async {
    var userId = await requireAuthenticatedUserId(session);

    // Ensure user can only update their own profile
    if (profile.userId != userId) {
      throw ForbiddenException('Cannot update another user\'s profile');
    }

    await UserProfile.db.updateRow(session, profile);
  }
}
```

### Method Overriding

Override parent methods to customize behavior:

```dart
abstract class BaseEndpoint extends Endpoint {
  Future<String> getMessage(Session session) async {
    return 'Base message';
  }
}

class CustomEndpoint extends BaseEndpoint {
  @override
  Future<String> getMessage(Session session) async {
    // Custom implementation
    return 'Custom message';
  }
}
```

## Excluding Endpoints from Generation

Use `@doNotGenerate` annotation to hide endpoints or methods from clients.

### Hiding Entire Endpoints

Prevent all methods in an endpoint from being exposed:

```dart
@doNotGenerate
class InternalEndpoint extends Endpoint {
  Future<void> internalOperation(Session session) async {
    // Only callable from server-side code
  }
}
```

Use for internal utilities or maintenance endpoints.

### Hiding Specific Methods

Expose some methods while hiding others:

```dart
class AdminEndpoint extends Endpoint {
  // Public method - generates client code
  Future<List<User>> getUsers(Session session) async {
    return await User.db.find(session);
  }

  // Hidden method - no client code generated
  @doNotGenerate
  Future<void> dangerousOperation(Session session) async {
    // Only callable internally
  }
}
```

## Middleware

Middleware intercepts HTTP requests and responses for cross-cutting concerns.

### Creating Middleware

Middleware is a function that wraps another handler:

```dart
// lib/src/middleware/cors_middleware.dart
import 'package:serverpod/serverpod.dart';

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (HttpRequest request) async {
      var response = await innerHandler(request);

      // Add CORS headers
      response.headers.set('Access-Control-Allow-Origin', '*');
      response.headers.set('Access-Control-Allow-Methods', 'GET, POST');

      return response;
    };
  };
}
```

### Registering Middleware

Add middleware before starting the server:

```dart
// lib/server.dart
void run(List<String> args) async {
  var pod = Serverpod(/* config */);

  // Add middleware before starting
  pod.server.addMiddleware(corsMiddleware());
  pod.server.addMiddleware(loggingMiddleware());

  await pod.start();
}
```

**Execution Order**: Middleware executes in the order added. First added middleware runs first on requests and last on responses (onion model).

### Common Middleware Patterns

**Request Logging**:
```dart
Middleware loggingMiddleware() {
  return (Handler innerHandler) {
    return (HttpRequest request) async {
      var startTime = DateTime.now();

      var response = await innerHandler(request);

      var duration = DateTime.now().difference(startTime);
      print('${request.method} ${request.uri} - ${duration.inMilliseconds}ms');

      return response;
    };
  };
}
```

**Rate Limiting**:
```dart
Middleware rateLimitMiddleware({int maxRequests = 100, Duration window = const Duration(minutes: 1)}) {
  var requestCounts = <String, List<DateTime>>{};

  return (Handler innerHandler) {
    return (HttpRequest request) async {
      var ip = request.connectionInfo?.remoteAddress.address ?? 'unknown';

      // Clean old entries
      requestCounts[ip]?.removeWhere((time) =>
        DateTime.now().difference(time) > window);

      // Check limit
      var count = requestCounts[ip]?.length ?? 0;
      if (count >= maxRequests) {
        return HttpResponse.tooManyRequests('Rate limit exceeded');
      }

      // Record request
      requestCounts[ip] = [...?requestCounts[ip], DateTime.now()];

      return await innerHandler(request);
    };
  };
}
```

## Best Practices

### Keep Endpoints Focused

Each endpoint should handle a specific domain or feature area. Avoid creating monolithic endpoints with many unrelated methods.

**Good**:
```dart
class UserEndpoint extends Endpoint { /* user operations */ }
class ProductEndpoint extends Endpoint { /* product operations */ }
class OrderEndpoint extends Endpoint { /* order operations */ }
```

**Avoid**:
```dart
class ApiEndpoint extends Endpoint { /* everything mixed together */ }
```

### Validate Input Early

Perform validation at the start of methods before expensive operations:

```dart
Future<Result> processData(Session session, DataInput input) async {
  // Validate first
  if (!input.isValid()) {
    throw ValidationException('Invalid input');
  }

  // Then process
  return await expensiveOperation(input);
}
```

### Use Descriptive Method Names

Method names should clearly indicate their purpose and behavior:

```dart
// Good names
Future<User> getUserById(Session session, int id)
Future<List<Order>> getUserOrders(Session session, int userId)
Future<void> cancelOrder(Session session, int orderId)

// Avoid vague names
Future<User> get(Session session, int id)
Future<List<Order>> fetch(Session session, int userId)
Future<void> process(Session session, int orderId)
```

### Handle Errors Gracefully

Provide meaningful error messages that clients can display or handle:

```dart
Future<void> deleteAccount(Session session, int userId) async {
  var user = await User.db.findById(session, userId);

  if (user == null) {
    throw NotFoundException('User not found: $userId');
  }

  if (user.hasActiveSubscription) {
    throw ValidationException(
      'Cannot delete account with active subscription. '
      'Please cancel subscription first.'
    );
  }

  await User.db.deleteRow(session, user);
}
```

### Document Complex Methods

Add documentation comments for complex logic:

```dart
/// Calculates user reputation score based on activity.
///
/// Score factors:
/// - Posts: +10 points each
/// - Comments: +2 points each
/// - Upvotes received: +1 point each
/// - Downvotes received: -1 point each
///
/// Returns the total reputation score.
Future<int> calculateReputation(Session session, int userId) async {
  // Implementation
}
```

### Optimize Database Queries

Fetch related data efficiently using includes:

```dart
// Inefficient - N+1 queries
Future<List<OrderWithProducts>> getOrders(Session session) async {
  var orders = await Order.db.find(session);

  for (var order in orders) {
    order.products = await Product.db.find(
      session,
      where: (t) => t.orderId.equals(order.id),
    );
  }

  return orders;
}

// Efficient - single query with includes
Future<List<Order>> getOrders(Session session) async {
  return await Order.db.find(
    session,
    include: Order.include(products: Product.includeList()),
  );
}
```

Endpoints form the API contract between your server and clients. Following these patterns ensures maintainable, performant, and developer-friendly APIs.
