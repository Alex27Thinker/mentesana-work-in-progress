// Mentesana — the atmosphere above the water (v2).
// Two full-bleed composited layers that make the whole app read as one
// continuous water column instead of screens pasted over a backdrop:
//
//   * DepthVeil    — the water darkens and cools continuously as you
//                    descend (driven by SeaManager.depth, eased by its
//                    ticker — not a per-navigation 700ms tween).
//   * GrainOverlay — a whisper of animated film grain over every gradient
//                    surface. Kills the flat digital look; opacity scales
//                    gently with depth. Static under reduced motion.
//
// Both are IgnorePointer overlays and honour reduced motion.

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/sea_manager.dart';
import '../../theme.dart';

/// The water darkens and cools as you descend. Reads SeaManager.depth
/// (0 surface … 1 deepest), which the manager eases every tick, so the
/// veil moves with the water instead of jumping per navigation.
class DepthVeil extends StatelessWidget {
  const DepthVeil({super.key, required this.manager});

  final SeaManager manager;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: manager,
        builder: (context, _) {
          final d = manager.depth;
          if (d <= .002) return const SizedBox.shrink();
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  // Kept translucent so the mood-tinted sea reads through
                  // at every depth — darker and a touch cooler with descent.
                  const Color(0xFF060B12)
                      .withValues(alpha: (d * .34).clamp(0.0, .34)),
                  const Color(0xFF04080D)
                      .withValues(alpha: (d * .50).clamp(0.0, .50)),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

/// A whisper of animated film grain — felt, not seen. One small tiled
/// noise image, shifted a few times a second; opacity scales with depth
/// when a [manager] is provided. Static under reduced motion.
class GrainOverlay extends StatefulWidget {
  const GrainOverlay({super.key, this.manager});

  final SeaManager? manager;

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay>
    with SingleTickerProviderStateMixin {
  static ui.Image? _noise;
  static Future<ui.Image>? _noiseFuture;

  Ticker? _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  double _elapsed = 0;

  static Future<ui.Image> _makeNoise() {
    final existing = _noiseFuture;
    if (existing != null) return existing;
    final completer = Completer<ui.Image>();
    const size = 128;
    final rng = math.Random(1117);
    final pixels = Uint8List(size * size * 4);
    for (var i = 0; i < size * size; i++) {
      // Mid-grey noise, alpha carries the texture — opacity is applied at
      // draw time via a modulate colour filter.
      final v = rng.nextBool() ? 255 : 0;
      pixels[i * 4] = v;
      pixels[i * 4 + 1] = v;
      pixels[i * 4 + 2] = v;
      pixels[i * 4 + 3] = 26 + rng.nextInt(58);
    }
    ui.decodeImageFromPixels(
        pixels, size, size, ui.PixelFormat.rgba8888, completer.complete);
    return _noiseFuture = completer.future;
  }

  @override
  void initState() {
    super.initState();
    if (_noise == null) {
      _makeNoise().then((img) {
        _noise = img;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _ticker?.dispose();
      _ticker = null;
    } else {
      _ticker ??= createTicker((elapsed) {
        // ~12 texture shifts a second — grain flickers, UI doesn't rebuild.
        final s = elapsed.inMicroseconds / 1e6;
        if (s - _elapsed >= .085) {
          _elapsed = s;
          _frame.value++;
        }
      })
        ..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = _noise;
    if (img == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GrainPainter(
            image: img,
            frame: _frame,
            manager: widget.manager,
          ),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.image, required this.frame, this.manager})
      : super(repaint: Listenable.merge([frame, if (manager != null) manager]));

  final ui.Image image;
  final ValueNotifier<int> frame;
  final SeaManager? manager;

  static final math.Random _rng = math.Random(23);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final depth = manager?.depth ?? 0;
    final opacity = ui.lerpDouble(kGrainOpacity, kGrainOpacityDeep, depth)!;
    final dx = _rng.nextDouble() * image.width.toDouble();
    final dy = _rng.nextDouble() * image.height.toDouble();
    final matrix = Matrix4.translationValues(-dx, -dy, 0);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          matrix.storage,
        )
        ..colorFilter = ColorFilter.mode(
          Color.fromRGBO(242, 238, 230, opacity),
          BlendMode.modulate,
        ),
    );
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.manager != manager;
}
