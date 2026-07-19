// Mentesana — statistical analysis of mood check-ins (MoodAnalyzer).

import 'dart:math' as math;

import '../../features/journal/domain/models.dart';
import 'analysis_models.dart';

class _MaPoint {
  const _MaPoint(this.ts, this.avgV, this.avgA);
  final int ts;
  final double avgV;
  final double avgA;
}

class MoodAnalyzer {
  const MoodAnalyzer(this.entries);
  final List<JournalEntry> entries;

  /// Quadrant labels for internal use (never shown as labels to the user).
  static String quadrantOf(double v, double a) {
    if (v >= 0 && a >= 0) return 'pleasant-activated';
    if (v >= 0 && a < 0) return 'pleasant-calm';
    if (v < 0 && a >= 0) return 'unpleasant-activated';
    return 'unpleasant-calm';
  }

  /// All mood entries (real entries only, not demo data), oldest first.
  List<JournalEntry> moodEntries() {
    final list = entries.where((e) => e.isMoodEntry).toList()
      ..sort((a, b) => a.ts.compareTo(b.ts));
    return list;
  }

  /// Entries within a time window (default: last 7 days).
  List<JournalEntry> recentMood([int days = 7]) {
    final cutoff =
        DateTime.now().millisecondsSinceEpoch - days * 24 * 60 * 60 * 1000;
    return moodEntries().where((e) => e.ts >= cutoff).toList();
  }

  /// Moving average of valence and arousal over a window.
  static List<_MaPoint> _movingAverage(List<JournalEntry> data,
      [int windowSize = 3]) {
    if (data.isEmpty) return [];
    final result = <_MaPoint>[];
    for (var i = 0; i < data.length; i++) {
      final start = math.max(0, i - windowSize + 1);
      final slice = data.sublist(start, i + 1);
      final avgV = slice.fold<double>(0, (s, e) => s + e.v!) / slice.length;
      final avgA = slice.fold<double>(0, (s, e) => s + e.a!) / slice.length;
      result.add(_MaPoint(data[i].ts, avgV, avgA));
    }
    return result;
  }

  /// Volatility: average distance between consecutive mood points.
  static double volatilityOf(List<JournalEntry> data) {
    if (data.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < data.length; i++) {
      total += math.sqrt(math.pow(data[i].v! - data[i - 1].v!, 2) +
          math.pow(data[i].a! - data[i - 1].a!, 2));
    }
    return total / (data.length - 1);
  }

  /// Quadrant distribution: proportion of entries in each quadrant.
  static Map<String, double> quadrantDistribution(List<JournalEntry> data) {
    final dist = <String, double>{
      'pleasant-activated': 0,
      'pleasant-calm': 0,
      'unpleasant-activated': 0,
      'unpleasant-calm': 0,
    };
    if (data.isEmpty) return dist;
    for (final e in data) {
      final q = quadrantOf(e.v!, e.a!);
      dist[q] = dist[q]! + 1;
    }
    for (final k in dist.keys) {
      dist[k] = dist[k]! / data.length;
    }
    return dist;
  }

  /// Dominant quadrant (the one with the most entries).
  static String? dominantQuadrant(List<JournalEntry> data) {
    final dist = quadrantDistribution(data);
    var max = 0.0;
    String? dom;
    for (final k in dist.keys) {
      if (dist[k]! > max) {
        max = dist[k]!;
        dom = k;
      }
    }
    return dom;
  }

  /// Trajectory: is the mood trending in a direction?
  static MoodTrajectory trajectoryOf(List<JournalEntry> data) {
    if (data.length < 3) {
      return const MoodTrajectory(
          0, 0, 'not enough weather to read a direction yet');
    }
    final ma = _movingAverage(data, math.min(3, (data.length / 2).ceil()));
    final first = ma.first, last = ma.last;
    final vDir = last.avgV - first.avgV;
    final aDir = last.avgA - first.avgA;
    var desc = '';
    const threshold = 0.25;
    if (vDir > threshold && aDir > threshold) {
      desc = 'moving toward brighter, more awake weather';
    } else if (vDir > threshold && aDir < -threshold) {
      desc = 'moving toward calmer, gentler weather';
    } else if (vDir < -threshold && aDir > threshold) {
      desc = 'moving toward heavier, more turbulent weather';
    } else if (vDir < -threshold && aDir < -threshold) {
      desc = 'moving toward quieter, lower weather';
    } else if (vDir > threshold) {
      desc = 'a gentle lift in valence';
    } else if (vDir < -threshold) {
      desc = 'a gentle dip in valence';
    } else if (aDir > threshold) {
      desc = 'slightly more activated';
    } else if (aDir < -threshold) {
      desc = 'slightly calmer';
    } else {
      desc = 'the weather has been holding steady';
    }
    return MoodTrajectory(vDir, aDir, desc);
  }

  /// Most frequent mood words.
  static List<WordCount> frequentWordsOf(List<JournalEntry> data,
      [int topN = 3]) {
    final counts = <String, int>{};
    for (final e in data) {
      final w = e.word;
      if (w != null && w.isNotEmpty) counts[w] = (counts[w] ?? 0) + 1;
    }
    final sorted = stableSortedByDesc(counts.entries, (e) => e.value);
    return sorted.take(topN).map((e) => WordCount(e.key, e.value)).toList();
  }

  /// Time-of-day pattern: when does the user most often check in?
  static TimePattern timeOfDayPattern(List<JournalEntry> data) {
    final slots = <String, int>{
      'morning': 0,
      'afternoon': 0,
      'evening': 0,
      'night': 0,
    };
    for (final e in data) {
      final h = e.date.hour;
      if (h < 6) {
        slots['night'] = slots['night']! + 1;
      } else if (h < 12) {
        slots['morning'] = slots['morning']! + 1;
      } else if (h < 18) {
        slots['afternoon'] = slots['afternoon']! + 1;
      } else {
        slots['evening'] = slots['evening']! + 1;
      }
    }
    var max = 0;
    String? dom;
    for (final k in slots.keys) {
      if (slots[k]! > max) {
        max = slots[k]!;
        dom = k;
      }
    }
    return TimePattern(slots, dom);
  }

  /// Full analysis summary.
  MoodAnalysis analyze([int days = 7]) {
    final all = moodEntries();
    final recent = recentMood(days);
    if (recent.isEmpty) {
      return MoodAnalysis(hasData: false, count: 0, days: days);
    }
    final ma = _movingAverage(recent);
    final vol = volatilityOf(recent);
    final dist = quadrantDistribution(recent);
    final dom = dominantQuadrant(recent);
    final traj = trajectoryOf(recent);
    final words = frequentWordsOf(recent);
    final timePattern = timeOfDayPattern(recent);
    MoodShift? shift;
    if (recent.length >= 6) {
      final recent3 = recent.sublist(recent.length - 3);
      final prior3 = recent.sublist(recent.length - 6, recent.length - 3);
      final rAvgV = recent3.fold<double>(0, (s, e) => s + e.v!) / 3;
      final pAvgV = prior3.fold<double>(0, (s, e) => s + e.v!) / 3;
      final rAvgA = recent3.fold<double>(0, (s, e) => s + e.a!) / 3;
      final pAvgA = prior3.fold<double>(0, (s, e) => s + e.a!) / 3;
      final vShift = rAvgV - pAvgV, aShift = rAvgA - pAvgA;
      if (vShift.abs() > 0.3 || aShift.abs() > 0.3) {
        shift = MoodShift(
            vShift,
            aShift,
            vShift > 0.3
                ? 'the weather has been brighter in the last few check-ins'
                : vShift < -0.3
                    ? 'the weather has been heavier in the last few check-ins'
                    : aShift > 0.3
                        ? 'things have felt more activated recently'
                        : 'things have felt calmer recently');
      }
    }
    return MoodAnalysis(
      hasData: true,
      count: recent.length,
      totalEntries: all.length,
      days: days,
      avgV: ma.isNotEmpty ? ma.last.avgV : 0,
      avgA: ma.isNotEmpty ? ma.last.avgA : 0,
      volatility: vol,
      quadrantDistribution: dist,
      dominantQuadrant: dom,
      trajectory: traj,
      frequentWords: words,
      timePattern: timePattern,
      shift: shift,
    );
  }
}
