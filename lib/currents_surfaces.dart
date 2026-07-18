// Mentesana — the currents surfaces.
// UI for the currents engine, woven into the living sea rather than bolted
// on: the undertow surface (a gentle observation and three micro-practices
// after a kept page), the almanac (the user's own weather patterns, breathing
// on Home), and the anchor & tide-return cards on the journal home.
//
// Every surface observes, invites, and lets go. Both exits are always
// costless; nothing is counted, streaked, or scored. All motion breathes on
// the shared kBreath rhythm and settles to stillness under reduced motion.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'currents_engine.dart';
import 'mood_palette.dart';
import 'theme.dart';

// ─────────────────────── shared small pieces ───────────────────────

Widget _pill(String label, VoidCallback onTap, {bool primary = false}) {
  final color = primary ? kRivaLight : textFaint;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: s4, vertical: s4),
      child: Text(
        label,
        style: GoogleFonts.alice(
          fontStyle: FontStyle.italic,
          fontSize: primary ? 14 : 13,
          color: color,
          decoration: TextDecoration.underline,
          decorationColor: color.withValues(alpha: primary ? .6 : .35),
        ),
      ),
    ),
  );
}

Widget _capsLabel(String text, Color color) =>
    Text(text, style: MenteType.caption.copyWith(color: color));

// ────────────────────────── the undertow ───────────────────────────────

/// The gentle surface that may rise once a page is kept: an observation about
/// a current under the page, and — only if invited — one of three small
/// practices (walking a brooding loop to one concrete moment, leaving a worry
/// with the tide, or hearing a harsh line from further out).
class UndertowSurface extends StatefulWidget {
  const UndertowSurface({
    super.key,
    required this.store,
    required this.entry,
    required this.reading,
    required this.reduced,
    required this.onClose,
  });

  final AppStore store;
  final JournalEntry entry;
  final UndertowReading reading;
  final bool reduced;
  final VoidCallback onClose;

  @override
  State<UndertowSurface> createState() => _UndertowSurfaceState();
}

class _PracticeCopy {
  const _PracticeCopy({
    required this.title,
    required this.lead,
    required this.steps,
    required this.keepLabel,
    required this.closing,
  });

  final String title;
  final String lead;
  final List<(String, String)> steps; // (prompt, hint)
  final String keepLabel;
  final String closing;
}

class _UndertowSurfaceState extends State<UndertowSurface>
    with TickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: kBreath);
  late final AnimationController _drift = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 11400));
  String _stage = 'observe'; // observe → practice → done
  int _step = 0;
  final List<TextEditingController> _fields = [
    TextEditingController(),
    TextEditingController(),
  ];
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.reduced) {
      _breath.repeat(reverse: true);
      _drift.repeat();
    } else {
      _breath.value = .5;
      _drift.value = .35;
    }
    if (widget.reading.kind == 'worry' && widget.reading.phrase.isNotEmpty) {
      _fields[0].text = widget.reading.phrase;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _drift.dispose();
    for (final f in _fields) {
      f.dispose();
    }
    _closeTimer?.cancel();
    super.dispose();
  }

  _PracticeCopy get _copy => switch (widget.reading.kind) {
        'worry' => const _PracticeCopy(
            title: 'leaving it with the tide',
            lead:
                'a worry carried all night changes nothing but the night. name it in one line and let the tide hold it — it will come back tomorrow evening, when you choose to look.',
            steps: [('the worry, in one line', 'as plainly as it will come…')],
            keepLabel: 'let the tide hold it',
            closing:
                'the tide has it now. tomorrow evening it returns to your journal shore — until then, it is not yours to carry.',
          ),
        'selfCritique' => const _PracticeCopy(
            title: 'from further out',
            lead:
                'someone fond of you reads this page and finds that line. how would they say it back to you?',
            steps: [
              (
                'their voice, a line or two',
                'kindness, with your own facts in it…'
              ),
            ],
            keepLabel: 'keep this with the page',
            closing: 'kept. distance is not denial — it is room to breathe.',
          ),
        _ => const _PracticeCopy(
            title: 'walking it to shore',
            lead:
                'circling stays in the fog; one concrete moment has edges. walk this down to a single one.',
            steps: [
              (
                'inside all of this, choose one single moment. when and where was it, exactly?',
                'one evening, one desk, one sentence…'
              ),
              (
                'stand inside that one moment. what is one small thing that could move, even a centimetre?',
                'small counts — a message, a note, a window opened…'
              ),
            ],
            keepLabel: 'keep this with the page',
            closing: 'kept. concrete ground holds better than fog.',
          ),
      };

  void _finishPractice() {
    final kind = widget.reading.kind;
    if (kind == 'worry') {
      final line = _fields[0].text.trim().isEmpty
          ? widget.reading.phrase
          : _fields[0].text.trim();
      if (line.isNotEmpty) widget.store.parkWorry(line);
    } else if (kind == 'selfCritique') {
      final line = _fields[0].text.trim();
      if (line.isNotEmpty) {
        widget.store
            .appendToEntry(widget.entry, '···\nfrom further out — $line');
      }
    } else {
      final s1 = _fields[0].text.trim();
      final s2 = _fields[1].text.trim();
      if (s1.isEmpty && s2.isEmpty) {
        widget.onClose();
        return;
      }
      final lines = [
        '···',
        if (s1.isNotEmpty) 'one moment, exactly — $s1',
        if (s2.isNotEmpty) 'what could move a little — $s2',
      ].join('\n');
      widget.store.appendToEntry(widget.entry, lines);
    }
    setState(() => _stage = 'done');
    _closeTimer =
        Timer(Duration(milliseconds: widget.reduced ? 1600 : 3400), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final tint = (e.v != null && e.a != null) ? seaTint(e.v!, e.a!) : kRiva;
    return Stack(
      children: [
        // The scrim arrives like dusk, softly; tapping it lets the page rest.
        Positioned.fill(
          child: GestureDetector(
            onTap: _stage == 'practice' ? null : widget.onClose,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: widget.reduced ? 0 : 640),
              curve: Curves.easeOut,
              builder: (_, t, __) => ColoredBox(
                  color: const Color(0xFF04080D).withValues(alpha: .58 * t)),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: widget.reduced ? 0 : 560),
            curve: kExhale,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                  offset: Offset(0, 36 * (1 - t)), child: child),
            ),
            child: AnimatedBuilder(
              animation: _breath,
              builder: (_, child) {
                final b =
                    Curves.easeInOut.transform(_breath.value); // 0..1 breath
                return Transform.scale(
                  scale: 1 + .004 * b,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  constraints: const BoxConstraints(maxWidth: 480),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: tint.withValues(alpha: .32)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0C1620).withValues(alpha: .97),
                        const Color(0xFF07101A).withValues(alpha: .99),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter:
                                  _CurrentsPainter(drift: _drift, tint: tint),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                          child: AnimatedSwitcher(
                            duration: Duration(
                                milliseconds: widget.reduced ? 0 : 420),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                            child: KeyedSubtree(
                              key: ValueKey('$_stage-$_step'),
                              child: switch (_stage) {
                                'practice' => _practice(tint),
                                'done' => _done(tint),
                                _ => _observe(tint),
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _observe(Color tint) {
    final r = widget.reading;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _capsLabel('a current under this page', kOro.withValues(alpha: .75)),
        const SizedBox(height: 10),
        Text(undertowObservation(r),
            style: MenteType.heading.copyWith(height: 1.4, color: textPrimary)),
        if (r.phrase.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('“${r.phrase}”',
              style: GoogleFonts.alice(
                  fontStyle: FontStyle.italic,
                  fontSize: 13.5,
                  height: 1.5,
                  color: kOro.withValues(alpha: .85))),
        ],
        const SizedBox(height: 10),
        Text('just something the water showed — it may be nothing at all.',
            style: GoogleFonts.alice(
                fontStyle: FontStyle.italic, fontSize: 11.5, color: textFaint)),
        const SizedBox(height: 16),
        Row(
          children: [
            _pill('two quiet minutes with it',
                () => setState(() => _stage = 'practice'),
                primary: true),
            const SizedBox(width: 10),
            _pill('let the page rest', widget.onClose),
          ],
        ),
      ],
    );
  }

  Widget _practice(Color tint) {
    final c = _copy;
    final last = _step == c.steps.length - 1;
    final (prompt, hint) = c.steps[_step];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _capsLabel(c.title, kRiva.withValues(alpha: .8)),
        const SizedBox(height: 10),
        Text(c.lead,
            style: MenteType.bodySerif
                .copyWith(height: 1.55, color: textSecondary)),
        const SizedBox(height: 14),
        Text(prompt,
            style: MenteType.heading.copyWith(height: 1.4, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: _fields[_step],
          maxLines: 4,
          minLines: 2,
          autofocus: !widget.reduced,
          style: MenteType.bodySerif.copyWith(height: 1.55, color: textPrimary),
          cursorColor: kRivaLight,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.alice(
                fontStyle: FontStyle.italic, fontSize: 13, color: textDisabled),
            filled: true,
            fillColor: tint.withValues(alpha: .07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: textDisabled),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: textDisabled),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kRiva.withValues(alpha: .45)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _pill(
              last ? c.keepLabel : 'and then',
              () {
                if (last) {
                  _finishPractice();
                } else {
                  setState(() => _step++);
                }
              },
              primary: true,
            ),
            const SizedBox(width: 10),
            _pill('not tonight', widget.onClose),
          ],
        ),
      ],
    );
  }

  Widget _done(Color tint) {
    final worry = widget.reading.kind == 'worry';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (worry)
          // The worry line visibly settles into the water and is carried off.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: widget.reduced ? 0 : 1600),
            curve: Curves.easeInOut,
            builder: (_, t, __) => Opacity(
              opacity: (1 - t).clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, 22 * t),
                child: Text('“${_fields[0].text.trim()}”',
                    style: GoogleFonts.alice(
                        fontStyle: FontStyle.italic,
                        fontSize: 13.5,
                        color: textSecondary)),
              ),
            ),
          ),
        if (worry) const SizedBox(height: 6),
        WaveDivider(color: tint, alpha: .35),
        const SizedBox(height: 10),
        Text(_copy.closing,
            style: MenteType.bodySerif
                .copyWith(height: 1.5, color: textSecondary)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _pill('good night to it', widget.onClose),
        ),
      ],
    );
  }
}

/// Slow underwater currents behind the undertow panel — three drifting
/// quadratic strokes and a soft travelling glow, phase-locked to one
/// unhurried loop. Never busy; barely there.
class _CurrentsPainter extends CustomPainter {
  _CurrentsPainter({required this.drift, required this.tint})
      : super(repaint: drift);

  final Animation<double> drift;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final t = drift.value * 2 * math.pi;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.3 + .22 * i);
      final amp = 5.0 + 2.0 * i;
      final path = Path()..moveTo(-12, y);
      final segs = math.max(3, (size.width / 90).round());
      final seg = (size.width + 24) / segs;
      for (var s = 0; s < segs; s++) {
        final phase = t + i * 1.9 + s * .8;
        path.quadraticBezierTo(
          -12 + seg * s + seg / 2,
          y + amp * math.sin(phase),
          -12 + seg * (s + 1),
          y,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = tint.withValues(alpha: .10 - .02 * i),
      );
    }
    // A slow glow crossing the panel, like light through water.
    final gx = ((drift.value + .25) % 1) * (size.width + 160) - 80;
    canvas.drawCircle(
      Offset(gx, size.height * .34),
      54,
      Paint()
        ..color = tint.withValues(alpha: .05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
  }

  @override
  bool shouldRepaint(_CurrentsPainter old) => old.tint != tint;
}

// ─────────────────────────────── the almanac ───────────────────────────────

/// The almanac on Home — the user's own leading patterns, read from their own
/// pages, under a slowly breathing horizon. Tapping unfolds the full reading.
/// Prose only; a pattern is an invitation, never a forecast of fact.
class AlmanacCard extends StatefulWidget {
  const AlmanacCard({super.key, required this.store});

  final AppStore store;

  @override
  State<AlmanacCard> createState() => _AlmanacCardState();
}

class _AlmanacCardState extends State<AlmanacCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 9200));
  bool _expanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.of(context).disableAnimations ||
        widget.store.reducedMotionOn;
    if (reduced) {
      _drift.stop();
      _drift.value = .3;
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (!store.almanacOn) return const SizedBox.shrink();
    final moodCount = store.entries.where((e) => e.isMoodEntry).length;
    if (moodCount < 4) return const SizedBox.shrink();
    final reading = almanacRead(store.entries);

    JournalEntry? latest;
    for (final e in store.entries) {
      if (e.isMoodEntry && (latest == null || e.ts > latest.ts)) latest = e;
    }
    final tint = latest != null ? seaTint(latest.v!, latest.a!) : kRiva;
    final sky = latest != null ? skyTint(latest.v!, latest.a!) : kRivaLight;

    final showable = reading.hasData && reading.lines.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: s8),
      child: ClipRRect(
        borderRadius: kSoftCardRadius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: kSoftCardRadius,
            border: Border.all(color: tint.withValues(alpha: .22)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A121C).withValues(alpha: .82),
                const Color(0xFF081019).withValues(alpha: .92),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter:
                        _HorizonPainter(drift: _drift, tint: tint, sky: sky),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: kSoftCardRadius,
                  onTap: showable
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              _capsLabel(
                                  'the almanac', kOro.withValues(alpha: .7)),
                              const Spacer(),
                              if (showable)
                                Text(_expanded ? 'fold' : 'unfold',
                                    style: MenteType.caption
                                        .copyWith(color: textFaint)),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            showable
                                ? reading.leading!.text
                                : 'still filling — the almanac learns only from your own weather, and there is not quite enough yet.',
                            style: MenteType.bodySerif
                                .copyWith(height: 1.45, color: textPrimary),
                          ),
                          if (_expanded && showable) ...[
                            const SizedBox(height: 10),
                            WaveDivider(color: tint, alpha: .3),
                            for (final l in reading.lines.skip(1))
                              Padding(
                                padding: const EdgeInsets.only(top: s8),
                                child: Text(l.text,
                                    style: MenteType.bodySerif.copyWith(
                                        height: 1.5, color: textSecondary)),
                              ),
                            const SizedBox(height: 10),
                            Text(
                                'your pattern, not a promise — read from ${reading.soundings} kept moments.',
                                style: GoogleFonts.alice(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                    color: textFaint)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A breathing horizon: two slow sine strokes low in the card and a soft
/// glow whose place follows the hour — dawn at the left edge, dusk at the
/// right. Abstract atmosphere, never a chart.
class _HorizonPainter extends CustomPainter {
  _HorizonPainter({required this.drift, required this.tint, required this.sky})
      : super(repaint: drift);

  final Animation<double> drift;
  final Color tint;
  final Color sky;

  @override
  void paint(Canvas canvas, Size size) {
    final t = drift.value * 2 * math.pi;
    for (var i = 0; i < 2; i++) {
      final y = size.height * (.72 + .14 * i);
      final amp = 2.6 + 1.6 * i;
      final path = Path()..moveTo(-8, y);
      final segs = math.max(3, (size.width / 70).round());
      final seg = (size.width + 16) / segs;
      for (var s = 0; s < segs; s++) {
        path.quadraticBezierTo(
          -8 + seg * s + seg / 2,
          y + amp * math.sin(t + i * 1.4 + s * 1.1),
          -8 + seg * (s + 1),
          y,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = tint.withValues(alpha: .22 - .08 * i),
      );
    }
    // The hour's glow — where in the day the reader stands.
    final now = DateTime.now();
    final frac = (now.hour * 60 + now.minute) / (24 * 60);
    final gx = size.width * (.08 + .84 * frac);
    final breathe = .5 + .5 * math.sin(t);
    canvas.drawCircle(
      Offset(gx, size.height * .68),
      4 + 1.2 * breathe,
      Paint()
        ..color = sky.withValues(alpha: .5 + .18 * breathe)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(gx, size.height * .68),
      16,
      Paint()
        ..color = sky.withValues(alpha: .10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(_HorizonPainter old) => old.tint != tint || old.sky != sky;
}

// ──────────────────────── the tide returns ─────────────────────────

/// When a parked worry's time has come, the tide brings it back — on the
/// journal home, on the user's own terms. Often it has gone lighter on its
/// own; noticing that is the practice.
class TideReturnsCard extends StatefulWidget {
  const TideReturnsCard({
    super.key,
    required this.store,
    required this.onWrite,
  });

  final AppStore store;
  final ValueChanged<String> onWrite;

  @override
  State<TideReturnsCard> createState() => _TideReturnsCardState();
}

class _TideReturnsCardState extends State<TideReturnsCard> {
  bool _leaving = false;

  @override
  Widget build(BuildContext context) {
    final due = widget.store.dueParkedWorries;
    if (due.isEmpty) return const SizedBox.shrink();
    final w = due.first;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      opacity: _leaving ? 0 : 1,
      child: Container(
        margin: const EdgeInsets.only(top: s12),
        padding: const EdgeInsets.all(s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _capsLabel(
                'the tide brought this back', kRiva.withValues(alpha: .8)),
            const SizedBox(height: 8),
            Text('“${w.text}”',
                style: MenteType.bodySerif
                    .copyWith(height: 1.45, color: textPrimary)),
            const SizedBox(height: 6),
            Text(
                'has it changed while the tide held it — heavier, lighter, or done with you?',
                style: MenteType.caption
                    .copyWith(height: 1.5, color: textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _pill('a few lines about it', () {
                  widget.store.settleWorry(w);
                  widget.onWrite(
                      'The tide returned a worry you set down — “${w.text}”. Where does it sit now?');
                }, primary: true),
                const SizedBox(width: 10),
                _pill('it can rest now', () {
                  setState(() => _leaving = true);
                  Timer(const Duration(milliseconds: 430), () {
                    if (mounted) widget.store.settleWorry(w);
                  });
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────  anchors ─────────────────────────────────

/// One small anchor — behavioural activation at the smallest scale, mined
/// from the user's own gentler days. Invites once, holds one at a time,
/// closes its loop with a few lines, and never counts anything.
class AnchorCard extends StatefulWidget {
  const AnchorCard({super.key, required this.store, required this.onWrite});

  final AppStore store;
  final ValueChanged<String> onWrite;

  @override
  State<AnchorCard> createState() => _AnchorCardState();
}

class _AnchorCardState extends State<AnchorCard> {
  bool _leaving = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final todayKey = dayKeyOf(nowMs);
    final open = store.openAnchor;

    if (open != null && open.forDay.compareTo(todayKey) <= 0) {
      return _card(
        label: 'an anchor you set',
        labelColor: kRiva.withValues(alpha: .8),
        body: '“${open.text}”',
        note:
            "if it happened, what was the water like near it? if it didn't — the sea doesn't count.",
        actions: [
          _pill('a few lines', () {
            store.reflectAnchor(open, 'written');
            widget.onWrite(
                'You held a small anchor — “${open.text}”. What was the water like near it, or near its absence?');
          }, primary: true),
          const SizedBox(width: 10),
          _pill('let it go', () {
            setState(() => _leaving = true);
            Timer(const Duration(milliseconds: 430), () {
              if (mounted) store.reflectAnchor(open, 'passed');
            });
          }),
        ],
      );
    }

    if (open == null &&
        nowMs >= store.anchorQuietUntil &&
        store.entries.length >= 8) {
      final mined = mineAnchors(store.entries);
      if (mined.isEmpty) return const SizedBox.shrink();
      final s = mined.first;
      return _card(
        label: 'one small anchor',
        labelColor: kOro.withValues(alpha: .7),
        body: '${s.action} — tomorrow, if the day allows.',
        lead: s.evidence,
        note: "no goal, no count. the sea keeps; it doesn't keep score.",
        actions: [
          _pill('hold it for tomorrow', () {
            store.setAnchor(text: s.action, theme: s.theme);
          }, primary: true),
          const SizedBox(width: 10),
          _pill('not now', () {
            setState(() => _leaving = true);
            Timer(const Duration(milliseconds: 430), () {
              if (mounted) store.quietAnchorInvites();
            });
          }),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _card({
    required String label,
    required Color labelColor,
    required String body,
    String? lead,
    required String note,
    required List<Widget> actions,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 420),
      opacity: _leaving ? 0 : 1,
      child: Container(
        margin: const EdgeInsets.only(top: s12),
        padding: const EdgeInsets.all(s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _capsLabel(label, labelColor),
            if (lead != null) ...[
              const SizedBox(height: 8),
              Text(lead,
                  style: GoogleFonts.alice(
                      fontStyle: FontStyle.italic,
                      fontSize: 12.5,
                      height: 1.5,
                      color: textSecondary)),
            ],
            const SizedBox(height: 8),
            Text(body,
                style: MenteType.heading
                    .copyWith(height: 1.4, color: textPrimary)),
            const SizedBox(height: 6),
            Text(note,
                style:
                    MenteType.caption.copyWith(height: 1.5, color: textFaint)),
            const SizedBox(height: 12),
            Row(children: actions),
          ],
        ),
      ),
    );
  }
}
