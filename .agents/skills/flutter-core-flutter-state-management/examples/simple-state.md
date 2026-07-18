# Simple State Management Examples

This guide demonstrates implementing the classic counter app using different state management approaches. Seeing the same functionality implemented multiple ways helps understand the trade-offs and patterns of each solution.

## Table of Contents

1. [The Counter App Spec](#the-counter-app-spec)
2. [setState Implementation](#setstate-implementation)
3. [ValueNotifier Implementation](#valuenotifier-implementation)
4. [Provider Implementation](#provider-implementation)
5. [Riverpod Implementation](#riverpod-implementation)
6. [BLoC Implementation](#bloc-implementation)
7. [Comparison](#comparison)

## The Counter App Spec

Our counter app has the following features:
- Display current count (starts at 0)
- Increment button (+1)
- Decrement button (-1)
- Reset button (back to 0)
- Display whether count is even or odd

This simple spec lets us focus on the state management patterns rather than complex business logic.

## setState Implementation

The most basic approach using StatefulWidget and setState().

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter - setState',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    setState(() {
      _count--;
    });
  }

  void _reset() {
    setState(() {
      _count = 0;
    });
  }

  String get _parity => _count % 2 == 0 ? 'Even' : 'Odd';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter - setState')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_count',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _parity,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _decrement,
                  heroTag: 'decrement',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: _increment,
                  heroTag: 'increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _reset,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Pros:**
- Simplest implementation
- No external dependencies
- Easy to understand
- Fast to write

**Cons:**
- Entire widget rebuilds on every change
- Can't share state easily
- Hard to test business logic
- Doesn't scale well

## ValueNotifier Implementation

Using ValueNotifier for reactive state without StatefulWidget.

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter - ValueNotifier',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CounterScreen(),
    );
  }
}

class Counter {
  final ValueNotifier<int> count = ValueNotifier(0);

  void increment() => count.value++;
  void decrement() => count.value--;
  void reset() => count.value = 0;

  void dispose() {
    count.dispose();
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final Counter _counter = Counter();

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  String _getParity(int count) => count % 2 == 0 ? 'Even' : 'Odd';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter - ValueNotifier')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Only rebuilds when count changes
            ValueListenableBuilder<int>(
              valueListenable: _counter.count,
              builder: (context, count, child) {
                return Column(
                  children: [
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getParity(count),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _counter.decrement,
                  heroTag: 'decrement',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: _counter.increment,
                  heroTag: 'increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _counter.reset,
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Pros:**
- Granular rebuilds (only ValueListenableBuilder rebuilds)
- Better separation of logic
- Still no external dependencies
- More testable than setState

**Cons:**
- Still requires manual disposal
- Sharing across widgets needs InheritedWidget
- More boilerplate than setState

## Provider Implementation

Using the Provider package with ChangeNotifier.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MyApp());

class Counter with ChangeNotifier {
  int _count = 0;

  int get count => _count;
  String get parity => _count % 2 == 0 ? 'Even' : 'Odd';

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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Counter(),
      child: MaterialApp(
        title: 'Counter - Provider',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const CounterScreen(),
      ),
    );
  }
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter - Provider')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Only rebuilds when counter changes
            Consumer<Counter>(
              builder: (context, counter, child) {
                return Column(
                  children: [
                    Text(
                      '${counter.count}',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      counter.parity,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () => context.read<Counter>().decrement(),
                  heroTag: 'decrement',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => context.read<Counter>().increment(),
                  heroTag: 'increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<Counter>().reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Pros:**
- Clean separation of logic
- Easy to share state across widgets
- Automatic disposal
- Good testing story
- Flutter team endorsed

**Cons:**
- Requires BuildContext
- Runtime errors possible (ProviderNotFoundException)
- External dependency

## Riverpod Implementation

Using Riverpod with code generation for modern Flutter patterns.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

// Computed value
@riverpod
String parity(ParityRef ref) {
  final count = ref.watch(counterProvider);
  return count % 2 == 0 ? 'Even' : 'Odd';
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter - Riverpod',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends ConsumerWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final parityText = ref.watch(parityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Counter - Riverpod')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Text(
              parityText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () => ref.read(counterProvider.notifier).decrement(),
                  heroTag: 'decrement',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => ref.read(counterProvider.notifier).increment(),
                  heroTag: 'increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(counterProvider.notifier).reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Pros:**
- Compile-time safety
- No BuildContext dependency
- Clean computed values (parity provider)
- Excellent testing
- Auto-dispose
- Code generation reduces boilerplate

**Cons:**
- Code generation build step
- Newer, smaller ecosystem than Provider
- Learning curve for Provider users

## BLoC Implementation

Using the BLoC pattern with flutter_bloc package.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

void main() => runApp(const MyApp());

// Events
abstract class CounterEvent extends Equatable {
  const CounterEvent();
  @override
  List<Object> get props => [];
}

class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}
class Reset extends CounterEvent {}

// States
class CounterState extends Equatable {
  final int count;

  const CounterState(this.count);

  String get parity => count % 2 == 0 ? 'Even' : 'Odd';

  @override
  List<Object> get props => [count];
}

// BLoC
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(0)) {
    on<Increment>((event, emit) => emit(CounterState(state.count + 1)));
    on<Decrement>((event, emit) => emit(CounterState(state.count - 1)));
    on<Reset>((event, emit) => emit(const CounterState(0)));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterBloc(),
      child: MaterialApp(
        title: 'Counter - BLoC',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const CounterScreen(),
      ),
    );
  }
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter - BLoC')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BlocBuilder<CounterBloc, CounterState>(
              builder: (context, state) {
                return Column(
                  children: [
                    Text(
                      '${state.count}',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.parity,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () => context.read<CounterBloc>().add(Decrement()),
                  heroTag: 'decrement',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () => context.read<CounterBloc>().add(Increment()),
                  heroTag: 'increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CounterBloc>().add(Reset()),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Pros:**
- Very clear event flow
- Excellent for testing
- Event logging capabilities
- Strict architecture
- Predictable state changes

**Cons:**
- Most boilerplate
- Overkill for simple counter
- Steeper learning curve
- More files to manage

## Comparison

### Lines of Code

| Solution | LOC | Files |
|----------|-----|-------|
| setState | ~80 | 1 |
| ValueNotifier | ~100 | 1 |
| Provider | ~90 | 1 |
| Riverpod | ~75 | 2 (main + generated) |
| BLoC | ~120 | 1 |

### Testability

**setState:**
```dart
// Hard - need to test through widget
testWidgets('increments counter', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```

**Provider:**
```dart
// Easy - test ChangeNotifier directly
test('increments counter', () {
  final counter = Counter();
  counter.increment();
  expect(counter.count, 1);
});
```

**Riverpod:**
```dart
// Very easy - test with container
test('increments counter', () {
  final container = ProviderContainer();
  expect(container.read(counterProvider), 0);
  container.read(counterProvider.notifier).increment();
  expect(container.read(counterProvider), 1);
});
```

**BLoC:**
```dart
// Very easy - test with bloc_test
blocTest<CounterBloc, CounterState>(
  'increments counter',
  build: () => CounterBloc(),
  act: (bloc) => bloc.add(Increment()),
  expect: () => [const CounterState(1)],
);
```

### Performance

For a simple counter, performance differences are negligible. However, the patterns show different characteristics:

- **setState**: Rebuilds entire widget
- **ValueNotifier**: Only rebuilds ValueListenableBuilder
- **Provider**: Only rebuilds Consumer
- **Riverpod**: Only rebuilds watching widgets
- **BLoC**: Only rebuilds BlocBuilder

### When to Use Each

**setState:**
- Learning Flutter
- Prototyping
- True ephemeral state
- This counter in isolation

**ValueNotifier:**
- Need granular rebuilds
- Want reactivity without packages
- Simple state sharing

**Provider:**
- Small to medium apps
- Team new to state management
- Want official endorsement

**Riverpod:**
- New projects (recommended)
- Want modern patterns
- Need compile-time safety

**BLoC:**
- Enterprise requirements
- Need event logging
- Team values strict architecture

## Conclusion

For a simple counter app, **setState is perfectly fine**. The complexity of Provider, Riverpod, or BLoC is unnecessary for such simple state.

However, these examples demonstrate the patterns that scale to complex applications:
- **Provider/Riverpod**: Clean separation, easy testing
- **BLoC**: Event-driven, predictable flow

Choose based on your application's needs, not the example's simplicity. A counter doesn't need BLoC, but a banking app probably does.
