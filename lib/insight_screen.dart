// Mentesana — the weekly insight ('surface' door).
// 1:1 port of #screen-insight + renderInsight from the Vite prototype,
// including the demo-data heuristic fallback and the async AI replacement.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '_shared/widgets/sea_motion.dart';
import 'ai_service.dart';
import 'analysis_engine.dart';
import 'app_store.dart';
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'theme.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({
    super.key,
    required this.store,
    required this.onBack,
    required this.onOpenEntry,
  });

  final AppStore store;
  final VoidCallback onBack;
  final ValueChanged<JournalEntry> onOpenEntry;

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen>
    with TickerProviderStateMixin {
  InsightParts? _aiInsight; // async replacement, like the web build
  late final Set<String> _priorShown; // insight lines seen before this visit

  // The headline breathes on the shared kBreath rhythm, tinted with the
  // week's dominant weather so the "surface" feels alive, not typeset.
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: kBreath);
  // A slow horizontal drift for the headline lens — like light moving
  // across the sea floor.
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: kDrift);

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  (double, double)? _weekWeather() {
    final moods = widget.store.entries
        .where((e) => e.isMoodEntry && e.v != null && e.a != null)
        .toList();
    if (moods.isEmpty) return null;
    final v = moods.fold<double>(0, (s, e) => s + e.v!) / moods.length;
    final a = moods.fold<double>(0, (s, e) => s + e.a!) / moods.length;
    return (v, a);
  }

  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    // If AI is enabled, fetch an enhanced insight asynchronously and
    // replace when it arrives (JS renderInsight tail).
    final store = widget.store;
    _priorShown = store.shownInsightLines.toSet();
    if (store.aiEnabled && store.entries.length >= 2) {
      AIService(store).generateAIWeeklyInsight().then((ai) {
        if (ai == null || !mounted) return; // fallback failed, keep local
        setState(() => _aiInsight = ai);
      });
    }
    // Remember this week's local lines after the first frame so repeats can
    // retire on later visits (done off-build to avoid writing mid-render).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || store.entries.isEmpty) return;
      final local = PromptEngine(store.entries).generateWeeklyInsight(
          experiment: store.activeTideExperiment,
          anchor: store.anchors.isNotEmpty ? store.anchors.last : null);
      store.recordShownInsightLines(local.patterns);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery can only be accessed after initState completes.
    if (!_animationStarted && !_reduced) {
      _animationStarted = true;
      _breath.repeat(reverse: true);
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final entries = store.entries;
    final source = entries.isNotEmpty ? entries : demoDays();
    final weekAgo =
        DateTime.now().millisecondsSinceEpoch - 7 * 24 * 60 * 60 * 1000;
    final recent = source.where((e) => e.ts >= weekAgo).toList();
    final rows = recent.isNotEmpty ? recent : source;

    // Use the analysis engine for a richer weekly insight; fall back to the
    // original heuristic for demo data or edge cases.
    InsightParts insight;
    if (entries.isNotEmpty) {
      insight = PromptEngine(entries).generateWeeklyInsight(
          experiment: store.activeTideExperiment,
          anchor: store.anchors.isNotEmpty ? store.anchors.last : null);
      // Retire pattern lines already seen in earlier weeks, unless doing so
      // would empty the letter — the local engine is finite, so this keeps it
      // from becoming wallpaper between AI-enhanced readings.
      var patterns = insight.patterns;
      if (patterns.length > 1) {
        final fresh = patterns.where((p) => !_priorShown.contains(p)).toList();
        if (fresh.isNotEmpty) patterns = fresh;
      }
      insight = InsightParts(
        headline: insight.headline,
        count: insight.count,
        patterns: patterns,
        question: insight.question,
        thin: entries.isNotEmpty && recent.length < 3,
        crisis: insight.crisis,
        crisisMessage: insight.crisisMessage,
        fromAI: insight.fromAI,
      );
    } else {
      insight = _demoHeuristic(rows);
    }
    if (_aiInsight != null) insight = _aiInsight!;

    // Always-on, on-device crisis surfacing — independent of the AI layer or
    // the proxy being reachable. Calm panel only (honours the hard limit).
    if (!insight.crisis && entries.isNotEmpty) {
      final written = entries.where((e) => e.text.isNotEmpty).toList();
      final last5 =
          written.length > 5 ? written.sublist(written.length - 5) : written;
      if (containsCrisisLanguage(last5.map((e) => e.text))) {
        insight.crisis = true;
        insight.crisisMessage ??= kSafetyText;
      }
    }

    final evidence =
        rows.where((e) => e.text.isNotEmpty || e.isMoodEntry).toList();
    final lastFour =
        evidence.length > 4 ? evidence.sublist(evidence.length - 4) : evidence;
    final thin = insight.thin;

    final moodVA = store.currentMoodVA();
    final bgTint = moodVA == null ? null : seaTint(moodVA.$1, moodVA.$2);
    final bgBase = bgTint ?? kIvory;

    return Stack(
      children: [
        // Sea gradient background — a faint mood-tinted wash so the insight
        // surface feels like it floats on the living sea.
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgBase.withValues(alpha: .04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: 'a small surface', onBack: widget.onBack),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: kExhale,
                builder: (context, t, child) {
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - t)),
                      child: child,
                    ),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(kGutter, 4, kGutter, 28),
                  children: [
                    // "your week" sublabel with a slow gold shimmer
                    AnimatedBuilder(
                      animation: _breath,
                      builder: (context, _) {
                        final t = _reduced ? .5 : _breath.value;
                        final shimmer = .55 + t * .35;
                        return Text(
                            'your week \u00b7 a reflection from what you kept',
                            style: MenteType.caption.copyWith(
                                letterSpacing: .18 * 10.5,
                                color: kOro.withValues(alpha: shimmer)));
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('a small surface from this week',
                        style: MenteType.eyebrow.copyWith(
                            letterSpacing: .22 * 10,
                            color: kOro.withValues(alpha: .75))),
                    const SizedBox(height: 8),
                    // The headline inside a soft, breathing lens — like the home
                    // screen's check-in lens but smaller, with a slow horizontal
                    // drift so it feels like light moving across the sea floor.
                    AnimatedBuilder(
                      animation: Listenable.merge([_breath, _drift]),
                      builder: (context, _) {
                        final bt = _reduced ? .5 : _breath.value;
                        final dt = _reduced ? .5 : _drift.value;
                        final va = _weekWeather();
                        final base = ivory(.94);
                        final tint = va == null
                            ? base
                            : Color.lerp(
                                base, seaTint(va.$1, va.$2), .10 + bt * .12)!;
                        final driftDx = 4 * math.sin(dt * 2 * math.pi);
                        final scale = 1 + (bt - .5) * .012;
                        return Transform.translate(
                          offset: Offset(driftDx, 0),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: s16, vertical: s16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: tint.withValues(alpha: .18)),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    tint.withValues(alpha: .08),
                                    tint.withValues(alpha: .03),
                                  ],
                                ),
                              ),
                              child: Text(
                                  thin
                                      ? 'Not enough weather for a pattern yet'
                                      : stripTags(insight.headline),
                                  style: MenteType.title
                                      .copyWith(height: 1.25, color: tint)),
                            ),
                          ),
                        );
                      },
                    ),
                    if (store.aiEnabled) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: s8, vertical: s4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: kOro.withValues(alpha: .4)),
                          ),
                          child: Text('deeper reflection',
                              style: MenteType.eyebrow.copyWith(
                                  letterSpacing: .16 * 9.5,
                                  color: kOro.withValues(alpha: .85))),
                        ),
                      ),
                    ],
                    if (insight.crisis &&
                        (insight.crisisMessage ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      // Calm crisis panel: a deeper indigo gradient with serif
                      // text — never red, never alarmed, never mood-tinted.
                      Container(
                        padding: const EdgeInsets.all(s16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              kSea.uc[0].withValues(alpha: .25),
                              kSea.uc[1].withValues(alpha: .15),
                            ],
                          ),
                          border: Border.all(
                              color: kSea.uc[0].withValues(alpha: .20)),
                        ),
                        child: Text(insight.crisisMessage!,
                            style: MenteType.bodySerif
                                .copyWith(height: 1.6, color: textPrimary)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _para(thin
                        ? 'A few pages are here, but not enough to call repetition a pattern. They can simply remain pages for now.'
                        : insight.count),
                    if (!thin) ...[
                      for (final (i, p) in insight.patterns.indexed) ...[
                        if (i > 0) const SizedBox(height: 4),
                        _patternCard(p, i),
                      ],
                      if (insight.question.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _patternCard(insight.question, insight.patterns.length),
                      ],
                    ],
                    const SizedBox(height: 18),
                    Text('\u2014 mentesana',
                        style: GoogleFonts.alice(
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            color: textSecondary)),
                    if (lastFour.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text('pages underneath',
                          style: MenteType.eyebrow.copyWith(
                              letterSpacing: .22 * 10, color: textFaint)),
                      const SizedBox(height: 8),
                      for (final e in lastFour) _sourceRow(e),
                    ],
                    const SizedBox(height: 18),
                    Text(
                        'patterns are invitations, not conclusions. each observation should lead back to the pages underneath.',
                        style: GoogleFonts.alice(
                            fontStyle: FontStyle.italic,
                            fontSize: 11.5,
                            height: 1.5,
                            color: textFaint)),
                    if (!thin) _experimentInvite(store),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// A pattern observation rendered as a floating card with staggered
  /// entrance animation — each card drifts upward as the user scrolls,
  /// like observations surfacing from deeper water.
  Widget _patternCard(String text, int index) {
    final va = widget.store.currentMoodVA();
    final tint = va == null ? null : seaTint(va.$1, va.$2);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 120),
      curve: kExhale,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: BreathingCard(
        tint: tint,
        radius: BorderRadius.circular(14),
        intensity: .6,
        child: Padding(
          padding: const EdgeInsets.all(s16),
          child: Text.rich(
            TextSpan(
                children: richTextSpans(
              text,
              MenteType.bodySerif.copyWith(height: 1.62, color: textSecondary),
              GoogleFonts.alice(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  height: 1.62,
                  color: kOro.withValues(alpha: .92)),
            )),
          ),
        ),
      ),
    );
  }

  /// Closes the loop from the surface side: when a pattern is here and no
  /// small experiment is underway, offer to gently try one. It only ever
  /// seeds a draft the user confirms — nothing starts on its own, and there
  /// is no goal, streak, or score attached.
  Widget _experimentInvite(AppStore store) {
    if (store.activeTideExperiment != null) return const SizedBox.shrink();
    if (store.entries.length < 3) return const SizedBox.shrink();
    final draft = PromptEngine(store.entries).suggestExperiment();
    if (draft == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: s24),
      child: InkWell(
        onTap: () {
          store.startTideExperiment(draft);
          setState(() {});
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1C2A2E),
              content: Text('a small thing to try is waiting in Tide Lab.',
                  style: TextStyle(color: textSecondary)),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(s16),
          // v2 — a pool of light, not a bordered box.
          decoration: seaCard(fill: .075, radius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('if you would like to try a small thing',
                  style: MenteType.eyebrow.copyWith(
                      letterSpacing: 1.8, color: kRiva.withValues(alpha: .8))),
              const SizedBox(height: 8),
              Text(draft.title,
                  style: MenteType.heading.copyWith(color: textPrimary)),
              const SizedBox(height: 6),
              Text(draft.action,
                  style: MenteType.bodySerif
                      .copyWith(height: 1.5, color: textSecondary)),
              const SizedBox(height: 8),
              Text('only to notice — no goal, nothing to keep up.',
                  style: GoogleFonts.alice(
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                      color: textFaint)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _para(String html) {
    return Padding(
      padding: const EdgeInsets.only(bottom: s8),
      child: Text.rich(
        TextSpan(
            children: richTextSpans(
          html,
          MenteType.bodySerif.copyWith(height: 1.62, color: textSecondary),
          GoogleFonts.alice(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.62,
              color: kOro.withValues(alpha: .92)),
        )),
      ),
    );
  }

  Widget _sourceRow(JournalEntry e) {
    final d = e.date;
    final label =
        '${kDowsShort[d.weekday % 7]} ${d.day} ${kMonthsShort[d.month - 1]}';
    final title = e.title.isNotEmpty
        ? e.title
        : ((e.word ?? '').isNotEmpty ? e.word! : 'a kept page');
    return Padding(
      padding: const EdgeInsets.only(bottom: s8),
      // Each source row wears its own kept weather and breathes on the
      // shared kBreath rhythm, so the "pages underneath" feel alive (#6/#7).
      child: BreathingCard(
        tint: (e.v != null && e.a != null) ? seaTint(e.v!, e.a!) : null,
        radius: BorderRadius.circular(11),
        child: InkWell(
          onTap: () => widget.onOpenEntry(e),
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: s12, vertical: s12),
            child: Text('$label \u00b7 $title',
                style: MenteType.caption.copyWith(color: textSecondary)),
          ),
        ),
      ),
    );
  }

  /// The original heuristic fallback for demo data or edge cases
  /// (JS renderInsight else-branch), verbatim strings.
  InsightParts _demoHeuristic(List<JournalEntry> rows) {
    final wordCounts = <String, int>{};
    final tagCounts = <String, int>{};
    const supportive = [
      'walk',
      'outside',
      'tea',
      'friend',
      'call',
      'sleep',
      'rest',
      'music',
      'swim',
      'food',
    ];
    final supports = <String, int>{};
    for (final e in rows) {
      final w = e.word;
      if (w != null && w.isNotEmpty) {
        wordCounts[w] = (wordCounts[w] ?? 0) + 1;
      }
      if (e.tag.isNotEmpty) {
        tagCounts[e.tag] = (tagCounts[e.tag] ?? 0) + 1;
      }
      final text = e.text.toLowerCase();
      for (final s in supportive) {
        if (text.contains(s)) supports[s] = (supports[s] ?? 0) + 1;
      }
    }
    String? top(Map<String, int> m) {
      final list =
          stableSortedByDesc(m.entries.toList(), (x) => x.value.toDouble());
      return list.isNotEmpty ? list.first.key : null;
    }

    final topWord = top(wordCounts);
    final topTag = top(tagCounts);
    final topSupport = top(supports);
    final written = rows.where((e) => e.text.isNotEmpty).length;
    final entries = widget.store.entries;
    final weekAgo =
        DateTime.now().millisecondsSinceEpoch - 7 * 24 * 60 * 60 * 1000;
    final recentCount = (entries.isNotEmpty ? entries : rows)
        .where((e) => e.ts >= weekAgo)
        .length;
    return InsightParts(
      headline: topWord != null
          ? 'A week with $topWord in it'
          : 'What the water held this week',
      count:
          '${rows.length} check-in${rows.length == 1 ? '' : 's'} this week; $written became a page.',
      patterns: [
        if (topTag != null)
          'The context <em>$topTag</em> appeared most often in what you chose to keep.'
        else if (topWord != null)
          'The word <em>$topWord</em> returned more than once. It may be worth sitting with, not solving.'
        else
          'You gave the week a place to land, one check-in at a time.',
        if (topSupport != null)
          'You mentioned <em>$topSupport</em> in a few pages. Not proof of a cause — simply something you may want to keep near.'
        else
          'No pattern is required. Sometimes noticing the weather is the whole practice.',
      ],
      question: topTag != null
          ? 'When <em>$topTag</em> comes up again, what would you like to remember?'
          : 'What is one small thing you would like to carry into next week?',
      thin: entries.isNotEmpty && recentCount < 3,
    );
  }
}
