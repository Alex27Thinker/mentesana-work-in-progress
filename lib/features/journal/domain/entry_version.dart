class EntryVersion {
  const EntryVersion({
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

  EntryVersion copyWith({
    int? editedAt,
    String? text,
    String? title,
    String? tag,
    String? tideLine,
  }) =>
      EntryVersion(
        editedAt: editedAt ?? this.editedAt,
        text: text ?? this.text,
        title: title ?? this.title,
        tag: tag ?? this.tag,
        tideLine: tideLine ?? this.tideLine,
      );

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
