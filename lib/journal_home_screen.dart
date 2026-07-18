// Mentesana — the journal home (the writing desk's front room).
// Structural screen (left-aligned, sea as container).
//
// Layout zones (charter):
//  - sky (top of screen): greeting + prompt question
//  - horizon: primary 'begin' action
//  - water (below): library, unfinished, recent pages, tide, anchor
// No cards, no boxes. Typography placed directly on the scene,
// hairline rules only where whitespace alone doesn't separate.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'currents_surfaces.dart';
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'sea_icons.dart';
import 'theme.dart';

/// Calendar icon for the header action.
const _calendarIcon = SeaIconData(
  ['M8 3.5V7M16 3.5V7', 'M4.5 11c2.5-.9 5-.9 7.5 0s5 .9 7.5 0'],
  rects: [
    [3.5, 5, 17, 15.5, 3],
  ],
);

/// jhRefreshPrompt — 'try another angle'.
const _refreshIcon = SeaIconData([
  'M20 11a8 8 0 0 0-14.5-4.5',
  'M4.4 3.9c-.4 1.7-.5 3.4-.3 5.1 1.7.2 3.4.1 5.1-.3',
  'M4 13a8 8 0 0 0 14.5 4.5',
  'M19.6 20.1c.4-1.7.5-3.4.3-5.1-1.7-.2-3.4-.1-5.1.3',
]);

/// jhWrite — the anchor-write arrow.
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

class _JournalHomeScreenState extends State<JournalHomeScreen> {
  int _promptIndex = 0;
  List<String>? _promptOptionsCache;

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JournalHomeScreen old) {
    super.didUpdateWidget(old);
    if (old.aiCachedPrompt != widget.aiCachedPrompt) {
      _promptOptionsCache = null;
    }
  }

  List<String> get _promptOptions => _promptOptionsCache ??=
      dailyPromptOptions(widget.store, aiCachedPrompt: widget.aiCachedPrompt);

  String get _currentPrompt {
    final options = _promptOptions;
    return options[_promptIndex % options.length];
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final entries = store.entries;
    final draft = store.readJournalDraft();
    final recent = entries
        .where((e) => e.text.isNotEmpty)
        .toList()
        .reversed
        .take(3)
        .toList();

    JournalEntry? lastEntry;
    for (final e in entries) {
      if (lastEntry == null || e.ts > lastEntry.ts) {
        lastEntry = e;
      }
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
      if (e.tideAt == null) {
        continue;
      }
      if (returned == null && e.tideAt! <= nowMs) {
        returned = e;
      }
      if (waiting == null && e.tideAt! > nowMs) {
        waiting = e;
      }
    }

    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head(),
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
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
                    children: [
                      // Sky zone: greeting.
                      Text(
                        journalGreeting(store),
                        style: MenteType.display.copyWith(
                          height: 1.18,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: s16),

                      // Return card — welcome back, if a gap warrants it.
                      if (lastEntry != null && gapDays >= 5)
                        _returnBlock(lastEntry),

                      // Continuity — today's pages so far.
                      if (latestToday != null)
                        _continuityBlock(latestToday, todayPages.length),

                      if (lastEntry != null && gapDays >= 5 ||
                          latestToday != null)
                        _hair(),

                      // Today's prompt — large serif question in the sky zone.
                      _promptBlock(),
                      const SizedBox(height: s24),

                      // Water zone: library + currents + archive + tide.
                      _sectionLabel('pages'),
                      const SizedBox(height: s8),
                      _libraryRow(),
                      TideReturnsCard(
                        store: store,
                        onWrite: widget.onWriteFromPrompt,
                      ),
                      AnchorCard(
                        store: store,
                        onWrite: widget.onWriteFromPrompt,
                      ),
                      if (draft != null) ...[
                        _hair(),
                        _sectionLabel('unfinished'),
                        const SizedBox(height: s8),
                        _draftRow(draft),
                        const SizedBox(height: s4),
                        Text(
                          'held safe as you wrote — nothing here is lost.',
                          style: GoogleFonts.alice(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: textFaint,
                          ),
                        ),
                      ],
                      _hair(),
                      _sectionLabel('recent pages'),
                      const SizedBox(height: s8),
                      if (recent.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: s4),
                          child: Text(
                            'a blank page is still a place to arrive.',
                            style: GoogleFonts.alice(
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              color: textFaint,
                            ),
                          ),
                        )
                      else
                        for (final e in recent) _recentRow(e),
                      if (attachmentCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: s4),
                          child: Text(
                            '$attachmentCount recent attachment${attachmentCount == 1 ? '' : 's'} kept with your pages.',
                            style: MenteType.caption.copyWith(color: textFaint),
                          ),
                        ),
                      const SizedBox(height: s8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onAllPages,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: s4),
                          child: Text(
                            'all pages in the archive',
                            style: GoogleFonts.alice(
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                              color: textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: ivory(.35),
                            ),
                          ),
                        ),
                      ),
                      if (returned != null) ...[
                        _hair(),
                        _tideBlock(
                          title: 'the tide returned this',
                          body: '\u201c${returned.tideLine}\u201d',
                          note: 'left with a page you kept earlier',
                        ),
                      ] else if (waiting != null) ...[
                        _hair(),
                        _tideBlock(
                          title: 'the tide is holding a line',
                          body:
                              'it will resurface when there has been a little distance.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Head — left-aligned title + calendar action.
  // ---------------------------------------------------------------------

  Widget _head() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(s24, s16, s24, s8),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: s4,
                vertical: s8,
              ),
              child: StrokeIcon(
                SeaIcons.back,
                size: 18,
                color: textSecondary,
                strokeWidth: 1.65,
              ),
            ),
          ),
          const SizedBox(width: s12),
          Text(
            'journal',
            style: MenteType.title.copyWith(
              color: textSecondary,
              fontSize: 20,
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Open calendar',
            child: InkWell(
              onTap: widget.onCalendar,
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: StrokeIcon(
                    _calendarIcon,
                    size: 20,
                    color: textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Sky zone blocks
  // ---------------------------------------------------------------------

  Widget _returnBlock(JournalEntry lastEntry) {
    final middleOf = lastEntry.tag.isNotEmpty
        ? lastEntry.tag
        : lastEntry.title.isNotEmpty
            ? lastEntry.title
            : lastEntry.word;
    return Padding(
      padding: const EdgeInsets.only(top: s8),
      child: Text.rich(
        TextSpan(
          style: MenteType.bodySerif.copyWith(
            height: 1.6,
            color: textSecondary,
          ),
          children: [
            TextSpan(
              text: 'welcome back. ',
              style: GoogleFonts.alice(
                fontStyle: FontStyle.italic,
                color: textPrimary,
              ),
            ),
            const TextSpan(text: 'The sea kept your place'),
            if (middleOf != null && middleOf.isNotEmpty) ...[
              const TextSpan(text: ' — last time, you were with '),
              TextSpan(
                text: middleOf,
                style: GoogleFonts.alice(
                  fontStyle: FontStyle.italic,
                  color: textSecondary,
                ),
              ),
            ],
            const TextSpan(
              text:
                  '. Pick up there, or start fresh. Nothing was lost while you were away.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _continuityBlock(JournalEntry latestToday, int count) {
    final title = latestToday.title.isNotEmpty
        ? latestToday.title
        : titleFromPage(latestToday.text).isNotEmpty
            ? titleFromPage(latestToday.text)
            : 'a page from today';
    return Padding(
      padding: const EdgeInsets.only(top: s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'today, so far · $count page${count == 1 ? '' : 's'}',
            style: MenteType.caption.copyWith(color: textFaint),
          ),
          const SizedBox(height: s4),
          Text(
            title,
            style: MenteType.heading.copyWith(
              height: 1.25,
              color: textPrimary,
            ),
          ),
          if (latestToday.pendingTranscription) ...[
            const SizedBox(height: 3),
            Text(
              'a voice note is still transcribing in the background…',
              style: MenteType.caption.copyWith(
                fontStyle: FontStyle.italic,
                color: kRivaLight.withValues(alpha: .85),
              ),
            ),
          ],
          const SizedBox(height: s4),
          Text(
            latestToday.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: MenteType.bodySerif.copyWith(
              height: 1.55,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: s12),
          Row(
            children: [
              _textLink(
                'continue this page',
                onTap: () => widget.onContinueEntry(latestToday),
                primary: true,
              ),
              const SizedBox(width: s16),
              _textLink('a new page', onTap: widget.onFreshPage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _promptBlock() {
    if (widget.store.isPromptDismissedToday()) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Not today — that is all right.',
              style: GoogleFonts.alice(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
          _textLink(
            'show it again',
            onTap: () => setState(() {
              widget.store.setPromptDismissed(false);
            }),
          ),
        ],
      );
    }
    final prompt = stripTags(_currentPrompt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                prompt,
                style: MenteType.title.copyWith(
                  height: 1.35,
                  color: textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Try another angle',
              child: InkWell(
                onTap: () => setState(() {
                  _promptIndex = (_promptIndex + 1) % _promptOptions.length;
                }),
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: StrokeIcon(
                      _refreshIcon,
                      size: 17,
                      color: textFaint,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: s16),
        Row(
          children: [
            _textLink(
              'begin',
              primary: true,
              onTap: () => widget.onWriteFromPrompt(
                stripTags(_currentPrompt),
              ),
            ),
            const SizedBox(width: s16),
            _textLink(
              'not today',
              onTap: () => setState(() {
                widget.store.setPromptDismissed(true);
              }),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Water zone rows
  // ---------------------------------------------------------------------

  Widget _libraryRow() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onLibrary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: s12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'prompt library',
                    style: MenteType.heading.copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: s4),
                  Text(
                    'questions to help you find where to begin.',
                    style: MenteType.caption.copyWith(color: textFaint),
                  ),
                ],
              ),
            ),
            StrokeIcon(
              _anchorWriteIcon,
              size: 18,
              color: textFaint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _draftRow(JournalDraft draft) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onResumeDraft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'unfinished page',
              style: MenteType.heading.copyWith(color: textPrimary),
            ),
            const SizedBox(height: s4),
            Text(
              draft.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MenteType.bodySerif.copyWith(
                height: 1.55,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentRow(JournalEntry e) {
    final d = e.date;
    final meta =
        '${d.day} ${kMonthsShort[d.month - 1].toLowerCase()} · ${hhmm(d)}';
    final kept = e.attachments.length;
    final title = e.title.isNotEmpty
        ? e.title
        : titleFromPage(e.text).isNotEmpty
            ? titleFromPage(e.text)
            : ((e.word ?? '').isNotEmpty ? e.word! : 'journal');
    return Padding(
      padding: const EdgeInsets.only(bottom: s8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onOpenEntry(e),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(meta,
                      style: MenteType.caption.copyWith(color: textFaint)),
                  if (e.pendingTranscription)
                    Text(
                      'transcribing voice note…',
                      style: MenteType.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: kRivaLight.withValues(alpha: .85),
                      ),
                    )
                  else if (kept > 0)
                    Text(
                      '$kept kept with it',
                      style: MenteType.caption.copyWith(color: kRiva),
                    ),
                ],
              ),
              const SizedBox(height: s4),
              Text(
                title,
                style: MenteType.heading.copyWith(color: textPrimary),
              ),
              const SizedBox(height: s4),
              Text(
                e.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MenteType.bodySerif.copyWith(
                  height: 1.55,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tideBlock(
      {required String title, required String body, String? note}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: MenteType.heading.copyWith(color: textPrimary),
          ),
          const SizedBox(height: s4),
          Text(
            body,
            style: GoogleFonts.alice(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              height: 1.55,
              color: textSecondary,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: s4),
            Text(note, style: MenteType.caption.copyWith(color: textFaint)),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Primitives
  // ---------------------------------------------------------------------

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(top: s4, bottom: s4),
        child: Text(
          label,
          style: MenteType.caption.copyWith(color: textFaint),
        ),
      );

  Widget _hair() => const Padding(
        padding: EdgeInsets.symmetric(vertical: s12),
        child: SizedBox(
          height: 0.5,
          width: double.infinity,
          child: ColoredBox(color: Color(0x14F2EEE6)),
        ),
      );

  Widget _textLink(
    String label, {
    required VoidCallback onTap,
    bool primary = false,
  }) {
    final color = primary ? kRivaLight : textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: s4, vertical: s4),
        child: Text(
          label,
          style: GoogleFonts.alice(
            fontStyle: FontStyle.italic,
            fontSize: 14,
            color: color,
            decoration: TextDecoration.underline,
            decorationColor: color.withValues(alpha: primary ? .6 : .35),
          ),
        ),
      ),
    );
  }
}
