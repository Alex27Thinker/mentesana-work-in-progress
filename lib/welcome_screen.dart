// Mentesana — onboarding ritual ("welcome").
// 1:1 Flutter port of the welcome flow from the Vite prototype:
// seven skippable breaths that explain the metaphor and evidence, gather only
// preferences that alter the first prompts, then lead directly to a weather
// check-in or a page — no account gate.

import 'package:flutter/material.dart';

import 'mood_palette.dart';
import 'theme.dart';

/// Where the ritual hands off when it closes.
/// 'home' (skip / after saving), 'checkin' (name the weather), 'write' (a page).
typedef WelcomeClose = void Function(String to, List<String> preferences);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onClose,
    this.initialPreferences = const [],
    this.testing = false,
  });

  /// Called after the leaving fade. When [testing] is true (replay from
  /// settings), the caller should not persist anything.
  final WelcomeClose onClose;
  final List<String> initialPreferences;
  final bool testing;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _stageCount = 7;

  int _step = 0;
  late List<String> _preferences = [...widget.initialPreferences];
  bool _leaving = false;

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  // ---------- palette (welcome screen CSS) ----------
  static const _kicker = kRivaLight;
  static const _riva = kRiva;

  void _close(String to) {
    setState(() => _leaving = true);
    Future.delayed(Duration(milliseconds: _reduced ? 0 : 700), () {
      if (!mounted) return;
      widget.onClose(to, _preferences);
    });
  }

  void _togglePref(String key) {
    setState(() {
      _preferences = _preferences.contains(key)
          ? _preferences.where((x) => x != key).toList()
          : [..._preferences, key];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _leaving ? 0 : 1,
      duration: Duration(milliseconds: _reduced ? 0 : 700),
      curve: kExhale,
      child: IgnorePointer(
        ignoring: _leaving,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, .54, 1],
              colors: [Color(0xFF2D3D43), Color(0xFF283540), Color(0xFF232E36)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(),
                  Expanded(child: _stage()),
                  _actions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- top bar: back ‹ / progress / skip ----------
  Widget _topBar() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Visibility(
              visible: _step > 0,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: _QuietButton(
                onTap: () {
                  if (_step > 0) setState(() => _step -= 1);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ivory(.16)),
                  ),
                  child: Text('‹',
                      style: MenteType.heading
                          .copyWith(height: 1, color: textSecondary)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: 'Introduction progress',
              value: '${_step + 1} of $_stageCount',
              child: Container(
                height: 1,
                color: ivory(.16),
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: Duration(milliseconds: _reduced ? 0 : 700),
                  curve: kExhale,
                  widthFactor: (_step + 1) / _stageCount,
                  child: Container(color: _riva, height: 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            height: 44,
            child: _QuietButton(
              onTap: () => _close('home'),
              child: Center(
                child: Text('skip',
                    style: MenteType.eyebrow.copyWith(color: textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- stages (copy ported verbatim from main.js welcomeStages) ----------
  Widget _stage() {
    final content = <Widget>[];
    switch (_step) {
      case 0:
        content.addAll([
          _kickerText('welcome to mentesana'),
          _title('The mind is an ocean.'),
          const SizedBox(height: 24),
          const _SeaLinesVisual(),
          const SizedBox(height: 16),
          _copy([
            const _Run(
                'Not a surface to perfect. A whole, enduring place that can contain many states without becoming any one of them.'),
          ]),
        ]);
        // The visual sits above the copy in the web layout; mirror that order.
        content
          ..removeRange(2, content.length)
          ..addAll([
            const SizedBox(height: 28),
            const _SeaLinesVisual(),
            const SizedBox(height: 28),
            _copy([
              const _Run(
                  'Not a surface to perfect. A whole, enduring place that can contain many states without becoming any one of them.'),
            ]),
          ]);
        break;
      case 1:
        content.addAll([
          _kickerText('the language of the app'),
          _title('Weather moves. The sea remains.'),
          const SizedBox(height: 26),
          _legendRow(
              'the sea', 'you — deeper and more lasting than any moment.'),
          _legendRow('weather',
              'what is here now: temporary, human, and never graded.'),
          _legendRow(
              'seasons', 'patterns that become visible gently over time.'),
        ]);
        break;
      case 2:
        content.addAll([
          _kickerText('how check-ins work'),
          _title('Two dimensions, then your own words.'),
          const SizedBox(height: 20),
          _copy([
            const _Run('The check-in uses the psychological '),
            const _Run('valence–arousal model', strong: true),
            const _Run(
                ': how pleasant or difficult a state feels, and how calm or activated it is. You can adjust the suggested word or leave uncertainty intact.'),
          ]),
          _evidence(
              'Naming feelings more precisely can support emotional awareness. It is an invitation to notice—not a diagnosis or a score.'),
        ]);
        break;
      case 3:
        content.addAll([
          _kickerText('why pages matter'),
          _title('Writing gives experience somewhere to land.'),
          const SizedBox(height: 24),
          _copy([
            const _Run('Mentesana draws on evidence around '),
            const _Run(
                'expressive writing, emotional labeling, and reflective distance',
                strong: true),
            const _Run(
                '. A page can help organize experience; later, repeated themes may become easier to notice.'),
          ]),
          _evidence(
              'These are evidence-informed design principles, not treatment promises. Mentesana never claims that one event caused a feeling.'),
        ]);
        break;
      case 4:
        content.addAll([
          _kickerText('what comes back'),
          _title('Patterns arrive as prose, never charts.'),
          const SizedBox(height: 24),
          _copy([
            const _Run(
                'Once a week, Mentesana may reflect a careful pattern and show the pages underneath it. Thin evidence stays thin. Every observation remains a question, never a conclusion.'),
          ]),
          _note(
              'No streaks. No badges. No “good” or “bad” moods. Silence and skipped days remain valid.'),
        ]);
        break;
      case 5:
        content.addAll([
          _kickerText('shape your first prompts'),
          _title('What would make beginning easier?'),
          const SizedBox(height: 24),
          _copy([
            const _Run(
                'Choose any that fit. These only change which writing openings appear first.'),
          ]),
          const SizedBox(height: 22),
          _choice('question', 'a reflective question to follow'),
          const SizedBox(height: 10),
          _choice('free', 'room to write without a structure'),
          const SizedBox(height: 10),
          _choice('naming', 'help naming what is here'),
          _note('You can select more than one—or none.'),
        ]);
        break;
      case 6:
        content.addAll([
          _kickerText('your first quiet moment'),
          _title('Begin where you are.'),
          const SizedBox(height: 20),
          _copy([
            const _Run(
                'Name the weather in your mind, or open a page without naming anything first.'),
          ]),
          const SizedBox(height: 26),
          _start('name the weather', primary: true, to: 'checkin'),
          const SizedBox(height: 10),
          _start('write a page', to: 'write'),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No account is required in this prototype. Your pages stay on this device.',
              textAlign: TextAlign.center,
              style: MenteType.eyebrow
                  .copyWith(letterSpacing: .3, color: textSecondary),
            ),
          ),
        ]);
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 2, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kickerText(String text) => Padding(
        padding: const EdgeInsets.only(bottom: s12),
        child: Text(text.toUpperCase(),
            style:
                MenteType.eyebrow.copyWith(color: _kicker, letterSpacing: 1.4)),
      );

  Widget _title(String text) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Text(text,
            style:
                MenteType.display.copyWith(height: 1.04, letterSpacing: -.85)),
      );

  Widget _copy(List<_Run> runs) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 312),
        child: Text.rich(
          TextSpan(
            children: [
              for (final r in runs)
                TextSpan(
                  text: r.text,
                  style: r.strong
                      ? const TextStyle(
                          color: kIvory, fontWeight: FontWeight.w500)
                      : null,
                ),
            ],
          ),
          style: MenteType.body.copyWith(height: 1.62, color: textPrimary),
        ),
      );

  Widget _evidence(String text) => Container(
        margin: const EdgeInsets.only(top: s24),
        padding: const EdgeInsets.symmetric(vertical: s16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: ivory(.13)),
            bottom: BorderSide(color: ivory(.13)),
          ),
        ),
        child: Text(text,
            style:
                MenteType.caption.copyWith(height: 1.55, color: textSecondary)),
      );

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(top: s16),
        child: Text(text,
            style:
                MenteType.eyebrow.copyWith(height: 1.5, color: textSecondary)),
      );

  Widget _legendRow(String term, String meaning) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.only(top: 12),
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: ivory(.1)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 70,
              child: Text(term,
                  style: MenteType.eyebrow.copyWith(
                      color: _kicker,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .88)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(meaning,
                  style: MenteType.caption
                      .copyWith(height: 1.45, color: textSecondary)),
            ),
          ],
        ),
      );

  Widget _choice(String key, String label) {
    final selected = _preferences.contains(key);
    return _QuietButton(
      onTap: () => _togglePref(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? kRiva.withValues(alpha: .72) : ivory(.17)),
          color: selected ? kRiva.withValues(alpha: .1) : ivory(.025),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, height: 1.35, color: kIvory)),
            ),
            const SizedBox(width: 12),
            // The radio ring: empty circle, or a thick Riva ring around ivory.
            Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? kIvory : null,
                border: Border.all(
                  color: selected ? _riva : ivory(.34),
                  width: selected ? 6 : 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _start(String label, {bool primary = false, required String to}) {
    return _QuietButton(
      onTap: () => _close(to),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: primary ? _riva : ivory(.22)),
          color: primary ? _riva : ivory(.04),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                color: primary ? const Color(0xFF07131B) : kIvory)),
      ),
    );
  }

  // ---------- actions: continue / next ----------
  Widget _actions() {
    if (_step == _stageCount - 1) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _QuietButton(
        onTap: () {
          if (_step < _stageCount - 1) setState(() => _step += 1);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: ivory(.24)),
            color: kRiva.withValues(alpha: .14),
          ),
          child: Text(
            _step == _stageCount - 2 ? 'continue' : 'next',
            style:
                MenteType.caption.copyWith(letterSpacing: .78, color: kIvory),
          ),
        ),
      ),
    );
  }
}

class _Run {
  const _Run(this.text, {this.strong = false});
  final String text;
  final bool strong;
}

/// The stage-one visual: three soft sea lines, gently tilted.
class _SeaLinesVisual extends StatelessWidget {
  const _SeaLinesVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      width: double.infinity,
      child: CustomPaint(painter: _SeaLinesPainter()),
    );
  }
}

class _SeaLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const lineColor = kRivaLight;
    // (topFraction, tiltDegrees, thickness)
    const lines = [
      (.20, -2.0, 10.0),
      (.49, 1.5, 8.0),
      (.76, -1.0, 12.0),
    ];
    for (final (top, deg, thick) in lines) {
      final y = size.height * top;
      final rect = Rect.fromLTWH(
          size.width * .04, y - thick / 2, size.width * .92, thick);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(deg * 3.14159265 / 180);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      final paint = Paint()
        ..shader = LinearGradient(colors: [
          lineColor.withValues(alpha: 0),
          lineColor.withValues(alpha: .5 * .28),
          lineColor.withValues(alpha: 0),
        ]).createShader(rect);
      canvas.drawOval(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SeaLinesPainter old) => false;
}

/// A borderless tap target — no Material ink, no highlight; the prototype's
/// buttons never splash.
class _QuietButton extends StatelessWidget {
  const _QuietButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}
