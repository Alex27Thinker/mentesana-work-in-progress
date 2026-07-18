# Rendering Performance in Flutter

Rendering performance determines how smoothly your Flutter app displays animations, transitions, and UI updates. This guide covers the Impeller rendering engine, RepaintBoundary optimization, shader compilation, and techniques to eliminate jank (stuttering) in your applications.

## Table of Contents

- [Understanding Flutter's Rendering Pipeline](#understanding-flutters-rendering-pipeline)
- [Frame Rate Targets](#frame-rate-targets)
- [Impeller Rendering Engine](#impeller-rendering-engine)
- [RepaintBoundary Optimization](#repaintboundary-optimization)
- [Shader Compilation and Jank](#shader-compilation-and-jank)
- [Opacity and Clipping Performance](#opacity-and-clipping-performance)
- [List and Grid Rendering](#list-and-grid-rendering)
- [Visual Debugging Tools](#visual-debugging-tools)
- [Advanced Rendering Techniques](#advanced-rendering-techniques)

## Understanding Flutter's Rendering Pipeline

### The Three Trees

Flutter maintains three parallel trees during rendering:

1. **Widget Tree**: Immutable descriptions of UI
2. **Element Tree**: Mutable instances managing widget lifecycle
3. **RenderObject Tree**: Performs layout, painting, and compositing

```
Widget Tree          Element Tree         RenderObject Tree
-----------          ------------         -----------------
Container      -->   Element         -->  RenderPadding
  Padding      -->     Element       -->  RenderPadding
    Text       -->       Element     -->  RenderParagraph
```

### Rendering Pipeline Phases

Each frame goes through these phases:

1. **Build**: Create widget tree from state
2. **Layout**: Calculate size and position of render objects
3. **Paint**: Draw render objects to layers
4. **Composite**: Combine layers into final scene
5. **Rasterize**: Convert to pixels (GPU)

```dart
// Build phase - triggered by setState()
@override
Widget build(BuildContext context) {
  return Container(child: Text('Hello'));
}

// Layout phase - RenderObject.performLayout()
// Calculates sizes and positions

// Paint phase - RenderObject.paint()
// Draws to canvas

// Composite & Rasterize - Engine handles
// Sends to GPU for final rendering
```

### Understanding Jank

**Jank** occurs when a frame takes longer than the target time:

- **60 FPS target**: 16.67ms per frame (60Hz displays)
- **120 FPS target**: 8.33ms per frame (120Hz displays)

Frames exceeding these times result in visible stuttering.

```
Frame Timeline:
|----16ms----|----16ms----|----16ms----| (smooth 60fps)
|----25ms----|--JANK--|-12ms-|         (janky - dropped frame)
```

## Frame Rate Targets

### 60 FPS - Standard Mobile Target

Most mobile devices have 60Hz displays:

```
Target: 16.67ms per frame
  - Build + Layout: ≤8ms
  - Paint + Composite: ≤8ms
```

### 120 FPS - High Refresh Rate Displays

Modern flagship devices support 120Hz:

```
Target: 8.33ms per frame
  - Build + Layout: ≤4ms
  - Paint + Composite: ≤4ms
```

This requires more aggressive optimization:

- Mandatory const constructors
- Strategic RepaintBoundary usage
- Minimal build work
- Efficient paint operations

### Measuring Frame Time

Use DevTools Performance view to measure:

```dart
// Custom timeline events
import 'dart:developer';

void performExpensiveOperation() {
  Timeline.startSync('ExpensiveOperation');

  // Do work

  Timeline.finishSync();
}
```

View results in DevTools Timeline tab to identify bottlenecks.

## Impeller Rendering Engine

### What is Impeller?

Impeller is Flutter's new rendering runtime that replaces Skia on supported platforms. It precompiles shaders at build time instead of runtime, eliminating first-frame jank.

### Key Differences from Skia

| Aspect | Skia (Legacy) | Impeller (Modern) |
|--------|---------------|-------------------|
| **Shader Compilation** | Runtime (causes jank) | Build-time (predictable) |
| **Pipeline State** | On-demand | Pre-built |
| **Caching** | Automatic, opaque | Explicit control |
| **Instrumentation** | Limited | Built-in tagging |
| **Concurrency** | Limited | Multi-threaded |

### Platform Support

**iOS**:
```bash
# Default since Flutter 3.10
# No fallback - Impeller only
flutter build ios
```

**Android**:
```bash
# Default on API 29+ with Vulkan support
# Automatically falls back to OpenGL on older devices
flutter build apk
```

To disable Impeller (debugging only):
```xml
<!-- AndroidManifest.xml -->
<application>
  <meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
</application>
```

**macOS** (Experimental):
```xml
<!-- Info.plist -->
<key>FLTEnableImpeller</key>
<true />
```

Or via command line:
```bash
flutter run --enable-impeller
```

### Performance Benefits

1. **Predictable Frame Times**: No runtime shader compilation
2. **Smooth First Frames**: Shaders ready before first use
3. **Better Battery Life**: Less CPU work during rendering
4. **Improved Tooling**: Frame capture without performance impact

### Shader Precompilation

Impeller compiles shaders during engine build:

```
Engine Build Time:
  - All shaders compiled to Metal (iOS)
  - All shaders compiled to Vulkan/OpenGL (Android)
  - Pipeline state objects created

Runtime:
  - Zero shader compilation
  - Immediate rendering
  - No jank
```

### Reporting Impeller Issues

Include in bug reports:
- Device chip info (Apple A-series, Snapdragon, etc.)
- Screenshots/videos of visual issues
- Performance trace from DevTools
- Minimal reproducible example

Tag issues: `[Impeller]`

## RepaintBoundary Optimization

### What is RepaintBoundary?

RepaintBoundary creates a separate compositing layer, isolating repaints to prevent unnecessary work in other parts of the UI.

### When to Use RepaintBoundary

Use RepaintBoundary when:

1. **Expensive CustomPaint widgets**: Complex drawing operations
2. **Animated widgets**: Only the animated portion repaints
3. **List items**: Prevent one item repaint affecting others
4. **Static content**: Content that rarely changes

### Basic Usage

```dart
// Isolate expensive paint operation
RepaintBoundary(
  child: CustomPaint(
    painter: ComplexChartPainter(data),
    size: Size(300, 200),
  ),
)
```

### RepaintBoundary in Lists

Prevent cascading repaints in lists:

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: ComplexListItem(
        item: items[index],
      ),
    );
  },
)
```

Without RepaintBoundary, updating one list item can trigger repaints in visible neighbors.

### RepaintBoundary with Animations

Isolate animated content:

```dart
class AnimatedCard extends StatefulWidget {
  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Static header doesn't repaint
        const ExpensiveHeader(),

        // Only animated part repaints
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + _controller.value * 0.1,
                child: child,
              );
            },
            child: const Card(
              child: Text('Animated Content'),
            ),
          ),
        ),

        // Static footer doesn't repaint
        const ExpensiveFooter(),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Debugging RepaintBoundary

Enable repaint rainbow:

```dart
import 'package:flutter/rendering.dart';

void main() {
  debugRepaintRainbowEnabled = true;
  runApp(MyApp());
}
```

This overlays colors on repainting regions. Areas changing color frequently are repainting often.

### RepaintBoundary Trade-offs

**Benefits**:
- Isolates repaints
- Reduces paint work
- Improves frame times

**Costs**:
- Creates separate layer (memory overhead)
- Compositing cost
- Can hurt performance if overused

**Guidelines**:
- Use for genuinely expensive paint operations
- Don't wrap every widget
- Profile to confirm benefit

### Checking Layer Performance

Enable layer checkerboard in DevTools:

```dart
debugPaintLayerBordersEnabled = true;
```

Excessive layers indicate overuse of RepaintBoundary or other layer-creating widgets.

## Shader Compilation and Jank

### Understanding Shader Jank

In legacy Skia renderer, shaders compile on first use, causing noticeable stutter:

```
First frame with effect:
  - Compile shader: 50-200ms (JANK!)
  - Render frame: 10ms
  Total: 60-210ms (multiple dropped frames)

Subsequent frames:
  - Use cached shader: 0ms
  - Render frame: 10ms
  Total: 10ms (smooth)
```

### Impeller Solution

Impeller eliminates shader jank by precompiling:

```
Build time:
  - All shaders compiled
  - Pipeline states created

Runtime (all frames):
  - Use precompiled shader: 0ms
  - Render frame: 10ms
  Total: 10ms (always smooth)
```

### Legacy Skia Workarounds

If using legacy Skia (older Android devices):

#### Shader Warmup

```dart
import 'package:flutter/rendering.dart';

Future<void> warmupShaders() async {
  final canvas = Canvas(
    PictureRecorder(),
    Rect.fromLTWH(0, 0, 100, 100),
  );

  // Trigger shader compilation
  final paint = Paint()..color = Colors.blue;
  canvas.drawCircle(Offset(50, 50), 40, paint);

  // Apply effects
  paint
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5)
    ..imageFilter = ImageFilter.blur(sigmaX: 5, sigmaY: 5);

  canvas.drawCircle(Offset(50, 50), 40, paint);
}

// Call during splash screen
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await warmupShaders();
  runApp(MyApp());
}
```

#### ShaderWarmUp Class

```dart
import 'package:flutter/scheduler.dart';

class MyShaderWarmUp extends ShaderWarmUp {
  @override
  Future<bool> warmUpOnCanvas(Canvas canvas) async {
    // Draw all effects used in your app
    final paint = Paint();

    // Blur
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRect(Rect.fromLTWH(0, 0, 100, 100), paint);

    // Shadow
    canvas.drawShadow(
      Path()..addRect(Rect.fromLTWH(0, 0, 100, 100)),
      Colors.black,
      5.0,
      true,
    );

    return true;
  }
}

// Usage
void main() {
  SchedulerBinding.instance.scheduleWarmUpFrame();
  runApp(MyApp());
}
```

## Opacity and Clipping Performance

### Opacity Performance Issues

The `Opacity` widget is expensive because it:

1. Allocates an offscreen buffer
2. Renders child into buffer
3. Composites buffer with opacity
4. Discards buffer

This happens every frame during animations.

### Opacity Alternatives

```dart
// BAD - Expensive Opacity widget
Opacity(
  opacity: _animation.value,
  child: ExpensiveWidget(),
)

// GOOD - AnimatedOpacity (optimized internally)
AnimatedOpacity(
  opacity: _visible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 300),
  child: ExpensiveWidget(),
)

// GOOD - FadeTransition with AnimationController
FadeTransition(
  opacity: _animation,
  child: ExpensiveWidget(),
)

// GOOD - Direct color with opacity for simple widgets
Container(
  color: Colors.blue.withOpacity(0.5), // Better than Opacity wrapper
  child: Text('Hello'),
)

// GOOD - For images
FadeInImage.memoryNetwork(
  placeholder: kTransparentImage,
  image: 'https://example.com/image.jpg',
)
```

### When Opacity is Acceptable

Static opacity (not animated):

```dart
// OK for non-animated opacity
const Opacity(
  opacity: 0.5,
  child: Icon(Icons.star),
)
```

But still prefer direct color modification:

```dart
// Better
Icon(Icons.star, color: Colors.yellow.withOpacity(0.5))
```

### Clipping Performance

Clipping is expensive, especially in animations:

```dart
// EXPENSIVE - Clips every frame during animation
AnimatedContainer(
  duration: Duration(seconds: 1),
  width: _expanded ? 200 : 100,
  height: 100,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.network('url'),
  ),
)

// BETTER - Use borderRadius without clipping
AnimatedContainer(
  duration: Duration(seconds: 1),
  width: _expanded ? 200 : 100,
  height: 100,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    image: DecorationImage(
      image: NetworkImage('url'),
      fit: BoxFit.cover,
    ),
  ),
)
```

### ClipPath Alternatives

```dart
// EXPENSIVE
ClipPath(
  clipper: MyCustomClipper(),
  child: Container(color: Colors.blue),
)

// BETTER - Use CustomPaint instead
CustomPaint(
  painter: MyCustomPainter(), // Draws shape directly
  child: Container(),
)
```

### Debugging Clipping

Enable checkerboard for offscreen layers:

```dart
import 'package:flutter/rendering.dart';

void main() {
  debugPaintLayerBordersEnabled = true;
  runApp(MyApp());
}
```

Gold borders indicate saveLayer() calls (from Opacity, ClipRect, etc.).

## List and Grid Rendering

### Lazy Building is Essential

Never build all list items upfront:

```dart
// BAD - Builds all 10,000 items immediately
ListView(
  children: List.generate(
    10000,
    (i) => ListTile(title: Text('Item $i')),
  ),
)

// GOOD - Only builds visible items
ListView.builder(
  itemCount: 10000,
  itemBuilder: (context, index) {
    return ListTile(title: Text('Item $index'));
  },
)
```

### ListView.builder Performance

```dart
ListView.builder(
  // Total items
  itemCount: items.length,

  // Only called for visible items
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: ListItem(items[index]),
    );
  },

  // Optimize scroll performance
  cacheExtent: 100, // Pixels to cache above/below
)
```

### GridView.builder

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.0,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return RepaintBoundary(
      child: GridItem(items[index]),
    );
  },
)
```

### CustomScrollView with Slivers

For complex scrolling layouts:

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(
      expandedHeight: 200,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Title'),
      ),
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListItem(items[index]),
        childCount: items.length,
      ),
    ),
    SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => GridItem(items[index]),
        childCount: items.length,
      ),
    ),
  ],
)
```

### Infinite Scrolling

Implement pagination for large datasets:

```dart
class InfiniteList extends StatefulWidget {
  @override
  State<InfiniteList> createState() => _InfiniteListState();
}

class _InfiniteListState extends State<InfiniteList> {
  final List<String> items = List.generate(20, (i) => 'Item $i');
  final ScrollController _controller = ScrollController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      items.addAll(List.generate(20, (i) => 'Item ${items.length + i}'));
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      itemCount: items.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Center(child: CircularProgressIndicator());
        }
        return ListTile(title: Text(items[index]));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Avoid Intrinsics

Intrinsics force double layout passes:

```dart
// EXPENSIVE - Calculates intrinsic sizes
IntrinsicHeight(
  child: Row(
    children: [
      Expanded(child: Text('Long text')),
      Expanded(child: Text('Short')),
    ],
  ),
)

// BETTER - Use explicit sizing
Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Expanded(child: Text('Long text')),
    Expanded(child: Text('Short')),
  ],
)
```

## Visual Debugging Tools

### DevTools Performance Overlay

Enable in DevTools or programmatically:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      showPerformanceOverlay: true,
      home: MyApp(),
    ),
  );
}
```

Shows:
- GPU thread time (top graph)
- UI thread time (bottom graph)
- Red bars indicate dropped frames

### Repaint Rainbow

```dart
import 'package:flutter/rendering.dart';

void main() {
  debugRepaintRainbowEnabled = true;
  runApp(MyApp());
}
```

Repainting areas flash different colors. Rapid color changes indicate frequent repaints.

### Layer Borders

```dart
debugPaintLayerBordersEnabled = true;
```

Shows:
- Blue borders: Compositing layers
- Gold borders: Offscreen layers (saveLayer calls)

### Size Inspector

```dart
debugPaintSizeEnabled = true;
```

Shows:
- Bounding boxes
- Baseline alignment
- Padding

### Checkerboard Offscreen Layers

In DevTools Performance view, enable "Checkerboard offscreen-rendered pictures."

Gold checkerboard indicates expensive offscreen rendering from:
- Opacity widget
- ShaderMask
- ColorFilter
- ClipPath
- BackdropFilter

## Advanced Rendering Techniques

### Custom RenderObject

For ultimate control, create custom RenderObject:

```dart
class MyRenderBox extends RenderBox {
  @override
  void performLayout() {
    // Custom layout logic
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final paint = Paint()..color = Colors.blue;
    canvas.drawRect(offset & size, paint);
  }
}

class MyWidget extends LeafRenderObjectWidget {
  @override
  RenderObject createRenderObject(BuildContext context) {
    return MyRenderBox();
  }
}
```

### SaveLayer Optimization

Avoid saveLayer when possible:

```dart
// EXPENSIVE - Uses saveLayer
canvas.saveLayer(bounds, paint);
canvas.drawImage(image, offset, Paint());
canvas.restore();

// BETTER - Direct painting when possible
canvas.drawImage(image, offset, paint);
```

### Rasterization Caching

For complex static content:

```dart
RepaintBoundary(
  child: Opacity(
    opacity: 1.0,
    child: ComplexStaticWidget(),
  ),
)
```

The RepaintBoundary + Opacity combination causes rasterization caching.

### Golden Tests for Rendering

Ensure rendering correctness:

```dart
testWidgets('Golden test', (tester) async {
  await tester.pumpWidget(MyWidget());
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('my_widget.png'),
  );
});
```

### Frame Callback Optimization

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();

    // Schedule work after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Work that should happen after first frame
      _initialize();
    });
  }

  void _initialize() {
    // Expensive initialization
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Best Practices Summary

1. **Use Impeller**: Enable by default on supported platforms
2. **Strategic RepaintBoundary**: Isolate expensive paint operations
3. **Avoid Opacity widget**: Use AnimatedOpacity or direct color modification
4. **Minimize Clipping**: Especially during animations
5. **Lazy Load Lists**: Always use builder patterns
6. **Profile Regularly**: Use DevTools Performance view
7. **Enable Visual Debugging**: Repaint rainbow and layer borders during development
8. **Target 60fps Minimum**: 16ms per frame, aim for 8ms on modern devices
9. **Watch for Shader Jank**: Impeller eliminates this, but be aware on legacy devices
10. **Optimize Paint Operations**: Custom RenderObjects for complex scenarios

Rendering performance requires balancing build complexity, paint operations, and compositing costs. Profile your specific use cases to identify bottlenecks, then apply targeted optimizations. Impeller makes many traditional optimizations unnecessary, but understanding the rendering pipeline remains valuable for advanced scenarios.
