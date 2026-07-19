import 'dart:convert';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';
import 'package:mentesana_mood_selector/features/journal/domain/currents_repository.dart';

class LegacyCurrentsRepository implements CurrentsRepository {
  final AppStore _store;
  final SettingsRepository _repo;

  LegacyCurrentsRepository(this._store, this._repo);

  @override
  List<TideExperiment> get tideExperiments => _store.tideExperiments;

  @override
  set tideExperiments(List<TideExperiment> v) => _store.tideExperiments = v;

  @override
  List<ParkedWorry> get parkedWorries => _store.parkedWorries;

  @override
  set parkedWorries(List<ParkedWorry> v) => _store.parkedWorries = v;

  @override
  List<Anchor> get anchors => _store.anchors;

  @override
  set anchors(List<Anchor> v) => _store.anchors = v;

  @override
  TideExperiment? get activeTideExperiment => _store.activeTideExperiment;

  @override
  void startExperiment(TideExperiment experiment) =>
      _store.startTideExperiment(experiment);

  @override
  void completeExperiment(String id) => _store.completeTideExperiment(id);

  @override
  void recordObservation(String id, String response) =>
      _store.recordTideObservation(id, response);

  @override
  void parkWorry(String text) => _store.parkWorry(text);

  @override
  void settleWorry(ParkedWorry worry) => _store.settleWorry(worry);

  @override
  List<ParkedWorry> get dueParkedWorries => _store.dueParkedWorries;

  @override
  void setAnchor({required String text, required String theme}) =>
      _store.setAnchor(text: text, theme: theme);

  @override
  void reflectAnchor(Anchor anchor, String outcome) =>
      _store.reflectAnchor(anchor, outcome);

  @override
  Anchor? get openAnchor => _store.openAnchor;

  @override
  void quietAnchorInvites({int days = 3}) =>
      _store.quietAnchorInvites(days: days);

  @override
  void saveParkedWorries() {
    _repo.parkedWorriesJson =
        jsonEncode(parkedWorries.map((w) => w.toJson()).toList());
    _store.notify();
  }

  @override
  void saveAnchors() {
    _repo.anchorsJson = jsonEncode(anchors.map((a) => a.toJson()).toList());
    _store.notify();
  }

  @override
  void saveTideExperiments() {
    _repo.tideExperimentsJson =
        jsonEncode(tideExperiments.map((e) => e.toJson()).toList());
    _store.notify();
  }
}
