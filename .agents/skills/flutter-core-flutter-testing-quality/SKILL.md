---
name: flutter-core:flutter-testing-quality
description: >
  Comprehensive Flutter testing and quality assurance guidance covering unit testing, widget testing,
  integration testing, golden tests, debugging techniques, code coverage, test-driven development,
  mocking strategies, DevTools profiling, and quality metrics. Use when testing Flutter applications,
  writing unit tests, widget tests, integration tests, debugging issues, improving test coverage,
  creating golden files, mocking dependencies, profiling performance, or establishing testing strategies.
trigger_phrases:
  - test Flutter app
  - write tests
  - unit test
  - widget test
  - integration test
  - golden test
  - visual regression
  - mock dependencies
  - test coverage
  - debugging Flutter
  - DevTools
  - Flutter debugger
  - test strategy
  - TDD
  - test-driven development
  - flutter_test
  - integration_test
  - mockito
  - test package
  - testWidgets
  - pumpWidget
  - find.byType
  - expect
  - verify
  - setUp
  - tearDown
  - debugging techniques
  - performance profiling
  - memory leaks
  - testing best practices
---

# Flutter Testing & Quality

A comprehensive guide to testing and quality assurance in Flutter applications. This skill covers the complete testing pyramid from fast unit tests to comprehensive integration tests, along with debugging techniques, profiling strategies, and quality metrics that ensure your Flutter apps are reliable, maintainable, and performant.

## Philosophy: Testing as a First-Class Citizen

Flutter's testing framework is not an afterthought—it's a core part of the development experience. The framework provides excellent testing APIs that make it genuinely pleasant to write tests. Testing in Flutter follows the testing pyramid: many fast unit tests at the base, a moderate number of widget tests in the middle, and fewer but crucial integration tests at the top.

The key insight is that testing isn't just about catching bugs—it's about designing better APIs, improving code architecture, and giving you confidence to refactor and evolve your codebase. Well-tested Flutter apps are easier to maintain, onboard new developers to, and extend with new features.

## Understanding the Testing Pyramid

Flutter supports three types of tests, each serving a distinct purpose in your quality assurance strategy.

### Unit Tests

Unit tests validate individual functions, methods, and classes in isolation. They are the foundation of your testing strategy because they:

- Run extremely fast (thousands can execute in seconds)
- Provide precise failure messages pointing to exact issues
- Enable test-driven development workflows
- Validate business logic independently of Flutter framework
- Require no special Flutter environment

Unit tests should comprise 60-70% of your test suite. They test pure Dart code: data models, utility functions, business logic, validators, parsers, and state management logic.

### Widget Tests

Widget tests (also called component tests) validate that your UI widgets behave correctly. They:

- Test widgets in isolation from the full app
- Verify widget rendering, layout, and user interactions
- Run faster than integration tests but slower than unit tests
- Can pump widgets, trigger interactions, and verify results
- Use Flutter's testing framework to simulate the widget tree

Widget tests should comprise 20-30% of your test suite. They test individual screens, complex widgets, form behavior, animations, and user interactions without requiring a real device.

### Integration Tests

Integration tests validate complete app flows on real devices or simulators. They:

- Test the entire app as users would experience it
- Verify navigation flows, API integration, and persistence
- Run slowest but provide highest confidence
- Catch issues that unit and widget tests miss
- Require actual device/emulator to execute

Integration tests should comprise 5-10% of your test suite. They test critical user journeys, onboarding flows, checkout processes, and cross-cutting concerns.

## Decision Tree: Choosing the Right Test Type

Use this decision tree to select the appropriate testing approach:

### Question 1: Does it involve UI rendering?

**If NO (pure Dart logic):**
→ Use **Unit Tests**
→ Test with `test()` package
→ No Flutter dependencies needed
→ **Reference**: [Unit Testing](references/unit-testing.md)

**If YES (involves widgets):**
→ Continue to Question 2

### Question 2: Does it require navigation or multiple screens?

**If NO (single widget/screen):**
→ Use **Widget Tests**
→ Test with `testWidgets()`
→ Mock external dependencies
→ **References**: [Widget Testing](references/widget-testing.md), [Mocking Strategies](examples/mocking-strategies.md)

**If YES (multiple screens/full flows):**
→ Use **Integration Tests**
→ Test with `integration_test` package
→ Run on real device/emulator
→ **Reference**: [Integration Testing](references/integration-testing.md)

### Question 3: Do you need visual regression testing?

**If validating pixel-perfect UI:**
→ Use **Golden Tests**
→ Generate golden files for comparison
→ Catch unintended visual changes
→ **Reference**: [Golden Tests](references/golden-tests.md)

## Core Testing Principles

Regardless of which test type you choose, follow these principles:

### 1. Arrange-Act-Assert (AAA) Pattern

Structure every test in three clear phases:

```dart
test('counter increments correctly', () {
  // Arrange: Set up test conditions
  final counter = Counter(initialValue: 0);

  // Act: Execute the operation
  counter.increment();

  // Assert: Verify the result
  expect(counter.value, 1);
});
```

This pattern makes tests readable, maintainable, and easy to debug when they fail.

### 2. Test One Thing at a Time

Each test should verify a single behavior or condition. If a test fails, you should immediately know what broke:

```dart
// Good: Tests one specific behavior
test('login validates empty email', () {
  final result = validator.validateEmail('');
  expect(result, 'Email cannot be empty');
});

// Bad: Tests multiple unrelated things
test('login validation', () {
  expect(validator.validateEmail(''), 'Email cannot be empty');
  expect(validator.validatePassword(''), 'Password cannot be empty');
  expect(validator.validateEmail('invalid'), 'Invalid email format');
});
```

### 3. Make Tests Independent

Tests should not depend on execution order or shared state. Each test should set up its own data and clean up after itself:

```dart
// Use setUp and tearDown for test isolation
group('UserRepository', () {
  late UserRepository repository;
  late Database mockDatabase;

  setUp(() {
    mockDatabase = MockDatabase();
    repository = UserRepository(mockDatabase);
  });

  tearDown(() {
    mockDatabase.close();
  });

  test('saves user correctly', () {
    // Test implementation
  });
});
```

### 4. Use Descriptive Test Names

Test names should describe what is being tested and the expected outcome:

```dart
// Good: Clear and descriptive
test('formatCurrency converts dollars to formatted string with two decimals', () {});
test('submitForm shows error message when email is invalid', () {});

// Bad: Vague and unclear
test('test1', () {});
test('currency works', () {});
```

### 5. Test Edge Cases and Error Conditions

Don't just test the happy path. Test boundary conditions, null values, empty lists, network failures, and error states:

```dart
group('parseUserAge', () {
  test('returns age for valid input', () {
    expect(parseUserAge('25'), 25);
  });

  test('returns null for negative numbers', () {
    expect(parseUserAge('-5'), null);
  });

  test('returns null for non-numeric input', () {
    expect(parseUserAge('abc'), null);
  });

  test('returns null for null input', () {
    expect(parseUserAge(null), null);
  });
});
```

## Testing Strategy for Different App Components

### Testing State Management

State management logic should be thoroughly unit tested independently of widgets:

- **setState**: Test stateful widgets with widget tests
- **ChangeNotifier/ValueNotifier**: Unit test notifier logic, widget test UI integration
- **Provider/Riverpod**: Mock providers in widget tests
- **BLoC**: Unit test blocs/cubits, widget test UI with BlocProvider
→ **Cross-reference**: flutter-state-management skill

### Testing Navigation and Routing

Navigation requires widget or integration tests:

- Widget tests: Mock Navigator and verify navigation calls
- Integration tests: Test complete navigation flows
- Verify route transitions, deep linking, and route guards
→ **Cross-reference**: flutter-navigation-routing skill

### Testing Network Calls

Network integration requires mocking:

- Unit test: Mock HTTP clients and test response handling
- Widget test: Mock repositories providing data
- Integration test: Use real API or mock server
→ **References**: [Unit Testing](references/unit-testing.md), [Mocking Strategies](examples/mocking-strategies.md)

### Testing Persistence

Database and storage operations require isolation:

- Unit test: Mock database interfaces
- Widget test: Provide test data from mocked repositories
- Integration test: Use in-memory or test databases
→ **Cross-reference**: flutter-persistence skill

### Testing Platform Channels

Native platform integration requires special handling:

- Mock MethodChannel calls in tests
- Use TestDefaultBinaryMessengerBinding
- Verify platform messages sent and received
→ **Reference**: [Mocking Strategies](examples/mocking-strategies.md)

## Debugging Strategies

Testing catches many issues, but effective debugging skills are essential when problems arise.

### Using Flutter DevTools

DevTools is Flutter's comprehensive debugging and profiling suite:

- **Widget Inspector**: Visualize widget tree, identify layout issues
- **Timeline View**: Profile performance, identify jank and frame drops
- **Memory View**: Track memory usage, find leaks
- **Network View**: Monitor HTTP requests and responses
- **Logging View**: View print statements and log messages
→ **Reference**: [Debugging](references/debugging.md)

### Debugging Techniques

Common debugging approaches for Flutter development:

- **Print Debugging**: Use `debugPrint()` for console output
- **Breakpoints**: Set breakpoints in VS Code or Android Studio
- **Flutter Inspector**: Inspect widget properties in real-time
- **Debug Flags**: Use `debugPrint`, `kDebugMode`, `assert()`
- **Layout Debugging**: Enable `debugPaintSizeEnabled` to visualize layout
→ **Reference**: [Debugging](references/debugging.md)

### Performance Profiling

Profile your app to identify bottlenecks:

- **Performance Overlay**: Shows frame rendering times
- **Timeline View**: Identifies expensive operations
- **Memory Profiler**: Finds memory leaks and excessive allocations
- **Build Methods**: Profile widget rebuilds to optimize
→ **Cross-reference**: flutter-performance skill

## Code Coverage and Quality Metrics

Measuring test coverage helps identify untested code paths.

### Measuring Coverage

Generate coverage reports to see which code is tested:

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

### Coverage Goals

Set realistic coverage targets:

- **70-80% overall coverage**: Good baseline for most apps
- **90%+ for critical code**: Payment processing, authentication, data validation
- **Lower for UI code**: 50-60% for complex visual widgets is acceptable
- **100% for utilities**: Pure functions should have complete coverage

→ **Reference**: [Test Coverage](references/test-coverage.md)

### Quality Beyond Coverage

Coverage is one metric, but quality requires more:

- **Test Maintainability**: Tests should be easy to understand and update
- **Test Speed**: Fast test suite enables rapid feedback
- **Test Reliability**: Tests should not be flaky or randomly fail
- **Test Documentation**: Complex tests should explain their purpose

## Test-Driven Development (TDD)

TDD is a development methodology where tests are written before implementation:

1. **Write a failing test** that describes desired behavior
2. **Write minimal code** to make the test pass
3. **Refactor** the code while keeping tests green
4. **Repeat** for the next feature

TDD benefits include better API design, higher test coverage, and confidence in refactoring. It's particularly effective for business logic, validators, and utility functions.

→ **Reference**: [Unit Testing](references/unit-testing.md)

## Common Testing Patterns

### Pattern 1: Testing Data Models

Validate that models serialize/deserialize correctly:

```dart
test('User.fromJson creates valid user', () {
  final json = {'id': '1', 'name': 'John', 'email': 'john@example.com'};
  final user = User.fromJson(json);

  expect(user.id, '1');
  expect(user.name, 'John');
  expect(user.email, 'john@example.com');
});
```

→ **Reference**: [Unit Testing](references/unit-testing.md)

### Pattern 2: Testing Form Validation

Verify validators catch invalid input:

```dart
testWidgets('login form shows error for invalid email', (tester) async {
  await tester.pumpWidget(MyApp());

  await tester.enterText(find.byType(TextField).first, 'invalid-email');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();

  expect(find.text('Please enter a valid email'), findsOneWidget);
});
```

→ **Reference**: [Widget Testing](references/widget-testing.md)

### Pattern 3: Testing Async Operations

Handle futures and streams in tests:

```dart
test('fetchUser returns user from API', () async {
  final user = await repository.fetchUser('123');
  expect(user.id, '123');
});

test('userStream emits updated users', () async {
  final stream = repository.userStream();

  expectLater(
    stream,
    emitsInOrder([user1, user2, emitsDone]),
  );

  repository.updateUser(user1);
  repository.updateUser(user2);
  await repository.close();
});
```

→ **References**: [Unit Testing](references/unit-testing.md), [Test Patterns](examples/test-patterns.md)

### Pattern 4: Testing Navigation

Verify navigation calls are triggered:

```dart
testWidgets('tapping button navigates to details screen', (tester) async {
  final mockObserver = MockNavigatorObserver();

  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(),
      navigatorObservers: [mockObserver],
    ),
  );

  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle();

  verify(mockObserver.didPush(any, any));
  expect(find.byType(DetailsScreen), findsOneWidget);
});
```

→ **References**: [Widget Testing](references/widget-testing.md), [Mocking Strategies](examples/mocking-strategies.md)

### Pattern 5: Golden Tests for Visual Regression

Catch unintended visual changes:

```dart
testWidgets('profile card matches golden file', (tester) async {
  await tester.pumpWidget(ProfileCard(user: testUser));

  await expectLater(
    find.byType(ProfileCard),
    matchesGoldenFile('goldens/profile_card.png'),
  );
});
```

→ **Reference**: [Golden Tests](references/golden-tests.md)

## Testing Best Practices

### Organization

- Keep test files alongside source files in `test/` directory
- Mirror source directory structure: `lib/models/user.dart` → `test/models/user_test.dart`
- Use `group()` to organize related tests
- Create test helpers in `test/helpers/` directory

### Performance

- Use `setUp()` and `tearDown()` efficiently
- Avoid unnecessary async operations
- Mock expensive operations
- Run tests in parallel when possible

### Maintainability

- Refactor duplicated test setup into helper functions
- Use custom matchers for complex assertions
- Keep tests simple and readable
- Update tests when requirements change

### Continuous Integration

- Run tests on every commit
- Block merges if tests fail
- Track coverage trends over time
- Run integration tests on multiple devices

## Next Steps: Dive Deeper

Now that you understand Flutter testing fundamentals, explore specific testing techniques:

### For Beginners

Start with **Unit Testing** fundamentals:
→ [Unit Testing](references/unit-testing.md)
→ [Test Patterns](examples/test-patterns.md)

### For Widget Testing

Learn to test UI components:
→ [Widget Testing](references/widget-testing.md)
→ [Mocking Strategies](examples/mocking-strategies.md)

### For Integration Testing

Test complete app flows:
→ [Integration Testing](references/integration-testing.md)

### For Visual Regression

Prevent unintended UI changes:
→ [Golden Tests](references/golden-tests.md)

### For Debugging

Master debugging and profiling:
→ [Debugging](references/debugging.md)

### For Coverage Analysis

Improve test coverage:
→ [Test Coverage](references/test-coverage.md)

## Related Skills

- **flutter-state-management**: Testing state management solutions (Provider, BLoC, Riverpod)
- **flutter-data-networking**: Testing API integration and network calls
- **flutter-architecture**: Testing architectural patterns (MVVM, Clean Architecture)
- **flutter-performance**: Profiling and optimizing Flutter apps

## Remember

Testing is not about achieving 100% coverage—it's about confidence. Write tests that give you confidence to refactor, add features, and deploy to production. Focus on testing behavior, not implementation details. Start with unit tests for business logic, add widget tests for UI components, and use integration tests for critical flows. Make testing a natural part of your development workflow, not an afterthought.
