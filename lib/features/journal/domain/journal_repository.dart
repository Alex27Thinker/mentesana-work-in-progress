import '../../journal/domain/models.dart';

abstract class JournalRepository {
  List<JournalEntry> get entries;
  set entries(List<JournalEntry> entries);

  JournalEntry? findByTs(int ts);
  void addEntry(JournalEntry entry);
  void updateEntry(JournalEntry oldEntry, JournalEntry newEntry);
  void deleteEntry(JournalEntry entry);
  void replaceAll(List<JournalEntry> newEntries);
  void saveEntries();

  int? get moodTintTs;
  set moodTintTs(int? value);

  List<String> get shownInsightLines;
  set shownInsightLines(List<String> value);

  Set<int> get syntheticEntryTimestamps;
  bool get hasSyntheticData;
  void markEntrySynthetic(int ts);
  void clearSyntheticTimestamps();
}
