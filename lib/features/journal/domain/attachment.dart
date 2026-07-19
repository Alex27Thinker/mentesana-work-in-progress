class Attachment {
  const Attachment({
    required this.name,
    required this.type,
    this.size = 0,
    this.data = '',
  });

  final String name;
  final String type;
  final int size;
  final String data;

  bool get isImage => type.startsWith('image/');
  bool get isAudio => type.startsWith('audio/');

  /// All fields are non-nullable, so ordinary typed copy semantics apply.
  Attachment copyWith({
    String? name,
    String? type,
    int? size,
    String? data,
  }) =>
      Attachment(
        name: name ?? this.name,
        type: type ?? this.type,
        size: size ?? this.size,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'size': size,
        'data': data,
      };

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
