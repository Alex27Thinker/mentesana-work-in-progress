import 'dart:async';

import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/features/journal/domain/currents_repository.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';

/// In-memory adapter backed by [AppStore] for the three currents
/// collections. Snapshots returned to callers are always unmodifiable
/// views. Persistence is delegated to [AppStore] focused operations,
/// so this adapter does not write to SharedPreferences directly and
/// does not need a generic notification escape hatch.
class LegacyCurrentsRepository implements CurrentsRepository {
  LegacyCurrentsRepository(this._store) {
    _store.addListener(_emit);
  }

  final AppStore _store;
  final StreamController<List<TideExperiment>> _experimentsController =
      StreamController<List<TideExperiment>>.broadcast();
  final StreamController<List<ParkedWorry>> _worriesController =
      StreamController<List<ParkedWorry>>.broadcast();
  final StreamController<List<Anchor>> _anchorsController =
      StreamController<List<Anchor>>.broadcast();

  void _emit() {
    _experimentsController
        .add(List<TideExperiment>.unmodifiable(_store.tideExperiments));
    _worriesController
        .add(List<ParkedWorry>.unmodifiable(_store.parkedWorries));
    _anchorsController.add(List<Anchor>.unmodifiable(_store.anchors));
  }

  @override
  Future<List<TideExperiment>> getExperiments() async =>
      List<TideExperiment>.unmodifiable(_store.tideExperiments);

  @override
  Stream<List<TideExperiment>> watchExperiments() async* {
    yield List<TideExperiment>.unmodifiable(_store.tideExperiments);
    yield* _experimentsController.stream;
  }

  @override
  TideExperiment? activeExperiment() => _store.activeTideExperiment;

  @override
  Future<void> startExperiment(TideExperiment experiment) async =>
      _store.startTideExperiment(experiment);

  @override
  Future<void> completeExperiment(String experimentId) async =>
      _store.completeTideExperiment(experimentId);

  @override
  Future<void> recordObservation(String experimentId, String response) async =>
      _store.recordTideObservation(experimentId, response);

  @override
  Future<List<ParkedWorry>> getParkedWorries() async =>
      List<ParkedWorry>.unmodifiable(_store.parkedWorries);

  @override
  Stream<List<ParkedWorry>> watchParkedWorries() async* {
    yield List<ParkedWorry>.unmodifiable(_store.parkedWorries);
    yield* _worriesController.stream;
  }

  @override
  List<ParkedWorry> dueParkedWorries() => _store.dueParkedWorries;

  @override
  Future<void> parkWorry(String text) async => _store.parkWorry(text);

  @override
  Future<void> settleWorry(ParkedWorry worry) async =>
      _store.settleWorry(worry);

  @override
  Future<List<Anchor>> getAnchors() async =>
      List<Anchor>.unmodifiable(_store.anchors);

  @override
  Stream<List<Anchor>> watchAnchors() async* {
    yield List<Anchor>.unmodifiable(_store.anchors);
    yield* _anchorsController.stream;
  }

  @override
  Anchor? openAnchor() => _store.openAnchor;

  @override
  Future<void> setAnchor({required String text, required String theme}) async =>
      _store.setAnchor(text: text, theme: theme);

  @override
  Future<void> reflectAnchor(Anchor anchor, String outcome) async =>
      _store.reflectAnchor(anchor, outcome);

  @override
  Future<void> quietAnchorInvites({int days = 3}) async =>
      _store.quietAnchorInvites(days: days);

  void dispose() {
    _store.removeListener(_emit);
    _experimentsController.close();
    _worriesController.close();
    _anchorsController.close();
  }
}
