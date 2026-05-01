# Blinking App (记忆闪烁) - Project Plan

## App Overview
- **Name**: Blinking (记忆闪烁)
- **Type**: Personal memory capture app
- **Framework**: Flutter
- **Platforms**: Android (iOS future)
- **Current Version**: 1.1.0-beta.5+20

## Goals
- Capture memories: text, audio, video, image
- Track daily routines
- AI-powered summaries and reminders
- Local + cloud sync
- Multi-language (Chinese/English)

## Project Status

### Completed Screens
| # | Screen | Description | Status |
|---|--------|-------------|--------|
| 1 | Home/Calendar | Monthly calendar + today's overview | Working |
| 2 | Moment/Timeline | Entries grouped by date, search + tag/date filter | Working |
| 3 | Add/Edit Entry | Create or edit memory (text/image) | Working |
| 4 | Routines | Daily habits tracking with completions | Working |
| 5 | Cherished / Cards | Note cards with templates, folders, AI merge, rich editor | Working |
| 6 | Cherished / Shelf | Yearly emotion jars | Working |
| 7 | Cherished / Summary | Chart metrics (daily/weekly/monthly) | Working |
| 8 | Settings | Tags, language, LLM config, AI persona, export/import | Working |
| 9 | AI Assistant | Multi-turn LLM chat with Save Reflection | Working |
| 10 | Entry Detail | Read-only entry view with share + Post to Chorus | Working |

### Completed Features (beyond screens)
| # | Item | Status |
|---|------|--------|
| 1 | AI assistant (multi-turn LLM chat + Save Reflection) | Done |
| 2 | AI Secrets tag (exclude private notes from AI context) | Done |
| 3 | Bilingual UI (EN/ZH) | Done |
| 4 | Backup/Restore (ZIP + JSON) with progress bars | Done |
| 5 | Card share (PNG export) | Done |
| 6 | Chorus social posting (publish to blinkingchorus.com) | Done |
| 7 | Habit import/export (JSON) | Done |
| 8 | Legal docs (Privacy Policy + ToS) | Done |
| 9 | Note cards + rich editor (flutter_quill, 100-word limit) | Done |
| 10 | Card PNG cleanup (PROP-4) | Done |
| 11 | DB indexes v11 (PROP-5) | Done |
| 12 | Onboarding banner | Done |
| 13 | 7-Day Trial API key flow — full stack (PROP-6) | Done |

### Remaining / Blocked
| # | Item | Status |
|---|------|--------|
| 1 | Firebase / Cloud Sync | Not started — deps commented out |
| 2 | iOS release | Moved to separate project `ClaudeDev/system-upgrade` |
| 3 | Daily checklist entries (PROP-9) | Designed, planned — stretch goal for v1.1.1 |
| 4 | AI Secrets lock icon on entries (PROP-7) | UX polish ~1h |
| 5 | Keepsakes tab rename (PROP-8) | Wait for beta feedback |
| 6 | Custom emoji images E-1/E-2 | Deferred |
| 7 | Card generation AI multi-design suggestions | Deferred |

## Technical Architecture

### Folder Structure
```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration + provider tree
├── core/                  # Core modules
│   ├── config/            # Theme, constants
│   ├── services/          # Storage, export, file, LLM, Chorus
│   └── utils/             # Helpers
├── l10n/                  # Localization (zh/en .arb files)
├── models/                # Entry, Tag, Routine, CardTemplate, CardFolder, NoteCard
├── providers/             # EntryProvider, TagProvider, RoutineProvider,
│                          # LocaleProvider, ThemeProvider, CardProvider,
│                          # JarProvider, SummaryProvider, RoutineProvider
├── screens/               # UI screens
│   ├── cherished/         # Cards, shelf, summary, card editor/preview/builder
│   ├── chorus/            # PostToChorusSheet
│   ├── moment/            # Timeline, entry detail
│   ├── routine/           # Routine screen
│   ├── settings/          # Settings screen
│   └── assistant/         # AI assistant chat
└── widgets/               # EmojiJarWidget, CardRenderer, FloatingRobotWidget, etc.
```

### Database Schema (v11)
| Table | Key Fields |
|-------|-----------|
| `entries` | id, type, content, tagIds, emotion, createdAt |
| `routines` | id, name, frequency, scheduledDaysOfWeek, scheduledDate, reminderTime |
| `completions` | id, routineId, date |
| `tags` | id, name, nameEn, color |
| `templates` | id, name, icon, fontColor, bgColor, isBuiltIn, customImagePath, **source_template_id** |
| `card_folders` | id, name, isDefault |
| `note_cards` | id, folderId, templateId, content, richContent, aiSummary, renderedImagePath |
| `note_card_entries` | cardId, entryId |

## Launch Roadmap (Target: end of May 2026)

| Week | Window | Focus |
|------|--------|-------|
| 1–2 | May 1–14 | PROP-6 alpha test, Play Store upload, monitor trial usage |
| 3 | May 15–21 | PROP-9 (stretch goal) + PROP-7/PROP-8 polish |
| 4 | May 22–30 | Launch readiness: Play Store listing, beta crash triage, smoke tests, version bump, release build |

## Development History

### v1.1.0-beta.5+20 — 2026-04-30
- **PROP-6: 7-Day Trial API Key Flow (full stack)**
  - App-side: `DeviceService` (anonymous install UUID), `TrialService` (trial lifecycle with demo mode), Settings trial banner + provider entry + start flow, LLM service trial error handling, floating robot trial states, assistant expiry banner, i18n (13 new EN/ZH strings)
  - Backend: Cloudflare Workers (2 endpoints: `/api/trial/start`, `/api/trial/chat`), D1/KV storage, rate limiting (20 req/day), proxy to OpenRouter `qwen/qwen3.5-flash`, kill switch via Workers secret
  - Export/import: trial data excluded from backup/restore
- **Test results:** 94/94 passing
- **Build artifacts:** APK 70.5 MB, AAB 54.7 MB
- **Backend:** Deployed at `blinkingchorus.com`

### v1.1.0-beta.4+19 — 2026-04-29
- PROP-4: Card PNG cleanup (orphan file deletion on card/folder/template delete)
- PROP-5: DB indexes v11 (`entry_tags(entry_id)` + `note_card_entries(card_id)`)
- Calendar routine checklist simplified to 2-element layout
- Restore progress dialog with percentage and time estimate
- 93 tests passing

### v1.1.0-beta.3+18 — 2026-04-28
**Bug fixes:**
- Fixed template name locale mismatch: Create Card → Select Template → Edit Template → Template Name field was always showing Chinese names even under English locale. Root cause: `_TemplateEditorSheetState.initState` was seeding `_nameController` with the raw DB `name` field (always Chinese). Fix: added `isZh` parameter to `_TemplateEditorSheet` and switched `initState` to `template.displayNameFor(isZh)`.

**Test fixes (pre-existing failures resolved):**
- `emoji_jar_overflow_test.dart`: Two tests assumed `LocaleProvider` defaults to `'zh'`; it actually defaults to `'en'` (changed in a prior commit). Fixed: seeded Chinese locale via `SharedPreferences.setMockInitialValues` + `loadLocale()` for the zh-specific test; corrected expected string to `'Ask AI'` for the visibility test.
- `version_test.dart` / `constants.dart`: `AppConstants.appVersion` was stale at `'1.1.0-beta.2'`; bumped to `'1.1.0-beta.3'` to match pubspec.
- `settings_screen.dart`: Hardcoded version strings updated to `1.1.0-beta.3` (display subtitle + feedback email subject).

**Test results:** 56/56 passing

**Build artifacts:**
| Artifact | Result | Size |
|----------|--------|------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` | — |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` | 65.3 MB |
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` | 49.3 MB |

### v1.1.0-beta.3+18 — prior changes in this build
- **DB schema v10**: Added `source_template_id TEXT` column to `templates` table (migration in `onUpgrade`).
- **CardTemplate**: Added `sourceTemplateId` field; `displayNameFor(isZh)` now derives English name for copies of built-ins (e.g. "Custom — Spring Day").
- **CardFolder**: Added `displayNameFor(bool isZh)` — default folder renders as "My Cards" in English.
- **CardProvider**: `copyBuiltInTemplate()` now stores `sourceTemplateId` so copies can resolve their English display name.
- **EntryDetailScreen**: Added "Post to Chorus" icon button — opens `PostToChorusSheet` and shows a snackbar on success.
- **ChorusService**: New `lib/core/services/chorus_service.dart` (social publishing).
- **Chorus screen**: `lib/screens/chorus/` added with `PostToChorusSheet`.

### v1.1.0-beta.2+11 — fb79935 → 22776c8
- Adaptive icon, card fixes, font fill, feedback button, iOS xcassets fixes.

### v1.1.0-beta.1+9 — fb79935
- Public beta: bilingual UI, legal docs, emoji jar fix, habit import/export, card preview.

### v1.0.x
| Version | What |
|---------|------|
| v1.0.6 | Rich card editor (flutter_quill), 100-word limit, card tap → edit |
| v1.0.5 | Card edit/AI merge/template image, social sharing, AI personalization |
| v1.0.4 | Habit system overhaul (RoutineFrequency, 3-tab screen, calendar badges) |
| v1.0.3 | Jar, cards, summary + LLM merge fix |
| v1.0.2 | Floating robot, LlmService, AssistantScreen real LLM |
| v1.0.1 | Emotion picker, routine categories, calendar emoji |
| v1.0.0 | Initial release |

## Build Commands
```bash
flutter test                          # 94 tests
flutter analyze --no-pub              # 0 errors
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

## Known Issues

### Open
- Firebase / Cloud Sync — all deps commented out, sync toggle is a no-op
- iOS release — moved to separate project `ClaudeDev/system-upgrade` (requires Xcode 26)
- Daily checklist entries (PROP-9) — designed and planned, stretch goal for v1.1.1

### Resolved
- Template name field shows Chinese under English locale (fixed v1.1.0-beta.3)
- AppConstants.appVersion out of sync with pubspec (fixed v1.1.0-beta.3)
- Emoji jar test locale assumption wrong (fixed v1.1.0-beta.3)
- Add Entry screen: Provider error
- SQLite migration from SharedPreferences
- Media persistence (FileService internal copy)
- Gradle build failures (compilerOptions DSL, JavaCompile --release flag)
- LLM API keys lost on restart
- Language setting lost on restart
- Search and tag filter unwired in Moment screen
- Duplicate AppProvider (deleted)
- Card PNG orphan files on delete (PROP-4)
- DB performance on queries (PROP-5 indexes)
- 7-day trial API key flow (PROP-6 — full stack deployed)
- Flutter 3.41.2→3.41.8 upgrade (unblocks Xcode 26)

## Next Steps

1. Commit & push PROP-6 code to GitHub
2. Upload v1.1.0-beta.5+20 AAB to Google Play Console (Internal Testing → Production)
3. Monitor trial usage and OpenRouter costs during alpha soak
4. Week 3 gate: if PROP-6 stable, begin PROP-9 daily checklist (v1.1.1 stretch)
5. Week 4: launch readiness — Play Store listing, crash triage, smoke tests

## Active Plans

| Plan | Status | Link |
|------|--------|------|
| 7-Day Trial API Key Flow (PROP-6) | ✅ Complete — deployed | [2026-04-30-prop-6-trial-api-key-plan.md](docs/plans/2026-04-30-prop-6-trial-api-key-plan.md) |
| Daily Checklist Entry (PROP-9) | Design complete — stretch goal | [2026-04-30-prop-9-daily-checklist-plan.md](docs/plans/2026-04-30-prop-9-daily-checklist-plan.md) |
| iOS Release | Moved to ClaudeDev/system-upgrade | — |

## Contact
- Developer: Justin
- Feedback: blinkingfeedback@gmail.com
