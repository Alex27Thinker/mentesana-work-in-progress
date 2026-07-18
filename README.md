
Works on mobile, desktop, and web targets.

## What's ported 1:1

### Check-in (mood selector)
- **Inner water field** (`SeaPainter`): the exact `draw()` pipeline — drifting upper-field gradient with chroma pulse, two travelling light pools, broad water-emergence dissolve, four swell layers, per-layer crest sheen, coherence marks, curvature-gated foam. All wave math copied constant-for-constant.
- **Circumplex palettes + bilerp**, the 16 anchored words with hysteresis, felt phrases, the SHADES editor, "your own word", drag field, hesitation ring, and the keep flow with the shared ~5.8s breath.
- The full shell integration: earlier-weather trace, "this is where you were — visiting" (revisit), the after-writing check ("after writing, this feels" / "the page has landed"), "say more", and the journaled subline.

### Journal editor
- The writing sheet over the check-in: mood pages and free pages ("a page for whatever is here — no weather required."), title, body, the stuck line, tag (≤18 chars), the tide bottle, attachments (cap 3 · 2.5 MB), versions (last 5), the safety line, drafts saved as you write, and the keep flow with 'kept.'
- The pivot invitation (>360 chars, low-valence, high-arousal), word count, "this page never leaves your device."

### Journal home
- Greeting (cased, i18n), the return card (≥5 quiet days — "welcome back."), today-so-far continuity ("continue this page" / "new page"), the daily prompt card with "try another angle", "not today" (per-day dismiss) and the anchor-write button, the prompt library card, unfinished draft, recent pages (3, with attachment counts), "all pages in the archive", and the tide (returned / holding).

### Prompt library, calendar, archive
- The library's themed prompt sets, with the AI daily prompt woven in when enabled.
- Calendar month (dots, today ring, has-entry border), week (columns sized by writing), and day (the ribbon of the day's pages along a 24h line) — with the exact empty-state lines.
- The archive as the sea, deeper: pages grouped by month, mood-only entries as driftwood, search by word/tag/title.

### Entry detail
- The full reading room: weather line, texture, tag, versions ("an earlier version of this page" with restore), attachments, distance ("from here, it reads differently"), re-reading counter, revisit-this-weather, duplicate-as-new-page, export (clipboard), and the two-step delete (arm — 'sure? tap again' — with the 9s disarm).

### Weekly insight
- One letter, in prose: the week's weather described (never charted), correlation-only phrasing, evidence lines from your own pages, the thin-data line, and the AI letter (when enabled) replacing the local one — post-filtered against forbidden language.

### Onboarding (welcome)
- The seven-stage ritual with every stage's copy verbatim, back circle, 1px progress line, skip → home, 700ms leaving fade, and both starts ("name the weather" → check-in, "write a page" → the free journal). Replayable from settings (testing mode persists nothing).

### Home
- Masthead, the day's weather, the breathing check-in lens (4-hour decay, fresh-session size, pressure-ring ripple, 420ms dissolve), `write another page` / `a page, without a weather`, the doors (archive · this week), and "on this day".
- The ambient sea behind Home, tinted by the kept mood with soft `.085` colour inertia; other screens darken with depth (`SCREEN_DEPTH`).

### Settings
- The icon-led menu and every detail section row-for-row (notifications, appearance, account, privacy incl. the PIN flow, your pages, journal preferences, deeper reflection, about), verbatim strings, the quiet toast, day rooms.

### Persistence & AI
- `app_store.dart` mirrors the prototype's localStorage layer key-for-key via `shared_preferences`, including the full entry shape `{ts, v, a, word, edited, text, title, prompt, tag, tideLine, tideAt, wordCount, attachments, versions, moodTs, texture, reflectionStep, after*}`.
- `ai_service.dart` mirrors `/api/ai-insight`: same system prompts, same post-filter, weekly letter + daily prompt. Point it at your deployed proxy with `--dart-define=MENTESANA_AI_PROXY=https://…/api/ai-insight`; without it, AI stays quietly off and the local engine writes the letter.

## Documented deviations

- **Export** (entry · text · JSON) copies to the clipboard; the print/PDF path answers 'copied — printing needs a browser.' No share/file plugin in this pass.
- **Import from file** is not yet ported; it answers with a quiet note.
- **Attachments / voice notes**: no camera-roll or microphone plumbing yet — the buttons answer in the prototype's own tone (quiet statuses), and audio attachments list without playback.
- **Reminders** fire as in-app quiet notes on a 30s check while the app is open. No system notifications yet.
- **Time inputs and selects**: inline HH:MM fields and tap-to-cycle values — the doctrine forbids native dialogs.
- **Scrolling** is native Flutter physics; the web's scroll positions are not preserved across screens.
- Lens inner shadow approximated with radial gradients; **font**: Alice via `google_fonts` (italic synthesized). Bundle the ttf as an asset for offline builds.
- The depth ambience (body class → CSS filter) is approximated with a per-screen darkened gradient behind the content.

## Files

- `lib/main.dart` — entry point (loads the store, hands off to the shell)
- `lib/app_shell.dart` — phone shell: routing + depth, ambient sea, bottom nav, journal editor overlay, write invite, post-journal prompt, PIN veil, onboarding boot, reminders, quiet notes
- `lib/app_store.dart` — persistence (localStorage keys 1:1), entries, drafts, i18n, reminders
- `lib/text_lexicons.dart` — the prototype's full text lexicons (verbatim)
- `lib/analysis_engine.dart` — the local prompt/insight engine (`PromptEngine`)
- `lib/ai_service.dart` — the AI proxy client (weekly letter, daily prompt, post-filter)
- `lib/journal_prompts.dart` — prompts, greeting, rich text spans, date helpers
- `lib/journal_editor.dart` — the writing sheet
- `lib/journal_home_screen.dart` — the journal's front room
- `lib/prompt_library_screen.dart` — the prompt library
- `lib/calendar_screen.dart` — month / week / day
- `lib/archive_screen.dart` — the archive
- `lib/entry_detail_screen.dart` — the reading room
- `lib/insight_screen.dart` — the weekly letter
- `lib/lock_screen.dart` — the PIN veil
- `lib/home_screen.dart` — home
- `lib/settings_screen.dart` — settings
- `lib/welcome_screen.dart` — onboarding
- `lib/sea_icons.dart` — SVG path-data parser + the prototype's stroke icons
- `lib/mood_palette.dart` — palettes, bilerp, words, shades, felt phrases, breath constants
- `lib/sea_painter.dart` — the water field (`CustomPainter`)
- `lib/mood_selector_screen.dart` — the check-in screen
