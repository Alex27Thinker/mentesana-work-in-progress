// Mentesana — the currents engine.
// Three quiet readers over the user's own kept pages. Everything is local,
// observational and evidence-grounded; nothing here diagnoses, scores,
// counts, or concludes.
//
//  · undertowScan — notices when a page circles the same water (brooding
//    why-loops, what-if worry chains, self-critique) and names which small
//    practice fits. Grounded in RF-CBT concreteness training, worry-
//    postponement trials, and self-distancing research.
//  · almanacRead — reads the user's own mood history for leading patterns
//    ("after low water, your pages have usually softened within a day").
//    Always their pattern, never a promise.
//  · mineAnchors — finds what has historically co-occurred with gentler
//    water in their own pages, so one tiny anchor can be offered
//    (behavioural activation at the smallest possible scale).

import 'app_store.dart';
import 'text_lexicons.dart';

// ─────────────────────────────── undertow ───────────────────────────────

/// What the scan noticed under a page.
class UndertowReading {
  UndertowReading({
    required this.kind,
    required this.phrase,
    required this.score,
  });

  /// 'brooding' (abstract why-loops and counterfactual replay),
  /// 'worry' (what-if chains reaching ahead of the day), or
  /// 'selfCritique' (the page turning on its writer).
  final String kind;

  /// The user's own circling phrase, quoted back — recognition, not verdict.
  final String phrase;
  final double score;
}

// Abstract "why …" loops — the signature of brooding rather than reflection.
// Processing-mode work (RF-CBT) shifts these toward "how / when / what
// exactly", which is what the walking-it-to-shore practice does.
final RegExp _kWhyLoopRe = RegExp(
  r"\bwhy (do|does|am|is|are|can'?t|won'?t|didn'?t|don'?t|couldn'?t)\b[^.?!\n]{0,60}",
  caseSensitive: false,
);

// "what if …" — worry reaching ahead.
final RegExp _kWhatIfRe =
    RegExp(r'\bwhat if\b[^.?!\n]{0,60}', caseSensitive: false);

// Counterfactual replay — "should have", "if only".
final RegExp _kCounterRe = RegExp(
  r"\b(should(n'?t)? have|if only|could have|wish i (had|hadn'?t))\b[^.?!\n]{0,60}",
  caseSensitive: false,
);

// The page turning on its writer.
final RegExp _kSelfCritRe = RegExp(
  r"\b(i('m| am) (such |so |a |just )*(failure|useless|stupid|pathetic|weak|worthless|a mess|broken|not (good )?enough)|hate myself|my fault|wrong with me|i ruin(ed)? (everything|it))\b[^.?!\n]{0,40}",
  caseSensitive: false,
);

List<String> _wordsOf(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r"[^\w\s']"), ' ')
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList(growable: false);

/// Scans one kept page. Returns null far more often than not: the scan needs
/// real length (30+ words) and at least two distinct signal families before
/// it will say anything at all — a single "always" is never enough.
UndertowReading? undertowScan(String text) {
  final words = _wordsOf(text);
  if (words.length < 30) return null;

  final why = _kWhyLoopRe.allMatches(text).toList();
  final whatIf = _kWhatIfRe.allMatches(text).toList();
  final counter = _kCounterRe.allMatches(text).toList();
  final selfCrit = _kSelfCritRe.allMatches(text).toList();
  final absolutist = words.where(kAbsolutistWords.contains).length;

  final brooding = why.length * 2.0 + counter.length * 1.5 + absolutist * .5;
  final worry = whatIf.length * 2.0 + absolutist * .25;
  final critique = selfCrit.length * 2.5 + absolutist * .25;

  var families = 0;
  if (why.isNotEmpty) families++;
  if (whatIf.isNotEmpty) families++;
  if (counter.isNotEmpty) families++;
  if (selfCrit.isNotEmpty) families++;
  if (absolutist > 0) families++;

  var kind = 'brooding';
  var score = brooding;
  if (worry > score) {
    kind = 'worry';
    score = worry;
  }
  if (critique > score) {
    kind = 'selfCritique';
    score = critique;
  }
  if (families < 2 || score < 3.0) return null;

  final source = kind == 'worry'
      ? whatIf
      : kind == 'selfCritique'
          ? selfCrit
          : (why.isNotEmpty ? why : counter);
  var phrase = source.isNotEmpty ? source.first.group(0)!.trim() : '';
  if (phrase.length > 64) phrase = '${phrase.substring(0, 64)}…';
  return UndertowReading(kind: kind, phrase: phrase, score: score);
}

/// The observation line for a reading — always "the water noticed",
/// never "you are".
String undertowObservation(UndertowReading r) => switch (r.kind) {
      'worry' =>
        'this page keeps reaching ahead — the same what-if returns more than once.',
      'selfCritique' =>
        'this page turns on you more than once. the sea would not speak to you this way.',
      _ =>
        'this page seems to circle the same water — passing over it again without quite landing.',
    };

// ─────────────────────────────── almanac ───────────────────────────────

class AlmanacLine {
  const AlmanacLine(this.kind, this.text);
  final String kind; // 'recovery' | 'slots' | 'weekday' | 'lift'
  final String text;
}

class AlmanacReading {
  const AlmanacReading({
    required this.hasData,
    this.lines = const [],
    this.soundings = 0,
  });

  final bool hasData;
  final List<AlmanacLine> lines;

  /// How many kept moments the reading is drawn from.
  final int soundings;

  AlmanacLine? get leading => lines.isEmpty ? null : lines.first;
}

const _kDayNamesAlmanac = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Reads the user's own history for leading patterns. Gates are deliberately
/// conservative — ≥10 kept moods across ≥10 days, and each pattern needs its
/// own minimum evidence before it may speak. An empty reading is honest, not
/// a failure.
AlmanacReading almanacRead(List<JournalEntry> entries, {DateTime? now}) {
  final moods = entries.where((e) => e.isMoodEntry).toList()
    ..sort((a, b) => a.ts.compareTo(b.ts));
  if (moods.length < 10) {
    return AlmanacReading(hasData: false, soundings: moods.length);
  }
  final spanDays = (moods.last.ts - moods.first.ts) / 86400000;
  if (spanDays < 10) {
    return AlmanacReading(hasData: false, soundings: moods.length);
  }

  final lines = <AlmanacLine>[];
  final base = moods.fold<double>(0, (s, e) => s + e.v!) / moods.length;

  // 1 · recovery after low water — the single most useful thing a low day
  // can hear, if (and only if) the user's own record supports it.
  var lows = 0, softened = 0;
  for (var i = 0; i < moods.length; i++) {
    final e = moods[i];
    if ((e.v ?? 0) > -0.3) continue;
    if (i + 1 >= moods.length) break;
    final next = moods[i + 1];
    if (next.ts - e.ts > 2 * 86400000) continue;
    lows++;
    if ((next.v ?? 0) - (e.v ?? 0) >= 0.25) softened++;
  }
  if (lows >= 4 && softened / lows >= 0.6) {
    lines.add(AlmanacLine('recovery',
        'after low water, your own pages have usually softened within a day or two — $softened of $lows times so far.'));
  }

  // 2 · time of day.
  final am = moods.where((e) {
    final h = e.date.hour;
    return h >= 5 && h < 12;
  }).toList();
  final pm = moods.where((e) => e.date.hour >= 17).toList();
  if (am.length >= 4 && pm.length >= 4) {
    final amAvg = am.fold<double>(0, (s, e) => s + e.v!) / am.length;
    final pmAvg = pm.fold<double>(0, (s, e) => s + e.v!) / pm.length;
    final d = amAvg - pmAvg;
    if (d.abs() >= 0.3) {
      lines.add(AlmanacLine(
          'slots',
          d > 0
              ? 'your mornings have tended to sit in gentler water than your evenings.'
              : 'your evenings have tended to sit in gentler water than your mornings.'));
    }
  }

  // 3 · day of week.
  final byDay = <int, List<double>>{};
  for (final e in moods) {
    (byDay[e.date.weekday] ??= []).add(e.v!);
  }
  var bestDev = 0.0;
  int? bestDow;
  byDay.forEach((dow, vs) {
    if (vs.length < 3) return;
    final dev = vs.reduce((a, b) => a + b) / vs.length - base;
    if (dev.abs() > bestDev.abs()) {
      bestDev = dev;
      bestDow = dow;
    }
  });
  if (bestDow != null && bestDev.abs() >= 0.3) {
    lines.add(AlmanacLine('weekday',
        '${_kDayNamesAlmanac[bestDow! - 1]}s have often carried ${bestDev > 0 ? 'lighter' : 'heavier'} water than the rest of your week.'));
  }

  // 4 · what co-occurs with gentler water (shared with the anchor miner).
  final lifts = mineAnchors(entries);
  if (lifts.isNotEmpty) {
    lines.add(AlmanacLine('lift',
        'pages that hold ${lifts.first.label} have tended toward gentler water.'));
  }

  // A low today reads the recovery line first — that is the moment it helps.
  final t = now ?? DateTime.now();
  JournalEntry? latest;
  for (final e in moods) {
    if (latest == null || e.ts > latest.ts) latest = e;
  }
  final todayLow = latest != null &&
      dayKeyOf(latest.ts) == dayKeyOf(t.millisecondsSinceEpoch) &&
      (latest.v ?? 0) <= -0.3;
  if (todayLow) {
    lines.sort((a, b) =>
        (a.kind == 'recovery' ? 0 : 1) - (b.kind == 'recovery' ? 0 : 1));
  }

  return AlmanacReading(hasData: true, lines: lines, soundings: moods.length);
}

// ─────────────────────────────── anchors ───────────────────────────────

/// A small thing the user's own record says tends to sit near gentler water.
class AnchorSuggestion {
  const AnchorSuggestion({
    required this.theme,
    required this.label,
    required this.action,
    required this.lift,
    required this.days,
  });

  final String theme;
  final String label; // 'the outside'
  final String action; // 'a few unhurried minutes outside'
  final double lift;
  final int days;

  String get evidence =>
      'pages that mention $label have sat in gentler water than your usual — $days days of your own record say so.';
}

class _AnchorSeed {
  const _AnchorSeed(this.theme, this.label, this.action, this.words);
  final String theme;
  final String label;
  final String action;
  final Set<String> words;
}

// Word lists are token-matched (never substrings), and deliberately skip
// words that carry other meanings in journals ('rest', 'playing', 'made').
const _kAnchorSeeds = <_AnchorSeed>[
  _AnchorSeed('outside', 'the outside', 'a few unhurried minutes outside', {
    'walk', 'walked', 'walking', 'outside', 'outdoors', 'park', 'nature',
    'sea', 'beach', 'sun', 'sunlight', 'air', 'trees', 'garden',
  }),
  _AnchorSeed('people', 'time with people',
      'one small hello — a message or a call', {
    'friend', 'friends', 'call', 'called', 'talked', 'coffee', 'dinner',
    'visit', 'visited', 'laughed', 'together',
  }),
  _AnchorSeed('body', 'moving the body', 'a slow stretch, or a short walk', {
    'run', 'ran', 'running', 'gym', 'swim', 'swam', 'yoga', 'stretch',
    'stretched', 'exercise', 'bike', 'cycling', 'danced', 'dancing',
  }),
  _AnchorSeed('making', 'making something',
      'ten unhurried minutes making something — badly is fine', {
    'draw', 'drew', 'drawing', 'paint', 'painted', 'music', 'guitar',
    'piano', 'sang', 'singing', 'cooked', 'baked', 'sketch', 'sketched',
  }),
  _AnchorSeed('rest', 'real rest',
      'one unhurried pause — tea, a bath, an early night', {
    'slept', 'nap', 'napped', 'rested', 'bath', 'tea',
  }),
];

/// Mines the user's own pages for gentle-water co-occurrence. Needs ≥8
/// distinct days with kept weather; each candidate needs ≥3 mention-days and
/// a lift of at least .12 against the user's own baseline. Correlation is
/// treated as exactly that — the copy never claims a cause.
List<AnchorSuggestion> mineAnchors(List<JournalEntry> entries) {
  final dayMood = <String, List<double>>{};
  for (final e in entries) {
    if (e.isMoodEntry) (dayMood[dayKeyOf(e.ts)] ??= []).add(e.v!);
  }
  if (dayMood.length < 8) return const [];
  final dayAvg = <String, double>{
    for (final kv in dayMood.entries)
      kv.key: kv.value.reduce((a, b) => a + b) / kv.value.length,
  };
  final base = dayAvg.values.reduce((a, b) => a + b) / dayAvg.length;

  // Tokenize each written page once, then let every seed look.
  final mentionDays = <String, Set<String>>{
    for (final seed in _kAnchorSeeds) seed.theme: <String>{},
  };
  for (final e in entries) {
    if (e.text.isEmpty) continue;
    final tokens = _wordsOf(e.text).toSet();
    for (final seed in _kAnchorSeeds) {
      if (tokens.any(seed.words.contains)) {
        mentionDays[seed.theme]!.add(dayKeyOf(e.ts));
      }
    }
  }

  final out = <AnchorSuggestion>[];
  for (final seed in _kAnchorSeeds) {
    final moody = [
      for (final d in mentionDays[seed.theme]!)
        if (dayAvg.containsKey(d)) dayAvg[d]!,
    ];
    if (moody.length < 3) continue;
    final lift = moody.reduce((a, b) => a + b) / moody.length - base;
    if (lift < .12) continue;
    out.add(AnchorSuggestion(
      theme: seed.theme,
      label: seed.label,
      action: seed.action,
      lift: lift,
      days: moody.length,
    ));
  }
  out.sort((a, b) => b.lift.compareTo(a.lift));
  return out;
}
