import 'anchor.dart';
import 'parked_worry.dart';
import 'tide_experiment.dart';

/// Persistence boundary for the currents features (tide experiments,
/// parked worries, anchors).
///
/// The interface is asynchronous. Mutation operations persist and
/// emit through the adapter; no separate `save...` methods are part
/// of the public surface. The legacy adapter delegates to focused
/// AppStore operations that combine persistence and notification.
///
/// Transitional placement: currents is currently stored under the journal
/// feature because the prototype's AppStore owns both concerns. Move this
/// contract to `features/currents/domain` when that feature is extracted.
abstract interface class CurrentsRepository {
  Future<List<TideExperiment>> getExperiments();
  Stream<List<TideExperiment>> watchExperiments();
  Future<TideExperiment?> activeExperiment();
  Future<void> startExperiment(TideExperiment experiment);
  Future<void> completeExperiment(String experimentId);
  Future<void> recordObservation(String experimentId, String response);

  Future<List<ParkedWorry>> getParkedWorries();
  Stream<List<ParkedWorry>> watchParkedWorries();
  Future<List<ParkedWorry>> dueParkedWorries();
  Future<void> parkWorry(String text);
  Future<void> settleWorry(ParkedWorry worry);

  Future<List<Anchor>> getAnchors();
  Stream<List<Anchor>> watchAnchors();
  Future<Anchor?> openAnchor();
  Future<void> setAnchor({required String text, required String theme});
  Future<void> reflectAnchor(Anchor anchor, String outcome);
  Future<void> quietAnchorInvites({int days = 3});
}
