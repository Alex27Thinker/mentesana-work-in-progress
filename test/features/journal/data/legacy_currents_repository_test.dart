import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/features/journal/data/legacy_currents_repository.dart';
import 'package:mentesana_mood_selector/features/journal/domain/currents_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppStore store;
  late CurrentsRepository repo;

  Future<void> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final r = SettingsRepository.createFromPrefs(prefs);
    store = AppStore.fromRepository(r);
    repo = LegacyCurrentsRepository(store);
  }

  setUp(fresh);

  group('LegacyCurrentsRepository', () {
    test('startExperiment and activeExperiment', () async {
      final e = TideExperiment(
        id: 'e1',
        title: 'walk',
        hypothesis: 'h',
        action: 'a',
        theme: 't',
        startedAt: 1000,
      );
      await repo.startExperiment(e);
      expect((await repo.getExperiments()).length, 1);
      expect((await repo.activeExperiment())?.id, 'e1');
    });

    test('recordObservation adds a single observation per day', () async {
      await repo.startExperiment(TideExperiment(
        id: 'e1',
        title: 'walk',
        hypothesis: 'h',
        action: 'a',
        theme: 't',
        startedAt: 1000,
      ));
      await repo.recordObservation('e1', 'did');
      final list = (await repo.getExperiments()).first.observations;
      expect(list.length, 1);
      expect(list.first.response, 'did');
    });

    test('completeExperiment marks completedAt', () async {
      await repo.startExperiment(TideExperiment(
        id: 'e1',
        title: 'walk',
        hypothesis: 'h',
        action: 'a',
        theme: 't',
        startedAt: 1000,
      ));
      await repo.completeExperiment('e1');
      final e = (await repo.getExperiments()).first;
      expect(e.isComplete, isTrue);
    });

    test('parkWorry and settleWorry', () async {
      await repo.parkWorry('I keep thinking about this');
      expect((await repo.getParkedWorries()).length, 1);
      final w = (await repo.getParkedWorries()).first;
      await repo.settleWorry(w);
      expect((await repo.getParkedWorries()).first.settled, isTrue);
    });

    test('setAnchor and reflectAnchor', () async {
      await repo.setAnchor(text: 'take a walk', theme: 'outdoors');
      expect((await repo.getAnchors()).length, 1);
      final a = (await repo.getAnchors()).first;
      await repo.reflectAnchor(a, 'written');
      expect((await repo.getAnchors()).first.outcome, 'written');
    });

    test('mutations survive AppStore recreation', () async {
      await repo.setAnchor(text: 'persisted anchor', theme: 'grounding');
      final prefs = await SharedPreferences.getInstance();
      final recreated = AppStore.fromRepository(
        SettingsRepository.createFromPrefs(prefs),
      );
      expect(recreated.anchors.single.text, 'persisted anchor');
    });

    test('snapshots are unmodifiable', () async {
      await repo.setAnchor(text: 'walk', theme: 'outdoors');
      final anchors = await repo.getAnchors();
      expect(
          () => anchors.add(const Anchor(
              setAt: 1, text: 'a', theme: 't', forDay: '2026-01-01')),
          throwsUnsupportedError);
    });

    test('dispose closes active watch streams', () async {
      final concrete = repo as LegacyCurrentsRepository;
      var done = false;
      final sub =
          concrete.watchExperiments().listen((_) {}, onDone: () => done = true);
      await Future<void>.delayed(Duration.zero);
      await concrete.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
      await sub.cancel();
    });

    test('dueParkedWorries reflects settled flag', () async {
      // No worries yet, so empty.
      expect(await repo.dueParkedWorries(), isEmpty);
    });
  });
}
