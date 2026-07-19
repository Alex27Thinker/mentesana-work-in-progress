import 'attachment.dart';

class JournalDraft {
  const JournalDraft({
    this.text = '',
    this.title = '',
    this.tag = '',
    this.bottle = '',
    this.mode = 'free',
    this.prompt,
    required this.ts,
    this.activeEntryTs,
    final List<Attachment>? attachments,
    this.v,
    this.a,
    this.word,
  }) : attachments = attachments ?? const [];

  final String text;
  final String title;
  final String tag;
  final String bottle;
  final String mode;
  final String? prompt;
  final int ts;
  final int? activeEntryTs;
  final List<Attachment> attachments;
  final double? v;
  final double? a;
  final String? word;

  JournalDraft copyWith({
    String? text,
    String? title,
    String? tag,
    String? bottle,
    String? mode,
    String? prompt,
    int? ts,
    int? activeEntryTs,
    List<Attachment>? attachments,
    double? v,
    double? a,
    String? word,
  }) =>
      JournalDraft(
        text: text ?? this.text,
        title: title ?? this.title,
        tag: tag ?? this.tag,
        bottle: bottle ?? this.bottle,
        mode: mode ?? this.mode,
        prompt: prompt ?? this.prompt,
        ts: ts ?? this.ts,
        activeEntryTs: activeEntryTs ?? this.activeEntryTs,
        attachments: attachments ?? this.attachments,
        v: v ?? this.v,
        a: a ?? this.a,
        word: word ?? this.word,
      );

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
