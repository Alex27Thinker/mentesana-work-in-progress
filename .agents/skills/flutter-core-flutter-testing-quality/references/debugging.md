# Debugging Flutter Applications

Debugging is an essential skill for Flutter developers. Flutter provides comprehensive debugging tools including DevTools, breakpoint debugging, logging, layout inspection, and performance profiling. Effective debugging helps you identify and fix issues quickly, understand app behavior, and optimize performance.

## Table of Contents

- [Flutter DevTools](#flutter-devtools)
- [Print Debugging](#print-debugging)
- [Breakpoint Debugging](#breakpoint-debugging)
- [Widget Inspector](#widget-inspector)
- [Layout Debugging](#layout-debugging)
- [Performance Profiling](#performance-profiling)
- [Memory Profiling](#memory-profiling)
- [Network Debugging](#network-debugging)
- [Logging Best Practices](#logging-best-practices)
- [Platform-Specific Debugging](#platform-specific-debugging)
- [Common Issues and Solutions](#common-issues-and-solutions)

## Flutter DevTools

DevTools is Flutter's official suite of debugging and performance tools accessible through a web interface.

### Launching DevTools

```bash
# Start your app in debug mode
flutter run

# DevTools URL will be shown in console
# Open in browser or use command:
flutter pub global activate devtools
flutter pub global run devtools
```

### From VS Code

1. Run app in debug mode (F5)
2. Click "Dart DevTools" in debug toolbar
3. Or use Command Palette: "Dart: Open DevTools"

### From Android Studio

1. Run app in debug mode
2. Click "Open DevTools" button in toolbar
3. Or use menu: Run → Open DevTools

### DevTools Features

- **Inspector**: Visual widget tree and layout exploration
- **Timeline**: Performance profiling and frame analysis
- **Memory**: Memory usage tracking and leak detection
- **Network**: HTTP request monitoring
- **Logging**: Application logs and print statements
- **Debugger**: Breakpoints and variable inspection
- **App Size**: Analyze app size and dependencies

## Print Debugging

The simplest debugging approach using print statements.

### Basic Printing

```dart
// Basic print
print('User logged in: $userId');

// debugPrint - better for large outputs
debugPrint('Large data structure: $largeObject');

// Only in debug mode
if (kDebugMode) {
  print('Debug information');
}
```

### Structured Logging

```dart
import 'dart:developer' as developer;

class UserService {
  Future<User> fetchUser(String id) async {
    developer.log(
      'Fetching user',
      name: 'UserService',
      error: 'Additional context',
      level: 800, // Custom log level
    );

    try {
      final user = await api.getUser(id);

      developer.log(
        'User fetched successfully',
        name: 'UserService',
        parameters: {'userId': id, 'userName': user.name},
      );

      return user;
    } catch (e, stackTrace) {
      developer.log(
        'Failed to fetch user',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // Error level
      );
      rethrow;
    }
  }
}
```

### Custom Debug Print

```dart
void debugLog(String message, {String tag = 'APP'}) {
  if (kDebugMode) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] [$tag] $message');
  }
}

// Usage
debugLog('User logged in', tag: 'AUTH');
debugLog('API call completed', tag: 'NETWORK');
```

### Conditional Printing

```dart
const bool _enableLogging = true;

void log(String message) {
  if (kDebugMode && _enableLogging) {
    print(message);
  }
}
```

## Breakpoint Debugging

Set breakpoints to pause execution and inspect state.

### Setting Breakpoints in VS Code

1. Click in the gutter left of line numbers
2. Red dot appears indicating breakpoint
3. Run in debug mode (F5)
4. Execution pauses at breakpoint

### Breakpoint Actions

```dart
class ShoppingCart {
  List<Product> _items = [];

  void addItem(Product product) {
    // Set breakpoint here
    _items.add(product);

    // Inspect variables:
    // - product
    // - _items
    // - this

    calculateTotal(); // Step into this method
  }

  double calculateTotal() {
    // Step through calculation
    double total = 0;
    for (var item in _items) {
      total += item.price; // Inspect each item
    }
    return total;
  }
}
```

### Debug Actions

- **Continue (F5)**: Resume execution
- **Step Over (F10)**: Execute current line, stay at current level
- **Step Into (F11)**: Go into function call
- **Step Out (Shift+F11)**: Complete current function
- **Restart (Ctrl+Shift+F5)**: Restart debugging session
- **Stop (Shift+F5)**: Stop debugging

### Conditional Breakpoints

Right-click breakpoint → Edit Breakpoint → Add condition:

```dart
// Only break when user is null
user == null

// Only break on specific iteration
i == 50

// Break when error occurs
error != null
```

### Logpoints

Print without modifying code:

Right-click in gutter → Add Logpoint

```dart
// Logpoint expression:
User {user.id}: {user.name}
```

## Widget Inspector

Visual tool for exploring widget trees and layouts.

### Opening Widget Inspector

1. Launch DevTools
2. Click "Flutter Inspector" tab
3. Or use VS Code: "Dart: Open Flutter Widget Inspector"

### Inspector Features

**Widget Tree**
- Hierarchical view of all widgets
- Click widget to select in tree
- Shows widget properties and constraints

**Layout Explorer**
- Visualize flex layouts (Row, Column)
- See flex factors and alignment
- Identify overflow issues

**Details Tree**
- Detailed widget properties
- Constructor parameters
- Render object information

### Select Widget Mode

```dart
// Click "Select Widget Mode" in DevTools
// Then click any widget in your running app
// Inspector shows that widget's details
```

### Debug Paint

Enable visual debugging overlays:

```dart
import 'package:flutter/rendering.dart';

void main() {
  // Show layout bounds
  debugPaintSizeEnabled = true;

  // Show baseline positions
  debugPaintBaselinesEnabled = true;

  // Show pointer hit test
  debugPaintPointersEnabled = true;

  // Show repaint rainbow
  debugRepaintRainbowEnabled = true;

  // Show layer boundaries
  debugPaintLayerBordersEnabled = true;

  runApp(MyApp());
}
```

### Widget Inspector Overlay

Enable in DevTools or programmatically:

```dart
import 'package:flutter/rendering.dart';

// Show widget overlay in app
WidgetsApp.debugShowWidgetInspectorOverride = true;

// Show material grid
MaterialApp(
  debugShowMaterialGrid: true,
  // ...
)

// Show checked mode banner
MaterialApp(
  debugShowCheckedModeBanner: false, // Disable banner
  // ...
)
```

## Layout Debugging

Debug layout issues and constraints.

### Debug Print Statements

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Print layout constraints
        print('Max width: ${constraints.maxWidth}');
        print('Max height: ${constraints.maxHeight}');

        return Container(
          // Widget implementation
        );
      },
    );
  }
}
```

### Overflow Debugging

```dart
// Show overflow indicators
MaterialApp(
  debugShowMaterialGrid: true,
  // ...
)

// Or globally
void main() {
  debugPaintSizeEnabled = true;
  runApp(MyApp());
}
```

### Common Layout Issues

**RenderFlex Overflow**
```dart
// Problem: Row with too many children
Row(
  children: [
    Text('Very long text that overflows'),
    Icon(Icons.star),
  ],
)

// Solution: Use Expanded or Flexible
Row(
  children: [
    Expanded(
      child: Text('Very long text that overflows'),
    ),
    Icon(Icons.star),
  ],
)
```

**Unbounded Height/Width**
```dart
// Problem: ListView in Column
Column(
  children: [
    ListView(children: [...]), // Unbounded height
  ],
)

// Solution: Wrap in Expanded
Column(
  children: [
    Expanded(
      child: ListView(children: [...]),
    ),
  ],
)
```

### Constraint Debugging

```dart
// Print constraints in build
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      debugPrint('Constraints: $constraints');

      if (constraints.maxWidth < 600) {
        return MobileLayout();
      } else {
        return DesktopLayout();
      }
    },
  );
}
```

## Performance Profiling

Identify and fix performance bottlenecks.

### Performance Overlay

Enable FPS overlay:

```dart
MaterialApp(
  showPerformanceOverlay: true,
  // ...
)
```

Or programmatically:

```bash
# Toggle performance overlay
flutter run --profile
# Press 'p' in terminal
```

### Timeline View

1. Open DevTools → Timeline tab
2. Click "Record"
3. Interact with app
4. Click "Stop"
5. Analyze timeline events

### Identifying Jank

**Good Performance**
- Green bars: 60 FPS (16ms per frame)
- Consistent frame times

**Jank Indicators**
- Red bars: Dropped frames
- Long build/layout/paint times
- Inconsistent frame durations

### Profiling Widget Builds

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DebugTimePainter(
        child: Text('Content'),
      ),
    );
  }
}

class DebugTimePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch()..start();

    // Painting logic

    stopwatch.stop();
    print('Paint time: ${stopwatch.elapsedMilliseconds}ms');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### Measuring Build Time

```dart
@override
Widget build(BuildContext context) {
  if (kDebugMode) {
    final stopwatch = Stopwatch()..start();
    final widget = _buildWidget(context);
    stopwatch.stop();
    print('Build time: ${stopwatch.elapsedMicroseconds}μs');
    return widget;
  }
  return _buildWidget(context);
}

Widget _buildWidget(BuildContext context) {
  // Actual widget building
  return Container();
}
```

### Profile Mode

Run in profile mode for accurate performance metrics:

```bash
# Profile mode (optimized, with debugging)
flutter run --profile

# Release mode (fully optimized, no debugging)
flutter run --release
```

## Memory Profiling

Track memory usage and detect leaks.

### Memory View in DevTools

1. Open DevTools → Memory tab
2. Click "Collect" to snapshot
3. Interact with app
4. Click "Collect" again
5. Compare memory usage

### Memory Leak Detection

**Common Causes**
- Unclosed streams
- Un-disposed controllers
- Retained listeners
- Circular references

**Example: Proper Disposal**
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _subscription = someStream.listen((data) {
      // Handle data
    });
  }

  @override
  void dispose() {
    // Always dispose resources
    _controller.dispose();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Memory Monitoring

```dart
import 'dart:developer' as developer;

void checkMemory() {
  developer.Timeline.startSync('memory_check');

  // Perform memory-intensive operation

  developer.Timeline.finishSync();
}
```

## Network Debugging

Monitor and debug network requests.

### Network View in DevTools

1. Open DevTools → Network tab
2. Make network requests in app
3. View request/response details
4. Inspect headers, body, timing

### Logging HTTP Requests

```dart
import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  final http.Client _inner;

  LoggingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('Request: ${request.method} ${request.url}');
    print('Headers: ${request.headers}');

    final response = await _inner.send(request);

    print('Response: ${response.statusCode}');
    print('Headers: ${response.headers}');

    return response;
  }
}

// Usage
final client = LoggingClient(http.Client());
final response = await client.get(Uri.parse('https://api.example.com/users'));
```

### Using Dio Interceptors

```dart
import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}

// Usage
final dio = Dio()..interceptors.add(LoggingInterceptor());
```

## Logging Best Practices

Structured logging for production debugging.

### Using Logger Package

```dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);

class UserService {
  Future<User> fetchUser(String id) async {
    logger.d('Fetching user: $id');

    try {
      final user = await api.getUser(id);
      logger.i('User fetched: ${user.name}');
      return user;
    } catch (e, stackTrace) {
      logger.e('Failed to fetch user', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
```

### Log Levels

```dart
logger.v('Verbose log'); // Verbose
logger.d('Debug log');   // Debug
logger.i('Info log');    // Info
logger.w('Warning log'); // Warning
logger.e('Error log');   // Error
logger.wtf('Fatal log'); // What a terrible failure
```

### Custom Logger

```dart
enum LogLevel { debug, info, warning, error }

class AppLogger {
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    final levelStr = level.name.toUpperCase();

    debugPrint('[$timestamp] [$levelStr] $tagStr $message');

    if (error != null) {
      debugPrint('Error: $error');
    }

    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}

// Usage
AppLogger.log('User logged in', tag: 'AUTH', level: LogLevel.info);
AppLogger.log('API error', tag: 'NETWORK', level: LogLevel.error, error: e);
```

## Platform-Specific Debugging

Debug platform-specific code.

### Android Debugging

```bash
# View Android logs
flutter logs

# Or use adb directly
adb logcat

# Filter by app
adb logcat | grep flutter
```

### iOS Debugging

```bash
# View iOS logs
flutter logs

# Use Xcode console
# Open Xcode → Window → Devices and Simulators
# Select device → View Device Logs
```

### Native Code Debugging

**Android (Java/Kotlin)**
```java
// In Android native code
Log.d("FlutterPlugin", "Native method called");
```

**iOS (Swift/Objective-C)**
```swift
// In iOS native code
NSLog("Flutter plugin method called")
```

## Common Issues and Solutions

### Issue: Widget Not Rebuilding

```dart
// Problem: setState not called in async callback
void fetchData() {
  api.getData().then((data) {
    _data = data; // State changed but no rebuild
  });
}

// Solution: Wrap in setState
void fetchData() {
  api.getData().then((data) {
    setState(() {
      _data = data;
    });
  });
}
```

### Issue: BuildContext Used After Widget Disposed

```dart
// Problem: Using context after navigation
void navigate() {
  api.doSomething().then((_) {
    Navigator.push(context, route); // Context might be invalid
  });
}

// Solution: Check mounted
void navigate() async {
  await api.doSomething();
  if (!mounted) return;
  Navigator.push(context, route);
}
```

### Issue: Infinite Build Loop

```dart
// Problem: setState in build
@override
Widget build(BuildContext context) {
  setState(() {}); // Causes infinite rebuild
  return Container();
}

// Solution: Move setState to appropriate lifecycle
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {});
  });
}
```

### Issue: Memory Leak from Stream

```dart
// Problem: Stream not disposed
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    someStream.listen((data) {
      // Handle data
    }); // Subscription never cancelled
  }
}

// Solution: Store and cancel subscription
class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

## Summary

Effective debugging techniques:

- **Use DevTools** for comprehensive debugging and profiling
- **Print debug information** with `debugPrint` and structured logging
- **Set breakpoints** to pause and inspect execution
- **Use Widget Inspector** to explore widget trees visually
- **Enable debug paint** to visualize layout constraints
- **Profile performance** in Timeline view
- **Track memory usage** to detect leaks
- **Monitor network requests** in Network view
- **Follow logging best practices** for production debugging
- **Debug platform-specific code** with native tools
- **Know common issues** and their solutions

Mastering these debugging techniques makes you a more efficient Flutter developer, able to quickly identify and resolve issues in your applications.
