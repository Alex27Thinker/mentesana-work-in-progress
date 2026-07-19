# ADR 004: File-Backed Attachments

**Date:** 2026-07-19
**Status:** Accepted
**Deciders:** Lead architect

## Context

Attachments (images, audio) are stored as base64 data URLs embedded in entry JSON in SharedPreferences. This wastes storage and encoding/decoding overhead.

## Decision

Store attachment files in the app-support directory with stable generated filenames. Database rows hold metadata (MIME type, size, relative path) only.

## Consequences

- Positive: no base64 overhead for images.
- Positive: can use platform image/audio decoders directly.
- Positive: deletion is straightforward.
- Negative: backup/restore must include file directory.
- Mitigation: plain and encrypted backups will package files alongside database export.
