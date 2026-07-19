// Mentesana — Sea Animation Manager (v2: one water column).
// Owns the ambient sea field model, the ticker lifecycle, foam state,
// mood-to-colour interpolation — and, new in v2, the global DEPTH of the
// water column plus an injected mood source. The former private
// `_applyMoodAtmosphere` was a no-op that could not be overridden from
// another library, which silently severed the mood → sea coupling after
// extraction; `moodSource` restores it properly.
// The sea is a living character — this manager keeps it breathing.

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../sea_painter.dart';

/// The day's atmosphere — valence/arousal in the field model's own units
/// (both -1 … 1). Weather, never a verdict.
typedef MoodAtmosphere = ({double valence, double arousal});

/// Manages the ambient sea animation — field model, ticker, foam,
/// mood-driven colour interpolation, and the global depth of the column.
///
/// Reactive signals any screen can feed:
///   * [scrollDrift] — a small parallax input from a scrolling surface,
///     heavily damped so the wave phase/horizon only nudges a few px.
///   * [ripple]      — a one-shot expanding wave ring from a point on
///     the sea (e.g. fired from the journal keep button's position).
///   * [setDepth]    — how far below the surface the visible screen sits
///     (0 … 1). Eased with quiet inertia; read by the shell's sea layer,
///     depth veil and grain. Snaps under reduced motion.
/// All are no-ops / instant under reduced motion.
class SeaManager with ChangeNotifier {
  final SeaFieldModel model = SeaFieldModel();
  Ticker? _ticker;
  TickerProvider? _vsync;

  final math.Random rand = math.Random(7);
  late final List<double> foamX = List.generate(60, (_) => rand.nextDouble());
  late final List<int> foamLayer = List.generate(60, (_) => rand.nextInt(5));

  bool _reduced = false;
  bool get reduced => _reduced;

  /// The damped target [scrollDrift] eases toward; decays to 0 when a
  /// scroll stops so the sea returns to rest.
  double _scrollTarget = 0;

  /// v2 — injected by the owner that can see the store (the shell).
  /// Called every tick; returns the atmosphere the sea should wear.
  /// When null the sea stays untinted.
  MoodAtmosphere Function()? moodSource;

  // ── Dot steering (v3) ──
  // While the mood-selector dot is active, the shared sea becomes the
  // mirror the user is stirring: full-strength v/a from the dot drives
  // the field, instead of the damped 0.55× atmosphere. releaseSea()
  // hands control back to the regular moodSource.
  bool _dotActive = false;
  double _dotV = 0;
  double _dotA = 0;

  /// Pin the visible field to the dot's current mood (v, a) until
  /// [releaseSea] is called. Idempotent — calling repeatedly just
  /// updates the target.
  void tintSea(double v, double a) {
    _dotActive = true;
    _dotV = v.clamp(-1.0, 1.0);
    _dotA = a.clamp(-1.0, 1.0);
    if (_reduced) {
      model
        ..visualV = _dotV
        ..visualA = _dotA;
      model.bump();
    }
  }

  /// Hand control back to the regular moodSource. The ticker eases the
  /// visible v/a back toward the atmosphere over the next few frames.
  void releaseSea() {
    if (!_dotActive) return;
    _dotActive = false;
  }

  // ── Depth (v2) ──
  double _depth = 0;
  double _depthTarget = 0;

  /// Current eased depth of the water column, 0 (surface) … 1 (deepest).
  double get depth => _depth;

  /// Declare how deep the visible screen sits. Eased by the ticker so
  /// navigating feels like moving water; snaps under reduced motion.
  void setDepth(double d) {
    _depthTarget = d.clamp(0.0, 1.0);
    if (_reduced) {
      _depth = _depthTarget;
      model.depth = _depth;
      notifyListeners();
    }
  }

  /// Connect to a TickerProvider (the shell's State).
  /// Call from initState / didChangeDependencies.
  void attachVsync(TickerProvider vsync) {
    _vsync = vsync;
  }

  /// Sync the reduced-motion state and start/stop the ticker accordingly.
  void syncReduced(bool reduced) {
    _reduced = reduced;
    if (reduced) {
      _ticker?.dispose();
      _ticker = null;
      _tick(const Duration(seconds: 4), settle: true);
    } else if (_ticker == null && _vsync != null) {
      _ticker = _vsync!.createTicker(_tick)..start();
    }
  }

  /// Pause the ticker (e.g. app backgrounded).
  void pause() => _ticker?.stop();

  /// Resume the ticker (e.g. app foregrounded).
  void resume() {
    if (!_reduced && _ticker != null && !_ticker!.isActive) {
      _ticker!.start();
    }
  }

  /// Feed a small parallax input from a scrolling surface. [offset] is the
  /// raw scroll offset in px (sign = direction). It is accumulated into a
  /// damped target the ticker eases the model toward a few px at a time, and
  /// the target decays back to 0 so the sea settles when scrolling stops.
  /// No-op under reduced motion.
  void scrollDrift(double offset) {
    if (_reduced) return;
    // Scale raw pixels down so even a fast scroll only nudges the sea.
    _scrollTarget = (_scrollTarget + offset * 0.02).clamp(-12.0, 12.0);
  }

  /// Fire a one-shot ripple impulse from [origin] (in the sea's own
  /// coordinate space — usually a global position converted to the sea
  /// layer's local box). The painter expands it as a soft wave ring.
  /// No-op under reduced motion.
  void ripple(Offset origin) {
    if (_reduced) return;
    model.ripples.add(SeaRipple(
      origin: origin,
      startT: model.t,
      valence: model.visualV,
      arousal: model.visualA,
    ));
  }

  void _tick(Duration elapsed, {bool settle = false}) {
    double tv = 0, ta = 0;
    // v3 — when the dot is active, the user is actively stirring the
    // mirror: skip the 0.55× ambient attenuation so the sea responds at
    // full strength to the dot's mood. releaseSea() flips this off.
    if (_dotActive) {
      tv = _dotV;
      ta = _dotA;
    } else {
      final src = moodSource?.call();
      if (src != null) {
        tv = src.valence.clamp(-1.0, 1.0);
        ta = src.arousal.clamp(-1.0, 1.0);
      }
      // The ambient field is a quiet backdrop — damp the kept weather so the
      // water at rest stays readable on every screen.
      tv *= 0.55;
      ta *= 0.55;
    }
    model
      ..t = elapsed.inMicroseconds / 1e6
      ..reduced = _reduced;
    if (settle) {
      model
        ..visualV = tv
        ..visualA = ta
        ..scrollDrift = 0
        ..depth = _depth;
      _depth = _depthTarget;
    } else {
      model
        ..visualV = model.visualV + (tv - model.visualV) * .085
        ..visualA = model.visualA + (ta - model.visualA) * .085
        // Ease the field toward the drift target a little each frame, and
        // let the target itself decay so the sea returns to rest.
        ..scrollDrift =
            model.scrollDrift + (_scrollTarget - model.scrollDrift) * .04
        ..depth = _depth;
      _scrollTarget *= .992;
      // Depth eases a touch quicker than the mood tint, so navigating
      // feels like moving water rather than waiting for water.
      final dd = (_depthTarget - _depth) * .06;
      if (dd.abs() > .00004) {
        _depth += dd;
        notifyListeners();
      }
    }
    final tw = (ta * .5 + tv * .35);
    model.wind = settle ? tw : model.wind + (tw - model.wind) * .04;
    model.bump();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
