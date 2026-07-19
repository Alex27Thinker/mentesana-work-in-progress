import '_copy_with_helpers.dart';
import 'attachment.dart';

class JournalDraft {
  static const List<Attachment> _emptyAttachments = <Attachment>[];

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
  }) : attachments = attachments == null
            ? _emptyAttachments
            : List<Attachment>.unmodifiable(attachments);

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

  /// Nullable fields use the sentinel: omit → preserve, null → clear.
  JournalDraft copyWith({
    String? text,
    String? title,
    String? tag,
    String? bottle,
    String? mode,
    Object? prompt = unset,
    int? ts,
    Object? activeEntryTs = unset,
    List<Attachment>? attachments,
    Object? v = unset,
    Object? a = unset,
    Object? word = unset,
  }) =>
      JournalDraft(
        text: text ?? this.text,
        title: title ?? this.title,
        tag: tag ?? this.tag,
        bottle: bottle ?? this.bottle,
        mode: mode ?? this.mode,
        prompt: isUnset(prompt) ? this.prompt : prompt as String?,
        ts: ts ?? this.ts,
        activeEntryTs:
            isUnset(activeEntryTs) ? this.activeEntryTs : activeEntryTs as int?,
        attachments: attachments == null
            ? this.attachments
            : List<Attachment>.unmodifiable(attachments),
        v: isUnset(v) ? this.v : v as double?,
        a: isUnset(a) ? this.a : a as double?,
        word: isUnset(word) ? this.word : word as String?,
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
