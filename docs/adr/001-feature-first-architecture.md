# ADR 001: Feature-First Architecture

**Date:** 2026-07-19
**Status:** Accepted
**Deciders:** Lead architect

## Context

The current codebase is mostly flat (`lib/` with 40 files, many >500 lines, one >2500). Screens, models, and logic are mixed. Adding new features is costly because there is no clear module boundary.

## Decision

Adopt a feature-first package layout under `lib/features/`. Each feature owns its `presentation/`, `domain/`, and `data/` directories. Shared primitives go under `design_system/` and `core/`.

## Consequences

- Positive: clear isolation, easier parallel work, obvious file locations.
- Positive: dependency direction is enforceable at the directory level.
- Negative: some duplication of simple types across features.
- Mitigation: keep shared domain models in `core/` where truly cross-cutting.
