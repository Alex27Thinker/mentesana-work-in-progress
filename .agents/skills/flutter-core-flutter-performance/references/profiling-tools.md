# Profiling Tools in Flutter

Flutter provides comprehensive profiling tools through DevTools and command-line utilities. This guide covers using the Performance view, CPU profiler, Memory view, Network view, and command-line profiling to diagnose and fix performance issues.

## Table of Contents

- [DevTools Overview](#devtools-overview)
- [Performance View](#performance-view)
- [CPU Profiler](#cpu-profiler)
- [Memory View](#memory-view)
- [Network View](#network-view)
- [Timeline Events](#timeline-events)
- [Command-Line Profiling](#command-line-profiling)
- [Profile Mode](#profile-mode)
- [Custom Performance Instrumentation](#custom-performance-instrumentation)
- [Performance Testing](#performance-testing)

## DevTools Overview

### Launching DevTools

**Method 1: From VS Code**
```bash
# Run app in profile mode
flutter run --profile

# Click "Dart DevTools" in debug toolbar
```

**Method 2: From Command Line**
```bash
# Run app
flutter run --profile

# DevTools URL is printed to console
# Open in browser or run:
dart devtools
```

**Method 3: Standalone**
```bash
# Install DevTools globally
dart pub global activate devtools

# Run DevTools
dart pub global run devtools
```

### DevTools Tabs

1. **Performance**: Frame analysis, timeline, rendering
2. **CPU Profiler**: Method-level performance analysis
3. **Memory**: Heap analysis, snapshots, leaks
4. **Network**: HTTP request monitoring
5. **Logging**: Console output and errors
6. **App Size**: Bundle size analysis
7. **Debugger**: Breakpoints and inspection

## Performance View

### Flutter Frames Chart

The frames chart shows real-time rendering performance:

```
UI Thread (Bottom):
[====|====|====|====] <- Build, layout, paint
 16ms  14ms  18ms  15ms

Raster Thread (Top):
[====|====|====|====] <- GPU rendering
 12ms  11ms  20ms  13ms

Green: < 16ms (60fps target)
Red: > 16ms (jank/dropped frame)
```

**Reading the Chart**:
- Each bar represents one frame
- UI thread (blue): Dart code execution
- Raster thread (orange): GPU rendering
- Red overlay: Frame exceeded 16ms threshold

### Frame Analysis Tab

Click on a janky (red) frame to see:

1. **Frame Time**: Total time for UI and Raster
2. **Expensive Operations**: Detected bottlenecks
3. **Recommendations**: Specific optimization suggestions
4. **Event Timeline**: Detailed timing breakdown

**Example Analysis**:
```
Frame #245: 28.4ms (JANK)
  UI: 22.1ms
    - Build: 15.2ms ← SLOW
    - Layout: 4.8ms
    - Paint: 2.1ms
  Raster: 6.3ms

Suggestions:
• Avoid work in build() methods
• Use const constructors
• Split large widgets
```

### Timeline Events Tab

Shows all events in selected frame:

```
Timeline (28.4ms total):
├─ build (15.2ms)
│  ├─ MyWidget.build (8.4ms) ← EXPENSIVE
│  ├─ ListView.build (4.2ms)
│  └─ ...
├─ layout (4.8ms)
└─ paint (2.1ms)
```

**Event Types**:
- **Build**: Widget tree construction
- **Layout**: Size/position calculation
- **Paint**: Drawing operations
- **Composite**: Layer composition
- **Vsync**: Frame synchronization
- **GPURasterizer**: GPU work

### Advanced Features

#### Track Widget Builds

Enable to see individual widget build times:

```dart
// In DevTools, enable "Track widget builds"
// Then interact with app

// Timeline shows:
MyExpensiveWidget.build: 12.3ms ← Identify slow widgets
MySimpleWidget.build: 0.2ms
```

#### Track Layouts

Shows layout operations:

```
layout events:
RenderFlex.performLayout: 3.2ms
RenderPadding.performLayout: 0.8ms
RenderConstrainedBox.performLayout: 0.4ms
```

Helps identify intrinsic layout passes and expensive layout calculations.

#### Track Paints

Shows paint operations:

```
paint events:
RenderCustomPaint.paint: 8.1ms ← EXPENSIVE
RenderDecoratedBox.paint: 1.2ms
RenderParagraph.paint: 0.6ms
```

#### Performance Overlay

Enable directly in app:

```dart
MaterialApp(
  showPerformanceOverlay: true,
  home: MyHomePage(),
)
```

Or programmatically:

```dart
import 'package:flutter/rendering.dart';

void togglePerformanceOverlay(bool enabled) {
  if (enabled) {
    debugProfileBuildsEnabled = true;
    debugProfilePaintsEnabled = true;
  } else {
    debugProfileBuildsEnabled = false;
    debugProfilePaintsEnabled = false;
  }
}
```

### Rendering Layers Debug

#### Checkerboard Offscreen Layers

Identify expensive saveLayer() calls:

```dart
// In DevTools: Enable "Highlight offscreen layers"
// Or programmatically:
import 'package:flutter/rendering.dart';

void main() {
  debugPaintLayerBordersEnabled = true;
  runApp(MyApp());
}
```

Gold checkerboard indicates offscreen rendering from:
- `Opacity` widget
- `ShaderMask`
- `ColorFilter`
- `BackdropFilter`
- `ClipPath` (sometimes)

#### Checkerboard Raster Cache

Shows which images are cached:

```dart
debugPaintRasterCacheEnabled = true;
```

Checkerboard appears on cached images, helping verify caching behavior.

### Export and Share Performance Data

**Export Timeline**:
1. Record performance session
2. Click export button (top-right)
3. Save JSON file
4. Share with team or import later

**Import Timeline**:
1. Click import button
2. Select previously exported JSON
3. Analyze offline

## CPU Profiler

### Starting CPU Profiler

```dart
// In DevTools:
// 1. Navigate to CPU Profiler tab
// 2. Click "Record"
// 3. Interact with app
// 4. Click "Stop"
// 5. Analyze flame chart
```

### Flame Chart

The flame chart visualizes method call stacks:

```
┌──────────────────────────────────────┐ main() [500ms]
│  ┌────────────────────────────────┐  │ runApp() [450ms]
│  │  ┌──────────────────────┐      │  │ build() [300ms]
│  │  │  ┌──────────┐        │      │  │ expensiveMethod() [200ms]
│  │  │  └──────────┘        │      │  │
│  │  └──────────────────────┘      │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘

Width = Time spent
Depth = Call stack depth
```

**Reading the Chart**:
- Wider = More time spent
- Top = Called by bottom
- Click to zoom into method
- Look for unusually wide sections

### Call Tree View

Shows top-down method hierarchy:

```
Method                    Total    Self
────────────────────────────────────────
main()                    500ms    0ms
└─ runApp()              450ms    10ms
   └─ build()            300ms    50ms
      └─ expensive()     200ms    200ms  ← HOT SPOT
```

**Columns**:
- **Total**: Time including children
- **Self**: Time in method itself (excluding children)

**Finding Bottlenecks**: Sort by "Self" to find methods doing the most work.

### Bottom-Up View

Shows methods that consume the most time, regardless of call path:

```
Method                    Total    Self
────────────────────────────────────────
expensive()               200ms    200ms  ← SLOWEST
jsonDecode()              150ms    150ms
build()                   300ms    50ms
runApp()                  450ms    10ms
```

Useful for identifying slow operations across different call stacks.

### Profile Granularity

Adjust sampling rate:

```dart
// High granularity (slower, more detail)
// Low granularity (faster, less detail)

// Set via DevTools CPU Profiler settings
// Default: Medium (good balance)
```

### CPU Profiler Best Practices

1. **Profile representative scenarios**: Real user interactions
2. **Run multiple sessions**: Verify consistency
3. **Focus on self time**: Direct work in methods
4. **Look for patterns**: Repeated expensive calls
5. **Profile in release mode**: Most accurate for production performance

## Memory View

### Memory Chart

Real-time memory usage visualization:

```
Memory (MB)
100 ┤        ╭─╮
 80 ┤     ╭──╯ ╰─╮
 60 ┤  ╭──╯      ╰───
 40 ┤╭─╯
 20 ┼╯
    └────────────────→ Time

Legend:
- Blue: Dart heap
- Orange: Native heap
- Green: Raster cache
```

**Memory Types**:
- **Dart/Flutter Heap**: Dart objects
- **Dart/Flutter Native**: Native objects (images, files)
- **Raster Cache**: Cached rendering layers
- **Allocated**: Total heap capacity
- **RSS**: Resident Set Size (total process memory)

### Profile Memory Tab

Current memory allocation by class:

```
Class                Instances    Shallow    Retained
──────────────────────────────────────────────────────
String               45,234       1.2 MB     1.2 MB
List                 12,456       512 KB     2.3 MB
_InternalLinkedList  8,901        234 KB     890 KB
MyWidget             234          45 KB      890 KB  ← Your classes
```

**Actions**:
- Click column headers to sort
- Filter by package (e.g., show only "my_app")
- Export to CSV
- Refresh to see current state
- Enable "Refresh on GC" for auto-update

### Diff Snapshots

Compare memory before and after operations:

```dart
// Workflow:
// 1. Take Snapshot A (baseline)
// 2. Perform operation (navigate, load data, etc.)
// 3. Take Snapshot B
// 4. Click "Diff" and select snapshots
// 5. Analyze differences

// Example diff:
Class                Delta Instances    Delta Retained
───────────────────────────────────────────────────────
MyScreen             +5                 +450 KB        ← LEAK
Image                +10                +2.3 MB        ← Expected
String               +234               +45 KB         ← Normal
```

**Interpreting Results**:
- **Positive delta**: Objects added
- **Negative delta**: Objects removed
- **Expected patterns**: Temporary allocations during operations
- **Leaks**: Persistent positive delta after operations complete

### Trace Instances

Track where specific classes are allocated:

```dart
// Steps:
// 1. Click "Trace Instances"
// 2. Select classes to track (e.g., MyWidget)
// 3. Click "Start Tracking"
// 4. Interact with app
// 5. Click "Refresh"
// 6. Select traced class to see allocation stacks

// Example output:
MyWidget allocated from:
├─ MyWidget() [234 allocations]
│  ├─ MyScreen.build()
│  │  └─ StatefulElement.rebuild()
│  └─ ListView.builder()
└─ ...
```

### Memory View Best Practices

1. **Take baseline snapshot**: Before testing
2. **Force GC**: Before second snapshot (button in DevTools)
3. **Test in isolation**: One feature at a time
4. **Look for retained paths**: Understand why objects persist
5. **Monitor Native memory**: Images and files

## Network View

### HTTP Request Monitoring

The Network tab shows all HTTP requests:

```
Status  Method  URL                           Time    Size
──────────────────────────────────────────────────────────
200     GET     /api/users                    234ms   12 KB
200     GET     /api/posts                    456ms   45 KB
404     POST    /api/invalid                  123ms   2 KB
```

**Request Details**:
- Click request to see headers, response, timing
- Filter by status code, method, URL
- Export request data

### Request Timing Breakdown

```
Request: GET /api/users (234ms total)

DNS Lookup:        12ms
TCP Connect:       23ms
TLS Handshake:     34ms
Request Sent:      5ms
Waiting (TTFB):    120ms  ← Server processing
Content Download:  40ms
```

Helps identify whether latency is network or server-side.

### Network Profiling Best Practices

1. **Monitor during typical usage**: Real-world scenarios
2. **Check request count**: Too many requests?
3. **Optimize payload size**: Compress, paginate
4. **Cache aggressively**: Reduce redundant requests
5. **Batch requests**: Combine when possible

## Timeline Events

### Custom Timeline Events

Instrument your code with custom events:

```dart
import 'dart:developer';

Future<void> processData(List<Data> items) async {
  // Start timeline event
  Timeline.startSync('processData');

  try {
    for (var item in items) {
      Timeline.startSync('processItem');
      await _processItem(item);
      Timeline.finishSync();
    }
  } finally {
    Timeline.finishSync();
  }
}
```

View in DevTools Timeline tab:

```
Timeline:
├─ processData (450ms)
│  ├─ processItem (120ms)
│  ├─ processItem (115ms)
│  ├─ processItem (125ms)
│  └─ processItem (90ms)
```

### Instant Events

For point-in-time markers:

```dart
Timeline.instantEvent('Cache miss', arguments: {
  'key': cacheKey,
  'timestamp': DateTime.now().toIso8601String(),
});
```

### Flow Events

Track async operations across frames:

```dart
final flow = Flow.begin();
Timeline.startSync('asyncOperation', flow: flow);

someAsyncCall().then((_) {
  Timeline.finishSync();
  flow.end();
});
```

### TimelineTask

Alternative API for duration tracking:

```dart
import 'dart:developer';

Future<void> myOperation() async {
  final task = TimelineTask()..start('MyOperation');

  await doWork();

  task.instant('Checkpoint');

  await doMoreWork();

  task.finish();
}
```

## Command-Line Profiling

### Observatory

Low-level VM profiling (advanced):

```bash
# Run with observatory
flutter run --profile --observatory-port=8888

# Open in browser
open http://localhost:8888
```

Observatory provides:
- CPU profiling
- Memory allocation
- VM metrics
- Isolate information

### Performance Trace Export

Export startup performance:

```bash
flutter run --profile --trace-startup --trace-skia

# Generates timeline.json
# Import into DevTools or chrome://tracing
```

### Build Timing

Measure build performance:

```bash
flutter build apk --profile --analyze-size

# Shows:
# - Build time breakdown
# - APK size analysis
# - Dart AOT compilation time
```

### Benchmark Tests

Create performance benchmark tests:

```dart
// test/benchmark/my_benchmark.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Benchmark widget build', (tester) async {
    await benchmarkWidgets((WidgetTester tester) async {
      await tester.pumpWidget(MyExpensiveWidget());
    }, (List<FrameTiming> timings) {
      final buildTimes = timings.map((t) => t.buildDuration).toList();
      final average = buildTimes.reduce((a, b) => a + b) / buildTimes.length;

      print('Average build time: ${average.inMilliseconds}ms');
      expect(average.inMilliseconds, lessThan(16)); // 60fps target
    });
  });
}
```

Run benchmarks:

```bash
flutter test test/benchmark/
```

## Profile Mode

### Why Profile Mode

**Debug Mode**:
- Includes debugging overhead
- Hot reload support
- Assertions enabled
- NOT representative of release performance

**Profile Mode**:
- Optimizations enabled
- Performance tracing available
- No debugging overhead
- Realistic performance metrics

**Release Mode**:
- Maximum optimizations
- No tracing available
- Best performance

### Running in Profile Mode

```bash
# Run on device
flutter run --profile

# Build APK
flutter build apk --profile

# Build iOS
flutter build ios --profile
```

### Profile Mode Characteristics

```dart
// Assertions disabled
assert(false); // No-op in profile mode

// Const evaluation
const expensiveComputation(); // Evaluated at compile time

// Tree shaking
if (kDebugMode) {
  debugPrint('Never executed in profile mode');
}
```

## Custom Performance Instrumentation

### Performance Monitoring Class

Create reusable performance monitoring:

```dart
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _metrics = {};

  static void start(String name) {
    _timers[name] = Stopwatch()..start();
  }

  static void stop(String name) {
    final timer = _timers[name];
    if (timer == null) return;

    timer.stop();
    _metrics.putIfAbsent(name, () => []).add(timer.elapsed);
    _timers.remove(name);
  }

  static void printStats(String name) {
    final metrics = _metrics[name];
    if (metrics == null || metrics.isEmpty) return;

    final total = metrics.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );
    final average = total ~/ metrics.length;

    print('$name stats:');
    print('  Calls: ${metrics.length}');
    print('  Average: ${average.inMilliseconds}ms');
    print('  Total: ${total.inMilliseconds}ms');
  }
}

// Usage
void myOperation() {
  PerformanceMonitor.start('myOperation');

  // Do work

  PerformanceMonitor.stop('myOperation');
}

// Later, print stats
PerformanceMonitor.printStats('myOperation');
```

### Frame Callback Monitoring

Track frame render times:

```dart
class FrameMonitor {
  static final List<Duration> _frameTimes = [];

  static void start() {
    WidgetsBinding.instance.addTimingsCallback(_onFrame);
  }

  static void stop() {
    WidgetsBinding.instance.removeTimingsCallback(_onFrame);
  }

  static void _onFrame(List<FrameTiming> timings) {
    for (var timing in timings) {
      _frameTimes.add(timing.totalSpan);
    }
  }

  static void printStats() {
    if (_frameTimes.isEmpty) return;

    final total = _frameTimes.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    );
    final average = total ~/ _frameTimes.length;
    final jankyFrames = _frameTimes
        .where((d) => d.inMilliseconds > 16)
        .length;

    print('Frame stats:');
    print('  Total frames: ${_frameTimes.length}');
    print('  Average: ${average.inMilliseconds}ms');
    print('  Janky (>16ms): $jankyFrames');
    print('  Jank rate: ${(jankyFrames / _frameTimes.length * 100).toStringAsFixed(1)}%');
  }
}

// Usage
void main() {
  FrameMonitor.start();
  runApp(MyApp());
}
```

### Widget Build Counter

Track rebuild frequency:

```dart
class BuildCounter {
  static final Map<String, int> _counts = {};

  static void increment(String widgetName) {
    _counts[widgetName] = (_counts[widgetName] ?? 0) + 1;
  }

  static void printStats() {
    print('Build counts:');
    _counts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value))
        ..forEach((entry) {
          print('  ${entry.key}: ${entry.value}');
        });
  }
}

// Usage in widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    BuildCounter.increment('MyWidget');
    return Container();
  }
}
```

## Performance Testing

### Integration Test Performance

```dart
// test_driver/perf_test.dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Performance Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Scroll performance', () async {
      // Start tracing
      await driver.startTracing();

      // Perform scroll
      await driver.scroll(
        find.byType('ListView'),
        0,
        -300,
        Duration(milliseconds: 300),
      );

      // Stop tracing
      final timeline = await driver.stopTracingAndDownloadTimeline();

      // Analyze timeline
      final summary = TimelineSummary.summarize(timeline);

      // Assert performance
      expect(
        summary.averageFrameBuildTimeMillis,
        lessThan(16),
      );

      expect(
        summary.percentileFrameBuildTimeMillis(90),
        lessThan(16),
      );

      // Write results
      await summary.writeSummaryToFile('scroll_performance', pretty: true);
    });
  });
}
```

### Golden Regression Testing

Ensure UI changes don't degrade performance:

```dart
testWidgets('Performance regression test', (tester) async {
  final Stopwatch stopwatch = Stopwatch()..start();

  await tester.pumpWidget(MyExpensiveWidget());

  stopwatch.stop();

  expect(
    stopwatch.elapsedMilliseconds,
    lessThan(100), // First build under 100ms
  );

  // Measure rebuild
  stopwatch.reset();
  stopwatch.start();

  await tester.pumpWidget(MyExpensiveWidget());

  stopwatch.stop();

  expect(
    stopwatch.elapsedMilliseconds,
    lessThan(16), // Rebuild under 16ms
  );
});
```

### Best Practices Summary

1. **Always profile in profile mode**: Debug metrics are misleading
2. **Use DevTools Performance view**: Most comprehensive tool
3. **Track custom events**: Instrument critical paths
4. **Monitor memory**: Memory leaks compound over time
5. **Profile regularly**: Catch regressions early
6. **Test on real devices**: Emulators don't represent real performance
7. **Establish baselines**: Know your performance targets
8. **Automate performance tests**: CI/CD integration
9. **Profile before optimization**: Measure to find real bottlenecks
10. **Document findings**: Share insights with team

Profiling is an iterative process. Regular monitoring, targeted instrumentation, and data-driven optimization lead to performant Flutter applications. Use DevTools as your primary tool, supplement with custom instrumentation for specific scenarios, and always validate improvements with measurements.
