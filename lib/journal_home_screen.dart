// Mentesana — the journal home (the writing desk's front room).
// 1:1 port of #screen-journalhome + renderJournalHome / renderTodayCard
// from the Vite prototype.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'currents_surfaces.dart';
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'theme.dart';
import 'sea_icons.dart';

/// Header calendar icon (verbatim path data from index.html).
const _calendarIcon = SeaIconData(
  ['M8 3.5V7M16 3.5V7', 'M4.5 11c2.5-.9 5-.9 7.5 0s5 .9 7.5 0'],
  rects: [
    [3.5, 5, 17, 15.5, 3],
  ],
);

/// jhRefreshPrompt — 'try another angle' (verbatim path data).
const _refreshIcon = SeaIconData([
  'M20 11a8 8 0 0 0-14.5-4.5',
  'M4.4 3.9c-.4 1.7-.5 3.4-.3 5.1 1.7.2 3.4.1 5.1-.3',
  'M4 13a8 8 0 0 0 14.5 4.5',
  'M19.6 20.1c.4-1.7.5-3.4.3-5.1-1.7-.2-3.4-.1-5.1.3',
]);

/// jhWrite — the anchor-write arrow (verbatim path data).
const _anchorWriteIcon = SeaIconData([
  'M5 12.6c4.3-.9 8.7-.9 13-.4',
  'M13 6.3c2.4 1.7 4.3 3.6 5.7 5.9-1.4 2.3-3.3 4.2-5.7 5.9',
]);

class JournalHomeScreen extends StatefulWidget {
  const JournalHomeScreen({
    super.key,
    required this.store,
    required this.aiCachedPrompt,
    required this.onBack,
    required this.onCalendar,
    required this.onLibrary,
    required this.onAllPages,
    required this.onFreshPage,
    required this.onResumeDraft,
    required this.onContinueEntry,
    required this.onOpenEntry,
    required this.onWriteFromPrompt,
  });

  final AppStore store;
  final String? aiCachedPrompt;
  final VoidCallback onBack;
  final VoidCallback onCalendar;
  final VoidCallback onLibrary;
  final VoidCallback onAllPages;
  final VoidCallback onFreshPage;
  final VoidCallback onResumeDraft;
  final ValueChanged<JournalEntry> onContinueEntry;
  final ValueChanged<JournalEntry> onOpenEntry;
  final ValueChanged<String> onWriteFromPrompt;

  @override
  State<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends State<JournalHomeScreen>
    with SingleTickerProviderStateMixin {
  int _promptIndex = 0; // JS promptIndex
  List<String>? _promptOptionsCache; // JS promptOptionsCache
  late final AnimationController _breathCtrl =
      AnimationController(vsync: this, duration: kBreath);

  bool get _reduced =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced) {
      _breathCtrl.stop();
      _breathCtrl.value = .5;
    } else if (!_breathCtrl.isAnimating) {
      _breathCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JournalHomeScreen old) {
    super.didUpdateWidget(old);
    // The AI prompt arriving invalidates the cached pool (JS re-render).
    if (old.aiCachedPrompt != widget.aiCachedPrompt) {
      _promptOptionsCache = null;
    }
  }

  List<String> get _promptOptions => _promptOptionsCache ??=
      dailyPromptOptions(widget.store, aiCachedPrompt: widget.aiCachedPrompt);

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final entries = store.entries;
    final draft = store.readJournalDraft();
    final recent =
        entries.where((e) => e.text.isNotEmpty).toList().reversed.take(3).toList();

    // The return, designed: a silence is data the sea kept, never a failure.
    JournalEntry? lastEntry;
    for (final e in entries) {
      if (lastEntry == null || e.ts > lastEntry.ts) lastEntry = e;
    }
    final gapDays = lastEntry != null
        ? (DateTime.now().millisecondsSinceEpoch - lastEntry.ts) ~/ 86400000
        : 0;

    final startToday = DateTime.now();
    final todayStartMs =
        DateTime(startToday.year, startToday.month, startToday.day)
            .millisecondsSinceEpoch;
    final todayPages = entries
        .where((e) => e.text.isNotEmpty && e.ts >= todayStartMs)
        .toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    final latestToday = todayPages.isNotEmpty ? todayPages.first : null;

    final attachmentCount =
        recent.fold<int>(0, (n, e) => n + e.attachments.length);

    final tideLines = entries.where((e) => e.tideLine.isNotEmpty).toList()
      ..sort((a, b) => (a.tideAt ?? 1 << 62).compareTo(b.tideAt ?? 1 << 62));
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    JournalEntry? returned;
    JournalEntry? waiting;
    for (final e in tideLines) {
      if (e.tideAt == null) continue;
      if (returned == null && e.tideAt! <= nowMs) returned = e;
      if (waiting == null && e.tideAt! > nowMs) waiting = e;
    }

    // The living sea shows through here — no flat lighting film on top of it
    // (#5). The day's weather is carried by the mood tint on the cards below.
    final moodVA = store.currentMoodVA();
    final bgTint = moodVA == null ? null : seaTint(moodVA.$1, moodVA.$2);
    final bgBase = bgTint ?? kIvory;

    return Stack(
      children: [
        // Sea gradient background — a faint mood-tinted wash so the journal
        // home feels submerged in the living sea, not floating on a flat
        // dark surface.
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
            ScreenHeader(
          title: 'journal',
          onBack: widget.onBack,
          trailing: Padding(
            padding: const EdgeInsets.only(right: s4),
            child: Semantics(
              button: true,
              label: 'Open calendar',
              child: InkWell(
                onTap: widget.onCalendar,
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 56,
                  height: 44,
                  child: Center(
                      child: StrokeIcon(_calendarIcon,
                          size: 20, color: textSecondary)),
                ),
              ),
            ),
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
            children: [
              // Greeting breathes on the shared kBreath rhythm — a slow
              // opacity pulse so it feels like a voice speaking, not a label.
              AnimatedBuilder(
                animation: _breathCtrl,
                builder: (context, _) {
                  final t = _reduced ? .5 : _breathCtrl.value;
                  final opacity = .86 + t * .12;
                  return Opacity(
                    opacity: opacity,
                    child: Text(journalGreeting(store),
                        style: MenteType.title.copyWith(height: 1.2, color: textPrimary)),
                  );
                },
              ),
              const WaveDivider(height: 14, alpha: .10),
              if (lastEntry != null && gapDays >= 5)
                _returnCard(lastEntry),
              if (latestToday != null)
                _continuityCard(latestToday, todayPages.length),
              const WaveDivider(height: 16, alpha: .10),
              Text('today',
                  style: MenteType.eyebrow.copyWith(
                      letterSpacing: .22 * 10,
                      color: textFaint)),
              const SizedBox(height: 10),
              _todayCard(),
              const SizedBox(height: 12),
              _libraryCard(),
              // What the currents carried here: a worry the tide brought
              // back, or one small anchor mined from gentler days.
              TideReturnsCard(store: store, onWrite: widget.onWriteFromPrompt),
              AnchorCard(store: store, onWrite: widget.onWriteFromPrompt),
              if (draft != null) ...[
                const WaveDivider(height: 14, alpha: .10),
                Text('unfinished',
                    style: MenteType.eyebrow.copyWith(
                        letterSpacing: .22 * 10,
                        color: textFaint)),
                const SizedBox(height: 8),
                _draftCard(draft),
                const SizedBox(height: 6),
                Text('held safe as you wrote \u2014 nothing here is lost.',
                    style: GoogleFonts.alice(
                        fontStyle: FontStyle.italic,
                        fontSize: 11.5,
                        color: textFaint)),
              ],
              const WaveDivider(height: 18, alpha: .10),
              Text('recent pages',
                  style: MenteType.eyebrow.copyWith(
                      letterSpacing: .22 * 10,
                      color: textFaint)),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: s4),
                  child: Text('A blank page is still a place to arrive.',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: textFaint)),
                )
              else
                for (final e in recent) _recentRow(e),
              if (attachmentCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                    '$attachmentCount recent attachment${attachmentCount == 1 ? '' : 's'} kept with your pages.',
                    style: MenteType.caption.copyWith( color: textFaint)),
              ],
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: widget.onAllPages,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: s16, vertical: s8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: textDisabled),
                    ),
                    child: Text('all pages in the archive',
                        style: MenteType.caption.copyWith(
                            letterSpacing: .08 * 11.5,
                            color: textSecondary)),
                  ),
                ),
              ),
              if (returned != null)
                _tideCard(
                  title: 'the tide returned this',
                  body: '\u201c${returned.tideLine}\u201d',
                  note: 'left with a page you kept earlier',
                )
              else if (waiting != null)
                _tideCard(
                  title: 'the tide is holding a line',
                  body:
                      'It will resurface when there has been a little distance.',
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

  Widget _returnCard(JournalEntry lastEntry) {
    final middleOf = lastEntry.tag.isNotEmpty
        ? lastEntry.tag
        : lastEntry.title.isNotEmpty
            ? lastEntry.title
            : lastEntry.word;
    return Container(
      margin: const EdgeInsets.only(top: s12),
      padding: const EdgeInsets.all(s16),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('welcome back.',
              style: MenteType.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style:
                  MenteType.bodySerif.copyWith( height: 1.6, color: textSecondary),
              children: [
                const TextSpan(text: 'The sea kept your place'),
                if (middleOf != null && middleOf.isNotEmpty) ...[
                  const TextSpan(text: ' \u2014 last time, you were with '),
                  TextSpan(
                      text: middleOf,
                      style: GoogleFonts.alice(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: textSecondary)),
                ],
                const TextSpan(
                    text:
                        '. Pick up there, or start fresh. Nothing was lost while you were away.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _continuityCard(JournalEntry latestToday, int count) {
    final title = latestToday.title.isNotEmpty
        ? latestToday.title
        : titleFromPage(latestToday.text).isNotEmpty
            ? titleFromPage(latestToday.text)
            : 'a page from today';
    return Container(
      margin: const EdgeInsets.only(top: s12),
      padding: const EdgeInsets.all(s16),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'today, so far \u00b7 $count page${count == 1 ? '' : 's'}',
              style: MenteType.eyebrow.copyWith(
                  letterSpacing: .18 * 10,
                  color: textFaint)),
          const SizedBox(height: 6),
          Text(title,
              style: MenteType.heading.copyWith(height: 1.25, color: textPrimary)),
          if (latestToday.pendingTranscription) ...[
            const SizedBox(height: 3),
            Text('a voice note is still transcribing in the background…',
                style: MenteType.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    color: kRivaLight.withValues(alpha: .85))),
          ],
          const SizedBox(height: 4),
          Text(latestToday.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MenteType.bodySerif.copyWith(height: 1.55, color: textSecondary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _pillButton('continue this page',
                  primary: true,
                  onTap: () => widget.onContinueEntry(latestToday)),
              const SizedBox(width: 8),
              _pillButton('new page', onTap: widget.onFreshPage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayCard() {
    final store = widget.store;
    if (store.isPromptDismissedToday()) {
      // Breathes on the shared kBreath rhythm; the inner decoration is
      // transparent because BreathingCard supplies the seaCard surface.
      return BreathingCard(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: kExhale,
          padding: const EdgeInsets.all(s16),
          decoration: const BoxDecoration(),
          child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Not today \u2014 that is all right.',
                  style: GoogleFonts.alice(
                      fontStyle: FontStyle.italic,
                      fontSize: 13.5,
                      color: textSecondary)),
            ),
            TextButton(
              onPressed: () => setState(() {
                store.setPromptDismissed(false);
              }),
              child: Text('show it again',
                  style: MenteType.caption.copyWith(
                      letterSpacing: .06 * 11,
                      decoration: TextDecoration.underline,
                      decorationColor: ivory(.35),
                      color: textSecondary)),
            ),
          ],
        ),
      ),
      );
    }
    final options = _promptOptions;
    final prompt = options[_promptIndex % options.length];
    // Breathes on the shared kBreath rhythm; inner decoration is transparent
    // because BreathingCard supplies the seaCard surface.
    return BreathingCard(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: kExhale,
        padding: const EdgeInsets.all(s16),
        decoration: const BoxDecoration(),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('a page for today',
                  style: MenteType.heading.copyWith(color: textPrimary)),
              Semantics(
                button: true,
                label: 'Try another angle',
                child: InkWell(
                  onTap: () => setState(() {
                    _promptIndex = (_promptIndex + 1) % options.length;
                  }),
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                        child: StrokeIcon(_refreshIcon,
                            size: 17, color: textFaint)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
                children: richTextSpans(
              prompt,
              MenteType.bodySerif.copyWith( height: 1.6, color: textSecondary),
              TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14.5,
                  height: 1.6,
                  color: kOro.withValues(alpha: .92)),
            )),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() {
                  widget.store.setPromptDismissed(true);
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: s4, vertical: s8),
                  child: Text('not today',
                      style: MenteType.caption.copyWith(
                          letterSpacing: .08 * 11,
                          color: textFaint)),
                ),
              ),
              Semantics(
                button: true,
                label: 'Write from this',
                child: InkWell(
                  onTap: () =>
                      widget.onWriteFromPrompt(stripTags(prompt)),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: kRiva.withValues(alpha: .6)),
                      color: kRiva.withValues(alpha: .12),
                    ),
                    child: Center(
                        child: StrokeIcon(_anchorWriteIcon,
                            size: 19, color: kRivaLight)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _libraryCard() {
    // Breathes on the shared kBreath rhythm so the card floats on the sea.
    return BreathingCard(
      child: InkWell(
        onTap: widget.onLibrary,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: kExhale,
          padding: const EdgeInsets.all(s16),
          decoration: _cardBox(),
          child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('prompt library',
                      style: MenteType.bodySerif.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textSecondary)),
                  const SizedBox(height: 3),
                  Text('questions to help you find where to begin.',
                      style: MenteType.caption.copyWith( color: textFaint)),
                ],
              ),
            ),
            Text('\u2192',
                style: MenteType.heading.copyWith( color: textFaint)),
          ],
        ),
      ),
      ),
    );
  }

  Widget _draftCard(JournalDraft draft) {
    return InkWell(
      onTap: widget.onResumeDraft,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: kExhale,
        padding: const EdgeInsets.all(s16),
        decoration: _cardBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('unfinished page',
                style: MenteType.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            const SizedBox(height: 4),
            Text(draft.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MenteType.bodySerif.copyWith(height: 1.55, color: textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _recentRow(JournalEntry e) {
    final d = e.date;
    final meta =
        '${d.day} ${kMonthsShort[d.month - 1].toLowerCase()} \u00b7 ${hhmm(d)}';
    final kept = e.attachments.length;
    final title = e.title.isNotEmpty
        ? e.title
        : titleFromPage(e.text).isNotEmpty
            ? titleFromPage(e.text)
            : ((e.word ?? '').isNotEmpty ? e.word! : 'journal');
    return Padding(
      padding: const EdgeInsets.only(bottom: s8),
      child: InkWell(
        onTap: () => widget.onOpenEntry(e),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: kExhale,
          padding: const EdgeInsets.all(s12),
          decoration: _cardBox(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(meta,
                      style:
                          MenteType.caption.copyWith( color: textFaint)),
                  if (e.pendingTranscription)
                    Text('transcribing voice note…',
                        style: MenteType.eyebrow.copyWith(
                            fontStyle: FontStyle.italic,
                            color: kRivaLight
                                .withValues(alpha: .85)))
                  else if (kept > 0)
                    Text('$kept kept with it',
                        style: MenteType.eyebrow.copyWith(
                            letterSpacing: .6,
                            color: kRiva)),
                ],
              ),
              const SizedBox(height: 4),
              Text(title,
                  style: MenteType.bodySerif.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              const SizedBox(height: 3),
              Text(e.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MenteType.bodySerif.copyWith(height: 1.55, color: textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tideCard(
      {required String title, required String body, String? note}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: kExhale,
      margin: const EdgeInsets.only(top: s16),
      padding: const EdgeInsets.all(s16),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: MenteType.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textSecondary)),
          const SizedBox(height: 6),
          Text(body,
              style: GoogleFonts.alice(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  height: 1.55,
                  color: textSecondary)),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(note,
                style: MenteType.caption.copyWith( color: textFaint)),
          ],
        ],
      ),
    );
  }

  /// Soft, mood-tinted panel (#6/#7): every card wears the day's weather via
  /// the shared seaCard(), instead of a flat ivory rectangle.
  BoxDecoration _cardBox() {
    final va = widget.store.currentMoodVA();
    final tint = va == null ? null : seaTint(va.$1, va.$2);
    return seaCard(tint: tint);
  }

  Widget _pillButton(String label,
      {bool primary = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: s12, vertical: s8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: primary
                  ? kRiva.withValues(alpha: .6)
                  : ivory(.14)),
          color: primary
              ? kRiva.withValues(alpha: .12)
              : Colors.transparent,
        ),
        child: Text(label,
            style: MenteType.caption.copyWith(
                letterSpacing: .04 * 12,
                color: primary
                    ? kRivaLight
                    : ivory(.68))),
      ),
    );
  }
}

