import '_copy_with_helpers.dart';

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

  /// [size] and [data] are non-nullable. They follow standard
  /// "omitted → preserve" semantics; the sentinel is only needed where
  /// the caller may want to clear a value explicitly.
  Attachment copyWith({
    Object? name = unset,
    Object? type = unset,
    int? size,
    String? data,
  }) =>
      Attachment(
        name: isUnset(name) ? this.name : name! as String,
        type: isUnset(type) ? this.type : type! as String,
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
