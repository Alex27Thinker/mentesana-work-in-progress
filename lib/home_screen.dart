// Mentesana — Home.
// 1:1 Flutter port of the prototype's Home screen: masthead, the day's
// weather, the breathing check-in lens (with mood tint that lets go over
// ~4 hours), the write invitation, the doors (archive / this week), and
// "on this day".

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '_shared/widgets/sea_motion.dart';
import 'app_store.dart';
import 'mood_palette.dart';
import 'theme.dart';

/// CSS `--nav-clearance` (92px + safe area; the shell adds the safe area).
const kNavClearance = 92.0;

const kOroHome = Color(0xFFE8B36A);

/// Home text floats over the living sea — same shadow as the CSS.
const kHomeShadow = [
  Shadow(
      offset: Offset(0, 1),
      blurRadius: 10,
      color: Color.fromRGBO(6, 11, 18, .58)),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.store,
    required this.onCheckin,
    required this.onSettings,
    required this.onWrite,
    required this.onDoor,
    this.outProgress = 0,
  });

  final AppStore store;

  /// Called after the lens finishes its 420ms dissolve.
  final VoidCallback onCheckin;
  final VoidCallback onSettings;
  final VoidCallback onWrite;

  /// 'archive' or 'insight' ("this week").
  final ValueChanged<String> onDoor;

  /// v3 — when non-null, the host (HomeToCheckinShell) sets this to
  /// fade the cluster out (1 = fully invisible). The shell passes the
  /// current value on every rebuild via its own ListenableBuilder; no
  /// AnimatedBuilder needed inside HomeScreen itself.
  final double outProgress;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _LensColors {
  const _LensColors(this.lens, this.veil, this.currents);
  final Color lens;
  final Color veil;
  final Color currents;
}

class _Ripple {
  _Ripple(this.center);
  final Offset center;
  final Key key = UniqueKey();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // sea-button-breathe (kBreath, scaled by the mood tempo), lens-shape 8s,
  // lens-current 7.4s.
  late final AnimationController _breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 5800));
  late final AnimationController _shape =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));
  late final AnimationController _currents = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 7400));

  final List<_Ripple> _ripples = [];
  bool _pressed = false;
  bool _dissolving = false;

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  TextStyle get _serif => GoogleFonts.alice(color: kIvory);

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_callSyncMotionLater);
    _callSyncMotionLater();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _callSyncMotionLater();
  }

  /// Defer [_syncMotion] to after the current build frame so we don't
  /// mutate AnimationController internals (duration setter fires
  /// listeners) while the framework is still in the build phase.
  void _callSyncMotionLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncMotion();
    });
  }

  /// JS tempo: 1 + (0.72 + 0.56 * ((a + 1) / 2) - 1) * strength.
  double _tempo() {
    final strength =
        widget.store.moodAtmosphereOn ? widget.store.lensMoodStrength() : 0.0;
    final mood = _latestMood();
    if (mood == null || strength <= 0) return 1;
    final a = mood.a ?? 0;
    return 1 + (0.72 + 0.56 * ((a + 1) / 2) - 1) * strength;
  }

  JournalEntry? _latestMood() {
    JournalEntry? mood;
    for (final e in widget.store.entries) {
      if (e.isMoodEntry && (mood == null || e.ts > mood.ts)) mood = e;
    }
    return mood;
  }

  void _syncMotion() {
    if (_reduced) {
      _breath.stop();
      _shape.stop();
      _currents.stop();
      return;
    }
    final breathMs = (5800 / _tempo()).round();
    if (_breath.duration?.inMilliseconds != breathMs || !_breath.isAnimating) {
      _breath.duration = Duration(milliseconds: breathMs);
      _breath.repeat(reverse: true);
    }
    if (!_shape.isAnimating) _shape.repeat(reverse: true);
    if (!_currents.isAnimating) _currents.repeat();
  }

  /// JS setHomeLens(): neutral Riva lens on no tint; otherwise the sea's own
  /// color at the kept mood, faded by the 4-hour strength.
  _LensColors _lensColors() {
    const neutral = _LensColors(
      kRiva,
      Color.fromRGBO(127, 168, 155, .18),
      Color.fromRGBO(242, 238, 230, .22),
    );
    final store = widget.store;
    if (!store.moodAtmosphereOn) return neutral;
    final strength = store.lensMoodStrength();
    final mood = _latestMood();
    if (mood == null || strength <= 0) return neutral;
    final v = mood.v ?? 0, a = mood.a ?? 0;
    final sea0 = kSea.bilerp(v, a)[0];
    final sky1 = kSky.bilerp(v, a)[1];
    return _LensColors(
      Color.lerp(neutral.lens, sea0, strength)!,
      Color.lerp(
          neutral.veil, sky1.withValues(alpha: .24 * strength), strength)!,
      Color.lerp(
          neutral.currents, sea0.withValues(alpha: .42 * strength), strength)!,
    );
  }

  void _tapLens() {
    if (_dissolving) return;
    HapticFeedback.lightImpact();
    setState(() => _dissolving = true);
    // v3 — ignite immediately; the parent starts the parallel fade-out
    // in the same frame. The lens's own scale dissolve runs alongside.
    widget.onCheckin();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _dissolving = false);
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_callSyncMotionLater);
    _breath.dispose();
    _shape.dispose();
    _currents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final today = store.latestMoodToday();
    final fresh = store.sessionFresh && today == null;
    final lensSize = fresh ? 124.0 : 112.0;
    final colors = _lensColors();
    final otd = store.findOnThisDay();
    final p = widget.outProgress.clamp(0.0, 1.0);

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        // CSS --home-cluster-top.
        final clusterTop = math.max(
            h * .24 + 128, math.min(h * .46 + 34, h - kNavClearance - 328));
        final lensLeft = (w - lensSize) / 2;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ---------- home cluster (faded by outProgress) ----------
            if (p < 1)
              Positioned.fill(
                child: Opacity(
                  opacity: 1 - p,
                  child: Transform.translate(
                    offset: Offset(0, 18.0 * p),
                    child: Stack(
                      children: [
                        // masthead
                        Positioned(
                          top: 30,
                          left: 26,
                          right: 26,
                          child: _masthead(),
                        ),
                        // the day's weather
                        Positioned(
                          top: h * .24,
                          left: 26,
                          right: 26,
                          child: Breathing(
                              intensity: .7, child: _homeCenter(today)),
                        ),
                        // write invitation
                        Positioned(
                          top: clusterTop + 128 + (fresh ? 12 : 0),
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onWrite,
                              child: Padding(
                                padding: const EdgeInsets.all(s8),
                                child: Text(
                                  today != null
                                      ? 'write another page'
                                      : 'a page, without a weather',
                                  style: MenteType.caption.copyWith(
                                    letterSpacing: 1.05,
                                    color: textSecondary,
                                    shadows: kHomeShadow,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // on this day
                        if (otd != null)
                          Positioned(
                            left: 26,
                            right: 26,
                            bottom: kNavClearance + 118,
                            child: _onThisDay(otd),
                          ),
                        // doors
                        Positioned(
                          left: 26,
                          right: 26,
                          bottom: kNavClearance,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _door(
                                  widget.store.t('archive'),
                                  'the sea, deeper',
                                  () => widget.onDoor('archive')),
                              _door('this week', 'a letter, on sundays',
                                  () => widget.onDoor('insight')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // ---------- ripples (under the lens) ----------
            for (final r in _ripples)
              _rippleWidget(r, Offset(lensLeft, clusterTop)),
            // ---------- the lens ----------
            Positioned(
              top: clusterTop,
              left: lensLeft,
              child: _lens(lensSize, colors, today),
            ),
          ],
        );
      }),
    );
  }

  // ---------- masthead: weekday · day number / · mentesana · ⋯ ----------
  Widget _masthead() {
    const dows = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    final now = DateTime.now();
    final dow = dows[now.weekday % 7];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dow,
                style: MenteType.caption.copyWith(
                    letterSpacing: 2.3,
                    color: textFaint,
                    shadows: kHomeShadow)),
            Text('${now.day}',
                style: _serif.copyWith(
                    fontSize: 30, color: textSecondary, shadows: kHomeShadow)),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: s4),
          child: Row(children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: textFaint),
            ),
            const SizedBox(width: 7),
            Text('mentesana',
                style: _serif.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.9,
                    color: textFaint,
                    shadows: kHomeShadow)),
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSettings,
              child: Padding(
                padding: const EdgeInsets.all(s8),
                child: Text('⋯',
                    style: MenteType.bodySerif
                        .copyWith(color: textFaint, height: 1)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ---------- status / word / sotto ----------
  Widget _homeCenter(JournalEntry? today) {
    final children = <Widget>[];
    if (today != null) {
      children.addAll([
        Text('last logged ${formatTime(today.date)}',
            textAlign: TextAlign.center,
            style: _serif.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 14.5,
                color: textSecondary,
                shadows: kHomeShadow)),
        const SizedBox(height: 6),
        Text(today.word ?? '',
            textAlign: TextAlign.center,
            style: _serif.copyWith(
                fontSize: 36, color: kIvory, shadows: kHomeShadow)),
        const SizedBox(height: 8),
        Text(
            today.tag.isNotEmpty
                ? 'last note touched ${today.tag}.'
                : 'the weather passes; the sea remains.',
            textAlign: TextAlign.center,
            style: _serif.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: textSecondary,
                shadows: kHomeShadow)),
      ]);
    } else {
      children.addAll([
        Text('no weather kept yet',
            textAlign: TextAlign.center,
            style: _serif.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 14.5,
                color: textSecondary,
                shadows: kHomeShadow)),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text('How’s the weather in your mind?',
              textAlign: TextAlign.center,
              style: _serif.copyWith(
                  fontSize: 26.5,
                  height: 1.16,
                  color: kIvory,
                  shadows: kHomeShadow)),
        ),
        const SizedBox(height: 8),
        Text('che tempo fa, dentro?',
            textAlign: TextAlign.center,
            style: _serif.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: textSecondary,
                shadows: kHomeShadow)),
      ]);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final c in children) Center(child: c)],
    );
  }

  // ---------- the lens ----------
  Widget _lens(double size, _LensColors colors, JournalEntry? today) {
    // v3 — outProgress drives the exit; _dissolving only matters when
    // the shell is not fading (p ≈ 0). This avoids double-gating during
    // the transition.
    final p = widget.outProgress.clamp(0.0, 1.0);
    final lensOp = p > 0.01 ? (1 - p) : (_dissolving ? 0.0 : 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        setState(() {
          _pressed = true;
          _ripples.add(_Ripple(d.localPosition));
        });
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _tapLens,
      child: AnimatedOpacity(
        opacity: lensOp,
        duration: Duration(milliseconds: _reduced ? 0 : 550),
        curve: kExhale,
        child: AnimatedScale(
          scale: _dissolving ? 1.8 : (_pressed ? .95 : 1),
          duration:
              Duration(milliseconds: _reduced ? 0 : (_dissolving ? 650 : 180)),
          curve: kExhale,
          child: AnimatedBuilder(
            animation: Listenable.merge([_breath, _shape, _currents]),
            builder: (context, _) {
              final m =
                  _reduced ? 0.0 : Curves.easeInOut.transform(_shape.value);
              final radius = _morphRadius(m, size);
              final breathe =
                  _reduced ? 0.0 : Curves.easeInOut.transform(_breath.value);
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: colors.veil,
                  border: Border.all(
                      color: const Color.fromRGBO(242, 238, 230, .48)),
                  boxShadow: [
                    const BoxShadow(
                        color: Color.fromRGBO(10, 24, 37, .28),
                        offset: Offset(0, 2),
                        blurRadius: 18),
                    // The breath: a ring that swells to 14px and returns.
                    BoxShadow(
                        color: colors.lens.withValues(alpha: .12),
                        spreadRadius: 14 * breathe),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Upper light pool.
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(-.12, -.36),
                            radius: .7,
                            colors: [
                              Color.fromRGBO(255, 255, 255, .16),
                              Color.fromRGBO(255, 255, 255, 0),
                            ],
                            stops: [0, .95],
                          ),
                        ),
                      ),
                      // Lower depth.
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(.12, .36),
                            radius: .95,
                            colors: [
                              Color.fromRGBO(10, 24, 37, 0),
                              Color.fromRGBO(10, 24, 37, .42),
                            ],
                            stops: [.3, 1],
                          ),
                        ),
                      ),
                      // Two slow internal currents.
                      CustomPaint(
                        painter: _LensCurrentsPainter(
                          color: colors.currents,
                          t: _reduced ? 0 : _currents.value,
                        ),
                      ),
                      // Label.
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('check in',
                                style: _serif.copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 16,
                                    color: kIvory)),
                            if (today != null)
                              Padding(
                                padding: const EdgeInsets.only(top: s4),
                                child: Text('again',
                                    style: MenteType.eyebrow.copyWith(
                                        letterSpacing: .9,
                                        color: textSecondary)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// lens-shape keyframes: the two organic border-radius states, blended.
  BorderRadius _morphRadius(double m, double size) {
    Radius r(double ax, double ay, double bx, double by) => Radius.elliptical(
          size * (ax + (bx - ax) * m) / 100,
          size * (ay + (by - ay) * m) / 100,
        );
    return BorderRadius.only(
      topLeft: r(48, 51, 52, 47),
      topRight: r(52, 48, 48, 54),
      bottomRight: r(49, 52, 53, 46),
      bottomLeft: r(51, 49, 47, 53),
    );
  }

  // ---------- pressure ring ----------
  Widget _rippleWidget(_Ripple r, Offset lensOrigin) {
    const ringSize = 14.0;
    final center = lensOrigin + r.center;
    return Positioned(
      key: r.key,
      left: center.dx - ringSize / 2,
      top: center.dy - ringSize / 2,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: _reduced ? 1 : 1550),
          curve: Curves.easeOut,
          onEnd: () {
            if (mounted) setState(() => _ripples.remove(r));
          },
          builder: (context, t, _) => Opacity(
            opacity: (.52 * (1 - t)).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: .8 + (11 - .8) * t,
              child: Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kIvory),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- doors ----------
  Widget _door(String label, String sotto, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: Color.fromRGBO(242, 238, 230, .12))),
        ),
        child: Row(
          children: [
            Text(label,
                style: _serif.copyWith(
                    fontSize: 16.5,
                    color: textSecondary,
                    shadows: kHomeShadow)),
            const Spacer(),
            Opacity(
              opacity: .75,
              child: Text(sotto,
                  style: MenteType.caption.copyWith(
                      letterSpacing: .5,
                      color: const Color(0xFF99A3B3),
                      shadows: kHomeShadow)),
            ),
            const SizedBox(width: 8),
            Text('›',
                style: MenteType.bodySerif
                    .copyWith(color: textFaint, shadows: kHomeShadow)),
          ],
        ),
      ),
    );
  }

  // ---------- on this day ----------
  Widget _onThisDay(JournalEntry e) {
    final months =
        ((DateTime.now().millisecondsSinceEpoch - e.ts) / (30 * 86400000))
            .floor();
    final ago = months <= 0
        ? 'a while back'
        : months == 1
            ? 'one month ago'
            : '$months months ago';
    return Container(
      padding: const EdgeInsets.only(top: s12),
      decoration: const BoxDecoration(
        border:
            Border(top: BorderSide(color: Color.fromRGBO(242, 238, 230, .14))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('on this day',
              style: MenteType.eyebrow.copyWith(
                  letterSpacing: .76, color: textFaint, shadows: kHomeShadow)),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '$ago, you called it '),
              TextSpan(
                  text: e.word ?? '',
                  style: const TextStyle(
                      color: kOroHome, fontStyle: FontStyle.normal)),
              TextSpan(text: e.text.isNotEmpty ? '. ${e.text}' : '.'),
            ]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _serif.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 13.5,
                height: 1.55,
                color: textSecondary,
                shadows: kHomeShadow),
          ),
        ],
      ),
    );
  }
}

/// The two slow lines drifting inside the lens (lens-current, 7.4s,
/// staggered like the CSS delays of -2.2s and -5.1s).
class _LensCurrentsPainter extends CustomPainter {
  _LensCurrentsPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // (topFraction, opacity, delaySeconds)
    const lines = [(.17, .55, 2.2), (.52, .28, 5.1)];
    for (final (top, opacity, delay) in lines) {
      final phase = ((t * 7.4 + delay) % 7.4) / 7.4;
      // translateX eases from -5% to 7% and back.
      final dx = -.05 + .12 * (.5 - .5 * math.cos(2 * math.pi * phase));
      final y = size.height * top;
      final x0 = size.width * (-.18 + dx);
      final len = size.width * 1.36;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));
      final path = Path()
        ..moveTo(x0, y + 3)
        ..quadraticBezierTo(x0 + len / 2, y - 4, x0 + len, y + 2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LensCurrentsPainter old) =>
      old.t != t || old.color != color;
}
