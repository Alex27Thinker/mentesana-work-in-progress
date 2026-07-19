# Agent Workflow

## Execution Model

Each phase must be verified independently. Do not skip verification steps.

### Per-Phase Sequence

1. Read files in scope.
2. Declare changes.
3. Make edits.
4. `dart format .`
5. `flutter analyze`
6. `flutter test`
7. `flutter test integration_test` (when present)
8. Inspect diff.
9. Fix regressions.
10. Commit with conventional commit message.

### When to Stop

Stop immediately if:
- Migration ambiguity arises.
- Possible data loss is detected.
- Privacy regression is introduced.
- Test failure cannot be resolved.
- User-visible behavior drifts from baseline.

Report the evidence. Do not improvise a repository-wide redesign.

## Skill Routing

Only load skills relevant to the current phase:

- **Architecture**: `flutter-apply-architecture-best-practices`, `flutter-architecture-expert`.
- **Persistence**: `drift-persistence`.
- **Testing**: `dart-add-unit-test`, `flutter-add-widget-test`.
- **Performance**: `flutter-core:flutter-performance`.
- **Review/security**: `devs:code-review`.
- **Git**: `git-lovely:useful-commits`.

Do not use BLoC, Riverpod, or state-management skills.
