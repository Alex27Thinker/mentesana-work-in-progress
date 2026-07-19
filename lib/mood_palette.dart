// Mentesana — mood selector palette & language.
// Ported 1:1 from src/main.js of the Vite prototype.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sea_icons.dart';

/// One shared exhale rhythm for every breathing surface (CSS --breath / --exhale).
const kBreath = Duration(milliseconds: 5800);
const Cubic kExhale = Cubic(.22, 1, .36, 1);

const kIvory = Color(0xFFF2EEE6);
const kOro =
    Color(0xFFE8B36A); // reserved for insight moments — not used as accent here
const kInkDeep = Color(0xFF10141E);

/// Riva — the "active / selected / discipline" association (JS --riva).
/// The single accent for primary actions, selection, and nav highlight.
/// Centralized here so screens stop hardcoding 0xFF7FA89B / 0xFF9FC2B7.
const kRiva = Color(0xFF7FA89B);
const kRivaLight = Color(0xFF9FC2B7);

Color ivory([double alpha = 1]) => kIvory.withValues(alpha: alpha);

Color riva([double alpha = 1]) => kRiva.withValues(alpha: alpha);

/// Circumplex corner palettes.
/// PA = pleasant-activated (cobalt into ember; not the Oro insight accent),
/// PC = pleasant-calm (sea-glass), UA = unpleasant-activated (smoky violet/slate),
/// UC = unpleasant-calm (dense indigo/blue-violet).
class CornerPalette {
  const CornerPalette({
    required this.pa,
    required this.pc,
    required this.ua,
    required this.uc,
  });

  final List<Color> pa;
  final List<Color> pc;
  final List<Color> ua;
  final List<Color> uc;

  /// Bilinear interpolation across the circumplex corners (JS `bilerp`).
  /// No quadrant gets brighter, safer, or more desirable treatment than another.
  List<Color> bilerp(double v, double a) {
    final u = (v + 1) / 2, w = (a + 1) / 2;
    return List<Color>.generate(2, (i) {
      final top = Color.lerp(ua[i], pa[i], u)!;
      final bot = Color.lerp(uc[i], pc[i], u)!;
      return Color.lerp(bot, top, w)!;
    }, growable: false);
  }
}

/// [upper field, transition] — abstract colour atmosphere, never a forecast.
const kSky = CornerPalette(
  pa: [Color(0xFF5575B4), Color(0xFFD78F68)],
  pc: [Color(0xFF2E7778), Color(0xFF8DA985)],
  ua: [Color(0xFF6B5887), Color(0xFF7C6B95)],
  uc: [Color(0xFF303A72), Color(0xFF4C568C)],
);

/// [surface, depth].
const kSea = CornerPalette(
  pa: [Color(0xFF315F9C), Color(0xFF182449)],
  pc: [Color(0xFF276E72), Color(0xFF13354A)],
  ua: [Color(0xFF48456F), Color(0xFF1D203F)],
  uc: [Color(0xFF30386B), Color(0xFF13183A)],
);

/// The living sea's surface colour at a given mood, at [alpha]. Single source
/// of the "wear the day's weather" tint used across screens for card fills,
/// borders, dividers, and header bands.
Color seaTint(double v, double a, [double alpha = 1]) =>
    kSea.bilerp(v, a)[0].withValues(alpha: alpha);

/// The atmosphere (transition band) colour at a given mood, at [alpha].
Color skyTint(double v, double a, [double alpha = 1]) =>
    kSky.bilerp(v, a)[1].withValues(alpha: alpha);

/// Gentle, uniform card curve — the app's soft-panel radius. No hard corners.
const BorderRadius kSoftCardRadius = BorderRadius.all(Radius.circular(18));

/// v2 — a POOL OF LIGHT, not a card. The sea is the only container:
/// content areas are defined by a soft radial pool of light falling from
/// the upper-left (light in water), with no border and no hard edge.
/// Pass [tint] = seaTint(...) to wear the day's weather; omit for ivory.
/// [border] is kept for signature exceptions (defaults to 0 = none).
BoxDecoration seaCard({
  Color? tint,
  double fill = .06,
  double border = 0,
  BorderRadius? radius,
}) {
  final base = tint ?? kIvory;
  return BoxDecoration(
    borderRadius: radius ?? kSoftCardRadius,
    gradient: RadialGradient(
      center: const Alignment(-.85, -1.1),
      radius: 1.7,
      colors: [
        base.withValues(alpha: fill + .05),
        base.withValues(alpha: fill * .55),
        base.withValues(alpha: fill * .16),
      ],
      stops: const [0, .52, 1],
    ),
    border:
        border <= 0 ? null : Border.all(color: base.withValues(alpha: border)),
  );
}

/// A faint wave stroke used as a section divider — the living-sea replacement
/// for a flat 1px line. Echoes the gentle quadratic currents of the home lens.
class WaveDivider extends StatelessWidget {
  const WaveDivider({
    super.key,
    this.color,
    this.height = 12,
    this.alpha = .18,
  });

  final Color? color;
  final double height;
  final double alpha;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter:
              _WaveDividerPainter((color ?? kIvory).withValues(alpha: alpha)),
        ),
      );
}

class _WaveDividerPainter extends CustomPainter {
  const _WaveDividerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final amp = size.height * .3;
    final segs = math.max(3, (size.width / 46).round());
    final seg = size.width / segs;
    final path = Path()..moveTo(0, midY);
    for (var i = 0; i < segs; i++) {
      final cx = seg * i + seg / 2;
      final ex = seg * (i + 1);
      path.quadraticBezierTo(cx, midY + amp * (i.isEven ? -1 : 1), ex, midY);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_WaveDividerPainter old) => old.color != color;
}

double hypot(double x, double y) => math.sqrt(x * x + y * y);

/// A feeling word anchored on the circumplex.
class MoodWord {
  const MoodWord(this.word, this.v, this.a);
  final String word;
  final double v;
  final double a;
}

const kWords = <MoodWord>[
  MoodWord('steady', .10, -.05),
  MoodWord('content', .70, -.35),
  MoodWord('serene', .85, -.80),
  MoodWord('grateful', .55, -.55),
  MoodWord('hopeful', .45, .20),
  MoodWord('excited', .70, .70),
  MoodWord('energized', .35, .85),
  MoodWord('restless', -.20, .60),
  MoodWord('anxious', -.65, .75),
  MoodWord('overwhelmed', -.85, .45),
  MoodWord('frustrated', -.60, .30),
  MoodWord('heavy', -.50, -.30),
  MoodWord('drained', -.60, -.70),
  MoodWord('lonely', -.75, -.45),
  MoodWord('quiet', -.10, -.60),
  MoodWord('tender', .20, -.40),
];

/// Shades: same place on the map, different flavor — words the dot cannot reach.
/// Distance can't tell fear from anger; only naming can.
const kShades = <String, List<String>>{
  'steady': ['grounded', 'even', 'okay'],
  'content': ['satisfied', 'at ease', 'mellow'],
  'serene': ['peaceful', 'still', 'clear'],
  'grateful': ['touched', 'warm', 'humbled'],
  'hopeful': ['encouraged', 'expectant', 'open'],
  'excited': ['eager', 'thrilled', 'giddy'],
  'energized': ['charged', 'motivated', 'alive'],
  'restless': ['unsettled', 'impatient', 'fidgety'],
  'anxious': ['worried', 'afraid', 'on edge'],
  'overwhelmed': ['flooded', 'stretched', 'frantic'],
  'frustrated': ['angry', 'irritated', 'stuck'],
  'heavy': ['sad', 'weary', 'discouraged'],
  'drained': ['exhausted', 'empty', 'numb'],
  'lonely': ['unseen', 'far away', 'left out'],
  'quiet': ['muted', 'inward', 'flat'],
  'tender': ['soft', 'moved', 'wistful'],
};

/// A deliberately fuzzy interpretation: it invites recognition, never diagnosis.
List<String> feltOptions(double v, double a) {
  if (a > .35 && v > .25) {
    return [
      'charged and hopeful',
      'awake to what is possible',
      'bright, with momentum'
    ];
  }
  if (a > .35 && v < -.25) {
    return [
      'restless, not bad',
      'too much at once',
      'asking for your attention'
    ];
  }
  if (a < -.35 && v > .25) {
    return ['softly okay', 'quietly held', 'settled, with room to breathe'];
  }
  if (a < -.35 && v < -.25) {
    return [
      'quiet, but carrying a lot',
      'flat and far away',
      'low tide, still here'
    ];
  }
  if (v > .35) {
    return [
      'open, with some lift',
      'lighter than before',
      'gently moving forward'
    ];
  }
  if (v < -.35) {
    return [
      'a little closed-in',
      'not easy to name',
      'somewhere under the weather'
    ];
  }
  return [
    'somewhere in between',
    'neither here nor there',
    'still finding the shape of it'
  ];
}

/// A shared 64px screen header: a quiet backlink on the left, a centered
/// title, and an optional trailing widget on the right. Every depth screen
/// uses this so the frame stays consistent and the sea reads through behind
/// it. The backlink label defaults to 'home' (the shell's root).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backLabel = 'home',
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final String backLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 64,
        child: Row(
          children: [
            if (onBack != null)
              TextButton.icon(
                onPressed: onBack,
                icon: StrokeIcon(SeaIcons.back, size: 20, color: ivory(.6)),
                label: Text(backLabel,
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: .14 * 12,
                        color: ivory(.6))),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: ivory(.6),
                ),
              )
            else
              const SizedBox(width: 68),
            Expanded(
              child: Center(
                // v2 — the header speaks in the app's serif voice: Alice,
                // no letterspacing, a touch larger. Frames every depth
                // screen with the same quiet authority as the home lens.
                child: Text(title,
                    style: GoogleFonts.alice(
                        fontSize: 20, height: 1.2, color: ivory(.92))),
              ),
            ),
            if (trailing != null) trailing! else const SizedBox(width: 68),
          ],
        ),
      );
}

/// A card that breathes on the shared kBreath rhythm — a gentle scale/opacity
/// pulse so static panels feel like they float on the living sea rather than
/// sitting pinned. Settles to stillness under reduced motion. Wrap any
/// seaCard()/Container in this to give it life.
class BreathingCard extends StatefulWidget {
  const BreathingCard({
    super.key,
    required this.child,
    this.tint,
    this.fill = .06,
    // v2 — borderless by default: a pool of light, not a boxed card.
    this.border = 0,
    this.radius,
    this.intensity = 1,
  });

  final Widget child;
  final Color? tint;
  final double fill;
  final double border;
  final BorderRadius? radius;
  final double intensity;

  @override
  State<BreathingCard> createState() => _BreathingCardState();
}

class _BreathingCardState extends State<BreathingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: kBreath);

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    // Animation starts in didChangeDependencies where MediaQuery is available.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced) {
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
    final deco = seaCard(
      tint: widget.tint,
      fill: widget.fill,
      border: widget.border,
      radius: widget.radius,
    );
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _reduced ? .5 : _ctrl.value;
        // A barely-there breath: ±1.2% scale and a soft opacity lift.
        final scale = 1 + (t - .5) * .024 * widget.intensity;
        final opacity = .92 + t * .08 * widget.intensity;
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Container(decoration: deco, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
