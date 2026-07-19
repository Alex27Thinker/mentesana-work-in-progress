# Testing Strategy

## Test Types

### Unit Tests (`test/features/*/domain/`, `test/core/`)

- Domain models: JSON parsing, serialization, edge cases.
- Analysis engines: tokenization, sentiment, crisis detection, seasons.
- Repositories: CRUD operations, migration logic.
- Controllers: state mutations, command execution.
- Navigation: back-policy precedence.

### Widget Tests (`test/features/*/presentation/`)

- Screen rendering: empty, loading, error, and populated states.
- User interactions: tapping, scrolling, text entry.
- Sea rendering: verify painter output invariants.

### Integration Tests (`integration_test/`)

- First launch and onboarding.
- Mood check-in flow.
- Create, edit, delete journal entry.
- Draft recovery.
- Archive and calendar navigation.
- Weekly local insight.
- AI fallback.
- PIN lock and auto-lock.
- Backup export and restore.
- Legacy data migration.
- Reduced-motion navigation.
- System back from every route.

### Migration Tests (`test/core/database/`)

- Schema creation and versioning.
- Legacy JSON import.
- Base64 attachment extraction.
- Interrupted migration recovery.
- Duplicate-safe operation.

## Testing Principles

- Use fixed clocks, seeded randomness, and deterministic fixtures.
- No unit test depends on real time, network, microphone, or filesystem.
- Use fakes for: clocks, notifications, AI gateway, voice recorder, filesystem.
- Prefer characterization tests before migrating production code.
- Coverage baseline: domain ≥ 90%, repositories ≥ 80%, controllers ≥ 80%.

## Test Helpers (`test/helpers/`)

- `TestClock` — injected clock for deterministic time.
- `FixtureLoader` — load test data from JSON fixtures.
- `FakeSettingsRepository` — in-memory preferences.
- `FakeJournalRepository` — in-memory journal store.
- `FakeAIService` — returns canned responses.
- `FakeNotificationService` — records scheduled notifications.
