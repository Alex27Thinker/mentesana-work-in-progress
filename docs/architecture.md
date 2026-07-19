# Mentesana Architecture

## Metaphor

- The enduring self is the sea.
- Moods are weather passing through it.
- Patterns over time are seasons.

## Current State (after correction commit)

The repository has:

- A feature-first domain model layer under
  `lib/features/journal/domain/`. Models are immutable
  (`const`-compatible where possible) with sentinel-based
  `copyWith` that distinguishes omitted, null, and replaced
  arguments. Collection fields are defensively
  `List.unmodifiable` copies.
- Extracted analysis modules under `lib/core/analysis/`. The
  modules import journal-domain models directly. They do not
  import `app_store.dart` or any persistence layer.
- Compatibility barrel re-exports in `lib/analysis_engine.dart`
  and `lib/text_lexicons.dart` so existing screens that import
  the root paths continue to compile.
- Domain repository interfaces in
  `lib/features/journal/domain/journal_repository.dart` and
  `lib/currents_repository.dart`. Both are asynchronous
  interfaces suitable for a future Drift implementation.
- Legacy adapters in
  `lib/features/journal/data/legacy_journal_repository.dart` and
  `lib/currents_repository.dart` that wrap `AppStore` and expose
  immutable snapshots. `AppStore` is the single writer.
- `BackupService` and `AttachmentStorage` interfaces with
  legacy adapters in `lib/core/backup/legacy_backup_service.dart`
  and `lib/features/journal/data/legacy_attachment_storage.dart`.
- `tool/verify.sh` for phase verification, with LF line endings.
- Documentation under `docs/` and an agent workflow guide
  (`AGENTS.md`, `.agent/`).

## Transitional

The following are partially migrated but the screens still
depend on `AppStore` directly. Boundaries are in place for the
next phase to migrate them:

- `AppStore` remains a `ChangeNotifier` that owns all journal,
  settings, and currents data. Controllers and services that
  depend on the new interfaces are not yet implemented.
- The `Lib/analysis_engine.dart` and `lib/text_lexicons.dart`
  barrel re-exports exist as a temporary compatibility layer.
- The `lib/core/sea_manager.dart` and `lib/core/navigation_manager.dart`
  managers are still wired through `get_it` directly.

## Target

```
lib/
├── app/           — app entry, bootstrap, navigation, shell composition
├── core/          — database, errors, lifecycle, privacy, time, utilities
├── design_system/ — theme, icons, motion, sea painting, shared widgets
├── features/      — feature modules (journal, check_in, insights, etc.)
└── main.dart
```

- Drift-backed persistence under `lib/core/database/`.
- File-backed attachments under `lib/core/attachments/`.
- Feature-first file migration: each screen in
  `lib/features/<feature>/presentation/`.
- Controllers own feature-facing state. Repositories own
  persistence. Widgets only own ephemeral presentation.
- Shell decomposition under `lib/app/shell/`.
- Analysis caching keyed by journal revision.

## Dependency Direction

```
presentation → domain ← data
```

- Feature presentation layers must not import another feature's screen.
- Cross-feature navigation belongs under `app/navigation`.
- Shared visual primitives belong under `design_system`.
- Business logic and domain models must not import Material widgets.
- Data implementations satisfy interfaces defined at the domain boundary.
- Screens must not access SharedPreferences, database objects, file APIs, notifications, or HTTP clients directly.

## State Management

- `get_it` for dependency injection.
- `watch_it` for reactive widget observation.
- No BLoC, Riverpod, Provider, Redux, or MobX.

## Controllers and Repositories

- **Repositories** own persistence (interfaces in domain, implementations in data).
- **Controllers** own feature-facing state and commands.
- **Domain engines** own pure analysis.
- **Services** own platform/network integrations.
- **Widgets** own local ephemeral presentation state.

## Testing Strategy

See `docs/testing-strategy.md`.
