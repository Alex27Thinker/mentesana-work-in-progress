import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';
import 'package:mentesana_mood_selector/features/journal/domain/journal_repository.dart';

class LegacyJournalRepository implements JournalRepository {
  final AppStore _store;

  LegacyJournalRepository(this._store);

  @override
  List<JournalEntry> get entries => _store.entries;

  @override
  set entries(List<JournalEntry> v) => _store.entries = v;

  @override
  JournalEntry? findByTs(int ts) => _store.findByTs(ts);

  @override
  void addEntry(JournalEntry entry) => _store.addEntry(entry);

  @override
  void updateEntry(JournalEntry oldEntry, JournalEntry newEntry) =>
      _store.updateEntry(oldEntry, newEntry);

  @override
  void deleteEntry(JournalEntry entry) => _store.deleteEntry(entry);

  @override
  void replaceAll(List<JournalEntry> newEntries) {
    _store.entries = newEntries;
    _store.saveEntries();
  }

  @override
  void saveEntries() => _store.saveEntries();

  @override
  int? get moodTintTs => _store.moodTintTs;

  @override
  set moodTintTs(int? v) => _store.moodTintTs = v;

  @override
  List<String> get shownInsightLines => _store.shownInsightLines;

  @override
  set shownInsightLines(List<String> v) => _store.shownInsightLines = v;

  @override
  Set<int> get syntheticEntryTimestamps => _store.syntheticEntryTimestamps;

  @override
  bool get hasSyntheticData => _store.hasSyntheticData;

  @override
  void markEntrySynthetic(int ts) => _store.markEntrySynthetic(ts);

  @override
  void clearSyntheticTimestamps() => _store.clearSyntheticTimestamps();
}
