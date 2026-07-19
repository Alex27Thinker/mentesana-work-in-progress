import '../../journal/domain/tide_experiment.dart';
import '../../journal/domain/parked_worry.dart';
import '../../journal/domain/anchor.dart';

abstract class CurrentsRepository {
  List<TideExperiment> get tideExperiments;
  set tideExperiments(List<TideExperiment> v);
  List<ParkedWorry> get parkedWorries;
  set parkedWorries(List<ParkedWorry> v);
  List<Anchor> get anchors;
  set anchors(List<Anchor> v);

  TideExperiment? get activeTideExperiment;
  void startExperiment(TideExperiment experiment);
  void completeExperiment(String experimentId);
  void recordObservation(String experimentId, String response);

  void parkWorry(String text);
  void settleWorry(ParkedWorry worry);
  List<ParkedWorry> get dueParkedWorries;

  void setAnchor({required String text, required String theme});
  void reflectAnchor(Anchor anchor, String outcome);
  Anchor? get openAnchor;
  void quietAnchorInvites({int days = 3});

  void saveParkedWorries();
  void saveAnchors();
  void saveTideExperiments();
}
