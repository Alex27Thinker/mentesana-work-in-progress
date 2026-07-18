// Mentesana — Personal Tide Lab.
// One small daily habit, one tap a day. Mentesana remembers whether the
// habit happened and quietly compares your ordinary sea check-ins on those
// days with the rest of your recent weather. The N-of-1 / EMA science lives
// in the engine and its thresholds — never in the interface language.
// It offers gentle leans, never diagnoses or causal conclusions.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'analysis_engine.dart';
import 'app_store.dart';
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'theme.dart';
import 'sea_icons.dart';

const _kRiva = Color(0xFF7FA89B);
const _kRivaBright = Color(0xFFB6D1C8);

/// A suggested habit, chosen from the user's own recent pages when a theme
/// repeats safely, otherwise a gentle default.
class _TideSuggestion {
  const _TideSuggestion({
    required this.theme,
    required this.title,
    required this.action,
  });

  final String theme;
  final String title;
  final String action;
}

/// The story and numbers behind one experiment, computed from borrowed
/// check-ins. `actionA`/`restA` hold per-day activation for the graphic.
class _TideStats {
  const _TideStats({
    required this.narrative,
    required this.grounded,
    this.actionA = const [],
    this.restA = const [],
  });

  final String narrative;
  final bool grounded;
  final List<double> actionA;
  final List<double> restA;
}

class TideLabScreen extends StatefulWidget {
  const TideLabScreen({
    super.key,
    required this.store,
    required this.onBack,
    required this.onOpenEntry,
  });

  final AppStore store;
  final VoidCallback onBack;
  final ValueChanged<JournalEntry> onOpenEntry;

  @override
  State<TideLabScreen> createState() => _TideLabScreenState();
}

class _TideLabScreenState extends State<TideLabScreen>
    with TickerProviderStateMixin {
  // The shared exhale rhythm every breathing surface uses, plus a slow
  // drift for the backdrop and a one-shot bloom when today lands.
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: kBreath);
  late final AnimationController _drift = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 14000));
  late final AnimationController _bloom = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750));

  final TextEditingController _ownAction = TextEditingController();
  bool _writingOwn = false;
  String? _pickedAction; // null = the suggested one
  String? _pickedTitle;
  int _duration = 7;

  bool get _reduced =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      widget.store.reducedMotionOn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    if (_reduced) {
      _breath.stop();
      _drift.stop();
      return;
    }
    if (!_breath.isAnimating) _breath.repeat(reverse: true);
    if (!_drift.isAnimating) _drift.repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    _drift.dispose();
    _bloom.dispose();
    _ownAction.dispose();
    super.dispose();
  }

  static const _actions = <String, String>{
    'work': 'Before ending work or study, write down the next smallest task.',
    'relationships': 'After an important interaction, take one quiet minute before the next activity.',
    'sleep': 'Give the final ten minutes before bed to a screen-free landing.',
    'health': 'Pause once during the day and notice what your body is asking for.',
    'self-care': 'Choose one small act of care before the day becomes crowded.',
    'creativity': 'Make five minutes for something expressive with no outcome required.',
    'nature': 'Step outside, or near a window, and notice three changing details.',
    'movement': 'Try five unhurried minutes of movement at a natural stopping point.',
    'food': 'Let one meal happen without another task beside it.',
    'money': 'Give financial thoughts one planned ten-minute container, then close it.',
  };

  static const _titles = <String, String>{
    'work': 'a gentler landing after work',
    'relationships': 'a quiet minute after people',
    'sleep': 'a softer way into sleep',
    'health': 'listening to the body once a day',
    'self-care': 'one small act of care',
    'creativity': 'five expressive minutes',
    'nature': 'a window of outside',
    'movement': 'five unhurried minutes',
    'food': 'one undisturbed meal',
    'money': 'a container for money thoughts',
  };

  // ---------- suggestion engine (safety gates unchanged) ----------

  _TideSuggestion _suggestion() {
    final cutoff = DateTime.now().millisecondsSinceEpoch - 42 * 86400000;
    final pages = widget.store.entries
        .where((e) =>
            e.ts >= cutoff &&
            e.text.trim().length > 20 &&
            !kSafetyRe.hasMatch(e.text))
        .toList();
    final byTheme = <String, int>{};
    for (final page in pages) {
      for (final hit in TextAnalyzer.detectThemes(page.text)) {
        byTheme[hit.theme] = (byTheme[hit.theme] ?? 0) + 1;
      }
    }
    final ranked = byTheme.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isNotEmpty && _actions.containsKey(ranked.first.key)) {
      final theme = ranked.first.key;
      return _TideSuggestion(
        theme: theme,
        title: _titles[theme] ?? 'a small tide around $theme',
        action: _actions[theme]!,
      );
    }
    return const _TideSuggestion(
      theme: 'daily transitions',
      title: 'a gentler landing',
      action:
          'At one natural stopping point, take three slow breaths and name the next small thing.',
    );
  }

  List<_TideSuggestion> _alternatives(String excludeTheme) {
    const order = ['movement', 'nature', 'sleep', 'self-care', 'work'];
    final result = <_TideSuggestion>[];
    for (final theme in order) {
      if (theme == excludeTheme || result.length == 3) continue;
      result.add(_TideSuggestion(
        theme: theme,
        title: _titles[theme]!,
        action: _actions[theme]!,
      ));
    }
    return result;
  }

  // ---------- borrowed measurement ----------

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Per-day average kept weather (v, a) from ordinary check-ins,
  /// between [fromTs] inclusive and [toTs] exclusive.
  Map<String, List<double>> _moodByDay(int fromTs, int toTs) {
    final sums = <String, List<double>>{};
    for (final entry in widget.store.entries) {
      if (!entry.isMoodEntry || entry.ts < fromTs || entry.ts >= toTs) continue;
      final key = _dayKey(entry.date);
      final sum = sums.putIfAbsent(key, () => [0, 0, 0]);
      sum[0] += entry.v!;
      sum[1] += entry.a!;
      sum[2] += 1;
    }
    return {
      for (final item in sums.entries)
        item.key: [item.value[0] / item.value[2], item.value[1] / item.value[2]]
    };
  }

  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  /// Compares check-ins on habit days against ordinary days (the 28 days
  /// before the experiment plus in-window days without the habit).
  _TideStats _stats(TideExperiment experiment) {
    final endTs = experiment.completedAt ??
        DateTime.now().millisecondsSinceEpoch + 86400000;
    final didDays = <String>{};
    for (final observation in experiment.observations) {
      if (observation.response == 'did') {
        didDays.add(_dayKey(
            DateTime.fromMillisecondsSinceEpoch(observation.ts)));
      }
    }
    final windowMood = _moodByDay(experiment.startedAt, endTs);
    final baselineMood = _moodByDay(
        experiment.startedAt - 28 * 86400000, experiment.startedAt);
    final actionA = <double>[], actionV = <double>[];
    final restA = <double>[], restV = <double>[];
    windowMood.forEach((day, mood) {
      (didDays.contains(day) ? actionA : restA).add(mood[1]);
      (didDays.contains(day) ? actionV : restV).add(mood[0]);
    });
    for (final mood in baselineMood.values) {
      restV.add(mood[0]);
      restA.add(mood[1]);
    }
    final kept = didDays.length;
    if (kept == 0) {
      return const _TideStats(
        narrative:
            'The habit never quite found its day — that is an honest finding too. Maybe a smaller one, or a different season.',
        grounded: false,
      );
    }
    if (actionA.length < 4 || restA.length < 4) {
      return _TideStats(
        narrative:
            'It happened on $kept day${kept == 1 ? '' : 's'}, but too few check-ins landed beside it to say anything yet. That is allowed.',
        grounded: false,
        actionA: actionA,
        restA: restA,
      );
    }
    final differenceA = _median(actionA) - _median(restA);
    final differenceV = _median(actionV) - _median(restV);
    String lean = '';
    if (differenceA.abs() >= .12) {
      lean = differenceA < 0 ? 'calmer' : 'more awake';
    }
    if (differenceV.abs() >= .12) {
      final word = differenceV > 0 ? 'easier to be in' : 'heavier';
      lean = lean.isEmpty ? word : '$lean, and $word';
    }
    final narrative = lean.isEmpty
        ? 'On the ${actionA.length} days it happened, your weather looked much like your usual days. Sameness counts — this one may simply not be your tide.'
        : 'On the ${actionA.length} days it happened, your weather tended to feel $lean than your usual days. A small lean, not a verdict — keep it if it feels useful.';
    return _TideStats(
      narrative: narrative,
      grounded: true,
      actionA: actionA,
      restA: restA,
    );
  }

  // ---------- lifecycle ----------

  void _begin(_TideSuggestion suggestion) {
    final ownText = _ownAction.text.trim();
    final useOwn = _writingOwn && ownText.isNotEmpty;
    final action = useOwn ? ownText : (_pickedAction ?? suggestion.action);
    final title = useOwn ? 'your own tide' : (_pickedTitle ?? suggestion.title);
    final now = DateTime.now().millisecondsSinceEpoch;
    widget.store.startTideExperiment(TideExperiment(
      id: 'tide-$now',
      title: title,
      hypothesis: 'Does this small habit shift my inner weather?',
      action: action,
      theme: suggestion.theme,
      startedAt: now,
      durationDays: _duration,
    ));
    setState(() {
      _writingOwn = false;
      _pickedAction = null;
      _pickedTitle = null;
      _ownAction.clear();
    });
  }

  void _keepToday(TideExperiment experiment, String response) {
    widget.store.recordTideObservation(experiment.id, response);
    if (!_reduced) _bloom.forward(from: 0);
    setState(() {});
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final suggestion = _suggestion();
    final active = widget.store.activeTideExperiment;
    final completed = widget.store.tideExperiments
        .where((experiment) => experiment.isComplete)
        .toList()
        .reversed
        .take(3)
        .toList();
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_breath, _drift]),
              builder: (context, _) => CustomPaint(
                painter: _TideLabBackdrop(
                  points: widget.store.entries
                      .where((entry) => entry.isMoodEntry)
                      .toList()
                      .reversed
                      .take(12)
                      .toList()
                      .reversed
                      .toList(),
                  breath: _reduced ? .5 : kExhale.transform(_breath.value),
                  drift: _reduced ? 0 : _drift.value,
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            _header(),
            const WaveDivider(),
            Expanded(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: _reduced ? 0 : 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: ListView(
                  key: ValueKey(active?.id ?? 'setup'),
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 104),
                  children: [
                    _intro(active == null),
                    const SizedBox(height: 22),
                    if (active == null)
                      _setupCard(suggestion)
                    else
                      _activeCard(active),
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 30),
                      _eyebrow('past tides'),
                      const SizedBox(height: 10),
                      for (final experiment in completed)
                        _completedCard(experiment),
                    ],
                    const SizedBox(height: 22),
                    Text(
                      'Tide Lab notices leans in your own weather. It never scores, diagnoses, or proves why something changed.',
                      style: GoogleFonts.alice(
                          fontStyle: FontStyle.italic,
                          fontSize: 11.5,
                          height: 1.55,
                          color: textFaint),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _header() => ScreenHeader(
        title: 'tide lab',
        onBack: widget.onBack,
        trailing: IconButton(
          onPressed: _showMethod,
          tooltip: 'How Tide Lab works',
          icon: StrokeIcon(SeaIcons.about, size: 18, color: textFaint),
        ),
      );

  Widget _intro(bool settingUp) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('one small habit · one tap a day'),
          const SizedBox(height: 10),
          Text(
              settingUp
                  ? 'Try one small thing for a week.'
                  : 'This week’s small tide.',
              style: MenteType.display.copyWith(height: 1.15, color: textPrimary)),
          const SizedBox(height: 10),
          Text(
            settingUp
                ? 'Each day, tap whether it happened. Your usual check-ins do the measuring — at the end, Mentesana shows whether your weather felt any different on the days you did it.'
                : 'Tap once a day. Your usual check-ins quietly hold the rest.',
            style: MenteType.bodySerif.copyWith( height: 1.6, color: textSecondary),
          ),
        ],
      );

  // ---------- setup ----------

  Widget _setupCard(_TideSuggestion suggestion) {
    final chosenAction = _pickedAction ?? suggestion.action;
    final alternatives = _alternatives(suggestion.theme);
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _eyebrow('a suggestion from your pages',
                color: kOro.withValues(alpha: .82)),
            const Spacer(),
            _breathingDot(kOro),
          ]),
          const SizedBox(height: 14),
          if (!_writingOwn) ...[
            Text(chosenAction,
                style: MenteType.heading.copyWith(height: 1.35, color: textPrimary)),
            const SizedBox(height: 16),
            _label('or try'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 18,
              runSpacing: 2,
              children: [
                for (final alt in alternatives)
                  _underlineChip(alt.title,
                      selected: _pickedAction == alt.action,
                      onTap: () => setState(() {
                            _pickedAction = alt.action;
                            _pickedTitle = alt.title;
                          })),
                _underlineChip('+ your own',
                    selected: false,
                    onTap: () => setState(() => _writingOwn = true)),
              ],
            ),
          ] else ...[
            TextField(
              controller: _ownAction,
              maxLines: 2,
              autofocus: true,
              style: MenteType.heading.copyWith(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'one small thing, in your words…',
                hintStyle: GoogleFonts.alice(
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    color: textDisabled),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: textDisabled)),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _kRiva)),
              ),
            ),
            const SizedBox(height: 8),
            _underlineChip('back to suggestions',
                selected: false,
                onTap: () => setState(() => _writingOwn = false)),
          ],
          const SizedBox(height: 18),
          _label('for how long'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 18,
            children: [
              for (final days in const [5, 7, 10, 14])
                _underlineChip('$days days',
                    selected: _duration == days,
                    onTap: () => setState(() => _duration = days)),
            ],
          ),
          const SizedBox(height: 20),
          _primaryButton('begin', () => _begin(suggestion)),
          const SizedBox(height: 10),
          Text('Nothing extra to measure — your daily check-in is enough.',
              textAlign: TextAlign.center,
              style: GoogleFonts.alice(
                  fontStyle: FontStyle.italic,
                  fontSize: 11.5,
                  color: textFaint)),
        ],
      ),
    );
  }

  // ---------- active ----------

  Widget _activeCard(TideExperiment experiment) {
    final now = DateTime.now();
    final todayRecorded = experiment.observations.any((observation) {
      final day = DateTime.fromMillisecondsSinceEpoch(observation.ts);
      return day.year == now.year && day.month == now.month && day.day == now.day;
    });
    final elapsed = now
        .difference(DateTime.fromMillisecondsSinceEpoch(experiment.startedAt))
        .inDays;
    final daysLeft = math.max(0, experiment.durationDays - elapsed);
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _eyebrow(experiment.title, color: const Color(0xFF9FC2B7)),
            const Spacer(),
            _breathingDot(_kRiva),
            const SizedBox(width: 8),
            Text(daysLeft == 0 ? 'ready to look back' : '$daysLeft days left',
                style: MenteType.caption.copyWith( color: textFaint)),
          ]),
          const SizedBox(height: 14),
          Text(experiment.action,
              style: MenteType.heading.copyWith(height: 1.35, color: textPrimary)),
          const SizedBox(height: 22),
          _weekTides(experiment),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(_kRiva, filled: true),
              const SizedBox(width: 5),
              Text('did it', style: MenteType.eyebrow.copyWith( color: textFaint)),
              const SizedBox(width: 16),
              _legendDot(ivory(.5), filled: false),
              const SizedBox(width: 5),
              Text('colour · that day’s weather',
                  style: MenteType.eyebrow.copyWith( color: textFaint)),
            ],
          ),
          const SizedBox(height: 18),
          if (!todayRecorded) ...[
            _label('did it happen today?'),
            const SizedBox(height: 6),
            Row(
              children: [
                _underlineChip('it did',
                    selected: false,
                    onTap: () => _keepToday(experiment, 'did')),
                const SizedBox(width: 26),
                _underlineChip('not today',
                    selected: false,
                    onTap: () => _keepToday(experiment, 'not')),
              ],
            ),
          ] else
            Center(
              child: Text('today is resting here',
                  style: GoogleFonts.alice(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: textFaint)),
            ),
          if (experiment.observations.length >= 5 || daysLeft == 0) ...[
            const SizedBox(height: 16),
            _primaryButton('see what the week held',
                () => widget.store.completeTideExperiment(experiment.id)),
          ],
        ],
      ),
    );
  }

  /// One drop per day riding a breathing water line. Each drop is coloured
  /// by that day's kept weather; habit days are filled, others hollow.
  Widget _weekTides(TideExperiment experiment) {
    final startDay = DateTime.fromMillisecondsSinceEpoch(experiment.startedAt);
    final startMidnight = DateTime(startDay.year, startDay.month, startDay.day);
    final byIndex = <int, String>{};
    for (final observation in experiment.observations) {
      final day = DateTime.fromMillisecondsSinceEpoch(observation.ts);
      final index = DateTime(day.year, day.month, day.day)
          .difference(startMidnight)
          .inDays;
      if (index >= 0 && index < experiment.durationDays) {
        byIndex[index] = observation.response;
      }
    }
    final moodByIndex = <int, List<double>>{};
    final moods = _moodByDay(
        startMidnight.millisecondsSinceEpoch,
        startMidnight.millisecondsSinceEpoch +
            experiment.durationDays * 86400000);
    moods.forEach((key, mood) {
      final parts = key.split('-').map(int.parse).toList();
      final index = DateTime(parts[0], parts[1], parts[2])
          .difference(startMidnight)
          .inDays;
      if (index >= 0 && index < experiment.durationDays) {
        moodByIndex[index] = mood;
      }
    });
    final todayIndex = DateTime.now().difference(startMidnight).inDays;
    return SizedBox(
      height: 58,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _bloom]),
        builder: (context, _) => CustomPaint(
          painter: _WeekTidesPainter(
            duration: experiment.durationDays,
            responses: byIndex,
            moods: moodByIndex,
            todayIndex: todayIndex,
            breath: _reduced ? .5 : kExhale.transform(_breath.value),
            bloom: _reduced ? 0 : _bloom.value,
          ),
          size: const Size(double.infinity, 58),
        ),
      ),
    );
  }

  // ---------- completed ----------

  Widget _completedCard(TideExperiment experiment) {
    final stats = _stats(experiment);
    return Padding(
      padding: const EdgeInsets.only(bottom: s8),
      child: _glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _eyebrow(experiment.title),
            const SizedBox(height: 9),
            Text('What the week seemed to hold',
                style: MenteType.heading.copyWith(color: textPrimary)),
            const SizedBox(height: 8),
            Text(stats.narrative,
                style: MenteType.bodySerif.copyWith( height: 1.55, color: textSecondary)),
            if (stats.grounded) ...[
              const SizedBox(height: 16),
              Row(children: [
                Text('calmer', style: MenteType.eyebrow.copyWith( color: textFaint)),
                const Spacer(),
                Text('more awake',
                    style: MenteType.eyebrow.copyWith( color: textFaint)),
              ]),
              const SizedBox(height: 6),
              SizedBox(
                height: 74,
                child: AnimatedBuilder(
                  animation: _breath,
                  builder: (context, _) => CustomPaint(
                    painter: _TideComparePainter(
                      actionA: stats.actionA,
                      restA: stats.restA,
                      breath:
                          _reduced ? .5 : kExhale.transform(_breath.value),
                    ),
                    size: const Size(double.infinity, 74),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(_kRiva, filled: true),
                  const SizedBox(width: 5),
                  Text('days with it',
                      style: MenteType.eyebrow.copyWith( color: textFaint)),
                  const SizedBox(width: 16),
                  _legendDot(ivory(.5), filled: false),
                  const SizedBox(width: 5),
                  Text('your usual days',
                      style: MenteType.eyebrow.copyWith( color: textFaint)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- shared small pieces ----------

  Widget _breathingDot(Color color) => AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          final t = _reduced ? .5 : kExhale.transform(_breath.value);
          return Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: .5 + t * .3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .1 + t * .14),
                  blurRadius: 10 + t * 6,
                  spreadRadius: 3 + t * 2,
                ),
              ],
            ),
          );
        },
      );

  Widget _legendDot(Color color, {required bool filled}) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color.withValues(alpha: .8) : Colors.transparent,
          border: Border.all(color: color.withValues(alpha: .8), width: 1),
        ),
      );

  Widget _underlineChip(String label,
          {required bool selected, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(3, 8, 3, 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? _kRiva.withValues(alpha: .85)
                    : ivory(.28),
                width: selected ? 1.4 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.alice(
                fontStyle: FontStyle.italic,
                fontSize: 16.5,
                color: selected ? _kRivaBright : ivory(.7)),
          ),
        ),
      );

  Widget _glass({required Widget child}) => Container(
        padding: const EdgeInsets.all(s16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textDisabled),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ivory(.065), const Color(0xFF0B141B).withValues(alpha: .6)],
          ),
        ),
        child: child,
      );

  Widget _eyebrow(String text, {Color? color}) => Text(text.toUpperCase(),
      style: MenteType.eyebrow.copyWith(
          letterSpacing: 1.8,
          color: color ?? ivory(.42)));

  Widget _label(String text) => Text(text.toUpperCase(),
      style: MenteType.eyebrow.copyWith( letterSpacing: 1.65, color: textFaint));

  Widget _primaryButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kRiva.withValues(alpha: .62)),
              color: _kRiva.withValues(alpha: .14),
            ),
            child: Text(label,
                style: MenteType.bodySerif.copyWith(color: _kRivaBright)),
          ),
        ),
      );

  void _showMethod() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B141B),
      barrierColor: const Color(0xFF060B12).withValues(alpha: .7),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('How Tide Lab works',
                style: MenteType.title.copyWith(color: textPrimary)),
            const SizedBox(height: 14),
            Text(
              'Pick one small daily habit. Each day, tap whether it happened — that is all. Your ordinary check-ins are the measurement, and at the end Mentesana compares your weather on habit days with your usual recent days. It can notice a lean; it cannot prove a cause, and it never turns your days into scores.',
              style: MenteType.bodySerif.copyWith( height: 1.65, color: textSecondary),
            ),
          ]),
        ),
      ),
    );
  }
}

/// One drop per day riding a breathing water line. Drop colour is that
/// day's kept weather (the sea's own palette); habit days are filled,
/// days without are hollow, unknown days are faint pebbles.
class _WeekTidesPainter extends CustomPainter {
  const _WeekTidesPainter({
    required this.duration,
    required this.responses,
    required this.moods,
    required this.todayIndex,
    required this.breath,
    required this.bloom,
  });

  final int duration;
  final Map<int, String> responses;
  final Map<int, List<double>> moods;
  final int todayIndex;
  final double breath;
  final double bloom;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height * .55;
    final amplitude = 3.5 + breath * 2.5;
    final water = Path()..moveTo(0, mid);
    for (double x = 0; x <= size.width; x += 6) {
      water.lineTo(
          x,
          mid +
              math.sin(x / size.width * math.pi * 2 + breath * math.pi) *
                  amplitude);
    }
    canvas.drawPath(
      water,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _kRiva.withValues(alpha: .16 + breath * .08),
    );
    for (var index = 0; index < duration; index++) {
      final x = size.width * (index + .5) / duration;
      final wave =
          math.sin(x / size.width * math.pi * 2 + breath * math.pi) * amplitude;
      final response = responses[index];
      final mood = moods[index];
      final isToday = index == todayIndex;
      // Colour comes from that day's weather when a check-in exists.
      final Color color = mood != null
          ? kSea.bilerp(mood[0], mood[1])[0]
          : kIvory.withValues(alpha: index <= todayIndex ? .3 : .15);
      final filled = response == 'did';
      double radius = response == null ? 3.2 : (filled ? 5.5 : 4.2);
      if (isToday) radius += breath * 1.2;
      final center = Offset(x, mid + wave - (response != null ? 6 : 0));
      if (isToday && bloom > 0 && bloom < 1) {
        canvas.drawCircle(
          center,
          radius + bloom * 16,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = _kRiva.withValues(alpha: (1 - bloom) * .5),
        );
      }
      if (filled) {
        canvas.drawCircle(
            center, radius, Paint()..color = color.withValues(alpha: .85));
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = _kRiva.withValues(alpha: .9),
        );
      } else {
        canvas.drawCircle(
            center, radius, Paint()..color = color.withValues(alpha: .2));
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = color.withValues(alpha: .8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WeekTidesPainter old) =>
      old.breath != breath ||
      old.bloom != bloom ||
      old.responses.length != responses.length ||
      old.moods.length != moods.length ||
      old.todayIndex != todayIndex;
}

/// Two quiet lanes on a calmer↔more-awake axis: habit days above (Riva,
/// filled), usual days below (ivory, hollow), each with a soft median tick.
/// The visual answer to “did it change anything?” in one glance.
class _TideComparePainter extends CustomPainter {
  const _TideComparePainter({
    required this.actionA,
    required this.restA,
    required this.breath,
  });

  final List<double> actionA;
  final List<double> restA;
  final double breath;

  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double xFor(double a) => size.width * (.06 + (a + 1) / 2 * .88);
    void lane(double y, List<double> values, Color color, bool filled) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..strokeWidth = .8
          ..color = kIvory.withValues(alpha: .08),
      );
      for (final value in values) {
        final center = Offset(xFor(value), y);
        if (filled) {
          canvas.drawCircle(
              center, 4.5, Paint()..color = color.withValues(alpha: .55));
          canvas.drawCircle(
            center,
            4.5,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.1
              ..color = color.withValues(alpha: .9),
          );
        } else {
          canvas.drawCircle(
              center, 4, Paint()..color = color.withValues(alpha: .12));
          canvas.drawCircle(
            center,
            4,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = color.withValues(alpha: .55),
          );
        }
      }
      // The median tick — where this kind of day typically sat.
      final medianX = xFor(_median(values));
      canvas.drawLine(
        Offset(medianX, y - 11 - breath * 2),
        Offset(medianX, y + 11 + breath * 2),
        Paint()
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: .75),
      );
    }

    lane(size.height * .3, actionA, _kRiva, true);
    lane(size.height * .74, restA, kIvory.withValues(alpha: .8), false);
    // A faint thread joining the two medians makes the gap readable.
    final actionX = xFor(_median(actionA));
    final restX = xFor(_median(restA));
    canvas.drawLine(
      Offset(actionX, size.height * .3),
      Offset(restX, size.height * .74),
      Paint()
        ..strokeWidth = .9
        ..color = kIvory.withValues(alpha: .18 + breath * .06),
    );
  }

  @override
  bool shouldRepaint(_TideComparePainter old) =>
      old.breath != breath ||
      old.actionA.length != actionA.length ||
      old.restA.length != restA.length;
}

/// The ambient backdrop: a breathing wash, two drifting swells, and the
/// constellation of recent kept weather bobbing very slightly with the drift.
class _TideLabBackdrop extends CustomPainter {
  const _TideLabBackdrop({
    required this.points,
    required this.breath,
    required this.drift,
  });

  final List<JournalEntry> points;
  final double breath;
  final double drift;

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(.6, -.45),
        radius: .9,
        colors: [
          _kRiva.withValues(alpha: .07 + breath * .07),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);

    // Two slow swells low in the water, out of the content's way.
    for (var swell = 0; swell < 2; swell++) {
      final phase = drift * math.pi * 2 + swell * 1.7;
      final baseY = size.height * (.82 + swell * .07);
      final amplitude = (5.0 + swell * 3) * (.7 + breath * .5);
      final path = Path()..moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 10) {
        path.lineTo(
            x, baseY + math.sin(x / size.width * math.pi * 2 + phase) * amplitude);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = kIvory.withValues(alpha: .045 + swell * .02 + breath * .015),
      );
    }

    if (points.isEmpty) return;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final entry = points[i];
      final bob = math.sin(drift * math.pi * 2 + i * .9) * 2.6;
      final x = size.width * (.12 + (entry.v! + 1) * .38);
      final y = size.height * (.14 + (1 - (entry.a! + 1) / 2) * .24) + bob;
      final point = Offset(x, y);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawCircle(
        point,
        2.2 + i / points.length * 1.5,
        Paint()
          ..color = kIvory.withValues(
              alpha: .06 + i / points.length * .12 + breath * .04),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = kIvory.withValues(alpha: .05 + breath * .03),
    );
  }

  @override
  bool shouldRepaint(_TideLabBackdrop old) =>
      old.breath != breath ||
      old.drift != drift ||
      old.points.length != points.length;
}

