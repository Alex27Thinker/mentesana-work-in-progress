# Unit Testing in Flutter

Unit tests are the foundation of your testing strategy. They validate individual functions, methods, and classes in complete isolation from the Flutter framework, UI, and external dependencies. Unit tests run incredibly fast—thousands can execute in seconds—making them ideal for test-driven development and continuous integration.

## Table of Contents

- [Setting Up Unit Tests](#setting-up-unit-tests)
- [Writing Your First Unit Test](#writing-your-first-unit-test)
- [Test Organization with Groups](#test-organization-with-groups)
- [Testing Async Code](#testing-async-code)
- [Testing Streams](#testing-streams)
- [Mocking Dependencies](#mocking-dependencies)
- [Test Setup and Teardown](#test-setup-and-teardown)
- [Custom Matchers](#custom-matchers)
- [Test-Driven Development](#test-driven-development)
- [Best Practices](#best-practices)

## Setting Up Unit Tests

Unit tests use the `test` package, which is automatically included in Flutter projects. Your tests live in the `test/` directory, mirroring your source structure.

### Project Structure

```
my_app/
├── lib/
│   ├── models/
│   │   └── user.dart
│   ├── services/
│   │   └── user_service.dart
│   └── utils/
│       └── validators.dart
└── test/
    ├── models/
    │   └── user_test.dart
    ├── services/
    │   └── user_service_test.dart
    └── utils/
        └── validators_test.dart
```

### Dependencies

Add testing dependencies to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/user_test.dart

# Run tests matching a name
flutter test --name "User model"

# Run tests with coverage
flutter test --coverage

# Watch mode (re-run on file changes)
flutter test --watch
```

## Writing Your First Unit Test

Let's test a simple validator function:

### Source Code: `lib/utils/validators.dart`

```dart
class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email cannot be empty';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email';
    }

    return null; // Valid email
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }

    return null; // Valid password
  }
}
```

### Test Code: `test/utils/validators_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('returns error for null email', () {
        final result = Validators.validateEmail(null);
        expect(result, 'Email cannot be empty');
      });

      test('returns error for empty email', () {
        final result = Validators.validateEmail('');
        expect(result, 'Email cannot be empty');
      });

      test('returns error for invalid email format', () {
        final result = Validators.validateEmail('invalid-email');
        expect(result, 'Please enter a valid email');
      });

      test('returns null for valid email', () {
        final result = Validators.validateEmail('user@example.com');
        expect(result, null);
      });

      test('accepts email with multiple subdomains', () {
        final result = Validators.validateEmail('user@mail.example.com');
        expect(result, null);
      });
    });

    group('validatePassword', () {
      test('returns error for null password', () {
        final result = Validators.validatePassword(null);
        expect(result, 'Password cannot be empty');
      });

      test('returns error for empty password', () {
        final result = Validators.validatePassword('');
        expect(result, 'Password cannot be empty');
      });

      test('returns error for short password', () {
        final result = Validators.validatePassword('Pass1');
        expect(result, 'Password must be at least 8 characters');
      });

      test('returns error when missing uppercase letter', () {
        final result = Validators.validatePassword('password123');
        expect(result, 'Password must contain an uppercase letter');
      });

      test('returns error when missing number', () {
        final result = Validators.validatePassword('Password');
        expect(result, 'Password must contain a number');
      });

      test('returns null for valid password', () {
        final result = Validators.validatePassword('Password123');
        expect(result, null);
      });
    });
  });
}
```

## Test Organization with Groups

Use `group()` to organize related tests hierarchically. Groups provide structure and make test output more readable.

### Nested Groups

```dart
void main() {
  group('Calculator', () {
    group('add', () {
      test('adds positive numbers', () {
        expect(Calculator.add(2, 3), 5);
      });

      test('adds negative numbers', () {
        expect(Calculator.add(-2, -3), -5);
      });

      test('handles zero', () {
        expect(Calculator.add(0, 5), 5);
      });
    });

    group('divide', () {
      test('divides positive numbers', () {
        expect(Calculator.divide(10, 2), 5);
      });

      test('throws when dividing by zero', () {
        expect(
          () => Calculator.divide(10, 0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
```

### Benefits of Groups

- **Readable output**: Test results show hierarchical structure
- **Shared setup**: Use `setUp()` for common initialization
- **Focused testing**: Run only tests in a specific group
- **Better organization**: Logical grouping improves maintainability

## Testing Async Code

Flutter apps are inherently asynchronous. Test async functions using `async` and `await`.

### Testing Futures

```dart
// Source: lib/services/api_service.dart
class ApiService {
  Future<User> fetchUser(String id) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    return User(id: id, name: 'John Doe');
  }

  Future<List<User>> fetchUsers() async {
    await Future.delayed(Duration(seconds: 1));
    return [
      User(id: '1', name: 'John'),
      User(id: '2', name: 'Jane'),
    ];
  }
}

// Test: test/services/api_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiService', () {
    late ApiService service;

    setUp(() {
      service = ApiService();
    });

    test('fetchUser returns user with correct id', () async {
      final user = await service.fetchUser('123');

      expect(user.id, '123');
      expect(user.name, isNotEmpty);
    });

    test('fetchUsers returns list of users', () async {
      final users = await service.fetchUsers();

      expect(users, hasLength(2));
      expect(users[0].name, 'John');
      expect(users[1].name, 'Jane');
    });

    test('fetchUser completes within timeout', () async {
      await expectLater(
        service.fetchUser('123'),
        completes,
      );
    });
  });
}
```

### Testing Error Conditions

```dart
test('fetchUser throws exception for invalid id', () async {
  expect(
    () async => await service.fetchUser('invalid'),
    throwsA(isA<NotFoundException>()),
  );
});

test('fetchUser throws specific error message', () async {
  try {
    await service.fetchUser('invalid');
    fail('Expected exception was not thrown');
  } catch (e) {
    expect(e.toString(), contains('User not found'));
  }
});
```

### Async Matchers

```dart
test('operation completes successfully', () async {
  await expectLater(
    service.performOperation(),
    completes,
  );
});

test('operation throws exception', () async {
  await expectLater(
    service.failingOperation(),
    throwsA(isA<CustomException>()),
  );
});

test('future emits expected value', () async {
  await expectLater(
    service.getValue(),
    completion(equals(42)),
  );
});
```

## Testing Streams

Streams are common in Flutter for real-time data, state management, and reactive programming.

### Basic Stream Testing

```dart
// Source: lib/services/counter_service.dart
class CounterService {
  final _controller = StreamController<int>();
  int _count = 0;

  Stream<int> get counterStream => _controller.stream;

  void increment() {
    _count++;
    _controller.add(_count);
  }

  void dispose() {
    _controller.close();
  }
}

// Test: test/services/counter_service_test.dart
void main() {
  group('CounterService', () {
    late CounterService service;

    setUp(() {
      service = CounterService();
    });

    tearDown(() {
      service.dispose();
    });

    test('stream emits incremented values', () async {
      // Arrange: Set up expectations
      final expectedValues = [1, 2, 3];
      final actualValues = <int>[];

      // Act: Subscribe to stream
      final subscription = service.counterStream.listen(actualValues.add);

      service.increment();
      service.increment();
      service.increment();

      // Wait for stream events to be processed
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      expect(actualValues, expectedValues);

      await subscription.cancel();
    });

    test('stream emits values in order', () {
      expectLater(
        service.counterStream,
        emitsInOrder([1, 2, 3]),
      );

      service.increment();
      service.increment();
      service.increment();
    });

    test('stream completes when disposed', () {
      expectLater(
        service.counterStream,
        emitsInOrder([1, 2, emitsDone]),
      );

      service.increment();
      service.increment();
      service.dispose();
    });
  });
}
```

### Advanced Stream Testing

```dart
test('stream emits through transformations', () {
  final stream = Stream.fromIterable([1, 2, 3, 4, 5]);

  expectLater(
    stream.where((n) => n.isEven).map((n) => n * 2),
    emitsInOrder([4, 8]),
  );
});

test('stream handles errors', () {
  final stream = Stream.fromIterable([1, 2, 3]).map((n) {
    if (n == 2) throw Exception('Error at 2');
    return n;
  });

  expectLater(
    stream,
    emitsInOrder([
      1,
      emitsError(isA<Exception>()),
      3,
    ]),
  );
});

test('broadcast stream can have multiple listeners', () {
  final controller = StreamController<int>.broadcast();
  final stream = controller.stream;

  expectLater(stream, emitsInOrder([1, 2, 3]));
  expectLater(stream, emitsInOrder([1, 2, 3]));

  controller.add(1);
  controller.add(2);
  controller.add(3);
  controller.close();
});
```

## Mocking Dependencies

Real unit tests isolate the code under test by mocking dependencies. Use `mockito` for creating mocks.

### Generating Mocks

```dart
// test/services/user_service_test.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

// Import the classes to mock
import 'package:my_app/services/api_client.dart';
import 'package:my_app/repositories/user_repository.dart';

// Generate mocks by running: flutter pub run build_runner build
@GenerateMocks([ApiClient, UserRepository])
import 'user_service_test.mocks.dart';

void main() {
  group('UserService', () {
    late MockApiClient mockApiClient;
    late MockUserRepository mockRepository;
    late UserService service;

    setUp(() {
      mockApiClient = MockApiClient();
      mockRepository = MockUserRepository();
      service = UserService(mockApiClient, mockRepository);
    });

    test('getUser fetches from API and saves to repository', () async {
      // Arrange: Set up mock behavior
      final expectedUser = User(id: '123', name: 'John Doe');

      when(mockApiClient.fetchUser('123'))
          .thenAnswer((_) async => expectedUser);

      when(mockRepository.save(any))
          .thenAnswer((_) async => true);

      // Act: Call the method
      final user = await service.getUser('123');

      // Assert: Verify behavior
      expect(user, expectedUser);
      verify(mockApiClient.fetchUser('123')).called(1);
      verify(mockRepository.save(expectedUser)).called(1);
    });

    test('getUser throws exception on API failure', () async {
      // Arrange
      when(mockApiClient.fetchUser(any))
          .thenThrow(NetworkException('Connection failed'));

      // Act & Assert
      expect(
        () async => await service.getUser('123'),
        throwsA(isA<NetworkException>()),
      );

      verifyNever(mockRepository.save(any));
    });
  });
}
```

### Stubbing Methods

```dart
// Return a value
when(mock.someMethod()).thenReturn(42);

// Return different values on consecutive calls
when(mock.someMethod()).thenReturn(1, 2, 3);

// Return async value
when(mock.fetchData()).thenAnswer((_) async => data);

// Throw exception
when(mock.failingMethod()).thenThrow(Exception('Error'));

// Match any argument
when(mock.methodWithArg(any)).thenReturn(result);

// Match specific argument
when(mock.methodWithArg('specific')).thenReturn(result);

// Match argument with matcher
when(mock.methodWithArg(argThat(startsWith('prefix')))).thenReturn(result);
```

### Verifying Interactions

```dart
// Verify method was called
verify(mock.someMethod());

// Verify method was called with specific arguments
verify(mock.methodWithArg('value'));

// Verify method was called N times
verify(mock.someMethod()).called(3);

// Verify method was never called
verifyNever(mock.someMethod());

// Verify method was called at least/at most N times
verify(mock.someMethod()).called(greaterThan(2));
verify(mock.someMethod()).called(lessThanOrEqualTo(5));

// Verify call order
verifyInOrder([
  mock.firstMethod(),
  mock.secondMethod(),
  mock.thirdMethod(),
]);

// Verify no other interactions
verifyNoMoreInteractions(mock);
```

## Test Setup and Teardown

Use `setUp()` and `tearDown()` to prepare and clean up test environments.

### Basic Setup and Teardown

```dart
void main() {
  group('DatabaseService', () {
    late Database database;
    late DatabaseService service;

    setUp(() {
      // Runs before each test
      database = createInMemoryDatabase();
      service = DatabaseService(database);
    });

    tearDown(() {
      // Runs after each test
      database.close();
    });

    test('insert adds record to database', () {
      service.insert(record);
      expect(service.count(), 1);
    });

    test('delete removes record from database', () {
      service.insert(record);
      service.delete(record.id);
      expect(service.count(), 0);
    });
  });
}
```

### Setup All and Teardown All

```dart
void main() {
  group('ExpensiveResourceTests', () {
    late ExpensiveResource resource;

    setUpAll(() {
      // Runs once before all tests in this group
      resource = ExpensiveResource.create();
    });

    tearDownAll(() {
      // Runs once after all tests in this group
      resource.dispose();
    });

    test('test 1', () {
      // Use resource
    });

    test('test 2', () {
      // Use resource
    });
  });
}
```

### Nested Setup and Teardown

```dart
void main() {
  late HttpClient client;

  setUp(() {
    // Runs before each test in any nested group
    client = HttpClient();
  });

  tearDown(() {
    client.close();
  });

  group('GET requests', () {
    late GetService getService;

    setUp(() {
      // Runs after parent setUp, before each test in this group
      getService = GetService(client);
    });

    test('fetches data', () {
      // Both setUps have run
    });
  });

  group('POST requests', () {
    late PostService postService;

    setUp(() {
      postService = PostService(client);
    });

    test('sends data', () {
      // Both setUps have run
    });
  });
}
```

## Custom Matchers

Create custom matchers for complex assertions that improve test readability.

### Simple Custom Matcher

```dart
// Create a matcher for even numbers
Matcher isEven = predicate((n) => n % 2 == 0, 'is even');

test('validates even numbers', () {
  expect(4, isEven);
  expect(5, isNot(isEven));
});
```

### Complex Custom Matcher

```dart
// Custom matcher for validating User objects
class IsValidUser extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! User) return false;

    return item.id.isNotEmpty &&
           item.name.isNotEmpty &&
           item.email.contains('@');
  }

  @override
  Description describe(Description description) {
    return description.add('is a valid user with id, name, and email');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! User) {
      return mismatchDescription.add('is not a User object');
    }

    final user = item as User;
    if (user.id.isEmpty) {
      return mismatchDescription.add('has empty id');
    }
    if (user.name.isEmpty) {
      return mismatchDescription.add('has empty name');
    }
    if (!user.email.contains('@')) {
      return mismatchDescription.add('has invalid email');
    }

    return mismatchDescription;
  }
}

// Usage
test('creates valid user', () {
  final user = createUser();
  expect(user, IsValidUser());
});
```

### Useful Built-in Matchers

```dart
// Equality
expect(actual, equals(expected));
expect(actual, same(expected)); // Identity

// Numeric
expect(value, greaterThan(5));
expect(value, lessThanOrEqualTo(10));
expect(value, inRange(0, 100));
expect(value, closeTo(3.14, 0.01));

// Strings
expect(text, contains('substring'));
expect(text, startsWith('prefix'));
expect(text, endsWith('suffix'));
expect(text, matches(RegExp(r'\d+')));

// Collections
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, hasLength(5));
expect(list, contains(item));
expect(list, containsAll([item1, item2]));
expect(map, containsPair('key', 'value'));

// Types
expect(object, isA<String>());
expect(object, isNull);
expect(object, isNotNull);

// Exceptions
expect(() => throwError(), throwsException);
expect(() => throwError(), throwsA(isA<CustomException>()));

// Async
await expectLater(future, completes);
await expectLater(future, throwsException);
await expectLater(future, completion(equals(value)));
```

## Test-Driven Development

TDD is a development approach where tests are written before implementation. This leads to better API design and higher test coverage.

### TDD Workflow

1. **Write a failing test** describing the desired behavior
2. **Run the test** and watch it fail (RED)
3. **Write minimal code** to make the test pass
4. **Run tests** and watch them pass (GREEN)
5. **Refactor** the code while keeping tests green
6. **Repeat** for the next feature

### TDD Example: Building a Calculator

**Step 1: Write failing test**

```dart
// test/calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/calculator.dart';

void main() {
  group('Calculator', () {
    late Calculator calculator;

    setUp(() {
      calculator = Calculator();
    });

    test('add returns sum of two numbers', () {
      expect(calculator.add(2, 3), 5);
    });
  });
}
```

**Step 2: Run test (fails because Calculator doesn't exist)**

```bash
flutter test
# Error: Undefined class 'Calculator'
```

**Step 3: Write minimal implementation**

```dart
// lib/calculator.dart
class Calculator {
  int add(int a, int b) {
    return a + b;
  }
}
```

**Step 4: Run test (passes)**

```bash
flutter test
# ✓ Calculator add returns sum of two numbers
```

**Step 5: Add more tests and features**

```dart
test('subtract returns difference of two numbers', () {
  expect(calculator.subtract(5, 3), 2);
});

test('multiply returns product of two numbers', () {
  expect(calculator.multiply(4, 3), 12);
});

test('divide returns quotient of two numbers', () {
  expect(calculator.divide(10, 2), 5);
});

test('divide throws when dividing by zero', () {
  expect(
    () => calculator.divide(10, 0),
    throwsA(isA<ArgumentError>()),
  );
});
```

**Step 6: Implement features**

```dart
class Calculator {
  int add(int a, int b) => a + b;

  int subtract(int a, int b) => a - b;

  int multiply(int a, int b) => a * b;

  double divide(int a, int b) {
    if (b == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return a / b;
  }
}
```

## Best Practices

### 1. Test Behavior, Not Implementation

Focus on what the code does, not how it does it:

```dart
// Bad: Tests implementation details
test('uses specific algorithm', () {
  expect(sorter.usesQuickSort, true);
});

// Good: Tests behavior
test('sorts list in ascending order', () {
  final result = sorter.sort([3, 1, 2]);
  expect(result, [1, 2, 3]);
});
```

### 2. Keep Tests Fast

Unit tests should run in milliseconds:

```dart
// Bad: Slow test
test('processes data', () async {
  await Future.delayed(Duration(seconds: 2));
  // Test logic
});

// Good: Mock slow operations
test('processes data', () {
  when(mockService.fetchData()).thenAnswer((_) async => testData);
  // Test logic runs instantly
});
```

### 3. Make Tests Readable

Use descriptive names and clear structure:

```dart
// Bad: Unclear test
test('test1', () {
  var r = calc.add(2, 3);
  expect(r, 5);
});

// Good: Clear and descriptive
test('add returns the sum of two positive integers', () {
  final result = calculator.add(2, 3);
  expect(result, 5);
});
```

### 4. Test Edge Cases

Don't just test happy paths:

```dart
group('parseAge', () {
  test('parses valid age string', () {
    expect(parseAge('25'), 25);
  });

  test('returns null for null input', () {
    expect(parseAge(null), null);
  });

  test('returns null for empty string', () {
    expect(parseAge(''), null);
  });

  test('returns null for non-numeric input', () {
    expect(parseAge('abc'), null);
  });

  test('returns null for negative number', () {
    expect(parseAge('-5'), null);
  });

  test('returns null for age over 150', () {
    expect(parseAge('200'), null);
  });
});
```

### 5. Use Test Helpers

Extract common test setup into helper functions:

```dart
// test/helpers/test_helpers.dart
User createTestUser({
  String id = '1',
  String name = 'Test User',
  String email = 'test@example.com',
}) {
  return User(id: id, name: name, email: email);
}

List<User> createTestUsers(int count) {
  return List.generate(
    count,
    (i) => createTestUser(id: '$i', name: 'User $i'),
  );
}

// Usage in tests
test('filters users by name', () {
  final users = createTestUsers(10);
  final filtered = service.filterByName(users, 'User 5');
  expect(filtered, hasLength(1));
});
```

### 6. Avoid Test Interdependence

Tests should run independently in any order:

```dart
// Bad: Tests depend on shared state
var counter = 0;

test('increments counter', () {
  counter++;
  expect(counter, 1);
});

test('doubles counter', () {
  counter *= 2; // Depends on previous test
  expect(counter, 2);
});

// Good: Tests are independent
test('increments counter', () {
  final counter = 0;
  final result = counter + 1;
  expect(result, 1);
});

test('doubles counter', () {
  final counter = 1;
  final result = counter * 2;
  expect(result, 2);
});
```

### 7. Use Meaningful Assertions

Make test failures informative:

```dart
// Bad: Unclear failure message
expect(user != null, true);

// Good: Clear failure message
expect(user, isNotNull);

// Even better: With custom message
expect(user, isNotNull, reason: 'User should be created successfully');
```

### 8. Clean Up Resources

Always dispose of resources:

```dart
group('StreamController tests', () {
  late StreamController<int> controller;

  setUp(() {
    controller = StreamController<int>();
  });

  tearDown(() {
    controller.close(); // Prevent memory leaks
  });

  test('adds value to stream', () {
    expectLater(controller.stream, emits(42));
    controller.add(42);
  });
});
```

## Summary

Unit testing is the foundation of quality Flutter applications. Follow these key principles:

- **Test pure logic independently** of Flutter framework and UI
- **Use mocks** to isolate code under test from dependencies
- **Structure tests** with groups, setUp, and tearDown
- **Test async code** properly with async/await
- **Handle streams** with appropriate matchers
- **Practice TDD** for better API design and coverage
- **Keep tests fast, focused, and independent**
- **Test edge cases** and error conditions
- **Make tests readable** with descriptive names and clear assertions

Well-written unit tests give you confidence to refactor, add features, and deploy with certainty that your business logic works correctly.
