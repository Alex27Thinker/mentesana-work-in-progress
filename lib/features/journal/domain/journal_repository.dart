import 'models.dart';

/// Persistence boundary for journal entries.
///
/// The interface is asynchronous so a future Drift implementation can
/// use background executors and stream-based observation. The legacy
/// adapter preserves existing behavior and may call into the
/// in-memory store synchronously before completing the future.
///
/// Deferred boundaries that are NOT part of this repository:
///   * moodTintTs — session/atmosphere metadata, not journal persistence;
///   * shownInsightLines — insight-history persistence;
///   * syntheticEntryTimestamps — debug/test seeding.
abstract interface class JournalRepository {
  /// Snapshot of all entries, oldest first. Returned list is unmodifiable
  /// to the caller.
  Future<List<JournalEntry>> getEntries();

  /// Stream of all entries, oldest first. Re-emits on mutation. Used by
  /// widgets and controllers that need live observation.
  Stream<List<JournalEntry>> watchEntries();

  /// Look up an entry by its stable timestamp identity.
  Future<JournalEntry?> findByTs(int ts);

  /// Insert a new entry. The supplied entry's timestamp is the stable
  /// identity. Throws [StateError] if an entry with the same `ts` already
  /// exists.
  Future<void> add(JournalEntry entry);

  /// Replace the entry with matching `ts`. The supplied entry's timestamp
  /// is the stable identity. Throws [StateError] if no entry with the
  /// supplied `ts` exists, or if the entry's `ts` was changed.
  Future<void> update(JournalEntry entry);

  /// Remove the entry with matching `ts`. Throws [StateError] if no
  /// entry exists. Returns silently if the entry has already been
  /// removed.
  Future<void> deleteByTs(int ts);

  /// Replace every entry with [entries]. The supplied list must contain
  /// unique timestamps. Used by import flows.
  Future<void> replaceAll(List<JournalEntry> entries);
}
