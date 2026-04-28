# Blinking App (记忆闪烁) - Project Plan

## App Overview
- **Name**: Blinking (记忆闪烁)
- **Type**: Personal memory capture app
- **Framework**: Flutter
- **Platforms**: Android (iOS future)
- **Current Version**: 1.1.0-beta.3+18

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

### Remaining / Blocked
| # | Item | Status |
|---|------|--------|
| 1 | Firebase / Cloud Sync | Not started — deps commented out |
| 2 | iOS build | Blocked — Flutter upgrade required for Xcode 26 deprecated API fix; see infrastructure upgrade plan |
| 3 | Chorus social feature | In progress — ChorusService + PostToChorusSheet added, wired to EntryDetail |
| 4 | Custom emoji images E-1/E-2 | Deferred from v1.1.0 beta |
| 5 | Card generation AI multi-design suggestions | Deferred from v1.1.0 beta |

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

### Database Schema (v10)
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

## Development History

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
flutter test                          # 56 tests
flutter analyze --no-pub              # 0 errors
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

## Known Issues

### Open
- Firebase / Cloud Sync — all deps commented out, sync toggle is a no-op
- iOS build — blocked on Flutter upgrade for Xcode 26 deprecated API fix (Xcode 26.4.1 available; Flutter stable fix pending)
- Chorus feature — service + sheet exist but backend API not confirmed

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

## Next Steps

1. Submit Android v1.1.0-beta.3+18 AAB to Google Play (Internal Testing → Production)
2. Confirm Chorus backend API and complete PostToChorusSheet integration
3. Firebase project setup + cloud sync implementation
4. Entry detail read-only view polish

## Active Plans

| Plan | Status | Link |
|------|--------|------|
| Infrastructure Upgrade & iOS Release | DRAFT — awaiting Flutter stable + Xcode 26 | [2026-04-28-infrastructure-upgrade-ios-release.md](docs/plans/2026-04-28-infrastructure-upgrade-ios-release.md) |

## Contact
- Developer: Justin
- Feedback: blinkingfeedback@gmail.com
