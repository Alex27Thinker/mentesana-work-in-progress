// Mentesana — Storage keys (canonical).
// Identical strings to the Vite prototype's localStorage keys.
// This is the single source of truth — both AppStore and SettingsRepository
// import from here. Previously duplicated in two files.

/// Storage keys — identical strings to the Vite prototype's localStorage keys.
class StoreKeys {
  static const entries = 'mentesana-entries';
  static const welcomed = 'mentesana-welcomed';
  static const onboardingPreferences = 'mentesana-onboarding-preferences';
  static const promptStyle = 'mentesana-prompt-style';
  static const room = 'mentesana-room';
  static const autoRoom = 'mentesana-auto-room';
  static const moodAtmosphere = 'mentesana-mood-atmosphere';
  static const textSize = 'mentesana-text-size';
  static const reducedMotion = 'mentesana-reduced-motion';
  static const profileName = 'mentesana-profile-name';
  static const language = 'mentesana-language';
  static const reminder = 'mentesana-reminder';
  static const reminderTime = 'mentesana-reminder-time';
  static const reminderLastFired = 'mentesana-reminder-last-fired';
  static const weeklyReminder = 'mentesana-weekly-reminder';
  static const weeklyReminderDay = 'mentesana-weekly-reminder-day';
  static const weeklyReminderLastFired = 'mentesana-weekly-reminder-last-fired';
  static const quietHours = 'mentesana-quiet-hours';
  static const quietHoursStart = 'mentesana-quiet-hours-start';
  static const quietHoursEnd = 'mentesana-quiet-hours-end';
  static const pinlock = 'mentesana-pinlock';
  static const pin = 'mentesana-pin';
  static const autolock = 'mentesana-autolock';
  static const tideLineDefault = 'mentesana-tide-line-default';
  static const attachmentCap = 'mentesana-attachment-cap';
  static const aiEnabled = 'mentesana-ai-enabled';
  static const journalDraft = 'mentesana-journal-draft';
  static const promptDismissed = 'mentesana-prompt-dismissed';
  static const tideExperiments = 'mentesana-tide-experiments';
  static const shownInsightLines = 'mentesana-shown-insight-lines';
  static const parkedWorries = 'mentesana-parked-worries';
  static const anchors = 'mentesana-anchors';
  static const currents = 'mentesana-currents';
  static const almanac = 'mentesana-almanac';
  static const undertowLastDay = 'mentesana-undertow-last-day';
  static const anchorQuietUntil = 'mentesana-anchor-quiet-until';
}