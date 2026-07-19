import '_copy_with_helpers.dart';
import 'tide_observation.dart';

class TideExperiment {
  static const List<int> _emptyEvidence = <int>[];
  static const List<TideObservation> _emptyObservations = <TideObservation>[];

  TideExperiment({
    required this.id,
    required this.title,
    required this.hypothesis,
    required this.action,
    required this.theme,
    required this.startedAt,
    this.durationDays = 7,
    List<int>? evidenceTs,
    List<TideObservation>? observations,
    this.completedAt,
  })  : evidenceTs = evidenceTs == null
            ? _emptyEvidence
            : List<int>.unmodifiable(evidenceTs),
        observations = observations == null
            ? _emptyObservations
            : List<TideObservation>.unmodifiable(observations);

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

  /// Sentinel-based copyWith so [completedAt] can be explicitly cleared.
  /// List arguments are defensively copied to keep this model immutable.
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
    Object? completedAt = unset,
  }) =>
      TideExperiment(
        id: id ?? this.id,
        title: title ?? this.title,
        hypothesis: hypothesis ?? this.hypothesis,
        action: action ?? this.action,
        theme: theme ?? this.theme,
        startedAt: startedAt ?? this.startedAt,
        durationDays: durationDays ?? this.durationDays,
        evidenceTs: evidenceTs == null
            ? this.evidenceTs
            : List<int>.unmodifiable(evidenceTs),
        observations: observations == null
            ? this.observations
            : List<TideObservation>.unmodifiable(observations),
        completedAt:
            isUnset(completedAt) ? this.completedAt : completedAt as int?,
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
