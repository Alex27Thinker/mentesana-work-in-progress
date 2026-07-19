class TideObservation {
  const TideObservation({
    required this.ts,
    required this.response,
  });

  final int ts;
  final String response;

  TideObservation copyWith({
    int? ts,
    String? response,
  }) =>
      TideObservation(
        ts: ts ?? this.ts,
        response: response ?? this.response,
      );

  Map<String, dynamic> toJson() => {'ts': ts, 'response': response};

  static TideObservation? fromJson(dynamic raw) {
    if (raw is! Map || raw['ts'] is! num) return null;
    var response = (raw['response'] ?? '').toString();
    const legacy = {
      'paired': 'did',
      'lower': 'did',
      'same': 'did',
      'higher': 'did',
    };
    response = legacy[response] ?? response;
    if (!const {'did', 'not', 'skipped'}.contains(response)) return null;
    return TideObservation(ts: (raw['ts'] as num).toInt(), response: response);
  }
}
