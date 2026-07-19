import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/features/journal/domain/models.dart';

void main() {
  group('JournalEntry collection immutability', () {
    test('constructor defensively copies supplied attachments', () {
      final source = <Attachment>[
        const Attachment(name: 'a.jpg', type: 'image/jpeg', size: 1, data: 'x'),
      ];
      final e = JournalEntry(ts: 1, attachments: source);
      // mutating the source list after construction must not alter the model
      source.add(const Attachment(
          name: 'b.jpg', type: 'image/jpeg', size: 1, data: 'y'));
      expect(e.attachments.length, 1);
    });

    test('constructor defensively copies supplied versions', () {
      final source = <EntryVersion>[
        const EntryVersion(editedAt: 1, text: 'v1', title: 't'),
      ];
      final e = JournalEntry(ts: 1, versions: source);
      source.add(const EntryVersion(editedAt: 2, text: 'v2', title: 't'));
      expect(e.versions.length, 1);
    });

    test('default empty attachments is immutable', () {
      final e = JournalEntry(ts: 1);
      expect(
          () =>
              e.attachments.add(const Attachment(name: 'a', type: 'image/png')),
          throwsUnsupportedError);
    });

    test('default empty versions is immutable', () {
      final e = JournalEntry(ts: 1);
      expect(
          () => e.versions
              .add(const EntryVersion(editedAt: 1, text: 't', title: 't')),
          throwsUnsupportedError);
    });

    test('copyWith defensively copies supplied attachments', () {
      final e = JournalEntry(ts: 1);
      final source = <Attachment>[
        const Attachment(name: 'a.jpg', type: 'image/jpeg', size: 1, data: 'x'),
      ];
      final r = e.copyWith(attachments: source);
      source.add(const Attachment(
          name: 'b.jpg', type: 'image/jpeg', size: 1, data: 'y'));
      expect(r.attachments.length, 1);
    });

    test('copyWith defensively copies supplied versions', () {
      final e = JournalEntry(ts: 1);
      final source = <EntryVersion>[
        const EntryVersion(editedAt: 1, text: 'v1', title: 't'),
      ];
      final r = e.copyWith(versions: source);
      source.add(const EntryVersion(editedAt: 2, text: 'v2', title: 't'));
      expect(r.versions.length, 1);
    });

    test('fromJson creates immutable collections', () {
      final e = JournalEntry.fromJson({
        'ts': 1,
        'attachments': [
          {'name': 'a.jpg', 'type': 'image/jpeg', 'size': 1, 'data': 'x'}
        ],
        'versions': [
          {'editedAt': 1, 'text': 't', 'title': 't'}
        ],
      })!;
      expect(
          () =>
              e.attachments.add(const Attachment(name: 'a', type: 'image/png')),
          throwsUnsupportedError);
      expect(
          () => e.versions
              .add(const EntryVersion(editedAt: 1, text: 't', title: 't')),
          throwsUnsupportedError);
    });
  });

  group('JournalDraft collection immutability', () {
    test('constructor defensively copies supplied attachments', () {
      final source = <Attachment>[
        const Attachment(name: 'a.jpg', type: 'image/jpeg', size: 1, data: 'x'),
      ];
      final d = JournalDraft(ts: 1, attachments: source);
      source.add(const Attachment(
          name: 'b.jpg', type: 'image/jpeg', size: 1, data: 'y'));
      expect(d.attachments.length, 1);
    });

    test('default empty attachments is immutable', () {
      final d = JournalDraft(ts: 1);
      expect(
          () =>
              d.attachments.add(const Attachment(name: 'a', type: 'image/png')),
          throwsUnsupportedError);
    });

    test('fromJson creates immutable attachments', () {
      final d = JournalDraft.fromJson({
        'ts': 1,
        'attachments': [
          {'name': 'a.jpg', 'type': 'image/jpeg', 'size': 1, 'data': 'x'}
        ],
      })!;
      expect(
          () =>
              d.attachments.add(const Attachment(name: 'a', type: 'image/png')),
          throwsUnsupportedError);
    });
  });

  group('TideExperiment collection immutability', () {
    test('constructor defensively copies observations', () {
      final source = <TideObservation>[
        const TideObservation(ts: 1, response: 'did'),
      ];
      final e = TideExperiment(
        id: 'e1',
        title: 't',
        hypothesis: 'h',
        action: 'a',
        theme: 't',
        startedAt: 1,
        observations: source,
      );
      source.add(const TideObservation(ts: 2, response: 'not'));
      expect(e.observations.length, 1);
    });

    test('constructor defensively copies evidenceTs', () {
      final source = <int>[1, 2];
      final e = TideExperiment(
        id: 'e1',
        title: 't',
        hypothesis: 'h',
        action: 'a',
        theme: 't',
        startedAt: 1,
        evidenceTs: source,
      );
      source.add(3);
      expect(e.evidenceTs.length, 2);
    });

    test('default empty observations is immutable', () {
      final e = TideExperiment(
        id: 'e1',
        title: 't',
        hypothesis: 'h',
        action: 'a',
        theme: 't',
        startedAt: 1,
      );
      expect(
          () =>
              e.observations.add(const TideObservation(ts: 1, response: 'did')),
          throwsUnsupportedError);
    });

    test('fromJson creates immutable observations', () {
      final e = TideExperiment.fromJson({
        'id': 'e1',
        'startedAt': 1,
        'observations': [
          {'ts': 1, 'response': 'did'}
        ],
      })!;
      expect(
          () =>
              e.observations.add(const TideObservation(ts: 2, response: 'not')),
          throwsUnsupportedError);
    });
  });
}
