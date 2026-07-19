# Privacy Boundaries

## Principle

Journal content stays on-device by default. AI features are opt-in only and send the minimum data needed.

## Current

- AI service sends structured analysis output + recent entries to a serverless proxy.
- Local analysis always runs first; AI is additive.
- Doctrine filter post-processes AI output to catch diagnostic language.
- Crisis language blocks AI insight generation entirely.

## Boundaries

### Always Local (No Network)

- Journal entry text and metadata
- Mood check-ins and analysis
- Crisis-language detection
- Currents engine (anchors, parked worries, tide experiments)
- Weekly insight generation (local path)
- All settings and preferences
- PIN code
- Backup encryption/decryption

### Opt-In Only (Network Permitted)

- AI-enhanced weekly insight
- AI-enhanced daily prompts

### What AI Sends

When opted in:
- Local analysis output (sentiment, themes, mood trajectory — no raw text)
- Recent entry summaries (truncated, last 12)
- Active experiment metadata
- No PIN, no device identifiers, no location, no contact data

### What AI Must Never Send

- Full journal text (truncated to 400 characters max per entry)
- Attachment contents
- PIN or passphrase
- Device or personal identifiers

## Enforcement

- `AIService` is the only class that performs network I/O.
- All AI responses run through `doctrineFilter` before display.
- `containsCrisisLanguage` check runs before AI insight is shown.
- `kAiProxyBase` is compiled out by default (empty string → no network).
- Server credentials never live in the app.
