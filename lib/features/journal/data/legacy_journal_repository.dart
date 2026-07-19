import 'dart:async';

import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/features/journal/domain/journal_repository.dart';

/// In-memory adapter backed by the existing [AppStore].
///
/// The adapter:
///   * exposes immutable [List] snapshots — never the AppStore's own
///     mutable list;
///   * uses [_entriesStream] to push change notifications to callers
///     that observe the journal;
///   * enforces the missing-entry and timestamp-identity policies
///     defined by [JournalRepository].
///
/// It does not write to SharedPreferences directly; persistence is
/// delegated to [AppStore] which is the single writer.
class LegacyJournalRepository implements JournalRepository {
  LegacyJournalRepository(this._store) {
    _store.addListener(_emit);
  }

  final AppStore _store;
  final StreamController<List<JournalEntry>> _controller =
      StreamController<List<JournalEntry>>.broadcast();
  List<JournalEntry>? _lastEmitted;

  void _emit() {
    final next = List<JournalEntry>.unmodifiable(_store.entries);
    if (_lastEmitted != null && _listEquals(_lastEmitted!, next)) return;
    _lastEmitted = next;
    _controller.add(next);
  }

  bool _listEquals(List<JournalEntry> a, List<JournalEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }

  @override
  Future<List<JournalEntry>> getEntries() async =>
      List<JournalEntry>.unmodifiable(_store.entries);

  @override
  Stream<List<JournalEntry>> watchEntries() async* {
    yield List<JournalEntry>.unmodifiable(_store.entries);
    yield* _controller.stream;
  }

  @override
  Future<JournalEntry?> findByTs(int ts) async => _store.findByTs(ts);

  @override
  Future<void> add(JournalEntry entry) async {
    if (_store.entries.any((e) => e.ts == entry.ts)) {
      throw StateError('add: duplicate ts ${entry.ts}');
    }
    _store.addEntry(entry);
  }

  @override
  Future<void> update(JournalEntry entry) async {
    final current = _store.findByTs(entry.ts);
    if (current == null) {
      throw StateError('update: no entry with ts=${entry.ts}');
    }
    _store.updateEntry(current, entry);
  }

  @override
  Future<void> deleteByTs(int ts) async {
    final current = _store.findByTs(ts);
    if (current == null) return; // already gone, silent success
    _store.deleteEntry(current);
  }

  @override
  Future<void> replaceAll(List<JournalEntry> entries) async {
    final tsList = entries.map((e) => e.ts).toList();
    if (tsList.toSet().length != tsList.length) {
      throw ArgumentError('replaceAll: duplicate timestamps');
    }
    _store.entries = List<JournalEntry>.unmodifiable(entries);
    _store.saveEntries();
  }

  Future<void> dispose() async {
    _store.removeListener(_emit);
    await _controller.close();
  }
}
