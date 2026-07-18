# Provider Patterns and Best Practices

Provider is Flutter's officially recommended state management solution for most applications. It's a wrapper around `InheritedWidget` that makes it easier to use and more composable. This guide covers Provider patterns, best practices, and when to use it.

## Table of Contents

1. [Provider Overview](#provider-overview)
2. [Core Provider Types](#core-provider-types)
3. [ChangeNotifierProvider](#changenotifierprovider)
4. [MultiProvider](#multiprovider)
5. [Consumer and Selector](#consumer-and-selector)
6. [ProxyProvider](#proxyprovider)
7. [Best Practices](#best-practices)
8. [Common Patterns](#common-patterns)
9. [Testing with Provider](#testing-with-provider)

## Provider Overview

Provider is a dependency injection and state management library that makes it easy to access and manage state across your widget tree without prop drilling.

### Why Provider?

**Advantages:**
- **Simple API**: Easy to learn, minimal boilerplate
- **Flutter-endorsed**: Recommended by the Flutter team
- **Composable**: Multiple providers work together seamlessly
- **Performant**: Granular rebuilds only where needed
- **Testable**: Easy to mock and test
- **Type-safe**: Compile-time safety with strong typing

**When to Use Provider:**
- Small to medium applications
- Teams new to Flutter state management
- Projects that need something more structured than `setState()` but less rigid than BLoC
- Applications without complex event-driven requirements

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
```

## Core Provider Types

Provider offers several specialized provider types for different use cases:

### Provider (Basic)

Exposes a value that never changes. Used for constants, configurations, or dependency injection.

```dart
class ApiConfig {
  final String baseUrl;
  final String apiKey;

  const ApiConfig({
    required this.baseUrl,
    required this.apiKey,
  });
}

// Provide the value
Provider<ApiConfig>(
  create: (_) => const ApiConfig(
    baseUrl: 'https://api.example.com',
    apiKey: 'your-api-key',
  ),
  child: MyApp(),
)

// Access the value
final config = Provider.of<ApiConfig>(context, listen: false);
// or using context extension
final config = context.read<ApiConfig>();
```

### Provider.value

For exposing an existing object instance. Useful when the object is created elsewhere.

```dart
final existingUser = User(id: '123', name: 'John');

Provider<User>.value(
  value: existingUser,
  child: UserProfile(),
)
```

### FutureProvider

Exposes a `Future` and automatically handles loading/error/data states.

```dart
FutureProvider<User>(
  create: (_) => fetchUser('123'),
  initialData: null,
  child: UserWidget(),
)

// Access with Consumer
Consumer<User?>(
  builder: (context, user, child) {
    if (user == null) return CircularProgressIndicator();
    return Text(user.name);
  },
)
```

### StreamProvider

Exposes a `Stream` and automatically subscribes/unsubscribes.

```dart
StreamProvider<List<Message>>(
  create: (_) => messagesStream,
  initialData: const [],
  child: MessageList(),
)

// Access the latest stream value
final messages = context.watch<List<Message>>();
```

## ChangeNotifierProvider

`ChangeNotifierProvider` is the most commonly used provider. It provides a `ChangeNotifier` and automatically calls `dispose()` when no longer needed.

### Basic Setup

```dart
// 1. Create a ChangeNotifier class
class Counter extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void decrement() {
    _count--;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}

// 2. Provide it at the top of your widget tree
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Counter(),
      child: const MyApp(),
    ),
  );
}

// 3. Access and modify state
class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Read and listen to changes
            Consumer<Counter>(
              builder: (context, counter, child) {
                return Text(
                  '${counter.count}',
                  style: Theme.of(context).textTheme.headlineLarge,
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  // Read without listening
                  onPressed: () => context.read<Counter>().decrement(),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => context.read<Counter>().increment(),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<Counter>().reset(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

### Complex State Management

```dart
class ShoppingCart extends ChangeNotifier {
  final List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total => _items.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  void addItem(Product product) {
    final existingIndex = _items.indexWhere((item) => item.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      _items.add(CartItem.fromProduct(product));
    }

    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  Future<void> checkout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await processOrder(_items);
      _items.clear();
    } catch (e) {
      // Handle error
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
```

### Async State Pattern

```dart
class ProductRepository extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await fetchProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final savedProduct = await saveProduct(product);
      _products.add(savedProduct);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    // Optimistic update
    final index = _products.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final removed = _products.removeAt(index);
      notifyListeners();

      try {
        await deleteProductApi(id);
      } catch (e) {
        // Rollback on error
        _products.insert(index, removed);
        _error = e.toString();
        notifyListeners();
        rethrow;
      }
    }
  }
}
```

## MultiProvider

When you need multiple providers, use `MultiProvider` to avoid nested provider widgets.

### Basic MultiProvider

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => UserProfile()),
        Provider(create: (_) => ApiConfig()),
      ],
      child: const MyApp(),
    ),
  );
}
```

### Scoped Providers

Provide different instances at different levels of the tree:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Global providers
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
      ],
      child: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}

class ShopScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Screen-specific providers
      providers: [
        ChangeNotifierProvider(create: (_) => ShoppingCart()),
        ChangeNotifierProvider(create: (_) => ProductRepository()),
      ],
      child: Scaffold(
        body: ProductList(),
      ),
    );
  }
}
```

### Provider Dependencies

When one provider depends on another, ensure correct ordering:

```dart
MultiProvider(
  providers: [
    // AuthService must be first
    ChangeNotifierProvider(create: (_) => AuthService()),

    // UserProfile depends on AuthService
    ChangeNotifierProvider(
      create: (context) => UserProfile(
        authService: context.read<AuthService>(),
      ),
    ),

    // ShoppingCart depends on both
    ChangeNotifierProvider(
      create: (context) => ShoppingCart(
        authService: context.read<AuthService>(),
        userProfile: context.read<UserProfile>(),
      ),
    ),
  ],
  child: MyApp(),
)
```

## Consumer and Selector

Provider offers multiple ways to access and listen to state changes.

### Consumer Widget

`Consumer` rebuilds only its builder function when the provided value changes.

```dart
Consumer<Counter>(
  builder: (context, counter, child) {
    // This rebuilds when counter changes
    return Text('Count: ${counter.count}');
  },
)
```

**With Child Optimization:**

```dart
Consumer<Counter>(
  // child is built once and reused
  child: const ExpensiveWidget(),
  builder: (context, counter, child) {
    return Column(
      children: [
        Text('Count: ${counter.count}'),
        child!, // Reused, not rebuilt
      ],
    );
  },
)
```

### Multiple Consumers

When you need multiple providers:

```dart
Consumer2<Counter, Theme>(
  builder: (context, counter, theme, child) {
    return Text(
      'Count: ${counter.count}',
      style: TextStyle(color: theme.primaryColor),
    );
  },
)

// Up to Consumer6 is available
Consumer3<A, B, C>(
  builder: (context, a, b, c, child) {
    // Use a, b, c
    return Widget();
  },
)
```

### Selector - Granular Rebuilds

`Selector` only rebuilds when a specific part of state changes:

```dart
class User {
  final String name;
  final String email;
  final int loginCount;

  User({
    required this.name,
    required this.email,
    required this.loginCount,
  });
}

// Only rebuilds when name changes, not email or loginCount
Selector<UserProfile, String>(
  selector: (context, profile) => profile.user.name,
  builder: (context, name, child) {
    return Text('Hello, $name!');
  },
)
```

**Multiple Values:**

```dart
Selector<ShoppingCart, ({int count, double total})>(
  selector: (context, cart) => (
    count: cart.itemCount,
    total: cart.total,
  ),
  builder: (context, data, child) {
    return Column(
      children: [
        Text('Items: ${data.count}'),
        Text('Total: \$${data.total.toStringAsFixed(2)}'),
      ],
    );
  },
)
```

### Context Extension Methods

Provider adds extension methods to `BuildContext`:

```dart
// Watch - rebuilds when value changes
final counter = context.watch<Counter>();

// Read - doesn't listen to changes (use in callbacks)
context.read<Counter>().increment();

// Select - watch only a specific property
final count = context.select<Counter, int>((counter) => counter.count);
```

**Usage Guidelines:**

```dart
Widget build(BuildContext context) {
  // ✅ DO: Watch in build method
  final counter = context.watch<Counter>();

  return Column(
    children: [
      Text('${counter.count}'),
      ElevatedButton(
        // ✅ DO: Read in callbacks
        onPressed: () => context.read<Counter>().increment(),
        child: const Text('Increment'),
      ),
    ],
  );
}

// ❌ DON'T: Watch in callbacks
ElevatedButton(
  onPressed: () {
    final counter = context.watch<Counter>(); // Error!
    counter.increment();
  },
  child: const Text('Increment'),
)

// ❌ DON'T: Read in build
Widget build(BuildContext context) {
  final counter = context.read<Counter>(); // Won't rebuild!
  return Text('${counter.count}');
}
```

## ProxyProvider

`ProxyProvider` creates a provider that depends on other providers and rebuilds when dependencies change.

### Basic ProxyProvider

```dart
class OrderService {
  final AuthService auth;
  final ShoppingCart cart;

  OrderService({required this.auth, required this.cart});

  Future<void> placeOrder() async {
    final userId = auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await submitOrder(
      userId: userId,
      items: cart.items,
    );
  }
}

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => ShoppingCart()),

    // ProxyProvider2 depends on AuthService and ShoppingCart
    ProxyProvider2<AuthService, ShoppingCart, OrderService>(
      update: (context, auth, cart, previous) {
        return OrderService(auth: auth, cart: cart);
      },
    ),
  ],
  child: MyApp(),
)
```

### ChangeNotifierProxyProvider

When the proxy itself is a `ChangeNotifier`:

```dart
class FilteredProducts extends ChangeNotifier {
  final ProductRepository repository;
  final FilterSettings settings;

  FilteredProducts({
    required this.repository,
    required this.settings,
  });

  List<Product> get products {
    return repository.products.where((product) {
      if (settings.minPrice != null && product.price < settings.minPrice!) {
        return false;
      }
      if (settings.category != null && product.category != settings.category) {
        return false;
      }
      return true;
    }).toList();
  }
}

MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProductRepository()),
    ChangeNotifierProvider(create: (_) => FilterSettings()),

    ChangeNotifierProxyProvider2<ProductRepository, FilterSettings, FilteredProducts>(
      create: (context) => FilteredProducts(
        repository: context.read<ProductRepository>(),
        settings: context.read<FilterSettings>(),
      ),
      update: (context, repository, settings, previous) {
        previous!.notifyListeners();
        return previous;
      },
    ),
  ],
  child: MyApp(),
)
```

## Best Practices

### 1. Separation of Concerns

Keep business logic in your `ChangeNotifier` classes, not in widgets:

```dart
// ✅ Good - Business logic in ChangeNotifier
class TodoList extends ChangeNotifier {
  final List<Todo> _todos = [];

  void addTodo(String title) {
    if (title.trim().isEmpty) return;

    _todos.add(Todo(
      id: DateTime.now().toString(),
      title: title.trim(),
      isCompleted: false,
    ));
    notifyListeners();
  }

  void toggleTodo(String id) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
      );
      notifyListeners();
    }
  }
}

// ❌ Bad - Business logic in widget
class TodoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final todoList = context.read<TodoList>();
        final title = 'New Todo';

        // Business logic should be in TodoList class
        if (title.trim().isNotEmpty) {
          todoList._todos.add(Todo(...));
          todoList.notifyListeners();
        }
      },
      child: const Text('Add'),
    );
  }
}
```

### 2. Immutable State When Possible

Use immutable data structures and create new instances on updates:

```dart
class UserProfile extends ChangeNotifier {
  User _user;

  User get user => _user;

  UserProfile(this._user);

  void updateName(String name) {
    // Create new instance instead of mutating
    _user = _user.copyWith(name: name);
    notifyListeners();
  }
}

class User {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  User copyWith({String? name, String? email}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
```

### 3. Dispose Resources

Always dispose of resources in your `ChangeNotifier`:

```dart
class StreamController extends ChangeNotifier {
  final StreamSubscription _subscription;

  StreamController(Stream<int> stream)
      : _subscription = stream.listen((_) {}) {
    _subscription.onData((data) {
      // Handle data
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

### 4. Avoid Unnecessary Rebuilds

Use `Selector` or `context.select()` to rebuild only when specific values change:

```dart
// ❌ Rebuilds when ANY cart property changes
Consumer<ShoppingCart>(
  builder: (context, cart, _) {
    return Text('Items: ${cart.itemCount}');
  },
)

// ✅ Only rebuilds when itemCount changes
Selector<ShoppingCart, int>(
  selector: (_, cart) => cart.itemCount,
  builder: (context, count, _) {
    return Text('Items: $count');
  },
)
```

### 5. Use listen: false for One-Time Reads

When you don't need to listen to changes:

```dart
// In build method
final config = Provider.of<ApiConfig>(context, listen: false);
// or
final config = context.read<ApiConfig>();

// In callbacks
onPressed: () {
  final cart = context.read<ShoppingCart>();
  cart.addItem(product);
}
```

### 6. Don't Call notifyListeners in Getters

```dart
// ❌ Bad - notifying in getter
int get count {
  notifyListeners(); // Wrong!
  return _count;
}

// ✅ Good - notify in setters/methods
void increment() {
  _count++;
  notifyListeners();
}
```

### 7. Handle Async Errors Properly

```dart
class DataService extends ChangeNotifier {
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await fetchItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

## Common Patterns

### Authentication Flow

```dart
class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await authApi.signIn(email, password);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await authApi.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      _user = await authApi.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _user = null;
      notifyListeners();
    }
  }
}

// Usage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  await authService.loadCurrentUser();

  runApp(
    ChangeNotifierProvider.value(
      value: authService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const SplashScreen();
          }
          return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
```

### Pagination

```dart
class PaginatedList<T> extends ChangeNotifier {
  final Future<List<T>> Function(int page) fetchPage;

  List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  PaginatedList(this.fetchPage);

  List<T> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newItems = await fetchPage(_currentPage + 1);

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    await loadMore();
  }
}

// Usage
class ProductListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaginatedList<Product>(fetchProducts)..loadMore(),
      child: const ProductListView(),
    );
  }
}

class ProductListView extends StatelessWidget {
  const ProductListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PaginatedList<Product>>(
      builder: (context, productList, _) {
        return RefreshIndicator(
          onRefresh: productList.refresh,
          child: ListView.builder(
            itemCount: productList.items.length + (productList.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= productList.items.length) {
                // Load more trigger
                productList.loadMore();
                return const Center(child: CircularProgressIndicator());
              }

              return ProductTile(product: productList.items[index]);
            },
          ),
        );
      },
    );
  }
}
```

## Testing with Provider

Provider is designed to be easily testable.

### Unit Testing ChangeNotifiers

```dart
void main() {
  group('Counter', () {
    test('starts at 0', () {
      final counter = Counter();
      expect(counter.count, 0);
    });

    test('increments', () {
      final counter = Counter();
      counter.increment();
      expect(counter.count, 1);
    });

    test('notifies listeners', () {
      final counter = Counter();
      var notified = false;

      counter.addListener(() {
        notified = true;
      });

      counter.increment();
      expect(notified, true);
    });
  });
}
```

### Widget Testing with Mocks

```dart
class MockCounter extends Mock implements Counter {}

void main() {
  testWidgets('displays counter value', (tester) async {
    final mockCounter = MockCounter();
    when(mockCounter.count).thenReturn(42);

    await tester.pumpWidget(
      ChangeNotifierProvider<Counter>.value(
        value: mockCounter,
        child: MaterialApp(
          home: CounterScreen(),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('calls increment on button press', (tester) async {
    final mockCounter = MockCounter();
    when(mockCounter.count).thenReturn(0);

    await tester.pumpWidget(
      ChangeNotifierProvider<Counter>.value(
        value: mockCounter,
        child: MaterialApp(
          home: CounterScreen(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    verify(mockCounter.increment()).called(1);
  });
}
```

### Integration Testing

```dart
void main() {
  testWidgets('full authentication flow', (tester) async {
    final authService = AuthService();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authService,
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Enter credentials
    await tester.enterText(
      find.byType(TextField).at(0),
      'test@example.com',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'password123',
    );

    // Tap sign in
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Verify navigation to home screen
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(authService.isAuthenticated, true);
  });
}
```

## Conclusion

Provider is a powerful yet simple state management solution that works well for most Flutter applications. Key takeaways:

- Start with `ChangeNotifierProvider` for reactive state
- Use `Consumer` and `Selector` for granular rebuilds
- Leverage `MultiProvider` for multiple providers
- Keep business logic in `ChangeNotifier` classes
- Use `context.read()` in callbacks, `context.watch()` in build
- Test your state logic independently of widgets

Provider strikes an excellent balance between simplicity and power, making it ideal for teams learning Flutter or building small to medium applications. If you need more advanced features like compile-time safety or no BuildContext dependency, consider Riverpod (covered in the next reference).
