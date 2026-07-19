// Mentesana — Settings Repository.
// Pure persistence layer: wraps SharedPreferences and provides typed getters
// and setters for every app setting. No business logic, no state management.
// Extracted from AppStore to separate persistence concerns from data models.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'store_keys.dart';

// Re-export so existing imports of StoreKeys from this file still work.
export 'store_keys.dart';

/// Pure persistence repository for all app settings.
/// Registered as an async singleton — loaded once at startup.
class SettingsRepository {
  SettingsRepository._(this._prefs);

  final SharedPreferences _prefs;

  /// Create from an already-obtained SharedPreferences instance.
  /// Used in tests where [SharedPreferences.setMockInitialValues] has been
  /// called before [SharedPreferences.getInstance].
  factory SettingsRepository.createFromPrefs(SharedPreferences prefs) =>
      SettingsRepository._(prefs);

  /// Create and initialise the repository.
  static Future<SettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepository._(prefs);
  }

  // -- Generic helpers --

  String _get(String key, [String fallback = '']) =>
      _prefs.getString(key) ?? fallback;

  void _set(String key, String value) => _prefs.setString(key, value);

  bool _getBool(String key, [bool fallback = false]) =>
      _get(key, fallback ? '1' : '0') == '1';

  int _getInt(String key, [int fallback = 0]) =>
      int.tryParse(_get(key, '$fallback')) ?? fallback;

  List<String> _getList(String key) {
    try {
      final raw = jsonDecode(_get(key, '[]'));
      return raw is List ? raw.map((x) => x.toString()).toList() : [];
    } catch (_) {
      return [];
    }
  }

  // -- Accessors --

  String get entriesJson => _get(StoreKeys.entries, '[]');
  set entriesJson(String v) => _set(StoreKeys.entries, v);

  bool get welcomed => _get(StoreKeys.welcomed) == '1';
  set welcomed(bool v) => _set(StoreKeys.welcomed, v ? '1' : '0');

  List<String> get onboardingPreferences =>
      _getList(StoreKeys.onboardingPreferences);
  set onboardingPreferences(List<String> v) =>
      _set(StoreKeys.onboardingPreferences, jsonEncode(v));

  String get room => _get(StoreKeys.room, 'night');
  set room(String v) => _set(StoreKeys.room, v);

  bool get autoRoomOn => _getBool(StoreKeys.autoRoom);
  set autoRoomOn(bool v) => _set(StoreKeys.autoRoom, v ? '1' : '0');

  bool get moodAtmosphereOn => _get(StoreKeys.moodAtmosphere) != '0';
  set moodAtmosphereOn(bool v) => _set(StoreKeys.moodAtmosphere, v ? '1' : '0');

  String get textSize => _get(StoreKeys.textSize, 'regular');
  set textSize(String v) => _set(StoreKeys.textSize, v);

  bool get reducedMotionOn => _getBool(StoreKeys.reducedMotion);
  set reducedMotionOn(bool v) => _set(StoreKeys.reducedMotion, v ? '1' : '0');

  String get profileName => _get(StoreKeys.profileName, 'Alessandro');
  set profileName(String v) => _set(StoreKeys.profileName, v);

  String get language => _get(StoreKeys.language, 'en');
  set language(String v) => _set(StoreKeys.language, v);

  bool get reminderOn => _getBool(StoreKeys.reminder);
  set reminderOn(bool v) => _set(StoreKeys.reminder, v ? '1' : '0');

  String get reminderAt => _get(StoreKeys.reminderTime, '20:30');
  set reminderAt(String v) => _set(StoreKeys.reminderTime, v);

  bool get weeklyReminderOn => _getBool(StoreKeys.weeklyReminder);
  set weeklyReminderOn(bool v) => _set(StoreKeys.weeklyReminder, v ? '1' : '0');

  int get weeklyReminderDay => _getInt(StoreKeys.weeklyReminderDay);
  set weeklyReminderDay(int v) => _set(StoreKeys.weeklyReminderDay, '$v');

  bool get quietHoursOn => _getBool(StoreKeys.quietHours);
  set quietHoursOn(bool v) => _set(StoreKeys.quietHours, v ? '1' : '0');

  String get quietHoursStart => _get(StoreKeys.quietHoursStart, '22:00');
  set quietHoursStart(String v) => _set(StoreKeys.quietHoursStart, v);

  String get quietHoursEnd => _get(StoreKeys.quietHoursEnd, '08:00');
  set quietHoursEnd(String v) => _set(StoreKeys.quietHoursEnd, v);

  bool get pinLockOn => _getBool(StoreKeys.pinlock);
  set pinLockOn(bool v) => _set(StoreKeys.pinlock, v ? '1' : '0');

  String get pinCode => _get(StoreKeys.pin);
  set pinCode(String v) => _set(StoreKeys.pin, v);

  int get autoLockSeconds => _getInt(StoreKeys.autolock);
  set autoLockSeconds(int v) => _set(StoreKeys.autolock, '$v');

  String? get promptStyle => _prefs.getString(StoreKeys.promptStyle);
  set promptStyle(String? v) {
    if (v != null) {
      _set(StoreKeys.promptStyle, v);
    } else {
      _prefs.remove(StoreKeys.promptStyle);
    }
  }

  bool get tideLineDefault => _getBool(StoreKeys.tideLineDefault);
  set tideLineDefault(bool v) => _set(StoreKeys.tideLineDefault, v ? '1' : '0');

  int get attachmentCap => _getInt(StoreKeys.attachmentCap, 3);
  set attachmentCap(int v) => _set(StoreKeys.attachmentCap, '$v');

  bool get aiEnabled => _getBool(StoreKeys.aiEnabled);
  set aiEnabled(bool v) => _set(StoreKeys.aiEnabled, v ? '1' : '0');

  String get tideExperimentsJson => _get(StoreKeys.tideExperiments, '[]');
  set tideExperimentsJson(String v) => _set(StoreKeys.tideExperiments, v);

  bool get currentsOn => _get(StoreKeys.currents) != '0';
  set currentsOn(bool v) => _set(StoreKeys.currents, v ? '1' : '0');

  bool get almanacOn => _get(StoreKeys.almanac) != '0';
  set almanacOn(bool v) => _set(StoreKeys.almanac, v ? '1' : '0');

  String get undertowLastDay => _get(StoreKeys.undertowLastDay);
  set undertowLastDay(String v) => _set(StoreKeys.undertowLastDay, v);

  int get anchorQuietUntil => _getInt(StoreKeys.anchorQuietUntil);
  set anchorQuietUntil(int v) => _set(StoreKeys.anchorQuietUntil, '$v');

  String get parkedWorriesJson => _get(StoreKeys.parkedWorries, '[]');
  set parkedWorriesJson(String v) => _set(StoreKeys.parkedWorries, v);

  String get anchorsJson => _get(StoreKeys.anchors, '[]');
  set anchorsJson(String v) => _set(StoreKeys.anchors, v);

  String get shownInsightLinesJson => _get(StoreKeys.shownInsightLines, '[]');
  set shownInsightLinesJson(String v) => _set(StoreKeys.shownInsightLines, v);

  String get journalDraftJson => _get(StoreKeys.journalDraft, '{}');
  set journalDraftJson(String v) => _set(StoreKeys.journalDraft, v);

  // -- Reminder firing tracking (used by AppStore.checkReminders) --

  String get reminderLastFired => _get(StoreKeys.reminderLastFired);
  set reminderLastFired(String v) => _set(StoreKeys.reminderLastFired, v);

  String get weeklyReminderLastFired => _get(StoreKeys.weeklyReminderLastFired);
  set weeklyReminderLastFired(String v) =>
      _set(StoreKeys.weeklyReminderLastFired, v);

  // -- Prompt dismissal (per-day key) --

  String get promptDismissed => _get(StoreKeys.promptDismissed);
  set promptDismissed(String v) => _set(StoreKeys.promptDismissed, v);

  // -- Raw access (for storage estimation and migration) --

  /// All keys currently held in SharedPreferences (for storage estimation).
  Iterable<String> get allKeys => _prefs.getKeys();

  /// Raw value for an arbitrary key (for storage estimation).
  Object? getRaw(String key) => _prefs.get(key);

  /// Generic string read for a key not covered by a typed accessor.
  String getString(String key, [String fallback = '']) =>
      _prefs.getString(key) ?? fallback;

  /// Generic string write for a key not covered by a typed accessor.
  void setString(String key, String value) => _prefs.setString(key, value);
}
