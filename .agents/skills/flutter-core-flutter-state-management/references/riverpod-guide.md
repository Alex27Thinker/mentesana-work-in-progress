# Riverpod Guide

Riverpod is a complete rewrite of Provider that fixes its limitations while adding powerful new features. Created by the same author (Remi Rousselet), Riverpod offers compile-time safety, no BuildContext dependency, and built-in support for async state. This guide covers Riverpod fundamentals, patterns, and code generation.

## Table of Contents

1. [Riverpod Overview](#riverpod-overview)
2. [Provider Types](#provider-types)
3. [Code Generation](#code-generation)
4. [Reading Providers](#reading-providers)
5. [Async State with AsyncValue](#async-state-with-asyncvalue)
6. [StateNotifier and StateNotifierProvider](#statenotifier-and-statenotifierprovider)
7. [Advanced Patterns](#advanced-patterns)
8. [Testing with Riverpod](#testing-with-riverpod)
9. [Migration from Provider](#migration-from-provider)

## Riverpod Overview

Riverpod (an anagram of Provider) is Provider 2.0, addressing its fundamental limitations while adding modern features.

### Why Riverpod?

**Advantages over Provider:**
- **Compile-time safety**: Catch errors at compile time, not runtime
- **No BuildContext**: Access providers anywhere, even outside widgets
- **No ProviderNotFoundException**: Providers are globally available
- **Better testing**: Override providers without widget rebuilds
- **Async built-in**: First-class support for async state with `AsyncValue`
- **Auto-dispose**: Automatic memory management
- **Code generation**: Less boilerplate with `@riverpod` annotation
- **Stateful hot reload**: Preserve state during hot reload with code generation

**When to Use Riverpod:**
- New Flutter projects (recommended default)
- Apps needing compile-time safety
- Projects with significant async state
- When you want modern Flutter patterns
- Any size project (startup to enterprise)

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0

# For code generation (recommended)
dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
  riverpod_lint: ^2.3.0  # Optional linting rules
```

### Basic Setup

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    // Wrap your app in ProviderScope
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
    );
  }
}
```

## Provider Types

Riverpod offers several provider types for different use cases.

### Provider - Immutable Values

For values that never change or are computed from other providers:

```dart
// Simple value
final apiKeyProvider = Provider<String>((ref) {
  return 'your-api-key';
});

// Computed value
final temperatureInCelsiusProvider = Provider<double>((ref) {
  return 20.0;
});

final temperatureInFahrenheitProvider = Provider<double>((ref) {
  final celsius = ref.watch(temperatureInCelsiusProvider);
  return celsius * 9 / 5 + 32;
});

// Using in a widget
class WeatherWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fahrenheit = ref.watch(temperatureInFahrenheitProvider);
    return Text('${fahrenheit.toStringAsFixed(1)}°F');
  }
}
```

### StateProvider - Simple Mutable State

For simple state that can be read and modified by UI:

```dart
final counterProvider = StateProvider<int>((ref) => 0);

// Reading
class CounterDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}

// Modifying
class IncrementButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Read and modify
        ref.read(counterProvider.notifier).state++;

        // Or update with a function
        ref.read(counterProvider.notifier).update((state) => state + 1);
      },
      child: const Text('Increment'),
    );
  }
}
```

### FutureProvider - Async Operations

For async operations that complete once (like API calls):

```dart
final userProvider = FutureProvider<User>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  return await fetchUser(userId);
});

// Using in a widget
class UserProfile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### StreamProvider - Continuous Data

For streams that emit multiple values over time:

```dart
final messagesProvider = StreamProvider<List<Message>>((ref) {
  final chatId = ref.watch(currentChatIdProvider);
  return messagesStream(chatId);
});

// Using in a widget
class MessageList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesProvider);

    return messagesAsync.when(
      data: (messages) => ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) => MessageTile(messages[index]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### StateNotifierProvider - Complex State Logic

For complex state with custom logic (covered in detail later):

```dart
final todoListProvider = StateNotifierProvider<TodoList, List<Todo>>((ref) {
  return TodoList();
});
```

## Code Generation

Riverpod's code generation simplifies syntax and adds features like stateful hot reload.

### Setup

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0
```

### Generated Provider

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Required: part directive
part 'my_provider.g.dart';

// Simple provider
@riverpod
String apiKey(ApiKeyRef ref) {
  return 'your-api-key';
}

// Async provider (automatically creates FutureProvider)
@riverpod
Future<User> user(UserRef ref, String userId) async {
  return await fetchUser(userId);
}

// Stream provider (automatically creates StreamProvider)
@riverpod
Stream<List<Message>> messages(MessagesRef ref, String chatId) {
  return messagesStream(chatId);
}

// Generate with: dart run build_runner watch
```

### Auto-Dispose

By default, generated providers auto-dispose when no longer used:

```dart
// Auto-disposes by default
@riverpod
Future<Data> data(DataRef ref) async {
  return await fetchData();
}

// Keep alive (never disposes)
@Riverpod(keepAlive: true)
Future<Config> config(ConfigRef ref) async {
  return await fetchConfig();
}
```

### Family Providers (Parameters)

Pass parameters to providers:

```dart
@riverpod
Future<Product> product(ProductRef ref, String productId) async {
  return await fetchProduct(productId);
}

// Using in a widget
class ProductWidget extends ConsumerWidget {
  final String productId;

  const ProductWidget({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));

    return productAsync.when(
      data: (product) => Text(product.name),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Generated Notifier

For complex state management:

```dart
@riverpod
class TodoList extends _$TodoList {
  @override
  List<Todo> build() {
    // Initial state
    return [];
  }

  void addTodo(String title) {
    state = [...state, Todo(id: DateTime.now().toString(), title: title)];
  }

  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          todo.copyWith(isCompleted: !todo.isCompleted)
        else
          todo,
    ];
  }

  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }
}

// Using in a widget
class TodoListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return CheckboxListTile(
          title: Text(todo.title),
          value: todo.isCompleted,
          onChanged: (_) {
            ref.read(todoListProvider.notifier).toggleTodo(todo.id);
          },
        );
      },
    );
  }
}
```

## Reading Providers

Riverpod offers multiple ways to read providers depending on context.

### In Widgets

Use `ConsumerWidget` or `Consumer`:

```dart
// ConsumerWidget - Entire widget is a consumer
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}

// Consumer - Scoped consumption
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ExpensiveWidget(), // Doesn't rebuild
        Consumer(
          builder: (context, ref, child) {
            final count = ref.watch(counterProvider);
            return Text('$count'); // Only this rebuilds
          },
        ),
      ],
    );
  }
}
```

### ConsumerStatefulWidget

For stateful widgets:

```dart
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Can access ref in lifecycle methods
    final data = ref.read(dataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

### Outside Widgets

Read providers without BuildContext:

```dart
final container = ProviderContainer();

// Read provider
final value = container.read(myProvider);

// Listen to changes
container.listen<int>(
  counterProvider,
  (previous, next) {
    print('Counter changed from $previous to $next');
  },
);

// Dispose when done
container.dispose();
```

### ref.watch vs ref.read vs ref.listen

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch - Rebuilds when provider changes
    final count = ref.watch(counterProvider);

    return Column(
      children: [
        Text('$count'),
        ElevatedButton(
          onPressed: () {
            // ref.read - One-time read, no rebuild
            ref.read(counterProvider.notifier).state++;
          },
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

// ref.listen - Side effects on changes
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  void initState() {
    super.initState();

    // Listen for side effects
    ref.listenManual(counterProvider, (previous, next) {
      if (next >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Counter reached 10!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Select - Granular Rebuilds

Watch only specific parts of state:

```dart
class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when user.name changes, not email or other fields
    final name = ref.watch(userProvider.select((user) => user.name));

    return Text('Hello, $name!');
  }
}
```

## Async State with AsyncValue

`AsyncValue` is Riverpod's powerful type for handling async state with loading, error, and data states.

### AsyncValue Basics

```dart
final userProvider = FutureProvider<User>((ref) async {
  return await fetchUser();
});

// Pattern matching with when
class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Error: $error'),
    );
  }
}

// Or use maybeWhen with default
userAsync.maybeWhen(
  data: (user) => Text(user.name),
  orElse: () => const Text('Loading...'),
);
```

### Manual AsyncValue

```dart
@riverpod
class TodoList extends _$TodoList {
  @override
  AsyncValue<List<Todo>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadTodos() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await fetchTodos();
    });
  }

  Future<void> addTodo(String title) async {
    // Preserve previous data during loading
    state = const AsyncValue.loading().copyWithPrevious(state);

    state = await AsyncValue.guard(() async {
      final newTodo = await createTodo(title);
      final currentData = state.value ?? [];
      return [...currentData, newTodo];
    });
  }
}
```

### AsyncValue Patterns

```dart
// Check state manually
final userAsync = ref.watch(userProvider);

if (userAsync.isLoading) {
  return const CircularProgressIndicator();
}

if (userAsync.hasError) {
  return Text('Error: ${userAsync.error}');
}

if (userAsync.hasValue) {
  final user = userAsync.value!;
  return Text(user.name);
}

// Access value with default
final user = userAsync.valueOrNull ?? User.guest();

// Map data while preserving loading/error state
final userName = userAsync.when(
  data: (user) => user.name,
  loading: () => 'Loading...',
  error: (_, __) => 'Error',
);
```

### Pull-to-Refresh

```dart
@riverpod
class DataList extends _$DataList {
  @override
  Future<List<Item>> build() async {
    return await fetchItems();
  }

  Future<void> refresh() async {
    // Invalidate and rebuild
    ref.invalidateSelf();
  }
}

// In widget
class DataListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dataListProvider.notifier).refresh();
      },
      child: dataAsync.when(
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => ItemTile(items[index]),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => Text('Error: $error'),
      ),
    );
  }
}
```

## StateNotifier and StateNotifierProvider

For complex state logic without code generation (though code generation is recommended).

### Basic StateNotifier

```dart
class Counter extends StateNotifier<int> {
  Counter() : super(0);

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

final counterProvider = StateNotifierProvider<Counter, int>((ref) {
  return Counter();
});

// Usage
class CounterWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Column(
      children: [
        Text('$count'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### Complex StateNotifier

```dart
class TodoListNotifier extends StateNotifier<List<Todo>> {
  TodoListNotifier() : super([]);

  void addTodo(String title) {
    state = [
      ...state,
      Todo(
        id: DateTime.now().toString(),
        title: title,
        isCompleted: false,
      ),
    ];
  }

  void toggleTodo(String id) {
    state = [
      for (final todo in state)
        if (todo.id == id)
          todo.copyWith(isCompleted: !todo.isCompleted)
        else
          todo,
    ];
  }

  void removeTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
  }

  void clearCompleted() {
    state = state.where((todo) => !todo.isCompleted).toList();
  }
}

final todoListProvider =
    StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  return TodoListNotifier();
});
```

## Advanced Patterns

### Provider Dependencies

Providers can depend on other providers:

```dart
final userIdProvider = StateProvider<String?>((ref) => null);

final userProvider = FutureProvider<User?>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;

  return await fetchUser(userId);
});

final userPostsProvider = FutureProvider<List<Post>>((ref) async {
  // Depends on userProvider
  final user = await ref.watch(userProvider.future);
  if (user == null) return [];

  return await fetchUserPosts(user.id);
});
```

### Combining Providers

```dart
final firstNameProvider = StateProvider<String>((ref) => '');
final lastNameProvider = StateProvider<String>((ref) => '');

final fullNameProvider = Provider<String>((ref) {
  final firstName = ref.watch(firstNameProvider);
  final lastName = ref.watch(lastNameProvider);
  return '$firstName $lastName'.trim();
});
```

### Filtered Lists

```dart
enum TodoFilter { all, active, completed }

final todoFilterProvider = StateProvider<TodoFilter>((ref) {
  return TodoFilter.all;
});

final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  final filter = ref.watch(todoFilterProvider);

  switch (filter) {
    case TodoFilter.active:
      return todos.where((todo) => !todo.isCompleted).toList();
    case TodoFilter.completed:
      return todos.where((todo) => todo.isCompleted).toList();
    case TodoFilter.all:
      return todos;
  }
});
```

### Caching and Invalidation

```dart
@riverpod
Future<Product> product(ProductRef ref, String id) async {
  // Auto-dispose after 5 minutes of not being used
  ref.cacheFor(const Duration(minutes: 5));

  return await fetchProduct(id);
}

// Manually invalidate
ref.invalidate(productProvider);

// Invalidate specific instance
ref.invalidate(productProvider('product-123'));

// Refresh (invalidate and immediately rebuild)
await ref.refresh(productProvider('product-123'));
```

### Lifecycle Hooks

```dart
@riverpod
Future<Data> data(DataRef ref) async {
  // Called when provider is created
  print('Provider created');

  // Called when provider is disposed
  ref.onDispose(() {
    print('Provider disposed');
  });

  // Cancel on dispose
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    print('Tick');
  });

  ref.onDispose(() {
    timer.cancel();
  });

  return await fetchData();
}
```

## Testing with Riverpod

Riverpod's architecture makes testing straightforward.

### Unit Testing Providers

```dart
void main() {
  test('counter increments', () {
    final container = ProviderContainer();

    expect(container.read(counterProvider), 0);

    container.read(counterProvider.notifier).state++;

    expect(container.read(counterProvider), 1);

    container.dispose();
  });
}
```

### Testing with Overrides

```dart
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  test('loads user data', () async {
    final mockRepo = MockUserRepository();
    when(() => mockRepo.getUser('123')).thenAnswer(
      (_) async => User(id: '123', name: 'Test'),
    );

    final container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    final user = await container.read(userProvider('123').future);

    expect(user.name, 'Test');
    verify(() => mockRepo.getUser('123')).called(1);

    container.dispose();
  });
}
```

### Widget Testing

```dart
void main() {
  testWidgets('displays counter value', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CounterWidget(),
        ),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('with mocked provider', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          counterProvider.overrideWith((ref) => 42),
        ],
        child: const MaterialApp(
          home: CounterWidget(),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
  });
}
```

## Migration from Provider

Riverpod can coexist with Provider, enabling gradual migration.

### Side-by-Side

```dart
void main() {
  runApp(
    // Riverpod ProviderScope
    ProviderScope(
      child: MultiProvider(
        // Provider MultiProvider
        providers: [
          ChangeNotifierProvider(create: (_) => OldCounter()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
```

### Migration Strategy

1. **Add Riverpod**: Install flutter_riverpod alongside provider
2. **Wrap with ProviderScope**: Add ProviderScope at root
3. **Migrate incrementally**: Convert one feature at a time
4. **Use code generation**: Start new providers with @riverpod
5. **Remove Provider**: Once fully migrated, remove provider dependency

### Provider to Riverpod Equivalents

```dart
// Provider -> Provider
Provider<ApiConfig>(create: (_) => ApiConfig())
→ final apiConfigProvider = Provider((ref) => ApiConfig());

// ChangeNotifierProvider -> StateNotifierProvider or @riverpod class
ChangeNotifierProvider(create: (_) => Counter())
→ @riverpod class Counter extends _$Counter { ... }

// FutureProvider -> FutureProvider
FutureProvider<User>(create: (_) => fetchUser())
→ final userProvider = FutureProvider((ref) async => await fetchUser());

// StreamProvider -> StreamProvider
StreamProvider<Data>(create: (_) => dataStream)
→ final dataProvider = StreamProvider((ref) => dataStream);
```

## Conclusion

Riverpod is the modern state management solution for Flutter, offering:

- **Compile-time safety** catches errors before runtime
- **No BuildContext** enables provider access anywhere
- **AsyncValue** provides elegant async state handling
- **Code generation** reduces boilerplate
- **Auto-dispose** prevents memory leaks
- **Excellent testing** with easy overrides

Key takeaways:

- Use **@riverpod** code generation for new providers
- Use **ref.watch()** in build methods, **ref.read()** in callbacks
- Handle async state with **AsyncValue.when()**
- Override providers in tests for easy mocking
- Start with Riverpod for new projects—it's the recommended default

Riverpod represents the current best practices for Flutter state management, combining the simplicity of Provider with modern features that scale from simple apps to complex enterprise applications.
