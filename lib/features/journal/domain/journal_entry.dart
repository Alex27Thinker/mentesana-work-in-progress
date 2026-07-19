import 'attachment.dart';
import 'entry_version.dart';

class JournalEntry {
  const JournalEntry({
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
    final List<Attachment>? attachments,
    this.tideLine = '',
    this.tideAt,
    this.moodTs,
    this.texture = '',
    this.reflectionStep = '',
    this.afterV,
    this.afterA,
    this.afterWord,
    this.afterTs,
    final List<EntryVersion>? versions,
    this.pendingTranscription = false,
    this.pendingAudioPath,
  })  : attachments = attachments ?? const [],
        versions = versions ?? const [];

  final int ts;
  final double? v;
  final double? a;
  final String? word;
  final bool edited;
  final String text;
  final String tag;
  final String title;
  final String prompt;
  final int? wordCount;
  final List<Attachment> attachments;
  final String tideLine;
  final int? tideAt;
  final int? moodTs;
  final String texture;
  final String reflectionStep;
  final double? afterV;
  final double? afterA;
  final String? afterWord;
  final int? afterTs;
  final List<EntryVersion> versions;
  final bool pendingTranscription;
  final String? pendingAudioPath;

  bool get isMoodEntry =>
      v != null &&
      a != null &&
      word != null &&
      word!.isNotEmpty &&
      word != 'journal';

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(ts);

  JournalEntry copyWith({
    int? ts,
    double? v,
    double? a,
    String? word,
    bool? edited,
    String? text,
    String? tag,
    String? title,
    String? prompt,
    int? wordCount,
    List<Attachment>? attachments,
    String? tideLine,
    int? tideAt,
    int? moodTs,
    String? texture,
    String? reflectionStep,
    double? afterV,
    double? afterA,
    String? afterWord,
    int? afterTs,
    List<EntryVersion>? versions,
    bool? pendingTranscription,
    String? pendingAudioPath,
  }) =>
      JournalEntry(
        ts: ts ?? this.ts,
        v: v ?? this.v,
        a: a ?? this.a,
        word: word ?? this.word,
        edited: edited ?? this.edited,
        text: text ?? this.text,
        tag: tag ?? this.tag,
        title: title ?? this.title,
        prompt: prompt ?? this.prompt,
        wordCount: wordCount ?? this.wordCount,
        attachments: attachments ?? this.attachments,
        tideLine: tideLine ?? this.tideLine,
        tideAt: tideAt ?? this.tideAt,
        moodTs: moodTs ?? this.moodTs,
        texture: texture ?? this.texture,
        reflectionStep: reflectionStep ?? this.reflectionStep,
        afterV: afterV ?? this.afterV,
        afterA: afterA ?? this.afterA,
        afterWord: afterWord ?? this.afterWord,
        afterTs: afterTs ?? this.afterTs,
        versions: versions ?? this.versions,
        pendingTranscription: pendingTranscription ?? this.pendingTranscription,
        pendingAudioPath: pendingAudioPath ?? this.pendingAudioPath,
      );

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
  final joined = words.take(9).join(' ') + (words.length > 9 ? '\u2026' : '');
  return joined.length > 84 ? joined.substring(0, 84) : joined;
}

const kSystemPageTitles = [
  'a page for whatever is here',
  'a page for whatever is here \u2014 no weather required.',
  'a page for whatever is here \u2014 no weather required',
];

bool isSystemPageTitle(String? title) =>
    kSystemPageTitles.contains((title ?? '').trim().toLowerCase());
