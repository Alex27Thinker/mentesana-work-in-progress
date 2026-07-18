// Mentesana — the archive ('deep' door).
// 1:1 port of #screen-archive + renderArchive from the Vite prototype.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'theme.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({
    super.key,
    required this.store,
    required this.onBack,
    required this.onOpenEntry,
  });

  final AppStore store;
  final VoidCallback onBack;
  final ValueChanged<JournalEntry> onOpenEntry;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _search = TextEditingController();
  String? _tagFilter; // JS archiveTagFilter

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final real = widget.store.entries.reversed.toList();
    final rows = real.isNotEmpty ? real : demoDays();
    final tags = <String>[];
    for (final e in rows) {
      if (e.tag.isNotEmpty && !tags.contains(e.tag)) tags.add(e.tag);
    }
    if (_tagFilter != null && !tags.contains(_tagFilter)) _tagFilter = null;
    final query = _search.text.trim().toLowerCase();
    var filtered = rows;
    if (_tagFilter != null) {
      filtered = filtered.where((e) => e.tag == _tagFilter).toList();
    }
    if (query.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              (e.word ?? '').toLowerCase().contains(query) ||
              e.text.toLowerCase().contains(query) ||
              e.tag.toLowerCase().contains(query))
          .toList();
    }
    final noMatch =
        (query.isNotEmpty || _tagFilter != null) && filtered.isEmpty;

    // Group by calendar day in insertion order; items ascend inside a day.
    final groups = <({int ts, List<JournalEntry> items})>[];
    final byKey = <String, List<JournalEntry>>{};
    for (final e in filtered) {
      final d = e.date;
      final key = '${d.year}-${d.month}-${d.day}';
      var items = byKey[key];
      if (items == null) {
        items = <JournalEntry>[];
        byKey[key] = items;
        groups.add((ts: e.ts, items: items));
      }
      items.add(e);
    }
    for (final g in groups) {
      g.items.sort((x, y) => x.ts.compareTo(y.ts));
    }

    final moodVA = widget.store.currentMoodVA();
    final bgTint = moodVA == null ? null : seaTint(moodVA.$1, moodVA.$2);
    final bgBase = bgTint ?? kIvory;

    return Stack(
      children: [
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
            ScreenHeader(title: 'the archive', onBack: widget.onBack),
            const WaveDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: MenteType.bodySerif.copyWith(color: textSecondary),
                cursorColor: kRiva,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'find a word, a page, a tag\u2026',
                  hintStyle: MenteType.bodySerif.copyWith(color: textDisabled),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textDisabled)),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: kRiva)),
                ),
              ),
            ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [for (final t in tags) _tagChip(t)],
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                  children: [
                    Text(
                        '${rows.length} page${rows.length == 1 ? '' : 's'}, so far',
                        style: MenteType.caption.copyWith(
                            letterSpacing: .14 * 11, color: textFaint)),
                    if (real.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: s8),
                        child: Text(
                            'a sample sea — your own days will gather here from your first keep',
                            style: GoogleFonts.alice(
                                fontStyle: FontStyle.italic,
                                fontSize: 12.5,
                                color: textFaint)),
                      ),
                    if (noMatch)
                      Padding(
                        padding: const EdgeInsets.only(top: s16),
                        child: Text('nothing matches — try another word.',
                            style: GoogleFonts.alice(
                                fontStyle: FontStyle.italic,
                                fontSize: 13.5,
                                color: textFaint)),
                      )
                    else
                      for (final g in groups) _dayGroup(g.ts, g.items),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tagChip(String tag) {
    final active = tag == _tagFilter;
    return InkWell(
      onTap: () => setState(() => _tagFilter = _tagFilter == tag ? null : tag),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: s8, vertical: s4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: active ? kRiva.withValues(alpha: .75) : ivory(.18)),
          color: active ? kRiva.withValues(alpha: .14) : Colors.transparent,
        ),
        child: Text('#$tag',
            style: MenteType.eyebrow.copyWith(
                letterSpacing: .08 * 10,
                color: active ? kRivaLight : ivory(.6))),
      ),
    );
  }

  Widget _dayGroup(int ts, List<JournalEntry> items) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return Padding(
      padding: const EdgeInsets.only(top: s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Text(kDowsShort[d.weekday % 7],
                    style: MenteType.eyebrow
                        .copyWith(letterSpacing: .16 * 10, color: textFaint)),
                Text('${d.day}',
                    style: MenteType.title.copyWith(color: textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [for (final e in items) _entryRow(e)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryRow(JournalEntry e) {
    final sky = kSky.bilerp(e.v ?? 0, e.a ?? 0);
    final sea = kSea.bilerp(e.v ?? 0, e.a ?? 0);
    final tint = (e.v != null && e.a != null) ? seaTint(e.v!, e.a!) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: s8),
      child: InkWell(
        onTap: () => widget.onOpenEntry(e),
        borderRadius: BorderRadius.circular(12),
        child: BreathingCard(
          tint: tint,
          fill: .05,
          border: .08,
          radius: BorderRadius.circular(12),
          intensity: .5,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        sky[1].withValues(alpha: .9),
                        sea[1].withValues(alpha: .95),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatTime12(e.date),
                            style:
                                MenteType.caption.copyWith(color: textFaint)),
                        if ((e.word ?? '').isNotEmpty)
                          Text(e.word!,
                              style: MenteType.heading
                                  .copyWith(color: textPrimary)),
                        if (e.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: s4),
                            child: Text.rich(
                              TextSpan(
                                  children: journalTextSpans(
                                e.text,
                                MenteType.caption.copyWith(
                                    height: 1.5, color: textSecondary),
                              )),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (e.tag.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: s4),
                            child: Text(e.tag,
                                style: MenteType.eyebrow
                                    .copyWith(letterSpacing: .9, color: kRiva)),
                          ),
                        if (e.attachments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: s4),
                            child: Text(
                                '\u25cc ${e.attachments.length} attachment${e.attachments.length == 1 ? '' : 's'}',
                                style: MenteType.eyebrow
                                    .copyWith(letterSpacing: .9, color: kRiva)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// JS fmtTime — toLocaleTimeString hour numeric, minute 2-digit (12h clock).
String formatTime12(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = '${d.minute}'.padLeft(2, '0');
  return '$h:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
}
