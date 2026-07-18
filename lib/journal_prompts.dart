// Mentesana — shared journal text logic.
// 1:1 port of journalPrompt, STUCK_PROMPTS, stepPrompt, dailyPromptOptions,
// PROMPT_LIBRARY, journalGreeting and distanceText from src/main.js.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'analysis_engine.dart';
import 'app_store.dart';

/// Strip the prototype's `<em>…</em>` markers (JS `replace(/<[^>]*>/g,'')`).
String stripTags(String s) => s.replaceAll(RegExp(r'<[^>]*>'), '');

/// Render a string with `<em>…</em>` markers as inline spans, the emphasized
/// runs italic serif — the same treatment the CSS gave `em` in prompts.
List<InlineSpan> richTextSpans(String s, TextStyle base, TextStyle em) {
  final spans = <InlineSpan>[];
  final re = RegExp(r'<em>(.*?)</em>');
  var idx = 0;
  for (final m in re.allMatches(s)) {
    if (m.start > idx) {
      spans.add(TextSpan(text: s.substring(idx, m.start), style: base));
    }
    spans.add(TextSpan(text: m.group(1), style: em));
    idx = m.end;
  }
  if (idx < s.length) {
    spans.add(TextSpan(text: s.substring(idx), style: base));
  }
  return spans;
}

/// Render journal text: `*emphasis*` runs become italic serif, matching the
/// prototype's renderJournalText (`\*([^\n*]+)\*` → `<em>`).
List<InlineSpan> journalTextSpans(String s, TextStyle base) {
  final em =
      GoogleFonts.alice(textStyle: base.copyWith(fontStyle: FontStyle.italic));
  final spans = <InlineSpan>[];
  final re = RegExp(r'\*([^\n*]+)\*');
  var idx = 0;
  for (final m in re.allMatches(s)) {
    if (m.start > idx) {
      spans.add(TextSpan(text: s.substring(idx, m.start), style: base));
    }
    spans.add(TextSpan(text: m.group(1), style: em));
    idx = m.end;
  }
  if (idx < s.length) {
    spans.add(TextSpan(text: s.substring(idx), style: base));
  }
  return spans;
}

/// JS `journalPrompt()` — the invitation matched to the kept weather.
/// Keeps the `<em>` marker around the user's word.
String journalPrompt(double? v, double? a, String? word) {
  final w = (word == null || word.isEmpty) ? 'this' : word;
  final vv = v ?? 0, aa = a ?? 0;
  if (aa > .3 && vv < -.2) {
    return 'you called it <em>$w</em> — what is asking for your attention?';
  }
  if (aa > .3 && vv > .2) {
    return 'you called it <em>$w</em> — what is moving through you?';
  }
  if (aa < -.3 && vv < -.2) {
    return 'you called it <em>$w</em> — what has felt hardest to carry?';
  }
  if (aa < -.3 && vv > .2) {
    return 'you called it <em>$w</em> — what helped you soften? what would you like to remember?';
  }
  if (vv >= .15) {
    return 'you called it <em>$w</em> — what made this? stay with it a moment.';
  }
  if (vv <= -.15) return 'you called it <em>$w</em> — what happened?';
  return 'you called it <em>$w</em> — where did today take you?';
}

/// JS `STUCK_PROMPTS` — for when it's hard to start.
const kStuckPrompts = [
  "what's one thing that surprised you today?",
  'what would you tell a friend who had your day?',
  "what's still sitting with you, unfinished?",
  'what did you notice in your body, right now?',
  'if today had a smell, what would it be?',
];

/// JS `pickStuckPrompt()` — day-of-month rotation, stable within a day.
String pickStuckPrompt() =>
    kStuckPrompts[DateTime.now().day % kStuckPrompts.length];

/// JS `stepPrompt(step)` — the three-step reflection scaffold.
String stepPrompt(String step, double? v, double? a) {
  final highHard = (a ?? 0) > .3 && (v ?? 0) < -.2;
  switch (step) {
    case 'meaning':
      return 'what did that bring up in you?';
    case 'need':
      return 'what is one thing you need next — from yourself, someone else, or tonight?';
    default: // 'event'
      return highHard
          ? 'start with what happened — only the part you can name.'
          : 'what happened just before this?';
  }
}

/// JS `dailyPromptOptions(includeGeneric)` — the ritual card's prompt pool.
/// [aiCachedPrompt] mirrors `window._aiCachedPrompt` (prepended when known).
List<String> dailyPromptOptions(
  AppStore store, {
  bool includeGeneric = true,
  String? aiCachedPrompt,
}) {
  final entries = store.entries;
  final source = entries
      .where((e) => (e.text.isNotEmpty || e.tag.isNotEmpty) && e.isMoodEntry)
      .toList();
  final tags = <String>[];
  for (final e in source) {
    if (e.tag.isNotEmpty && !tags.contains(e.tag)) tags.add(e.tag);
  }
  final tagsRev = tags.reversed.toList();
  final last = source.isNotEmpty ? source.last : null;
  final options = <String>[];
  // Context-aware prompts from the analysis engine (mood + text patterns)
  if (entries.isNotEmpty) {
    options.addAll(PromptEngine(entries).generateContextPrompts());
  }
  // AI-enhanced prompt: prepended when the async fetch has come back
  // (the shell owns the fetch; see MentesanaShell._maybeFetchAiPrompt).
  if (aiCachedPrompt != null &&
      aiCachedPrompt.isNotEmpty &&
      !options.contains(aiCachedPrompt)) {
    options.insert(0, aiCachedPrompt);
  }
  if (tagsRev.isNotEmpty) {
    options.add(
        'You have written about <em>${tagsRev[0]}</em> before. What feels different about it today?');
  }
  if (last != null && last.word != null && last.word!.isNotEmpty) {
    options.add(
        'Last time, you called the weather <em>${last.word}</em>. What has shifted, if anything?');
  }
  if (tagsRev.length > 1) {
    options.add(
        '<em>${tagsRev[1]}</em> has come up before too. Is it still here, in some form?');
  }
  if (!includeGeneric) return options;
  var preferred = List<String>.from(store.onboardingPreferences);
  // Settings prompt-style override takes priority over onboarding preferences
  final settingsStyle = store.promptStyleRaw;
  if (settingsStyle != null) {
    preferred = [settingsStyle, ...preferred.where((p) => p != settingsStyle)];
  }
  const tailored = {
    'question': 'What would you tell a friend who had your day?',
    'free': 'What has been asking for somewhere to land?',
    'naming': 'What is here before you explain or solve it?',
  };
  for (final key in preferred) {
    final t = tailored[key];
    if (t != null && !options.contains(t)) options.add(t);
  }
  options
      .add('What is one small thing from today that you do not want to lose?');
  options.add('What would you tell a friend who had your day?');
  options.add('What is still sitting with you, unfinished?');
  // JS `Array.from(new Set(options))` — dedupe, keep first occurrence.
  final seen = <String>{};
  return options.where(seen.add).toList();
}

/// JS `PROMPT_LIBRARY` — the fixed categories. 'looking back' is appended
/// at render time from `dailyPromptOptions(includeGeneric: false)`.
const kPromptLibrary = <String, List<String>>{
  'to begin': [
    "What is one thing from today you don't want to lose?",
    'What would you write if no one were going to read it?',
    'Start with the first sentence that comes, even if it feels wrong.',
    'If today needed a title, what would it be?',
    'What is the truest thing you could say about right now?',
  ],
  "when it's hard to start": kStuckPrompts,
  "naming what's here": [
    'What word would you give to this, if you had to choose just one?',
    'Where do you notice it in your body?',
    'Does this feel familiar, or new?',
    'What is underneath this, if anything?',
    'What would it feel like to let this be, just for a page?',
  ],
  'the day, up close': [
    "What did you see today that you'd like to remember?",
    "What's a sound, smell, or texture that stayed with you?",
    'Who did you talk to — what do you remember them saying?',
    "What's the smallest true thing you can say about today?",
  ],
};

/// JS `journalGreeting()` — 'Good evening, Alessandro.'
String journalGreeting(AppStore store) {
  final name = store.profileName.isNotEmpty ? store.profileName : 'Alessandro';
  final h = DateTime.now().hour;
  final key = h < 5
      ? 'greetingNight'
      : h < 12
          ? 'greetingMorning'
          : h < 18
              ? 'greetingAfternoon'
              : 'greetingEvening';
  return '${store.t(key)}, $name.';
}

/// JS `distanceText()` — the same page, retold as if a friend wrote it.
String distanceText(String text) {
  return text
      .replaceAll(RegExp("\\bI['\u2019]m\\b"), 'they are')
      .replaceAll(RegExp("\\bI['\u2019]ve\\b"), 'they have')
      .replaceAll(RegExp("\\bI['\u2019]ll\\b"), 'they will')
      .replaceAll(RegExp("\\bI['\u2019]d\\b"), 'they would')
      .replaceAll(RegExp(r'\bI am\b'), 'they are')
      .replaceAll(RegExp(r'\bI was\b'), 'they were')
      .replaceAll(RegExp(r'\bI have\b'), 'they have')
      .replaceAll(RegExp(r'\bI had\b'), 'they had')
      .replaceAll(RegExp(r'\bI\b'), 'they')
      .replaceAll(RegExp(r'\bme\b'), 'them')
      .replaceAll(RegExp(r'\bMe\b'), 'Them')
      .replaceAll(RegExp(r'\bmy\b'), 'their')
      .replaceAll(RegExp(r'\bMy\b'), 'Their')
      .replaceAll(RegExp(r'\bmine\b'), 'theirs')
      .replaceAll(RegExp(r'\bmyself\b'), 'themself');
}

/// JS `jSafety` trigger — now delegates to the canonical, broadened crisis
/// detector in analysis_engine so every surface screens identically.
final kSafetyRe = kCrisisRe;

/// The safety line itself (index.html #jSafety, rendered without markup).
const kSafetyText =
    'If you might be in danger right now, this page can wait — please reach for a person. Call your local emergency number, Samaritans 116 123 (UK & Ireland), or 988 (US) — free, any hour.';

/// JS date formats used across journal surfaces.
const kDowsShort = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
const kDowsLong = [
  'sunday',
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday'
];
const kMonthsShort = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec'
];
const kMonthsLong = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december'
];

/// en-GB `weekday, day month` lowercase — e.g. 'thursday, 16 july'.
String jDateLine(DateTime dt) =>
    '${kDowsLong[dt.weekday % 7]}, ${dt.day} ${kMonthsLong[dt.month - 1]}';

/// `HH:mm` (24h), as the journal header shows next to the date.
String hhmm(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

/// en-GB `d mmm` lowercase — e.g. '16 jul'.
String dMmm(DateTime dt) => '${dt.day} ${kMonthsShort[dt.month - 1]}';
