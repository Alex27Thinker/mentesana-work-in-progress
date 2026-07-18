# SharedPreferences in Flutter

SharedPreferences provides a simple, persistent key-value storage solution for Flutter applications. It wraps platform-specific storage mechanisms—NSUserDefaults on iOS and SharedPreferences on Android—with a unified async Dart API that works consistently across platforms.

## Core Concepts

SharedPreferences stores simple data types persistently on the device, surviving app restarts and updates. Data is stored as key-value pairs where keys are strings and values can be primitives (int, double, bool, String) or lists of strings. This makes it ideal for user preferences, settings, flags, and small configuration data.

The package handles platform differences automatically, ensuring that data written on one platform can be read consistently. However, SharedPreferences is not designed for critical data storage since writes may be buffered and not immediately persisted to disk.

## Installation and Setup

Add the shared_preferences package to your pubspec.yaml:

```yaml
dependencies:
  shared_preferences: ^2.3.0
```

Import the package in your Dart files:

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

No additional platform-specific configuration is required. The package works out of the box on Android, iOS, macOS, Linux, Windows, and web platforms.

## API Evolution

The shared_preferences package has evolved through several API versions:

### Legacy API (SharedPreferences)
The original API requires obtaining a SharedPreferences instance before any operations. While still functional, this API is planned for deprecation in future versions:

```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setInt('counter', 42);
final counter = prefs.getInt('counter') ?? 0;
```

### Async API (SharedPreferencesAsync)
The newer async API (introduced in version 2.3.0) eliminates the need to obtain an instance first, providing a cleaner interface for occasional access:

```dart
final prefsAsync = SharedPreferencesAsync();
await prefsAsync.setInt('counter', 42);
final counter = await prefsAsync.getInt('counter') ?? 0;
```

### Cached API (SharedPreferencesWithCache)
For applications that frequently access preferences, the cached API loads preferences into memory once and keeps them synchronized:

```dart
final prefsWithCache = await SharedPreferencesWithCache.create(
  cacheOptions: const SharedPreferencesWithCacheOptions(),
);
await prefsWithCache.setInt('counter', 42);
final counter = prefsWithCache.getInt('counter') ?? 0; // No await needed for reads
```

The Flutter team strongly encourages using SharedPreferencesAsync or SharedPreferencesWithCache for new projects.

## Supported Data Types

SharedPreferences supports a limited set of data types, each with corresponding getter and setter methods:

### Primitive Types

**Int** - Integer values:
```dart
await prefs.setInt('age', 25);
final age = prefs.getInt('age') ?? 0;
```

**Double** - Floating-point numbers:
```dart
await prefs.setDouble('price', 19.99);
final price = prefs.getDouble('price') ?? 0.0;
```

**Bool** - Boolean flags:
```dart
await prefs.setBool('isDarkMode', true);
final isDarkMode = prefs.getBool('isDarkMode') ?? false;
```

**String** - Text values:
```dart
await prefs.setString('username', 'john_doe');
final username = prefs.getString('username') ?? '';
```

**String List** - Lists of strings:
```dart
await prefs.setStringList('tags', ['flutter', 'dart', 'mobile']);
final tags = prefs.getStringList('tags') ?? [];
```

All getter methods return nullable values, requiring null-aware operators or default values to handle missing keys.

## Basic Operations

### Writing Data

Set values using the appropriate setter method. All setters return a Future<bool> indicating success:

```dart
final success = await prefs.setString('apiKey', 'abc123');
if (!success) {
  // Handle write failure
  print('Failed to save API key');
}
```

In practice, write failures are rare and usually indicate platform-level issues like insufficient storage space or permission problems.

### Reading Data

Read values using the corresponding getter method, always providing a default value for missing keys:

```dart
final theme = prefs.getString('theme') ?? 'light';
final fontSize = prefs.getInt('fontSize') ?? 14;
final notificationsEnabled = prefs.getBool('notifications') ?? true;
```

### Checking Key Existence

Verify if a key exists before reading:

```dart
final hasUsername = prefs.containsKey('username');
if (hasUsername) {
  final username = prefs.getString('username')!;
  // Use username safely
}
```

### Deleting Data

Remove specific keys or clear all preferences:

```dart
// Remove a single key
await prefs.remove('temporaryData');

// Clear all preferences (use with caution)
await prefs.clear();

// Get all keys to selectively clear
final allKeys = prefs.getKeys();
for (final key in allKeys) {
  if (key.startsWith('cache_')) {
    await prefs.remove(key);
  }
}
```

## Practical Patterns

### User Settings Management

Create a settings service that encapsulates SharedPreferences operations:

```dart
class SettingsService {
  static const _keyTheme = 'theme';
  static const _keyLanguage = 'language';
  static const _keyNotifications = 'notifications_enabled';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // Theme
  String get theme => _prefs.getString(_keyTheme) ?? 'system';
  Future<void> setTheme(String theme) => _prefs.setString(_keyTheme, theme);

  // Language
  String get language => _prefs.getString(_keyLanguage) ?? 'en';
  Future<void> setLanguage(String lang) => _prefs.setString(_keyLanguage, lang);

  // Notifications
  bool get notificationsEnabled => _prefs.getBool(_keyNotifications) ?? true;
  Future<void> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(_keyNotifications, enabled);
}
```

### Onboarding State

Track whether users have completed onboarding flows:

```dart
class OnboardingService {
  static const _keyCompleted = 'onboarding_completed';
  static const _keyVersion = 'onboarding_version';

  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  bool hasCompletedOnboarding() {
    return _prefs.getBool(_keyCompleted) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    await _prefs.setBool(_keyCompleted, true);
    await _prefs.setInt(_keyVersion, 1);
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_keyCompleted);
  }

  bool needsOnboardingUpdate(int currentVersion) {
    final savedVersion = _prefs.getInt(_keyVersion) ?? 0;
    return savedVersion < currentVersion;
  }
}
```

### Feature Flags

Manage feature toggles and A/B testing flags:

```dart
class FeatureFlags {
  final SharedPreferences _prefs;

  FeatureFlags(this._prefs);

  bool isFeatureEnabled(String featureName) {
    return _prefs.getBool('feature_$featureName') ?? false;
  }

  Future<void> setFeatureEnabled(String featureName, bool enabled) {
    return _prefs.setBool('feature_$featureName', enabled);
  }

  Future<void> updateFlagsFromServer(Map<String, bool> flags) async {
    for (final entry in flags.entries) {
      await setFeatureEnabled(entry.key, entry.value);
    }
  }
}
```

### Last Sync Timestamp

Track when data was last synchronized with a server:

```dart
class SyncManager {
  static const _keyLastSync = 'last_sync_timestamp';
  final SharedPreferences _prefs;

  SyncManager(this._prefs);

  DateTime? getLastSyncTime() {
    final timestamp = _prefs.getInt(_keyLastSync);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> updateLastSyncTime() {
    return _prefs.setInt(
      _keyLastSync,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool shouldSync({Duration interval = const Duration(hours: 1)}) {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;

    final elapsed = DateTime.now().difference(lastSync);
    return elapsed >= interval;
  }
}
```

## Advanced Patterns

### Versioned Preferences

Handle preference schema changes across app versions:

```dart
class VersionedPreferences {
  static const _keyVersion = '_prefs_version';
  static const _currentVersion = 2;

  final SharedPreferences _prefs;

  VersionedPreferences(this._prefs);

  static Future<VersionedPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    final instance = VersionedPreferences(prefs);
    await instance._migrate();
    return instance;
  }

  Future<void> _migrate() async {
    final currentVersion = _prefs.getInt(_keyVersion) ?? 0;

    if (currentVersion < 1) {
      await _migrateToV1();
    }
    if (currentVersion < 2) {
      await _migrateToV2();
    }

    await _prefs.setInt(_keyVersion, _currentVersion);
  }

  Future<void> _migrateToV1() async {
    // Rename old keys
    final oldTheme = _prefs.getString('app_theme');
    if (oldTheme != null) {
      await _prefs.setString('theme', oldTheme);
      await _prefs.remove('app_theme');
    }
  }

  Future<void> _migrateToV2() async {
    // Convert string to bool
    final oldNotifValue = _prefs.getString('notifications');
    if (oldNotifValue != null) {
      await _prefs.setBool('notifications', oldNotifValue == 'true');
      await _prefs.remove('notifications');
    }
  }
}
```

### Prefix-Based Organization

Organize related preferences using key prefixes:

```dart
class PrefixedPreferences {
  final SharedPreferences _prefs;
  final String _prefix;

  PrefixedPreferences(this._prefs, this._prefix);

  String _key(String key) => '${_prefix}_$key';

  Future<void> setString(String key, String value) =>
      _prefs.setString(_key(key), value);

  String? getString(String key) => _prefs.getString(_key(key));

  Future<void> clearAll() async {
    final keys = _prefs.getKeys()
        .where((key) => key.startsWith('$_prefix_'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

// Usage
final userPrefs = PrefixedPreferences(prefs, 'user');
final cachePrefs = PrefixedPreferences(prefs, 'cache');

await userPrefs.setString('name', 'John');
await cachePrefs.setString('token', 'abc123');
```

### Type-Safe Preferences

Create type-safe wrappers for complex data:

```dart
class TypeSafePrefs {
  final SharedPreferences _prefs;

  TypeSafePrefs(this._prefs);

  // Enum preferences
  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString('theme_mode', mode.name);

  ThemeMode getThemeMode() {
    final name = _prefs.getString('theme_mode');
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  // JSON preferences (for simple objects)
  Future<void> setUser(Map<String, dynamic> user) =>
      _prefs.setString('user', jsonEncode(user));

  Map<String, dynamic>? getUser() {
    final json = _prefs.getString('user');
    return json != null ? jsonDecode(json) as Map<String, dynamic> : null;
  }
}
```

## Integration with State Management

### Provider Integration

Use SharedPreferences with Provider for reactive settings:

```dart
class SettingsNotifier extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs);

  static const _keyTheme = 'theme';

  String get theme => _prefs.getString(_keyTheme) ?? 'light';

  Future<void> setTheme(String theme) async {
    await _prefs.setString(_keyTheme, theme);
    notifyListeners();
  }
}

// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsNotifier(prefs),
      child: const MyApp(),
    ),
  );
}
```

### Riverpod Integration

Create providers for SharedPreferences data:

```dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

final themeProvider = StateNotifierProvider<ThemeNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;
  static const _key = 'theme';

  ThemeNotifier(this._prefs) : super(_prefs.getString(_key) ?? 'light');

  Future<void> setTheme(String theme) async {
    await _prefs.setString(_key, theme);
    state = theme;
  }
}
```

## Best Practices

### Key Naming Conventions

Use consistent, descriptive key names with clear prefixes:

```dart
class PrefKeys {
  // User-related preferences
  static const userTheme = 'user_theme';
  static const userLanguage = 'user_language';
  static const userName = 'user_name';

  // App state
  static const onboardingComplete = 'app_onboarding_complete';
  static const firstLaunch = 'app_first_launch';

  // Cache
  static const cacheTimestamp = 'cache_last_update';
  static const cacheVersion = 'cache_version';
}
```

### Default Values

Always provide sensible defaults for missing values:

```dart
class Defaults {
  static const theme = 'light';
  static const language = 'en';
  static const fontSize = 14;
  static const notificationsEnabled = true;
}

final theme = prefs.getString(PrefKeys.userTheme) ?? Defaults.theme;
```

### Error Handling

Handle potential errors gracefully:

```dart
Future<bool> saveUserSettings(UserSettings settings) async {
  try {
    await prefs.setString('user_name', settings.name);
    await prefs.setString('user_email', settings.email);
    return true;
  } catch (e) {
    print('Failed to save settings: $e');
    return false;
  }
}
```

### Testing

Mock SharedPreferences for unit tests:

```dart
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'theme': 'dark',
      'counter': 42,
    });
    prefs = await SharedPreferences.getInstance();
  });

  test('reads theme correctly', () {
    expect(prefs.getString('theme'), 'dark');
  });

  test('updates counter', () async {
    await prefs.setInt('counter', 43);
    expect(prefs.getInt('counter'), 43);
  });
}
```

## Limitations and Considerations

### Not for Critical Data

SharedPreferences does not guarantee immediate persistence. Writes may be buffered and flushed asynchronously, so data might be lost if the app crashes immediately after a write. Never use it for critical data that must be persisted immediately.

### Storage Size Limits

While there's no hard limit, SharedPreferences is designed for small amounts of data. Storing large strings or many keys can impact app startup time since all preferences are loaded into memory. Keep individual values small (under 1KB) and total preferences under 100KB.

### No Encryption

Data is stored in plain text, making it readable on rooted/jailbroken devices or through device backups. Never store passwords, API keys, or other sensitive data without encryption. Use flutter_secure_storage for sensitive information.

### Type Safety

All values are stored as strings internally (except on platforms that support native types). Type mismatches can cause runtime errors if you attempt to read a value with the wrong getter method. Always use consistent types for each key.

### Concurrency

Multiple simultaneous writes to the same key may result in race conditions. The last write wins, potentially overwriting data. For complex state updates, consider using a single write operation or a more robust storage solution.

## Platform-Specific Behavior

### Android
Data is stored in XML files in the app's private storage directory. The SharedPreferences API is native to Android, providing optimal performance.

### iOS
Uses NSUserDefaults, which stores data as property list files. Supports iCloud synchronization when properly configured, though this is not enabled by default in the Flutter plugin.

### Web
Stores data in the browser's LocalStorage API, which has a typical limit of 5-10MB per domain. Data persists across browser sessions but can be cleared by users.

### Desktop (Windows, Linux, macOS)
Uses platform-appropriate storage locations (Registry on Windows, preference files on macOS/Linux). Behavior is consistent with mobile platforms but file locations differ.

## Migration to Newer APIs

If using the legacy API, migrate to SharedPreferencesAsync for simpler code:

```dart
// Legacy
final prefs = await SharedPreferences.getInstance();
final value = prefs.getInt('key') ?? 0;
await prefs.setInt('key', value + 1);

// New async API
final prefs = SharedPreferencesAsync();
final value = await prefs.getInt('key') ?? 0;
await prefs.setInt('key', value + 1);
```

For frequently accessed preferences, use SharedPreferencesWithCache:

```dart
final prefs = await SharedPreferencesWithCache.create(
  cacheOptions: const SharedPreferencesWithCacheOptions(
    // Optional: specify which keys to cache
    allowList: <String>{'theme', 'language', 'fontSize'},
  ),
);

// Reads are synchronous (no await)
final theme = prefs.getString('theme') ?? 'light';

// Writes still require await
await prefs.setString('theme', 'dark');
```

## Common Use Cases

SharedPreferences excels in these scenarios:

- User interface preferences (theme, language, font size)
- Feature flags and A/B test assignments
- Onboarding and tutorial completion tracking
- Last sync timestamps and app version numbers
- Simple app state that survives restarts
- Non-sensitive API configuration
- User opt-in/opt-out preferences
- Recently used items or search history (small lists)

Choose SharedPreferences when simplicity and ease of implementation are priorities, data structures are flat, and relational queries are not needed. For complex data, relational queries, or larger datasets, consider SQLite (via sqflite or Drift) or NoSQL solutions (via Hive).
