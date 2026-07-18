# Mocking Strategies

Effective mocking is essential for isolating code under test from external dependencies. This guide demonstrates comprehensive mocking strategies for HTTP clients, databases, platform channels, and other common Flutter dependencies.

## Table of Contents

- [Mocking with Mockito](#mocking-with-mockito)
- [Mocking HTTP Clients](#mocking-http-clients)
- [Mocking Dio](#mocking-dio)
- [Mocking Databases](#mocking-databases)
- [Mocking SharedPreferences](#mocking-sharedpreferences)
- [Mocking Platform Channels](#mocking-platform-channels)
- [Mocking Streams](#mocking-streams)
- [Mocking Navigation](#mocking-navigation)
- [Manual Mocks (Fakes)](#manual-mocks-fakes)
- [Best Practices](#best-practices)

## Mocking with Mockito

Mockito is the standard mocking library for Dart and Flutter.

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### Generating Mocks

```dart
// test/services/user_service_test.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

// Classes to mock
import 'package:my_app/services/api_client.dart';
import 'package:my_app/repositories/user_repository.dart';

// Generate mocks
@GenerateMocks([ApiClient, UserRepository])
import 'user_service_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late MockUserRepository mockRepository;

  setUp(() {
    mockApiClient = MockApiClient();
    mockRepository = MockUserRepository();
  });

  test('example test', () {
    // Use mocks in tests
  });
}
```

### Generate Mock Classes

```bash
# Generate mocks
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch
```

### Basic Stubbing

```dart
test('stubbing methods', () {
  // Return a value
  when(mockApiClient.getUser('123'))
      .thenReturn(User(id: '123', name: 'John'));

  // Return async value
  when(mockApiClient.fetchUser('123'))
      .thenAnswer((_) async => User(id: '123', name: 'John'));

  // Throw exception
  when(mockApiClient.getUser('invalid'))
      .thenThrow(NotFoundException());

  // Return different values on consecutive calls
  when(mockApiClient.getRetryCount())
      .thenReturn(1, 2, 3);
});
```

### Verification

```dart
test('verifying interactions', () {
  final service = UserService(mockApiClient);

  service.fetchUser('123');

  // Verify method was called
  verify(mockApiClient.getUser('123')).called(1);

  // Verify method was called with any argument
  verify(mockApiClient.getUser(any)).called(1);

  // Verify method was never called
  verifyNever(mockApiClient.deleteUser(any));

  // Verify call order
  verifyInOrder([
    mockApiClient.authenticate(),
    mockApiClient.getUser('123'),
  ]);

  // Verify no other interactions
  verifyNoMoreInteractions(mockApiClient);
});
```

## Mocking HTTP Clients

Testing code that makes HTTP requests.

### Mocking http.Client

```dart
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Service using http.Client
class UserApiService {
  final http.Client client;

  UserApiService(this.client);

  Future<User> fetchUser(String id) async {
    final response = await client.get(
      Uri.parse('https://api.example.com/users/$id'),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<void> createUser(User user) async {
    final response = await client.post(
      Uri.parse('https://api.example.com/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create user');
    }
  }
}

// Test
@GenerateMocks([http.Client])
import 'user_api_service_test.mocks.dart';

void main() {
  group('UserApiService', () {
    late MockClient mockClient;
    late UserApiService service;

    setUp(() {
      mockClient = MockClient();
      service = UserApiService(mockClient);
    });

    group('fetchUser', () {
      test('returns User when successful', () async {
        // Arrange
        final jsonResponse = jsonEncode({
          'id': '123',
          'name': 'John Doe',
          'email': 'john@example.com',
        });

        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response(jsonResponse, 200));

        // Act
        final user = await service.fetchUser('123');

        // Assert
        expect(user.id, '123');
        expect(user.name, 'John Doe');
        verify(mockClient.get(
          Uri.parse('https://api.example.com/users/123'),
        )).called(1);
      });

      test('throws exception on error', () async {
        // Arrange
        when(mockClient.get(any))
            .thenAnswer((_) async => http.Response('Not Found', 404));

        // Act & Assert
        expect(
          () => service.fetchUser('123'),
          throwsException,
        );
      });
    });

    group('createUser', () {
      test('creates user successfully', () async {
        // Arrange
        final user = User(id: '1', name: 'Jane', email: 'jane@example.com');

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('', 201));

        // Act
        await service.createUser(user);

        // Assert
        verify(mockClient.post(
          Uri.parse('https://api.example.com/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user.toJson()),
        )).called(1);
      });

      test('throws exception on error', () async {
        // Arrange
        final user = User(id: '1', name: 'Jane', email: 'jane@example.com');

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('Error', 500));

        // Act & Assert
        expect(
          () => service.createUser(user),
          throwsException,
        );
      });
    });
  });
}
```

### Mock HTTP Responses with Different Status Codes

```dart
test('handles various HTTP status codes', () async {
  // Success
  when(mockClient.get(any))
      .thenAnswer((_) async => http.Response('{"data": "ok"}', 200));

  // Created
  when(mockClient.post(any))
      .thenAnswer((_) async => http.Response('', 201));

  // Bad Request
  when(mockClient.put(any))
      .thenAnswer((_) async => http.Response('Bad Request', 400));

  // Unauthorized
  when(mockClient.get(Uri.parse('/protected')))
      .thenAnswer((_) async => http.Response('Unauthorized', 401));

  // Not Found
  when(mockClient.get(Uri.parse('/missing')))
      .thenAnswer((_) async => http.Response('Not Found', 404));

  // Server Error
  when(mockClient.get(Uri.parse('/error')))
      .thenAnswer((_) async => http.Response('Server Error', 500));
});
```

## Mocking Dio

Dio is a popular HTTP client with interceptors and more features.

### Mocking Dio

```dart
import 'package:dio/dio.dart';

// Service using Dio
class ApiService {
  final Dio dio;

  ApiService(this.dio);

  Future<List<User>> getUsers() async {
    final response = await dio.get<List<dynamic>>('/users');
    return response.data!.map((json) => User.fromJson(json)).toList();
  }

  Future<User> createUser(User user) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/users',
      data: user.toJson(),
    );
    return User.fromJson(response.data!);
  }
}

// Test with mocked Dio
@GenerateMocks([Dio])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService', () {
    late MockDio mockDio;
    late ApiService service;

    setUp(() {
      mockDio = MockDio();
      service = ApiService(mockDio);
    });

    test('getUsers returns list of users', () async {
      // Arrange
      final responseData = [
        {'id': '1', 'name': 'User 1'},
        {'id': '2', 'name': 'User 2'},
      ];

      when(mockDio.get<List<dynamic>>('/users'))
          .thenAnswer((_) async => Response(
                data: responseData,
                statusCode: 200,
                requestOptions: RequestOptions(path: '/users'),
              ));

      // Act
      final users = await service.getUsers();

      // Assert
      expect(users, hasLength(2));
      expect(users[0].name, 'User 1');
    });

    test('createUser creates and returns user', () async {
      // Arrange
      final user = User(id: '1', name: 'New User');
      final responseData = {'id': '1', 'name': 'New User'};

      when(mockDio.post<Map<String, dynamic>>(
        '/users',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: responseData,
            statusCode: 201,
            requestOptions: RequestOptions(path: '/users'),
          ));

      // Act
      final created = await service.createUser(user);

      // Assert
      expect(created.id, '1');
      verify(mockDio.post('/users', data: user.toJson())).called(1);
    });

    test('handles DioException', () async {
      // Arrange
      when(mockDio.get<List<dynamic>>('/users'))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/users'),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act & Assert
      expect(() => service.getUsers(), throwsA(isA<DioException>()));
    });
  });
}
```

## Mocking Databases

Testing database operations without actual database.

### Mocking Sqflite

```dart
import 'package:sqflite/sqflite.dart';

// Database service
class UserDatabase {
  final Database database;

  UserDatabase(this.database);

  Future<List<User>> getUsers() async {
    final List<Map<String, dynamic>> maps = await database.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<int> insertUser(User user) async {
    return await database.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    return await database.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(String id) async {
    return await database.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// Test
@GenerateMocks([Database])
import 'user_database_test.mocks.dart';

void main() {
  group('UserDatabase', () {
    late MockDatabase mockDatabase;
    late UserDatabase userDb;

    setUp(() {
      mockDatabase = MockDatabase();
      userDb = UserDatabase(mockDatabase);
    });

    test('getUsers returns list of users', () async {
      // Arrange
      final data = [
        {'id': '1', 'name': 'User 1', 'email': 'user1@example.com'},
        {'id': '2', 'name': 'User 2', 'email': 'user2@example.com'},
      ];

      when(mockDatabase.query('users'))
          .thenAnswer((_) async => data);

      // Act
      final users = await userDb.getUsers();

      // Assert
      expect(users, hasLength(2));
      expect(users[0].name, 'User 1');
    });

    test('insertUser inserts and returns row id', () async {
      // Arrange
      final user = User(id: '1', name: 'New User', email: 'new@example.com');

      when(mockDatabase.insert('users', any))
          .thenAnswer((_) async => 1);

      // Act
      final id = await userDb.insertUser(user);

      // Assert
      expect(id, 1);
      verify(mockDatabase.insert('users', user.toMap())).called(1);
    });

    test('updateUser updates user', () async {
      // Arrange
      final user = User(id: '1', name: 'Updated', email: 'updated@example.com');

      when(mockDatabase.update(
        'users',
        any,
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      )).thenAnswer((_) async => 1);

      // Act
      final rowsAffected = await userDb.updateUser(user);

      // Assert
      expect(rowsAffected, 1);
      verify(mockDatabase.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      )).called(1);
    });

    test('deleteUser deletes user', () async {
      // Arrange
      when(mockDatabase.delete(
        'users',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      )).thenAnswer((_) async => 1);

      // Act
      final rowsDeleted = await userDb.deleteUser('1');

      // Assert
      expect(rowsDeleted, 1);
      verify(mockDatabase.delete(
        'users',
        where: 'id = ?',
        whereArgs: ['1'],
      )).called(1);
    });
  });
}
```

## Mocking SharedPreferences

Testing preferences without actual persistence.

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Preferences service
class PreferencesService {
  final SharedPreferences prefs;

  PreferencesService(this.prefs);

  String? getUsername() => prefs.getString('username');

  Future<bool> setUsername(String username) =>
      prefs.setString('username', username);

  bool isDarkMode() => prefs.getBool('darkMode') ?? false;

  Future<bool> setDarkMode(bool enabled) =>
      prefs.setBool('darkMode', enabled);
}

// Test
@GenerateMocks([SharedPreferences])
import 'preferences_service_test.mocks.dart';

void main() {
  group('PreferencesService', () {
    late MockSharedPreferences mockPrefs;
    late PreferencesService service;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      service = PreferencesService(mockPrefs);
    });

    test('getUsername returns stored username', () {
      // Arrange
      when(mockPrefs.getString('username')).thenReturn('john_doe');

      // Act
      final username = service.getUsername();

      // Assert
      expect(username, 'john_doe');
    });

    test('setUsername stores username', () async {
      // Arrange
      when(mockPrefs.setString('username', any))
          .thenAnswer((_) async => true);

      // Act
      final result = await service.setUsername('jane_doe');

      // Assert
      expect(result, true);
      verify(mockPrefs.setString('username', 'jane_doe')).called(1);
    });

    test('isDarkMode returns stored value', () {
      // Arrange
      when(mockPrefs.getBool('darkMode')).thenReturn(true);

      // Act
      final isDark = service.isDarkMode();

      // Assert
      expect(isDark, true);
    });

    test('isDarkMode returns false when not set', () {
      // Arrange
      when(mockPrefs.getBool('darkMode')).thenReturn(null);

      // Act
      final isDark = service.isDarkMode();

      // Assert
      expect(isDark, false);
    });
  });
}
```

## Mocking Platform Channels

Testing platform-specific functionality.

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Service using platform channels
class BatteryService {
  static const platform = MethodChannel('samples.flutter.dev/battery');

  Future<int> getBatteryLevel() async {
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to get battery level: ${e.message}');
    }
  }

  Future<void> openSettings() async {
    await platform.invokeMethod('openSettings');
  }
}

// Test
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BatteryService', () {
    late BatteryService service;
    const MethodChannel channel = MethodChannel('samples.flutter.dev/battery');

    setUp(() {
      service = BatteryService();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getBatteryLevel returns battery level', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getBatteryLevel') {
          return 85;
        }
        return null;
      });

      // Act
      final level = await service.getBatteryLevel();

      // Assert
      expect(level, 85);
    });

    test('getBatteryLevel throws on platform exception', () async {
      // Arrange
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'Battery unavailable');
      });

      // Act & Assert
      expect(() => service.getBatteryLevel(), throwsException);
    });

    test('openSettings calls platform method', () async {
      // Arrange
      bool methodCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'openSettings') {
          methodCalled = true;
        }
        return null;
      });

      // Act
      await service.openSettings();

      // Assert
      expect(methodCalled, true);
    });
  });
}
```

## Mocking Streams

Testing stream-based functionality.

```dart
import 'dart:async';

// Service with stream
class LocationService {
  final StreamController<Location> _controller;

  LocationService() : _controller = StreamController<Location>.broadcast();

  Stream<Location> get locationStream => _controller.stream;

  void updateLocation(Location location) {
    _controller.add(location);
  }

  void dispose() {
    _controller.close();
  }
}

// Test
void main() {
  group('LocationService', () {
    late LocationService service;

    setUp(() {
      service = LocationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('stream emits location updates', () {
      // Arrange
      final location1 = Location(lat: 1.0, lng: 1.0);
      final location2 = Location(lat: 2.0, lng: 2.0);

      // Assert
      expect(
        service.locationStream,
        emitsInOrder([location1, location2]),
      );

      // Act
      service.updateLocation(location1);
      service.updateLocation(location2);
    });

    test('stream can have multiple listeners', () {
      // Arrange
      final location = Location(lat: 1.0, lng: 1.0);

      // Assert
      expect(service.locationStream, emits(location));
      expect(service.locationStream, emits(location));

      // Act
      service.updateLocation(location);
    });
  });
}
```

## Mocking Navigation

Testing navigation without MaterialApp.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Widget that navigates
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DetailsScreen()),
          );
        },
        child: const Text('Go to Details'),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Text('Details'),
    );
  }
}

// Mock NavigatorObserver
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

// Test
@GenerateMocks([NavigatorObserver])
import 'navigation_test.mocks.dart';

void main() {
  group('Navigation', () {
    late MockNavigatorObserver mockObserver;

    setUp(() {
      mockObserver = MockNavigatorObserver();
    });

    testWidgets('navigates to details screen', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          navigatorObservers: [mockObserver],
        ),
      );

      // Act
      await tester.tap(find.text('Go to Details'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockObserver.didPush(any, any));
      expect(find.byType(DetailsScreen), findsOneWidget);
    });
  });
}
```

## Manual Mocks (Fakes)

Creating fake implementations for testing.

```dart
// Interface
abstract class UserRepository {
  Future<User?> getUser(String id);
  Future<void> saveUser(User user);
  Future<List<User>> getAllUsers();
}

// Fake implementation for testing
class FakeUserRepository implements UserRepository {
  final Map<String, User> _users = {};
  bool shouldFail = false;

  @override
  Future<User?> getUser(String id) async {
    if (shouldFail) {
      throw Exception('Database error');
    }
    return _users[id];
  }

  @override
  Future<void> saveUser(User user) async {
    if (shouldFail) {
      throw Exception('Database error');
    }
    _users[user.id] = user;
  }

  @override
  Future<List<User>> getAllUsers() async {
    if (shouldFail) {
      throw Exception('Database error');
    }
    return _users.values.toList();
  }

  // Test helpers
  void clear() {
    _users.clear();
  }

  int get userCount => _users.length;
}

// Test
void main() {
  group('UserService with Fake', () {
    late FakeUserRepository fakeRepo;
    late UserService service;

    setUp(() {
      fakeRepo = FakeUserRepository();
      service = UserService(fakeRepo);
    });

    test('saves and retrieves user', () async {
      // Arrange
      final user = User(id: '1', name: 'Test');

      // Act
      await service.saveUser(user);
      final retrieved = await service.getUser('1');

      // Assert
      expect(retrieved, user);
      expect(fakeRepo.userCount, 1);
    });

    test('handles repository errors', () async {
      // Arrange
      fakeRepo.shouldFail = true;

      // Act & Assert
      expect(() => service.getUser('1'), throwsException);
    });
  });
}
```

## Best Practices

### 1. Mock Interfaces, Not Implementations

```dart
// Good: Mock the interface
abstract class DataSource {
  Future<Data> fetch();
}

@GenerateMocks([DataSource])

// Bad: Mock concrete implementation
class ConcreteDataSource implements DataSource {
  @override
  Future<Data> fetch() => ...;
}
```

### 2. Use Descriptive Mock Names

```dart
// Good
late MockUserRepository mockUserRepo;
late MockApiClient mockApiClient;

// Bad
late MockUserRepository mock1;
late MockApiClient m;
```

### 3. Reset Mocks Between Tests

```dart
setUp(() {
  mockApiClient = MockApiClient();
  // Fresh mock for each test
});

// Or explicitly reset
setUp(() {
  reset(mockApiClient);
});
```

### 4. Verify Important Interactions

```dart
test('saves user to repository', () async {
  await service.createUser(user);

  // Verify the important interaction happened
  verify(mockRepository.save(user)).called(1);
});
```

### 5. Don't Over-Mock

```dart
// Bad: Mocking everything
when(mock.add(any, any)).thenReturn(0);
when(mock.subtract(any, any)).thenReturn(0);
when(mock.multiply(any, any)).thenReturn(0);

// Good: Mock only what's needed for the test
when(mock.add(2, 3)).thenReturn(5);
```

## Summary

Effective mocking strategies:

- **Use Mockito** for automatic mock generation
- **Mock HTTP clients** to test network code
- **Mock databases** to isolate persistence logic
- **Mock SharedPreferences** for settings tests
- **Mock platform channels** for native functionality
- **Mock streams** for reactive programming
- **Mock navigation** to test routing
- **Create fakes** for complex behaviors
- **Follow best practices** for maintainable tests

Proper mocking enables fast, reliable, and isolated unit tests that give you confidence in your code without external dependencies.
