# Blinking App — Gap Analysis

Tracks the delta between `PROJECT_PLAN.md` and the actual codebase.
Last updated: **2026-03-01**

---

## ✅ Fixed — All Resolved

### 1. `AssistantScreen` references non-existent property → FIXED
Created `Schedule` model and added `schedules` getter to `RoutineProvider`.

### 2. `AssistantScreen` not wired into navigation → FIXED
Added as the 4th tab in the bottom navigation bar.

### 3. `Schedule` model missing → FIXED
Created `lib/models/schedule.dart`.

### 4. No local database (SharedPreferences only) → FIXED
Migrated all data to **SQLite** via `DatabaseService` with auto-migration from legacy prefs.

### 5. Push notifications not implemented → FIXED
`NotificationService` using `flutter_local_notifications` with timezone support. Synced to routine lifecycle.

### 6. Media files stored as local paths only → FIXED
`FileService` copies captured media to internal documents directory. DB stores relative paths.

### 7. Android JVM / Kotlin Gradle errors → FIXED
- Moved `compilerOptions {}` out of `android {}` into top-level `kotlin {}` block (`app/build.gradle.kts`)
- Removed `options.release.set(17)` from `JavaCompile` tasks (`build.gradle.kts`) — blocked by AGP
- `flutter build apk --debug` passes cleanly ✅

### 8. settings_screen.dart broken (would not compile) → FIXED
File was missing `package:flutter/material.dart` and `package:provider/provider.dart` imports, had
orphaned closing parentheses, and a missing closing `}` for `_showAddLlmDialog`. Rewrote the file
with all fixes applied.

### 9. LLM API keys lost on app restart → FIXED
`_llmProviders` list was held only in widget state. Added `initState() → _loadLlmSettings()` and
`_saveLlmSettings()` backed by SharedPreferences (`llm_providers`, `llm_selected_index`). Keys and
selected provider now survive restarts.

### 10. Language switching non-functional → FIXED
`LocaleProvider.setLocale()` correctly saves to SharedPreferences, but `loadLocale()` was never
called on startup. Fixed in `app.dart` by calling `provider.loadLocale()` inside the
`ChangeNotifierProvider` create callback. Language selection now persists across restarts.

### 11. Search not wired in Moment screen → FIXED
`TextField.onChanged` now calls `setState(() => _searchQuery = value.trim())`. Entries are filtered
case-insensitively on content in `_buildEntryList`. Added a clear button when search is active.

### 12. Tag filter not implemented in Moment screen → FIXED
The "标签" chip now opens a tag picker dialog (`_showTagPicker()`). Selected tag is stored in
`_tagFilterId` and applied in `_buildEntryList` via `entry.tagIds.contains(_tagFilterId)`. Chips
deselect correctly on repeated tap.

### 13. Entry detail / edit view missing → FIXED
`moment_screen.dart` `onTap` navigates to `AddEntryScreen(existingEntry: entry)`, which loads the
existing content, media, and tags and saves updates via `entryProvider.updateEntry()`.

### 14. CSV export missing → FIXED
`ExportService.exportCsv()` is implemented (uses `csv_utils.dart`). The Settings screen wires it
via `_handleExportCsv()` → `exportService.shareFile()`.

### 15. Backup / restore has no import UI → FIXED
`_handleRestore()` in Settings screen uses `FilePicker` to pick a `.zip` or `.json` file, calls
`StorageService.restoreFromBackup()`, then reloads all providers. Full round-trip works.

### 16. Duplicate `AppProvider` causes data inconsistency risk → FIXED
`lib/providers/app_provider.dart` deleted. Settings screen already used `TagProvider` directly;
all other screens use specialized providers. No cross-provider state inconsistency possible.

### 17. `CompletionLog` model orphaned → FIXED
`lib/models/completion_log.dart` deleted. Removed its export from `lib/models/models.dart`.
`Routine` uses its inline `RoutineCompletion` as the canonical completion type.

---

## 🔴 Open — Not Implemented

### A. Firebase / Cloud Sync
All four Firebase dependencies are commented out in `pubspec.yaml`. No Firebase initialization,
auth, Firestore, or cloud storage. The Settings screen has no sync toggle (it was a no-op stub
and was removed). Cloud sync is explicitly deferred to a future phase.

**Files affected:** `pubspec.yaml` (deps), would need `core/services/sync_service.dart` (new)

---

### B. Real AI / LLM calls in Assistant screen
`AssistantScreen._sendMessage()` returns the same hardcoded string to every message:
> *"收到您的消息！AI功能将在后续版本中完善。"*

The LLM provider config (name, model, API key, base URL) is now persisted in Settings, but no
HTTP client or LLM SDK is wired into the assistant. The config exists; the call does not.

**File:** `lib/screens/assistant/assistant_screen.dart`
**Fix needed:** Read selected provider from SharedPreferences, make HTTP POST to `baseUrl` with
the API key, parse streaming or batch response.

---

### C. No tests
Only the default `test/widget_test.dart` placeholder (`1 + 1 == 2`) exists.
48 source files have zero test coverage: models, providers, repositories, services, and screens.

---

## Summary Table

| Feature | Status | Notes |
|---------|--------|-------|
| Local storage (SQLite) | ✅ Done | Auto-migrates from SharedPreferences |
| Push notifications | ✅ Done | Synced with routine lifecycle |
| Media persistence | ✅ Done | FileService copies to internal storage |
| Home / Calendar screen | ✅ Done | — |
| Moment screen — search | ✅ Done | Live filter on content |
| Moment screen — tag filter | ✅ Done | Tag picker dialog |
| Moment screen — date filter | ✅ Done | Today / This week chips |
| Add / Edit Entry screen | ✅ Done | Text, image, audio, video; edit existing |
| Routines screen | ✅ Done | Daily check-in, counter routines |
| Settings — tag management | ✅ Done | CRUD via TagProvider |
| Settings — language switching | ✅ Done | Persisted via SharedPreferences |
| Settings — LLM config | ✅ Done | API keys persisted across restarts |
| JSON export + share | ✅ Done | ExportService + share_plus |
| CSV export + share | ✅ Done | csv_utils + ExportService + share_plus |
| ZIP backup + restore | ✅ Done | FilePicker import, full data round-trip |
| Gradle / APK build | ✅ Done | `flutter build apk --debug` clean |
| Cloud sync (Firebase) | ❌ Deferred | Deps commented out |
| AI / LLM responses | ❌ Stub | Config ready, HTTP calls not wired |
| Unit / integration tests | ❌ Missing | Placeholder only |
