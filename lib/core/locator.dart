// Mentesana — Dependency Injection configuration.
// Central composition root using get_it + watch_it.
// All services and managers are registered here before runApp().

import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_it/watch_it.dart';

import '../_shared/services/attachment_service.dart';
import '../_shared/services/settings_repository.dart';
import '../app_store.dart';
import '../core/attachment_storage.dart';
import '../core/backup/backup_service.dart';
import '../core/backup/legacy_backup_service.dart';
import '../features/journal/data/legacy_attachment_storage.dart';
import '../features/journal/data/legacy_currents_repository.dart';
import '../features/journal/data/legacy_journal_repository.dart';
import '../features/journal/domain/currents_repository.dart';
import '../features/journal/domain/journal_repository.dart';
import 'navigation_manager.dart';
import 'sea_manager.dart';

final GetIt di = GetIt.instance;

/// Configure all dependencies — call once before runApp().
void configureDependencies() {
  // -- Services (external boundaries, no app state) --
  di.registerSingletonAsync<SettingsRepository>(
    () => SettingsRepository.create(),
  );

  di.registerLazySingleton<ImagePicker>(() => ImagePicker());
  di.registerLazySingleton<AttachmentService>(
    () => AttachmentService(imagePicker: di<ImagePicker>()),
  );

  // -- Managers (business logic, depend on services) --
  di.registerLazySingleton<NavigationManager>(() => NavigationManager());
  di.registerLazySingleton<SeaManager>(() => SeaManager());

  // AppStore is a special case: it's a ChangeNotifier that wraps persistence
  // and acts as the legacy data hub during the migration. Registered as an
  // async singleton so it can load SharedPreferences before anything uses it.
  di.registerSingletonWithDependencies<AppStore>(
    () {
      final repo = di<SettingsRepository>();
      return AppStore.fromRepository(repo);
    },
    dependsOn: [SettingsRepository],
  );

  // -- Domain interfaces (boundaries available for future controller
  // migration). Each is registered as a lazy singleton so it shares the
  // same AppStore instance as the UI. Current screens still depend on
  // AppStore during the transition.
  di.registerLazySingleton<JournalRepository>(
    () => LegacyJournalRepository(di<AppStore>()),
    dispose: (repository) => (repository as LegacyJournalRepository).dispose(),
  );
  di.registerLazySingleton<CurrentsRepository>(
    () => LegacyCurrentsRepository(di<AppStore>()),
    dispose: (repository) => (repository as LegacyCurrentsRepository).dispose(),
  );
  di.registerLazySingleton<AttachmentStorage>(
    () => const LegacyAttachmentStorage(),
  );
  di.registerLazySingleton<BackupService>(
    () => LegacyBackupService(di<AppStore>()),
  );
}

/// Shorthand used by widgets that extend WatchingWidget.
/// Allows `locate<T>()` instead of `GetIt.I<T>()`.
/// (Renamed to avoid conflict with watch_it's global `di`.)
T locate<T extends Object>() => GetIt.I<T>();
