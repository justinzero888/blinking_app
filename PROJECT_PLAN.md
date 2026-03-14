# Blinking App (记忆闪烁) - Project Plan

## 📱 App Overview
- **Name**: Blinking (记忆闪烁)
- **Type**: Personal memory capture app
- **Framework**: Flutter
- **Platforms**: Android (iOS future)

## 🎯 Goals
- Capture memories: text, audio, video, image
- Track daily routines
- AI-powered summaries and reminders
- Local + cloud sync
- Multi-language (Chinese/English)

## 📊 Project Status

### ✅ Completed Screens
| # | Screen | Description | Status |
|---|--------|-------------|--------|
| 1 | Home/Calendar | Monthly calendar + today's overview | ✅ Working |
| 2 | Moment/Timeline | Entries grouped by date, search + tag/date filter | ✅ Working |
| 3 | Add/Edit Entry | Create or edit memory (text/audio/video/image) | ✅ Working |
| 4 | Routines | Daily habits tracking with completions | ✅ Working |
| 5 | Settings | Tags, language, LLM config, export/import | ✅ Working |

### 🔄 Remaining Screens
| # | Screen | Description | Status |
|---|--------|-------------|--------|
| 6 | AI Assistant | Daily reminders, summaries, real LLM calls | ⏳ Stub only |

## 🛠 Technical Architecture

### Folder Structure
```
lib/
├── main.dart              # Entry point
├── app.dart               # App configuration + provider tree
├── core/                  # Core modules
│   ├── config/            # Theme, constants
│   ├── services/          # Storage, export, file, notification
│   ├── utils/             # CSV utils, helpers
│   └── extensions/        # Extensions
├── l10n/                  # Localization (zh/en)
├── models/                # Entry, Tag, Routine, Media, Schedule
├── repositories/          # Data access layer
├── providers/             # EntryProvider, TagProvider, RoutineProvider,
│                          # LocaleProvider, ThemeProvider
├── screens/               # UI screens
└── widgets/               # Reusable widgets
```

### Data Model
- **Entry**: id, type, content, mediaUrls[], tagIds[], createdAt, updatedAt
- **Tag**: id, name, nameEn, color, category
- **Media**: id, entryId, type, localPath, cloudUrl
- **Routine**: id, name, frequency, reminderTime, isActive, completionLog[]
- **Schedule**: id, routineId, scheduledDate, completedAt, notes

## 📅 Development Timeline

### Phase 1: Core Routine (MVP)
- [x] Fix Add Entry screen provider issue
- [x] Implement Routines screen
- [x] Daily check-in functionality (date-specific tracking)
- [x] Local storage with SQLite
- [x] Multimedia storage (copied to app-internal directory)
- [x] Push notifications for reminders
- [x] History view (Calendar integration)
- [x] JSON export + share
- [x] CSV export + share
- [x] Backup (ZIP) + restore (file picker import)

### Phase 2: Free-form Entries
- [x] Complete Add Entry functionality (media capture & persistence)
- [x] Audio recording via FlutterSound
- [x] Multimedia preview (open image/video/audio in external apps)
- [x] Tag management (CRUD in Settings, filter in Moment screen)
- [x] Tag filter in Moment screen (tag picker dialog)
- [x] Live search in Moment screen
- [x] Entry detail/edit (tap entry → AddEntryScreen with existingEntry)
- [x] Language switching (Chinese/English, persisted across restarts)
- [x] LLM provider config persisted across restarts (API keys saved)
- [ ] Cloud sync (Firebase)

### Phase 3: AI Features
- [ ] Real LLM API calls (provider config exists, calls not wired)
- [ ] Daily summaries
- [ ] Weekly/monthly reports
- [ ] Reflection prompts

## 🔧 Environment Setup

### Key Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| Flutter | 3.x | Framework |
| provider | ^6.0.0 | State management |
| sqflite | ^2.3.0 | Local database (SQLite) |
| path_provider | ^2.1.0 | File paths |
| shared_preferences | ^2.x | Settings / LLM config persistence |
| image_picker | ^1.0.0 | Media capture |
| flutter_sound | ^9.16.3 | Audio recording |
| flutter_local_notifications | ^x.x.x | Routine reminders |
| share_plus | ^x.x.x | File sharing for exports |
| archive | ^x.x.x | ZIP backup |
| file_picker | ^x.x.x | Restore from backup |
| flutter_localizations | SDK | i18n |
| intl | ^0.18.0 | Date/number formatting |

> Firebase deps are commented out in pubspec.yaml — cloud sync deferred.

### Build Tools
- **Java**: OpenJDK 17
- **Kotlin**: 2.2.20
- **Android SDK**: Target SDK 34
- **Gradle**: 8.14
- **Build**: `flutter build apk --debug` — clean ✅

## 📋 Known Issues

### Open (Not Yet Implemented)
- [ ] Firebase / Cloud Sync — all deps commented out, sync toggle is a no-op
- [ ] Real AI responses — AssistantScreen returns a hardcoded string
- [ ] Unit / integration tests — only a placeholder test file exists

### Resolved
- [x] Add Entry screen: Provider error
- [x] SQLite migration from SharedPreferences
- [x] Media persistence (FileService internal copy)
- [x] Gradle build failures (compilerOptions DSL, JavaCompile --release flag)
- [x] settings_screen.dart: missing Flutter imports, syntax errors, unclosed method
- [x] LLM API keys lost on restart (now persisted via SharedPreferences)
- [x] Language setting lost on restart (LocaleProvider.loadLocale() called on init)
- [x] Search and tag filter unwired in Moment screen
- [x] Duplicate AppProvider (deleted — specialized providers are canonical)
- [x] Orphaned CompletionLog model (deleted)

## 🎯 Next Steps

1. Wire real LLM calls in AssistantScreen using the persisted provider config
2. Firebase project setup + cloud sync implementation
3. Write unit tests for providers, repositories, and storage service
4. iOS build configuration

## 📞 Contact
- Developer: Justin
- Platform: Telegram
