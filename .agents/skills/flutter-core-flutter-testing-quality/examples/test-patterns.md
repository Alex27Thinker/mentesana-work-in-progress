# Common Testing Patterns

This guide demonstrates common testing patterns and best practices for Flutter applications. These patterns are proven approaches for testing various scenarios you'll encounter in real-world Flutter development.

## Table of Contents

- [AAA Pattern (Arrange-Act-Assert)](#aaa-pattern-arrange-act-assert)
- [Testing Data Models](#testing-data-models)
- [Testing Repository Pattern](#testing-repository-pattern)
- [Testing State Management](#testing-state-management)
- [Testing Forms and Validation](#testing-forms-and-validation)
- [Testing Async Operations](#testing-async-operations)
- [Testing Error Handling](#testing-error-handling)
- [Testing Pagination](#testing-pagination)
- [Testing Search Functionality](#testing-search-functionality)
- [Testing Authentication Flow](#testing-authentication-flow)

## AAA Pattern (Arrange-Act-Assert)

The foundation of well-structured tests.

### Basic AAA Structure

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculator adds two numbers correctly', () {
    // Arrange: Set up test conditions
    final calculator = Calculator();
    final a = 5;
    final b = 3;

    // Act: Execute the operation
    final result = calculator.add(a, b);

    // Assert: Verify the result
    expect(result, 8);
  });
}
```

### AAA with Setup

```dart
group('ShoppingCart', () {
  late ShoppingCart cart;
  late Product testProduct;

  setUp(() {
    // Arrange: Common setup for all tests
    cart = ShoppingCart();
    testProduct = Product(id: '1', name: 'Test', price: 10.0);
  });

  test('adds item to cart', () {
    // Arrange: Cart is already set up in setUp()

    // Act
    cart.addItem(testProduct);

    // Assert
    expect(cart.items, contains(testProduct));
    expect(cart.itemCount, 1);
  });

  test('calculates total correctly', () {
    // Arrange
    cart.addItem(testProduct);
    cart.addItem(Product(id: '2', name: 'Test 2', price: 20.0));

    // Act
    final total = cart.total;

    // Assert
    expect(total, 30.0);
  });
});
```

## Testing Data Models

Testing model classes including serialization and validation.

### JSON Serialization

```dart
// Model: lib/models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final int age;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          age == other.age;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ email.hashCode ^ age.hashCode;
}

// Test: test/models/user_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Model', () {
    group('fromJson', () {
      test('creates User from valid JSON', () {
        // Arrange
        final json = {
          'id': '123',
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 30,
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.id, '123');
        expect(user.name, 'John Doe');
        expect(user.email, 'john@example.com');
        expect(user.age, 30);
      });

      test('throws when JSON is missing required fields', () {
        // Arrange
        final json = {
          'id': '123',
          'name': 'John Doe',
          // Missing email and age
        };

        // Act & Assert
        expect(() => User.fromJson(json), throwsA(isA<TypeError>()));
      });
    });

    group('toJson', () {
      test('converts User to JSON correctly', () {
        // Arrange
        final user = User(
          id: '123',
          name: 'John Doe',
          email: 'john@example.com',
          age: 30,
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['id'], '123');
        expect(json['name'], 'John Doe');
        expect(json['email'], 'john@example.com');
        expect(json['age'], 30);
      });
    });

    group('equality', () {
      test('users with same values are equal', () {
        // Arrange
        final user1 = User(id: '1', name: 'John', email: 'john@example.com', age: 30);
        final user2 = User(id: '1', name: 'John', email: 'john@example.com', age: 30);

        // Assert
        expect(user1, equals(user2));
      });

      test('users with different values are not equal', () {
        // Arrange
        final user1 = User(id: '1', name: 'John', email: 'john@example.com', age: 30);
        final user2 = User(id: '2', name: 'Jane', email: 'jane@example.com', age: 25);

        // Assert
        expect(user1, isNot(equals(user2)));
      });
    });
  });
}
```

### Model with Validation

```dart
// Model: lib/models/email.dart
class Email {
  final String value;

  Email(this.value) {
    if (value.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      throw ArgumentError('Invalid email format');
    }
  }

  @override
  String toString() => value;
}

// Test: test/models/email_test.dart
void main() {
  group('Email', () {
    test('creates Email with valid value', () {
      expect(() => Email('user@example.com'), returnsNormally);
    });

    test('throws on empty value', () {
      expect(
        () => Email(''),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Email cannot be empty',
        )),
      );
    });

    test('throws on invalid format', () {
      expect(
        () => Email('invalid-email'),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'Invalid email format',
        )),
      );
    });

    group('valid email formats', () {
      final validEmails = [
        'user@example.com',
        'user.name@example.com',
        'user+tag@example.co.uk',
        'user_name@example-domain.com',
      ];

      for (final email in validEmails) {
        test('accepts "$email"', () {
          expect(() => Email(email), returnsNormally);
        });
      }
    });
  });
}
```

## Testing Repository Pattern

Testing data access layer with mocked dependencies.

```dart
// Repository: lib/repositories/user_repository.dart
abstract class UserRepository {
  Future<User> getUser(String id);
  Future<List<User>> getUsers();
  Future<void> saveUser(User user);
  Future<void> deleteUser(String id);
}

class UserRepositoryImpl implements UserRepository {
  final ApiClient apiClient;
  final LocalDatabase database;

  UserRepositoryImpl({
    required this.apiClient,
    required this.database,
  });

  @override
  Future<User> getUser(String id) async {
    try {
      // Try to get from cache first
      final cachedUser = await database.getUser(id);
      if (cachedUser != null) {
        return cachedUser;
      }

      // Fetch from API
      final user = await apiClient.fetchUser(id);

      // Cache the user
      await database.saveUser(user);

      return user;
    } catch (e) {
      throw RepositoryException('Failed to get user: $e');
    }
  }

  @override
  Future<List<User>> getUsers() async {
    final users = await apiClient.fetchUsers();
    await database.saveUsers(users);
    return users;
  }

  @override
  Future<void> saveUser(User user) async {
    await apiClient.updateUser(user);
    await database.saveUser(user);
  }

  @override
  Future<void> deleteUser(String id) async {
    await apiClient.deleteUser(id);
    await database.deleteUser(id);
  }
}

// Test: test/repositories/user_repository_test.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

@GenerateMocks([ApiClient, LocalDatabase])
import 'user_repository_test.mocks.dart';

void main() {
  group('UserRepositoryImpl', () {
    late MockApiClient mockApiClient;
    late MockLocalDatabase mockDatabase;
    late UserRepositoryImpl repository;

    setUp(() {
      mockApiClient = MockApiClient();
      mockDatabase = MockLocalDatabase();
      repository = UserRepositoryImpl(
        apiClient: mockApiClient,
        database: mockDatabase,
      );
    });

    group('getUser', () {
      final testUser = User(
        id: '123',
        name: 'Test User',
        email: 'test@example.com',
        age: 30,
      );

      test('returns cached user when available', () async {
        // Arrange
        when(mockDatabase.getUser('123'))
            .thenAnswer((_) async => testUser);

        // Act
        final user = await repository.getUser('123');

        // Assert
        expect(user, testUser);
        verify(mockDatabase.getUser('123')).called(1);
        verifyNever(mockApiClient.fetchUser(any));
      });

      test('fetches from API when not cached', () async {
        // Arrange
        when(mockDatabase.getUser('123'))
            .thenAnswer((_) async => null);
        when(mockApiClient.fetchUser('123'))
            .thenAnswer((_) async => testUser);
        when(mockDatabase.saveUser(any))
            .thenAnswer((_) async => {});

        // Act
        final user = await repository.getUser('123');

        // Assert
        expect(user, testUser);
        verify(mockDatabase.getUser('123')).called(1);
        verify(mockApiClient.fetchUser('123')).called(1);
        verify(mockDatabase.saveUser(testUser)).called(1);
      });

      test('throws RepositoryException on error', () async {
        // Arrange
        when(mockDatabase.getUser('123'))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getUser('123'),
          throwsA(isA<RepositoryException>()),
        );
      });
    });

    group('saveUser', () {
      final testUser = User(
        id: '123',
        name: 'Test User',
        email: 'test@example.com',
        age: 30,
      );

      test('saves to both API and database', () async {
        // Arrange
        when(mockApiClient.updateUser(any))
            .thenAnswer((_) async => {});
        when(mockDatabase.saveUser(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.saveUser(testUser);

        // Assert
        verify(mockApiClient.updateUser(testUser)).called(1);
        verify(mockDatabase.saveUser(testUser)).called(1);
      });
    });

    group('deleteUser', () {
      test('deletes from both API and database', () async {
        // Arrange
        when(mockApiClient.deleteUser(any))
            .thenAnswer((_) async => {});
        when(mockDatabase.deleteUser(any))
            .thenAnswer((_) async => {});

        // Act
        await repository.deleteUser('123');

        // Assert
        verify(mockApiClient.deleteUser('123')).called(1);
        verify(mockDatabase.deleteUser('123')).called(1);
      });
    });
  });
}
```

## Testing State Management

Testing state management with different solutions.

### Testing ChangeNotifier

```dart
// State: lib/state/counter_state.dart
import 'package:flutter/foundation.dart';

class CounterState extends ChangeNotifier {
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

// Test: test/state/counter_state_test.dart
void main() {
  group('CounterState', () {
    late CounterState state;

    setUp(() {
      state = CounterState();
    });

    test('initial count is 0', () {
      expect(state.count, 0);
    });

    test('increment increases count', () {
      state.increment();
      expect(state.count, 1);
    });

    test('decrement decreases count', () {
      state.increment();
      state.increment();
      state.decrement();
      expect(state.count, 1);
    });

    test('reset sets count to 0', () {
      state.increment();
      state.increment();
      state.reset();
      expect(state.count, 0);
    });

    test('notifies listeners on increment', () {
      var notified = false;
      state.addListener(() => notified = true);

      state.increment();

      expect(notified, true);
    });

    test('multiple operations work correctly', () {
      state.increment(); // 1
      state.increment(); // 2
      state.increment(); // 3
      state.decrement(); // 2
      expect(state.count, 2);
    });
  });
}
```

### Testing BLoC

```dart
// BLoC: lib/blocs/counter_bloc.dart
import 'package:bloc/bloc.dart';

abstract class CounterEvent {}

class IncrementEvent extends CounterEvent {}
class DecrementEvent extends CounterEvent {}
class ResetEvent extends CounterEvent {}

class CounterState {
  final int count;
  CounterState(this.count);
}

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(0)) {
    on<IncrementEvent>((event, emit) {
      emit(CounterState(state.count + 1));
    });

    on<DecrementEvent>((event, emit) {
      emit(CounterState(state.count - 1));
    });

    on<ResetEvent>((event, emit) {
      emit(CounterState(0));
    });
  }
}

// Test: test/blocs/counter_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';

void main() {
  group('CounterBloc', () {
    blocTest<CounterBloc, CounterState>(
      'emits [CounterState(1)] when IncrementEvent is added',
      build: () => CounterBloc(),
      act: (bloc) => bloc.add(IncrementEvent()),
      expect: () => [CounterState(1)],
    );

    blocTest<CounterBloc, CounterState>(
      'emits [CounterState(-1)] when DecrementEvent is added',
      build: () => CounterBloc(),
      act: (bloc) => bloc.add(DecrementEvent()),
      expect: () => [CounterState(-1)],
    );

    blocTest<CounterBloc, CounterState>(
      'emits [CounterState(0)] when ResetEvent is added after increment',
      build: () => CounterBloc(),
      act: (bloc) {
        bloc.add(IncrementEvent());
        bloc.add(IncrementEvent());
        bloc.add(ResetEvent());
      },
      expect: () => [
        CounterState(1),
        CounterState(2),
        CounterState(0),
      ],
    );
  });
}
```

## Testing Forms and Validation

Testing form inputs and validation logic.

```dart
// Validator: lib/validators/form_validators.dart
class FormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirm) {
      return 'Passwords do not match';
    }
    return null;
  }
}

// Test: test/validators/form_validators_test.dart
void main() {
  group('FormValidators', () {
    group('validateEmail', () {
      test('returns null for valid email', () {
        expect(FormValidators.validateEmail('user@example.com'), null);
      });

      test('returns error for empty email', () {
        expect(
          FormValidators.validateEmail(''),
          'Email is required',
        );
      });

      test('returns error for null email', () {
        expect(
          FormValidators.validateEmail(null),
          'Email is required',
        );
      });

      test('returns error for invalid email format', () {
        expect(
          FormValidators.validateEmail('invalid-email'),
          'Please enter a valid email',
        );
      });

      final validEmails = [
        'user@example.com',
        'user.name@example.com',
        'user+tag@example.co.uk',
      ];

      for (final email in validEmails) {
        test('accepts valid email: $email', () {
          expect(FormValidators.validateEmail(email), null);
        });
      }
    });

    group('validatePassword', () {
      test('returns null for valid password', () {
        expect(FormValidators.validatePassword('Password123'), null);
      });

      test('returns error for empty password', () {
        expect(
          FormValidators.validatePassword(''),
          'Password is required',
        );
      });

      test('returns error for short password', () {
        expect(
          FormValidators.validatePassword('Pass1'),
          'Password must be at least 8 characters',
        );
      });

      test('returns error for password without uppercase', () {
        expect(
          FormValidators.validatePassword('password123'),
          'Password must contain an uppercase letter',
        );
      });

      test('returns error for password without number', () {
        expect(
          FormValidators.validatePassword('Password'),
          'Password must contain a number',
        );
      });
    });

    group('validateConfirmPassword', () {
      test('returns null when passwords match', () {
        expect(
          FormValidators.validateConfirmPassword('Pass123', 'Pass123'),
          null,
        );
      });

      test('returns error when passwords do not match', () {
        expect(
          FormValidators.validateConfirmPassword('Pass123', 'Pass456'),
          'Passwords do not match',
        );
      });

      test('returns error for empty confirm password', () {
        expect(
          FormValidators.validateConfirmPassword('Pass123', ''),
          'Please confirm your password',
        );
      });
    });
  });
}
```

## Testing Async Operations

Testing futures, streams, and async state.

```dart
// Service: lib/services/data_service.dart
class DataService {
  final ApiClient apiClient;

  DataService(this.apiClient);

  Future<List<Item>> fetchItems() async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    return await apiClient.getItems();
  }

  Stream<Item> watchItems() {
    return Stream.periodic(
      Duration(seconds: 1),
      (count) => Item(id: '$count', name: 'Item $count'),
    ).take(5);
  }

  Future<Item> createItem(String name) async {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    return await apiClient.createItem(name);
  }
}

// Test: test/services/data_service_test.dart
@GenerateMocks([ApiClient])
import 'data_service_test.mocks.dart';

void main() {
  group('DataService', () {
    late MockApiClient mockApiClient;
    late DataService service;

    setUp(() {
      mockApiClient = MockApiClient();
      service = DataService(mockApiClient);
    });

    group('fetchItems', () {
      test('returns items from API', () async {
        // Arrange
        final expectedItems = [
          Item(id: '1', name: 'Item 1'),
          Item(id: '2', name: 'Item 2'),
        ];
        when(mockApiClient.getItems())
            .thenAnswer((_) async => expectedItems);

        // Act
        final items = await service.fetchItems();

        // Assert
        expect(items, expectedItems);
        verify(mockApiClient.getItems()).called(1);
      });

      test('completes within timeout', () async {
        // Arrange
        when(mockApiClient.getItems())
            .thenAnswer((_) async => []);

        // Act & Assert
        await expectLater(
          service.fetchItems(),
          completes,
        );
      });
    });

    group('watchItems', () {
      test('emits items over time', () async {
        // Assert
        expect(
          service.watchItems(),
          emitsInOrder([
            isA<Item>().having((i) => i.id, 'id', '0'),
            isA<Item>().having((i) => i.id, 'id', '1'),
            isA<Item>().having((i) => i.id, 'id', '2'),
            isA<Item>().having((i) => i.id, 'id', '3'),
            isA<Item>().having((i) => i.id, 'id', '4'),
            emitsDone,
          ]),
        );
      });

      test('stream completes after 5 items', () {
        expect(
          service.watchItems(),
          emitsInOrder([
            anything,
            anything,
            anything,
            anything,
            anything,
            emitsDone,
          ]),
        );
      });
    });

    group('createItem', () {
      test('creates item successfully', () async {
        // Arrange
        final expectedItem = Item(id: '1', name: 'New Item');
        when(mockApiClient.createItem('New Item'))
            .thenAnswer((_) async => expectedItem);

        // Act
        final item = await service.createItem('New Item');

        // Assert
        expect(item, expectedItem);
      });

      test('throws on empty name', () {
        // Act & Assert
        expect(
          () => service.createItem(''),
          throwsArgumentError,
        );
      });
    });
  });
}
```

## Testing Error Handling

Comprehensive error scenario testing.

```dart
// Service: lib/services/user_service.dart
enum UserServiceError {
  notFound,
  unauthorized,
  serverError,
  networkError,
}

class UserServiceException implements Exception {
  final UserServiceError error;
  final String message;

  UserServiceException(this.error, this.message);

  @override
  String toString() => 'UserServiceException: $message';
}

class UserService {
  final ApiClient apiClient;

  UserService(this.apiClient);

  Future<User> fetchUser(String id) async {
    try {
      final response = await apiClient.get('/users/$id');

      if (response.statusCode == 404) {
        throw UserServiceException(
          UserServiceError.notFound,
          'User not found',
        );
      }

      if (response.statusCode == 401) {
        throw UserServiceException(
          UserServiceError.unauthorized,
          'Unauthorized',
        );
      }

      if (response.statusCode >= 500) {
        throw UserServiceException(
          UserServiceError.serverError,
          'Server error',
        );
      }

      return User.fromJson(response.body);
    } on SocketException {
      throw UserServiceException(
        UserServiceError.networkError,
        'Network connection failed',
      );
    } on TimeoutException {
      throw UserServiceException(
        UserServiceError.networkError,
        'Request timed out',
      );
    }
  }
}

// Test: test/services/user_service_test.dart
void main() {
  group('UserService Error Handling', () {
    late MockApiClient mockApiClient;
    late UserService service;

    setUp(() {
      mockApiClient = MockApiClient();
      service = UserService(mockApiClient);
    });

    test('throws notFound error on 404', () async {
      // Arrange
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => Response(statusCode: 404, body: {}),
      );

      // Act & Assert
      expect(
        () => service.fetchUser('123'),
        throwsA(
          isA<UserServiceException>().having(
            (e) => e.error,
            'error',
            UserServiceError.notFound,
          ),
        ),
      );
    });

    test('throws unauthorized error on 401', () async {
      // Arrange
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => Response(statusCode: 401, body: {}),
      );

      // Act & Assert
      expect(
        () => service.fetchUser('123'),
        throwsA(
          isA<UserServiceException>().having(
            (e) => e.error,
            'error',
            UserServiceError.unauthorized,
          ),
        ),
      );
    });

    test('throws serverError on 500', () async {
      // Arrange
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => Response(statusCode: 500, body: {}),
      );

      // Act & Assert
      expect(
        () => service.fetchUser('123'),
        throwsA(
          isA<UserServiceException>().having(
            (e) => e.error,
            'error',
            UserServiceError.serverError,
          ),
        ),
      );
    });

    test('throws networkError on SocketException', () async {
      // Arrange
      when(mockApiClient.get(any)).thenThrow(SocketException(''));

      // Act & Assert
      expect(
        () => service.fetchUser('123'),
        throwsA(
          isA<UserServiceException>().having(
            (e) => e.error,
            'error',
            UserServiceError.networkError,
          ),
        ),
      );
    });

    test('throws networkError on TimeoutException', () async {
      // Arrange
      when(mockApiClient.get(any)).thenThrow(TimeoutException(''));

      // Act & Assert
      expect(
        () => service.fetchUser('123'),
        throwsA(
          isA<UserServiceException>().having(
            (e) => e.error,
            'error',
            UserServiceError.networkError,
          ),
        ),
      );
    });
  });
}
```

(Due to length constraints, I'll provide a summary of remaining patterns rather than full implementation)

## Additional Patterns Summary

**Testing Pagination**: Test loading pages, reaching end, error handling during pagination

**Testing Search**: Test search queries, debouncing, empty results, special characters

**Testing Authentication**: Test login flow, token refresh, session expiration, logout

These patterns provide a solid foundation for testing real-world Flutter applications. Apply the AAA pattern consistently, mock external dependencies, and test both happy paths and error conditions comprehensively.
