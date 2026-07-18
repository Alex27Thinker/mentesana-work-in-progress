# Gesture Detection Reference

Comprehensive guide to Flutter's gesture detection system, including pointer events, gesture recognizers, and interaction patterns.

## Table of Contents

- [Gesture System Overview](#gesture-system-overview)
- [Pointer Events](#pointer-events)
- [GestureDetector Widget](#gesturedetector-widget)
- [Gesture Types](#gesture-types)
- [InkWell and Material Gestures](#inkwell-and-material-gestures)
- [Gesture Arena and Disambiguation](#gesture-arena-and-disambiguation)
- [Custom Gesture Recognizers](#custom-gesture-recognizers)
- [Multi-Touch Gestures](#multi-touch-gestures)
- [Platform-Specific Considerations](#platform-specific-considerations)

## Gesture System Overview

Flutter's gesture system operates on two distinct layers:

**Layer 1: Pointer Events** - Raw input data describing the location and movement of pointers (touches, mouse, stylus) on the screen.

**Layer 2: Gestures** - Semantic actions recognized from pointer event sequences (taps, drags, scales, etc.).

### Architecture

```
User Input (touch, mouse, stylus)
    ↓
Pointer Events (PointerDown, PointerMove, PointerUp, PointerCancel)
    ↓
Gesture Recognizers (compete in arena)
    ↓
Gesture Callbacks (onTap, onDrag, etc.)
    ↓
Application Response
```

### When to Use Each Layer

**Use Pointer Events** when you need:
- Raw input data without interpretation
- Custom gesture logic not covered by built-in recognizers
- Fine-grained control over input handling

**Use Gestures** (recommended) when you need:
- Standard interaction patterns (tap, drag, scale)
- Automatic gesture disambiguation
- Platform-appropriate behavior

## Pointer Events

Four types of pointer events describe the lifecycle of user interaction:

### Pointer Event Types

**PointerDownEvent**: A pointer has contacted the screen at a particular location.

**PointerMoveEvent**: A pointer has moved while in contact with the screen.

**PointerUpEvent**: A pointer has stopped contacting the screen.

**PointerCancelEvent**: Input from the pointer is no longer directed to this app.

### Listener Widget

Use the Listener widget to receive raw pointer events:

```dart
Listener(
  onPointerDown: (PointerDownEvent event) {
    print('Pointer down at ${event.position}');
  },
  onPointerMove: (PointerMoveEvent event) {
    print('Pointer moved to ${event.position}');
    print('Delta: ${event.delta}');
  },
  onPointerUp: (PointerUpEvent event) {
    print('Pointer up at ${event.position}');
  },
  onPointerCancel: (PointerCancelEvent event) {
    print('Pointer cancelled');
  },
  child: Container(
    width: 200,
    height: 200,
    color: Colors.blue,
  ),
)
```

### Pointer Event Properties

**event.position**: Global position on screen (Offset)
**event.localPosition**: Position relative to widget (Offset)
**event.delta**: Movement since last event (Offset)
**event.pressure**: Touch pressure (0.0 to 1.0)
**event.kind**: Input device type (touch, mouse, stylus, etc.)
**event.device**: Unique identifier for the input device

### Custom Drawing with Pointer Events

```dart
class DrawingCanvas extends StatefulWidget {
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        setState(() {
          _points.add(event.localPosition);
        });
      },
      onPointerMove: (event) {
        setState(() {
          _points.add(event.localPosition);
        });
      },
      onPointerUp: (event) {
        setState(() {
          _points.add(null); // Break between lines
        });
      },
      child: CustomPaint(
        painter: DrawingPainter(_points),
        size: Size.infinite,
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
```

## GestureDetector Widget

GestureDetector is the primary widget for detecting gestures. It only detects gestures for callbacks that are non-null.

### Basic Usage

```dart
GestureDetector(
  onTap: () {
    print('Tapped');
  },
  onDoubleTap: () {
    print('Double tapped');
  },
  onLongPress: () {
    print('Long pressed');
  },
  child: Container(
    width: 200,
    height: 200,
    color: Colors.blue,
    child: Center(
      child: Text('Tap me'),
    ),
  ),
)
```

### Gesture Callbacks with Details

Many gesture callbacks provide detailed information:

```dart
GestureDetector(
  onTapDown: (TapDownDetails details) {
    print('Tap down at ${details.globalPosition}');
    print('Local position: ${details.localPosition}');
  },
  onTapUp: (TapUpDetails details) {
    print('Tap up at ${details.globalPosition}');
  },
  onLongPressStart: (LongPressStartDetails details) {
    print('Long press started at ${details.globalPosition}');
  },
  onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
    print('Long press moved to ${details.globalPosition}');
    print('Offset from origin: ${details.offsetFromOrigin}');
  },
  onLongPressEnd: (LongPressEndDetails details) {
    print('Long press ended at ${details.globalPosition}');
  },
  child: // ...
)
```

### HitTestBehavior

Controls how hit-testing is performed:

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  // opaque: Child and empty space both receive events
  // translucent: Only child receives events, but doesn't block
  // deferToChild: Only child receives events (default)
  onTap: () {
    print('Tapped');
  },
  child: Container(
    width: 200,
    height: 200,
    // No color - will still receive taps with opaque behavior
  ),
)
```

## Gesture Types

### Tap Gestures

```dart
GestureDetector(
  onTapDown: (details) {
    // Pointer contacted screen (might result in tap)
    print('Position: ${details.localPosition}');
  },
  onTapUp: (details) {
    // Pointer stopped contacting screen (triggers tap)
  },
  onTap: () {
    // Tap completed successfully
  },
  onTapCancel: () {
    // Tap was cancelled (pointer moved too much)
  },
  child: // ...
)
```

### Double Tap

```dart
GestureDetector(
  onDoubleTap: () {
    // User tapped same location twice quickly
    print('Double tapped');
  },
  onDoubleTapDown: (details) {
    // Second tap started
  },
  onDoubleTapCancel: () {
    // Double tap cancelled
  },
  child: // ...
)
```

**Note**: Cannot use both `onTap` and `onDoubleTap` together effectively - onTap will delay to check for double tap.

### Long Press

```dart
GestureDetector(
  onLongPress: () {
    // Pointer remained in contact for extended period
    print('Long pressed');
  },
  onLongPressStart: (details) {
    // Long press detected, includes position
  },
  onLongPressMoveUpdate: (details) {
    // Pointer moved during long press
    print('Moved: ${details.offsetFromOrigin}');
  },
  onLongPressEnd: (details) {
    // Long press ended, includes velocity
    print('Velocity: ${details.velocity}');
  },
  onLongPressUp: () {
    // Pointer stopped contacting screen after long press
  },
  child: // ...
)
```

### Vertical Drag

```dart
GestureDetector(
  onVerticalDragStart: (DragStartDetails details) {
    // Pointer contacted, might move vertically
    print('Start position: ${details.globalPosition}');
  },
  onVerticalDragUpdate: (DragUpdateDetails details) {
    // Pointer moved vertically
    print('Delta: ${details.delta.dy}'); // Change in Y
    print('Primary delta: ${details.primaryDelta}');
  },
  onVerticalDragEnd: (DragEndDetails details) {
    // Pointer stopped contacting screen
    print('Velocity: ${details.velocity.pixelsPerSecond.dy}');
  },
  onVerticalDragCancel: () {
    // Drag was cancelled
  },
  child: // ...
)
```

### Horizontal Drag

```dart
GestureDetector(
  onHorizontalDragStart: (DragStartDetails details) {
    // Pointer contacted, might move horizontally
  },
  onHorizontalDragUpdate: (DragUpdateDetails details) {
    // Pointer moved horizontally
    print('Delta: ${details.delta.dx}'); // Change in X
  },
  onHorizontalDragEnd: (DragEndDetails details) {
    // Drag ended with velocity information
    print('Velocity: ${details.velocity.pixelsPerSecond.dx}');
  },
  child: // ...
)
```

### Pan (Multi-directional Drag)

```dart
GestureDetector(
  onPanStart: (DragStartDetails details) {
    // Pointer contacted, might move in any direction
  },
  onPanUpdate: (DragUpdateDetails details) {
    // Pointer moved in any direction
    print('Delta X: ${details.delta.dx}');
    print('Delta Y: ${details.delta.dy}');
  },
  onPanEnd: (DragEndDetails details) {
    // Pan ended with velocity
    print('Velocity: ${details.velocity.pixelsPerSecond}');
  },
  child: // ...
)
```

**Important**: Cannot use pan callbacks with horizontal or vertical drag callbacks - they conflict.

### Scale (Pinch/Zoom/Rotate)

```dart
GestureDetector(
  onScaleStart: (ScaleStartDetails details) {
    // Scaling gesture started
    print('Focal point: ${details.focalPoint}');
  },
  onScaleUpdate: (ScaleUpdateDetails details) {
    // Scale changed
    print('Scale: ${details.scale}'); // 1.0 = no change
    print('Rotation: ${details.rotation}'); // Radians
    print('Focal point: ${details.focalPoint}');
  },
  onScaleEnd: (ScaleEndDetails details) {
    // Scale gesture ended
    print('Velocity: ${details.velocity}');
  },
  child: // ...
)
```

### Practical Scale Example

```dart
class ZoomableImage extends StatefulWidget {
  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _previousScale = _scale;
        _previousOffset = _offset;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = _previousScale * details.scale;
          _offset = _previousOffset + details.focalPointDelta;
        });
      },
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_offset.dx, _offset.dy)
          ..scale(_scale),
        child: Image.asset('assets/image.png'),
      ),
    );
  }
}
```

## InkWell and Material Gestures

InkWell provides Material Design ripple effects on tap.

### Basic InkWell

```dart
InkWell(
  onTap: () {
    print('Tapped with ripple effect');
  },
  splashColor: Colors.blue.withOpacity(0.3),
  highlightColor: Colors.blue.withOpacity(0.1),
  child: Container(
    padding: EdgeInsets.all(16),
    child: Text('Tap me'),
  ),
)
```

### InkWell vs GestureDetector

**Use InkWell when**:
- You want Material Design ripple effects
- Building Material Design interfaces
- Want visual feedback without custom implementation

**Use GestureDetector when**:
- You need custom visual feedback
- Working with non-Material designs
- Need gestures beyond tap (drag, scale, etc.)

### Material Widgets with Built-in Gestures

Many Material widgets have built-in gesture support:

```dart
// IconButton
IconButton(
  icon: Icon(Icons.favorite),
  onPressed: () {
    print('Icon tapped');
  },
)

// TextButton
TextButton(
  onPressed: () {
    print('Button pressed');
  },
  child: Text('Click me'),
)

// Card with InkWell
Card(
  child: InkWell(
    onTap: () {
      print('Card tapped');
    },
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Tappable card'),
    ),
  ),
)
```

### Ink for Proper Ripples

```dart
// Correct: Ripple appears above decoration
Material(
  child: Ink(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue, Colors.purple],
      ),
    ),
    child: InkWell(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Gradient button'),
      ),
    ),
  ),
)
```

## Gesture Arena and Disambiguation

When multiple gesture recognizers overlap, Flutter uses a competitive arena to determine which gesture wins.

### How It Works

1. **Pointer down**: All interested recognizers enter the arena
2. **Pointer moves**: Recognizers evaluate the movement
3. **Elimination**: Recognizers can eliminate themselves if gesture doesn't match
4. **Declaration**: A recognizer can declare victory, eliminating all others
5. **Winner**: Last remaining recognizer handles the gesture

### Example: Horizontal vs Vertical Drag

```dart
Column(
  children: [
    // Horizontal drag wins if horizontal movement exceeds threshold
    GestureDetector(
      onHorizontalDragUpdate: (details) {
        print('Horizontal: ${details.delta.dx}');
      },
      child: Container(
        width: 200,
        height: 100,
        color: Colors.blue,
        child: GestureDetector(
          // Vertical drag wins if vertical movement exceeds threshold
          onVerticalDragUpdate: (details) {
            print('Vertical: ${details.delta.dy}');
          },
          child: Container(
            color: Colors.red,
          ),
        ),
      ),
    ),
  ],
)
```

### Controlling Arena Behavior

Use `GestureRecognizerFactoryWithHandlers` for advanced control:

```dart
RawGestureDetector(
  gestures: {
    AllowMultipleGestureRecognizer: GestureRecognizerFactoryWithHandlers<
      AllowMultipleGestureRecognizer
    >(
      () => AllowMultipleGestureRecognizer(),
      (instance) {
        instance.onTap = () {
          print('Tap');
        };
      },
    ),
  },
  child: // ...
)
```

## Custom Gesture Recognizers

Create custom gesture recognizers for specialized interaction patterns.

### Basic Custom Recognizer

```dart
class CustomGestureRecognizer extends OneSequenceGestureRecognizer {
  final VoidCallback? onCustomGesture;

  CustomGestureRecognizer({this.onCustomGesture});

  @override
  void addPointer(PointerDownEvent event) {
    // Start tracking this pointer
    startTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    // Process pointer events
    if (event is PointerMoveEvent) {
      // Check for custom gesture pattern
      if (_isCustomGesture(event)) {
        resolve(GestureDisposition.accepted);
        onCustomGesture?.call();
      }
    } else if (event is PointerUpEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  bool _isCustomGesture(PointerMoveEvent event) {
    // Implement custom gesture detection logic
    return false;
  }

  @override
  String get debugDescription => 'custom gesture';

  @override
  void didStopTrackingLastPointer(int pointer) {
    resolve(GestureDisposition.rejected);
  }
}
```

### Circle Gesture Recognizer Example

```dart
class CircleGestureRecognizer extends OneSequenceGestureRecognizer {
  final VoidCallback? onCircle;
  final List<Offset> _points = [];

  CircleGestureRecognizer({this.onCircle});

  @override
  void addPointer(PointerDownEvent event) {
    _points.clear();
    _points.add(event.localPosition);
    startTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      _points.add(event.localPosition);
    } else if (event is PointerUpEvent) {
      if (_isCircle()) {
        resolve(GestureDisposition.accepted);
        onCircle?.call();
      } else {
        resolve(GestureDisposition.rejected);
      }
      stopTrackingPointer(event.pointer);
    }
  }

  bool _isCircle() {
    if (_points.length < 10) return false;

    // Simple circle detection: check if path is roughly circular
    final center = _calculateCenter();
    final avgRadius = _calculateAverageRadius(center);
    final variance = _calculateRadiusVariance(center, avgRadius);

    return variance < 0.3; // Allow 30% variance
  }

  Offset _calculateCenter() {
    double sumX = 0, sumY = 0;
    for (final point in _points) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / _points.length, sumY / _points.length);
  }

  double _calculateAverageRadius(Offset center) {
    double sumRadius = 0;
    for (final point in _points) {
      sumRadius += (point - center).distance;
    }
    return sumRadius / _points.length;
  }

  double _calculateRadiusVariance(Offset center, double avgRadius) {
    double sumSquaredDiff = 0;
    for (final point in _points) {
      final radius = (point - center).distance;
      final diff = radius - avgRadius;
      sumSquaredDiff += diff * diff;
    }
    return (sumSquaredDiff / _points.length) / avgRadius;
  }

  @override
  String get debugDescription => 'circle';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
```

## Multi-Touch Gestures

Handle multiple simultaneous touch points.

### Tracking Multiple Pointers

```dart
class MultiTouchWidget extends StatefulWidget {
  @override
  State<MultiTouchWidget> createState() => _MultiTouchWidgetState();
}

class _MultiTouchWidgetState extends State<MultiTouchWidget> {
  final Map<int, Offset> _pointers = {};

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        setState(() {
          _pointers[event.pointer] = event.localPosition;
        });
      },
      onPointerMove: (event) {
        setState(() {
          _pointers[event.pointer] = event.localPosition;
        });
      },
      onPointerUp: (event) {
        setState(() {
          _pointers.remove(event.pointer);
        });
      },
      child: CustomPaint(
        painter: MultiTouchPainter(_pointers),
        size: Size.infinite,
      ),
    );
  }
}

class MultiTouchPainter extends CustomPainter {
  final Map<int, Offset> pointers;

  MultiTouchPainter(this.pointers);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final position in pointers.values) {
      canvas.drawCircle(position, 50, paint);
    }
  }

  @override
  bool shouldRepaint(MultiTouchPainter oldDelegate) {
    return oldDelegate.pointers != pointers;
  }
}
```

## Platform-Specific Considerations

### Mouse vs Touch

```dart
GestureDetector(
  onTapDown: (details) {
    switch (details.kind) {
      case PointerDeviceKind.mouse:
        print('Mouse click');
        break;
      case PointerDeviceKind.touch:
        print('Touch');
        break;
      case PointerDeviceKind.stylus:
        print('Stylus');
        break;
      default:
        print('Other device');
    }
  },
  child: // ...
)
```

### Hover Effects (Desktop/Web)

```dart
class HoverButton extends StatefulWidget {
  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          print('Clicked');
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Hover me'),
        ),
      ),
    );
  }
}
```

### Right-Click Context Menu

```dart
GestureDetector(
  onSecondaryTapDown: (details) {
    // Right-click or long-press on mobile
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        PopupMenuItem(child: Text('Option 1')),
        PopupMenuItem(child: Text('Option 2')),
      ],
    );
  },
  child: // ...
)
```

## Best Practices

1. **Prefer Material widgets**: Use InkWell, IconButton when appropriate
2. **Avoid gesture conflicts**: Don't mix pan with horizontal/vertical drag
3. **Provide visual feedback**: Show users their interactions are recognized
4. **Use appropriate hit test behavior**: Control what receives gestures
5. **Handle cancellation**: Always implement cancel callbacks
6. **Consider platform**: Desktop, mobile, and web have different interaction patterns
7. **Optimize performance**: Don't rebuild entire trees in gesture handlers
8. **Test on devices**: Gestures feel different on actual hardware
9. **Respect accessibility**: Provide alternative interaction methods
10. **Use velocity information**: Implement physics-based animations from gesture velocity
