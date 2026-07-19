import 'tide_observation.dart';

class TideExperiment {
  const TideExperiment({
    required this.id,
    required this.title,
    required this.hypothesis,
    required this.action,
    required this.theme,
    required this.startedAt,
    this.durationDays = 7,
    final List<int>? evidenceTs,
    final List<TideObservation>? observations,
    this.completedAt,
  })  : evidenceTs = evidenceTs ?? const [],
        observations = observations ?? const [];

  final String id;
  final String title;
  final String hypothesis;
  final String action;
  final String theme;
  final int startedAt;
  final int durationDays;
  final List<int> evidenceTs;
  final List<TideObservation> observations;
  final int? completedAt;

  bool get isComplete => completedAt != null;

  TideExperiment copyWith({
    String? id,
    String? title,
    String? hypothesis,
    String? action,
    String? theme,
    int? startedAt,
    int? durationDays,
    List<int>? evidenceTs,
    List<TideObservation>? observations,
    int? completedAt,
  }) =>
      TideExperiment(
        id: id ?? this.id,
        title: title ?? this.title,
        hypothesis: hypothesis ?? this.hypothesis,
        action: action ?? this.action,
        theme: theme ?? this.theme,
        startedAt: startedAt ?? this.startedAt,
        durationDays: durationDays ?? this.durationDays,
        evidenceTs: evidenceTs ?? this.evidenceTs,
        observations: observations ?? this.observations,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hypothesis': hypothesis,
        'action': action,
        'theme': theme,
        'startedAt': startedAt,
        'durationDays': durationDays,
        'evidenceTs': evidenceTs,
        'observations': observations.map((o) => o.toJson()).toList(),
        if (completedAt != null) 'completedAt': completedAt,
      };

  static TideExperiment? fromJson(dynamic raw) {
    if (raw is! Map || raw['startedAt'] is! num) return null;
    final id = (raw['id'] ?? '').toString();
    if (id.isEmpty) return null;
    return TideExperiment(
      id: id,
      title: (raw['title'] ?? 'a small experiment').toString(),
      hypothesis: (raw['hypothesis'] ?? '').toString(),
      action: (raw['action'] ?? '').toString(),
      theme: (raw['theme'] ?? 'daily life').toString(),
      startedAt: (raw['startedAt'] as num).toInt(),
      durationDays: raw['durationDays'] is num
          ? (raw['durationDays'] as num).toInt().clamp(3, 21).toInt()
          : 7,
      evidenceTs: raw['evidenceTs'] is List
          ? (raw['evidenceTs'] as List)
              .whereType<num>()
              .map((x) => x.toInt())
              .toList()
          : null,
      observations: raw['observations'] is List
          ? (raw['observations'] as List)
              .map(TideObservation.fromJson)
              .whereType<TideObservation>()
              .toList()
          : null,
      completedAt: raw['completedAt'] is num
          ? (raw['completedAt'] as num).toInt()
          : null,
    );
  }
}
