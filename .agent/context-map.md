# Context Map

## Core Files

| File | Purpose | Lines |
|---|---|---|
| `lib/app_store.dart` | Monolithic store — models, persistence, state, settings | 1442 |
| `lib/app_shell.dart` | Shell — navigation, overlays, lifecycle, sea wiring | 1149 |
| `lib/analysis_engine.dart` | Local analysis — mood, text, prompt, seasons | 973 |
| `lib/text_lexicons.dart` | Lexicons — sentiment, themes, crisis, stop words, undertow | 2717 |
| `lib/currents_engine.dart` | Currents engine | 375 |
| `lib/currents_surfaces.dart` | Currents UI cards | 854 |
| `lib/sea_painter.dart` | Sea rendering | 589 |

## Feature Screens

| File | Purpose | Lines |
|---|---|---|
| `lib/settings_screen.dart` | Settings screen | 1384 |
| `lib/tide_lab_screen.dart` | Tide Lab screen | 1047 |
| `lib/mood_selector_screen.dart` | Mood selector | 988 |
| `lib/journal_editor.dart` | Journal editor | 964 |
| `lib/journal_home_screen.dart` | Journal home | 733 |
| `lib/home_screen.dart` | Home screen | 685 |
| `lib/calendar_screen.dart` | Calendar screen | 669 |
| `lib/insight_screen.dart` | Insight screen | 548 |
| `lib/welcome_screen.dart` | Onboarding screens | 521 |

## Key Services

| File | Purpose | Lines |
|---|---|---|
| `lib/ai_service.dart` | Optional AI gateway | 291 |
| `lib/notification_service.dart` | Local notifications | 128 |
| `lib/voice_transcription_service.dart` | Voice transcription | 146 |
| `lib/_shared/services/settings_repository.dart` | SharedPreferences layer | 130 |
| `lib/_shared/services/attachment_service.dart` | Image picker/compression | 102 |
| `lib/core/locator.dart` | get_it configuration | 40 |

## Managers

| File | Purpose | Lines |
|---|---|---|
| `lib/core/navigation_manager.dart` | Screen navigation state | 114 |
| `lib/core/sea_manager.dart` | Sea animation state | 190 |
