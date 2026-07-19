// Mentesana — the archive ('deep' door).
// Structural screen: typography on the sea. No cards, no boxes, no counter.
// Entries read as left-aligned serif rows, grouped by day with whitespace.

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(title: 'the archive', onBack: widget.onBack),
        const WaveDivider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(kGutter, 0, kGutter, 4),
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
            padding: const EdgeInsets.fromLTRB(kGutter, 10, kGutter, 0),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [for (final t in tags) _tagFilterLink(t)],
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
              padding: const EdgeInsets.fromLTRB(kGutter, 14, kGutter, 28),
              children: [
                if (real.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: s16),
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
    );
  }

  Widget _tagFilterLink(String tag) {
    final active = tag == _tagFilter;
    return InkWell(
      onTap: () => setState(() => _tagFilter = _tagFilter == tag ? null : tag),
      child: Text('#$tag',
          style: MenteType.caption
              .copyWith(color: active ? kRivaLight : ivory(.6))),
    );
  }

  Widget _dayGroup(int ts, List<JournalEntry> items) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return Padding(
      padding: const EdgeInsets.only(bottom: s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${kDowsShort[d.weekday % 7]} ${d.day} ${kMonthsShort[d.month - 1]}',
              style: MenteType.caption.copyWith(color: textFaint)),
          const SizedBox(height: 6),
          for (final e in items) _entryRow(e),
        ],
      ),
    );
  }

  Widget _entryRow(JournalEntry e) {
    return InkWell(
      onTap: () => widget.onOpenEntry(e),
      child: Padding(
        padding: const EdgeInsets.only(bottom: s12, top: s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatTime12(e.date),
                style: MenteType.caption.copyWith(color: textFaint)),
            if ((e.word ?? '').isNotEmpty)
              Text(e.word!,
                  style: MenteType.heading.copyWith(color: textPrimary)),
            if (e.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: s4),
                child: Text.rich(
                  TextSpan(
                      children: journalTextSpans(
                    e.text,
                    MenteType.caption
                        .copyWith(height: 1.5, color: textSecondary),
                  )),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (e.tag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: s4),
                child: Text('#$e.tag',
                    style: MenteType.caption.copyWith(color: kRiva)),
              ),
            if (e.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: s4),
                child: Text(
                    '\u25cc ${e.attachments.length} attachment${e.attachments.length == 1 ? '' : 's'}',
                    style: MenteType.caption.copyWith(color: textSecondary)),
              ),
          ],
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
