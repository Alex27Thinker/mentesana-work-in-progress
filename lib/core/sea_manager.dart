// Mentesana — Sea Animation Manager.
// Extracted from the monolithic AppShell: owns the ambient sea field model,
// the ticker lifecycle, foam state, and mood-to-colour interpolation.
// The sea is a living character — this manager keeps it breathing.

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../sea_painter.dart';

/// Manages the ambient sea animation — field model, ticker, foam, and
/// mood-driven colour interpolation. Extracted from MentesanaShell.
///
/// Also owns two optional reactive signals any screen can feed:
///   * [scrollDrift] — a small parallax input from a scrolling surface,
///     heavily damped so the wave phase/horizon only nudges a few px.
///   * [ripple]      — a one-shot expanding wave ring from a point on
///     the sea (e.g. fired from the journal keep button's position).
/// Both are no-ops under reduced motion.
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
    model.ripples.add(SeaRipple(origin: origin, startT: model.t));
  }

  void _tick(Duration elapsed, {bool settle = false}) {
    double tv = 0, ta = 0;
    // Mood atmosphere requires the store — accessed via get_it.
    // The manager doesn't own the store; it reads from it.
    _applyMoodAtmosphere((v, a) {
      tv = v;
      ta = a;
    }, settle: settle);
    model
      ..t = elapsed.inMicroseconds / 1e6
      ..reduced = _reduced;
    if (settle) {
      model
        ..visualV = tv
        ..visualA = ta
        ..scrollDrift = 0;
    } else {
      model
        ..visualV = model.visualV + (tv - model.visualV) * .085
        ..visualA = model.visualA + (ta - model.visualA) * .085
        // Ease the field toward the drift target a little each frame, and
        // let the target itself decay so the sea returns to rest.
        ..scrollDrift =
            model.scrollDrift + (_scrollTarget - model.scrollDrift) * .04;
      _scrollTarget *= .992;
    }
    final tw = (ta * .5 + tv * .35);
    model.wind = settle ? tw : model.wind + (tw - model.wind) * .04;
    model.bump();
  }

  void _applyMoodAtmosphere(void Function(double v, double a) setter,
      {bool settle = false}) {
    // This will be called from the shell which has access to the store.
    // Default: no mood tint.
    setter(0, 0);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }
}
