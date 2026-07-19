# ADR 005: Repository and Controller Boundaries

**Date:** 2026-07-19
**Status:** Accepted
**Deciders:** Lead architect

## Context

AppStore is a 1442-line ChangeNotifier that owns models, persistence, settings, and domain logic. No separation between persistence, business logic, and UI state.

## Decision

Introduce domain-facing repository interfaces. Controllers depend on interfaces, not concrete data implementations. Services own platform/network integrations.

## Consequences

- Positive: testable controllers and repositories.
- Positive: persistence can change without affecting controllers.
- Positive: clear ownership boundaries.
- Negative: more files and indirection for trivial cases.
- Mitigation: do not create repository interfaces for settings that are inherently simple key-value stores.
