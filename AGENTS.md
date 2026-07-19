# Mentesana — Agent Workflow Guide

This file tells every future agent how to operate in this repository safely and consistently.

## 1. Product Hard Limits (Never Violate)

Mentesana is a journaling-first mental wellness app. The self is the sea; moods are weather; patterns are seasons.

**Never:**
- diagnose, label, or claim causation;
- describe moods as good or bad;
- add streaks, scores, badges, points, or rewards;
- make crisis UI red, alarming, or coercive;
- send private journal content to a network service without explicit opt-in;
- weaken existing local crisis-language checks;
- remove reduced-motion support;
- silently change stored user data.

## 2. Before Editing

1. `git log --oneline -5` — understand recent context.
2. `git status` — check for uncommitted work.
3. Inspect every call site before changing a public class, constructor, repository, controller, model, route, or service.
4. Declare which files are in scope for the current task.
5. Read the target file(s) fully before editing.

## 3. Architecture Rules

- **State stack**: `get_it` + `watch_it`. Do not introduce BLoC, Riverpod, Provider, or any other state framework without an approved ADR.
- **Dependency direction**: `presentation -> domain <- data`. Feature screens must not import another feature's screen.
- **Persistence**: View layer never accesses SharedPreferences, database, file APIs, notifications, or HTTP clients directly.
- **Domain purity**: Business logic and domain models must not import Material widgets.
- **Repository pattern**: Data implementations satisfy interfaces defined at the domain boundary. Controllers depend on interfaces, not concrete persistence.

## 4. Testing Requirements

- `dart format .` — must pass.
- `flutter analyze` — must have zero new warnings.
- `flutter test` — must pass before commit.
- Run `flutter test integration_test` when integration tests exist.
- Add characterization tests for any behavior being migrated.

## 5. Commit Conventions

Use conventional commits:
- `feat:` — new feature
- `refactor:` — behavior-preserving restructuring
- `perf:` — performance improvement
- `test:` — test addition
- `chore:` — tooling, config, CI
- `security:` — security hardening
- `docs:` — documentation only

Keep commits small and focused. Never mix unrelated phases in one commit.

## 6. Migration Safety

- Never delete legacy data before migration is verified.
- Migration must be idempotent and restart-safe.
- Verify entry counts, version counts, and attachment hashes after migration.
- Preserve backward-compatible JSON parsing for old backup imports.

## 7. Privacy

- Never log: journal text, transcripts, prompts, attachment contents, PINs, passphrases, encryption keys, or raw AI payloads.
- Configure network timeouts for all external calls.
- Keep server credentials outside the app entirely.
