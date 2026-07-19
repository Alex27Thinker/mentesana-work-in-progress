import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/app_store.dart';

void main() {
  group('Attachment', () {
    test('toJson produces correct map', () {
      const a = Attachment(
          name: 'test.jpg', type: 'image/jpeg', size: 1024, data: 'abc123');
      expect(a.toJson(), {
        'name': 'test.jpg',
        'type': 'image/jpeg',
        'size': 1024,
        'data': 'abc123',
      });
    });

    test('fromJson parses valid map', () {
      final result = Attachment.fromJson(
          {'name': 'a.jpg', 'type': 'image/png', 'size': 2048, 'data': 'xyz'});
      expect(result, isNotNull);
      expect(result!.name, 'a.jpg');
      expect(result.type, 'image/png');
      expect(result.size, 2048);
      expect(result.data, 'xyz');
    });

    test('fromJson returns null for non-map input', () {
      expect(Attachment.fromJson(null), isNull);
      expect(Attachment.fromJson('string'), isNull);
      expect(Attachment.fromJson(42), isNull);
    });

    test('fromJson handles missing fields gracefully', () {
      final result = Attachment.fromJson(<String, dynamic>{});
      expect(result, isNotNull);
      expect(result!.name, '');
      expect(result.type, '');
      expect(result.size, 0);
      expect(result.data, '');
    });

    test('isImage and isAudio helpers', () {
      const img = Attachment(name: 'a.png', type: 'image/png');
      const aud = Attachment(name: 'a.webm', type: 'audio/webm');
      const other = Attachment(name: 'a.txt', type: 'text/plain');
      expect(img.isImage, isTrue);
      expect(img.isAudio, isFalse);
      expect(aud.isImage, isFalse);
      expect(aud.isAudio, isTrue);
      expect(other.isImage, isFalse);
      expect(other.isAudio, isFalse);
    });
  });

  group('EntryVersion', () {
    test('toJson produces correct map', () {
      const v = EntryVersion(editedAt: 1000, text: 'hello', title: 'My Page');
      expect(v.toJson(), {
        'editedAt': 1000,
        'text': 'hello',
        'title': 'My Page',
        'tag': '',
        'tideLine': '',
      });
    });

    test('fromJson parses valid map', () {
      final result = EntryVersion.fromJson({
        'editedAt': 2000,
        'text': 'new text',
        'title': 'New Title',
        'tag': 'work',
        'tideLine': 'morning',
      });
      expect(result, isNotNull);
      expect(result!.editedAt, 2000);
      expect(result.text, 'new text');
      expect(result.title, 'New Title');
      expect(result.tag, 'work');
      expect(result.tideLine, 'morning');
    });

    test('fromJson returns null when editedAt is missing', () {
      expect(EntryVersion.fromJson({'text': 'hi'}), isNull);
    });

    test('fromJson handles non-numeric editedAt', () {
      expect(EntryVersion.fromJson({'editedAt': 'string'}), isNull);
    });
  });

  group('JournalEntry', () {
    test('toJson round-trip preserves data', () {
      final entry = JournalEntry(
        ts: 1000,
        v: 0.5,
        a: -0.3,
        word: 'hopeful',
        text: 'A good day.',
        tag: 'personal',
        title: 'Today',
        edited: true,
        prompt: 'How was today?',
        wordCount: 3,
        attachments: [
          const Attachment(name: 'img.jpg', type: 'image/jpeg', data: 'base64')
        ],
        tideLine: 'evening tide',
        tideAt: 2000,
        moodTs: 1500,
        texture: 'warm',
        reflectionStep: 'grateful',
        afterV: 0.6,
        afterA: -0.2,
        afterWord: 'content',
        afterTs: 1600,
        versions: [
          const EntryVersion(editedAt: 900, text: 'first draft', title: 'Today')
        ],
        pendingTranscription: true,
        pendingAudioPath: '/tmp/audio.webm',
      );

      final json = entry.toJson();
      final restored = JournalEntry.fromJson(json);

      expect(restored, isNotNull);
      expect(restored!.ts, entry.ts);
      expect(restored.v, entry.v);
      expect(restored.a, entry.a);
      expect(restored.word, entry.word);
      expect(restored.text, entry.text);
      expect(restored.tag, entry.tag);
      expect(restored.title, entry.title);
      expect(restored.edited, entry.edited);
      expect(restored.prompt, entry.prompt);
      expect(restored.wordCount, entry.wordCount);
      expect(restored.attachments.length, 1);
      expect(restored.attachments.first.name, 'img.jpg');
      expect(restored.tideLine, entry.tideLine);
      expect(restored.tideAt, entry.tideAt);
      expect(restored.moodTs, entry.moodTs);
      expect(restored.texture, entry.texture);
      expect(restored.reflectionStep, entry.reflectionStep);
      expect(restored.afterV, entry.afterV);
      expect(restored.afterA, entry.afterA);
      expect(restored.afterWord, entry.afterWord);
      expect(restored.afterTs, entry.afterTs);
      expect(restored.versions.length, 1);
      expect(restored.versions.first.text, 'first draft');
      expect(restored.pendingTranscription, isTrue);
      expect(restored.pendingAudioPath, '/tmp/audio.webm');
    });

    test('toJson omits empty optional fields', () {
      final entry = JournalEntry(ts: 1000);
      final json = entry.toJson();
      expect(json.containsKey('v'), isFalse);
      expect(json.containsKey('a'), isFalse);
      expect(json.containsKey('text'), isFalse);
      expect(json.containsKey('attachments'), isFalse);
      expect(json.containsKey('versions'), isFalse);
    });

    test('fromJson returns null for invalid input', () {
      expect(JournalEntry.fromJson(null), isNull);
      expect(JournalEntry.fromJson('string'), isNull);
      expect(JournalEntry.fromJson({'no_ts': true}), isNull);
      expect(JournalEntry.fromJson({'ts': 'string'}), isNull);
    });

    test('isMoodEntry identifies mood entries correctly', () {
      final moodEntry = JournalEntry(ts: 1, v: 0.5, a: -0.3, word: 'calm');
      expect(moodEntry.isMoodEntry, isTrue);

      final noWord = JournalEntry(ts: 2, v: 0.5, a: -0.3);
      expect(noWord.isMoodEntry, isFalse);

      final journalWord = JournalEntry(ts: 3, v: 0.5, a: -0.3, word: 'journal');
      expect(journalWord.isMoodEntry, isFalse);

      final emptyWord = JournalEntry(ts: 4, v: 0.5, a: -0.3, word: '');
      expect(emptyWord.isMoodEntry, isFalse);
    });

    test('date returns correct DateTime', () {
      final entry = JournalEntry(ts: 1000000);
      expect(entry.date.millisecondsSinceEpoch, 1000000);
    });
  });

  group('titleFromPage', () {
    test('extracts first non-empty line', () {
      expect(titleFromPage('\n\nHello world\nNext line'), 'Hello world');
    });

    test('strips markdown markers', () {
      expect(titleFromPage('*italic* and **bold** and #hash'),
          'italic and bold and hash');
    });

    test('capped at 9 words and 84 characters', () {
      const long = 'one two three four five six seven eight nine ten eleven';
      final result = titleFromPage(long);
      expect(result, 'one two three four five six seven eight nine\u2026');
      expect(result.length, lessThanOrEqualTo(84));
    });

    test('returns empty for empty input', () {
      expect(titleFromPage(null), '');
      expect(titleFromPage(''), '');
      expect(titleFromPage('   \n\n  '), '');
    });
  });

  group('isSystemPageTitle', () {
    test('detects system page titles', () {
      expect(isSystemPageTitle('a page for whatever is here'), isTrue);
      expect(
          isSystemPageTitle(
              'a page for whatever is here \u2014 no weather required.'),
          isTrue);
      expect(isSystemPageTitle('Custom Title'), isFalse);
    });
  });

  group('JournalDraft', () {
    test('toJson round-trip preserves data', () {
      final draft = JournalDraft(
        text: 'Draft body',
        title: 'Draft Title',
        tag: 'work',
        bottle: 'morning',
        prompt: 'How are you?',
        ts: 5000,
        activeEntryTs: 4000,
        attachments: [
          const Attachment(name: 'img.jpg', type: 'image/jpeg', data: 'base64')
        ],
        v: 0.3,
        a: -0.1,
        word: 'calm',
      );

      final json = draft.toJson();
      final restored = JournalDraft.fromJson(json);

      expect(restored, isNotNull);
      expect(restored!.text, draft.text);
      expect(restored.title, draft.title);
      expect(restored.tag, draft.tag);
      expect(restored.bottle, draft.bottle);
      expect(restored.mode, draft.mode);
      expect(restored.prompt, draft.prompt);
      expect(restored.ts, draft.ts);
      expect(restored.activeEntryTs, draft.activeEntryTs);
      expect(restored.attachments.length, 1);
      expect(restored.v, draft.v);
      expect(restored.a, draft.a);
      expect(restored.word, draft.word);
    });

    test('fromJson returns null for non-map', () {
      expect(JournalDraft.fromJson(null), isNull);
    });
  });

  group('TideObservation', () {
    test('toJson round-trip', () {
      const obs = TideObservation(ts: 1000, response: 'did');
      final json = obs.toJson();
      final restored = TideObservation.fromJson(json);
      expect(restored, isNotNull);
      expect(restored!.ts, 1000);
      expect(restored.response, 'did');
    });

    test('fromJson normalizes legacy responses', () {
      for (final legacy in ['paired', 'lower', 'same', 'higher']) {
        final obs = TideObservation.fromJson({'ts': 1000, 'response': legacy});
        expect(obs, isNotNull);
        expect(obs!.response, 'did');
      }
    });

    test('fromJson rejects invalid responses', () {
      expect(TideObservation.fromJson({'ts': 1000, 'response': 'invalid'}),
          isNull);
    });
  });

  group('TideExperiment', () {
    test('toJson round-trip', () {
      final exp = TideExperiment(
        id: 'exp-1',
        title: 'Morning Walk',
        hypothesis: 'Walking helps.',
        action: 'walk 10 min',
        theme: 'daily life',
        startedAt: 1000,
        evidenceTs: [1000, 1001],
        observations: [const TideObservation(ts: 2000, response: 'did')],
        completedAt: 3000,
      );

      final json = exp.toJson();
      final restored = TideExperiment.fromJson(json);

      expect(restored, isNotNull);
      expect(restored!.id, 'exp-1');
      expect(restored.title, 'Morning Walk');
      expect(restored.hypothesis, 'Walking helps.');
      expect(restored.action, 'walk 10 min');
      expect(restored.theme, 'daily life');
      expect(restored.startedAt, 1000);
      expect(restored.durationDays, 7);
      expect(restored.evidenceTs, [1000, 1001]);
      expect(restored.observations.length, 1);
      expect(restored.isComplete, isTrue);
    });

    test('fromJson gracefully handles missing id', () {
      expect(TideExperiment.fromJson({'startedAt': 1000}), isNull);
    });

    test('durationDays clamps to 3-21', () {
      final exp = TideExperiment.fromJson({
        'id': 'e1',
        'startedAt': 1000,
        'durationDays': 100,
      });
      expect(exp!.durationDays, 21);

      final exp2 = TideExperiment.fromJson({
        'id': 'e2',
        'startedAt': 1000,
        'durationDays': 1,
      });
      expect(exp2!.durationDays, 3);
    });

    test('isComplete reflects completedAt', () {
      final open = TideExperiment(
          id: 'e1',
          title: '',
          hypothesis: '',
          action: '',
          theme: '',
          startedAt: 1000);
      expect(open.isComplete, isFalse);

      final done = TideExperiment(
          id: 'e2',
          title: '',
          hypothesis: '',
          action: '',
          theme: '',
          startedAt: 1000,
          completedAt: 2000);
      expect(done.isComplete, isTrue);
    });
  });

  group('ParkedWorry', () {
    test('toJson round-trip', () {
      const w = ParkedWorry(
          ts: 1000, text: 'Worried about work', returnAt: 2000, settled: true);
      final json = w.toJson();
      final restored = ParkedWorry.fromJson(json);
      expect(restored, isNotNull);
      expect(restored!.ts, 1000);
      expect(restored.text, 'Worried about work');
      expect(restored.returnAt, 2000);
      expect(restored.settled, isTrue);
    });

    test('fromJson validates required fields', () {
      final result =
          ParkedWorry.fromJson(<String, dynamic>{'ts': 1, 'text': 'hi'});
      expect(result, isNull);
      expect(
          ParkedWorry.fromJson(
              <String, dynamic>{'ts': 1, 'text': 'hi', 'returnAt': 'string'}),
          isNull);
    });
  });

  group('Anchor', () {
    test('toJson round-trip', () {
      const a = Anchor(
          setAt: 1000,
          text: 'Deep breath',
          theme: 'calm',
          forDay: '2026-07-19');
      final json = a.toJson();
      final restored = Anchor.fromJson(json);
      expect(restored, isNotNull);
      expect(restored!.setAt, 1000);
      expect(restored.text, 'Deep breath');
      expect(restored.theme, 'calm');
      expect(restored.forDay, '2026-07-19');
    });

    test('fromJson validates required fields', () {
      expect(Anchor.fromJson(<String, dynamic>{}), isNull);
      expect(
          Anchor.fromJson(<String, dynamic>{'setAt': 1, 'text': 'hi'}), isNull);
    });

    test('isOpen reflects reflection status', () {
      const open = Anchor(setAt: 1, text: 'a', theme: 'b', forDay: 'c');
      expect(open.isOpen, isTrue);

      const reflected = Anchor(
          setAt: 1, text: 'a', theme: 'b', forDay: 'c', reflectedAt: 2000);
      expect(reflected.isOpen, isFalse);
    });
  });

  group('dayKeyOf', () {
    test('produces zero-padded yyyy-mm-dd', () {
      final d = DateTime(2026, 7, 5);
      expect(dayKeyOf(d.millisecondsSinceEpoch), '2026-07-05');
    });
  });

  group('formatTime', () {
    test('formats time in 12h format', () {
      final morning = DateTime(2026, 1, 1, 9, 5);
      expect(formatTime(morning), '9:05 AM');

      final afternoon = DateTime(2026, 1, 1, 14, 30);
      expect(formatTime(afternoon), '2:30 PM');

      final midnight = DateTime(2026);
      expect(formatTime(midnight), '12:00 AM');

      final noon = DateTime(2026, 1, 1, 12);
      expect(formatTime(noon), '12:00 PM');
    });
  });

  group('demoDays', () {
    test('returns 10 demo entries', () {
      final entries = demoDays();
      expect(entries.length, 10);
    });

    test('all entries have valid timestamps in the past', () {
      final entries = demoDays();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final e in entries) {
        expect(e.ts, lessThan(now));
      }
    });
  });
}
