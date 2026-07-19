# Data Storage

## Current State (Legacy)

- **Journal entries**: stored as a single JSON array in SharedPreferences under `mentesana-entries`.
- **Attachments**: base64-encoded data URLs embedded in entry JSON.
- **Settings**: individual SharedPreferences keys.
- **Drafts**: single JSON object under `mentesana-journal-draft`.
- **Tide experiments, parked worries, anchors**: separate JSON keys.

**Problems:**
- Every mutation serializes the entire journal.
- Attachment base64 payloads bloat SharedPreferences.
- SharedPreferences setter Futures are un-awaited.
- No migration versioning.

## Target State

### Structured Data (Drift/SQLite)

- `journal_entries` — entry records with normalized fields.
- `entry_versions` — version history with foreign key.
- `attachments` — metadata with file path, foreign key to entry.
- `tide_experiments` — N-of-1 experiments.
- `tide_observations` — daily observations per experiment.
- `parked_worries` — worry postponement records.
- `anchors` — behavioural activation records.
- `shown_insight_lines` — deduplication for weekly insight.
- `migration_metadata` — schema version tracking.

### Preferences (SharedPreferences)

Settings that remain in SharedPreferences:
- Theme / room
- Language
- Reduced motion
- Reminder toggles and times
- PIN lock and auto-lock
- Text size
- Profile name
- AI opt-in toggle
- Onboarding completion

### Attachments (File System)

- App-support directory for attachment files.
- Stable generated filenames.
- MIME type, size metadata in database.
- Atomic file writes.
- Cleanup on entry deletion.
- Image compression before write.

## Migration

See Phase 6 implementation. Migration is idempotent, restart-safe, and verifies record counts and hashes before marking complete.
