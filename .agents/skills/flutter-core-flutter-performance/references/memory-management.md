# Memory Management in Flutter

Effective memory management is crucial for Flutter app performance and stability. This guide covers memory leak detection, disposal patterns, profiling techniques, and best practices for keeping your app's memory footprint minimal.

## Table of Contents

- [Understanding Dart Memory Management](#understanding-dart-memory-management)
- [Memory Leaks vs Memory Bloat](#memory-leaks-vs-memory-bloat)
- [Common Memory Leak Patterns](#common-memory-leak-patterns)
- [Disposal Patterns](#disposal-patterns)
- [DevTools Memory View](#devtools-memory-view)
- [Memory Profiling Techniques](#memory-profiling-techniques)
- [BuildContext Memory Issues](#buildcontext-memory-issues)
- [Image and Asset Memory](#image-and-asset-memory)
- [Stream and Listener Management](#stream-and-listener-management)
- [Best Practices](#best-practices)

## Understanding Dart Memory Management

### The Dart Heap

Dart uses automatic memory management with garbage collection:

```
Heap Memory:
  - All Dart objects live on the heap
  - Created via constructors: MyClass()
  - Automatically deallocated when unreachable
  - Garbage collector runs periodically
```

### Garbage Collection

The Dart VM uses generational garbage collection:

```dart
// Object lifecycle
var myObject = MyClass(); // Allocated on heap

// Object is reachable while references exist
useObject(myObject);

// Becomes unreachable when no references remain
myObject = null;

// Garbage collector eventually deallocates memory
```

### Reachability and Retaining Paths

Objects stay in memory as long as they're reachable from the root:

```dart
class Child {
  final String name;
  Child(this.name);
}

class Parent {
  Child? child;
}

// Root holds reference
Parent rootParent = Parent();

void example() {
  // Create child
  Child child = Child('Alice');

  // One retaining path: root → example() → child
  print(child.name);

  // Create another parent
  Parent localParent = Parent()..child = child;

  // Two retaining paths now:
  // 1. root → example() → child
  // 2. root → example() → localParent → child

  rootParent.child = child;

  // Three retaining paths:
  // 1. root → example() → child
  // 2. root → example() → localParent → child
  // 3. root → rootParent → child

  // Function exits, local references cleared
}

// child still reachable via rootParent.child
// Won't be garbage collected

// Clear reference
rootParent.child = null;
// Now child is unreachable and will be collected
```

### Shallow Size vs Retained Size

**Shallow Size**: Memory occupied by the object itself

**Retained Size**: Memory that would be freed if the object were collected

```dart
class SmallChild {
  final int value = 42; // 8 bytes
  // Shallow size: ~16 bytes (object header + value)
}

class Parent {
  final LargeObject data = LargeObject(); // 1MB
  final SmallChild child = SmallChild();

  // Shallow size: ~24 bytes (object + references)
  // Retained size: ~1MB + 24 bytes (includes data and child)
}
```

Understanding retained size helps identify memory leak impact.

## Memory Leaks vs Memory Bloat

### Memory Leaks

**Definition**: Objects that should be deallocated but remain in memory due to unintended references.

**Characteristics**:
- Progressive memory growth over time
- Objects no longer needed but still referenced
- Eventually causes out-of-memory crashes

```dart
// Memory leak example
class LeakyService {
  static final List<StreamController> _controllers = [];

  StreamController createController() {
    final controller = StreamController();
    _controllers.add(controller); // LEAK - never removed
    return controller;
  }
}

// Every call to createController() leaks memory
// _controllers list grows indefinitely
```

### Memory Bloat

**Definition**: Excessive memory usage from overly large resources or inefficient data structures.

**Characteristics**:
- High memory usage from the start
- Objects are needed but unnecessarily large
- Causes slowdowns and crashes

```dart
// Memory bloat example
class BloatedImageCache {
  final Map<String, Image> _cache = {};

  Future<Image> loadImage(String url) async {
    if (!_cache.containsKey(url)) {
      // Loads full-resolution 10MB image
      _cache[url] = await loadFullResImage(url);
    }
    return _cache[url]!;
  }

  // Better: Use appropriate resolution
  Future<Image> loadImageOptimized(String url, int targetWidth) async {
    final key = '$url-$targetWidth';
    if (!_cache.containsKey(key)) {
      // Loads only what's needed (maybe 500KB)
      _cache[key] = await loadResizedImage(url, targetWidth);
    }
    return _cache[key]!;
  }
}
```

### Identifying Leak vs Bloat

| Symptom | Memory Leak | Memory Bloat |
|---------|------------|--------------|
| Memory growth | Progressive | Immediate |
| Pattern | Increases with usage | Constant high usage |
| Solution | Fix disposal/references | Optimize resources |

## Common Memory Leak Patterns

### Pattern 1: Closures Retaining Large Objects

Closures capture their surrounding scope, potentially retaining large objects:

```dart
// BAD - Closure retains entire MyLargeObject
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final MyLargeObject largeObject = MyLargeObject(); // 10MB

  void setupHandler() {
    final handler = () {
      // Only needs largeObject.name (small string)
      print(largeObject.name);
    };

    // handler retains entire largeObject (10MB)
    globalHandlerRegistry.register(handler);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// GOOD - Extract only what's needed
class _MyWidgetState extends State<MyWidget> {
  final MyLargeObject largeObject = MyLargeObject();

  void setupHandler() {
    final name = largeObject.name; // Extract string
    final handler = () {
      // handler only retains name (tiny)
      print(name);
    };

    globalHandlerRegistry.register(handler);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Pattern 2: BuildContext in Closures

BuildContext retains the entire widget tree:

```dart
// BAD - BuildContext in closure
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Closure captures context
    final handler = () {
      final theme = Theme.of(context); // Retains entire widget tree
      applyTheme(theme);
    };

    someAsyncOperation(handler);
    return Container();
  }
}

// GOOD - Extract data before closure
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Extract theme
    final handler = () {
      applyTheme(theme); // Only retains ThemeData
    };

    someAsyncOperation(handler);
    return Container();
  }
}
```

### Pattern 3: Listeners Not Removed

```dart
// BAD - Listener never removed
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();

    // Adds listener but never removes
    MyGlobalNotifier.instance.addListener(_onNotify);
  }

  void _onNotify() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  // Widget disposed but listener remains
  // Listener retains entire State object
}

// GOOD - Remove listener in dispose
class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    MyGlobalNotifier.instance.addListener(_onNotify);
  }

  void _onNotify() {
    setState(() {});
  }

  @override
  void dispose() {
    MyGlobalNotifier.instance.removeListener(_onNotify); // Clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Pattern 4: Static/Global References

```dart
// BAD - Static reference prevents collection
class CacheManager {
  static Widget? cachedWidget; // Prevents widget from being collected

  static void cacheForLater(Widget widget) {
    cachedWidget = widget; // Widget stays in memory forever
  }
}

// GOOD - Use WeakReference or clear explicitly
class CacheManager {
  static final Map<String, WeakReference<Widget>> _cache = {};

  static void cache(String key, Widget widget) {
    _cache[key] = WeakReference(widget);
    // Widget can be collected when no longer needed
  }

  static Widget? get(String key) {
    return _cache[key]?.target; // May return null if collected
  }
}
```

### Pattern 5: Timer/Periodic Callbacks

```dart
// BAD - Timer never cancelled
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();

    // Timer retains State object indefinitely
    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// GOOD - Cancel timer in dispose
class _MyWidgetState extends State<MyWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Clean up
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## Disposal Patterns

### Basic Disposal

Always dispose of objects that implement `Disposable` or similar patterns:

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Resources requiring disposal
  late TextEditingController _textController;
  late AnimationController _animController;
  late FocusNode _focusNode;
  StreamSubscription? _subscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController();
    _animController = AnimationController(vsync: this);
    _focusNode = FocusNode();
    _subscription = myStream.listen(_handleData);
    _timer = Timer.periodic(Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    // Dispose in reverse order of initialization
    _timer?.cancel();
    _subscription?.cancel();
    _focusNode.dispose();
    _animController.dispose();
    _textController.dispose();

    super.dispose();
  }

  void _handleData(data) {}
  void _onTick(Timer timer) {}

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _textController);
  }
}
```

### ChangeNotifier Disposal

```dart
class MyNotifier extends ChangeNotifier {
  Timer? _timer;

  MyNotifier() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose(); // Important for ChangeNotifier
  }
}

// Usage
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late MyNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = MyNotifier();
    _notifier.addListener(_onChanged);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onChanged);
    _notifier.dispose(); // Dispose the notifier
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Conditional Disposal

Handle nullable resources:

```dart
class _MyWidgetState extends State<MyWidget> {
  TextEditingController? _controller;

  void maybeCreateController() {
    if (someCondition) {
      _controller = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Safe disposal of nullable resource
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Disposal with Error Handling

```dart
@override
void dispose() {
  try {
    _subscription?.cancel();
  } catch (e) {
    // Log but don't prevent other disposals
    debugPrint('Error cancelling subscription: $e');
  }

  try {
    _controller.dispose();
  } catch (e) {
    debugPrint('Error disposing controller: $e');
  }

  super.dispose();
}
```

## DevTools Memory View

### Memory View Overview

DevTools Memory view provides:

1. **Memory Chart**: Timeline of memory usage
2. **Profile Memory**: Current allocation by class
3. **Diff Snapshots**: Compare before/after memory states
4. **Trace Instances**: Track allocation sources

### Memory Chart Components

```
Memory Types in Chart:
- Dart/Flutter Heap: Dart objects
- Dart/Flutter Native: Native objects (images, files)
- Raster Cache: Rendered layers cache
- Allocated: Total heap capacity
- RSS: Resident Set Size (process memory)
```

### Taking Memory Snapshots

**Basic workflow**:

```dart
// 1. Start app in profile mode
flutter run --profile

// 2. Open DevTools
// 3. Navigate to Memory view
// 4. Take baseline snapshot
// 5. Perform operations
// 6. Take second snapshot
// 7. Compare with Diff view
```

### Profile Memory Tab

Shows current allocations grouped by class:

```
Class Name         | Instances | Shallow | Retained
-------------------|-----------|---------|----------
String             | 45,234    | 1.2 MB  | 1.2 MB
List               | 12,456    | 512 KB  | 2.3 MB
MyCustomWidget     | 234       | 45 KB   | 890 KB
```

**Actions**:
- Sort by instance count, shallow size, or retained size
- Filter by package or class name
- Export to CSV for analysis
- Enable "Refresh on GC" for real-time updates

### Diff Snapshots Workflow

Detect memory leaks in features:

```dart
// Example: Test navigation for leaks
// 1. Take snapshot (Snapshot A)
// 2. Navigate to screen
await tester.pumpAndSettle();

// 3. Navigate back
Navigator.pop(context);
await tester.pumpAndSettle();

// 4. Force garbage collection (in DevTools)
// 5. Take snapshot (Snapshot B)
// 6. Compare: Snapshot B - Snapshot A

// Expected: Net zero change
// Actual leak: Positive instance count for screen widgets
```

**Analyzing Diff**:
- Filter by package to see your classes
- Look for unexpected positive deltas
- Check retained size for impact
- Click on instances to see retaining paths

### Trace Instances Tab

Track where objects are allocated:

```dart
// 1. Select classes to trace (e.g., MyWidget)
// 2. Click "Start Tracking"
// 3. Use app to trigger allocations
// 4. Click "Refresh"
// 5. Select traced class
// 6. Review allocation call stacks
```

**View modes**:
- **Call Tree**: Top-down (shows what called what)
- **Bottom-Up**: Bottom-up (shows different paths to allocation)

Helps answer: "Why are so many instances of MyWidget being created?"

## Memory Profiling Techniques

### Technique 1: Identify Leaking Widgets

```dart
// Steps:
// 1. Navigate to screen
// 2. Take snapshot
// 3. Navigate away
// 4. Force GC (in DevTools)
// 5. Take snapshot
// 6. Diff snapshots
// 7. Filter for screen widget class

// Expected: 0 instances (widget should be collected)
// If > 0: Widget is leaked, check retaining paths
```

### Technique 2: Monitor Memory During Animations

```dart
// 1. Take baseline snapshot
// 2. Start animation loop
// 3. Run for 30 seconds
// 4. Take second snapshot
// 5. Compare memory growth

// Expected: Stable memory (minor fluctuations from GC)
// If growing: Possible leak in animation callback
```

### Technique 3: Test List Scrolling

```dart
// 1. Take snapshot
// 2. Scroll list to end
// 3. Scroll back to start
// 4. Force GC
// 5. Take snapshot
// 6. Compare

// Expected: Minimal growth (some caching is normal)
// If significant growth: List items not being released
```

### Technique 4: Image Memory Analysis

```dart
// Monitor image memory:
// 1. Check Memory Chart for "Dart/Flutter Native"
// 2. Load images
// 3. Navigate away
// 4. Check if Native memory decreases

// If not decreasing: Image cache not clearing
```

### Technique 5: Periodic Memory Check

```dart
// Add to debug builds
class MemoryMonitor {
  static Timer? _timer;

  static void start() {
    _timer = Timer.periodic(Duration(seconds: 10), (_) {
      final info = ProcessInfo.currentRss;
      debugPrint('RSS: ${info ~/ 1024 / 1024} MB');
    });
  }

  static void stop() {
    _timer?.cancel();
  }
}

// Call in main()
void main() {
  if (kDebugMode) {
    MemoryMonitor.start();
  }
  runApp(MyApp());
}
```

## BuildContext Memory Issues

### The BuildContext Problem

BuildContext provides access to the widget tree but retains references:

```dart
// BAD - Context stored in State
class _MyWidgetState extends State<MyWidget> {
  BuildContext? _storedContext;

  @override
  Widget build(BuildContext context) {
    _storedContext = context; // DON'T DO THIS

    return Container();
  }

  void laterOperation() {
    // _storedContext might be stale
    // Also prevents widget tree from being collected
    final theme = Theme.of(_storedContext!);
  }
}

// GOOD - Extract data, not context
class _MyWidgetState extends State<MyWidget> {
  ThemeData? _theme;

  @override
  Widget build(BuildContext context) {
    _theme = Theme.of(context); // Store data, not context

    return Container();
  }

  void laterOperation() {
    // Use stored theme data
    applyTheme(_theme!);
  }
}
```

### BuildContext in Async Callbacks

```dart
// BAD - Context in async callback
Future<void> loadData(BuildContext context) async {
  final data = await fetchData();

  // Context might be invalid if widget unmounted
  // Also retains widget tree during async operation
  Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(data)));
}

// GOOD - Check mounted state
Future<void> loadData() async {
  final data = await fetchData();

  if (!mounted) return; // State might be disposed

  // Use context from build method only when mounted
  Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(data)));
}
```

### BuildContext in Closures

```dart
// BAD
void setupCallback(BuildContext context) {
  final callback = () {
    final mediaQuery = MediaQuery.of(context); // Retains context
    print(mediaQuery.size);
  };

  someGlobalService.register(callback);
}

// GOOD
void setupCallback(BuildContext context) {
  final size = MediaQuery.of(context).size; // Extract size
  final callback = () {
    print(size); // Only retains Size object
  };

  someGlobalService.register(callback);
}
```

## Image and Asset Memory

### Image Caching

Flutter automatically caches images. Control cache size:

```dart
// Set max cache size (default is 1000 images or 100 MB)
void configureImageCache() {
  PaintingBinding.instance.imageCache.maximumSize = 500; // Max 500 images
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB
}

// Call in main()
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureImageCache();
  runApp(MyApp());
}
```

### Clear Image Cache

```dart
// Clear all cached images
PaintingBinding.instance.imageCache.clear();

// Clear specific image
PaintingBinding.instance.imageCache.evict(imageProvider);
```

### Optimize Image Loading

```dart
// BAD - Loads full resolution
Image.network('https://example.com/large-image.jpg')

// GOOD - Specify cache dimensions
Image.network(
  'https://example.com/large-image.jpg',
  cacheWidth: 400, // Resize to 400px width
)

// GOOD - Use appropriate image size
Image.asset(
  'assets/image.jpg',
  cacheHeight: 300,
)
```

### Dispose Cached Images

```dart
class MyImageWidget extends StatefulWidget {
  @override
  State<MyImageWidget> createState() => _MyImageWidgetState();
}

class _MyImageWidgetState extends State<MyImageWidget> {
  late ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = NetworkImage('https://example.com/image.jpg');
  }

  @override
  void dispose() {
    // Remove from cache when widget disposed
    _imageProvider.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(image: _imageProvider);
  }
}
```

## Stream and Listener Management

### Stream Subscriptions

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = someStream.listen(
      (data) {
        setState(() {
          // Handle data
        });
      },
      onError: (error) {
        debugPrint('Stream error: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Critical: Cancel subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Multiple Subscriptions

```dart
class _MyWidgetState extends State<MyWidget> {
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();

    _subscriptions.add(stream1.listen(_handleStream1));
    _subscriptions.add(stream2.listen(_handleStream2));
    _subscriptions.add(stream3.listen(_handleStream3));
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  void _handleStream1(data) {}
  void _handleStream2(data) {}
  void _handleStream3(data) {}

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### ChangeNotifier Listeners

```dart
class _MyWidgetState extends State<MyWidget> {
  late MyNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = MyNotifier();
    _notifier.addListener(_handleChange);
  }

  @override
  void dispose() {
    _notifier.removeListener(_handleChange); // Must remove
    _notifier.dispose(); // Then dispose notifier
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## Best Practices

### 1. Always Dispose Resources

```dart
// Checklist for disposal:
// ✓ TextEditingController
// ✓ AnimationController
// ✓ FocusNode
// ✓ StreamSubscription
// ✓ Timer
// ✓ ChangeNotifier listeners
// ✓ ScrollController
// ✓ TabController
// ✓ Any custom Disposable objects
```

### 2. Extract Values from BuildContext

```dart
// DON'T store context, extract what you need
final theme = Theme.of(context);
final mediaQuery = MediaQuery.of(context);
final navigator = Navigator.of(context);
```

### 3. Avoid Global State When Possible

```dart
// Instead of globals, use InheritedWidget or Provider
class MyService extends InheritedWidget {
  final ServiceImpl service;

  const MyService({
    required this.service,
    required Widget child,
  }) : super(child: child);

  static ServiceImpl of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MyService>()!.service;
  }

  @override
  bool updateShouldNotify(MyService old) => service != old.service;
}
```

### 4. Use Weak References for Caches

```dart
class Cache<K, V> {
  final Map<K, WeakReference<V>> _cache = {};

  void set(K key, V value) {
    _cache[key] = WeakReference(value);
  }

  V? get(K key) {
    return _cache[key]?.target;
  }
}
```

### 5. Profile Regularly

- Run memory profiling weekly during development
- Before each release, perform memory leak audit
- Monitor RSS in production (if possible)
- Set up automated memory tests

### 6. Test Navigation Thoroughly

```dart
// Test that screens are properly disposed
testWidgets('Screen cleanup test', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to screen
  await tester.tap(find.text('Open Screen'));
  await tester.pumpAndSettle();

  // Navigate back
  await tester.pageBack();
  await tester.pumpAndSettle();

  // Check for lingering state (requires instrumentation)
  // Or manually test with DevTools snapshots
});
```

### 7. Limit Image Cache Size

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set reasonable cache limits
  PaintingBinding.instance.imageCache
    ..maximumSize = 100
    ..maximumSizeBytes = 50 * 1024 * 1024; // 50 MB

  runApp(MyApp());
}
```

### 8. Use mounted Check

```dart
Future<void> loadData() async {
  final data = await fetchData();

  // Always check mounted before setState
  if (!mounted) return;

  setState(() {
    _data = data;
  });
}
```

### 9. Prefer Stateless Widgets

StatelessWidget has lower memory overhead and is simpler to reason about:

```dart
// Prefer this when possible
class MyWidget extends StatelessWidget {
  final String data;
  const MyWidget(this.data);

  @override
  Widget build(BuildContext context) => Text(data);
}
```

### 10. Monitor Memory in CI/CD

```dart
// Add memory tests to integration tests
testWidgets('Memory stress test', (tester) async {
  final initialMemory = await getMemoryUsage();

  // Perform operations
  for (int i = 0; i < 100; i++) {
    await tester.tap(find.byType(MyButton));
    await tester.pumpAndSettle();
  }

  final finalMemory = await getMemoryUsage();
  final growth = finalMemory - initialMemory;

  // Assert memory growth is reasonable
  expect(growth, lessThan(10 * 1024 * 1024)); // Less than 10 MB
});
```

Memory management in Flutter requires vigilance in disposal patterns, awareness of closure capturing, and regular profiling. Use DevTools Memory view to catch leaks early, follow disposal best practices, and test memory behavior as part of your development workflow. The combination of automatic garbage collection and proper resource management creates stable, performant Flutter applications.
