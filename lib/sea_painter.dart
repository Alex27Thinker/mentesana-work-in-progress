// Mentesana — inner water field.
// CustomPainter port of draw()/waveY()/waveCurv() from src/main.js.
// No stars, clouds, sun, or forecast imagery: the upper space is atmosphere,
// not outdoor weather. Arousal changes the amount and pace of movement.
// Valence changes its character, never its worth.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'mood_palette.dart';

/// Mutable render state driven by the selector's ticker.
/// The visual field follows the cursor with soft inertia, preserving a
/// continuous gradient (see MoodSelectorScreen._onTick).
class SeaFieldModel extends ChangeNotifier {
  double t = 0;
  double visualV = 0;
  double visualA = 0;
  /// Wind: a steady directional drift on the water, -1 (left/offshore) … +1
  /// (right/onshore). Drives a constant lean in the swell and chop; gusts are
  /// derived from [t] and arousal so the field never blows perfectly steady.
  double wind = 0;
  bool reduced = false;

  void bump() => notifyListeners();
}

class SeaPainter extends CustomPainter {
  SeaPainter({
    required this.model,
    required this.foamX,
    required this.foamLayer,
  }) : super(repaint: model);

  final SeaFieldModel model;

  // Foam samples are attached to specific wave layers, so activity follows the
  // water's actual crests rather than appearing as free-floating particles.
  final List<double> foamX;
  final List<int> foamLayer;

  // Reusable path objects — allocated once, reset each frame to reduce GC load
  // from creating ~40–70 Path instances per frame (see flutter-performance skill).
  final List<Path> _silhouettePaths = List.generate(4, (_) => Path());
  final List<Path> _crestPaths = List.generate(4, (_) => Path());
  final Path _markPath = Path();
  final Path _streakPath = Path();

  static Color _mix(Color a, Color b, double t) =>
      Color.lerp(a, b, t.clamp(0.0, 1.0))!;

  /// Arousal changes the amount and pace of movement.
  /// Valence changes its character, never its worth.
  /// [wind] is a steady directional drift (-1…1); gusts are derived from [t]
  /// and arousal so the field never blows perfectly steady.
  static double waveY(double x, double t, int layer, double energy,
      double valence, double breathe, double h, double horizonY,
      [double wind = 0]) {
    // First movement is already present inside the dissolve zone; no static horizon is drawn.
    final base = horizonY - 12 + layer * (h - horizonY) / 5.15;
    final coherence = (valence + 1) / 2, layering = 1 - coherence;
    // Arousal lifts amplitude; unpleasant weather (low valence) runs a touch
    // taller and more restless, pleasant weather settles lower and longer.
    final amp = (3.15 + layer * 2.9) *
        (.25 + 1.38 * energy) *
        breathe *
        (1 + .35 * layering);
    final k1 = .009 + .010 * energy;
    // Cross-wave frequency opens up sharply as weather fractures (low valence):
    // the water reads clearly choppier. High valence keeps it long and coherent.
    final k2 = (.017 + .014 * energy) * (1 + .85 * layering);
    final k3 = (.029 + .022 * energy) * (1 - .11 * layering);
    final speed = (.11 + 1.05 * energy) * (.62 + layer * .12);

    // Wind: a steady lean plus slow, irregular gusts. Gusts grow with arousal
    // and with fractured weather, so a restless sea is also a gusty one. The
    // wind pushes the wave phase (crests travel downwind) and tilts the whole
    // layer, deeper layers leaning a touch more — like fetch building.
    final gust = wind *
        (.6 +
            .4 * math.sin(t * (.25 + .5 * energy) + layer * 1.7) +
            .25 * math.sin(t * (.7 + .9 * energy) + layer * 4.3)) *
        (1 + .5 * layering);
    // Horizontal advection: the stronger the wind, the faster crests travel
    // sideways. This is what makes the wave direction visibly follow the wind.
    final windPhase = x * .022 * gust + t * speed * gust * 2.2;
    final main = x * k1 + t * speed + layer * (1.15 + coherence * 1.12) + windPhase;

    // Organic swell: a few incommensurate octaves summed per layer, each with
    // its own drift, so the surface never repeats on a clean period. This is
    // what keeps the water from reading as a synthetic sine.
    final swell = math.sin(main) * .68 -
        math.cos(main * 2 + layer * .7) * (.045 + .115 * energy) +
        math.sin(main * 2.37 + t * speed * .31 + layer * 1.9) * (.03 + .05 * energy) +
        math.sin(main * 4.13 - t * speed * .22 + layer * 3.1) * (.015 + .03 * energy);

    // Cross-chop grows strongly with fractured weather; its phase tumbles
    // faster there, so unpleasant water visibly breaks apart. Two offset
    // octaves keep the chop from looking like a single ruled line. Wind carries
    // the chop downwind too.
    final cross = (math.sin(x * k2 -
                t * speed * (.34 + 1.1 * layering) +
                layer * (2 + layering * 1.4) +
                windPhase * 1.4) +
            .5 *
                math.sin(x * k2 * 1.7 +
                    t * speed * (.5 + 1.3 * layering) +
                    layer * 3.3 +
                    windPhase * 1.4)) *
        (.05 + .55 * layering);
    // Coherent braid is the signature of calm, pleasant water; it all but
    // vanishes when the weather is unpleasant, leaving the surface unbraided.
    final braid = math.sin(x * k3 +
            t * speed * (.55 + .22 * coherence) +
            layer * (.65 + coherence * .8)) *
        (.04 + .30 * coherence);
    // Arousal adds a fine, quick, irregular ripple that sharpens crests
    // without changing their worth — restless water, not angry water.
    final ripple = (math.sin(x * (.05 + .04 * energy) + t * speed * 2.4) +
            .4 * math.sin(x * (.11 + .07 * energy) - t * speed * 3.1)) *
        (.02 + .09 * energy) *
        (1 - .4 * coherence);
    // A constant, gentle tilt from the mean wind — the sea leans the way it blows.
    final lean = wind * (2.5 + 4 * layer) * (1 - .3 * coherence);
    return base + lean + amp * (swell + cross + braid + ripple);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    // This is an emergence zone for water, not a literal horizon line.
    final horizonY = h * .48;

    final t = model.t;
    final visualV = model.visualV, visualA = model.visualA;
    final energy = (visualA + 1) / 2;
    final breathe =
        model.reduced ? 1.0 : 1 + .035 * math.sin(t * 2 * math.pi / 5.5);
    final atmosphere = kSky.bilerp(visualV, visualA);
    final seaCol = kSea.bilerp(visualV, visualA);
    final valence = visualV;
    final coherence = (visualV + 1) / 2, layering = 1 - coherence;
    final chromaPulse =
        model.reduced ? 0.0 : .045 * math.sin(t * .22 + visualV * 1.7);

    double wy(double x, int layer) =>
        waveY(x, t, layer, energy, valence, breathe, h, horizonY, model.wind);

    // Upper field: diffuse mental space with moving colour, deliberately not a literal sky.
    final driftX = w * (.18 + .12 * math.sin(t * .11));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(driftX, 0),
          Offset(w - driftX * .35, h),
          [
            _mix(atmosphere[0], atmosphere[1], math.max(0, .12 + chromaPulse)),
            _mix(atmosphere[0], atmosphere[1], .72),
            _mix(atmosphere[1], seaCol[0], .50),
          ],
          [0, .52, 1],
        ),
    );

    // Two soft colour pools travel slowly through the field; these are light in water, not sun or clouds.
    final hazeX =
        w * (.22 + coherence * .50) + math.sin(t * .12) * (7 + energy * 10);
    final pool = _mix(atmosphere[1], seaCol[0], .25);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(hazeX, h * .42),
          w * .76,
          [
            pool.withValues(alpha: .12 + .06 * energy),
            _mix(atmosphere[0], atmosphere[1], .5)
                .withValues(alpha: .045 + .025 * layering),
            pool.withValues(alpha: 0),
          ],
          [0, .54, 1],
        ),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w - hazeX * .65, h * .70),
          w * .62,
          [
            _mix(seaCol[0], atmosphere[0], .42)
                .withValues(alpha: .055 + .025 * coherence),
            seaCol[0].withValues(alpha: 0),
          ],
          [0, 1],
        ),
    );

    // Water emerges over a broad dissolve zone — there is no environmental horizon to read.
    canvas.drawRect(
      Rect.fromLTRB(0, horizonY - 150, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, horizonY - 150),
          Offset(0, h),
          [
            _mix(atmosphere[1], seaCol[0], .60).withValues(alpha: 0),
            _mix(atmosphere[1], seaCol[0], .70).withValues(alpha: .16),
            seaCol[0].withValues(alpha: .82),
            seaCol[1],
          ],
          [0, .34, .64, 1],
        ),
    );

    // Swell layers — each is a single smooth silhouette (curved through sample
    // midpoints, not straight segments). Every bit of that layer's lighting —
    // crest sheen, surface marks, foam — is clipped to its own polygon, so
    // nothing ever floats above or behind the surface that's actually painted.
    for (var layer = 0; layer < 4; layer++) {
      final depth = layer / 3;
      final col = _mix(seaCol[0], seaCol[1], .25 + .75 * depth);

      // Pre-compute wave sample points ONCE per layer — reused for both the
      // silhouette fill and the crest stroke, avoiding redundant wy() calls.
      final pts = <Offset>[];
      for (double x = -6; x <= w + 6; x += 4) {
        pts.add(Offset(x, wy(x, layer)));
      }

      // Reusable silhouette path — reset instead of allocating new Path().
      final silhouette = _silhouettePaths[layer]..reset();
      silhouette
        ..moveTo(-6, h + 4)
        ..lineTo(pts[0].dx, pts[0].dy);
      for (var i = 0; i < pts.length - 1; i++) {
        final mx = (pts[i].dx + pts[i + 1].dx) / 2;
        final my = (pts[i].dy + pts[i + 1].dy) / 2;
        silhouette.quadraticBezierTo(pts[i].dx, pts[i].dy, mx, my);
      }
      silhouette
        ..lineTo(pts.last.dx, pts.last.dy)
        ..lineTo(w + 6, h + 4)
        ..close();

      final fill = Paint();
      if (layer == 0) {
        fill.shader = ui.Gradient.linear(
          Offset(0, horizonY - 28),
          Offset(0, horizonY + 104),
          [col.withValues(alpha: 0), col.withValues(alpha: .28), col.withValues(alpha: .88)],
          [0, .42, 1],
        );
      } else {
        // Cache wy(0, layer) to avoid computing the same value twice.
        final crestY = wy(0, layer);
        fill.shader = ui.Gradient.linear(
          Offset(0, crestY - 6),
          Offset(0, crestY + 120),
          [
            _mix(col, seaCol[1], .18).withValues(alpha: .92),
            col.withValues(alpha: .86 + .06 * depth),
          ],
        );
      }
      canvas.drawPath(silhouette, fill);

      canvas.save();
      canvas.clipPath(silhouette);

      // Crest sheen — follows the same pts array, reusing pre-computed data.
      // Reusable crest path — reset instead of allocating new Path().
      final crest = _crestPaths[layer]..reset();
      crest.moveTo(pts[0].dx, pts[0].dy);
      for (var i = 0; i < pts.length - 1; i++) {
        final mx = (pts[i].dx + pts[i + 1].dx) / 2;
        final my = (pts[i].dy + pts[i + 1].dy) / 2;
        crest.quadraticBezierTo(pts[i].dx, pts[i].dy, mx, my);
      }
      canvas.drawPath(
        crest,
        Paint()
          ..style = PaintingStyle.stroke
          // Choppy, restless water (low valence / high arousal) earns a
          // brighter, slightly thicker crest; calm water keeps it whisper-thin.
          ..strokeWidth = .7 + .5 * layering + .35 * energy
          ..color = ivory(.014 +
              .020 * depth +
              .022 * energy +
              .020 * layering),
      );

      // Surface handwriting: linked light marks at one end, interwoven marks at
      // the other. Equal restraint keeps both kinds of weather dignified.
      // Reuses a single _markPath across all marks in this layer.
      final markCount = 4 + (energy * 5).round();
      for (var mark = 0; mark < markCount; mark++) {
        final seed = math.sin((mark + 1) * 91.7 + layer * 17.3);
        final mx = ((mark + .5 + seed * .24) / markCount) * w;
        final my = wy(mx, layer) + 8 + (mark % 3) * (4 + layer * 1.5);
        final len =
            coherence > .5 ? 16 + coherence * 26 : 7 + (1 - coherence) * 13;
        final tilt = coherence > .5
            ? math.sin(t * .3 + mark) * 1.5
            : math.sin(t * .65 + mark * 2.1) * 4;
        canvas.drawPath(
          _markPath
            ..reset()
            ..moveTo(mx - len / 2, my - tilt * .35)
            ..quadraticBezierTo(mx, my + tilt, mx + len / 2, my + tilt * .25),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = coherence > .5 ? .8 : .7
            ..color = ivory(.025 + .026 * energy),
        );
      }

      // Wind streaks — short surface lines that lean downwind and stretch with
      // wind strength, so the blow is visible on the water itself. They ride
      // the layer's curve and point the way the sea is travelling.
      // Reuses a single _streakPath across all streaks in this layer.
      final windMag = model.wind.abs();
      if (windMag > .04 && !model.reduced) {
        final streakCount = 3 + (windMag * 6).round();
        final dir = model.wind.sign;
        for (var s = 0; s < streakCount; s++) {
          final seed = math.sin((s + 1) * 53.3 + layer * 9.1);
          final sx = (((s + .5 + seed * .3) / streakCount) * w +
                  t * 14 * dir * (1 + energy)) %
              (w + 40) -
              20;
          final sy = wy(sx, layer) + 4 + (s % 3) * (3 + layer);
          final len = (10 + windMag * 34) * (1 - depth * .3);
          final drift = math.sin(t * .5 + s) * 2;
          canvas.drawPath(
            _streakPath
              ..reset()
              ..moveTo(sx - len / 2 * dir, sy - drift * .3)
              ..quadraticBezierTo(sx, sy + drift, sx + len / 2 * dir, sy + drift * .3),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .6 + windMag * .8
              ..color = ivory((.03 + .05 * windMag) * (1 - depth * .4)),
          );
        }
      }

      // Foam on this layer — clings only to sharply curved, breaking crests and
      // rides the wave itself, rather than drifting as independent particles.
      // Fractured weather (low valence) breaks white more easily; calm,
      // coherent water keeps its surface unbroken.
      if (energy > .3 || layering > .55) {
        final foamGain = math.min(1.0, (energy - .3) / .5 + layering * .4);
        final thresh = 3.4 - 2.6 * energy - 1.4 * layering;
        for (var i = 0; i < foamX.length; i++) {
          if (foamLayer[i] != layer) continue;
          final fx = foamX[i] * w;
          const d = 6.0;
          // Cache wy(fx, layer) — used 3× in curvature + 1× for fy.
          final fy0 = wy(fx, layer);
          final curv =
              wy(fx - d, layer) - 2 * fy0 + wy(fx + d, layer);
          final sharp = math.max(0.0, curv - thresh);
          final foaminess = math.min(1.0, sharp / 5.5);
          if (foaminess < .05) continue;
          final fy = fy0 - 2;
          final churn = .55 + .45 * math.sin(t * 1.7 + fx * .045);
          final alp = foamGain * foaminess * churn * .65;
          if (alp < .02) continue;
          // Spray is blown downwind: foam rides slightly off the crest in the
          // wind direction, more so when the wind is stronger.
          final fxw = fx + model.wind * (2 + foaminess * 4);
          canvas.drawCircle(
            Offset(fxw, fy),
            1.1 + foaminess * 1.5,
            Paint()..color = ivory(alp.clamp(0.0, 1.0)),
          );
        }
      }

      canvas.restore();
    }

    // Vignette (CSS: inset 0 0 90px rgba(6,11,18,.38)).
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      Rect.fromLTRB(-30, -30, w + 30, h + 30),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 60
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
        ..color = const Color(0xFF060B12).withValues(alpha: .38),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SeaPainter oldDelegate) => false;
}

