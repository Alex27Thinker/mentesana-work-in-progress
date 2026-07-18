// Mentesana — Dependency Injection configuration.
// Central composition root using get_it + watch_it.
// All services and managers are registered here before runApp().

import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watch_it/watch_it.dart';

import '../_shared/services/attachment_service.dart';
import '../_shared/services/settings_repository.dart';
import '../app_store.dart';
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
}

/// Shorthand used by widgets that extend WatchingWidget.
/// Allows `locate<T>()` instead of `GetIt.I<T>()`.
/// (Renamed to avoid conflict with watch_it's global `di`.)
T locate<T extends Object>() => GetIt.I<T>();
