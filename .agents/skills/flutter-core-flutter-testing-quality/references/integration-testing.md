# Integration Testing in Flutter

Integration tests (also called end-to-end or E2E tests) validate complete app flows on real devices or emulators. They test your entire application as users would experience it, including navigation, API integration, state persistence, and multi-screen workflows. Integration tests provide the highest confidence that your app works correctly in production but run slower than unit or widget tests.

## Table of Contents

- [Setting Up Integration Tests](#setting-up-integration-tests)
- [Your First Integration Test](#your-first-integration-test)
- [Testing Complete Flows](#testing-complete-flows)
- [Testing with Real APIs](#testing-with-real-apis)
- [Testing Navigation](#testing-navigation)
- [Testing Persistence](#testing-persistence)
- [Testing Platform Integration](#testing-platform-integration)
- [Performance Testing](#performance-testing)
- [Running on Multiple Devices](#running-on-multiple-devices)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)

## Setting Up Integration Tests

Integration tests use the `integration_test` package, which is maintained by the Flutter team.

### Add Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### Project Structure

Integration tests live in the `integration_test/` directory at the project root:

```
my_app/
├── lib/
│   └── main.dart
├── test/
│   └── widget_test.dart
├── integration_test/
│   ├── app_test.dart
│   ├── login_flow_test.dart
│   └── checkout_flow_test.dart
└── pubspec.yaml
```

### Update Main App for Testing

Create a test-friendly entry point or use compile-time flags:

```dart
// lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      home: const HomeScreen(),
    );
  }
}
```

### Running Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test

# Run specific test file
flutter test integration_test/app_test.dart

# Run on specific device
flutter test integration_test --device-id=<device-id>

# Run with driver (for more control)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

### Test Driver (Optional)

For advanced features like performance profiling, create a test driver:

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

## Your First Integration Test

Let's test a simple counter app end-to-end.

### App Code: `lib/main.dart`

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter App',
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('increment-button'),
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Test Code: `integration_test/app_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:my_app/main.dart' as app;

void main() {
  // Initialize integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Counter App Integration Test', () {
    testWidgets('increments counter when FAB is tapped', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('0'), findsOneWidget);

      // Tap the floating action button
      await tester.tap(find.byKey(const Key('increment-button')));
      await tester.pumpAndSettle();

      // Verify counter incremented
      expect(find.text('1'), findsOneWidget);

      // Tap multiple times
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('increment-button')));
        await tester.pumpAndSettle();
      }

      // Verify final count
      expect(find.text('5'), findsOneWidget);
    });
  });
}
```

## Testing Complete Flows

Integration tests shine when testing multi-step user journeys.

### Login Flow Test

```dart
// integration_test/login_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow', () {
    testWidgets('complete login flow with valid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.text('Login'), findsOneWidget);

      // Enter email
      await tester.enterText(
        find.byKey(const Key('email-field')),
        'user@example.com',
      );

      // Enter password
      await tester.enterText(
        find.byKey(const Key('password-field')),
        'password123',
      );

      // Tap login button
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();

      // Verify navigation to home screen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome, user@example.com'), findsOneWidget);
    });

    testWidgets('shows error for invalid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(
        find.byKey(const Key('email-field')),
        'invalid@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password-field')),
        'wrongpassword',
      );

      // Tap login button
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('logout flow returns to login screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(
        find.byKey(const Key('email-field')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password-field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('login-button')));
      await tester.pumpAndSettle();

      // Open menu
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify back on login screen
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });
  });
}
```

### Shopping Cart Flow Test

```dart
// integration_test/checkout_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping Cart Flow', () {
    testWidgets('complete checkout flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to products
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      // Add first product to cart
      await tester.tap(find.byKey(const Key('add-to-cart-0')));
      await tester.pumpAndSettle();

      // Verify cart badge updates
      expect(find.text('1'), findsOneWidget);

      // Add second product to cart
      await tester.tap(find.byKey(const Key('add-to-cart-1')));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);

      // Navigate to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // Verify cart contents
      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);

      // Proceed to checkout
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();

      // Fill shipping information
      await tester.enterText(
        find.byKey(const Key('address-field')),
        '123 Main St',
      );
      await tester.enterText(
        find.byKey(const Key('city-field')),
        'New York',
      );
      await tester.enterText(
        find.byKey(const Key('zip-field')),
        '10001',
      );

      // Continue to payment
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Enter payment information
      await tester.enterText(
        find.byKey(const Key('card-number-field')),
        '4111111111111111',
      );
      await tester.enterText(
        find.byKey(const Key('expiry-field')),
        '12/25',
      );
      await tester.enterText(
        find.byKey(const Key('cvv-field')),
        '123',
      );

      // Complete purchase
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      // Verify success screen
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.textContaining('Order #'), findsOneWidget);
    });

    testWidgets('removes item from cart', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Add item to cart
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-to-cart-0')));
      await tester.pumpAndSettle();

      // Navigate to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // Remove item
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Verify cart is empty
      expect(find.text('Your cart is empty'), findsOneWidget);
    });
  });
}
```

## Testing with Real APIs

Integration tests can use real API endpoints or mock servers.

### Testing with Mock Server

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import 'package:my_app/main.dart' as app;

class MockClient extends Mock implements http.Client {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('API Integration', () {
    testWidgets('fetches and displays user data', (tester) async {
      // Start app with mock HTTP client
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Wait for API call to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify data is displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('handles API errors gracefully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to screen that makes API call
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      // Simulate network error by waiting and checking error state
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Verify error message
      expect(
        find.text('Failed to load products'),
        findsOneWidget,
      );
    });
  });
}
```

### Testing with Real API (Staging Environment)

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real API Integration', () {
    testWidgets('fetches real data from staging API', (tester) async {
      // Configure app to use staging API
      const String apiUrl = 'https://staging-api.example.com';

      app.main();
      await tester.pumpAndSettle();

      // Test with real API calls
      await tester.tap(find.text('Load Data'));
      await tester.pumpAndSettle();

      // Wait for network request (use reasonable timeout)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify real data is displayed
      expect(find.byType(ListView), findsOneWidget);
    });
  }, timeout: const Timeout(Duration(minutes: 2)));
}
```

## Testing Navigation

Test complex navigation flows with multiple screens.

### Multi-Screen Navigation

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Flow', () {
    testWidgets('navigates through app screens', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Start on home screen
      expect(find.text('Home'), findsOneWidget);

      // Navigate to products
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.text('Products'), findsOneWidget);

      // Navigate to product detail
      await tester.tap(find.text('Product 1'));
      await tester.pumpAndSettle();
      expect(find.text('Product Details'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Products'), findsOneWidget);

      // Navigate to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();
      expect(find.text('Shopping Cart'), findsOneWidget);

      // Navigate to home using bottom nav
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('deep linking navigation', (tester) async {
      // Test deep link to specific product
      app.main();
      await tester.pumpAndSettle();

      // Simulate deep link
      // This depends on your routing implementation
      await tester.tap(find.text('Open Product 5'));
      await tester.pumpAndSettle();

      // Verify navigated to correct product
      expect(find.text('Product 5'), findsOneWidget);
    });
  });
}
```

### Bottom Navigation

```dart
testWidgets('bottom navigation preserves state', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Navigate to tab 2
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // Perform action in tab 2
  await tester.enterText(find.byType(TextField), 'search query');
  await tester.pumpAndSettle();

  // Switch to tab 3
  await tester.tap(find.byIcon(Icons.settings));
  await tester.pumpAndSettle();

  // Switch back to tab 2
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();

  // Verify state was preserved
  expect(find.text('search query'), findsOneWidget);
});
```

## Testing Persistence

Test that data persists across app restarts.

### SharedPreferences Testing

```dart
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Persistence', () {
    testWidgets('saves and loads user preferences', (tester) async {
      // Clear preferences before test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Enable dark mode
      await tester.tap(find.byKey(const Key('dark-mode-switch')));
      await tester.pumpAndSettle();

      // Restart app
      await tester.restartAndRestore();
      await tester.pumpAndSettle();

      // Navigate back to settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Verify dark mode is still enabled
      final switchWidget = tester.widget<Switch>(
        find.byKey(const Key('dark-mode-switch')),
      );
      expect(switchWidget.value, true);
    });
  });
}
```

### Database Testing

```dart
testWidgets('persists data in local database', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Add item
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('item-name')), 'Test Item');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify item appears
  expect(find.text('Test Item'), findsOneWidget);

  // Restart app
  await tester.restartAndRestore();
  await tester.pumpAndSettle();

  // Verify item persisted
  expect(find.text('Test Item'), findsOneWidget);
});
```

## Testing Platform Integration

Test platform-specific features and native integrations.

### Testing Camera Integration

```dart
testWidgets('captures photo from camera', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Navigate to camera screen
  await tester.tap(find.text('Take Photo'));
  await tester.pumpAndSettle();

  // On real device, this would open camera
  // In test, we can verify the intent was triggered
  expect(find.byType(CameraScreen), findsOneWidget);

  // Simulate photo capture
  await tester.tap(find.byIcon(Icons.camera));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Verify photo is displayed
  expect(find.byType(Image), findsOneWidget);
});
```

### Testing Location Services

```dart
testWidgets('uses device location', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Request location
  await tester.tap(find.text('Get Current Location'));
  await tester.pumpAndSettle();

  // Wait for location to be fetched
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();

  // Verify location is displayed
  expect(find.textContaining('Lat:'), findsOneWidget);
  expect(find.textContaining('Lng:'), findsOneWidget);
});
```

## Performance Testing

Measure app performance during integration tests.

### Tracking Timeline

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Tests', () {
    testWidgets('scrolling performance', (tester) async {
      await binding.traceAction(() async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to list
        await tester.tap(find.text('Items'));
        await tester.pumpAndSettle();

        // Scroll through list
        final listFinder = find.byType(Scrollable);
        await tester.fling(listFinder, const Offset(0, -500), 5000);
        await tester.pumpAndSettle();
      }, reportKey: 'scrolling_timeline');
    });

    testWidgets('app startup performance', (tester) async {
      await binding.traceAction(() async {
        app.main();
        await tester.pumpAndSettle();
      }, reportKey: 'startup_timeline');
    });
  });
}
```

### Frame Timing

```dart
testWidgets('measures frame build time', (tester) async {
  await binding.watchPerformance(() async {
    app.main();
    await tester.pumpAndSettle();

    // Perform actions
    for (int i = 0; i < 10; i++) {
      await tester.tap(find.byKey(Key('button-$i')));
      await tester.pumpAndSettle();
    }
  }, reportKey: 'frame_timing');
});
```

## Running on Multiple Devices

Test across different devices and screen sizes.

### Device-Specific Tests

```bash
# Run on specific device
flutter test integration_test --device-id=emulator-5554

# Run on all connected devices
flutter test integration_test --device-id=all

# Run on specific platform
flutter test integration_test --device-id=ios
flutter test integration_test --device-id=android
```

### Responsive Layout Testing

```dart
testWidgets('adapts to different screen sizes', (tester) async {
  // Test on phone size
  tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
  tester.binding.window.devicePixelRatioTestValue = 3.0;

  app.main();
  await tester.pumpAndSettle();

  expect(find.byType(BottomNavigationBar), findsOneWidget);
  expect(find.byType(NavigationDrawer), findsNothing);

  // Test on tablet size
  tester.binding.window.physicalSizeTestValue = const Size(2048, 2732);
  tester.binding.window.devicePixelRatioTestValue = 2.0;

  await tester.pumpAndSettle();

  expect(find.byType(NavigationDrawer), findsOneWidget);
  expect(find.byType(BottomNavigationBar), findsNothing);

  // Reset
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
});
```

## CI/CD Integration

Automate integration tests in continuous integration pipelines.

### GitHub Actions Example

```yaml
# .github/workflows/integration_tests.yml
name: Integration Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  integration_test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Start iOS Simulator
        run: |
          xcrun simctl boot "iPhone 14" || true
          xcrun simctl list devices

      - name: Run integration tests
        run: flutter test integration_test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

### Running Tests in Parallel

```bash
# Split tests across multiple devices
flutter test integration_test/test1.dart --device-id=device1 &
flutter test integration_test/test2.dart --device-id=device2 &
flutter test integration_test/test3.dart --device-id=device3 &
wait
```

## Best Practices

### 1. Keep Tests Independent

Each test should set up its own state and clean up:

```dart
testWidgets('test', (tester) async {
  // Clear app state
  await clearAppData();

  app.main();
  await tester.pumpAndSettle();

  // Test logic
});
```

### 2. Use Realistic Test Data

Use data that resembles production:

```dart
final testUser = User(
  id: 'test-user-123',
  name: 'Test User',
  email: 'test@example.com',
);
```

### 3. Add Generous Timeouts

Network calls and animations take time:

```dart
testWidgets('test', (tester) async {
  // ...
  await tester.pumpAndSettle(const Duration(seconds: 5));
}, timeout: const Timeout(Duration(minutes: 2)));
```

### 4. Test Critical Paths First

Focus on essential user journeys:

- User registration and login
- Core feature workflows
- Payment and checkout
- Data synchronization

### 5. Use Screenshots for Debugging

Capture screenshots when tests fail:

```dart
testWidgets('test', (tester) async {
  try {
    // Test logic
  } catch (e) {
    await binding.takeScreenshot('test-failure');
    rethrow;
  }
});
```

### 6. Mock External Services

Use mock servers for consistent results:

```dart
// Start mock server before tests
setUpAll(() async {
  mockServer = await startMockServer();
});

tearDownAll(() async {
  await mockServer.close();
});
```

### 7. Test on Real Devices

Simulators are convenient, but test on physical devices periodically:

```bash
# Run on connected physical device
flutter devices
flutter test integration_test --device-id=<physical-device-id>
```

### 8. Monitor Performance

Track performance metrics over time:

```dart
testWidgets('monitors memory usage', (tester) async {
  await binding.traceAction(() async {
    // Heavy operations
  }, reportKey: 'memory_usage');
});
```

## Summary

Integration testing validates complete app functionality:

- **Use `integration_test` package** for end-to-end tests
- **Test complete user flows** across multiple screens
- **Run on real devices** for highest confidence
- **Test with real or mock APIs** depending on needs
- **Verify navigation flows** and state persistence
- **Measure performance** with timeline tracing
- **Automate in CI/CD** for continuous quality
- **Keep tests independent** and use realistic data
- **Add generous timeouts** for async operations
- **Focus on critical paths** first

Integration tests provide confidence that your app works correctly in production environments, catching issues that unit and widget tests cannot.
