// Mentesana — local store.
// Flutter port of the localStorage layer from the Vite prototype (src/main.js).
// Storage keys mirror the prototype 1:1 (`mentesana-*`) so behavior stays comparable.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

import '_shared/services/settings_repository.dart';
import 'notification_service.dart';
import 'voice_transcription_service.dart';

/// One page attachment (image or voice note), stored as a data URL —
/// the exact shape the prototype keeps in localStorage.
class Attachment {
  Attachment({
    required this.name,
    required this.type,
    this.size = 0,
    this.data = '',
  });

  final String name;
  final String type; // MIME, e.g. image/png or audio/webm
  final int size;
  final String data; // data URL (base64)

  bool get isImage => type.startsWith('image/');
  bool get isAudio => type.startsWith('audio/');

  Map<String, dynamic> toJson() =>
      {'name': name, 'type': type, 'size': size, 'data': data};

  static Attachment? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    return Attachment(
      name: (raw['name'] ?? '').toString(),
      type: (raw['type'] ?? '').toString(),
      size: raw['size'] is num ? (raw['size'] as num).toInt() : 0,
      data: (raw['data'] ?? '').toString(),
    );
  }
}

/// One earlier version of a page (JS keeps the last 5 on edit).
class EntryVersion {
  EntryVersion({
    required this.editedAt,
    required this.text,
    required this.title,
    this.tag = '',
    this.tideLine = '',
  });

  final int editedAt;
  final String text;
  final String title;
  final String tag;
  final String tideLine;

  Map<String, dynamic> toJson() => {
        'editedAt': editedAt,
        'text': text,
        'title': title,
        'tag': tag,
        'tideLine': tideLine,
      };

  static EntryVersion? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final at = raw['editedAt'];
    if (at is! num) return null;
    return EntryVersion(
      editedAt: at.toInt(),
      text: (raw['text'] ?? '').toString(),
      title: (raw['title'] ?? '').toString(),
      tag: (raw['tag'] ?? '').toString(),
      tideLine: (raw['tideLine'] ?? '').toString(),
    );
  }
}

/// One kept page — the archive shape from the prototype. Mutable, exactly
/// like the JS objects the prototype edits in place:
/// `{ ts, v, a, word, edited, text, tag, title, prompt, wordCount,
///    attachments, tideLine, tideAt, moodTs, texture, reflectionStep,
///    afterV, afterA, afterWord, afterTs, versions }`.
class JournalEntry {
  JournalEntry({
    required this.ts,
    this.v,
    this.a,
    this.word,
    this.edited = false,
    this.text = '',
    this.tag = '',
    this.title = '',
    this.prompt = '',
    this.wordCount,
    List<Attachment>? attachments,
    this.tideLine = '',
    this.tideAt,
    this.moodTs,
    this.texture = '',
    this.reflectionStep = '',
    this.afterV,
    this.afterA,
    this.afterWord,
    this.afterTs,
    List<EntryVersion>? versions,
    this.pendingTranscription = false,
    this.pendingAudioPath,
  })  : attachments = attachments ?? [],
        versions = versions ?? [];

  /// Milliseconds since epoch (JS `Date.now()`).
  int ts;
  double? v;
  double? a;

  /// The kept weather word. Null for a page without a weather
  /// (the prototype migrated the old `'journal'` placeholder to null).
  String? word;
  bool edited;
  String text;
  String tag;
  String title;
  String prompt;
  int? wordCount;
  List<Attachment> attachments;

  /// A line left for a later tide; resurfaces after `tideAt`.
  String tideLine;
  int? tideAt;

  /// When the weather on this page was last kept (mood edited after writing).
  int? moodTs;
  String texture;
  String reflectionStep;

  /// The after-writing weather (JS `keepAfterWeather()`).
  double? afterV;
  double? afterA;
  String? afterWord;
  int? afterTs;
  List<EntryVersion> versions;

  /// True while a voice-note transcription is still finishing in the
  /// background for this page — set the moment the page is kept if
  /// recording finished before transcribing did (see
  /// AppStore.transcribeInBackground). Screens can show a small
  /// "transcribing…" indicator while this is true.
  bool pendingTranscription;

  /// The temp audio file a pending background transcription is working
  /// from. Cleared (and the file deleted) once that transcription lands
  /// or fails — never persisted past that point.
  String? pendingAudioPath;

  /// JS `isMoodEntry()`: v & a are numbers, word present and not 'journal'.
  bool get isMoodEntry =>
      v != null &&
      a != null &&
      word != null &&
      word!.isNotEmpty &&
      word != 'journal';

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(ts);

  Map<String, dynamic> toJson() => {
        'ts': ts,
        if (v != null) 'v': v,
        if (a != null) 'a': a,
        'word': word,
        'edited': edited,
        if (text.isNotEmpty) 'text': text,
        if (tag.isNotEmpty) 'tag': tag,
        if (title.isNotEmpty) 'title': title,
        if (prompt.isNotEmpty) 'prompt': prompt,
        if (wordCount != null) 'wordCount': wordCount,
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toJson()).toList(),
        if (tideLine.isNotEmpty) 'tideLine': tideLine,
        if (tideAt != null) 'tideAt': tideAt,
        if (moodTs != null) 'moodTs': moodTs,
        if (texture.isNotEmpty) 'texture': texture,
        if (reflectionStep.isNotEmpty) 'reflectionStep': reflectionStep,
        if (afterV != null) 'afterV': afterV,
        if (afterA != null) 'afterA': afterA,
        if (afterWord != null) 'afterWord': afterWord,
        if (afterTs != null) 'afterTs': afterTs,
        if (versions.isNotEmpty)
          'versions': versions.map((v) => v.toJson()).toList(),
        if (pendingTranscription) 'pendingTranscription': true,
        if (pendingAudioPath != null) 'pendingAudioPath': pendingAudioPath,
      };

  static JournalEntry? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final ts = raw['ts'];
    if (ts is! num) return null;
    double? numOrNull(dynamic x) => x is num ? x.toDouble() : null;
    String? strOrNull(dynamic x) =>
        x == null ? null : (x.toString().isEmpty ? null : x.toString());
    return JournalEntry(
      ts: ts.toInt(),
      v: numOrNull(raw['v']),
      a: numOrNull(raw['a']),
      word: strOrNull(raw['word']),
      edited: raw['edited'] == true,
      text: (raw['text'] ?? '').toString(),
      tag: (raw['tag'] ?? '').toString(),
      title: (raw['title'] ?? '').toString(),
      prompt: (raw['prompt'] ?? '').toString(),
      wordCount:
          raw['wordCount'] is num ? (raw['wordCount'] as num).toInt() : null,
      attachments: raw['attachments'] is List
          ? (raw['attachments'] as List)
              .map(Attachment.fromJson)
              .whereType<Attachment>()
              .toList()
          : null,
      tideLine: (raw['tideLine'] ?? '').toString(),
      tideAt: raw['tideAt'] is num ? (raw['tideAt'] as num).toInt() : null,
      moodTs: raw['moodTs'] is num ? (raw['moodTs'] as num).toInt() : null,
      texture: (raw['texture'] ?? '').toString(),
      reflectionStep: (raw['reflectionStep'] ?? '').toString(),
      afterV: numOrNull(raw['afterV']),
      afterA: numOrNull(raw['afterA']),
      afterWord: strOrNull(raw['afterWord']),
      afterTs: raw['afterTs'] is num ? (raw['afterTs'] as num).toInt() : null,
      versions: raw['versions'] is List
          ? (raw['versions'] as List)
              .map(EntryVersion.fromJson)
              .whereType<EntryVersion>()
              .toList()
          : null,
      pendingTranscription: raw['pendingTranscription'] == true,
      pendingAudioPath: strOrNull(raw['pendingAudioPath']),
    );
  }
}

/// JS `titleFromPage()`: first non-empty line, markup stripped,
/// first nine words, capped at 84 characters.
String titleFromPage(String? text) {
  final first = (text ?? '')
      .split(RegExp(r'\n+'))
      .map((x) => x.trim())
      .firstWhere((x) => x.isNotEmpty, orElse: () => '');
  final clean = first
      .replaceAll(RegExp(r'[*_#>`]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (clean.isEmpty) return '';
  final words = clean.split(' ');
  final joined = words.take(9).join(' ') + (words.length > 9 ? '…' : '');
  return joined.length > 84 ? joined.substring(0, 84) : joined;
}

/// JS `SYSTEM_PAGE_TITLES` — placeholder titles migrated to real ones.
const kSystemPageTitles = [
  'a page for whatever is here',
  'a page for whatever is here — no weather required.',
  'a page for whatever is here — no weather required',
];

bool isSystemPageTitle(String? title) =>
    kSystemPageTitles.contains((title ?? '').trim().toLowerCase());

/// The unsaved page (JS journal draft, key `mentesana-journal-draft`).
class JournalDraft {
  JournalDraft({
    this.text = '',
    this.title = '',
    this.tag = '',
    this.bottle = '',
    this.mode = 'free',
    this.prompt,
    required this.ts,
    this.activeEntryTs,
    List<Attachment>? attachments,
    this.v,
    this.a,
    this.word,
  }) : attachments = attachments ?? [];

  final String text;
  final String title;
  final String tag;
  final String bottle;
  final String mode; // 'mood' | 'free'
  final String? prompt;
  final int ts;
  final int? activeEntryTs;
  final List<Attachment> attachments;
  final double? v;
  final double? a;
  final String? word;

  Map<String, dynamic> toJson() => {
        'text': text,
        'title': title,
        'tag': tag,
        'bottle': bottle,
        'mode': mode,
        'prompt': prompt,
        'ts': ts,
        'activeEntryTs': activeEntryTs,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'v': v,
        'a': a,
        'word': word,
      };

  static JournalDraft? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    double? numOrNull(dynamic x) => x is num ? x.toDouble() : null;
    return JournalDraft(
      text: (raw['text'] ?? '').toString(),
      title: (raw['title'] ?? '').toString(),
      tag: (raw['tag'] ?? '').toString(),
      bottle: (raw['bottle'] ?? '').toString(),
      mode: (raw['mode'] ?? 'free').toString(),
      prompt: raw['prompt']?.toString(),
      ts: raw['ts'] is num ? (raw['ts'] as num).toInt() : 0,
      activeEntryTs: raw['activeEntryTs'] is num
          ? (raw['activeEntryTs'] as num).toInt()
          : null,
      attachments: raw['attachments'] is List
          ? (raw['attachments'] as List)
              .map(Attachment.fromJson)
              .whereType<Attachment>()
              .toList()
          : null,
      v: numOrNull(raw['v']),
      a: numOrNull(raw['a']),
      word: raw['word']?.toString(),
    );
  }
}

/// One daily note inside a Tide Lab experiment. The only question Tide Lab
/// asks is whether the small action found the user today (`did`, `not`, or
/// `skipped`) — the mood measurement is borrowed from the ordinary daily
/// check-in, never rated twice.
class TideObservation {
  const TideObservation({required this.ts, required this.response});

  final int ts;
  final String response;

  Map<String, dynamic> toJson() => {'ts': ts, 'response': response};

  static TideObservation? fromJson(dynamic raw) {
    if (raw is! Map || raw['ts'] is! num) return null;
    var response = (raw['response'] ?? '').toString();
    // Early prototypes stored 'paired'/'lower'/'same'/'higher' responses —
    // all of them meant the action happened that day.
    const legacy = {
      'paired': 'did',
      'lower': 'did',
      'same': 'did',
      'higher': 'did',
    };
    response = legacy[response] ?? response;
    if (!const {'did', 'not', 'skipped'}.contains(response)) return null;
    return TideObservation(ts: (raw['ts'] as num).toInt(), response: response);
  }
}

/// A user-owned N-of-1 reflection. It stores a hypothesis and observations,
/// never a diagnosis, causal claim, score, or success state.
class TideExperiment {
  TideExperiment({
    required this.id,
    required this.title,
    required this.hypothesis,
    required this.action,
    required this.theme,
    required this.startedAt,
    this.durationDays = 7,
    List<int>? evidenceTs,
    List<TideObservation>? observations,
    this.completedAt,
  })  : evidenceTs = evidenceTs ?? [],
        observations = observations ?? [];

  final String id;
  final String title;
  final String hypothesis;
  final String action;
  final String theme;
  final int startedAt;
  final int durationDays;
  final List<int> evidenceTs;
  final List<TideObservation> observations;
  int? completedAt;

  bool get isComplete => completedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hypothesis': hypothesis,
        'action': action,
        'theme': theme,
        'startedAt': startedAt,
        'durationDays': durationDays,
        'evidenceTs': evidenceTs,
        'observations': observations.map((o) => o.toJson()).toList(),
        if (completedAt != null) 'completedAt': completedAt,
      };

  static TideExperiment? fromJson(dynamic raw) {
    if (raw is! Map || raw['startedAt'] is! num) return null;
    final id = (raw['id'] ?? '').toString();
    if (id.isEmpty) return null;
    return TideExperiment(
      id: id,
      title: (raw['title'] ?? 'a small experiment').toString(),
      hypothesis: (raw['hypothesis'] ?? '').toString(),
      action: (raw['action'] ?? '').toString(),
      theme: (raw['theme'] ?? 'daily life').toString(),
      startedAt: (raw['startedAt'] as num).toInt(),
      durationDays: raw['durationDays'] is num
          ? (raw['durationDays'] as num).toInt().clamp(3, 21).toInt()
          : 7,
      evidenceTs: raw['evidenceTs'] is List
          ? (raw['evidenceTs'] as List)
              .whereType<num>()
              .map((x) => x.toInt())
              .toList()
          : null,
      observations: raw['observations'] is List
          ? (raw['observations'] as List)
              .map(TideObservation.fromJson)
              .whereType<TideObservation>()
              .toList()
          : null,
      completedAt: raw['completedAt'] is num
          ? (raw['completedAt'] as num).toInt()
          : null,
    );
  }
}

/// A worry set down on purpose, to be looked at later on the user's own
/// terms — worry postponement, with the tide holding it in the meantime.
/// It returns on the journal home once its time comes; nothing pushes.
class ParkedWorry {
  ParkedWorry({
    required this.ts,
    required this.text,
    required this.returnAt,
    this.settled = false,
  });

  int ts;
  String text;
  int returnAt;
  bool settled;

  static ParkedWorry? fromJson(dynamic j) {
    if (j is! Map) return null;
    final ts = j['ts'], text = j['text'], returnAt = j['returnAt'];
    if (ts is! int || text is! String || returnAt is! int) return null;
    return ParkedWorry(
      ts: ts,
      text: text,
      returnAt: returnAt,
      settled: j['settled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'ts': ts,
        'text': text,
        'returnAt': returnAt,
        'settled': settled,
      };
}

/// One tiny planned action, mined from the user's own gentler days —
/// behavioural activation at the smallest possible scale. At most one is
/// open at a time; skipping is costless; nothing is ever counted.
class Anchor {
  Anchor({
    required this.setAt,
    required this.text,
    required this.theme,
    required this.forDay,
    this.reflectedAt,
    this.outcome = '',
  });

  int setAt;
  String text;
  String theme;

  /// Local calendar key ('yyyy-mm-dd') of the day the anchor is held for.
  String forDay;
  int? reflectedAt;
  String outcome; // '' | 'written' | 'passed'

  bool get isOpen => reflectedAt == null;

  static Anchor? fromJson(dynamic j) {
    if (j is! Map) return null;
    final setAt = j['setAt'], text = j['text'], forDay = j['forDay'];
    if (setAt is! int || text is! String || forDay is! String) return null;
    return Anchor(
      setAt: setAt,
      text: text,
      theme: j['theme'] is String ? j['theme'] as String : '',
      forDay: forDay,
      reflectedAt: j['reflectedAt'] is int ? j['reflectedAt'] as int : null,
      outcome: j['outcome'] is String ? j['outcome'] as String : '',
    );
  }

  Map<String, dynamic> toJson() => {
        'setAt': setAt,
        'text': text,
        'theme': theme,
        'forDay': forDay,
        if (reflectedAt != null) 'reflectedAt': reflectedAt,
        'outcome': outcome,
      };
}

/// Local calendar key, zero-padded 'yyyy-mm-dd' — sorts and compares
/// lexicographically. Used by the currents engine and anchors.
String dayKeyOf(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// Interface language table — ported verbatim from the prototype's I18N map.
/// (The prototype only translates these strings; detail rows stay English.)
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
          ? raw
              .map(JournalEntry.fromJson)
              .whereType<JournalEntry>()
              .toList(growable: true)
          : [];
    } catch (_) {
      entries = [];
    }
    // JS boot migration: the old 'journal' word becomes null; system page
    // titles become real titles from the text.
    var entriesMigrated = false;
    for (final e in entries) {
      if (e.word == 'journal') {
        e.word = null;
        entriesMigrated = true;
      }
      if (isSystemPageTitle(e.title) && e.text.isNotEmpty) {
        e.title = titleFromPage(e.text);
        if (e.title.isEmpty) e.title = 'a page from this day';
        entriesMigrated = true;
      }
      // Restore the mood-tint timestamp from the newest mood entry (boot fix).
      if (e.isMoodEntry) {
        final t = e.moodTs ?? e.ts;
        if (t > (moodTintTs ?? 0)) moodTintTs = t;
      }
      // A background transcription that never landed (e.g. the app was
      // closed mid-run) can't resume across a restart in this version —
      // clear the flag rather than leave a "transcribing…" badge stuck
      // forever. Whatever text had already been kept is untouched.
      if (e.pendingTranscription) {
        e.pendingTranscription = false;
        e.pendingAudioPath = null;
        entriesMigrated = true;
      }
    }
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
    parkedWorries.add(ParkedWorry(
      ts: now.millisecondsSinceEpoch,
      text: text,
      returnAt: returns.millisecondsSinceEpoch,
    ));
    _saveParkedWorries();
  }

  List<ParkedWorry> get dueParkedWorries {
    final now = DateTime.now().millisecondsSinceEpoch;
    return parkedWorries
        .where((w) => !w.settled && w.returnAt <= now)
        .toList(growable: false);
  }

  void settleWorry(ParkedWorry w) {
    w.settled = true;
    _saveParkedWorries();
  }

  void _saveParkedWorries() {
    _repo.parkedWorriesJson =
        jsonEncode(parkedWorries.map((w) => w.toJson()).toList());
    notifyListeners();
  }

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
    anchors.add(Anchor(
      setAt: now.millisecondsSinceEpoch,
      text: text,
      theme: theme,
      forDay: dayKeyOf(tomorrow.millisecondsSinceEpoch),
    ));
    _saveAnchors();
  }

  void reflectAnchor(Anchor a, String outcome) {
    a.reflectedAt = DateTime.now().millisecondsSinceEpoch;
    a.outcome = outcome;
    _saveAnchors();
  }

  /// 'not now' on an anchor invite — quiet for a few days, never punished.
  void quietAnchorInvites({int days = 3}) {
    anchorQuietUntil = DateTime.now().millisecondsSinceEpoch + days * 86400000;
    _repo.anchorQuietUntil = anchorQuietUntil;
    notifyListeners();
  }

  void _saveAnchors() {
    _repo.anchorsJson = jsonEncode(anchors.map((a) => a.toJson()).toList());
    notifyListeners();
  }

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
    e.text = e.text.trim().isEmpty ? add : '${e.text.trimRight()}\n\n$add';
    e.wordCount =
        e.text.trim().isEmpty ? 0 : e.text.trim().split(RegExp(r'\s+')).length;
    saveEntries();
  }

  // ---------- i18n ----------
  String t(String key) => kI18n[language]?[key] ?? kI18n['en']![key] ?? key;

  // ---------- entries ----------
  void saveEntries() {
    _repo.entriesJson = jsonEncode(entries.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  void addEntry(JournalEntry e) {
    entries.add(e);
    if (e.isMoodEntry) moodTintTs = e.ts;
    saveEntries();
  }

  void resetEntries() {
    entries = [];
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
      active.completedAt = DateTime.now().millisecondsSinceEpoch;
    }
    tideExperiments.add(experiment);
    _saveTideExperiments();
  }

  void recordTideObservation(String experimentId, String response) {
    if (!const {'did', 'not', 'skipped'}.contains(response)) return;
    TideExperiment? experiment;
    for (final item in tideExperiments) {
      if (item.id == experimentId) experiment = item;
    }
    if (experiment == null || experiment.isComplete) return;
    final now = DateTime.now();
    experiment.observations.removeWhere((observation) {
      final day = DateTime.fromMillisecondsSinceEpoch(observation.ts);
      return day.year == now.year &&
          day.month == now.month &&
          day.day == now.day;
    });
    experiment.observations.add(TideObservation(
      ts: now.millisecondsSinceEpoch,
      response: response,
    ));
    _saveTideExperiments();
  }

  void completeTideExperiment(String experimentId) {
    for (final experiment in tideExperiments) {
      if (experiment.id == experimentId && !experiment.isComplete) {
        experiment.completedAt = DateTime.now().millisecondsSinceEpoch;
      }
    }
    _saveTideExperiments();
  }

  void _saveTideExperiments() {
    _repo.tideExperimentsJson =
        jsonEncode(tideExperiments.map((e) => e.toJson()).toList());
    notifyListeners();
  }

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
    entries.remove(e);
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
    entry.pendingTranscription = true;
    entry.pendingAudioPath = audioPath;
    if (!entries.contains(entry)) entries.add(entry);
    saveEntries();
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
    e.pendingTranscription = false;
    e.pendingAudioPath = null;
    final t = transcript.trim();
    if (t.isNotEmpty) {
      e.text = _appendTranscript(e.text, t);
      e.wordCount =
          e.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    }
    saveEntries();
  }

  /// Clears the pending flag after a background transcription fails —
  /// nothing already on the page is touched or lost.
  void failTranscription(int ts) {
    final e = findByTs(ts);
    if (e == null) return;
    e.pendingTranscription = false;
    e.pendingAudioPath = null;
    saveEntries();
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
