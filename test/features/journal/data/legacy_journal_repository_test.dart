import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/features/journal/data/legacy_journal_repository.dart';
import 'package:mentesana_mood_selector/features/journal/domain/journal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppStore store;
  late JournalRepository repo;

  Future<void> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final r = SettingsRepository.createFromPrefs(prefs);
    store = AppStore.fromRepository(r);
    repo = LegacyJournalRepository(store);
  }

  setUp(fresh);

  group('LegacyJournalRepository', () {
    test('getEntries returns an unmodifiable snapshot', () async {
      final entries = await repo.getEntries();
      expect(() => entries.add(JournalEntry(ts: 999)), throwsUnsupportedError);
    });

    test('add() persists a new entry', () async {
      await repo.add(JournalEntry(ts: 1, text: 'first'));
      expect(store.entries.length, 1);
      expect(store.entries.first.text, 'first');
    });

    test('add() rejects duplicate ts', () async {
      await repo.add(JournalEntry(ts: 1, text: 'a'));
      expect(
        () => repo.add(JournalEntry(ts: 1, text: 'b')),
        throwsStateError,
      );
    });

    test('findByTs returns matching entry', () async {
      await repo.add(JournalEntry(ts: 5, text: 'a'));
      final r = await repo.findByTs(5);
      expect(r, isNotNull);
      expect(r!.text, 'a');
    });

    test('update() replaces the entry', () async {
      await repo.add(JournalEntry(ts: 5, text: 'a'));
      final current = await repo.findByTs(5);
      await repo.update(current!.copyWith(text: 'b'));
      expect((await repo.findByTs(5))!.text, 'b');
    });

    test('update() throws on missing entry', () async {
      expect(
        () => repo.update(JournalEntry(ts: 9999, text: 'b')),
        throwsStateError,
      );
    });

    test('deleteByTs removes the entry', () async {
      await repo.add(JournalEntry(ts: 5, text: 'a'));
      await repo.deleteByTs(5);
      expect(await repo.findByTs(5), isNull);
    });

    test('deleteByTs on missing entry is a silent no-op', () async {
      await repo.deleteByTs(9999);
    });

    test('replaceAll replaces every entry', () async {
      await repo.add(JournalEntry(ts: 1, text: 'a'));
      await repo.add(JournalEntry(ts: 2, text: 'b'));
      await repo.replaceAll([JournalEntry(ts: 9, text: 'only')]);
      expect(store.entries.length, 1);
      expect(store.entries.first.text, 'only');
    });

    test('mutations survive AppStore recreation', () async {
      await repo.add(JournalEntry(ts: 42, text: 'persisted'));
      final prefs = await SharedPreferences.getInstance();
      final recreated = AppStore.fromRepository(
        SettingsRepository.createFromPrefs(prefs),
      );
      expect(recreated.findByTs(42)?.text, 'persisted');
    });

    test('replaceAll rejects duplicate timestamps', () async {
      expect(
        () => repo.replaceAll([
          JournalEntry(ts: 1, text: 'a'),
          JournalEntry(ts: 1, text: 'b'),
        ]),
        throwsArgumentError,
      );
    });

    test('dispose closes active watch streams', () async {
      final concrete = repo as LegacyJournalRepository;
      var done = false;
      final sub =
          concrete.watchEntries().listen((_) {}, onDone: () => done = true);
      await Future<void>.delayed(Duration.zero);
      await concrete.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
      await sub.cancel();
    });

    test('watchEntries emits initial snapshot and updates on change', () async {
      final seen = <int>[];
      final sub = repo.watchEntries().listen((entries) {
        seen.add(entries.length);
      });
      await Future<void>.delayed(Duration.zero);
      await repo.add(JournalEntry(ts: 1, text: 'a'));
      await Future<void>.delayed(Duration.zero);
      await repo.add(JournalEntry(ts: 2, text: 'b'));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen.first, 0);
      expect(seen.last, 2);
    });
  });
}
