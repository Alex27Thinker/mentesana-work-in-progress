import 'package:flutter_test/flutter_test.dart';
import 'package:mentesana_mood_selector/analysis_engine.dart';
import 'package:mentesana_mood_selector/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentesana_mood_selector/_shared/services/settings_repository.dart';

void main() {
  group('Privacy: crisis language', () {
    test('crisis language detected in multiple texts', () {
      expect(containsCrisisLanguage(['Feeling okay', 'I want to die']), isTrue);
    });

    test('no crisis language in safe texts', () {
      expect(containsCrisisLanguage(['Rough day', 'Better tomorrow']), isFalse);
    });
  });

  group('Privacy: AI opt-in', () {
    late SettingsRepository repo;
    late AppStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepository.createFromPrefs(prefs);
      store = AppStore.fromRepository(repo);
    });

    test('AI is opt-in, default off', () {
      expect(store.aiEnabled, isFalse);
    });

    test('AI toggle persists', () {
      store.setAiEnabled(true);
      expect(store.aiEnabled, isTrue);

      final store2 = AppStore.fromRepository(repo);
      expect(store2.aiEnabled, isTrue);
    });
  });

  group('Privacy: PIN storage', () {
    late SettingsRepository repo;
    late AppStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepository.createFromPrefs(prefs);
      store = AppStore.fromRepository(repo);
    });

    test('PIN defaults to empty', () {
      expect(store.pinCode, '');
      expect(store.pinLockOn, isFalse);
    });

    test('PIN can be set and retrieved', () {
      store.setPin('1234');
      expect(store.pinCode, '1234');
    });
  });

  group('Quiet hours', () {
    late SettingsRepository repo;
    late AppStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepository.createFromPrefs(prefs);
      store = AppStore.fromRepository(repo);
    });

    test('quiet hours default to off', () {
      expect(store.quietHoursOn, isFalse);
      expect(store.quietHoursStart, '22:00');
      expect(store.quietHoursEnd, '08:00');
    });
  });
}
