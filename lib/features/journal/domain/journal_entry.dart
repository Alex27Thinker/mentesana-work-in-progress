import '_copy_with_helpers.dart';
import 'attachment.dart';
import 'entry_version.dart';

class JournalEntry {
  static const List<Attachment> _emptyAttachments = <Attachment>[];
  static const List<EntryVersion> _emptyVersions = <EntryVersion>[];

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
  })  : attachments = attachments == null
            ? _emptyAttachments
            : List<Attachment>.unmodifiable(attachments),
        versions = versions == null
            ? _emptyVersions
            : List<EntryVersion>.unmodifiable(versions);

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

  /// Nullable fields use the sentinel:
  ///   * omit   → preserve;
  ///   * null   → clear;
  ///   * value  → replace.
  /// List fields are defensively copied via [List.unmodifiable].
  JournalEntry copyWith({
    int? ts,
    Object? v = unset,
    Object? a = unset,
    Object? word = unset,
    bool? edited,
    String? text,
    String? tag,
    String? title,
    String? prompt,
    Object? wordCount = unset,
    List<Attachment>? attachments,
    String? tideLine,
    Object? tideAt = unset,
    Object? moodTs = unset,
    String? texture,
    String? reflectionStep,
    Object? afterV = unset,
    Object? afterA = unset,
    Object? afterWord = unset,
    Object? afterTs = unset,
    List<EntryVersion>? versions,
    bool? pendingTranscription,
    Object? pendingAudioPath = unset,
  }) =>
      JournalEntry(
        ts: ts ?? this.ts,
        v: isUnset(v) ? this.v : v as double?,
        a: isUnset(a) ? this.a : a as double?,
        word: isUnset(word) ? this.word : word as String?,
        edited: edited ?? this.edited,
        text: text ?? this.text,
        tag: tag ?? this.tag,
        title: title ?? this.title,
        prompt: prompt ?? this.prompt,
        wordCount: isUnset(wordCount) ? this.wordCount : wordCount as int?,
        attachments: attachments == null
            ? this.attachments
            : List<Attachment>.unmodifiable(attachments),
        tideLine: tideLine ?? this.tideLine,
        tideAt: isUnset(tideAt) ? this.tideAt : tideAt as int?,
        moodTs: isUnset(moodTs) ? this.moodTs : moodTs as int?,
        texture: texture ?? this.texture,
        reflectionStep: reflectionStep ?? this.reflectionStep,
        afterV: isUnset(afterV) ? this.afterV : afterV as double?,
        afterA: isUnset(afterA) ? this.afterA : afterA as double?,
        afterWord: isUnset(afterWord) ? this.afterWord : afterWord as String?,
        afterTs: isUnset(afterTs) ? this.afterTs : afterTs as int?,
        versions: versions == null
            ? this.versions
            : List<EntryVersion>.unmodifiable(versions),
        pendingTranscription: pendingTranscription ?? this.pendingTranscription,
        pendingAudioPath: isUnset(pendingAudioPath)
            ? this.pendingAudioPath
            : pendingAudioPath as String?,
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
