# Code Review Checklist

## Architecture

- [ ] Dependency direction `presentation → domain ← data` is maintained.
- [ ] No Material imports in domain or data layer files.
- [ ] No SharedPreferences/database/network access in widgets.
- [ ] Feature screens do not import other feature screens.
- [ ] Cross-feature navigation goes through `app/navigation/`.

## Safety

- [ ] No diagnostic or causal language introduced.
- [ ] Crisis check is not weakened.
- [ ] Reduced motion support preserved.
- [ ] Privacy: no journal text in logs, no unnecessary data in network calls.
- [ ] SharedPreferences write Futures are awaited.

## Correctness

- [ ] All `fromJson` constructors handle malformed input without crashing.
- [ ] Default values match existing behavior.
- [ ] Migration is idempotent and restart-safe.
- [ ] New tests cover empty, error, and edge cases.

## Style

- [ ] `dart format .` passes.
- [ ] `flutter analyze` has no new warnings.
- [ ] No dead code, commented-out code, or unused imports.
- [ ] Conventional commit message format.
