# Custom Drag-and-Drop Implementation

A complete implementation of a custom drag-and-drop system with visual feedback, snap-to-grid, and reordering.

## Overview

This example demonstrates:
- Custom gesture detection for drag-and-drop
- Visual feedback during dragging
- Snap-to-grid positioning
- Item reordering
- Drop zone validation
- Animated transitions
- Multi-item support

## Complete Implementation

```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag and Drop Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DragDropDemo(),
    );
  }
}

// Main demo page
class DragDropDemo extends StatefulWidget {
  const DragDropDemo({super.key});

  @override
  State<DragDropDemo> createState() => _DragDropDemoState();
}

class _DragDropDemoState extends State<DragDropDemo> {
  final List<DraggableItem> _items = [
    DraggableItem(
      id: '1',
      color: Colors.red,
      label: 'Item 1',
      position: const Offset(50, 100),
    ),
    DraggableItem(
      id: '2',
      color: Colors.blue,
      label: 'Item 2',
      position: const Offset(150, 100),
    ),
    DraggableItem(
      id: '3',
      color: Colors.green,
      label: 'Item 3',
      position: const Offset(250, 100),
    ),
    DraggableItem(
      id: '4',
      color: Colors.orange,
      label: 'Item 4',
      position: const Offset(50, 200),
    ),
  ];

  final List<DropZone> _dropZones = [
    DropZone(
      id: 'zone1',
      label: 'Zone 1',
      rect: const Rect.fromLTWH(50, 350, 150, 150),
      acceptedColors: [Colors.red, Colors.blue],
    ),
    DropZone(
      id: 'zone2',
      label: 'Zone 2',
      rect: const Rect.fromLTWH(220, 350, 150, 150),
      acceptedColors: [Colors.green, Colors.orange],
    ),
  ];

  String? _draggedItemId;
  Offset? _draggedItemPosition;
  bool _snapToGrid = true;
  final double _gridSize = 50.0;

  void _onDragStart(String itemId, Offset position) {
    setState(() {
      _draggedItemId = itemId;
      _draggedItemPosition = position;
    });
  }

  void _onDragUpdate(Offset position) {
    setState(() {
      _draggedItemPosition = position;
    });
  }

  void _onDragEnd() {
    if (_draggedItemId == null || _draggedItemPosition == null) return;

    final item = _items.firstWhere((i) => i.id == _draggedItemId);
    final itemCenter = Offset(
      _draggedItemPosition!.dx + 40,
      _draggedItemPosition!.dy + 40,
    );

    // Check if dropped in a valid zone
    DropZone? targetZone;
    for (final zone in _dropZones) {
      if (zone.rect.contains(itemCenter)) {
        targetZone = zone;
        break;
      }
    }

    Offset finalPosition;

    if (targetZone != null && targetZone.acceptsColor(item.color)) {
      // Snap to zone center
      finalPosition = Offset(
        targetZone.rect.center.dx - 40,
        targetZone.rect.center.dy - 40,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.label} dropped in ${targetZone.label}'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      // Snap to grid or keep position
      finalPosition = _snapToGrid
          ? _snapPositionToGrid(_draggedItemPosition!)
          : _draggedItemPosition!;
    }

    setState(() {
      item.position = finalPosition;
      _draggedItemId = null;
      _draggedItemPosition = null;
    });
  }

  Offset _snapPositionToGrid(Offset position) {
    return Offset(
      (position.dx / _gridSize).round() * _gridSize,
      (position.dy / _gridSize).round() * _gridSize,
    );
  }

  void _resetPositions() {
    setState(() {
      _items[0].position = const Offset(50, 100);
      _items[1].position = const Offset(150, 100);
      _items[2].position = const Offset(250, 100);
      _items[3].position = const Offset(50, 200);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drag and Drop Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPositions,
            tooltip: 'Reset positions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Text('Snap to Grid:'),
                Switch(
                  value: _snapToGrid,
                  onChanged: (value) {
                    setState(() => _snapToGrid = value);
                  },
                ),
                const SizedBox(width: 16),
                Text('Grid Size: ${_gridSize.toInt()}px'),
              ],
            ),
          ),
          // Main canvas
          Expanded(
            child: Stack(
              children: [
                // Grid background
                if (_snapToGrid) _buildGridBackground(),
                // Drop zones
                ..._dropZones.map((zone) => _buildDropZone(zone)),
                // Draggable items
                ..._items.map((item) {
                  final isDragging = item.id == _draggedItemId;
                  final position = isDragging
                      ? _draggedItemPosition!
                      : item.position;

                  return DraggableBox(
                    key: ValueKey(item.id),
                    item: item,
                    position: position,
                    isDragging: isDragging,
                    onDragStart: (details) => _onDragStart(
                      item.id,
                      item.position,
                    ),
                    onDragUpdate: (details) => _onDragUpdate(
                      position + details.delta,
                    ),
                    onDragEnd: (details) => _onDragEnd(),
                  );
                }),
              ],
            ),
          ),
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Drag items around the canvas'),
                const Text('• Red/Blue items go in Zone 1'),
                const Text('• Green/Orange items go in Zone 2'),
                const Text('• Toggle snap-to-grid for precise positioning'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      painter: GridPainter(gridSize: _gridSize),
      size: Size.infinite,
    );
  }

  Widget _buildDropZone(DropZone zone) {
    final isDragOver = _draggedItemPosition != null &&
        _draggedItemId != null &&
        zone.rect.contains(Offset(
          _draggedItemPosition!.dx + 40,
          _draggedItemPosition!.dy + 40,
        ));

    final item = _draggedItemId != null
        ? _items.firstWhere((i) => i.id == _draggedItemId)
        : null;

    final isValidDrop = isDragOver &&
        item != null &&
        zone.acceptsColor(item.color);

    return Positioned(
      left: zone.rect.left,
      top: zone.rect.top,
      width: zone.rect.width,
      height: zone.rect.height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border.all(
            color: isValidDrop
                ? Colors.green
                : isDragOver
                    ? Colors.red
                    : Colors.grey,
            width: isValidDrop ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isValidDrop
              ? Colors.green.withOpacity(0.1)
              : isDragOver
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                zone.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accepts: ${zone.acceptedColors.map((c) => _colorName(c)).join(", ")}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _colorName(Color color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.orange) return 'Orange';
    return 'Unknown';
  }
}

// Draggable box widget
class DraggableBox extends StatelessWidget {
  final DraggableItem item;
  final Offset position;
  final bool isDragging;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  const DraggableBox({
    super.key,
    required this.item,
    required this.position,
    required this.isDragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: isDragging
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: onDragStart,
        onPanUpdate: onDragUpdate,
        onPanEnd: onDragEnd,
        child: Transform.scale(
          scale: isDragging ? 1.1 : 1.0,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDragging ? 0.3 : 0.1),
                  blurRadius: isDragging ? 12 : 4,
                  offset: Offset(0, isDragging ? 6 : 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Grid painter for background
class GridPainter extends CustomPainter {
  final double gridSize;

  GridPainter({required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize;
  }
}

// Data models
class DraggableItem {
  final String id;
  final Color color;
  final String label;
  Offset position;

  DraggableItem({
    required this.id,
    required this.color,
    required this.label,
    required this.position,
  });
}

class DropZone {
  final String id;
  final String label;
  final Rect rect;
  final List<Color> acceptedColors;

  DropZone({
    required this.id,
    required this.label,
    required this.rect,
    required this.acceptedColors,
  });

  bool acceptsColor(Color color) {
    return acceptedColors.contains(color);
  }
}
```

## Advanced Features

### 1. List Reordering with Drag-and-Drop

```dart
class ReorderableListDemo extends StatefulWidget {
  const ReorderableListDemo({super.key});

  @override
  State<ReorderableListDemo> createState() => _ReorderableListDemoState();
}

class _ReorderableListDemoState extends State<ReorderableListDemo> {
  final List<String> _items = List.generate(10, (i) => 'Item ${i + 1}');
  int? _draggedIndex;
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reorderable List')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final isDragging = _draggedIndex == index;
          final isHovering = _hoverIndex == index;

          return DragTarget<int>(
            onWillAccept: (draggedIndex) {
              setState(() => _hoverIndex = index);
              return true;
            },
            onLeave: (_) {
              setState(() => _hoverIndex = null);
            },
            onAccept: (draggedIndex) {
              setState(() {
                final item = _items.removeAt(draggedIndex);
                _items.insert(index, item);
                _draggedIndex = null;
                _hoverIndex = null;
              });
            },
            builder: (context, candidateData, rejectedData) {
              return LongPressDraggable<int>(
                data: index,
                onDragStarted: () {
                  setState(() => _draggedIndex = index);
                },
                onDragEnd: (_) {
                  setState(() {
                    _draggedIndex = null;
                    _hoverIndex = null;
                  });
                },
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _items[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _items[index],
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    top: isHovering && index < (_draggedIndex ?? -1) ? 60 : 8,
                    bottom: isHovering && index > (_draggedIndex ?? 999) ? 60 : 8,
                    left: 8,
                    right: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDragging
                        ? Colors.grey[300]
                        : isHovering
                            ? Colors.blue[100]
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isHovering ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle),
                      const SizedBox(width: 16),
                      Text(_items[index]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 2. Multi-Select Drag-and-Drop

```dart
class MultiSelectDragDrop extends StatefulWidget {
  const MultiSelectDragDrop({super.key});

  @override
  State<MultiSelectDragDrop> createState() => _MultiSelectDragDropState();
}

class _MultiSelectDragDropState extends State<MultiSelectDragDrop> {
  final Set<String> _selectedIds = {};
  final List<DraggableItem> _items = [
    // Initialize items...
  ];

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _items.map((item) {
        final isSelected = _selectedIds.contains(item.id);

        return GestureDetector(
          onTap: () => _toggleSelection(item.id),
          onPanStart: (details) {
            if (!isSelected) {
              _toggleSelection(item.id);
            }
          },
          onPanUpdate: (details) {
            setState(() {
              // Move all selected items
              for (final id in _selectedIds) {
                final selectedItem = _items.firstWhere((i) => i.id == id);
                selectedItem.position += details.delta;
              }
            });
          },
          child: Positioned(
            left: item.position.dx,
            top: item.position.dy,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.yellow, width: 3)
                    : null,
              ),
              child: Center(child: Text(item.label)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

### 3. Custom Gesture Recognizer for Complex Patterns

```dart
class CustomDragGestureRecognizer extends OneSequenceGestureRecognizer {
  final void Function(Offset)? onDragStart;
  final void Function(Offset)? onDragUpdate;
  final void Function()? onDragEnd;

  Offset? _startPosition;

  CustomDragGestureRecognizer({
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  void addPointer(PointerDownEvent event) {
    _startPosition = event.position;
    startTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      onDragStart?.call(event.position);
    } else if (event is PointerMoveEvent) {
      onDragUpdate?.call(event.position);
    } else if (event is PointerUpEvent) {
      onDragEnd?.call();
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'custom drag';

  @override
  void didStopTrackingLastPointer(int pointer) {
    resolve(GestureDisposition.rejected);
  }
}
```

## Key Concepts Demonstrated

1. **Custom Gesture Handling**: Using GestureDetector with onPan callbacks
2. **Visual Feedback**: Scale transform and shadows during drag
3. **Snap-to-Grid**: Mathematical rounding to grid coordinates
4. **Drop Zone Validation**: Color-based acceptance rules
5. **Animated Transitions**: Smooth movement when not dragging
6. **State Management**: Tracking drag state and positions
7. **Custom Painting**: Grid background with CustomPainter
8. **Hit Testing**: Checking if dropped in valid zones

This example provides a comprehensive foundation for implementing drag-and-drop functionality in Flutter applications.
