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

  /// An optional parallax input from screen scroll — shifts wave phase and
  /// the horizon by a few px, heavily damped. Default 0 = no effect, so the
  /// painter's existing rendering is unchanged when screens don't feed it.
  double scrollDrift = 0;

  /// Depth 0 (surface) … 1 (deepest). Set by SeaManager each tick so deeper
  /// views slow wave motion, darken colours, and suppress foam.
  double depth = 0;

  /// Eased sea-state physics (mood → wave character). Mutable instance,
  /// never replaced — advanceSeaState() eases fields toward targets.
  final SeaState sea = SeaState();

  double _lastSeaT = -1;

  /// One-shot ripple impulses the painter expands as wave rings radiating
  /// from [origin]. Empty = no effect (existing rendering unchanged).
  final List<SeaRipple> ripples = [];

  void bump() => notifyListeners();

  /// Compute target sea-state from visualV, visualA, depth and ease toward
  /// it with ~12 s inertia so mood changes feel like weather rolling in.
  void advanceSeaState() {
    final visualV = this.visualV;
    final visualA = this.visualA;
    final energy = (visualA + 1) / 2;
    final coherenceTarget = (visualV + 1) / 2;
    final layering = 1 - coherenceTarget;

    final tAmp = energy.clamp(0.0, 1.0);
    final tChop = (energy * .4 + layering * .6).clamp(0.0, 1.0);
    final tFoam = ((energy - .3) / .7 + layering * .35).clamp(0.0, 1.0);
    final tCoherence = coherenceTarget;
    final tSmooth = (visualV * .5 + .5).clamp(0.0, 1.0);
    final tWindStreaks = (energy * .85 + .15).clamp(0.0, 1.0);
    final tBreathPeriod = (5.8 + (1 - energy) * 2.2).clamp(4.0, 9.0);
    final tBreathIrreg = (energy * .5).clamp(0.0, 0.5);
    final tGlintWidth = (.15 + (visualV + 1) / 2 * .35).clamp(0.06, 0.5);
    final tGlintBright = (.04 + (visualV + 1) / 2 * .10).clamp(0.02, 0.16);
    final tGlintSteady = ((visualV + 1) / 2).clamp(0.0, 1.0);
    final tGlintBreakup = energy.clamp(0.0, 1.0);
    final tV = visualV;
    final tA = visualA;

    final dt = t - _lastSeaT;
    final snap = reduced || dt <= 0 || dt > 1.0;
    final f = snap ? 1.0 : (1 - math.exp(-dt / 12.0)).clamp(0.0, 1.0);

    sea.amp += (tAmp - sea.amp) * f;
    sea.chop += (tChop - sea.chop) * f;
    sea.foam += (tFoam - sea.foam) * f;
    sea.coherence += (tCoherence - sea.coherence) * f;
    sea.smoothness += (tSmooth - sea.smoothness) * f;
    sea.windStreaks += (tWindStreaks - sea.windStreaks) * f;
    sea.breathPeriod += (tBreathPeriod - sea.breathPeriod) * f;
    sea.breathIrreg += (tBreathIrreg - sea.breathIrreg) * f;
    sea.glintWidth += (tGlintWidth - sea.glintWidth) * f;
    sea.glintBright += (tGlintBright - sea.glintBright) * f;
    sea.glintSteady += (tGlintSteady - sea.glintSteady) * f;
    sea.glintBreakup += (tGlintBreakup - sea.glintBreakup) * f;
    sea.v += (tV - sea.v) * f;
    sea.a += (tA - sea.a) * f;

    _lastSeaT = t;
  }
}

/// A single ripple impulse on the sea — an expanding wave ring from
/// [origin], seeded at [startT] (seconds, in the field's own clock). Removed
/// by the painter once it has fully expanded and faded. No-op under reduced
/// motion (the manager never pushes one when reduced).
class SeaRipple {
  SeaRipple({
    required this.origin,
    required this.startT,
    required this.valence,
    required this.arousal,
  });
  final Offset origin;
  final double startT;
  final double valence;
  final double arousal;

  static const Duration lifetime = Duration(milliseconds: 1600);
  static const double maxRadius = 320;
}

/// Eased sea‑state physics — mutable fields that SeaFieldModel eases every
/// frame so mood changes read as weather rolling in, not as a hard cut.
class SeaState {
  double amp = 0.5;
  double chop = 0.5;
  double foam = 0.5;
  double coherence = 0.5;
  double smoothness = 0.5;
  double windStreaks = 0.3;
  double breathPeriod = 5.8;
  double breathIrreg = 0.0;
  double glintWidth = 0.25;
  double glintBright = 0.08;
  double glintSteady = 1.0;
  double glintBreakup = 0.5;
  double v = 0;
  double a = 0;
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
  final Path _glintPath = Path();

  // Reusable point lists — allocated once, cleared per frame so wave sampling
  // never allocates on the hot path.
  final List<List<Offset>> _ptsLists = List.generate(4, (_) => []);

  static Color _mix(Color a, Color b, double t) =>
      Color.lerp(a, b, t.clamp(0.0, 1.0))!;

  /// Arousal changes the amount and pace of movement.
  /// Valence changes its character, never its worth.
  /// [wind] is a steady directional drift (-1…1); gusts are derived from [t]
  /// and arousal so the field never blows perfectly steady.
  /// [sea] (optional) provides eased sea‑state; when null behaviour is
  /// identical to the pre‑v2 code.
  /// [depth] (optional) slows wave motion in deeper views.
  static double waveY(double x, double t, int layer, double energy,
      double valence, double breathe, double h, double horizonY,
      [double wind = 0,
      double scrollDrift = 0,
      SeaState? sea,
      double depth = 0]) {
    final base =
        horizonY - 12 + layer * (h - horizonY) / 5.15 + scrollDrift * 4;
    final coherence = sea != null ? sea.coherence : (valence + 1) / 2;
    final layering = 1 - coherence;
    t = t % 100000;
    final e = sea != null ? sea.amp : energy;
    final depthSlow = 1 - 0.55 * depth;
    final amp = (3.15 + layer * 2.9) *
        (.25 + 1.38 * e) *
        breathe *
        (1 + .35 * layering);
    final k1 = .009 + .010 * e;
    final k2 = (.017 + .014 * e) * (1 + .85 * layering);
    final k3 = (.029 + .022 * e) * (1 - .11 * layering);
    final speed = (.11 + 1.05 * e) * (.62 + layer * .12);

    final gust = wind *
        (.6 +
            .4 * math.sin(t * (.25 + .5 * e) + layer * 1.7) +
            .25 * math.sin(t * (.7 + .9 * e) + layer * 4.3)) *
        (1 + .5 * layering);

    final windPhase = x * .022 * gust + t * speed * depthSlow * gust * 2.2;
    final driftPhase = scrollDrift * 6;
    final main = x * k1 +
        t * speed * depthSlow +
        layer * (1.15 + coherence * 1.12) +
        windPhase +
        driftPhase;

    final swell = math.sin(main) * .68 -
        math.cos(main * 2 + layer * .7) * (.045 + .115 * e) +
        math.sin(main * 2.37 + t * speed * depthSlow * .31 + layer * 1.9) *
            (.03 + .05 * e) +
        math.sin(main * 4.13 - t * speed * depthSlow * .22 + layer * 3.1) *
            (.015 + .03 * e);

    final crossMul =
        sea != null ? (.05 + .38 * sea.chop) : (.05 + .38 * layering);
    final cross = (math.sin(x * k2 -
                t * speed * depthSlow * (.34 + 1.1 * layering) +
                layer * (2 + layering * 1.4) +
                windPhase * 1.4) +
            .5 *
                math.sin(x * k2 * 1.7 +
                    t * speed * depthSlow * (.5 + 1.3 * layering) +
                    layer * 3.3 +
                    windPhase * 1.4)) *
        crossMul;

    final braid = math.sin(x * k3 +
            t * speed * depthSlow * (.55 + .22 * coherence) +
            layer * (.65 + coherence * .8)) *
        (.04 + .30 * coherence);

    final ripple = (math
                .sin(x * (.05 + .04 * e) + t * speed * depthSlow * 2.4) +
            .4 * math.sin(x * (.11 + .07 * e) - t * speed * depthSlow * 3.1)) *
        (.02 + .09 * e) *
        (1 - .4 * coherence);

    final lean = wind * (2.5 + 4 * layer) * (1 - .3 * coherence);

    var y = base + lean + amp * (swell + cross + braid + ripple);

    if (sea != null && sea.smoothness < 0.6) {
      final noiseScale = (0.6 - sea.smoothness) / 0.6 * 3;
      y += math.sin(x * .17 + t * .7) *
          math.sin(t * .43 + layer * 1.3) *
          noiseScale;
    }

    return y;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (w <= 0 || h <= 0) return;
    final horizonY = h * .48;

    model.advanceSeaState();

    final t = model.t;
    final visualV = model.visualV, visualA = model.visualA;
    final energy = (visualA + 1) / 2;
    final breathe = model.reduced
        ? 1.0
        : 1 +
            .04 * math.sin(t * 2 * math.pi / model.sea.breathPeriod) +
            model.sea.breathIrreg *
                .025 *
                math.sin(
                    t * 2 * math.pi / (model.sea.breathPeriod * .71) + 1.2);
    final atmosphere = kSky.bilerp(visualV, visualA);
    final seaCol = kSea.bilerp(visualV, visualA);
    final valence = visualV;
    final coherence = (visualV + 1) / 2, layering = 1 - coherence;
    final chromaPulse =
        model.reduced ? 0.0 : .045 * math.sin(t * .22 + visualV * 1.7);

    // Depth murk: lerp sea & atmosphere colours toward kInkDeep.
    final dMurk = model.depth.clamp(0.0, 1.0);
    final foamFade = (1 - dMurk / .5).clamp(0.0, 1.0);
    final Color surface =
        Color.lerp(seaCol[0], const Color(0xFF10141E), dMurk * .72)!;
    final Color deep =
        Color.lerp(seaCol[1], const Color(0xFF10141E), dMurk * .82)!;
    final Color atmosDeep =
        Color.lerp(atmosphere[1], const Color(0xFF10141E), dMurk * .45)!;

    double wy(double x, int layer) => waveY(
        x,
        t,
        layer,
        energy,
        valence,
        breathe,
        h,
        horizonY,
        model.wind,
        model.scrollDrift,
        model.sea,
        model.depth);

    // Upper field: diffuse mental space with moving colour, deliberately not a literal sky.
    final driftX = w * (.18 + .12 * math.sin(t * .11));
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(driftX, 0),
          Offset(w - driftX * .35, h),
          [
            _mix(atmosphere[0], atmosDeep, math.max(0, .12 + chromaPulse)),
            _mix(atmosphere[0], atmosDeep, .72),
            _mix(atmosDeep, surface, .50),
          ],
          [0, .52, 1],
        ),
    );

    // Two soft colour pools travel slowly through the field; these are light in water, not sun or clouds.
    final hazeX =
        w * (.22 + coherence * .50) + math.sin(t * .12) * (7 + energy * 10);
    final pool = _mix(atmosDeep, surface, .25);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(hazeX, h * .42),
          w * .76,
          [
            pool.withValues(alpha: .12 + .06 * energy),
            _mix(atmosphere[0], atmosDeep, .5)
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
            _mix(surface, atmosphere[0], .42)
                .withValues(alpha: .055 + .025 * coherence),
            surface.withValues(alpha: 0),
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
            _mix(atmosDeep, surface, .60).withValues(alpha: 0),
            _mix(atmosDeep, surface, .70).withValues(alpha: .16),
            surface.withValues(alpha: .82),
            deep,
          ],
          [0, .34, .64, 1],
        ),
    );

    // Swell layers — each is a single smooth silhouette (curved through sample
    // midpoints, not straight segments). Every bit of that layer's lighting —
    // crest sheen, surface marks, foam — is clipped to its own polygon, so
    // nothing ever floats above or behind the surface that's actually painted.
    for (var layer = 0; layer < 4; layer++) {
      final layerDepth = layer / 3;
      final col = _mix(surface, deep, .25 + .75 * layerDepth);

      // Pre-compute wave sample points ONCE per layer — reused for both the
      // silhouette fill and the crest stroke, avoiding redundant wy() calls.
      // Reuses a pre-allocated list so paint() never allocates on the hot path.
      final pts = _ptsLists[layer];
      final nPts = ((w + 12) / 4).ceil() + 1;
      while (pts.length < nPts) {
        pts.add(Offset.zero);
      }
      for (var i = 0; i < nPts; i++) {
        final x = -6 + i * 4.0;
        pts[i] = Offset(x, wy(x, layer));
      }

      // Reusable silhouette path — reset instead of allocating new Path().
      final silhouette = _silhouettePaths[layer]..reset();
      silhouette
        ..moveTo(-6, h + 4)
        ..lineTo(pts[0].dx, pts[0].dy);
      for (var i = 0; i < nPts - 1; i++) {
        final mx = (pts[i].dx + pts[i + 1].dx) / 2;
        final my = (pts[i].dy + pts[i + 1].dy) / 2;
        silhouette.quadraticBezierTo(pts[i].dx, pts[i].dy, mx, my);
      }
      silhouette
        ..lineTo(pts[nPts - 1].dx, pts[nPts - 1].dy)
        ..lineTo(w + 6, h + 4)
        ..close();

      final fill = Paint();
      if (layer == 0) {
        fill.shader = ui.Gradient.linear(
          Offset(0, horizonY - 28),
          Offset(0, horizonY + 104),
          [
            col.withValues(alpha: 0),
            col.withValues(alpha: .28),
            col.withValues(alpha: .88)
          ],
          [0, .42, 1],
        );
      } else {
        final crestY = wy(0, layer);
        fill.shader = ui.Gradient.linear(
          Offset(0, crestY - 6),
          Offset(0, crestY + 120),
          [
            _mix(col, deep, .18).withValues(alpha: .92),
            col.withValues(alpha: .86 + .06 * layerDepth),
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
      for (var i = 0; i < nPts - 1; i++) {
        final mx = (pts[i].dx + pts[i + 1].dx) / 2;
        final my = (pts[i].dy + pts[i + 1].dy) / 2;
        crest.quadraticBezierTo(pts[i].dx, pts[i].dy, mx, my);
      }
      canvas.drawPath(
        crest,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 + .5 * layering + .35 * energy
          ..color =
              ivory(.014 + .020 * layerDepth + .022 * energy + .020 * layering),
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
      final windMag = model.wind.abs() * (.4 + .6 * model.sea.windStreaks);
      if (windMag > .04 && !model.reduced) {
        final streakCount = 2 + (model.sea.windStreaks * 7).round();
        final dir = model.wind.sign;
        for (var s = 0; s < streakCount; s++) {
          final seed = math.sin((s + 1) * 53.3 + layer * 9.1);
          final sx = (((s + .5 + seed * .3) / streakCount) * w +
                      t * 14 * dir * (1 + energy)) %
                  (w + 40) -
              20;
          final sy = wy(sx, layer) + 4 + (s % 3) * (3 + layer);
          final len = (10 + windMag * 34) * (1 - layerDepth * .3);
          final drift = math.sin(t * .5 + s) * 2;
          canvas.drawPath(
            _streakPath
              ..reset()
              ..moveTo(sx - len / 2 * dir, sy - drift * .3)
              ..quadraticBezierTo(
                  sx, sy + drift, sx + len / 2 * dir, sy + drift * .3),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = .6 + windMag * .8
              ..color = ivory((.03 + .05 * windMag) * (1 - layerDepth * .4)),
          );
        }
      }

      // Foam on this layer — clings only to sharply curved, breaking crests and
      // rides the wave itself, rather than drifting as independent particles.
      // Fractured weather (low valence) breaks white more easily; calm,
      // coherent water keeps its surface unbroken.
      if (energy > .3 || layering > .55) {
        final rawGain = math.min(1.0, (energy - .3) / .5 + layering * .4);
        final foamGain = rawGain * foamFade;
        if (foamGain > .01) {
          final thresh = 3.4 - 2.6 * energy - 1.4 * layering;
          for (var i = 0; i < foamX.length; i++) {
            if (foamLayer[i] != layer) continue;
            final fx = foamX[i] * w;
            const d = 6.0;
            final fy0 = wy(fx, layer);
            final curv = wy(fx - d, layer) - 2 * fy0 + wy(fx + d, layer);
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
      }

      canvas.restore();
    }

    // Ripples — one-shot expanding wave rings a screen can fire (e.g. on the
    // journal keep). Carried on the model so any screen can trigger one via
    // SeaManager.ripple(Offset), and pruned here once they have fully grown.
    // No-op under reduced motion (the manager never pushes one then) and the
    // list is empty by default, so existing rendering is unchanged.
    if (!model.reduced && model.ripples.isNotEmpty) {
      final lifetimeS = SeaRipple.lifetime.inMilliseconds / 1000.0;
      for (var i = model.ripples.length - 1; i >= 0; i--) {
        final r = model.ripples[i];
        final riEnergy = (r.arousal + 1) / 2;
        final ringCount = 1 + (riEnergy * 2).round();
        final ringSpacing = 6 - riEnergy * 4.5;
        final lifetimeScale = 1.3 - riEnergy;

        final age = t - r.startT;
        final scaledLifetime = lifetimeS * lifetimeScale;
        if (age >= scaledLifetime) {
          model.ripples.removeAt(i);
          continue;
        }
        final p = age / scaledLifetime;
        if (p >= 1 || p < 0) {
          model.ripples.removeAt(i);
          continue;
        }

        final ease = 1 - math.pow(1 - p, 3).toDouble();
        final baseRadius = ease * SeaRipple.maxRadius * (1 + riEnergy * .3);
        final alpha = ((.36 + riEnergy * .2) * (1 - p)).clamp(0.0, .56);
        final strokeW = 1.1 + (1 - riEnergy) * 1.4;

        for (var ring = 0; ring < ringCount; ring++) {
          final radius =
              (baseRadius - ring * ringSpacing).clamp(0.0, SeaRipple.maxRadius);
          if (radius < 1) continue;
          canvas.drawCircle(
            r.origin,
            radius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW
              ..color = Color.fromRGBO(242, 238, 230, alpha),
          );
        }
      }
    }

    // Glint: shimmer band of broken horizontal light below the horizon —
    // the sea's breath made visible as light on water. Skipped under reduced
    // motion; warm when valence is positive, cool when negative.
    if (!model.reduced) {
      final glintWidth = w * model.sea.glintWidth;
      final centerX = hazeX;
      final left = (centerX - glintWidth / 2).clamp(0.0, w);
      final right = (centerX + glintWidth / 2).clamp(0.0, w);
      final bandTop = horizonY + 2;
      final bandH = h * .22;

      final dashCount = 8 + (model.sea.glintBreakup * 18).round();
      final steady = model.sea.glintSteady;
      final bright = model.sea.glintBright;

      for (var d = 0; d < dashCount; d++) {
        final dy = bandTop + (d / dashCount) * bandH;
        final dashW =
            (right - left) * (.2 + .8 * (1 - model.sea.glintBreakup * .7));
        final flicker = steady < .9
            ? .55 + .45 * math.sin(t * (7 + (1 - steady) * 18) + d * 2.3)
            : 1.0;
        final alp = bright *
            .7 *
            flicker *
            (1 - (dy - bandTop) / bandH).clamp(0.0, 1.0);
        if (alp < .005) continue;

        final drift = math.sin(t * .35 + d * 1.7) * glintWidth * .15;
        final dx = left + (right - left) * ((d % 3) / 3.0) + drift;

        final glintWarm =
            _mix(atmosphere[1], surface, .35).withValues(alpha: alp);
        final glintCool =
            _mix(atmosphere[0], surface, .55).withValues(alpha: alp * .8);
        final glintCol =
            Color.lerp(glintCool, glintWarm, model.sea.glintSteady)!;

        canvas.drawPath(
          _glintPath
            ..reset()
            ..moveTo(dx - dashW / 2, dy)
            ..lineTo(dx + dashW / 2, dy),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7 + (1 - steady) * .5
            ..strokeCap = StrokeCap.round
            ..color = glintCol,
        );
      }
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
