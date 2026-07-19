import '_copy_with_helpers.dart';

class Anchor {
  const Anchor({
    required this.setAt,
    required this.text,
    required this.theme,
    required this.forDay,
    this.reflectedAt,
    this.outcome = '',
  });

  final int setAt;
  final String text;
  final String theme;
  final String forDay;
  final int? reflectedAt;
  final String outcome;

  bool get isOpen => reflectedAt == null;

  /// [reflectedAt] is nullable. Sentinel semantics let callers:
  ///   * omit the argument → preserve current value;
  ///   * pass `null`        → explicitly clear the reflection time;
  ///   * pass a timestamp  → set the reflection time.
  Anchor copyWith({
    int? setAt,
    String? text,
    String? theme,
    String? forDay,
    Object? reflectedAt = unset,
    String? outcome,
  }) =>
      Anchor(
        setAt: setAt ?? this.setAt,
        text: text ?? this.text,
        theme: theme ?? this.theme,
        forDay: forDay ?? this.forDay,
        reflectedAt:
            isUnset(reflectedAt) ? this.reflectedAt : reflectedAt as int?,
        outcome: outcome ?? this.outcome,
      );

  static Anchor? fromJson(dynamic j) {
    if (j is! Map) return null;
    final setAt = j['setAt'], text = j['text'], forDay = j['forDay'];
    if (setAt is! int || text is! String || forDay is! String) return null;
    return Anchor(
      setAt: setAt,
      text: text,
      theme: j['theme'] is String ? j['theme'] as String : '',
      forDay: forDay,
      reflectedAt: j['reflectedAt'] is int ? j['reflectedAt'] as int : null,
      outcome: j['outcome'] is String ? j['outcome'] as String : '',
    );
  }

  Map<String, dynamic> toJson() => {
        'setAt': setAt,
        'text': text,
        'theme': theme,
        'forDay': forDay,
        if (reflectedAt != null) 'reflectedAt': reflectedAt,
        'outcome': outcome,
      };
}
