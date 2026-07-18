# Built-in State Management Solutions

Flutter provides powerful built-in state management primitives that can handle many common scenarios without requiring external packages. Understanding these fundamentals is essential whether you're building simple apps or need to understand what's happening under the hood of higher-level state management solutions.

## Table of Contents

1. [setState() - The Foundation](#setstate---the-foundation)
2. [ValueNotifier - Reactive Single Values](#valuenotifier---reactive-single-values)
3. [ChangeNotifier - Custom Observable Objects](#changenotifier---custom-observable-objects)
4. [InheritedWidget - Data Propagation](#inheritedwidget---data-propagation)
5. [InheritedNotifier - Combining Patterns](#inheritednotifier---combining-patterns)
6. [StreamBuilder - Async Streams](#streambuilder---async-streams)
7. [FutureBuilder - One-Time Async Operations](#futurebuilder---one-time-async-operations)
8. [Comparison and When to Use Each](#comparison-and-when-to-use-each)

## setState() - The Foundation

`setState()` is the most fundamental state management tool in Flutter. It's used within `StatefulWidget` to notify the framework that internal state has changed and the widget needs to be rebuilt.

### When to Use

Use `setState()` for:
- Ephemeral state scoped to a single widget
- Simple UI state like toggles, counters, or form inputs
- State that doesn't need to be shared with other widgets
- Rapid prototyping and learning Flutter

### How It Works

```dart
class CounterWidget extends StatefulWidget {
  const CounterWidget({Key? key}) : super(key: key);

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // All state mutations should happen within setState()
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method runs every time setState() is called
    return Column(
      children: [
        Text('Count: $_counter'),
        ElevatedButton(
          onPressed: _incrementCounter,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### Best Practices

**DO:**
- Keep state mutations inside `setState()`
- Make `setState()` calls synchronous and fast
- Use `setState()` for simple, localized state

**DON'T:**
- Call async operations directly inside `setState()`
- Call `setState()` after widget is disposed
- Use `setState()` for state shared across multiple screens

### Common Patterns

#### Handling Async Operations

```dart
class DataWidget extends StatefulWidget {
  @override
  State<DataWidget> createState() => _DataWidgetState();
}

class _DataWidgetState extends State<DataWidget> {
  bool _isLoading = false;
  String? _data;
  String? _error;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await fetchData();
      if (!mounted) return; // Check if widget is still in tree

      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const CircularProgressIndicator();
    if (_error != null) return Text('Error: $_error');
    if (_data == null) return const Text('No data');
    return Text(_data!);
  }
}
```

#### Form State Management

```dart
class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Process login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value?.contains('@') ?? false ? null : 'Invalid email',
            onSaved: (value) => _email = value ?? '',
          ),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) =>
                (value?.length ?? 0) >= 6 ? null : 'Password too short',
            onSaved: (value) => _password = value ?? '',
          ),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

## ValueNotifier - Reactive Single Values

`ValueNotifier<T>` is a `ChangeNotifier` that holds a single value. When the value changes, it notifies all registered listeners. This is perfect for simple reactive values that need to be observed.

### When to Use

Use `ValueNotifier` for:
- Single reactive values (numbers, strings, booleans)
- State that multiple widgets need to observe
- Avoiding unnecessary rebuilds with `ValueListenableBuilder`
- Simple reactive programming without external packages

### Basic Implementation

```dart
class CounterNotifier {
  // Create a ValueNotifier holding an integer
  final ValueNotifier<int> counter = ValueNotifier<int>(0);

  void increment() {
    counter.value++; // Automatically notifies listeners
  }

  void dispose() {
    counter.dispose(); // Clean up when done
  }
}

// Using ValueNotifier in a widget
class CounterDisplay extends StatelessWidget {
  final ValueNotifier<int> counter;

  const CounterDisplay({Key? key, required this.counter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: counter,
      builder: (context, value, child) {
        // Only this builder rebuilds when counter changes
        return Text('Count: $value');
      },
    );
  }
}
```

### Advanced Patterns

#### Multiple ValueNotifiers

```dart
class ThemeController {
  final ValueNotifier<bool> isDarkMode = ValueNotifier(false);
  final ValueNotifier<double> textScale = ValueNotifier(1.0);

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }

  void increaseTextSize() {
    textScale.value = (textScale.value + 0.1).clamp(0.5, 2.0);
  }

  void dispose() {
    isDarkMode.dispose();
    textScale.dispose();
  }
}

// Usage with multiple listeners
class SettingsScreen extends StatelessWidget {
  final ThemeController controller;

  const SettingsScreen({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: controller.isDarkMode,
          builder: (context, isDark, _) {
            return SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDark,
              onChanged: (_) => controller.toggleTheme(),
            );
          },
        ),
        ValueListenableBuilder<double>(
          valueListenable: controller.textScale,
          builder: (context, scale, _) {
            return ListTile(
              title: Text('Text Size: ${scale.toStringAsFixed(1)}x'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: controller.increaseTextSize,
              ),
            );
          },
        ),
      ],
    );
  }
}
```

#### Computed Values

```dart
class ShoppingCart {
  final ValueNotifier<List<CartItem>> items = ValueNotifier([]);

  // Computed value using custom notifier
  late final ValueNotifier<double> total = _ComputedValueNotifier(
    items,
    (items) => items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    ),
  );

  void addItem(CartItem item) {
    items.value = [...items.value, item];
  }

  void dispose() {
    items.dispose();
    total.dispose();
  }
}

class _ComputedValueNotifier<S, T> extends ValueNotifier<T> {
  _ComputedValueNotifier(this.source, this.compute) : super(compute(source.value)) {
    source.addListener(_onSourceChanged);
  }

  final ValueNotifier<S> source;
  final T Function(S) compute;

  void _onSourceChanged() {
    value = compute(source.value);
  }

  @override
  void dispose() {
    source.removeListener(_onSourceChanged);
    super.dispose();
  }
}
```

### Performance Benefits

`ValueListenableBuilder` only rebuilds the widget subtree inside its builder, making it more efficient than `setState()` which rebuilds the entire widget:

```dart
class OptimizedWidget extends StatelessWidget {
  final ValueNotifier<int> counter = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    print('OptimizedWidget.build called'); // Only called once

    return Column(
      children: [
        const ExpensiveWidget(), // Never rebuilds
        ValueListenableBuilder<int>(
          valueListenable: counter,
          builder: (context, value, child) {
            print('Builder called'); // Called when counter changes
            return Text('Count: $value');
          },
        ),
        ElevatedButton(
          onPressed: () => counter.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

## ChangeNotifier - Custom Observable Objects

`ChangeNotifier` is a class that provides a change notification API using the observer pattern. It's the foundation for many Flutter state management solutions.

### When to Use

Use `ChangeNotifier` for:
- Custom model classes with multiple properties
- Complex state with multiple fields that change together
- Implementing custom observable objects
- Building your own state management solution

### Basic Implementation

```dart
class Counter extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners(); // Notify all observers
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

// Usage with AnimatedBuilder (works with any Listenable)
class CounterDisplay extends StatelessWidget {
  final Counter counter;

  const CounterDisplay({Key? key, required this.counter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: counter, // ChangeNotifier implements Listenable
      builder: (context, child) {
        return Text('Count: ${counter.count}');
      },
    );
  }
}
```

### Complex State Management

```dart
class TodoList extends ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);

  int get completedCount => _todos.where((todo) => todo.isCompleted).length;

  int get activeCount => _todos.where((todo) => !todo.isCompleted).length;

  void addTodo(String title) {
    _todos.add(Todo(
      id: DateTime.now().toString(),
      title: title,
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

  void removeTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _todos.removeWhere((todo) => todo.isCompleted);
    notifyListeners();
  }
}

class Todo {
  final String id;
  final String title;
  final bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  Todo copyWith({String? title, bool? isCompleted}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
```

### Async State with ChangeNotifier

```dart
class UserProfile extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await fetchUser(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserUpdate update) async {
    if (_user == null) return;

    final updatedUser = _user!.copyWith(
      name: update.name ?? _user!.name,
      email: update.email ?? _user!.email,
    );

    // Optimistic update
    _user = updatedUser;
    notifyListeners();

    try {
      await saveUser(updatedUser);
    } catch (e) {
      // Revert on error
      await loadUser(_user!.id);
      _error = 'Failed to update profile';
      notifyListeners();
    }
  }
}
```

### Best Practices

**DO:**
- Always call `notifyListeners()` after state changes
- Make state immutable when possible
- Dispose of `ChangeNotifier` when no longer needed
- Use private fields with public getters

**DON'T:**
- Forget to call `notifyListeners()`
- Call `notifyListeners()` during a build
- Expose mutable state directly
- Create circular dependencies between notifiers

## InheritedWidget - Data Propagation

`InheritedWidget` is a special widget that efficiently propagates data down the widget tree. It's the foundation for how Provider, Riverpod, and other state management solutions work.

### When to Use

Use `InheritedWidget` for:
- Sharing data across many descendants
- Theme or configuration data
- Building custom dependency injection
- Understanding how Provider works internally

### Basic Implementation

```dart
class CounterProvider extends InheritedWidget {
  final int counter;
  final VoidCallback increment;

  const CounterProvider({
    Key? key,
    required this.counter,
    required this.increment,
    required Widget child,
  }) : super(key: key, child: child);

  // Access method for descendants
  static CounterProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CounterProvider>();
  }

  static CounterProvider of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No CounterProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(CounterProvider oldWidget) {
    // Return true if descendants should rebuild
    return counter != oldWidget.counter;
  }
}

// Usage
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CounterProvider(
      counter: _counter,
      increment: _increment,
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }
}

// Accessing from descendants
class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = CounterProvider.of(context);
    return Text('Count: ${provider.counter}');
  }
}

class IncrementButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = CounterProvider.of(context);
    return ElevatedButton(
      onPressed: provider.increment,
      child: const Text('Increment'),
    );
  }
}
```

### Advanced Pattern: InheritedWidget with State

```dart
class AppState {
  final bool isDarkMode;
  final String username;

  AppState({required this.isDarkMode, required this.username});

  AppState copyWith({bool? isDarkMode, String? username}) {
    return AppState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      username: username ?? this.username,
    );
  }
}

class AppStateProvider extends StatefulWidget {
  final Widget child;

  const AppStateProvider({Key? key, required this.child}) : super(key: key);

  @override
  State<AppStateProvider> createState() => AppStateProviderState();

  static AppStateProviderState of(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<_InheritedAppState>()
        ?.state;
    assert(result != null, 'No AppStateProvider found in context');
    return result!;
  }
}

class AppStateProviderState extends State<AppStateProvider> {
  AppState _state = AppState(isDarkMode: false, username: 'Guest');

  AppState get state => _state;

  void updateState(AppState newState) {
    setState(() {
      _state = newState;
    });
  }

  void toggleTheme() {
    updateState(_state.copyWith(isDarkMode: !_state.isDarkMode));
  }

  void setUsername(String username) {
    updateState(_state.copyWith(username: username));
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedAppState(
      state: this,
      child: widget.child,
    );
  }
}

class _InheritedAppState extends InheritedWidget {
  final AppStateProviderState state;

  const _InheritedAppState({
    required this.state,
    required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(_InheritedAppState oldWidget) {
    return state._state != oldWidget.state._state;
  }
}
```

## InheritedNotifier - Combining Patterns

`InheritedNotifier` combines `InheritedWidget` with `Listenable` (like `ChangeNotifier` or `ValueNotifier`). This is a powerful pattern for sharing reactive state.

### Implementation

```dart
class ThemeNotifier extends ValueNotifier<ThemeData> {
  ThemeNotifier(ThemeData value) : super(value);

  void toggleBrightness() {
    value = value.brightness == Brightness.dark
        ? ThemeData.light()
        : ThemeData.dark();
  }
}

class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    Key? key,
    required ThemeNotifier notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static ThemeNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>()!
        .notifier!;
  }
}

// Usage
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeNotifier = ThemeNotifier(ThemeData.light());

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: _themeNotifier,
      child: Builder(
        builder: (context) {
          final theme = ThemeProvider.of(context).value;
          return MaterialApp(
            theme: theme,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
```

## StreamBuilder - Async Streams

`StreamBuilder` connects your UI to a `Stream`, automatically rebuilding when new events arrive. Perfect for real-time data like WebSocket messages, database changes, or continuous sensor readings.

### When to Use

Use `StreamBuilder` for:
- Real-time data streams (chat messages, live updates)
- Firebase Firestore snapshots
- WebSocket connections
- Continuous sensor data
- Any data that updates continuously over time

### Basic Implementation

```dart
class MessagesWidget extends StatelessWidget {
  final Stream<List<Message>> messagesStream;

  const MessagesWidget({Key? key, required this.messagesStream})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
      stream: messagesStream,
      builder: (context, snapshot) {
        // Handle different connection states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No messages');
        }

        final messages = snapshot.data!;
        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return MessageTile(message: messages[index]);
          },
        );
      },
    );
  }
}
```

### Advanced Patterns

#### Stream with Initial Data

```dart
StreamBuilder<int>(
  stream: counterStream,
  initialData: 0, // Show immediately while waiting
  builder: (context, snapshot) {
    return Text('Count: ${snapshot.data}');
  },
)
```

#### Multiple Stream States

```dart
class UserPresenceWidget extends StatelessWidget {
  final Stream<UserPresence> presenceStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserPresence>(
      stream: presenceStream,
      builder: (context, snapshot) {
        // Check connection state first
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const Text('Not connected');
          case ConnectionState.waiting:
            return const CircularProgressIndicator();
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (!snapshot.hasData) {
              return const Text('No data');
            }

            final presence = snapshot.data!;
            return Row(
              children: [
                CircleAvatar(
                  radius: 6,
                  backgroundColor: presence.isOnline
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(presence.isOnline ? 'Online' : 'Offline'),
              ],
            );
        }
      },
    );
  }
}
```

### Best Practices

**DO:**
- Create streams in `initState()` or as final fields, never in `build()`
- Dispose of stream controllers when done
- Handle all connection states (none, waiting, active, done)
- Check for errors with `snapshot.hasError`

**DON'T:**
- Create new streams in the build method (causes infinite rebuilds)
- Forget to cancel stream subscriptions
- Assume data is always available
- Ignore connection states

### Common Mistake: Stream in Build Method

```dart
// ❌ WRONG - Creates new stream on every build
StreamBuilder<int>(
  stream: Stream.periodic(Duration(seconds: 1), (count) => count),
  builder: (context, snapshot) => Text('${snapshot.data}'),
)

// ✅ CORRECT - Create stream once
class CorrectStreamWidget extends StatefulWidget {
  @override
  State<CorrectStreamWidget> createState() => _CorrectStreamWidgetState();
}

class _CorrectStreamWidgetState extends State<CorrectStreamWidget> {
  late final Stream<int> _stream;

  @override
  void initState() {
    super.initState();
    _stream = Stream.periodic(
      const Duration(seconds: 1),
      (count) => count,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stream,
      builder: (context, snapshot) => Text('${snapshot.data}'),
    );
  }
}
```

## FutureBuilder - One-Time Async Operations

`FutureBuilder` connects your UI to a `Future`, displaying loading, error, and success states automatically. Use it for one-time async operations like API calls or database queries.

### When to Use

Use `FutureBuilder` for:
- Loading data from APIs
- One-time database queries
- File I/O operations
- Any asynchronous operation that completes once

### Basic Implementation

```dart
class UserProfileWidget extends StatelessWidget {
  final Future<User> userFuture;

  const UserProfileWidget({Key? key, required this.userFuture})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data'));
        }

        final user = snapshot.data!;
        return Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.avatarUrl),
              radius: 50,
            ),
            const SizedBox(height: 16),
            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(user.email),
          ],
        );
      },
    );
  }
}
```

### Correct Future Management

The future must be created in `initState()`, `didUpdateWidget()`, or `didChangeDependencies()`, not in the `build()` method:

```dart
// ❌ WRONG - Future recreated on every build
class WrongFutureWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: fetchData(), // Recreated on every build!
      builder: (context, snapshot) => Text(snapshot.data ?? 'Loading...'),
    );
  }
}

// ✅ CORRECT - Future created once
class CorrectFutureWidget extends StatefulWidget {
  @override
  State<CorrectFutureWidget> createState() => _CorrectFutureWidgetState();
}

class _CorrectFutureWidgetState extends State<CorrectFutureWidget> {
  late final Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchData(); // Created once
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) => Text(snapshot.data ?? 'Loading...'),
    );
  }
}
```

### Pull-to-Refresh Pattern

```dart
class RefreshableDataWidget extends StatefulWidget {
  @override
  State<RefreshableDataWidget> createState() => _RefreshableDataWidgetState();
}

class _RefreshableDataWidgetState extends State<RefreshableDataWidget> {
  late Future<List<Item>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<List<Item>> _loadData() async {
    return await fetchItems();
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Item>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ItemTile(item: items[index]);
            },
          );
        },
      ),
    );
  }
}
```

### Best Practices

**DO:**
- Create futures in `initState()`, never in `build()`
- Handle all connection states
- Provide retry mechanisms for errors
- Use `initialData` if you have cached data

**DON'T:**
- Create futures in the build method
- Assume the future always succeeds
- Ignore loading and error states
- Use FutureBuilder for streams (use StreamBuilder instead)

## Comparison and When to Use Each

| Solution | Use Case | Complexity | Rebuild Scope |
|----------|----------|------------|---------------|
| `setState()` | Ephemeral widget state | Low | Entire widget |
| `ValueNotifier` | Single reactive value | Low | ValueListenableBuilder only |
| `ChangeNotifier` | Custom observable objects | Medium | AnimatedBuilder only |
| `InheritedWidget` | Propagate data down tree | Medium | Dependent widgets |
| `InheritedNotifier` | Combine inheritance + observation | Medium | Dependent widgets |
| `StreamBuilder` | Continuous async data | Medium | Builder only |
| `FutureBuilder` | One-time async operations | Low | Builder only |

### Decision Guide

**Start with `setState()` if:**
- State is scoped to a single widget
- You don't need granular rebuilds
- You're prototyping quickly

**Upgrade to `ValueNotifier` when:**
- You need granular rebuilds
- State is observed by multiple widgets
- You want simple reactivity

**Use `ChangeNotifier` when:**
- You have complex state with multiple fields
- You need custom business logic
- You're building a reusable state class

**Consider `InheritedWidget` when:**
- You need dependency injection
- You're sharing config/theme data
- You want to understand Provider's internals

**Choose `StreamBuilder` for:**
- Real-time data streams
- WebSocket or Firebase updates
- Continuous sensor data

**Choose `FutureBuilder` for:**
- API calls and HTTP requests
- One-time database queries
- File operations

### Combining Approaches

You can and should combine these approaches:

```dart
class HybridWidget extends StatefulWidget {
  @override
  State<HybridWidget> createState() => _HybridWidgetState();
}

class _HybridWidgetState extends State<HybridWidget> {
  // Future for initial data load
  late final Future<Config> _configFuture;

  // Stream for real-time updates
  late final Stream<List<Message>> _messagesStream;

  // ValueNotifier for local reactive state
  final ValueNotifier<bool> _isFiltered = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _configFuture = loadConfig();
    _messagesStream = watchMessages();
  }

  @override
  void dispose() {
    _isFiltered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Config>(
      future: _configFuture,
      builder: (context, configSnapshot) {
        if (!configSnapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _isFiltered,
              builder: (context, isFiltered, _) {
                return SwitchListTile(
                  title: const Text('Filter Messages'),
                  value: isFiltered,
                  onChanged: (value) => _isFiltered.value = value,
                );
              },
            ),
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _messagesStream,
                builder: (context, messagesSnapshot) {
                  if (!messagesSnapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  var messages = messagesSnapshot.data!;
                  if (_isFiltered.value) {
                    messages = messages.where((m) => !m.isRead).toList();
                  }

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return MessageTile(message: messages[index]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
```

## Conclusion

Flutter's built-in state management solutions are powerful and flexible. They form the foundation of all higher-level state management packages. Understanding these primitives will help you:

- Choose the right tool for each situation
- Understand how Provider, Riverpod, and BLoC work internally
- Build custom state management solutions when needed
- Write more efficient Flutter applications

Start with `setState()` and `FutureBuilder`, then graduate to `ValueNotifier` and `ChangeNotifier` as your needs grow. Only reach for external packages when built-in solutions become unwieldy for your use case.
