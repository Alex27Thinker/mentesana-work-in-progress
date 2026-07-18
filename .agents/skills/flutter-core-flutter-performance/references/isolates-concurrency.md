# Isolates and Concurrency in Flutter

Isolates are Dart's approach to concurrency, providing true parallel execution without shared memory. This guide covers when to use isolates, implementation patterns, communication strategies, and best practices for keeping your UI responsive during heavy computation.

## Table of Contents

- [Understanding Isolates](#understanding-isolates)
- [When to Use Isolates](#when-to-use-isolates)
- [Short-Lived Isolates](#short-lived-isolates)
- [Long-Lived Isolates](#long-lived-isolates)
- [Communication Between Isolates](#communication-between-isolates)
- [Platform Plugins in Isolates](#platform-plugins-in-isolates)
- [Isolate Patterns and Recipes](#isolate-patterns-and-recipes)
- [Performance Considerations](#performance-considerations)
- [Testing Isolates](#testing-isolates)
- [Common Pitfalls](#common-pitfalls)

## Understanding Isolates

### What Are Isolates?

Isolates are Dart's concurrency model, similar to threads but with key differences:

```
Thread Model (Traditional):
- Shared memory
- Race conditions possible
- Requires locks/mutexes
- Complex synchronization

Isolate Model (Dart):
- Isolated memory
- No shared state
- Message passing only
- Simpler reasoning
```

### Isolate Characteristics

```dart
// Main isolate (UI thread)
void main() {
  runApp(MyApp());

  // Everything runs on main isolate by default
  // Including: build, setState, gestures, animations
}

// Spawned isolate (worker thread)
void workerIsolate(dynamic message) {
  // Completely separate memory
  // Cannot access main isolate variables
  // Communicates via messages
}
```

**Key Properties**:
1. **Isolated Memory**: Each isolate has its own heap
2. **No Shared State**: Cannot share variables directly
3. **Message Passing**: Communication via SendPort/ReceivePort
4. **True Parallelism**: Runs on separate CPU cores
5. **No Race Conditions**: No shared mutable state

### Memory Model

```dart
// Main isolate memory
class MainIsolate {
  static int counter = 0; // Main isolate only

  static void increment() {
    counter++; // Only affects main isolate
  }
}

// Spawned isolate
void workerIsolate(SendPort sendPort) {
  // This is a DIFFERENT memory space
  // MainIsolate.counter doesn't exist here
  // Must receive data via messages
}

// Spawn worker
await Isolate.spawn(workerIsolate, receivePort.sendPort);

// Worker cannot see MainIsolate.counter
// Must send counter value as message
```

### When NOT to Use Isolates

Isolates have overhead. Don't use for:

```dart
// ❌ Fast operations
List<int> numbers = [1, 2, 3, 4, 5];
int sum = numbers.reduce((a, b) => a + b); // Too fast for isolate

// ❌ Simple async operations
final response = await http.get(url); // Already non-blocking

// ❌ UI operations
setState(() {}); // Must run on main isolate

// ❌ Small datasets
List<int> sortSmall(List<int> items) {
  return items..sort(); // Overhead exceeds benefit
}
```

## When to Use Isolates

### The 16ms Rule

Use isolates when operations exceed one frame (16ms at 60fps):

```dart
// Measure operation time
final stopwatch = Stopwatch()..start();
performOperation();
stopwatch.stop();

if (stopwatch.elapsedMilliseconds > 16) {
  // Consider using isolate
}
```

### Common Use Cases

**1. JSON Parsing**

Large JSON payloads (>100KB):

```dart
// ✅ Use isolate for large JSON
Future<List<Photo>> parsePhotos(String jsonString) async {
  return await Isolate.run(() {
    final List<dynamic> data = jsonDecode(jsonString);
    return data.map((json) => Photo.fromJson(json)).toList();
  });
}
```

**2. Image Processing**

```dart
// ✅ Image manipulation
Future<Uint8List> applyFilter(Uint8List imageData, Filter filter) async {
  return await Isolate.run(() {
    return filter.apply(imageData);
  });
}
```

**3. Database Operations**

```dart
// ✅ Complex queries
Future<List<Record>> queryDatabase(String query) async {
  return await Isolate.run(() {
    final db = Database.open();
    return db.query(query);
  });
}
```

**4. Cryptography**

```dart
// ✅ Encryption/decryption
Future<String> encrypt(String data, String key) async {
  return await Isolate.run(() {
    return CryptoLib.encrypt(data, key);
  });
}
```

**5. File Operations**

```dart
// ✅ Large file processing
Future<List<String>> processLogFile(String path) async {
  return await Isolate.run(() {
    final file = File(path);
    final lines = file.readAsLinesSync();
    return lines.where((line) => line.contains('ERROR')).toList();
  });
}
```

**6. Complex Computations**

```dart
// ✅ Heavy calculations
Future<List<double>> calculateTrajectory(List<Point> points) async {
  return await Isolate.run(() {
    // Complex physics calculations
    return PhysicsEngine.simulate(points);
  });
}
```

## Short-Lived Isolates

### Isolate.run()

The simplest way to run code in an isolate:

```dart
import 'dart:isolate';

Future<int> computeSum(List<int> numbers) async {
  return await Isolate.run(() {
    return numbers.reduce((a, b) => a + b);
  });
}

// Usage
void main() async {
  final numbers = List.generate(1000000, (i) => i);
  final sum = await computeSum(numbers);
  print('Sum: $sum');
}
```

**How Isolate.run() Works**:

```dart
// Behind the scenes:
// 1. Spawns new isolate
// 2. Sends function and arguments
// 3. Executes function
// 4. Sends result back
// 5. Kills isolate
// 6. Returns result

// All in one call!
final result = await Isolate.run(heavyComputation);
```

### Passing Data to Isolate.run()

```dart
// Simple types (copied)
await Isolate.run(() => processNumber(42));

// Lists and Maps (copied)
await Isolate.run(() => processData({'key': 'value'}));

// Custom classes (must be serializable or use closures)
class Config {
  final int value;
  Config(this.value);
}

// Capture in closure
final config = Config(42);
await Isolate.run(() {
  return processWithConfig(config.value); // Access via closure
});
```

### Return Values

```dart
// Return simple types
Future<int> computeAge() async {
  return await Isolate.run(() => 2024 - 1990);
}

// Return lists
Future<List<String>> processStrings(List<String> input) async {
  return await Isolate.run(() {
    return input.map((s) => s.toUpperCase()).toList();
  });
}

// Return custom objects (must be sendable)
class Result {
  final String message;
  final int value;
  Result(this.message, this.value);
}

Future<Result> compute() async {
  return await Isolate.run(() {
    return Result('Done', 42);
  });
}
```

### Error Handling

```dart
Future<int> riskyComputation() async {
  try {
    return await Isolate.run(() {
      if (Random().nextBool()) {
        throw Exception('Random failure');
      }
      return 42;
    });
  } catch (e) {
    print('Isolate error: $e');
    return -1;
  }
}
```

## Long-Lived Isolates

### When to Use Long-Lived Isolates

Use long-lived isolates when:

1. **Repeated computations**: Same operation many times
2. **Maintaining state**: Isolate needs to keep data
3. **Continuous processing**: Background tasks
4. **Avoiding spawn overhead**: Isolate.run() spawn cost adds up

### Basic Long-Lived Isolate Pattern

```dart
import 'dart:isolate';

class WorkerIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();

  Future<void> start() async {
    // Spawn isolate
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort.sendPort,
    );

    // Get SendPort from isolate
    _sendPort = await _receivePort.first as SendPort;
  }

  // Entry point (runs in isolate)
  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();

    // Send our ReceivePort's SendPort back
    sendPort.send(receivePort.sendPort);

    // Listen for messages
    receivePort.listen((message) {
      // Process message
      final result = _processMessage(message);

      // Send result back
      sendPort.send(result);
    });
  }

  static dynamic _processMessage(dynamic message) {
    // Do work here
    return 'Processed: $message';
  }

  Future<dynamic> send(dynamic message) async {
    if (_sendPort == null) {
      throw StateError('Isolate not started');
    }

    // Send message
    _sendPort!.send(message);

    // Wait for response
    return await _receivePort.first;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort.close();
  }
}

// Usage
void main() async {
  final worker = WorkerIsolate();
  await worker.start();

  final result = await worker.send('Hello');
  print(result); // "Processed: Hello"

  worker.dispose();
}
```

### Request-Response Pattern

```dart
class RequestResponseIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  final Map<int, Completer> _pending = {};
  int _nextId = 0;

  Future<void> start() async {
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort.sendPort);
    _receivePort.listen(_handleResponse);
    _sendPort = await _receivePort.first as SendPort;
  }

  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      final Map<String, dynamic> msg = message;
      final id = msg['id'] as int;
      final data = msg['data'];

      // Process
      final result = heavyComputation(data);

      // Send response with ID
      sendPort.send({'id': id, 'result': result});
    });
  }

  void _handleResponse(dynamic message) {
    final Map<String, dynamic> msg = message;
    final id = msg['id'] as int;
    final result = msg['result'];

    _pending[id]?.complete(result);
    _pending.remove(id);
  }

  Future<dynamic> compute(dynamic data) async {
    final id = _nextId++;
    final completer = Completer();
    _pending[id] = completer;

    _sendPort!.send({'id': id, 'data': data});

    return await completer.future;
  }

  void dispose() {
    _isolate?.kill();
    _receivePort.close();
  }
}
```

### Stateful Worker Isolate

Maintain state across operations:

```dart
class StatefulWorker {
  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    // State maintained across messages
    int counter = 0;
    final Map<String, dynamic> cache = {};

    receivePort.listen((message) {
      final Map<String, dynamic> msg = message;
      final command = msg['command'] as String;

      switch (command) {
        case 'increment':
          counter++;
          sendPort.send(counter);
          break;

        case 'cache':
          final key = msg['key'] as String;
          final value = msg['value'];
          cache[key] = value;
          sendPort.send('cached');
          break;

        case 'retrieve':
          final key = msg['key'] as String;
          sendPort.send(cache[key]);
          break;
      }
    });
  }
}
```

## Communication Between Isolates

### SendPort and ReceivePort

```dart
// ReceivePort: Receives messages (like Stream)
final receivePort = ReceivePort();

// SendPort: Sends messages
final sendPort = receivePort.sendPort;

// Listen for messages
receivePort.listen((message) {
  print('Received: $message');
});

// Send message
sendPort.send('Hello');
```

### Message Types

**Primitive types** (copied efficiently):

```dart
sendPort.send(42);
sendPort.send('string');
sendPort.send(3.14);
sendPort.send(true);
```

**Collections** (copied):

```dart
sendPort.send([1, 2, 3]);
sendPort.send({'key': 'value'});
sendPort.send({1, 2, 3});
```

**Custom objects** (must be sendable):

```dart
class Message {
  final String text;
  final int value;
  Message(this.text, this.value);
}

// Works if all fields are sendable
sendPort.send(Message('hello', 42));
```

**Efficient transfer** with Isolate.exit():

```dart
// Instead of copying, transfer ownership
void isolateEntry(SendPort sendPort) {
  final largeList = List.generate(1000000, (i) => i);

  // Transfer ownership (zero-copy)
  Isolate.exit(sendPort, largeList);
}
```

### Bidirectional Communication

```dart
class BidirectionalIsolate {
  static void _isolateEntry(SendPort mainSendPort) {
    final isolateReceivePort = ReceivePort();

    // Send our SendPort to main
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((message) {
      // Echo back
      mainSendPort.send('Echo: $message');
    });
  }

  Future<void> start() async {
    final mainReceivePort = ReceivePort();

    await Isolate.spawn(_isolateEntry, mainReceivePort.sendPort);

    // Get isolate's SendPort
    final isolateSendPort = await mainReceivePort.first as SendPort;

    // Now we can send messages both ways
    isolateSendPort.send('Hello');

    mainReceivePort.listen((message) {
      print('From isolate: $message');
    });
  }
}
```

## Platform Plugins in Isolates

### BackgroundIsolateBinaryMessenger

Access platform plugins from background isolates (Flutter 3.7+):

```dart
import 'package:flutter/services.dart';
import 'dart:isolate';
import 'dart:ui';

void backgroundIsolateEntry(RootIsolateToken token) async {
  // Initialize messenger
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  // Now can use platform plugins
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString('key');

  print('Value from background: $value');
}

// Main isolate
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = RootIsolateToken.instance!;

  await Isolate.spawn(backgroundIsolateEntry, token);

  runApp(MyApp());
}
```

### Supported Plugins

Most plugins work with BackgroundIsolateBinaryMessenger:

```dart
void backgroundWork(RootIsolateToken token) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  // ✅ SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // ✅ Path Provider
  final dir = await getApplicationDocumentsDirectory();

  // ✅ SQLite
  final db = await openDatabase('my.db');

  // ❌ Cannot use UI-related plugins
  // ❌ Cannot use dart:ui methods
}
```

### Limitations

```dart
void backgroundIsolate(RootIsolateToken token) {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  // ❌ Cannot access rootBundle
  // await rootBundle.loadString('asset.txt');

  // ❌ Cannot use dart:ui
  // final codec = await ui.instantiateImageCodec(bytes);

  // ❌ Cannot receive unsolicited platform messages
  // Only request-response is supported

  // ✅ CAN query platform channels
  final result = await platform.invokeMethod('myMethod');
}
```

## Isolate Patterns and Recipes

### Pattern 1: Worker Pool

Multiple workers for parallel processing:

```dart
class WorkerPool {
  final List<WorkerIsolate> _workers = [];
  int _nextWorker = 0;

  Future<void> init(int workerCount) async {
    for (int i = 0; i < workerCount; i++) {
      final worker = WorkerIsolate();
      await worker.start();
      _workers.add(worker);
    }
  }

  Future<dynamic> execute(dynamic task) async {
    final worker = _workers[_nextWorker];
    _nextWorker = (_nextWorker + 1) % _workers.length;
    return await worker.send(task);
  }

  void dispose() {
    for (var worker in _workers) {
      worker.dispose();
    }
  }
}

// Usage
final pool = WorkerPool();
await pool.init(4); // 4 workers

final results = await Future.wait([
  pool.execute(task1),
  pool.execute(task2),
  pool.execute(task3),
  pool.execute(task4),
]);
```

### Pattern 2: Stream Processing

Process stream data in isolate:

```dart
class StreamProcessor {
  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is List) {
        // Process batch
        final processed = message.map((item) => process(item)).toList();
        sendPort.send(processed);
      }
    });
  }

  final StreamController _controller = StreamController();
  SendPort? _sendPort;

  Stream get stream => _controller.stream;

  Future<void> start() async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_isolateEntry, receivePort.sendPort);

    receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else {
        _controller.add(message);
      }
    });

    _sendPort = await receivePort.first as SendPort;
  }

  void add(List data) {
    _sendPort?.send(data);
  }
}
```

### Pattern 3: Compute Function

Simplified helper for one-off computations:

```dart
Future<R> compute<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message,
) async {
  return await Isolate.run(() => callback(message));
}

// Usage
final result = await compute(
  (message) => expensiveComputation(message),
  inputData,
);

// Or define callback separately
int sumList(List<int> numbers) {
  return numbers.reduce((a, b) => a + b);
}

final sum = await compute(sumList, [1, 2, 3, 4, 5]);
```

### Pattern 4: Progress Reporting

Report progress from isolate:

```dart
class ProgressIsolate {
  static void _isolateEntry(SendPort sendPort) {
    final total = 100;

    for (int i = 0; i <= total; i++) {
      // Do work
      heavyWork();

      // Report progress
      sendPort.send({'progress': i / total});
    }

    // Send final result
    sendPort.send({'done': true, 'result': 'Complete'});
  }

  final ReceivePort _receivePort = ReceivePort();
  final StreamController<double> _progressController = StreamController();

  Stream<double> get progress => _progressController.stream;

  Future<dynamic> start() async {
    final completer = Completer();

    _receivePort.listen((message) {
      if (message is Map) {
        if (message.containsKey('progress')) {
          _progressController.add(message['progress']);
        } else if (message['done'] == true) {
          _progressController.close();
          completer.complete(message['result']);
        }
      }
    });

    await Isolate.spawn(_isolateEntry, _receivePort.sendPort);

    return await completer.future;
  }
}

// Usage
final isolate = ProgressIsolate();

isolate.progress.listen((progress) {
  print('Progress: ${(progress * 100).toInt()}%');
});

final result = await isolate.start();
```

### Pattern 5: Cancellable Isolate

```dart
class CancellableIsolate {
  Isolate? _isolate;
  bool _cancelled = false;

  Future<dynamic> run(Function computation) async {
    final receivePort = ReceivePort();

    _isolate = await Isolate.spawn((sendPort) {
      final result = computation();
      sendPort.send(result);
    }, receivePort.sendPort);

    final result = await receivePort.first;

    if (_cancelled) {
      throw Exception('Operation cancelled');
    }

    return result;
  }

  void cancel() {
    _cancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
  }
}

// Usage
final isolate = CancellableIsolate();

final future = isolate.run(() => longComputation());

// Cancel after 5 seconds
Future.delayed(Duration(seconds: 5), () {
  isolate.cancel();
});

try {
  final result = await future;
} catch (e) {
  print('Cancelled: $e');
}
```

## Performance Considerations

### Isolate Spawn Overhead

```dart
// Spawning isolate has cost (~10-30ms)
// Avoid spawning for quick operations

final stopwatch = Stopwatch()..start();

await Isolate.spawn(quickFunction, data);

stopwatch.stop();
print('Spawn overhead: ${stopwatch.elapsedMilliseconds}ms');
// Typical: 15-25ms
```

**Guidelines**:
- **Operation < 50ms**: Don't use isolate
- **Operation > 100ms**: Use isolate
- **50-100ms**: Profile to decide

### Message Passing Cost

```dart
// Large objects have copy cost
final largeList = List.generate(1000000, (i) => i);

final stopwatch = Stopwatch()..start();
sendPort.send(largeList); // Copies entire list
stopwatch.stop();

print('Copy time: ${stopwatch.elapsedMilliseconds}ms');
// Can be significant for large data
```

**Optimization**: Use Isolate.exit() for zero-copy transfer:

```dart
void isolateEntry(SendPort sendPort) {
  final largeData = generateLargeData();

  // Transfer ownership (no copy)
  Isolate.exit(sendPort, largeData);
}
```

### Memory Usage

Each isolate has its own heap:

```dart
// Main isolate: 50 MB
// Worker isolate 1: 30 MB
// Worker isolate 2: 30 MB
// Total: 110 MB

// Limit worker count to manage memory
```

### Best Performance Pattern

```dart
// ✅ Long-lived isolate for repeated work
final worker = WorkerIsolate();
await worker.start(); // Pay spawn cost once

for (var task in tasks) {
  await worker.compute(task); // No spawn overhead
}

worker.dispose();

// ❌ Spawning for each task
for (var task in tasks) {
  await Isolate.run(() => compute(task)); // Spawn cost every time
}
```

## Testing Isolates

### Unit Testing Isolate Functions

```dart
test('Isolate computation', () async {
  final result = await Isolate.run(() {
    return computeSum([1, 2, 3, 4, 5]);
  });

  expect(result, 15);
});
```

### Testing Long-Lived Isolates

```dart
test('Worker isolate', () async {
  final worker = WorkerIsolate();
  await worker.start();

  final result = await worker.send('test');

  expect(result, 'Processed: test');

  worker.dispose();
});
```

### Mock Isolates for Testing

```dart
abstract class IsolateService {
  Future<int> compute(int value);
}

class RealIsolateService implements IsolateService {
  @override
  Future<int> compute(int value) async {
    return await Isolate.run(() => heavyComputation(value));
  }
}

class MockIsolateService implements IsolateService {
  @override
  Future<int> compute(int value) async {
    // Skip isolate in tests
    return heavyComputation(value);
  }
}
```

## Common Pitfalls

### Pitfall 1: Accessing UI from Isolate

```dart
// ❌ WRONG
void isolateEntry(SendPort sendPort) {
  setState(() {}); // ERROR: No setState in isolate
  Navigator.push(...); // ERROR: No Navigator
}

// ✅ CORRECT
void isolateEntry(SendPort sendPort) {
  final result = compute();
  sendPort.send(result); // Send result to main isolate
}

// Main isolate updates UI
receivePort.listen((result) {
  setState(() {
    _result = result;
  });
});
```

### Pitfall 2: Forgetting to Close ReceivePorts

```dart
// ❌ Memory leak
final receivePort = ReceivePort();
await Isolate.spawn(worker, receivePort.sendPort);
// receivePort never closed

// ✅ Proper cleanup
final receivePort = ReceivePort();
try {
  await Isolate.spawn(worker, receivePort.sendPort);
  final result = await receivePort.first;
  return result;
} finally {
  receivePort.close();
}
```

### Pitfall 3: Sending Non-Sendable Objects

```dart
// ❌ WRONG
class MyClass {
  final Function callback; // Functions not sendable
  MyClass(this.callback);
}

sendPort.send(MyClass(() {})); // ERROR

// ✅ CORRECT
class MyMessage {
  final String data;
  MyMessage(this.data);
}

sendPort.send(MyMessage('hello')); // OK
```

### Pitfall 4: Expecting Shared State

```dart
// ❌ WRONG
int globalCounter = 0;

void isolateEntry(SendPort sendPort) {
  globalCounter++; // Doesn't affect main isolate
  sendPort.send(globalCounter);
}

// Main isolate:
print(globalCounter); // Still 0!

// ✅ CORRECT
void isolateEntry(SendPort sendPort) {
  int localCounter = 0;
  localCounter++;
  sendPort.send(localCounter); // Send value back
}
```

### Pitfall 5: Web Compatibility

```dart
// ❌ Doesn't work on web
import 'dart:isolate';

void webCode() {
  Isolate.spawn(...); // Not supported on web
}

// ✅ Use compute() for web compatibility
import 'package:flutter/foundation.dart';

void webCode() {
  compute(heavyFunction, data); // Works on mobile and web
}
```

### Best Practices Summary

1. **Use Isolate.run() for simple cases**: Easiest API
2. **Long-lived isolates for repeated work**: Avoid spawn overhead
3. **Profile before using isolates**: Ensure benefit exceeds cost
4. **Close ReceivePorts**: Prevent memory leaks
5. **Send minimal data**: Message passing has cost
6. **Use Isolate.exit()**: Zero-copy transfer for large data
7. **Handle errors**: Wrap in try-catch
8. **Test isolate code**: Unit test computation logic
9. **Consider web**: Use compute() for compatibility
10. **Monitor memory**: Each isolate uses separate heap

Isolates are powerful tools for maintaining UI responsiveness during heavy computation. Use them judiciously, understanding the trade-offs between spawn overhead, message passing costs, and the benefits of parallel execution. When used appropriately, isolates enable smooth, responsive Flutter applications even under heavy computational load.
