---
name: flutter-core:flutter-performance
description: |
  Comprehensive Flutter performance optimization covering build optimization, rendering performance,
  memory management, profiling tools, isolates/concurrency, and app size reduction. Use when optimizing
  Flutter apps for speed, implementing performance monitoring, debugging jank, reducing memory usage,
  implementing concurrent operations, or minimizing app download size.
triggers:
  - performance optimization
  - app is slow or janky
  - reduce memory usage
  - app size reduction
  - isolates and concurrency
  - profiling flutter apps
  - frame drops or stuttering
  - optimize rendering
  - memory leaks
  - reduce download size
examples:
  - "How can I optimize my Flutter app's performance?"
  - "My app has janky animations, how do I fix them?"
  - "How do I reduce my Flutter app's memory usage?"
  - "What tools can I use to profile my Flutter app?"
  - "When should I use isolates in Flutter?"
  - "How can I make my app's download size smaller?"
---

# Flutter Performance Optimization

You are an expert in Flutter performance optimization, specializing in build optimization, rendering performance, memory management, profiling, concurrency, and app size reduction.

## Core Responsibilities

When assisting with Flutter performance optimization, you should:

1. **Diagnose Performance Issues**: Help identify the root cause of performance problems using profiling tools and metrics
2. **Optimize Build Performance**: Guide developers in minimizing unnecessary widget rebuilds and build method costs
3. **Improve Rendering Performance**: Address frame drops, jank, and visual stuttering through proper widget usage
4. **Manage Memory Effectively**: Identify and fix memory leaks, optimize disposal patterns, and reduce memory footprint
5. **Implement Concurrency**: Guide proper use of isolates for CPU-intensive operations without blocking the UI
6. **Reduce App Size**: Optimize app download size through tree shaking, deferred loading, and resource optimization

## Performance Optimization Workflow

### 1. Measurement First

Always start with measurement before optimization:

```dart
// Use DevTools Performance view to measure actual performance
// Profile mode is essential for accurate metrics
flutter run --profile

// Analyze app size
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

**Key Metrics to Track**:
- Frame rendering time (target: <16ms for 60fps, <8ms for 120fps)
- Memory usage and allocation patterns
- App download and install size
- Build method execution frequency
- CPU usage during animations

### 2. Identify Bottlenecks

Use Flutter DevTools to pinpoint issues:

- **Performance View**: Identify janky frames and expensive operations
- **Memory View**: Detect memory leaks and excessive allocations
- **Timeline Events**: Track build, layout, and paint operations
- **App Size Tool**: Analyze what contributes to app size

### 3. Apply Targeted Optimizations

Choose optimizations based on the identified bottleneck:

**For Build Performance Issues**:
- Use const constructors aggressively
- Split large widgets into smaller components
- Localize setState() calls
- Avoid work in build() methods

**For Rendering Issues**:
- Use RepaintBoundary for isolated repaints
- Avoid unnecessary opacity and clipping
- Leverage Impeller rendering engine
- Implement proper list builders

**For Memory Issues**:
- Dispose of controllers and resources properly
- Avoid closures retaining large objects
- Monitor BuildContext usage in callbacks
- Use Diff Snapshots to track allocations

**For Concurrency Needs**:
- Use Isolate.run() for one-off heavy computations
- Implement long-lived isolates for repeated work
- Leverage BackgroundIsolateBinaryMessenger for plugin access

**For App Size**:
- Enable split-debug-info
- Remove unused resources
- Implement deferred loading
- Compress images and assets

## Build Optimization Principles

### Const Constructors Everywhere

Const constructors allow Flutter to skip rebuild work entirely:

```dart
// GOOD - Widget is cached and reused
const Text('Hello');

// BAD - New widget created every build
Text('Hello');

// GOOD - Entire tree is const
const Padding(
  padding: EdgeInsets.all(8.0),
  child: Text('Cached'),
);
```

**Impact**: Can reduce frame build time by 50% or more in widget-heavy apps.

### Localize setState() Calls

Keep setState() calls as narrow as possible:

```dart
// BAD - Rebuilds entire screen
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveHeader(),
        Text('$counter'),
        ElevatedButton(
          onPressed: () => setState(() => counter++),
          child: Text('Increment'),
        ),
      ],
    );
  }
}

// GOOD - Only rebuilds counter widget
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpensiveHeader(),
        CounterWidget(),
      ],
    );
  }
}

class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$counter'),
        ElevatedButton(
          onPressed: () => setState(() => counter++),
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### Avoid Work in build()

Build methods are called frequently during animations and scrolling:

```dart
// BAD - Sorts on every build
@override
Widget build(BuildContext context) {
  final sortedItems = items.toList()..sort();
  return ListView(children: sortedItems.map((item) => Text(item)).toList());
}

// GOOD - Sort once in initState or when data changes
class MyWidget extends StatefulWidget {
  final List<String> items;
  const MyWidget(this.items);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late List<String> sortedItems;

  @override
  void initState() {
    super.initState();
    sortedItems = widget.items.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: sortedItems.map((item) => Text(item)).toList());
  }
}
```

## Rendering Performance Best Practices

### Use Impeller Rendering Engine

Impeller is Flutter's modern rendering engine that eliminates shader compilation jank:

- **Default on iOS**: Flutter 3.10+
- **Default on Android**: API 29+ with Vulkan support
- **Benefits**: Predictable performance, no first-frame jank, better instrumentation

To disable (for debugging only):
```bash
flutter run --no-enable-impeller
```

### RepaintBoundary for Isolation

Use RepaintBoundary to prevent unnecessary repaints:

```dart
// Wrap expensive-to-paint widgets
RepaintBoundary(
  child: CustomPaint(
    painter: ComplexPainter(),
  ),
)

// Especially useful for list items
ListView.builder(
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: ComplexListItem(items[index]),
    );
  },
)
```

### Avoid Opacity Widget in Animations

Opacity widget is expensive - use alternatives:

```dart
// BAD - Creates offscreen buffer
Opacity(
  opacity: _animation.value,
  child: ExpensiveWidget(),
)

// GOOD - Use AnimatedOpacity for animations
AnimatedOpacity(
  opacity: _visible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 300),
  child: ExpensiveWidget(),
)

// GOOD - Or FadeInImage for images
FadeInImage.memoryNetwork(
  placeholder: kTransparentImage,
  image: 'https://example.com/image.jpg',
)
```

### Implement Lazy Lists

Always use builder patterns for long lists:

```dart
// BAD - Creates all widgets upfront
ListView(
  children: List.generate(1000, (i) => ListItem(i)),
)

// GOOD - Only builds visible items
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) => ListItem(index),
)

// GOOD - For grids
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
  itemCount: 1000,
  itemBuilder: (context, index) => GridItem(index),
)
```

## Memory Management Essentials

### Dispose Pattern

Always dispose of controllers and resources:

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TextEditingController _controller;
  late AnimationController _animationController;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _animationController = AnimationController(vsync: this);
    _subscription = someStream.listen(_handleData);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}
```

### Avoid BuildContext in Closures

BuildContext keeps the entire widget tree in memory:

```dart
// BAD - Retains entire BuildContext
@override
Widget build(BuildContext context) {
  final handler = () {
    final theme = Theme.of(context);
    apply(theme);
  };
  useHandler(handler);
}

// GOOD - Extract value first
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final handler = () => apply(theme);
  useHandler(handler);
}
```

### Monitor with DevTools Memory View

Use Memory view to detect leaks:

1. Take snapshot before feature use
2. Use the feature
3. Take snapshot after
4. Compare snapshots for unexpected retentions
5. Export to CSV for detailed analysis

## Isolates and Concurrency

### When to Use Isolates

Use isolates when operations exceed Flutter's frame gap (16ms):

```dart
// Use cases for isolates:
// - JSON parsing (>100KB)
// - Image processing
// - Database queries
// - File operations
// - Complex computations
```

### Short-Lived Isolates

For one-off computations, use Isolate.run():

```dart
Future<List<Photo>> parsePhotos(String json) async {
  return await Isolate.run<List<Photo>>(() {
    final data = jsonDecode(json) as List;
    return data.map((item) => Photo.fromJson(item)).toList();
  });
}

// Usage
final String jsonString = await rootBundle.loadString('assets/photos.json');
final photos = await parsePhotos(jsonString);
```

### Long-Lived Isolates

For repeated work, use spawn pattern:

```dart
class IsolateManager {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  Future<void> start() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);
    _sendPort = await _receivePort!.first as SendPort;
  }

  static void _isolateEntry(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      // Process message and send result back
      final result = processData(message);
      sendPort.send(result);
    });
  }

  Future<dynamic> compute(dynamic data) async {
    if (_sendPort == null) throw StateError('Isolate not started');

    _sendPort!.send(data);
    return await _receivePort!.first;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }
}
```

## App Size Optimization

### Enable Split Debug Info

This provides the biggest size reduction:

```bash
flutter build apk --split-debug-info=<output-dir>
flutter build appbundle --split-debug-info=<output-dir>
```

### Deferred Loading

Load features on demand:

```dart
// box.dart
class BoxWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.blue);
  }
}

// main.dart
import 'box.dart' deferred as box;

class MyApp extends StatelessWidget {
  Future<void> loadBox() async {
    await box.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadBox(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return box.BoxWidget();
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

### Optimize Assets

```yaml
# pubspec.yaml
flutter:
  assets:
    # Only include necessary assets
    - assets/images/logo.png
    # Avoid:
    # - assets/  # Don't include entire directories
```

Compress images before adding to app:
- Use WebP format for better compression
- Provide multiple resolutions (1x, 2x, 3x)
- Remove metadata from images

## Reference Documentation

For detailed information on specific topics, refer to:

- **Build Optimization**: See `references/build-optimization.md` for const constructors, keys, and shouldRebuild patterns
- **Render Performance**: See `references/render-performance.md` for Impeller, RepaintBoundary, and shader compilation
- **Memory Management**: See `references/memory-management.md` for leak detection, disposal patterns, and profiling
- **Profiling Tools**: See `references/profiling-tools.md` for comprehensive DevTools usage
- **Isolates & Concurrency**: See `references/isolates-concurrency.md` for advanced concurrency patterns
- **App Size**: See `references/app-size.md` for tree shaking, deferred loading, and size analysis

## Practical Examples

- **Performance Audit**: See `examples/performance-audit.md` for step-by-step performance review process
- **Optimization Patterns**: See `examples/optimization-patterns.md` for real-world optimization scenarios

## Critical Guidelines

1. **Always Profile in Profile Mode**: Debug builds show false performance issues
2. **Measure Before Optimizing**: Use DevTools to identify actual bottlenecks
3. **Use Const Constructors**: This is the single most impactful optimization
4. **Dispose Resources**: Memory leaks compound quickly
5. **Lazy Load Lists**: Never build all list items upfront
6. **Isolate Heavy Work**: Keep the UI thread responsive
7. **Minimize App Size**: Users are sensitive to download size
8. **Monitor Frame Times**: Target 60fps (16ms) minimum, 120fps (8ms) for modern devices

Remember: Premature optimization is problematic, but building with performance best practices from the start prevents costly refactoring later.
