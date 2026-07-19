# ADR 003: Drift-Backed Journal Persistence

**Date:** 2026-07-19
**Status:** Accepted
**Deciders:** Lead architect

## Context

Journal entries are currently stored as a single JSON blob in SharedPreferences. Every mutation rewrites the entire list. Base64 attachment data bloats the payload.

## Decision

Use Drift (SQLite) for all structured journal data: entries, versions, attachments metadata, tide experiments, parked worries, anchors.

## Consequences

- Positive: incremental updates instead of full-rewrite.
- Positive: indexed queries for date range, mood filtering, etc.
- Positive: foreign key integrity.
- Positive: schema versioning and migration.
- Negative: adds Drift dependency and build_runner for generated code.
- Mitigation: the dependency is well-established in the Flutter ecosystem; generated code is checked in.
