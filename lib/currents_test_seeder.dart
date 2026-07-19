// Mentesana — debug test-data seeder for currents features.
// Only available in kDebugMode. Never visible or accessible in release builds.
// All generated records are marked with a synthetic flag so "Clear currents test data"
// removes only generated data, never real entries.

import 'app_store.dart';

/// A synthetic marker stored in the synthetic field of JournalEntry.
/// The prototype's JournalEntry doesn't have a synthetic field — we use a
/// separate static set of synthetic entry timestamps in AppStore.
/// This is the key used to mark synthetic records.
const String kSyntheticMarker = '__synthetic__';

class CurrentsTestSeeder {
  CurrentsTestSeeder._();

  static bool get isDebugMode {
    return const bool.fromEnvironment('dart.vm.product') == false;
  }

  /// Seed 14+ days of realistic dated mood and journal data.
  /// Returns the number of entries seeded.
  static int seedTestData(AppStore store) {
    if (!isDebugMode) return 0;
    if (store.hasSyntheticData) return 0; // Prevent duplicate seeding.

    final now = DateTime.now();
    final entries = <JournalEntry>[];
    final random = _SeededRandom(42);

    // Generate 14 days of data (15 days to ensure enough span).
    const days = 15;
    final baseMoodValues = <double>[
      -0.8, -0.2, 0.3, 0.5, 0.1, -0.4, -0.6, // Week 1
      -0.3, 0.2, 0.6, 0.4, 0.0, -0.1, 0.3, 0.7, // Week 2 + extra
    ];
    final baseArousalValues = <double>[
      -0.4,
      0.1,
      0.3,
      -0.1,
      -0.2,
      -0.5,
      -0.3,
      0.0,
      0.4,
      0.2,
      -0.1,
      -0.3,
      0.1,
      0.3,
      0.0,
    ];
    final words = [
      'tired',
      'okay',
      'hopeful',
      'calm',
      'anxious',
      'low',
      'flat',
      'steady',
      'lighter',
      'peaceful',
      'fine',
      'restless',
      'warm',
      'bright',
      'quiet',
    ];
    for (var i = 0; i < days; i++) {
      final dayDate = now.subtract(Duration(days: days - i));
      final v = baseMoodValues[i % baseMoodValues.length] +
          random.nextDouble() * 0.3 -
          0.15;
      final a = baseArousalValues[i % baseArousalValues.length] +
          random.nextDouble() * 0.3 -
          0.15;
      // Ensure v is within [-1, 1].
      final moodV = v.clamp(-1.0, 1.0);
      final moodA = a.clamp(-1.0, 1.0);
      final word = words[i % words.length];

      // Time of day: morning (7-11) or evening (17-20) varied.
      final hour =
          (i % 2 == 0) ? 8 + random.nextInt(4) : 17 + random.nextInt(4);
      final minute = random.nextInt(60);
      final ts =
          DateTime(dayDate.year, dayDate.month, dayDate.day, hour, minute)
              .millisecondsSinceEpoch;

      // Journal text: include outside/ walk/ park/ sunlight on gentler days.
      var text = _generateEntryText(moodV, i, random);

      // For gentler days (v >= 0.2), include outside/walk/park/sunlight themes
      // so the Anchor miner finds them.
      if (moodV >= 0.2 && i % 3 != 0) {
        final outsidePhrases = [
          'Took a walk in the park, the sunlight felt good.',
          'Sat outside for a bit, just breathing the air.',
          'Walked through the garden, noticed the trees.',
          'The sunlight through the window was warm.',
          'Went for a walk by the sea.',
          'Spent time outside in the fresh air.',
          'The park was quiet, birds singing.',
        ];
        text = '$text\n\n${outsidePhrases[i % outsidePhrases.length]}';
      }

      final entry = JournalEntry(
        ts: ts,
        v: moodV,
        a: moodA,
        word: word,
        text: text.trim(),
        title: _titleFromText(text),
      );
      entries.add(entry);
    }

    // Add 3 undertow fixture entries that genuinely pass undertowScan logic:
    // brooding, worry, selfCritique — each 30+ words.
    final undertowEntries = _createUndertowFixtures(now, random);
    entries.addAll(undertowEntries);

    // Add one due ParkedWorry (returnAt <= now).
    final worryEntry = _createParkedWorryFixture(now);
    entries.add(worryEntry);

    // Add one open Anchor due today (forDay == todayKey).
    final anchorEntry = _createAnchorFixture(now);
    entries.add(anchorEntry);

    // Mark all entries as synthetic.
    for (final e in entries) {
      store.markEntrySynthetic(e.ts);
    }

    // Add entries to store.
    for (final e in entries) {
      store.addEntry(e);
    }

    // Add a due ParkedWorry to the store (returnAt <= now).
    const worryText =
        'I\'ve been worrying about the upcoming presentation at work. [TEST fixture worry]';
    store.parkedWorries = [
      ...store.parkedWorries,
      ParkedWorry(
        ts: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        text: worryText,
        returnAt: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
      ),
    ];
    store.saveParkedWorries();

    // Add an open Anchor due today.
    store.anchors = [
      ...store.anchors,
      Anchor(
        setAt: now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
        text: 'a few unhurried minutes outside [TEST fixture anchor]',
        theme: 'outside',
        forDay: dayKeyOf(now.millisecondsSinceEpoch),
      ),
    ];
    store.saveAnchors();

    return entries.length;
  }

  /// Clear only synthetic test data. Returns the number of entries removed.
  static int clearTestData(AppStore store) {
    if (!isDebugMode) return 0;
    final syntheticTs = store.syntheticEntryTimestamps.toList();
    if (syntheticTs.isEmpty) return 0;

    // Remove entries that are synthetic.
    store.entries =
        store.entries.where((e) => !syntheticTs.contains(e.ts)).toList();
    store.saveEntries();

    // Clear synthetic timestamps.
    store.clearSyntheticTimestamps();

    // Also clear parked worries that were generated synthetically.
    store.parkedWorries = store.parkedWorries
        .where((w) =>
            !w.text.contains('[TEST]') && !w.text.contains('fixture worry'))
        .toList();
    store.saveParkedWorries();

    // Also clear synthetic anchors.
    store.anchors = store.anchors
        .where((a) =>
            !a.text.contains('[TEST]') && !a.text.contains('fixture anchor'))
        .toList();
    store.saveAnchors();

    return syntheticTs.length;
  }

  /// Create three undertow fixture entries that genuinely pass undertowScan.
  static List<JournalEntry> _createUndertowFixtures(
      DateTime now, _SeededRandom random) {
    final entries = <JournalEntry>[];
    final baseDate = now.subtract(const Duration(days: 1));

    // 1. Brooding fixture: why loops + counterfactual.
    const broodingText = '''
Why do I always end up in the same place? Why can't I just get it right for once? 
I should have done things differently last week. If only I had known better. 
I keep going over it and over it, but nothing changes. I feel stuck in this loop. 
Why does everything feel so hard right now? I can't seem to break out of this pattern. 
It's pointless, really. I'll never figure this out.
''';
    final broodingEntry = JournalEntry(
      ts: baseDate.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      v: -0.5,
      a: -0.3,
      word: 'low',
      text: broodingText.trim(),
      title: 'Brooding fixture [TEST]',
    );
    entries.add(broodingEntry);

    // 2. Worry fixture: what-if chains.
    const worryText = '''
What if I don't get the job? What if I'm not good enough for this position? 
What if they find out I'm not as capable as they think? I keep thinking about it. 
What if I fail and everyone sees it? What if I can't handle the pressure? 
I can't stop worrying about what will happen next week. It's consuming me.
''';
    final worryEntry = JournalEntry(
      ts: baseDate.subtract(const Duration(hours: 4)).millisecondsSinceEpoch,
      v: -0.6,
      a: 0.2,
      word: 'anxious',
      text: worryText.trim(),
      title: 'Worry fixture [TEST]',
    );
    entries.add(worryEntry);

    // 3. Self-critique fixture.
    const critiqueText = '''
I'm such a failure. I can't do anything right. I hate myself for messing this up. 
My fault, always my fault. There's something wrong with me. I ruin everything. 
I'm useless, completely useless. I don't know why I even try anymore. 
I'm pathetic and weak. I'll never be good enough for anyone.
''';
    final critiqueEntry = JournalEntry(
      ts: baseDate.subtract(const Duration(hours: 6)).millisecondsSinceEpoch,
      v: -0.8,
      a: -0.4,
      word: 'hopeless',
      text: critiqueText.trim(),
      title: 'Self-critique fixture [TEST]',
    );
    entries.add(critiqueEntry);

    return entries;
  }

  /// Create a due ParkedWorry (returnAt <= now).
  static JournalEntry _createParkedWorryFixture(DateTime now) {
    const text = '''
I've been carrying this worry about the upcoming presentation. 
What if I forget everything? What if they see how nervous I am? 
It's been on my mind for days. Letting it go to the tide for now.
'''; // This is the worry text that gets parked.

    // This entry is just a journal entry; the parked worry is added separately.
    // We'll return a synthetic entry and also add the parked worry to the store.
    // But we need to add the parked worry to the store's parkedWorries list.
    // We'll handle this in seedTestData by adding the parked worry directly.
    return JournalEntry(
      ts: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
      v: -0.3,
      a: 0.1,
      word: 'worried',
      text: text.trim(),
      title: 'Parked worry fixture [TEST]',
    );
  }

  /// Create an open Anchor due today.
  static JournalEntry _createAnchorFixture(DateTime now) {
    const text = '''
Today I want to hold a small anchor: a few unhurried minutes outside. 
The sea suggests it, and I'm willing to try.
''';
    return JournalEntry(
      ts: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      v: 0.3,
      a: 0.1,
      word: 'hopeful',
      text: text.trim(),
      title: 'Anchor fixture [TEST]',
    );
  }

  static String _titleFromText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return '';
    final first = lines.first.trim();
    if (first.length > 84) return first.substring(0, 84);
    return first;
  }

  static String _generateEntryText(
      double moodV, int dayIndex, _SeededRandom random) {
    final phrases = [
      'Today was quiet. I sat with my thoughts for a while.',
      'The morning felt heavy, but the afternoon lifted a little.',
      'I noticed the light changing through the window.',
      'Some days are just about getting through. Today was one of those.',
      'I wrote a few lines and felt a little lighter.',
      'The sea was calm today. I tried to match it.',
      'I thought about what I need to let go of.',
      'A small moment of peace found me this evening.',
      'I am learning to sit with discomfort.',
      'Today I let myself rest when I needed to.',
    ];
    final idx = dayIndex % phrases.length;
    return phrases[idx];
  }
}

/// A simple seeded random number generator for deterministic test data.
class _SeededRandom {
  _SeededRandom(this._seed);
  int _seed;

  int nextInt(int max) {
    if (max <= 0) return 0;
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed & 0x7FFFFFFF) % max;
  }

  double nextDouble() {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed & 0x7FFFFFFF) / 0x7FFFFFFF;
  }
}
