# Widget Testing in Flutter

Widget tests (also called component tests) validate that your UI components behave correctly. They test individual widgets or widget combinations in isolation from the full app, verifying rendering, layout, user interactions, and state changes. Widget tests strike a balance between unit tests and integration tests—they run faster than full integration tests while still validating UI behavior.

## Table of Contents

- [Setting Up Widget Tests](#setting-up-widget-tests)
- [Your First Widget Test](#your-first-widget-test)
- [Finding Widgets](#finding-widgets)
- [Interacting with Widgets](#interacting-with-widgets)
- [Testing State Changes](#testing-state-changes)
- [Pumping and Settling](#pumping-and-settling)
- [Testing Text Input](#testing-text-input)
- [Testing Navigation](#testing-navigation)
- [Testing Async Widgets](#testing-async-widgets)
- [Mocking Dependencies](#mocking-dependencies)
- [Testing Themes and Localization](#testing-themes-and-localization)
- [Custom Finders](#custom-finders)
- [Best Practices](#best-practices)

## Setting Up Widget Tests

Widget tests use the `flutter_test` package, which is included by default in Flutter projects.

### Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### Test File Structure

Place widget tests in `test/` directory, mirroring your source structure:

```
my_app/
├── lib/
│   ├── screens/
│   │   └── home_screen.dart
│   └── widgets/
│       └── user_card.dart
└── test/
    ├── screens/
    │   └── home_screen_test.dart
    └── widgets/
        └── user_card_test.dart
```

### Running Widget Tests

```bash
# Run all widget tests
flutter test

# Run specific test file
flutter test test/widgets/user_card_test.dart

# Run tests with name filter
flutter test --name "UserCard"

# Run with coverage
flutter test --coverage
```

## Your First Widget Test

Let's test a simple counter widget:

### Source: `lib/widgets/counter_widget.dart`

```dart
import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  void _decrement() {
    setState(() {
      _counter--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Count: $_counter',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _decrement,
              child: const Text('Decrement'),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _increment,
              child: const Text('Increment'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Test: `test/widgets/counter_widget_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/counter_widget.dart';

void main() {
  group('CounterWidget', () {
    testWidgets('displays initial count of 0', (tester) async {
      // Arrange: Pump the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterWidget(),
          ),
        ),
      );

      // Assert: Verify initial state
      expect(find.text('Count: 0'), findsOneWidget);
    });

    testWidgets('increments counter when increment button is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterWidget(),
          ),
        ),
      );

      // Act: Tap the increment button
      await tester.tap(find.text('Increment'));
      await tester.pump(); // Rebuild the widget

      // Assert
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('decrements counter when decrement button is tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterWidget(),
          ),
        ),
      );

      // Act: Tap decrement button
      await tester.tap(find.text('Decrement'));
      await tester.pump();

      // Assert
      expect(find.text('Count: -1'), findsOneWidget);
    });

    testWidgets('handles multiple increments', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterWidget(),
          ),
        ),
      );

      // Act: Tap increment multiple times
      await tester.tap(find.text('Increment'));
      await tester.pump();
      await tester.tap(find.text('Increment'));
      await tester.pump();
      await tester.tap(find.text('Increment'));
      await tester.pump();

      // Assert
      expect(find.text('Count: 3'), findsOneWidget);
    });
  });
}
```

## Finding Widgets

Flutter provides powerful finders to locate widgets in the widget tree.

### Common Finders

```dart
// Find by text
find.text('Hello World')

// Find by key
find.byKey(const Key('my-widget'))

// Find by widget type
find.byType(ElevatedButton)

// Find by icon
find.byIcon(Icons.add)

// Find by tooltip
find.byTooltip('Add item')

// Find widgets containing text
find.textContaining('partial')

// Find semantics with label
find.bySemanticsLabel('Submit button')
```

### Descendant and Ancestor Finders

```dart
// Find descendant (child)
find.descendant(
  of: find.byType(Card),
  matching: find.text('Title'),
)

// Find ancestor (parent)
find.ancestor(
  of: find.text('Child Text'),
  matching: find.byType(Container),
)

// Find widget that is a descendant of one widget and ancestor of another
find.descendant(
  of: find.byType(ListView),
  matching: find.ancestor(
    of: find.text('Item Title'),
    matching: find.byType(ListTile),
  ),
)
```

### Finder Expectations

```dart
// Expect exactly one widget
expect(find.text('Hello'), findsOneWidget);

// Expect zero widgets
expect(find.text('Goodbye'), findsNothing);

// Expect at least one widget
expect(find.byType(Text), findsWidgets);

// Expect specific number of widgets
expect(find.byType(ListTile), findsNWidgets(5));

// Expect at least N widgets
expect(find.text('Item'), findsAtLeastNWidgets(3));
```

### Advanced Finding

```dart
// Find by predicate
find.byWidgetPredicate(
  (widget) => widget is Text && widget.data!.startsWith('Prefix'),
)

// Find by element predicate
find.byElementPredicate(
  (element) => element.widget is Container,
)

// Combine finders with .and
final buttonWithText = find.byType(ElevatedButton).and(
  find.text('Submit'),
);
```

## Interacting with Widgets

Simulate user interactions to test widget behavior.

### Tapping

```dart
testWidgets('button tap triggers action', (tester) async {
  await tester.pumpWidget(MyWidget());

  // Tap once
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  // Tap at specific coordinates
  await tester.tapAt(const Offset(100, 100));
  await tester.pump();

  // Long press
  await tester.longPress(find.text('Hold me'));
  await tester.pump();
});
```

### Scrolling

```dart
testWidgets('scrolls to reveal item', (tester) async {
  await tester.pumpWidget(MyScrollableList());

  // Scroll until item is visible
  await tester.scrollUntilVisible(
    find.text('Item 50'),
    500.0, // Delta to scroll by
    scrollable: find.byType(Scrollable),
  );

  expect(find.text('Item 50'), findsOneWidget);
});

testWidgets('drags widget', (tester) async {
  await tester.pumpWidget(MyDraggableWidget());

  // Drag by offset
  await tester.drag(
    find.byType(Draggable),
    const Offset(300, 0),
  );
  await tester.pumpAndSettle();

  // Fling (fast drag)
  await tester.fling(
    find.byType(ListView),
    const Offset(0, -300),
    3000, // Velocity
  );
  await tester.pumpAndSettle();
});
```

### Entering Text

```dart
testWidgets('enters text in text field', (tester) async {
  await tester.pumpWidget(MyForm());

  // Enter text
  await tester.enterText(
    find.byType(TextField),
    'Hello World',
  );
  await tester.pump();

  expect(find.text('Hello World'), findsOneWidget);
});

testWidgets('clears text field', (tester) async {
  await tester.pumpWidget(MyForm());

  // Enter then clear text
  await tester.enterText(find.byType(TextField), 'Test');
  await tester.pump();

  await tester.enterText(find.byType(TextField), '');
  await tester.pump();

  expect(find.text('Test'), findsNothing);
});
```

### Gestures

```dart
testWidgets('performs gestures', (tester) async {
  await tester.pumpWidget(MyWidget());

  // Get center of widget
  final center = tester.getCenter(find.byType(Container));

  // Press and hold
  final gesture = await tester.startGesture(center);
  await tester.pump(const Duration(seconds: 1));
  await gesture.up();
  await tester.pump();

  // Double tap
  await tester.tap(find.byType(InkWell));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.byType(InkWell));
  await tester.pump();
});
```

## Testing State Changes

Verify that widgets respond correctly to state changes.

### Testing StatefulWidget State

```dart
class ToggleWidget extends StatefulWidget {
  const ToggleWidget({super.key});

  @override
  State<ToggleWidget> createState() => _ToggleWidgetState();
}

class _ToggleWidgetState extends State<ToggleWidget> {
  bool _isOn = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_isOn ? 'ON' : 'OFF'),
        Switch(
          value: _isOn,
          onChanged: (value) {
            setState(() {
              _isOn = value;
            });
          },
        ),
      ],
    );
  }
}

// Test
testWidgets('toggle switches state', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: ToggleWidget()),
  );

  // Verify initial state
  expect(find.text('OFF'), findsOneWidget);
  expect(find.text('ON'), findsNothing);

  // Tap switch
  await tester.tap(find.byType(Switch));
  await tester.pump();

  // Verify state changed
  expect(find.text('OFF'), findsNothing);
  expect(find.text('ON'), findsOneWidget);
});
```

### Testing with Inherited Widgets

```dart
class CounterProvider extends InheritedWidget {
  final int counter;
  final VoidCallback onIncrement;

  const CounterProvider({
    super.key,
    required this.counter,
    required this.onIncrement,
    required super.child,
  });

  static CounterProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CounterProvider>()!;
  }

  @override
  bool updateShouldNotify(CounterProvider oldWidget) {
    return counter != oldWidget.counter;
  }
}

class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = CounterProvider.of(context);
    return Column(
      children: [
        Text('Count: ${provider.counter}'),
        ElevatedButton(
          onPressed: provider.onIncrement,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

// Test
testWidgets('displays and updates counter from provider', (tester) async {
  int counter = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) {
          return CounterProvider(
            counter: counter,
            onIncrement: () => setState(() => counter++),
            child: const CounterDisplay(),
          );
        },
      ),
    ),
  );

  expect(find.text('Count: 0'), findsOneWidget);

  await tester.tap(find.text('Increment'));
  await tester.pump();

  expect(find.text('Count: 1'), findsOneWidget);
});
```

## Pumping and Settling

Understanding when to use `pump()`, `pumpAndSettle()`, and `pumpFrames()` is crucial.

### pump()

Triggers a rebuild of the widget tree. Use for immediate state changes:

```dart
testWidgets('button changes color on tap', (tester) async {
  await tester.pumpWidget(ColorChangingButton());

  await tester.tap(find.byType(ElevatedButton));
  await tester.pump(); // Single frame rebuild

  // Verify new state
});
```

### pumpAndSettle()

Repeatedly pumps until there are no more frames scheduled. Use for animations:

```dart
testWidgets('animates to new position', (tester) async {
  await tester.pumpWidget(AnimatedWidget());

  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle(); // Wait for animation to complete

  // Verify final state after animation
});
```

### pump() with Duration

Advance time by a specific duration:

```dart
testWidgets('shows message after delay', (tester) async {
  await tester.pumpWidget(DelayedMessage());

  expect(find.text('Message'), findsNothing);

  await tester.pump(const Duration(seconds: 2));

  expect(find.text('Message'), findsOneWidget);
});
```

### pumpFrames()

Pump a specific number of frames:

```dart
testWidgets('animation progresses correctly', (tester) async {
  await tester.pumpWidget(MyAnimation());

  // Pump 10 frames, each 16ms apart (60fps)
  await tester.pumpFrames(
    find.byType(MyAnimation),
    const Duration(milliseconds: 16),
    frames: 10,
  );
});
```

## Testing Text Input

Test forms and text input comprehensively.

### Basic Text Input

```dart
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  void _submit() {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email cannot be empty';
      });
      return;
    }
    // Submit logic
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: const Key('email-field'),
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          key: const Key('password-field'),
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        if (_errorMessage != null)
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

// Test
testWidgets('shows error for empty email', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: LoginForm())),
  );

  // Don't enter email
  await tester.enterText(find.byKey(const Key('password-field')), 'password123');
  await tester.tap(find.text('Submit'));
  await tester.pump();

  expect(find.text('Email cannot be empty'), findsOneWidget);
});

testWidgets('submits form with valid input', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: LoginForm())),
  );

  await tester.enterText(find.byKey(const Key('email-field')), 'user@example.com');
  await tester.enterText(find.byKey(const Key('password-field')), 'password123');
  await tester.tap(find.text('Submit'));
  await tester.pump();

  expect(find.text('Email cannot be empty'), findsNothing);
});
```

### Testing Validation

```dart
testWidgets('validates email format', (tester) async {
  await tester.pumpWidget(MyFormWidget());

  await tester.enterText(find.byType(TextField), 'invalid-email');
  await tester.tap(find.text('Submit'));
  await tester.pump();

  expect(find.text('Please enter a valid email'), findsOneWidget);
});

testWidgets('clears validation error on correction', (tester) async {
  await tester.pumpWidget(MyFormWidget());

  // Enter invalid email
  await tester.enterText(find.byType(TextField), 'invalid');
  await tester.tap(find.text('Submit'));
  await tester.pump();

  expect(find.text('Please enter a valid email'), findsOneWidget);

  // Correct the email
  await tester.enterText(find.byType(TextField), 'valid@example.com');
  await tester.pump();

  expect(find.text('Please enter a valid email'), findsNothing);
});
```

## Testing Navigation

Test navigation flows within widget tests.

### Testing Route Pushes

```dart
testWidgets('navigates to detail screen', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: const HomeScreen(),
      routes: {
        '/details': (context) => const DetailsScreen(),
      },
    ),
  );

  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle();

  expect(find.byType(DetailsScreen), findsOneWidget);
});
```

### Testing with Navigator Observer

```dart
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

testWidgets('pushes route when button tapped', (tester) async {
  final mockObserver = MockNavigatorObserver();

  await tester.pumpWidget(
    MaterialApp(
      home: const HomeScreen(),
      navigatorObservers: [mockObserver],
      routes: {
        '/details': (context) => const DetailsScreen(),
      },
    ),
  );

  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle();

  verify(mockObserver.didPush(any, any)).called(2); // Initial route + pushed route
});
```

### Testing Back Navigation

```dart
testWidgets('returns to previous screen', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: const HomeScreen(),
      routes: {
        '/details': (context) => const DetailsScreen(),
      },
    ),
  );

  // Navigate forward
  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle();
  expect(find.byType(DetailsScreen), findsOneWidget);

  // Navigate back
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

## Testing Async Widgets

Handle asynchronous operations in widget tests.

### Testing FutureBuilder

```dart
class UserProfile extends StatelessWidget {
  final Future<User> userFuture;

  const UserProfile({super.key, required this.userFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final user = snapshot.data!;
        return Text('Hello, ${user.name}');
      },
    );
  }
}

// Test
testWidgets('shows loading indicator while waiting', (tester) async {
  final userFuture = Future.delayed(
    const Duration(seconds: 2),
    () => User(name: 'John'),
  );

  await tester.pumpWidget(
    MaterialApp(home: UserProfile(userFuture: userFuture)),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('shows user name when loaded', (tester) async {
  final userFuture = Future.value(User(name: 'John'));

  await tester.pumpWidget(
    MaterialApp(home: UserProfile(userFuture: userFuture)),
  );

  await tester.pump(); // Let future complete

  expect(find.text('Hello, John'), findsOneWidget);
});

testWidgets('shows error message on failure', (tester) async {
  final userFuture = Future<User>.error('Network error');

  await tester.pumpWidget(
    MaterialApp(home: UserProfile(userFuture: userFuture)),
  );

  await tester.pump();

  expect(find.textContaining('Error'), findsOneWidget);
});
```

### Testing StreamBuilder

```dart
testWidgets('updates when stream emits new values', (tester) async {
  final controller = StreamController<int>();

  await tester.pumpWidget(
    MaterialApp(
      home: StreamBuilder<int>(
        stream: controller.stream,
        initialData: 0,
        builder: (context, snapshot) {
          return Text('Count: ${snapshot.data}');
        },
      ),
    ),
  );

  expect(find.text('Count: 0'), findsOneWidget);

  controller.add(1);
  await tester.pump();
  expect(find.text('Count: 1'), findsOneWidget);

  controller.add(2);
  await tester.pump();
  expect(find.text('Count: 2'), findsOneWidget);

  await controller.close();
});
```

## Mocking Dependencies

Widget tests should isolate widgets by mocking external dependencies.

### Mocking Services

```dart
// Service interface
abstract class UserService {
  Future<User> fetchUser(String id);
}

// Mock implementation
class MockUserService extends Mock implements UserService {}

// Widget using service
class UserDetailScreen extends StatelessWidget {
  final UserService userService;
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userService,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: userService.fetchUser(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(snapshot.data!.name);
        }
        return const CircularProgressIndicator();
      },
    );
  }
}

// Test
testWidgets('displays user name from service', (tester) async {
  final mockService = MockUserService();
  when(mockService.fetchUser('123'))
      .thenAnswer((_) async => User(id: '123', name: 'John Doe'));

  await tester.pumpWidget(
    MaterialApp(
      home: UserDetailScreen(
        userService: mockService,
        userId: '123',
      ),
    ),
  );

  await tester.pump(); // Let future complete

  expect(find.text('John Doe'), findsOneWidget);
  verify(mockService.fetchUser('123')).called(1);
});
```

### Mocking with Provider

```dart
testWidgets('uses mocked provider', (tester) async {
  final mockService = MockUserService();
  when(mockService.getUsers()).thenAnswer(
    (_) async => [User(name: 'Test User')],
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Provider<UserService>.value(
        value: mockService,
        child: const UserListScreen(),
      ),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('Test User'), findsOneWidget);
});
```

## Testing Themes and Localization

### Testing with Custom Theme

```dart
testWidgets('uses theme colors', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const MyThemedWidget(),
    ),
  );

  final container = tester.widget<Container>(find.byType(Container));
  expect(container.color, Colors.red);
});
```

### Testing Localization

```dart
testWidgets('displays localized text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: const MyLocalizedWidget(),
    ),
  );

  expect(find.text('Hola'), findsOneWidget);
});
```

## Custom Finders

Create reusable custom finders for complex queries.

```dart
// Custom finder for widgets with specific text style
Finder findTextWithStyle(String text, TextStyle style) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data == text &&
        widget.style == style,
  );
}

// Usage
testWidgets('displays title with correct style', (tester) async {
  await tester.pumpWidget(MyWidget());

  expect(
    findTextWithStyle('Title', const TextStyle(fontSize: 24)),
    findsOneWidget,
  );
});

// Custom finder for enabled buttons
Finder findEnabledButton(String text) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is ElevatedButton &&
        (widget.onPressed != null) &&
        (widget.child as Text).data == text,
  );
}
```

## Best Practices

### 1. Wrap Widgets in MaterialApp

Always provide MaterialApp or required inherited widgets:

```dart
// Bad: Missing MaterialApp
testWidgets('test', (tester) async {
  await tester.pumpWidget(MyWidget());
  // May fail if MyWidget depends on Theme, MediaQuery, etc.
});

// Good: Provides necessary context
testWidgets('test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MyWidget(),
      ),
    ),
  );
});
```

### 2. Use Keys for Precise Widget Finding

```dart
// Widget
TextField(
  key: const Key('email-field'),
  decoration: const InputDecoration(labelText: 'Email'),
)

// Test
await tester.enterText(find.byKey(const Key('email-field')), 'test@example.com');
```

### 3. Test Widget Behavior, Not Implementation

```dart
// Bad: Testing internal state
testWidgets('_counter is incremented', (tester) async {
  // Can't access private _counter variable
});

// Good: Testing visible behavior
testWidgets('counter text updates when button tapped', (tester) async {
  await tester.pumpWidget(MyWidget());

  await tester.tap(find.text('Increment'));
  await tester.pump();

  expect(find.text('Count: 1'), findsOneWidget);
});
```

### 4. Prefer Specific Finders

```dart
// Bad: Too broad
expect(find.text('Submit'), findsOneWidget);

// Good: More specific
expect(
  find.descendant(
    of: find.byType(ElevatedButton),
    matching: find.text('Submit'),
  ),
  findsOneWidget,
);
```

### 5. Clean Up Resources

```dart
testWidgets('disposes controllers', (tester) async {
  final controller = TextEditingController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: TextField(controller: controller),
    ),
  );

  // Test logic
});
```

### 6. Test Accessibility

```dart
testWidgets('has semantic labels', (tester) async {
  await tester.pumpWidget(MyWidget());

  expect(
    find.bySemanticsLabel('Submit button'),
    findsOneWidget,
  );
});

testWidgets('passes accessibility guidelines', (tester) async {
  await tester.pumpWidget(MyWidget());

  await expectLater(tester, meetsGuideline(textContrastGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
});
```

### 7. Use pumpAndSettle for Animations

```dart
testWidgets('navigation animation completes', (tester) async {
  await tester.pumpWidget(MyApp());

  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle(); // Wait for transition animation

  expect(find.byType(NextScreen), findsOneWidget);
});
```

### 8. Test Error States

```dart
testWidgets('shows error message on failure', (tester) async {
  final mockService = MockService();
  when(mockService.fetch()).thenThrow(Exception('Network error'));

  await tester.pumpWidget(MyWidget(service: mockService));

  await tester.pumpAndSettle();

  expect(find.text('Network error'), findsOneWidget);
});
```

## Summary

Widget testing validates UI components in isolation:

- **Use `testWidgets()`** for all widget tests
- **Find widgets** with `find.text()`, `find.byType()`, `find.byKey()`
- **Interact** with `tap()`, `enterText()`, `drag()`, `scroll()`
- **Pump widgets** with `pump()`, `pumpAndSettle()`, or `pump(duration)`
- **Test state changes** by verifying UI updates
- **Mock dependencies** to isolate widget behavior
- **Test navigation** with MaterialApp routes
- **Handle async** with FutureBuilder and StreamBuilder
- **Test accessibility** with semantic finders
- **Keep tests focused** on user-visible behavior

Widget tests provide confidence that your UI works correctly without the overhead of full integration tests.
