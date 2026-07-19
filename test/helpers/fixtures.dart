import 'package:mentesana_mood_selector/app_store.dart';

JournalEntry fixtureEntry({
  int ts = 1000000,
  double? v = 0.3,
  double? a = -0.2,
  String? word = 'calm',
  String text = 'A test journal entry.',
  String tag = 'work',
  String title = 'Test Entry',
  bool edited = false,
  List<Attachment>? attachments,
  List<EntryVersion>? versions,
}) {
  return JournalEntry(
    ts: ts,
    v: v,
    a: a,
    word: word,
    text: text,
    tag: tag,
    title: title,
    edited: edited,
    attachments: attachments,
    versions: versions,
  );
}

JournalEntry fixtureMoodEntry({
  int ts = 2000000,
  double v = 0.5,
  double a = -0.3,
  String word = 'hopeful',
  int? moodTs,
}) {
  return JournalEntry(
    ts: ts,
    v: v,
    a: a,
    word: word,
    text: '',
    moodTs: moodTs ?? ts,
  );
}

final List<JournalEntry> fixtureDemoDays = demoDays();

JournalDraft fixtureDraft({
  String text = 'Draft text',
  int ts = 3000000,
  String mode = 'free',
}) {
  return JournalDraft(
    text: text,
    ts: ts,
    mode: mode,
  );
}

TideExperiment fixtureExperiment({
  String id = 'exp-1',
  String title = 'Morning Walk',
  String action = 'walk for 10 minutes',
  int startedAt = 1000000,
}) {
  return TideExperiment(
    id: id,
    title: title,
    hypothesis: 'Morning walks may help start the day more calmly.',
    action: action,
    theme: 'daily life',
    startedAt: startedAt,
  );
}

Attachment fixtureAttachment({
  String name = 'photo.jpg',
  String type = 'image/jpeg',
  int size = 1024,
  String data = 'base64data',
}) {
  return Attachment(
    name: name,
    type: type,
    size: size,
    data: data,
  );
}

Map<String, dynamic> fixtureEntryJson({
  int ts = 1000000,
  double? v = 0.3,
  double? a = -0.2,
  String text = 'Test entry.',
}) {
  return {
    'ts': ts,
    if (v != null) 'v': v,
    if (a != null) 'a': a,
    'word': 'calm',
    'text': text,
  };
}
