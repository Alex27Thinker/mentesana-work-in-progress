// Mentesana — the calendar (month / week / day of kept weather).
// Structural screen: left-aligned, bare typography on the sea.
// No tile grid, no segmented pill, no counter. Days as bare numerals
// with a soft mood-tinted radial glow where entries were kept.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'archive_screen.dart' show formatTime12;
import 'core/locator.dart';
import 'core/sea_manager.dart';
import 'journal_prompts.dart';
import 'mood_palette.dart';
import 'sea_icons.dart';
import 'theme.dart';

/// Month-nav chevrons (verbatim path data from index.html).
const _chevronLeft =
    SeaIconData(['M15 5c-3.3 1.8-5.6 4.1-6.9 7 1.3 2.9 3.6 5.2 6.9 7']);
const _chevronRight =
    SeaIconData(['M9 5c3.3 1.8 5.6 4.1 6.9 7-1.3 2.9-3.6 5.2-6.9 7']);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.store,
    required this.onBack,
    required this.onOpenEntry,
  });

  final AppStore store;
  final VoidCallback onBack;
  final ValueChanged<JournalEntry> onOpenEntry;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _view = 'month';
  DateTime _focus = DateTime.now();

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<JournalEntry> _entriesFor(DateTime date) {
    final es = widget.store.entries
        .where((e) => _sameDay(e.date, date))
        .toList()
      ..sort((a, b) => a.ts.compareTo(b.ts));
    return es;
  }

  Color _entryColor(JournalEntry e) {
    if (e.v == null || e.a == null) {
      return kRiva;
    }
    return kSea.bilerp(e.v!, e.a!)[0];
  }

  void _shift(int dir) {
    setState(() {
      if (_view == 'week') {
        _focus = _focus.add(Duration(days: 7 * dir));
      } else if (_view == 'day') {
        _focus = _focus.add(Duration(days: dir));
      } else {
        _focus = DateTime(_focus.year, _focus.month + dir);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // No counter displayed per charter; only computed if needed for
    // internal logic. Entries are fetched on demand; total is for
    // the week view which needs to know max entries.
    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head(),
              const SizedBox(height: s4),
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
                  child: NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      locate<SeaManager>().scrollDrift(n.scrollDelta ?? 0);
                      // v2 — absorb here so the shell's global coupler
                      // doesn't count this scroll twice.
                      return true;
                    },
                    child: ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                      children: [
                        _navRow(now),
                        const SizedBox(height: s16),
                        _viewSwitch(),
                        const SizedBox(height: s20),
                        if (_view == 'month')
                          ..._monthView(now)
                        else if (_view == 'week')
                          ..._weekView()
                        else
                          ..._dayView(),
                      ],
                    ),
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
  // Head — left-aligned, back + title.
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
              padding: const EdgeInsets.symmetric(horizontal: s4, vertical: s8),
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
            'calendar',
            style: MenteType.title.copyWith(color: textSecondary, fontSize: 20),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Nav row (chevrons + header name, no counter).
  // ---------------------------------------------------------------------

  Widget _navRow(DateTime now) {
    final headerName = _view == 'day'
        ? '${kDowsLong[_focus.weekday % 7]}, ${kMonthsLong[_focus.month - 1]} ${_focus.day}'
        : _view == 'week'
            ? 'this week'
            : '${kMonthsLong[_focus.month - 1]} ${_focus.year}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _shift(-1),
          child: Padding(
            padding: const EdgeInsets.all(s8),
            child: StrokeIcon(
              _chevronLeft,
              size: 18,
              color: textSecondary,
              strokeWidth: 1.65,
            ),
          ),
        ),
        Text(
          headerName,
          style: MenteType.heading.copyWith(color: textPrimary),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _shift(1),
          child: Padding(
            padding: const EdgeInsets.all(s8),
            child: StrokeIcon(
              _chevronRight,
              size: 18,
              color: textSecondary,
              strokeWidth: 1.65,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // View switcher — three plain text links, no segmented pill.
  // ---------------------------------------------------------------------

  Widget _viewSwitch() {
    Widget link(String label) {
      final active = _view == label;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _view = label),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: s8, vertical: s4),
          child: Text(
            label,
            style: GoogleFonts.alice(
              fontStyle: FontStyle.italic,
              fontSize: 14,
              color: active ? textPrimary : textFaint,
              decoration: active ? TextDecoration.underline : null,
              decorationColor: ivory(.4),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      link('month'),
      link('week'),
      link('day'),
    ]);
  }

  // ---------------------------------------------------------------------
  // Month view — 7-column bare numerals.
  // ---------------------------------------------------------------------

  List<Widget> _monthView(DateTime now) {
    final year = _focus.year, month = _focus.month;
    final first = DateTime(year, month);
    final cellCount = DateTime(year, month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= cellCount; day++) {
      final date = DateTime(year, month, day);
      final es = _entriesFor(date);
      final isToday = _sameDay(date, now);
      final isSelected = _sameDay(date, _focus);
      final tint = es.isNotEmpty ? _entryColor(es.first) : null;
      cells.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _focus = date;
            _view = 'day';
          }),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40, minWidth: 40),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mood-tinted glow behind the numeral.
                if (tint != null)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tint.withValues(alpha: .22),
                          tint.withValues(alpha: 0),
                        ],
                        stops: const [0, 1],
                      ),
                    ),
                  ),
                Text(
                  '$day',
                  style: MenteType.caption.copyWith(
                    fontSize: isSelected ? 15 : (isToday ? 14 : 13),
                    color: isToday ? kOro : textSecondary,
                    decoration: isSelected ? TextDecoration.underline : null,
                    decorationColor:
                        isSelected ? ivory(.35) : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return [
      // 7-bare day-of-week initials.
      Row(
        children: [
          for (final d in const ['m', 't', 'w', 't', 'f', 's', 's'])
            Expanded(
              child: Center(
                child: Text(
                  d,
                  style: MenteType.caption.copyWith(color: textFaint),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: s8),
      // Numerals grid — built as wrap so there's no fixed-tile-box cell
      // per the charter. 7 columns via SizedBox width factions.
      SizedBox(
        width: double.infinity,
        child: Wrap(
          children: cells
              .map(
                (c) => SizedBox(
                    width: (MediaQuery.of(context).size.width - 44) / 7,
                    child: c),
              )
              .toList(),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------
  // Week view — bare mood columns + entries underneath.
  // ---------------------------------------------------------------------

  List<Widget> _weekView() {
    final start = _focus.subtract(Duration(days: _focus.weekday % 7));
    final dayData = List.generate(7, (i) {
      final date = DateTime(start.year, start.month, start.day + i);
      return (date: date, es: _entriesFor(date));
    });
    final hasAny = dayData.any((d) => d.es.isNotEmpty);
    var maxEntries = 1;
    for (final d in dayData) {
      if (d.es.length > maxEntries) maxEntries = d.es.length;
    }
    const minColH = 4.0, maxColH = 64.0;

    Widget column(({DateTime date, List<JournalEntry> es}) d) {
      final dow = kDowsShort[d.date.weekday % 7].substring(0, 1);
      Widget bar;
      if (d.es.isEmpty) {
        bar = const SizedBox(
          height: minColH,
          width: double.infinity,
        );
      } else {
        final avgV =
            d.es.fold<double>(0, (s, e) => s + (e.v ?? 0)) / d.es.length;
        final avgA =
            d.es.fold<double>(0, (s, e) => s + (e.a ?? 0)) / d.es.length;
        final seaColor = kSea.bilerp(avgV, avgA);
        final colH =
            (minColH + (d.es.length / maxEntries) * (maxColH - minColH))
                .roundToDouble();
        bar = Container(
          height: colH,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(5),
              bottom: Radius.circular(4),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                seaColor[0].withValues(alpha: .58),
                seaColor[1].withValues(alpha: .82),
              ],
            ),
          ),
        );
      }
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _focus = d.date;
            _view = 'day';
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  dow,
                  style: MenteType.caption.copyWith(color: textFaint),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 42),
                  child: bar,
                ),
                const SizedBox(height: 6),
                Text(
                  '${d.date.day}',
                  style: MenteType.caption.copyWith(
                    color:
                        _sameDay(d.date, _focus) ? textPrimary : textSecondary,
                    decoration: _sameDay(d.date, _focus)
                        ? TextDecoration.underline
                        : null,
                    decorationColor: ivory(.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final widgets = <Widget>[
      SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: dayData.map(column).toList(),
        ),
      ),
    ];
    if (hasAny) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Center(
            child: Text(
              'seven days of sea — each column holds the weather that day carried',
              textAlign: TextAlign.center,
              style: GoogleFonts.alice(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: textFaint,
              ),
            ),
          ),
        ),
      );
    }

    // No card wrappers on detail rows; plain left-aligned text rows.
    final detailRows = dayData.where((d) => d.es.isNotEmpty).map((d) {
      final words = d.es.map((e) => e.word ?? 'journal').join(' · ');
      return Padding(
        padding: const EdgeInsets.only(bottom: s8),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _focus = d.date;
            _view = 'day';
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: s8),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '${kDowsShort[d.date.weekday % 7]} ${d.date.day}',
                    style: MenteType.caption.copyWith(color: textFaint),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${d.es.length} page${d.es.length == 1 ? '' : 's'}',
                        style: MenteType.caption.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        words,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MenteType.caption.copyWith(color: textFaint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
    widgets.addAll(detailRows);

    return widgets;
  }

  // ---------------------------------------------------------------------
  // Day view.
  // ---------------------------------------------------------------------

  List<Widget> _dayView() {
    final es = _entriesFor(_focus);
    final widgets = <Widget>[];
    if (es.isNotEmpty) {
      final sorted = es.toList()..sort((a, b) => a.ts.compareTo(b.ts));
      List<(double, Color)> stops;
      if (sorted.length == 1) {
        final c = _entryColor(sorted[0]);
        stops = [(0, c), (1, c)];
      } else {
        stops = [
          for (final e in sorted)
            (
              (e.date.hour * 60 + e.date.minute) / 1440,
              _entryColor(e),
            ),
        ];
      }
      widgets.add(
        SizedBox(
          height: 52,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 18,
                  child: Container(
                    height: 2,
                    color: ivory(.12),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 14,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        stops: [for (final s in stops) s.$1],
                        colors: [
                          for (final s in stops) s.$2.withValues(alpha: .4),
                        ],
                      ),
                    ),
                  ),
                ),
                for (final e in sorted)
                  Positioned(
                    left: ((e.date.hour * 60 + e.date.minute) / 1440) *
                            (box.maxWidth - 13) -
                        2,
                    top: 12.5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onOpenEntry(e),
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _entryColor(e).withValues(alpha: .4),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final l in const ['12am', 'noon', '12pm'])
                        Text(
                          l,
                          style: MenteType.caption.copyWith(color: textFaint),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: s16));
    }
    widgets.add(
      Text(
        'pages from this day',
        style: MenteType.caption.copyWith(color: textFaint),
      ),
    );
    widgets.add(const SizedBox(height: s8));
    if (es.isEmpty) {
      widgets.add(
        Text(
          'no pages from this day — not every day needs one.',
          style: GoogleFonts.alice(
            fontStyle: FontStyle.italic,
            fontSize: 13,
            color: textFaint,
          ),
        ),
      );
    } else {
      for (final e in es) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: s8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onOpenEntry(e),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 10),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _entryColor(e).withValues(alpha: .7),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatTime12(e.date),
                            style: MenteType.caption.copyWith(color: textFaint),
                          ),
                          Text(
                            e.word ?? 'journal',
                            style: MenteType.heading.copyWith(
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            e.text.isNotEmpty
                                ? e.text
                                : 'a weather kept without words.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: MenteType.caption.copyWith(
                              height: 1.5,
                              color: textSecondary,
                            ),
                          ),
                        ],
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
    return widgets;
  }
}
