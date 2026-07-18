# BLoC Architecture and Pattern

BLoC (Business Logic Component) is an architectural pattern for Flutter that enforces strict separation between business logic and UI through an event-driven approach. This guide covers BLoC fundamentals, the flutter_bloc package, and when to use this pattern.

## Table of Contents

1. [BLoC Pattern Overview](#bloc-pattern-overview)
2. [Core Concepts](#core-concepts)
3. [flutter_bloc Package](#flutter_bloc-package)
4. [Cubit - Simplified BLoC](#cubit---simplified-bloc)
5. [Advanced Patterns](#advanced-patterns)
6. [Testing BLoCs](#testing-blocs)
7. [Best Practices](#best-practices)
8. [When to Use BLoC](#when-to-use-bloc)

## BLoC Pattern Overview

The BLoC pattern separates business logic from presentation through a unidirectional data flow using streams. UI components send events to BLoCs, which process them and emit new states.

### Architecture

```
┌─────────────┐
│     UI      │
│   (Widget)  │
└──────┬──────┘
       │ Events
       ▼
┌─────────────┐
│    BLoC     │
│   (Logic)   │
└──────┬──────┘
       │ States
       ▼
┌─────────────┐
│     UI      │
│  (Rebuild)  │
└─────────────┘
```

### Why BLoC?

**Advantages:**
- **Testability**: Business logic completely isolated from UI
- **Reusability**: BLoCs can be shared across platforms (Flutter web, mobile, desktop)
- **Predictability**: Clear event-state flow makes debugging easier
- **Scalability**: Well-suited for large, complex applications
- **Team Structure**: Clear boundaries for team responsibilities

**When to Use BLoC:**
- Large enterprise applications
- Apps requiring strict architecture
- Teams needing clear separation of concerns
- Applications with complex business logic
- Projects requiring audit trails (event logging)
- Regulated industries (finance, healthcare)

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5  # For value equality in states/events

dev_dependencies:
  bloc_test: ^9.1.4  # For testing BLoCs
```

## Core Concepts

### Events

Events represent user interactions or system events that trigger state changes.

```dart
import 'package:equatable/equatable.dart';

abstract class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => [];
}

class CounterIncremented extends CounterEvent {
  const CounterIncremented();
}

class CounterDecremented extends CounterEvent {
  const CounterDecremented();
}

class CounterReset extends CounterEvent {
  const CounterReset();
}

// Events with data
class CounterIncrementedBy extends CounterEvent {
  final int value;

  const CounterIncrementedBy(this.value);

  @override
  List<Object?> get props => [value];
}
```

### States

States represent the current state of the application at any point in time.

```dart
import 'package:equatable/equatable.dart';

abstract class CounterState extends Equatable {
  const CounterState();

  @override
  List<Object?> get props => [];
}

class CounterInitial extends CounterState {
  const CounterInitial();
}

class CounterValue extends CounterState {
  final int count;

  const CounterValue(this.count);

  @override
  List<Object?> get props => [count];
}
```

### Bloc

The Bloc class processes events and emits states.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterInitial()) {
    on<CounterIncremented>(_onIncremented);
    on<CounterDecremented>(_onDecremented);
    on<CounterReset>(_onReset);
    on<CounterIncrementedBy>(_onIncrementedBy);
  }

  void _onIncremented(CounterIncremented event, Emitter<CounterState> emit) {
    final currentState = state;
    if (currentState is CounterValue) {
      emit(CounterValue(currentState.count + 1));
    } else {
      emit(const CounterValue(1));
    }
  }

  void _onDecremented(CounterDecremented event, Emitter<CounterState> emit) {
    final currentState = state;
    if (currentState is CounterValue) {
      emit(CounterValue(currentState.count - 1));
    }
  }

  void _onReset(CounterReset event, Emitter<CounterState> emit) {
    emit(const CounterInitial());
  }

  void _onIncrementedBy(
    CounterIncrementedBy event,
    Emitter<CounterState> emit,
  ) {
    final currentState = state;
    final currentCount = currentState is CounterValue ? currentState.count : 0;
    emit(CounterValue(currentCount + event.value));
  }
}
```

## flutter_bloc Package

The flutter_bloc package provides widgets for integrating BLoCs with Flutter's widget tree.

### BlocProvider

Provides a BLoC to its descendants and manages its lifecycle.

```dart
class CounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CounterBloc(),
      child: const CounterScreen(),
    );
  }
}
```

### MultiBlocProvider

Provides multiple BLoCs at once:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc()..add(AppStarted()),
    ),
    BlocProvider<ThemeBloc>(
      create: (context) => ThemeBloc(),
    ),
    BlocProvider<SettingsBloc>(
      create: (context) => SettingsBloc(),
    ),
  ],
  child: MyApp(),
)
```

### BlocBuilder

Rebuilds UI in response to state changes:

```dart
class CounterScreen extends StatelessWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: BlocBuilder<CounterBloc, CounterState>(
          builder: (context, state) {
            if (state is CounterInitial) {
              return const Text('Press the button to start');
            } else if (state is CounterValue) {
              return Text(
                '${state.count}',
                style: Theme.of(context).textTheme.headlineLarge,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              context.read<CounterBloc>().add(const CounterIncremented());
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              context.read<CounterBloc>().add(const CounterDecremented());
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```

### BlocListener

Performs side effects (navigation, dialogs) in response to state changes:

```dart
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthSuccess) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (state is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error)),
      );
    }
  },
  child: LoginForm(),
)
```

### BlocConsumer

Combines `BlocBuilder` and `BlocListener`:

```dart
BlocConsumer<AuthBloc, AuthState>(
  listener: (context, state) {
    // Side effects
    if (state is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error)),
      );
    }
  },
  builder: (context, state) {
    // UI building
    if (state is AuthLoading) {
      return const CircularProgressIndicator();
    } else if (state is AuthSuccess) {
      return Text('Welcome, ${state.user.name}!');
    }
    return const LoginButton();
  },
)
```

### BlocSelector

Rebuilds only when a specific part of state changes:

```dart
BlocSelector<UserBloc, UserState, String>(
  selector: (state) {
    if (state is UserLoaded) {
      return state.user.name;
    }
    return '';
  },
  builder: (context, name) {
    return Text('Hello, $name!');
  },
)
```

## Cubit - Simplified BLoC

Cubit is a simplified version of BLoC that doesn't use events. It's easier to use for simple scenarios.

### Basic Cubit

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
  void reset() => emit(0);
}

// Usage
BlocProvider(
  create: (_) => CounterCubit(),
  child: BlocBuilder<CounterCubit, int>(
    builder: (context, count) {
      return Text('$count');
    },
  ),
)

// Trigger state changes
context.read<CounterCubit>().increment();
```

### Complex Cubit with Multiple States

```dart
// States
abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;

  const TodoLoaded(this.todos);

  @override
  List<Object?> get props => [todos];
}

class TodoError extends TodoState {
  final String message;

  const TodoError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class TodoCubit extends Cubit<TodoState> {
  final TodoRepository repository;

  TodoCubit({required this.repository}) : super(TodoInitial());

  Future<void> loadTodos() async {
    emit(TodoLoading());

    try {
      final todos = await repository.fetchTodos();
      emit(TodoLoaded(todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> addTodo(String title) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      try {
        final newTodo = await repository.addTodo(title);
        emit(TodoLoaded([...currentState.todos, newTodo]));
      } catch (e) {
        emit(TodoError(e.toString()));
      }
    }
  }

  Future<void> toggleTodo(String id) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      final todos = currentState.todos.map((todo) {
        if (todo.id == id) {
          return todo.copyWith(isCompleted: !todo.isCompleted);
        }
        return todo;
      }).toList();

      emit(TodoLoaded(todos));

      try {
        await repository.updateTodo(
          todos.firstWhere((todo) => todo.id == id),
        );
      } catch (e) {
        // Rollback on error
        emit(TodoLoaded(currentState.todos));
        emit(TodoError(e.toString()));
      }
    }
  }

  Future<void> deleteTodo(String id) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      final todos = currentState.todos.where((todo) => todo.id != id).toList();

      emit(TodoLoaded(todos));

      try {
        await repository.deleteTodo(id);
      } catch (e) {
        emit(TodoLoaded(currentState.todos));
        emit(TodoError(e.toString()));
      }
    }
  }
}
```

## Advanced Patterns

### Async Event Handling

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository repository;

  UserBloc({required this.repository}) : super(UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateUser>(_onUpdateUser);
  }

  Future<void> _onLoadUser(
    LoadUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    try {
      final user = await repository.getUser(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      emit(UserUpdating(currentState.user));

      try {
        final updatedUser = await repository.updateUser(event.user);
        emit(UserLoaded(updatedUser));
      } catch (e) {
        emit(UserLoaded(currentState.user));
        emit(UserError(e.toString()));
      }
    }
  }
}
```

### Stream Transformations

Control how events are processed with transformers:

```dart
import 'package:stream_transform/stream_transform.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      // Debounce: Wait 300ms after last event before processing
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());

    try {
      final results = await searchApi.search(event.query);
      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}

// Debounce transformer
EventTransformer<T> debounce<T>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}
```

### Bloc-to-Bloc Communication

```dart
class CartBloc extends Bloc<CartEvent, CartState> {
  final AuthBloc authBloc;
  late StreamSubscription authSubscription;

  CartBloc({required this.authBloc}) : super(CartEmpty()) {
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);

    // Listen to auth changes
    authSubscription = authBloc.stream.listen((authState) {
      if (authState is AuthLoggedOut) {
        add(ClearCart());
      }
    });
  }

  @override
  Future<void> close() {
    authSubscription.cancel();
    return super.close();
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) {
    // Only allow if authenticated
    if (authBloc.state is! AuthAuthenticated) {
      emit(CartError('Must be logged in to add to cart'));
      return;
    }

    final currentState = state;
    if (currentState is CartLoaded) {
      final items = [...currentState.items, event.item];
      emit(CartLoaded(items));
    } else {
      emit(CartLoaded([event.item]));
    }
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) {
    if (state is CartLoaded) {
      final currentState = state as CartLoaded;
      final items = currentState.items
          .where((item) => item.id != event.itemId)
          .toList();

      if (items.isEmpty) {
        emit(CartEmpty());
      } else {
        emit(CartLoaded(items));
      }
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartEmpty());
  }
}
```

### Hydrated BLoC (Persistence)

Save and restore bloc state automatically:

```dart
// Add dependency: hydrated_bloc: ^9.1.0

import 'package:hydrated_bloc/hydrated_bloc.dart';

class CounterCubit extends HydratedCubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);

  @override
  int? fromJson(Map<String, dynamic> json) {
    return json['count'] as int?;
  }

  @override
  Map<String, dynamic>? toJson(int state) {
    return {'count': state};
  }
}

// Setup in main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

  runApp(MyApp());
}
```

### BLoC Observers

Monitor all bloc events and state changes:

```dart
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    print('onCreate -- ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    print('onEvent -- ${bloc.runtimeType}, $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('onChange -- ${bloc.runtimeType}, $change');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('onTransition -- ${bloc.runtimeType}, $transition');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    print('onError -- ${bloc.runtimeType}, $error');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    print('onClose -- ${bloc.runtimeType}');
  }
}

// Setup in main
void main() {
  Bloc.observer = AppBlocObserver();
  runApp(MyApp());
}
```

## Testing BLoCs

BLoCs are highly testable since they're isolated from the UI.

### Unit Testing with bloc_test

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:test/test.dart';

void main() {
  group('CounterBloc', () {
    late CounterBloc counterBloc;

    setUp(() {
      counterBloc = CounterBloc();
    });

    tearDown(() {
      counterBloc.close();
    });

    test('initial state is CounterInitial', () {
      expect(counterBloc.state, equals(const CounterInitial()));
    });

    blocTest<CounterBloc, CounterState>(
      'emits [CounterValue(1)] when CounterIncremented is added',
      build: () => CounterBloc(),
      act: (bloc) => bloc.add(const CounterIncremented()),
      expect: () => [const CounterValue(1)],
    );

    blocTest<CounterBloc, CounterState>(
      'emits [CounterValue(5)] when CounterIncrementedBy(5) is added',
      build: () => CounterBloc(),
      act: (bloc) => bloc.add(const CounterIncrementedBy(5)),
      expect: () => [const CounterValue(5)],
    );

    blocTest<CounterBloc, CounterState>(
      'emits multiple states when multiple events are added',
      build: () => CounterBloc(),
      act: (bloc) => bloc
        ..add(const CounterIncremented())
        ..add(const CounterIncremented())
        ..add(const CounterDecremented()),
      expect: () => [
        const CounterValue(1),
        const CounterValue(2),
        const CounterValue(1),
      ],
    );
  });
}
```

### Testing with Mocked Dependencies

```dart
class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  group('TodoBloc', () {
    late TodoRepository repository;
    late TodoBloc todoBloc;

    setUp(() {
      repository = MockTodoRepository();
      todoBloc = TodoBloc(repository: repository);
    });

    tearDown(() {
      todoBloc.close();
    });

    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoading, TodoLoaded] when LoadTodos succeeds',
      build: () {
        when(() => repository.fetchTodos()).thenAnswer(
          (_) async => [
            Todo(id: '1', title: 'Test', isCompleted: false),
          ],
        );
        return todoBloc;
      },
      act: (bloc) => bloc.add(LoadTodos()),
      expect: () => [
        TodoLoading(),
        TodoLoaded([Todo(id: '1', title: 'Test', isCompleted: false)]),
      ],
      verify: (_) {
        verify(() => repository.fetchTodos()).called(1);
      },
    );

    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoading, TodoError] when LoadTodos fails',
      build: () {
        when(() => repository.fetchTodos()).thenThrow(
          Exception('Failed to load'),
        );
        return todoBloc;
      },
      act: (bloc) => bloc.add(LoadTodos()),
      expect: () => [
        TodoLoading(),
        isA<TodoError>()
            .having((e) => e.message, 'message', contains('Failed to load')),
      ],
    );
  });
}
```

### Widget Testing with BLoCs

```dart
void main() {
  group('CounterScreen', () {
    testWidgets('renders current count', (tester) async {
      final bloc = CounterBloc();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const CounterScreen(),
          ),
        ),
      );

      expect(find.text('Press the button to start'), findsOneWidget);

      bloc.add(const CounterIncremented());
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('calls increment when button pressed', (tester) async {
      final bloc = MockCounterBloc();

      when(() => bloc.state).thenReturn(const CounterValue(0));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CounterBloc>.value(
            value: bloc,
            child: const CounterScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));

      verify(() => bloc.add(const CounterIncremented())).called(1);
    });
  });
}
```

## Best Practices

### 1. Use Equatable for Value Equality

Always use `Equatable` for events and states to ensure proper comparison:

```dart
// ✅ Good
class CounterValue extends CounterState with EquatableMixin {
  final int count;

  CounterValue(this.count);

  @override
  List<Object?> get props => [count];
}

// ❌ Bad - Won't detect duplicate states
class CounterValue extends CounterState {
  final int count;
  CounterValue(this.count);
}
```

### 2. Keep BLoCs Focused

Each BLoC should have a single responsibility:

```dart
// ✅ Good - Focused responsibilities
AuthBloc()
UserProfileBloc()
NotificationBloc()

// ❌ Bad - Too many responsibilities
AppBloc() // Handles auth, profile, notifications, theme...
```

### 3. Handle All States in UI

Always handle loading, error, and success states:

```dart
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    if (state is UserLoading) {
      return const CircularProgressIndicator();
    } else if (state is UserError) {
      return ErrorWidget(message: state.message);
    } else if (state is UserLoaded) {
      return UserProfile(user: state.user);
    }
    return const SizedBox.shrink();
  },
)
```

### 4. Use BlocListener for Side Effects

Don't perform side effects in builders:

```dart
// ✅ Good - Side effects in listener
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthSuccess) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  },
  child: LoginForm(),
)

// ❌ Bad - Side effects in builder
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthSuccess) {
      Navigator.pushReplacementNamed(context, '/home'); // Don't do this!
    }
    return LoginForm();
  },
)
```

### 5. Don't Access BLoC in Event Handlers

BLoC event handlers should be pure functions of the event and current state:

```dart
// ✅ Good
void _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
  final userId = event.userId; // From event
  final user = await repository.getUser(userId);
  emit(UserLoaded(user));
}

// ❌ Bad - Accessing external state
void _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
  final userId = authBloc.currentUserId; // Don't access other BLoCs
  final user = await repository.getUser(userId);
  emit(UserLoaded(user));
}
```

### 6. Close BLoCs Properly

Always close BLoCs when done to prevent memory leaks. `BlocProvider` handles this automatically, but manual instances need closing:

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final MyBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MyBloc();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: MyContent(),
    );
  }
}
```

### 7. Use Cubit for Simple State

If you don't need event logging or complex transformations, use Cubit:

```dart
// Simple state - use Cubit
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  void toggleTheme() {
    emit(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

// Complex state with audit trail - use BLoC
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  // Events are logged for audit purposes
}
```

## When to Use BLoC

### Use BLoC When:

✅ Building enterprise or large-scale applications
✅ You need strict separation of concerns
✅ Event logging and audit trails are required
✅ Multiple team members work on the same codebase
✅ Your app has complex business logic
✅ You're in a regulated industry (finance, healthcare)
✅ You need to share logic across multiple platforms
✅ Testability is a top priority

### Consider Alternatives When:

❌ Building a simple app or MVP
❌ Your team is new to Flutter (start with Provider)
❌ You need rapid prototyping
❌ The app has minimal business logic
❌ You prefer less boilerplate (consider Riverpod)

## Conclusion

BLoC is a powerful architectural pattern for Flutter that enforces discipline and scalability. Key takeaways:

- **Events** represent user actions, **States** represent app state, **BLoCs** process events and emit states
- Use **Cubit** for simple scenarios, **BLoC** for complex event-driven logic
- BLoC widgets (`BlocBuilder`, `BlocListener`, `BlocConsumer`) integrate BLoCs with Flutter
- BLoCs are highly testable with `bloc_test` package
- Best for large applications with complex business logic
- Overkill for simple apps—start with Provider or built-in solutions

BLoC shines in enterprise environments where predictability, testability, and clear architectural boundaries are essential. If your project fits these criteria, BLoC provides a robust foundation for scaling your Flutter application.
