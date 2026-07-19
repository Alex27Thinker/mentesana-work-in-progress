class ParkedWorry {
  const ParkedWorry({
    required this.ts,
    required this.text,
    required this.returnAt,
    this.settled = false,
  });

  final int ts;
  final String text;
  final int returnAt;
  final bool settled;

  ParkedWorry copyWith({
    int? ts,
    String? text,
    int? returnAt,
    bool? settled,
  }) =>
      ParkedWorry(
        ts: ts ?? this.ts,
        text: text ?? this.text,
        returnAt: returnAt ?? this.returnAt,
        settled: settled ?? this.settled,
      );

  static ParkedWorry? fromJson(dynamic j) {
    if (j is! Map) return null;
    final ts = j['ts'], text = j['text'], returnAt = j['returnAt'];
    if (ts is! int || text is! String || returnAt is! int) return null;
    return ParkedWorry(
      ts: ts,
      text: text,
      returnAt: returnAt,
      settled: j['settled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'ts': ts,
        'text': text,
        'returnAt': returnAt,
        'settled': settled,
      };
}
