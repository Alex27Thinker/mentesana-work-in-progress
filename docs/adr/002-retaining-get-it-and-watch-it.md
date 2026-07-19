# ADR 002: Retaining get_it and watch_it

**Date:** 2026-07-19
**Status:** Accepted
**Deciders:** Lead architect

## Context

The project uses `get_it` for DI and `watch_it` for reactive observation. These were introduced after extracting state from the monolithic `AppStore`/`AppShell`.

## Decision

Retain `get_it` and `watch_it`. Do not introduce BLoC, Riverpod, Provider, Redux, or MobX.

## Consequences

- Positive: proven stack for this codebase size.
- Positive: avoids framework migration cost.
- Negative: `get_it` lacks scope disposal semantics of `Riverpod`.
- Mitigation: use `get_it` scopes for controller lifecycle, and `watch_it`'s `onDispose` for cleanup.
