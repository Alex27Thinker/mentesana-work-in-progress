// Mentesana — one kept page, up close.
// 1:1 port of #screen-entrydetail + renderEntryDetail / distanceText
// from the Vite prototype.
//
// PORT NOTE (documented deviation, see README): 'export page' opened a print
// window on the web; here the page text is copied to the clipboard and a
// quiet note says so.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'archive_screen.dart' show formatTime12;
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'sea_icons.dart';

class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({
    super.key,
    required this.store,
    required this.entry,
    required this.reads,
    required this.reduced,
    required this.onBack,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRevisitWeather,
    required this.onDeleted,
  });

  final AppStore store;
  final JournalEntry entry;
  final int reads; // in-session re-reading counter (JS detailReads)
  final bool reduced;
  final VoidCallback onBack;
  final ValueChanged<JournalEntry> onEdit;
  final ValueChanged<JournalEntry> onDuplicate;
  final ValueChanged<JournalEntry> onRevisitWeather;
  final VoidCallback onDeleted;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _moreOpen = false;
  bool _distance = false;
  bool _deleteArmed = false;
  bool _deleteReady = false; // after the breath: button becomes tappable
  Timer? _armTimer;
  Timer? _disarmTimer;
  String _exportNote = '';
  Timer? _exportNoteTimer;

  @override
  void dispose() {
    _armTimer?.cancel();
    _disarmTimer?.cancel();
    _exportNoteTimer?.cancel();
    super.dispose();
  }

  void _disarmDelete() {
    _armTimer?.cancel();
    _disarmTimer?.cancel();
    _deleteArmed = false;
    _deleteReady = false;
  }

  void _armDelete() {
    setState(() {
      _deleteArmed = true;
      _deleteReady = false;
    });
    _armTimer?.cancel();
    // Gentle, slow friction: the confirmation arrives after a breath,
    // and stands down on its own.
    _armTimer = Timer(
        Duration(milliseconds: widget.reduced ? 400 : 2200), () {
      if (!mounted || !_deleteArmed) return;
      setState(() => _deleteReady = true);
      _disarmTimer?.cancel();
      _disarmTimer = Timer(const Duration(milliseconds: 9000), () {
        if (!mounted || !_deleteArmed) return;
        setState(_disarmDelete);
      });
    });
  }

  void _deleteEntry() {
    _disarmDelete();
    widget.store.entries.remove(widget.entry);
    widget.store.saveEntries();
    widget.onDeleted();
  }

  void _restoreVersion(int index) {
    final e = widget.entry;
    if (index < 0 || index >= e.versions.length) return;
    final v = e.versions[index];
    e.versions = [
      ...e.versions,
      EntryVersion(
        editedAt: DateTime.now().millisecondsSinceEpoch,
        text: e.text,
        title: e.title,
        tag: e.tag,
        tideLine: e.tideLine,
      ),
    ];
    e.text = v.text;
    e.title = v.title;
    e.tag = v.tag;
    e.tideLine = v.tideLine;
    widget.store.saveEntries();
    setState(() {});
  }

  void _exportPage() {
    final e = widget.entry;
    final text = '${e.word ?? 'journal'}\n'
        '${e.date}\n\n'
        '${e.text.isNotEmpty ? e.text : 'A weather kept without words.'}';
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _exportNote = 'copied — printing needs a browser.');
    _exportNoteTimer?.cancel();
    _exportNoteTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _exportNote = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final hasMood = e.v != null && e.a != null;
    final sky = hasMood
        ? kSky.bilerp(e.v!, e.a!)
        : [const Color(0xFF33485C), const Color(0xFF101926)];
    final sea = hasMood
        ? kSea.bilerp(e.v!, e.a!)
        : [const Color(0xFF26313D), const Color(0xFF0A1119)];
    final prompt = e.prompt.isNotEmpty
        ? e.prompt
        : (e.reflectionStep == 'need'
            ? 'What do you need next?'
            : e.reflectionStep == 'meaning'
                ? 'What did it bring up?'
                : 'What happened just before this?');
    final real = widget.store.entries.contains(e);
    final d = e.date;
    final timeLine =
        '${kDowsLong[d.weekday % 7]}, ${kMonthsLong[d.month - 1]} ${d.day} \u00b7 ${formatTime12(d)}';
    final softenVisible =
        widget.reads >= 3 && e.text.isNotEmpty && !_distance;

    final moodTint = hasMood ? seaTint(e.v!, e.a!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: 'a kept page',
          onBack: widget.onBack,
          backLabel: 'return',
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: kExhale,
            builder: (context, t, w) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - t)),
                  child: w,
                ),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                BreathingCard(
                  tint: moodTint,
                  fill: .06,
                  border: .10,
                  radius: BorderRadius.circular(18),
                  intensity: .5,
                  child: Container(
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [sky[0], sea[1]],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(timeLine,
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: .14 * 11,
                        color: ivory(.45))),
                const SizedBox(height: 6),
                Text(e.title.isNotEmpty ? e.title : (e.word ?? 'journal'),
                    style: GoogleFonts.alice(
                        fontSize: 36, height: 1.15, color: ivory(.94))),
                if (e.texture.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(e.texture,
                      style: TextStyle(fontSize: 12.5, color: ivory(.55))),
                ],
                if ((e.afterWord ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                          fontSize: 13, height: 1.55, color: ivory(.68)),
                      children: [
                        const TextSpan(text: 'The weather began '),
                        TextSpan(
                            text: (e.word ?? '').isNotEmpty ? e.word : 'here',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const TextSpan(text: ' and later felt '),
                        TextSpan(
                            text: e.afterWord,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const TextSpan(
                            text:
                                '. No direction required \u2014 only a shift noticed.'),
                      ],
                    ),
                  ),
                ],
                if (e.tag.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('#${e.tag}',
                      style: TextStyle(fontSize: 12.5, color: ivory(.55))),
                ],
                _rule(),
                _label('the page began with'),
                const SizedBox(height: 6),
                Text(prompt,
                    style: GoogleFonts.alice(
                        fontStyle: FontStyle.italic,
                        fontSize: 14.5,
                        height: 1.5,
                        color: ivory(.7))),
                _rule(),
                _label('written'),
                const SizedBox(height: 8),
                if (e.text.isNotEmpty) ...[
                  Text.rich(
                    TextSpan(
                        children: journalTextSpans(
                      _distance ? distanceText(e.text) : e.text,
                      TextStyle(
                          fontSize: 19, height: 1.75, color: ivory(.88)),
                    )),
                  ),
                  if (_distance) ...[
                    const SizedBox(height: 10),
                    Text(
                        'at a distance — the same page, retold as if a friend wrote it. the sense matters more than the grammar.',
                        style: GoogleFonts.alice(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: ivory(.5))),
                  ],
                ] else
                  Text('This weather was kept without words.',
                      style: GoogleFonts.alice(
                          fontStyle: FontStyle.italic,
                          fontSize: 14.5,
                          color: ivory(.55))),
                if (e.attachments.isNotEmpty) ...[
                  _rule(),
                  _label('kept with this page'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final a in e.attachments) _attachment(a),
                    ],
                  ),
                ],
                if (softenVisible) ...[
                  const SizedBox(height: 14),
                  Text(
                      'you have come back to this page a few times. would it help to read it as if a friend wrote it?',
                      style: GoogleFonts.alice(
                          fontStyle: FontStyle.italic,
                          fontSize: 12.5,
                          height: 1.5,
                          color: ivory(.55))),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _action('edit',
                        primary: true, onTap: () => widget.onEdit(e)),
                    if (e.text.isNotEmpty)
                      _action(
                          _distance ? 'in your own voice' : 'read at a distance',
                          onTap: () => setState(() => _distance = !_distance)),
                    _action(_moreOpen ? 'less' : 'more', onTap: () {
                      setState(() {
                        _moreOpen = !_moreOpen;
                        _disarmDelete();
                      });
                    }),
                  ],
                ),
                if (_moreOpen) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _action('duplicate',
                          onTap: () => widget.onDuplicate(e)),
                      if (hasMood)
                        _action('revisit this weather',
                            onTap: () => widget.onRevisitWeather(e)),
                      _action('export page', onTap: _exportPage),
                      if (real) _deleteAction(),
                    ],
                  ),
                ],
                if (_exportNote.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_exportNote,
                      style: GoogleFonts.alice(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: ivory(.55))),
                ],
                if (e.versions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _label('earlier versions'),
                  const SizedBox(height: 8),
                  for (var i = e.versions.length - 1; i >= 0; i--)
                    _versionRow(i),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // #8: a faint wave stroke replaces the flat 1px rule; it wears the page's
  // own kept weather when there is one.
  Widget _rule() {
    final e = widget.entry;
    final hasMood = e.v != null && e.a != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: WaveDivider(
          color: hasMood ? seaTint(e.v!, e.a!) : kIvory,
          alpha: hasMood ? .42 : .16),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontSize: 10, letterSpacing: .22 * 10, color: ivory(.4)));

  Widget _attachment(Attachment a) {
    if (a.isImage && a.data.isNotEmpty) {
      final comma = a.data.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(a.data.substring(comma + 1));
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                gaplessPlayback: true),
          );
        } catch (_) {}
      }
    }
    // Voice notes: the web build had a custom player; playback needs a
    // plugin here, so the chip stays quiet (see README).
    final name = a.isAudio ? a.name : a.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: seaCard(border: .16, radius: BorderRadius.circular(11)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (a.isAudio)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child:
                  StrokeIcon(SeaIcons.record, size: 15, color: ivory(.6)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Text('\u25cc', style: TextStyle(color: ivory(.6))),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: ivory(.72))),
          ),
        ],
      ),
    );
  }

  Widget _action(String label,
      {bool primary = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: primary
                  ? kRiva.withValues(alpha: .6)
                  : ivory(.13)),
          color: primary
              ? kRiva.withValues(alpha: .12)
              : Colors.transparent,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                letterSpacing: .05 * 12,
                color:
                    primary ? kRivaLight : ivory(.68))),
      ),
    );
  }

  Widget _deleteAction() {
    final label = !_deleteArmed
        ? 'delete'
        : _deleteReady
            ? 'delete this page'
            : 'held for a moment';
    final enabled = !_deleteArmed || _deleteReady;
    return InkWell(
      onTap: enabled
          ? () {
              if (!_deleteArmed) {
                _armDelete();
              } else {
                _deleteEntry();
              }
            }
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFC98A7B)
                  .withValues(alpha: _deleteArmed && !_deleteReady ? .28 : .55)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                letterSpacing: .05 * 12,
                color: const Color(0xFFC98A7B)
                    .withValues(alpha: _deleteArmed && !_deleteReady ? .5 : .9))),
      ),
    );
  }

  Widget _versionRow(int index) {
    final v = widget.entry.versions[index];
    final d = DateTime.fromMillisecondsSinceEpoch(v.editedAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _restoreVersion(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ivory(.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${dMmm(d)} ${hhmm(d)}',
                  style: TextStyle(fontSize: 12, color: ivory(.65))),
              Text('restore',
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: .08 * 11,
                      color: kRivaLight)),
            ],
          ),
        ),
      ),
    );
  }
}

