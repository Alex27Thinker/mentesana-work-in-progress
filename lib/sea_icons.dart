// Mentesana — hand-drawn stroke icon language.
// The exact SVG path data from index.html, rendered with a small path-data
// parser. Icons keep the prototype's stroke voice: thin lines, round caps,
// and a wavy underline where the web icons carry one.

import 'package:flutter/widgets.dart';

/// Icon data in the prototype's 24×24 viewBox: raw `<path d>` strings plus
/// optional `<circle>` / `<rect rx>` primitives.
class SeaIconData {
  const SeaIconData(this.paths,
      {this.circles = const [], this.rects = const []});

  final List<String> paths;

  /// Each circle: [cx, cy, r].
  final List<List<double>> circles;

  /// Each rect: [x, y, width, height, rx].
  final List<List<double>> rects;
}

/// Icon set — path data copied verbatim from index.html.
class SeaIcons {
  /// `.backlink-icon` chevron.
  static const back =
      SeaIconData(['M15 5c-3.3 1.8-5.6 4.1-6.9 7 1.3 2.9 3.6 5.2 6.9 7']);

  static const notifications = SeaIconData([
    'M12 4c-3.4 0-5.6 2.4-5.6 6 0 4.5-1.7 5.6-2.4 7h16c-.7-1.4-2.4-2.5-2.4-7 0-3.6-2.2-6-5.6-6',
    'M10.3 20.3c.5.8 2.9.8 3.4 0',
  ]);

  static const appearance = SeaIconData([
    'M7.5 15.5a4.5 4.5 0 0 1 9 0',
    'M4 18.8c2.7 1.1 5.3 1.1 8 0s5.3-1.1 8 0',
    'M12 4.5v2.4M5.9 7.4l1.8 1.8M18.1 7.4l-1.8 1.8',
  ]);

  static const privacy = SeaIconData(
    ['M8.5 10.5V7.8a3.5 3.5 0 0 1 7 0v2.7'],
    rects: [
      [5.5, 10.5, 13, 10, 3]
    ],
  );

  static const data = SeaIconData(
    ['M8 10c1.3-.8 2.7-.8 4 0s2.7.8 4 0M8 14c1.3-.8 2.7-.8 4 0s2.7.8 4 0'],
    rects: [
      [4.5, 4.5, 15, 15, 2.5]
    ],
  );

  static const device = SeaIconData(
    ['M10 17.4c1.3.4 2.7.4 4 0'],
    rects: [
      [6.2, 3.5, 11.6, 17, 2.6]
    ],
  );

  static const replay = SeaIconData([
    'M5 12a7 7 0 1 1 2.1 5',
    'M5 7.5V12h4.5',
    'M8 16.8c1.3-.6 2.7-.6 4 0s2.7.6 4 0',
  ]);

  static const journal = SeaIconData([
    'M5 4.8h10.8a3.2 3.2 0 0 1 3.2 3.2v11.2H8.2A3.2 3.2 0 0 1 5 16z',
    'M8.4 9.5c1.2-.6 2.5-.6 3.8 0s2.5.6 3.8 0M8.4 13.8c1.2-.6 2.5-.6 3.8 0s2.5.6 3.8 0',
  ]);

  static const ai = SeaIconData([
    'M12 3.5a8.5 8.5 0 0 0-8.5 8.5 8.5 8.5 0 0 0 8.5 8.5 8.5 8.5 0 0 0 8.5-8.5A8.5 8.5 0 0 0 12 3.5',
    'M12 7.5c-2.5 0-4.5 2-4.5 4.5s2 4.5 4.5 4.5 4.5-2 4.5-4.5-2-4.5-4.5-4.5',
    'M12 10.5v3M10.5 12h3',
  ]);

  static const about = SeaIconData(
    ['M12 11c.25 2 .25 4 0 6M12 7.4h.01'],
    circles: [
      [12, 12, 8.5]
    ],
  );

  static const navHome = SeaIconData([
    'M4.5 11.2 12 4.7l7.5 6.5v8.1H14.8v-5.7H9.2v5.7H4.5z',
    'M4 20.3c2.7.8 5.3.8 8 0s5.3-.8 8 0',
  ]);

  static const navWrite = SeaIconData([
    'M13 20.6c2.6.8 5.1.7 8-.6',
    'M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z',
  ]);

  /// Journal shelf: leave a line for the tide (#jTideBtn).
  static const tide = SeaIconData([
    'M10.2 3.5h3.6M10.6 3.5v3.1c-1.9 1-2.9 2.7-2.9 4.9v6.3a2.6 2.6 0 0 0 2.6 2.6h3.4a2.6 2.6 0 0 0 2.6-2.6v-6.3c0-2.2-1-3.9-2.9-4.9V3.5',
    'M9 15.1c1-.7 2-.7 3 0s2 .7 3 0',
  ]);

  /// Journal shelf: a word to find this page by (#jTagBtn).
  static const tag = SeaIconData(
    [
      'M12.6 4.2h4.2a2.8 2.8 0 0 1 2.8 2.8v4.2c0 .7-.3 1.4-.8 2l-5.9 5.9a2.55 2.55 0 0 1-3.6 0L4.9 14.7a2.55 2.55 0 0 1 0-3.6l5.9-5.9c.5-.6 1.2-1 1.8-1z'
    ],
    circles: [
      [15.6, 8.4, 1.25]
    ],
  );

  /// Journal shelf: attach a photo or sound (label for #jAttach).
  static const attach = SeaIconData([
    'M20.8 12.2l-8.3 8.3a5.7 5.7 0 0 1-8-8l8.7-8.7a3.8 3.8 0 1 1 5.4 5.4l-8.7 8.7a1.9 1.9 0 0 1-2.7-2.7l8-8',
  ]);

  /// Journal shelf: record a voice note (#jRecord).
  static const record = SeaIconData(
    [
      'M6 11.5c.4 3.4 2.4 5.3 6 5.3s5.6-1.9 6-5.3',
      'M12 17v3',
      'M9.3 20.6c1.7.7 3.7.7 5.4 0',
    ],
    rects: [
      [9.5, 3.5, 5, 10, 2.5]
    ],
  );

  static const navJournal = journal;
}

/// Renders a [SeaIconData] as a stroked icon.
/// [strokeWidth] is in viewBox units (scales with the icon, like SVG).
class StrokeIcon extends StatelessWidget {
  const StrokeIcon(
    this.icon, {
    super.key,
    this.size = 19,
    required this.color,
    this.strokeWidth = 1.45,
  });

  final SeaIconData icon;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StrokeIconPainter(icon, color, strokeWidth),
      ),
    );
  }
}

class _StrokeIconPainter extends CustomPainter {
  _StrokeIconPainter(this.icon, this.color, this.strokeWidth);

  final SeaIconData icon;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final d in icon.paths) {
      canvas.drawPath(parseSvgPath(d), paint);
    }
    for (final c in icon.circles) {
      canvas.drawCircle(Offset(c[0], c[1]), c[2], paint);
    }
    for (final r in icon.rects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r[0], r[1], r[2], r[3]),
          Radius.circular(r[4]),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StrokeIconPainter old) =>
      old.icon != icon || old.color != color || old.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// Minimal SVG path-data parser: M m L l H h V v C c S s Q q A a Z z, with
// implicit command repetition (enough for every icon in the prototype).
// ---------------------------------------------------------------------------

final RegExp _pathToken =
    RegExp(r'([MmLlHhVvCcSsQqAaZz])|(-?\d*\.?\d+(?:[eE][+-]?\d+)?)');

Path parseSvgPath(String d) {
  final path = Path();
  final tokens = _pathToken.allMatches(d).toList();
  var i = 0;
  var cmd = '';
  var cur = Offset.zero;
  var subpathStart = Offset.zero;
  Offset? prevCubicControl;

  double nextNum() {
    final m = tokens[i++];
    return double.parse(m.group(2)!);
  }

  bool numbersAhead() => i < tokens.length && tokens[i].group(2) != null;

  while (i < tokens.length) {
    final t = tokens[i];
    if (t.group(1) != null) {
      cmd = t.group(1)!;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        cur = subpathStart;
        prevCubicControl = null;
        continue;
      }
    } else if (cmd == 'M') {
      cmd = 'L'; // implicit lineto after moveto
    } else if (cmd == 'm') {
      cmd = 'l';
    }

    switch (cmd) {
      case 'M':
      case 'm':
        {
          final x = nextNum(), y = nextNum();
          cur = cmd == 'm' ? cur + Offset(x, y) : Offset(x, y);
          path.moveTo(cur.dx, cur.dy);
          subpathStart = cur;
          prevCubicControl = null;
          break;
        }
      case 'L':
      case 'l':
        {
          final x = nextNum(), y = nextNum();
          cur = cmd == 'l' ? cur + Offset(x, y) : Offset(x, y);
          path.lineTo(cur.dx, cur.dy);
          prevCubicControl = null;
          break;
        }
      case 'H':
      case 'h':
        {
          final x = nextNum();
          cur = Offset(cmd == 'h' ? cur.dx + x : x, cur.dy);
          path.lineTo(cur.dx, cur.dy);
          prevCubicControl = null;
          break;
        }
      case 'V':
      case 'v':
        {
          final y = nextNum();
          cur = Offset(cur.dx, cmd == 'v' ? cur.dy + y : y);
          path.lineTo(cur.dx, cur.dy);
          prevCubicControl = null;
          break;
        }
      case 'C':
      case 'c':
        {
          final rel = cmd == 'c';
          final base = rel ? cur : Offset.zero;
          final c1 = base + Offset(nextNum(), nextNum());
          final c2 = base + Offset(nextNum(), nextNum());
          final end = base + Offset(nextNum(), nextNum());
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          prevCubicControl = c2;
          cur = end;
          break;
        }
      case 'S':
      case 's':
        {
          final rel = cmd == 's';
          final base = rel ? cur : Offset.zero;
          final c1 =
              prevCubicControl == null ? cur : cur * 2 - prevCubicControl;
          final c2 = base + Offset(nextNum(), nextNum());
          final end = base + Offset(nextNum(), nextNum());
          path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
          prevCubicControl = c2;
          cur = end;
          break;
        }
      case 'Q':
      case 'q':
        {
          final rel = cmd == 'q';
          final base = rel ? cur : Offset.zero;
          final c1 = base + Offset(nextNum(), nextNum());
          final end = base + Offset(nextNum(), nextNum());
          path.quadraticBezierTo(c1.dx, c1.dy, end.dx, end.dy);
          prevCubicControl = null;
          cur = end;
          break;
        }
      case 'A':
      case 'a':
        {
          final rel = cmd == 'a';
          final rx = nextNum(), ry = nextNum();
          final rot = nextNum();
          final largeArc = nextNum() != 0;
          final sweep = nextNum() != 0;
          final base = rel ? cur : Offset.zero;
          final end = base + Offset(nextNum(), nextNum());
          path.arcToPoint(
            end,
            radius: Radius.elliptical(rx, ry),
            rotation: rot,
            largeArc: largeArc,
            clockwise: sweep,
          );
          prevCubicControl = null;
          cur = end;
          break;
        }
      default:
        // Unknown token — skip defensively.
        i++;
    }
    // Guard: if a malformed string leaves numbers with no command, stop.
    if (cmd == '' && numbersAhead()) break;
  }
  return path;
}
