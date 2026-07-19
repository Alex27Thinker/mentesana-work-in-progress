# Privacy Boundaries

## Current Behaviour

- AI is opt-in. The toggle is off by default and lives in
  `SettingsRepository.aiEnabled`. A change to the toggle does not
  initiate any network request.
- The local analysis engine always runs first and remains the
  default. The AI layer is additive: failures and unavailability
  fall back silently to the local letter.
- Crisis-language detection is local and deterministic
  (`containsCrisisLanguage` in `lib/core/analysis/crisis_policy.dart`).
  No crisis check is ever performed remotely.
- All AI requests pass through `doctrineFilter` before being shown
  to the user; forbidden language is sanitized.

## AI Path Network Behaviour

When the user has explicitly enabled AI, `AIService` may send the
following to the configured proxy:

- Local analysis output (sentiment, theme counts, mood
  trajectory, frequent words). These are derived from journal
  text but contain no raw journal text.
- Truncated recent entry summaries, capped at 12 entries,
  newest last. Each summary is capped at 400 characters of the
  original entry text (`ai_service.dart: buildInsightContext`) or
  200 characters (`buildPromptContext`). Truncation is the
  prototype's documented behaviour, not a new restriction.
- Active tide experiment metadata: id, title, theme, observation
  count.
- Active anchor text, if present.
- A prompt for the model: head, count, patterns, question, and
  a thin-evidence flag (computed locally from the entry set).

The AI path NEVER sends:

- Attachment contents or attachment metadata.
- The PIN code or the auto-lock seconds.
- The backup passphrase.
- The device identifier, locale, or any other device metadata.
- The provider key. The key lives only on the server.

The proxy base URL is read from the `MENTESANA_AI_PROXY` build
constant. When the constant is empty (the default build), the
network call fails immediately and the AI layer falls back to
the local analysis. Server credentials never live in the app.

## Deferred or Not Implemented

The following are explicitly NOT part of the current
implementation and must not be claimed:

- File-backed attachments.
- Drift persistence.
- Controller decomposition.
- Analysis caching.
- Shell decomposition.
- AI opt-in audit logging on the client.

## Enforcement

- `AIService` is the only class that performs network I/O.
- All AI responses run through `doctrineFilter` before display.
- `containsCrisisLanguage` runs before AI insight is shown; a
  crisis result replaces the AI letter with a local one.
- The build constant `kAiProxyBase` is empty by default, which
  disables network calls without code changes.
- The provider key never lives in the app.
- All network calls are time-bound by the Dart `HttpClient`
  defaults; long stalls are not expected.
