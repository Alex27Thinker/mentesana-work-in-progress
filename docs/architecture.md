# Mentesana Architecture

## Metaphor

- The enduring self is the sea.
- Moods are weather passing through it.
- Patterns over time are seasons.

## Target Structure

```
lib/
├── app/           — app entry, bootstrap, navigation, shell composition
├── core/          — database, errors, lifecycle, privacy, time, utilities
├── design_system/ — theme, icons, motion, sea painting, shared widgets
├── features/      — feature modules (journal, check_in, insights, etc.)
└── main.dart
```

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
