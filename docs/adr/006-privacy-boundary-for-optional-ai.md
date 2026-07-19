# ADR 006: Privacy Boundary for Optional AI

**Date:** 2026-07-19
**Status:** Accepted
**Deciders:** Lead architect

## Context

AI insight is an optional enhancement. The default path is entirely local. The AI path must send structured data to a serverless proxy.

## Decision

- AI is always opt-in, default off.
- `AIService` is the only class that performs network I/O.
- All AI output runs through `doctrineFilter` before display.
- `containsCrisisLanguage` runs before AI insight is shown.
- Server credentials never live in the app.
- Network timeouts are configured on all external calls.
- Local fallback is silent and automatic.

## Consequences

- Positive: clear privacy boundary.
- Positive: local analysis is the unbreakable default.
- Negative: AI integration cannot be tested without a proxy endpoint.
- Mitigation: `FakeAIService` provides deterministic responses for tests.
