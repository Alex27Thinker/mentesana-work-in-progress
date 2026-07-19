// Mentesana — shared motion & texture system.
// Reusable animation primitives that give every screen a coherent,
// living-sea feel. Every widget here honours reduced motion.
//
// Timing constants extend the shared kBreath/kExhale from mood_palette.dart
// into a full vocabulary: drift (slow horizontal wander), swell (medium
// ambient pulse), ripple (quick tap feedback), dissolve (lens fade), and
// surface (card entrance rise).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../mood_palette.dart';

// ─────────────────────── Timing Constants ───────────────────────

/// Slow horizontal drift — for floating elements (bubbles, pebbles, shelf tools).
const kDrift = Duration(milliseconds: 11400);

/// Medium swell — for ambient motion on cards and panels.
const kSwell = Duration(milliseconds: 7400);

/// Quick tap feedback.
const kRipple = Duration(milliseconds: 400);

/// Lens dissolve duration.
const kDissolve = Duration(milliseconds: 420);

/// Surface rise — for card entrance animations.
const kSurface = Duration(milliseconds: 2000);

// ─────────────────────── Ambient Motion Primitives ───────────────────────

/// Slowly translates a child horizontally on a sine wave.
/// Use for floating elements that should drift like something carried by a
/// current — shelf tools, floating badges, decorative elements.
class DriftingPosition extends StatefulWidget {
  const DriftingPosition({
    super.key,
    required this.child,
    this.amplitude = 6.0,
    this.duration = kDrift,
  });

  final Widget child;
  final double amplitude;
  final Duration duration;

  @override
  State<DriftingPosition> createState() => _DriftingPositionState();
}

class _DriftingPositionState extends State<DriftingPosition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _ctrl.stop();
      _ctrl.value = .5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final dx = math.sin(_ctrl.value * 2 * math.pi) * widget.amplitude;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Fades and slides children in sequence with kExhale curve.
/// Each child is delayed by [staggerDelay]ms after the previous one begins.
/// Use for list items, pattern cards, and any multi-element reveal.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.children,
    this.staggerDelay = 150,
    this.verticalOffset = 24.0,
    this.itemDuration = 400,
  });

  final List<Widget> children;
  final int staggerDelay;
  final double verticalOffset;
  final int itemDuration;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final total = widget.itemDuration +
        widget.staggerDelay * (widget.children.length - 1);
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced || widget.children.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.children,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.children.length, (i) {
        final itemStart =
            (widget.staggerDelay * i) / _ctrl.duration!.inMilliseconds;
        final itemEnd = (widget.staggerDelay * i + widget.itemDuration) /
            _ctrl.duration!.inMilliseconds;
        final range = itemEnd - itemStart;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final localT = ((_ctrl.value - itemStart) / range).clamp(0.0, 1.0);
            final eased = kExhale.transform(localT);
            return Opacity(
              opacity: eased,
              child: Transform.translate(
                offset: Offset(0, widget.verticalOffset * (1 - eased)),
                child: child,
              ),
            );
          },
          child: widget.children[i],
        );
      }),
    );
  }
}

/// v2 — wraps a headline so it breathes with the sea: a barely-there
/// scale/opacity swell on the shared ~5.8s breath. Reserved for ONE
/// ambient line per screen (the greeting, the daily prompt) — more would
/// tip into gimmick. Settles to stillness under reduced motion.
class Breathing extends StatefulWidget {
  const Breathing({
    super.key,
    required this.child,
    this.intensity = 1,
  });

  final Widget child;
  final double intensity;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: kBreath);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _ctrl.stop();
      _ctrl.value = .5;
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = kExhale.transform(_ctrl.value);
        return Opacity(
          opacity: .92 + t * .08 * widget.intensity,
          child: Transform.scale(
            scale: 1 + (t - .5) * .012 * widget.intensity,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A mood-tinted gradient overlay that "wears the day's weather."
/// Use as a background for any card or panel that should feel submerged
/// in the ambient sea colour rather than sitting on a flat surface.
class MoodTintedGradient extends StatelessWidget {
  const MoodTintedGradient({
    super.key,
    this.tint,
    this.opacity = .06,
    this.child,
  });

  final Color? tint;
  final double opacity;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final base = tint ?? kIvory;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: opacity + .03),
            base.withValues(alpha: opacity * .45),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Shadow style that varies by screen depth.
/// Deeper screens (archive, calendar) get softer, more diffuse shadows;
/// shallower screens (home, journal home) get tighter shadows.
/// Creates a consistent depth hierarchy across the app.
class DepthShadow extends StatelessWidget {
  const DepthShadow({
    super.key,
    required this.depth,
    required this.child,
  });

  final double depth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final blur = 6.0 + depth * 8.0;
    final offset = 1.0 + depth * 2.0;
    final alpha = (0.12 + depth * 0.06).clamp(0.0, 0.4);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF060B12).withValues(alpha: alpha),
            blurRadius: blur,
            offset: Offset(0, offset),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────── Screen Transition ───────────────────────

/// A custom page transition that slides up from below with a fade,
/// like surfacing from deeper water. Replaces the default Material
/// PageRoute for a coherent sea-depth metaphor.
class SeaTransition extends PageRouteBuilder<void> {
  SeaTransition({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: kExhale,
              )),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: kExhale,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        );
}
