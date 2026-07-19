# Dependency Rules

## Direction

```
presentation → domain ← data
```

Example: `JournalScreen` (presentation) depends on `JournalController` (domain/controller) which depends on `JournalRepository` (domain interface). The concrete `DriftJournalRepository` (data) implements the interface.

## Rules

1. **Feature isolation.** Feature `journal/presentation` must not import `insights/presentation`.
2. **Cross-feature navigation.** Goes through `app/navigation/` only.
3. **No Material in domain.** Domain models, use cases, and engine code must not import `package:flutter/material.dart`.
4. **No persistence in widgets.** Screens never access SharedPreferences, Drift, file I/O, notifications, or HTTP clients.
5. **Interface dependency.** Controllers receive domain interfaces, not concrete implementations.
6. **Package imports preferred.** Avoid deep relative imports like `../../feature_x/file.dart`.
7. **No generic folders.** Avoid `helpers/`, `utils/`, `managers/` unless genuinely cross-cutting and documented.

## Violation Consequences

Any import that violates these rules must be justified in a comment and documented in the ADR.

## Enforcement

- `flutter analyze` with strict-casts, strict-inference, strict-raw-types.
- Architecture dependency tests (see `test/architecture/`).
- Code review checklist (see `.agent/review-checklist.md`).
