// Mentesana — local store.
// Flutter port of the localStorage layer from the Vite prototype (src/main.js).
// Storage keys mirror the prototype 1:1 (`mentesana-*`) so behavior stays comparable.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

import '_shared/services/settings_repository.dart';
import 'features/journal/domain/models.dart';
import 'notification_service.dart';
import 'voice_transcription_service.dart';

export 'features/journal/domain/models.dart';

/// Interface language table — ported verbatim from the prototype's I18N map.
const kI18n = <String, Map<String, String>>{
  'en': {
    'greetingNight': 'Good night',
    'greetingMorning': 'Good morning',
    'greetingAfternoon': 'Good afternoon',
    'greetingEvening': 'Good evening',
    'write': 'write',
    'journal': 'journal',
    'home': 'home',
    'archive': 'archive',
    'calendar': 'calendar',
    'settings': 'settings',
    'insight': 'insight',
    'yourPages': 'your pages',
    'exportAndArchive': 'export and archive',
    'thisDevice': 'this device',
    'whereEntriesLive': 'where entries live',
    'about': 'about',
    'howMentesanaWorks': 'how Mentesana works',
    'notifications': 'notifications',
    'yourQuietReminder': 'your quiet reminder',
    'appearance': 'appearance',
    'readingRooms': 'reading rooms',
    'privacy': 'privacy',
    'yourPagesProtected': 'your pages, protected',
    'revisitBeginning': 'revisit the beginning',
    'journalPreferences': 'journal preferences',
    'howPagesBegin': 'how pages begin and return',
  },
  'it': {
    'greetingNight': 'Buona notte',
    'greetingMorning': 'Buongiorno',
    'greetingAfternoon': 'Buon pomeriggio',
    'greetingEvening': 'Buona sera',
    'write': 'scrivi',
    'journal': 'diario',
    'home': 'home',
    'archive': 'archivio',
    'calendar': 'calendario',
    'settings': 'impostazioni',
    'insight': 'riflessione',
    'yourPages': 'le tue pagine',
    'exportAndArchive': 'esporta e archivia',
    'thisDevice': 'questo dispositivo',
    'whereEntriesLive': 'dove vivono le pagine',
    'about': 'info',
    'howMentesanaWorks': 'come funziona Mentesana',
    'notifications': 'notifiche',
    'yourQuietReminder': 'il tuo promemoria silenzioso',
    'appearance': 'aspetto',
    'readingRooms': 'stanze di lettura',
    'privacy': 'privacy',
    'yourPagesProtected': 'le tue pagine, protette',
    'revisitBeginning': "rivedi l'inizio",
    'journalPreferences': 'preferenze diario',
    'howPagesBegin': 'come iniziano le pagine',
  },
};

/// MOOD DECAY: the lens and ambient tint let go of the last mood over ~4h,
/// same as the prototype's applyMoodAtmosphere (MOOD_DECAY_MS = 14400000).
const kMoodDecayMs = 14400000;

/// Local calendar key, zero-padded 'yyyy-mm-dd' — sorts and compares
/// lexicographically. Used by the currents engine and anchors.
String dayKeyOf(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// App-wide state + persistence. Mirrors the prototype's settings variables,
/// their defaults, and the entries array.
///
/// Persistence is handled exclusively by [SettingsRepository] — the legacy
/// dual-path (raw SharedPreferences fallback) has been removed since only
/// the DI-constructed `fromRepository` path is used in production.
class AppStore extends ChangeNotifier {
  AppStore.fromRepository(this._repo) {
    _loadAll();
  }

  /// The SettingsRepository — the single persistence backend.
  final SettingsRepository _repo;

  // ---------- entries ----------
  List<JournalEntry> entries = [];

  /// When the tinted weather was last kept (JS `moodTintTs`).
  /// Restored from the newest mood entry on boot — the "saved-mood boot fix".
  int? moodTintTs;

  /// Session boundary: true only until the first Home render after boot or
  /// after the app returns from background. A fresh open shows a neutral lens.
  bool sessionFresh = true;

  // ---------- settings (defaults identical to the prototype) ----------
  bool welcomed = false;
  List<String> onboardingPreferences = [];
  String room = 'night';
  bool autoRoomOn = false;
  bool moodAtmosphereOn = true;
  String textSize = 'regular';
  bool reducedMotionOn = false;
  String profileName = 'Alessandro';
  String language = 'en';
  bool reminderOn = false;
  String reminderAt = '20:30';
  bool weeklyReminderOn = false;
  int weeklyReminderDay = 0; // 0 = Sunday, as JS getDay()
  bool quietHoursOn = false;
  String quietHoursStart = '22:00';
  String quietHoursEnd = '08:00';
  bool pinLockOn = false;
  String pinCode = '';
  int autoLockSeconds = 0;
  String? _promptStyle;
  bool tideLineDefault = false;
  int attachmentCap = 3;
  bool aiEnabled = false;
  List<TideExperiment> tideExperiments = [];

  // ---------- currents (undertow / almanac / anchors) ----------
  bool currentsOn = true; // undertow observations after a kept page
  bool almanacOn = true; // the almanac card on Home
  String undertowLastDay = ''; // at most one gentle offer per day
  int anchorQuietUntil = 0; // 'not now' quiets anchor invites for a few days
  List<ParkedWorry> parkedWorries = [];
  List<Anchor> anchors = [];

  /// Synthetic entry timestamps for test data seeder.
  /// Used to mark and clear generated test data.
  Set<int> syntheticEntryTimestamps = {};

  bool get hasSyntheticData => syntheticEntryTimestamps.isNotEmpty;

  void markEntrySynthetic(int ts) {
    syntheticEntryTimestamps.add(ts);
  }

  void clearSyntheticTimestamps() {
    syntheticEntryTimestamps.clear();
  }

  /// Weekly-insight lines already shown, so the local letter can retire
  /// repeats instead of becoming wallpaper (see recordShownInsightLines).
  List<String> shownInsightLines = [];

  TideExperiment? get activeTideExperiment {
    for (final experiment in tideExperiments.reversed) {
      if (!experiment.isComplete) return experiment;
    }
    return null;
  }

  void _loadAll() {
    try {
      final raw = jsonDecode(_repo.entriesJson);
      entries = raw is List
          ? raw.map(JournalEntry.fromJson).whereType<JournalEntry>().toList()
          : [];
    } catch (_) {
      entries = const [];
    }
    var entriesMigrated = false;
    entries = entries.map((e) {
      var migrated = e;
      if (migrated.word == 'journal') {
        migrated = migrated.copyWith(word: null);
        entriesMigrated = true;
      }
      if (isSystemPageTitle(migrated.title) && migrated.text.isNotEmpty) {
        final t = titleFromPage(migrated.text);
        migrated =
            migrated.copyWith(title: t.isNotEmpty ? t : 'a page from this day');
        entriesMigrated = true;
      }
      if (migrated.isMoodEntry) {
        final t = migrated.moodTs ?? migrated.ts;
        if (t > (moodTintTs ?? 0)) moodTintTs = t;
      }
      if (migrated.pendingTranscription) {
        migrated = migrated.copyWith(
            pendingTranscription: false, pendingAudioPath: null);
        entriesMigrated = true;
      }
      return migrated;
    }).toList();
    if (entriesMigrated) {
      _repo.entriesJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    }
    welcomed = _repo.welcomed;
    onboardingPreferences = _repo.onboardingPreferences;
    room = _repo.room;
    autoRoomOn = _repo.autoRoomOn;
    moodAtmosphereOn = _repo.moodAtmosphereOn;
    textSize = _repo.textSize;
    reducedMotionOn = _repo.reducedMotionOn;
    profileName = _repo.profileName;
    language = _repo.language;
    reminderOn = _repo.reminderOn;
    reminderAt = _repo.reminderAt;
    weeklyReminderOn = _repo.weeklyReminderOn;
    weeklyReminderDay = _repo.weeklyReminderDay;
    quietHoursOn = _repo.quietHoursOn;
    quietHoursStart = _repo.quietHoursStart;
    quietHoursEnd = _repo.quietHoursEnd;
    pinLockOn = _repo.pinLockOn;
    pinCode = _repo.pinCode;
    autoLockSeconds = _repo.autoLockSeconds;
    _promptStyle = _repo.promptStyle;
    tideLineDefault = _repo.tideLineDefault;
    attachmentCap = _repo.attachmentCap;
    aiEnabled = _repo.aiEnabled;
    try {
      final raw = jsonDecode(_repo.tideExperimentsJson);
      tideExperiments = raw is List
          ? raw
              .map(TideExperiment.fromJson)
              .whereType<TideExperiment>()
              .toList(growable: true)
          : [];
    } catch (_) {
      tideExperiments = [];
    }
    currentsOn = _repo.currentsOn;
    almanacOn = _repo.almanacOn;
    undertowLastDay = _repo.undertowLastDay;
    anchorQuietUntil = _repo.anchorQuietUntil;
    try {
      final raw = jsonDecode(_repo.parkedWorriesJson);
      parkedWorries = raw is List
          ? raw
              .map(ParkedWorry.fromJson)
              .whereType<ParkedWorry>()
              .toList(growable: true)
          : [];
    } catch (_) {
      parkedWorries = [];
    }
    try {
      final raw = jsonDecode(_repo.anchorsJson);
      anchors = raw is List
          ? raw.map(Anchor.fromJson).whereType<Anchor>().toList(growable: true)
          : [];
    } catch (_) {
      anchors = [];
    }
    try {
      final raw = jsonDecode(_repo.shownInsightLinesJson);
      shownInsightLines =
          raw is List ? raw.map((x) => x.toString()).toList() : [];
    } catch (_) {
      shownInsightLines = [];
    }
    // Re-arm real OS notifications for reminders that were already on —
    // scheduled alarms don't survive an app reinstall/update on their own.
    if (reminderOn) NotificationService.instance.scheduleDaily(reminderAt);
    if (weeklyReminderOn) {
      NotificationService.instance.scheduleWeekly(weeklyReminderDay);
    }
  }

  // ---------- currents: parked worries (worry postponement) ----------
  /// The tide takes a worry and returns it tomorrow evening — far enough to
  /// be a real pause, near enough that the promise is kept.
  void parkWorry(String text) {
    final now = DateTime.now();
    final returns = DateTime(now.year, now.month, now.day + 1, 18);
    parkedWorries = [
      ...parkedWorries,
      ParkedWorry(
        ts: now.millisecondsSinceEpoch,
        text: text,
        returnAt: returns.millisecondsSinceEpoch,
      ),
    ];
    _saveParkedWorries();
  }

  List<ParkedWorry> get dueParkedWorries {
    final now = DateTime.now().millisecondsSinceEpoch;
    return parkedWorries
        .where((w) => !w.settled && w.returnAt <= now)
        .toList(growable: false);
  }

  void settleWorry(ParkedWorry w) {
    parkedWorries = parkedWorries.map((pw) {
      if (pw.ts == w.ts && pw.text == w.text) return pw.copyWith(settled: true);
      return pw;
    }).toList();
    _saveParkedWorries();
  }

  void _saveParkedWorries() => persistParkedWorries();

  // Public wrapper for seeder to save parked worries.
  void saveParkedWorries() {
    _saveParkedWorries();
  }

  // ---------- currents: anchors (behavioural activation) ----------
  Anchor? get openAnchor {
    for (final a in anchors.reversed) {
      if (a.isOpen) return a;
    }
    return null;
  }

  void setAnchor({required String text, required String theme}) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    anchors = [
      ...anchors,
      Anchor(
        setAt: now.millisecondsSinceEpoch,
        text: text,
        theme: theme,
        forDay: dayKeyOf(tomorrow.millisecondsSinceEpoch),
      ),
    ];
    _saveAnchors();
  }

  void reflectAnchor(Anchor a, String outcome) {
    anchors = anchors.map((anchor) {
      if (anchor.setAt == a.setAt &&
          anchor.forDay == a.forDay &&
          anchor.text == a.text) {
        return anchor.copyWith(
            reflectedAt: DateTime.now().millisecondsSinceEpoch,
            outcome: outcome);
      }
      return anchor;
    }).toList();
    _saveAnchors();
  }

  /// 'not now' on an anchor invite — quiet for a few days, never punished.
  void quietAnchorInvites({int days = 3}) {
    anchorQuietUntil = DateTime.now().millisecondsSinceEpoch + days * 86400000;
    _repo.anchorQuietUntil = anchorQuietUntil;
    notifyListeners();
  }

  void _saveAnchors() => persistAnchors();

  // Public wrapper for seeder to save anchors.
  void saveAnchors() {
    _saveAnchors();
  }

  // ---------- currents: undertow & almanac settings ----------
  void markUndertowOffered() {
    undertowLastDay = dayKeyOf(DateTime.now().millisecondsSinceEpoch);
    _repo.undertowLastDay = undertowLastDay;
  }

  void setCurrentsOn(bool v) {
    currentsOn = v;
    _repo.currentsOn = v;
    notifyListeners();
  }

  void setAlmanacOn(bool v) {
    almanacOn = v;
    _repo.almanacOn = v;
    notifyListeners();
  }

  /// Grow a kept page from a micro-practice — appended below the page's own
  /// words, never replacing them.
  void appendToEntry(JournalEntry e, String addition) {
    final add = addition.trim();
    if (add.isEmpty) return;
    final current = findByTs(e.ts);
    if (current == null) {
      throw StateError('appendToEntry: no entry with ts=${e.ts}');
    }
    final newText = current.text.trim().isEmpty
        ? add
        : '${current.text.trimRight()}\n\n$add';
    final newCount = newText.trim().isEmpty
        ? 0
        : newText.trim().split(RegExp(r'\s+')).length;
    updateEntry(current, current.copyWith(text: newText, wordCount: newCount));
  }

  // ---------- i18n ----------
  String t(String key) => kI18n[language]?[key] ?? kI18n['en']![key] ?? key;

  // ---------- entries ----------

  /// Replace [oldEntry] with [newEntry] in the entries list.
  /// Entries are uniquely identified by their [JournalEntry.ts] timestamp.
  ///
  /// Returns `true` when the entry was found and replaced. Returns `false`
  /// when no entry with that timestamp exists; in that case the entries
  /// list is not modified.
  ///
  /// Persistence and listener notification are NOT triggered by this method
  /// — the caller is responsible for one explicit `saveEntries()` and one
  /// notification cycle per logical update. Centralising the side effects
  /// outside the helper keeps persistence and observation single-shot.
  bool _replaceEntry(JournalEntry oldEntry, JournalEntry newEntry) {
    assert(oldEntry.ts == newEntry.ts,
        'replacement must preserve timestamp identity');
    final idx = entries.indexWhere((e) => e.ts == oldEntry.ts);
    if (idx < 0) return false;
    entries = [...entries]..[idx] = newEntry;
    return true;
  }

  void saveEntries() {
    _repo.entriesJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  /// Public replacement operation used by feature widgets and adapters.
  ///
  /// Persists exactly once and notifies exactly once on a successful
  /// replacement. Throws a [StateError] if no entry with [oldEntry.ts]
  /// exists — the explicit policy is to fail loudly rather than silently
  /// no-op. This keeps callers from believing an update succeeded when
  /// it was applied to stale data.
  bool updateEntry(JournalEntry oldEntry, JournalEntry newEntry) {
    if (oldEntry.ts != newEntry.ts) {
      throw StateError(
          'updateEntry must preserve ts identity (${oldEntry.ts} → ${newEntry.ts})');
    }
    final current = findByTs(oldEntry.ts);
    if (current == null) {
      throw StateError('updateEntry: no entry with ts=${oldEntry.ts}');
    }
    if (!identical(current, oldEntry)) {
      throw StateError('updateEntry: stale entry with ts=${oldEntry.ts}');
    }
    final replaced = _replaceEntry(current, newEntry);
    if (!replaced) {
      throw StateError('updateEntry: no entry with ts=${oldEntry.ts}');
    }
    saveEntries();
    return true;
  }

  /// Persist parked worries to settings and notify listeners once.
  void persistParkedWorries() {
    _repo.parkedWorriesJson =
        jsonEncode(parkedWorries.map((w) => w.toJson()).toList());
    notifyListeners();
  }

  /// Persist anchors to settings and notify listeners once.
  void persistAnchors() {
    _repo.anchorsJson = jsonEncode(anchors.map((a) => a.toJson()).toList());
    notifyListeners();
  }

  /// Persist tide experiments to settings and notify listeners once.
  void persistTideExperiments() {
    _repo.tideExperimentsJson =
        jsonEncode(tideExperiments.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void addEntry(JournalEntry e) {
    entries = [...entries, e];
    if (e.isMoodEntry) moodTintTs = e.ts;
    saveEntries();
  }

  void resetEntries() {
    entries = const [];
    saveEntries();
  }

  /// JS `latestMoodToday()`: newest mood entry with today's date.
  JournalEntry? latestMoodToday() {
    final now = DateTime.now();
    JournalEntry? latest;
    for (final e in entries) {
      if (!e.isMoodEntry) continue;
      final d = e.date;
      if (d.year != now.year || d.month != now.month || d.day != now.day) {
        continue;
      }
      if (latest == null || e.ts > latest.ts) latest = e;
    }
    return latest;
  }

  /// JS `todaysEntry()`: newest entry (mood or page) with today's date.
  JournalEntry? todaysEntry() {
    final now = DateTime.now();
    JournalEntry? latest;
    for (final e in entries) {
      final d = e.date;
      if (d.year != now.year || d.month != now.month || d.day != now.day) {
        continue;
      }
      if (latest == null || e.ts > latest.ts) latest = e;
    }
    return latest;
  }

  /// JS `ON_THIS_DAY_DEMO`: one month ago at 19:40 — 'hopeful'.
  static JournalEntry onThisDayDemo() {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month - 1, now.day, 19, 40);
    return JournalEntry(
      ts: dt.millisecondsSinceEpoch,
      v: .35,
      a: -.3,
      word: 'hopeful',
      text: 'Sent the application. Strange kind of calm after.',
    );
  }

  /// JS `findOnThisDay()`: same day-of-month from an earlier month, else the
  /// demo memory when the archive is empty.
  JournalEntry? findOnThisDay() {
    final now = DateTime.now();
    if (entries.isNotEmpty) {
      final matches = entries.where((e) {
        final d = e.date;
        return d.day == now.day && (d.month != now.month || d.year != now.year);
      }).toList();
      return matches.isNotEmpty ? matches.last : null;
    }
    return onThisDayDemo();
  }

  /// Lens mood strength: 1 right after a check-in, 0 after four hours.
  double lensMoodStrength() {
    final ts = moodTintTs;
    if (ts == null) return 0;
    final s = 1 - (DateTime.now().millisecondsSinceEpoch - ts) / kMoodDecayMs;
    return s.clamp(0.0, 1.0);
  }

  /// The current mood coordinates, faded by the 4-hour strength and honouring
  /// the atmosphere setting. Screens turn this into a colour via seaTint(...).
  /// Returns null when there's no live weather to wear.
  (double, double)? currentMoodVA() {
    if (!moodAtmosphereOn) return null;
    final s = lensMoodStrength();
    if (s <= 0) return null;
    JournalEntry? mood;
    for (final e in entries) {
      if (e.isMoodEntry && (mood == null || e.ts > mood.ts)) mood = e;
    }
    if (mood == null) return null;
    return ((mood.v ?? 0) * s, (mood.a ?? 0) * s);
  }

  // ---------- settings setters (persist + notify) ----------
  void setWelcomed(List<String> prefsChosen) {
    welcomed = true;
    onboardingPreferences = prefsChosen;
    _repo.welcomed = true;
    _repo.onboardingPreferences = prefsChosen;
    notifyListeners();
  }

  void setRoom(String value) {
    room = value;
    _repo.room = value;
    notifyListeners();
  }

  void setAutoRoom(bool on) {
    autoRoomOn = on;
    _repo.autoRoomOn = on;
    notifyListeners();
  }

  void setMoodAtmosphere(bool on) {
    moodAtmosphereOn = on;
    _repo.moodAtmosphereOn = on;
    notifyListeners();
  }

  void setTextSize(String value) {
    textSize = value;
    _repo.textSize = value;
    notifyListeners();
  }

  void setReducedMotion(bool on) {
    reducedMotionOn = on;
    _repo.reducedMotionOn = on;
    notifyListeners();
  }

  void setProfileName(String value) {
    profileName = value;
    _repo.profileName = value;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    _repo.language = value;
    notifyListeners();
  }

  void setReminder(bool on) {
    reminderOn = on;
    _repo.reminderOn = on;
    if (on) {
      NotificationService.instance.requestPermission().then((granted) {
        if (granted) NotificationService.instance.scheduleDaily(reminderAt);
      });
    } else {
      NotificationService.instance.cancelDaily();
    }
    notifyListeners();
  }

  void setReminderTime(String value) {
    reminderAt = value;
    _repo.reminderAt = value;
    if (reminderOn) NotificationService.instance.scheduleDaily(value);
    notifyListeners();
  }

  void setWeeklyReminder(bool on) {
    weeklyReminderOn = on;
    _repo.weeklyReminderOn = on;
    if (on) {
      NotificationService.instance.requestPermission().then((granted) {
        if (granted) {
          NotificationService.instance.scheduleWeekly(weeklyReminderDay);
        }
      });
    } else {
      NotificationService.instance.cancelWeekly();
    }
    notifyListeners();
  }

  void setWeeklyReminderDay(int day) {
    weeklyReminderDay = day;
    _repo.weeklyReminderDay = day;
    if (weeklyReminderOn) NotificationService.instance.scheduleWeekly(day);
    notifyListeners();
  }

  void setQuietHours(bool on) {
    quietHoursOn = on;
    _repo.quietHoursOn = on;
    notifyListeners();
  }

  void setQuietHoursStart(String value) {
    quietHoursStart = value;
    _repo.quietHoursStart = value;
    notifyListeners();
  }

  void setQuietHoursEnd(String value) {
    quietHoursEnd = value;
    _repo.quietHoursEnd = value;
    notifyListeners();
  }

  void setPinLock(bool on) {
    pinLockOn = on;
    _repo.pinLockOn = on;
    notifyListeners();
  }

  void setPin(String value) {
    pinCode = value;
    _repo.pinCode = value;
    notifyListeners();
  }

  void setAutoLock(int seconds) {
    autoLockSeconds = seconds;
    _repo.autoLockSeconds = seconds;
    notifyListeners();
  }

  /// Raw settings prompt-style override (null when unset), as
  /// `dailyPromptOptions` reads it in the prototype.
  String? get promptStyleRaw => _promptStyle;

  /// Prompt style falls back to the first onboarding preference, else 'question'.
  String get promptStyle =>
      _promptStyle ??
      (onboardingPreferences.isNotEmpty
          ? onboardingPreferences.first
          : 'question');

  void setPromptStyle(String value) {
    _promptStyle = value;
    _repo.promptStyle = value;
    notifyListeners();
  }

  void setTideLineDefault(bool on) {
    tideLineDefault = on;
    _repo.tideLineDefault = on;
    notifyListeners();
  }

  void setAiEnabled(bool on) {
    aiEnabled = on;
    _repo.aiEnabled = on;
    notifyListeners();
  }

  void startTideExperiment(TideExperiment experiment) {
    final active = activeTideExperiment;
    if (active != null) {
      tideExperiments = tideExperiments.map((e) {
        if (e.id == active.id) {
          return e.copyWith(completedAt: DateTime.now().millisecondsSinceEpoch);
        }
        return e;
      }).toList();
    }
    tideExperiments = [...tideExperiments, experiment];
    _saveTideExperiments();
  }

  void recordTideObservation(String experimentId, String response) {
    if (!const {'did', 'not', 'skipped'}.contains(response)) return;
    tideExperiments = tideExperiments.map((experiment) {
      if (experiment.id != experimentId || experiment.isComplete) {
        return experiment;
      }
      final now = DateTime.now();
      final filtered = experiment.observations.where((observation) {
        final day = DateTime.fromMillisecondsSinceEpoch(observation.ts);
        return !(day.year == now.year &&
            day.month == now.month &&
            day.day == now.day);
      }).toList();
      return experiment.copyWith(
        observations: [
          ...filtered,
          TideObservation(ts: now.millisecondsSinceEpoch, response: response),
        ],
      );
    }).toList();
    _saveTideExperiments();
  }

  void completeTideExperiment(String experimentId) {
    tideExperiments = tideExperiments.map((experiment) {
      if (experiment.id == experimentId && !experiment.isComplete) {
        return experiment.copyWith(
            completedAt: DateTime.now().millisecondsSinceEpoch);
      }
      return experiment;
    }).toList();
    _saveTideExperiments();
  }

  void _saveTideExperiments() => persistTideExperiments();

  // ---------- derived ----------
  /// Auto room: day between 07:00 and 19:00, matching JS `applyAutoRoom()`.
  String get effectiveRoom {
    if (!autoRoomOn) return room;
    final hr = DateTime.now().hour;
    return (hr >= 7 && hr < 19) ? 'day' : 'night';
  }

  /// Text scale: .92 / 1 / 1.08 (CSS 13.8px / 15px / 16.2px).
  double get textScale => textSize == 'small'
      ? .92
      : textSize == 'large'
          ? 1.08
          : 1.0;

  // ---------- data section ----------
  /// Bytes held under `mentesana-*` keys (key + value, like the prototype's
  /// localStorage estimate). Quota shown against the same 5 MB yardstick.
  int storageBytes() {
    var total = 0;
    for (final key in _repo.allKeys) {
      if (!key.startsWith('mentesana-')) continue;
      final value = _repo.getRaw(key);
      total += utf8.encode(key).length;
      total += utf8.encode('$value').length;
    }
    return total;
  }

  /// JS export-as-text format: newest first,
  /// `date time — word` + optional text, blank line between pages.
  String exportText() {
    final lines = entries.reversed.map((e) {
      final dt = e.date;
      final date = '${dt.month}/${dt.day}/${dt.year}';
      return '$date ${formatTime(dt)} — ${e.word}${e.text.isNotEmpty ? '\n${e.text}' : ''}';
    });
    return lines.join('\n\n');
  }

  String exportJson() => jsonEncode({
        'entries': entries.map((e) => e.toJson()).toList(),
        'tideExperiments': tideExperiments.map((e) => e.toJson()).toList(),
      });

  /// Record weekly-insight lines that were just shown, keeping only the most
  /// recent so retired lines can eventually resurface.
  void recordShownInsightLines(List<String> lines) {
    if (lines.isEmpty) return;
    final merged = [...shownInsightLines, ...lines];
    shownInsightLines =
        merged.length > 40 ? merged.sublist(merged.length - 40) : merged;
    _repo.shownInsightLinesJson = jsonEncode(shownInsightLines);
  }

  /// Restore a JSON backup (as produced by [exportJson] or an encrypted
  /// backup). Merges by timestamp so a restore never silently drops pages the
  /// device already has. Returns the page count after restore, or null if the
  /// payload could not be read.
  int? importJson(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final incoming = (data['entries'] is List)
          ? (data['entries'] as List)
              .map(JournalEntry.fromJson)
              .whereType<JournalEntry>()
              .toList()
          : <JournalEntry>[];
      final byTs = {for (final e in entries) e.ts: e};
      for (final e in incoming) {
        byTs[e.ts] = e;
      }
      entries = byTs.values.toList()..sort((a, b) => a.ts.compareTo(b.ts));
      if (data['tideExperiments'] is List) {
        final byId = {for (final x in tideExperiments) x.id: x};
        for (final x in (data['tideExperiments'] as List)
            .map(TideExperiment.fromJson)
            .whereType<TideExperiment>()) {
          byId[x.id] = x;
        }
        tideExperiments = byId.values.toList();
        _saveTideExperiments();
      }
      saveEntries();
      return entries.length;
    } catch (_) {
      return null;
    }
  }

  /// A passphrase-locked backup string (AES-256-CBC, random IV prepended).
  /// The passphrase is never stored; losing it means losing the backup.
  String exportEncrypted(String passphrase) {
    final keyBytes = crypto.sha256.convert(utf8.encode(passphrase)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(exportJson(), iv: iv);
    return 'MSNA1:${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Restore a passphrase-locked backup produced by [exportEncrypted].
  /// Returns the page count after restore, or null on a wrong passphrase or
  /// unreadable payload.
  int? importEncrypted(String blob, String passphrase) {
    try {
      final parts = blob.trim().split(':');
      if (parts.length != 3 || parts[0] != 'MSNA1') return null;
      final keyBytes = crypto.sha256.convert(utf8.encode(passphrase)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV(base64Decode(parts[1]));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final plain =
          encrypter.decrypt(enc.Encrypted(base64Decode(parts[2])), iv: iv);
      return importJson(plain);
    } catch (_) {
      return null;
    }
  }

  // ---------- journal drafts (JS readJournalDraft / saveJournalDraft) ----------
  JournalDraft? readJournalDraft() {
    try {
      final raw = jsonDecode(_repo.journalDraftJson);
      return JournalDraft.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  /// Returns false when storage refused the draft ('storage is full').
  bool saveJournalDraft(JournalDraft draft) {
    try {
      _repo.journalDraftJson = jsonEncode(draft.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearJournalDraft() {
    _repo.journalDraftJson = '{}';
  }

  // ---------- "a page for today" dismissal (JS PROMPT_DISMISS_KEY) ----------
  static String _todaysDismissKey() {
    // JS `new Date().toDateString()`, e.g. "Thu Jul 16 2026".
    const dows = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final d = DateTime.now();
    final dd = d.day.toString().padLeft(2, '0');
    return '${dows[d.weekday % 7]} ${months[d.month - 1]} $dd ${d.year}';
  }

  bool isPromptDismissedToday() => _repo.promptDismissed == _todaysDismissKey();

  void setPromptDismissed(bool dismissed) {
    if (dismissed) {
      _repo.promptDismissed = _todaysDismissKey();
    } else {
      _repo.promptDismissed = '';
    }
    notifyListeners();
  }

  // ---------- entry helpers used across screens ----------
  JournalEntry? findByTs(int ts) {
    for (final e in entries) {
      if (e.ts == ts) return e;
    }
    return null;
  }

  void deleteEntry(JournalEntry e) {
    entries = entries.where((x) => x.ts != e.ts).toList();
    saveEntries();
  }

  // ---------- background voice transcription ----------
  // A recorded-then-transcribed voice note no longer has to finish
  // transcribing before its page can be kept. The journal editor hands a
  // still-running (or already-finished) transcription off to this store
  // via [transcribeInBackground], which survives the editor closing — the
  // result lands on the entry itself once it's ready.

  final Set<int> _transcribing = {};
  WhisperTranscriber? _backgroundTranscriber;

  /// True while a background transcription is still running for the
  /// entry with this `ts`. Screens can use this to show a small
  /// "transcribing…" indicator.
  bool isTranscribing(int ts) => _transcribing.contains(ts);

  /// Marks [entry] as awaiting an in-flight transcription and persists
  /// it right away — the entry is safe to leave even though the
  /// transcript has not landed yet.
  void beginPendingTranscription(JournalEntry entry, String audioPath) {
    final current = findByTs(entry.ts);
    if (current == null) {
      addEntry(entry.copyWith(
        pendingTranscription: true,
        pendingAudioPath: audioPath,
      ));
      return;
    }
    updateEntry(
      current,
      current.copyWith(
        pendingTranscription: true,
        pendingAudioPath: audioPath,
      ),
    );
  }

  /// Runs [audioPath]'s transcription in the background, independent of
  /// any editor screen's lifecycle, and lands the transcript on [entry]
  /// (by `ts`) when it finishes.
  void transcribeInBackground(
    JournalEntry entry,
    String audioPath, {
    VoiceModelQuality quality = VoiceModelQuality.balanced,
    String language = 'auto',
  }) {
    beginPendingTranscription(entry, audioPath);
    final ts = entry.ts;
    if (_transcribing.contains(ts)) return; // already running for this page
    _transcribing.add(ts);
    _backgroundTranscriber ??= WhisperTranscriber(quality: quality);
    _backgroundTranscriber!
        .transcribe(audioPath, language: language)
        .then((transcript) => completeTranscription(ts, transcript))
        .catchError((_) => failTranscription(ts))
        .whenComplete(() {
      _transcribing.remove(ts);
      _deleteFile(audioPath);
    });
  }

  /// Lands a finished background transcript on the entry with this `ts`
  /// — appended after whatever text is already there, matching the
  /// spacing courtesy the editor itself uses when inserting live.
  void completeTranscription(int ts, String transcript) {
    final e = findByTs(ts);
    if (e == null) return;
    final t = transcript.trim();
    var updated =
        e.copyWith(pendingTranscription: false, pendingAudioPath: null);
    if (t.isNotEmpty) {
      final newText = _appendTranscript(e.text, t);
      updated = updated.copyWith(
        text: newText,
        wordCount:
            newText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
      );
    }
    updateEntry(e, updated);
  }

  /// Clears the pending flag after a background transcription fails —
  /// nothing already on the page is touched or lost.
  void failTranscription(int ts) {
    final e = findByTs(ts);
    if (e == null) return;
    updateEntry(
      e,
      e.copyWith(pendingTranscription: false, pendingAudioPath: null),
    );
  }

  static String _appendTranscript(String existing, String transcript) {
    if (existing.trim().isEmpty) return transcript;
    return existing.endsWith('\n')
        ? '$existing\n$transcript'
        : '$existing\n\n$transcript';
  }

  static void _deleteFile(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  // ---------- reminders (in-app, while open — see README) ----------
  /// JS `isInQuietHours()`, including the overnight window (e.g. 22:00–08:00).
  bool isInQuietHours([DateTime? at]) {
    if (!quietHoursOn) return false;
    final now = at ?? DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final startMin = _timeStrToMinutes(quietHoursStart);
    final endMin = _timeStrToMinutes(quietHoursEnd);
    if (startMin <= endMin) return minutes >= startMin && minutes < endMin;
    return minutes >= startMin || minutes < endMin;
  }

  static int _timeStrToMinutes(String ts) {
    final parts = ts.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return h * 60 + m;
  }

  /// JS `checkReminders()`: daily fires in a five-minute window once per day;
  /// weekly fires between 09:00 and 10:00 on the chosen day, once per week.
  /// Returns the toast messages that should surface now.
  List<String> checkReminders() {
    final fired = <String>[];
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final todayKey = _dayKey(now);

    if (reminderOn && !isInQuietHours(now)) {
      final remMin = _timeStrToMinutes(reminderAt);
      final lastDaily = _repo.reminderLastFired;
      if (nowMin >= remMin && nowMin < remMin + 5 && lastDaily != todayKey) {
        _repo.reminderLastFired = todayKey;
        fired.add('a quiet nudge — the sea has room for a page.');
      }
    }

    if (weeklyReminderOn && !isInQuietHours(now)) {
      final weekKeyStr = '$todayKey-$weeklyReminderDay';
      final lastWeekly = _repo.weeklyReminderLastFired;
      final jsDay = now.weekday % 7; // JS getDay(): Sunday = 0
      if (jsDay == weeklyReminderDay &&
          nowMin >= 540 &&
          nowMin < 600 &&
          lastWeekly != weekKeyStr) {
        _repo.weeklyReminderLastFired = weekKeyStr;
        fired.add('your weekly reflection is ready when you are.');
      }
    }
    return fired;
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

/// JS `DEMO_DAYS` — the archive's sample sea, shown until the user keeps
/// their first page. Times: `h` hours on the day `d` days ago, minutes
/// `(h * 11) % 60`.
List<JournalEntry> demoDays() {
  JournalEntry mk(int d, int h, double v, double a, String word, String text) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day - d, h, (h * 11) % 60);
    return JournalEntry(
        ts: dt.millisecondsSinceEpoch, v: v, a: a, word: word, text: text);
  }

  return [
    mk(1, 8, .3, .35, 'restless',
        'Slept badly. Coffee helped less than usual.'),
    mk(1, 20, .55, -.35, 'content',
        'Long walk after the library. The draft is finally moving.'),
    mk(2, 22, -.5, .5, 'frustrated',
        'Deadline moved again. Wrote until it stopped buzzing.'),
    mk(3, 21, -.2, -.55, 'tired', ''),
    mk(4, 7, .2, .55, 'alive',
        'Morning swim. Cold enough to reset everything.'),
    mk(4, 19, -.15, -.25, 'tender',
        'Long day, in the end. Called it early, made tea.'),
    mk(5, 21, 0, 0, 'steady', ''),
    mk(6, 18, -.6, .7, 'on edge',
        'Presentation tomorrow. Named it and it shrank a little.'),
    mk(7, 20, .65, .3, 'grateful', 'Call home. Nonna asked about the app.'),
    mk(8, 21, -.35, -.3, 'flat', ''),
  ];
}

/// JS `fmtTime()`: `toLocaleTimeString(hour: numeric, minute: 2-digit)`,
/// e.g. "7:40 PM".
String formatTime(DateTime dt) {
  final h24 = dt.hour;
  final h = h24 % 12 == 0 ? 12 : h24 % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m ${h24 < 12 ? 'AM' : 'PM'}';
}
