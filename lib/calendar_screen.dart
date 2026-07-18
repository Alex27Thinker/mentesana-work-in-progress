// Mentesana — the calendar (month / week / day of kept weather).
// 1:1 port of #screen-calendar + renderCalendar from the Vite prototype.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_store.dart';
import 'archive_screen.dart' show formatTime12;
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
  String _view = 'month'; // JS calendarView
  DateTime _focus = DateTime.now(); // JS calendarFocus

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
    if (e.v == null || e.a == null) return kRiva;
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
    final headerName = _view == 'day'
        ? '${kDowsLong[_focus.weekday % 7]}, ${kMonthsLong[_focus.month - 1]} ${_focus.day}'
        : _view == 'week'
            ? 'this week'
            : '${kMonthsLong[_focus.month - 1]} ${_focus.year}';
    final total = widget.store.entries.where((e) {
      final d = e.date;
      return d.month == _focus.month && d.year == _focus.year;
    }).length;

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
            ScreenHeader(
              title: 'calendar',
              onBack: widget.onBack,
              backLabel: 'journal',
            ),
            const WaveDivider(),
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
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _navButton(
                            _chevronLeft, () => _shift(-1), 'Previous month'),
                        Column(
                          children: [
                            Text(headerName,
                                style: MenteType.heading
                                    .copyWith(color: textPrimary)),
                            const SizedBox(height: 2),
                            Text('$total kept',
                                style: MenteType.caption.copyWith(
                                    letterSpacing: .12 * 10.5,
                                    color: textFaint)),
                          ],
                        ),
                        _navButton(
                            _chevronRight, () => _shift(1), 'Next month'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _viewSwitch(),
                    const SizedBox(height: 18),
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
          ],
        ),
      ],
    );
  }

  Widget _navButton(SeaIconData icon, VoidCallback onTap, String semantic) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: textDisabled),
        ),
        child: Center(child: StrokeIcon(icon, size: 18, color: textSecondary)),
      ),
    );
  }

  Widget _viewSwitch() {
    Widget seg(String label) {
      final active = _view == label;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _view = label),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: active ? kRiva : Colors.transparent,
            ),
            child: Center(
              child: Text(label,
                  style: MenteType.caption.copyWith(
                      letterSpacing: .08 * 11.5,
                      color: active ? const Color(0xFF10141E) : ivory(.6))),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(s4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: textDisabled),
      ),
      child: Row(children: [seg('month'), seg('week'), seg('day')]),
    );
  }

  // ---------- month ----------

  List<Widget> _monthView(DateTime now) {
    final year = _focus.year, month = _focus.month;
    final first = DateTime(year, month);
    final days = DateTime(year, month + 1, 0).day;
    final leading = first.weekday % 7; // JS getDay(): Sunday = 0
    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= days; day++) {
      final date = DateTime(year, month, day);
      final es = _entriesFor(date);
      final isToday = _sameDay(date, now);
      final tint = es.isNotEmpty ? _entryColor(es.first) : null;
      cells.add(InkWell(
        onTap: () => setState(() {
          _focus = date;
          _view = 'day';
        }),
        borderRadius: BorderRadius.circular(12),
        child: BreathingCard(
          tint: tint,
          fill: es.isNotEmpty ? .08 : .03,
          border: es.isNotEmpty ? .12 : .06,
          radius: BorderRadius.circular(12),
          intensity: .4,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                          color: kOro.withValues(alpha: .65), spreadRadius: 1)
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day',
                    style: MenteType.caption.copyWith(color: textSecondary)),
                if (es.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: s4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in es.take(3))
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: _entryColor(e)),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ));
    }
    return [
      Row(
        children: [
          for (final d in const ['s', 'm', 't', 'w', 't', 'f', 's'])
            Expanded(
              child: Center(
                child: Text(d,
                    style: MenteType.caption
                        .copyWith(letterSpacing: .18 * 10.5, color: textFaint)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: cells,
      ),
    ];
  }

  // ---------- week ----------

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
    const minColH = 18.0, maxColH = 72.0;

    Widget column(({DateTime date, List<JournalEntry> es}) d) {
      final dow = kDowsShort[d.date.weekday % 7].substring(0, 1);
      Widget water;
      if (d.es.isEmpty) {
        water = Container(
          height: minColH,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10), bottom: Radius.circular(6)),
            border: Border.all(color: textDisabled),
          ),
        );
      } else {
        // dominant mood: average valence/arousal of the day's entries
        final avgV =
            d.es.fold<double>(0, (s, e) => s + (e.v ?? 0)) / d.es.length;
        final avgA =
            d.es.fold<double>(0, (s, e) => s + (e.a ?? 0)) / d.es.length;
        final seaColor = kSea.bilerp(avgV, avgA);
        final skyColor = kSky.bilerp(avgV, avgA);
        final colH =
            (minColH + (d.es.length / maxEntries) * (maxColH - minColH))
                .roundToDouble();
        water = Container(
          height: colH,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10), bottom: Radius.circular(6)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, .6, 1],
              colors: [
                skyColor[0].withValues(alpha: .72),
                seaColor[0].withValues(alpha: .88),
                seaColor[1].withValues(alpha: .95),
              ],
            ),
          ),
        );
      }
      return Expanded(
        child: InkWell(
          onTap: () => setState(() {
            _focus = d.date;
            _view = 'day';
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(dow,
                    style: MenteType.eyebrow
                        .copyWith(letterSpacing: .14 * 10, color: textFaint)),
                const SizedBox(height: 6),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 42),
                    child: water),
                const SizedBox(height: 6),
                Text('${d.date.day}',
                    style: MenteType.caption.copyWith(color: textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    final detailRows = dayData.where((d) => d.es.isNotEmpty).map((d) {
      final words = d.es.map((e) => e.word ?? 'journal').join(' \u00b7 ');
      return Padding(
        padding: const EdgeInsets.only(bottom: s8),
        child: InkWell(
          onTap: () => setState(() {
            _focus = d.date;
            _view = 'day';
          }),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: s12, vertical: s12),
            // #6/#7: the day row wears that day's dominant weather.
            decoration: seaCard(
                tint: _entryColor(d.es.first),
                border: .12,
                radius: BorderRadius.circular(12)),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text('${kDowsShort[d.date.weekday % 7]} ${d.date.day}',
                      style: MenteType.caption.copyWith(color: textFaint)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${d.es.length} page${d.es.length == 1 ? '' : 's'}',
                          style: MenteType.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textSecondary)),
                      Text(words,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MenteType.caption.copyWith(color: textFaint)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return [
      SizedBox(
        height: 120,
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dayData.map(column).toList()),
      ),
      if (hasAny) ...[
        const SizedBox(height: 10),
        Center(
          child: Text(
              'seven days of sea — each column holds the weather that day carried',
              textAlign: TextAlign.center,
              style: GoogleFonts.alice(
                  fontStyle: FontStyle.italic,
                  fontSize: 11.5,
                  color: textFaint)),
        ),
      ],
      const SizedBox(height: 14),
      if (detailRows.isEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: s8),
            child: Text('This week has room for you.',
                style: GoogleFonts.alice(
                    fontStyle: FontStyle.italic,
                    fontSize: 13.5,
                    color: textFaint)),
          ),
        )
      else
        ...detailRows,
    ];
  }

  // ---------- day ----------

  List<Widget> _dayView() {
    final es = _entriesFor(_focus);
    final widgets = <Widget>[];
    if (es.isNotEmpty) {
      // mood ribbon: a soft gradient band connecting the day's mood dots,
      // coloured by each entry's sea colour — the day's emotional weather
      // as a shifting hue strip
      final sorted = es.toList()..sort((a, b) => a.ts.compareTo(b.ts));
      List<(double, Color)> stops;
      if (sorted.length == 1) {
        final c = _entryColor(sorted[0]);
        stops = [(0, c), (1, c)];
      } else {
        stops = [
          for (final e in sorted)
            ((e.date.hour * 60 + e.date.minute) / 1440, _entryColor(e)),
        ];
      }
      widgets.add(SizedBox(
        height: 52,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 18,
                child: Container(height: 2, color: textDisabled),
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
                        for (final s in stops) s.$2.withValues(alpha: .4)
                      ],
                    ),
                  ),
                ),
              ),
              for (final e in sorted)
                Positioned(
                  left: ((e.date.hour * 60 + e.date.minute) / 1440) *
                      (box.maxWidth - 13),
                  top: 12.5,
                  child: GestureDetector(
                    onTap: () => widget.onOpenEntry(e),
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _entryColor(e),
                        border: Border.all(
                            color: const Color(0xFF2D3D43), width: 2),
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
                    for (final l in const ['12am', 'noon', '12am'])
                      Text(l,
                          style: MenteType.eyebrow.copyWith(color: textFaint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
      widgets.add(const SizedBox(height: 16));
    }
    widgets.add(Text('pages from this day',
        style: MenteType.eyebrow
            .copyWith(letterSpacing: .22 * 10, color: textFaint)));
    widgets.add(const SizedBox(height: 8));
    if (es.isEmpty) {
      widgets.add(Text('No pages from this day — not every day needs one.',
          style: GoogleFonts.alice(
              fontStyle: FontStyle.italic, fontSize: 13.5, color: textFaint)));
    } else {
      for (final e in es) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: s8),
          child: InkWell(
            onTap: () => widget.onOpenEntry(e),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: s12, vertical: s12),
              // #6/#7: each page row wears its own kept weather.
              decoration: seaCard(
                  tint:
                      (e.v != null && e.a != null) ? seaTint(e.v!, e.a!) : null,
                  border: .12,
                  radius: BorderRadius.circular(12)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 10),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: _entryColor(e)),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatTime12(e.date),
                            style:
                                MenteType.caption.copyWith(color: textFaint)),
                        Text(e.word ?? 'journal',
                            style: MenteType.bodySerif
                                .copyWith(color: textPrimary)),
                        Text(
                            e.text.isNotEmpty
                                ? e.text
                                : 'A weather kept without words.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: MenteType.caption
                                .copyWith(height: 1.5, color: textFaint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
    }
    return widgets;
  }
}
