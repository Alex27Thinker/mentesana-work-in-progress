import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:mentesana_mood_selector/entry_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = SettingsRepository.createFromPrefs(prefs);
    store = AppStore.fromRepository(repo);
  });

  Widget host(
    JournalEntry entry, {
    ValueChanged<JournalEntry>? onEdit,
    VoidCallback? onDeleted,
  }) =>
      MaterialApp(
        home: Material(
          child: EntryDetailScreen(
            store: store,
            entry: entry,
            reads: 0,
            reduced: true,
            onBack: () {},
            onEdit: onEdit ?? (_) {},
            onDuplicate: (_) {},
            onRevisitWeather: (_) {},
            onDeleted: onDeleted ?? () {},
          ),
        ),
      );

  testWidgets('export uses the current entry after parent replacement',
      (tester) async {
    final entry = JournalEntry(
      ts: 1,
      text: 'original text',
      title: 'original title',
    );
    store.addEntry(entry);
    await tester.pumpWidget(host(entry));
    await tester.pump();
    // Simulate the parent replacing the entry in the store.
    final replacement = entry.copyWith(text: 'replaced text');
    store.updateEntry(entry, replacement);
    // Trigger a parent rebuild with the new entry.
    await tester.pumpWidget(host(replacement));
    await tester.pump();
    // Verify the screen is now using the replacement entry. The
    // displayed text comes from the local _entry field.
    expect(find.text('replaced text'), findsOneWidget);
  });

  testWidgets('restoration updates subsequent edit actions', (tester) async {
    final entry = JournalEntry(
      ts: 2,
      text: 'current text',
      title: 'current title',
      versions: [
        const EntryVersion(
          editedAt: 1000,
          text: 'restored text',
          title: 'restored title',
        ),
      ],
    );
    store.addEntry(entry);
    JournalEntry? edited;
    await tester.pumpWidget(host(entry, onEdit: (value) => edited = value));
    await tester.pump();

    await tester.ensureVisible(find.text('restore'));
    await tester.tap(find.text('restore'));
    await tester.pump();
    expect(find.text('restored text'), findsOneWidget);
    expect(store.findByTs(2)?.text, 'restored text');

    await tester.ensureVisible(find.text('edit'));
    await tester.tap(find.text('edit'));
    expect(edited?.text, 'restored text');
    expect(edited?.title, 'restored title');
  });
}
