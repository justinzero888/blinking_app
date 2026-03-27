# Session Summary — 2026-03-16

## Completed Tasks

### Phase 1 — Habit system overhaul (v1.0.4 · 78d2c7b) ✅ TESTED
- Extended `RoutineFrequency`: `daily | weekly | scheduled | adhoc`
- Added `scheduledDaysOfWeek: List<int>?` and `scheduledDate: DateTime?` to `Routine` model
- DB v4→v5: routine scheduling columns
- `getRoutinesForDate(DateTime)` replaces `getActiveRoutinesForToday()`
- `isMissedOn(Routine, DateTime)` pure derivation (no DB column)
- `RoutineScreen` rewrite: 3-tab (全部 / 今日 / 记录), new add/edit dialog
- `CalendarWidget.dayHabitStatus` — mini `LinearProgressIndicator` per cell
- `HomeScreen`: completed habits → single green ✓ icon row; past pending → single red ✗ icon row

### Phase 2–4 — Card enhancements, sharing, AI personalization (v1.0.5 · 7bb251c) ✅ TESTED
- `CardTemplate.customImagePath` — user-uploaded background
- `NoteCard.aiSummary` — AI-generated display text (originals preserved)
- DB v5→v6: `custom_image_path` on templates, `ai_summary` on note_cards
- `CardBuilderDialog`: edit mode, AI merge toggle, `_TemplateEditorSheet`
- `CardProvider.updateCard()`, `copyBuiltInTemplate()`
- `CardsTab`: long-press → Edit/Share/Delete menu
- `EntryCard` share button; card share PNG via `share_plus`
- Settings "AI 个性化": name + personality → SharedPreferences
- `AssistantScreen` dynamic system prompt; AppBar shows custom name
- `FloatingRobotWidget`: pulse idle + wave-on-tap (3 `AnimationController`s)

### Bug fixes (deaaa89) ✅
- **DB migration bug**: `ai_summary`/`custom_image_path` were missing for users upgrading from v5 (Phase 1 APK). Fixed by bumping to v6 with correct `< 6` block; removed Phase 2 columns from `< 4` CREATE TABLE.
- **Card tap**: Added `onTap` → `_viewCard()` dialog with `_CardFullView`
- **Image upload hang**: Added `READ_MEDIA_IMAGES` + `READ_EXTERNAL_STORAGE` to `AndroidManifest.xml`

### Rich card editor (v1.0.6 · ddf89d5 + 85f8dbf) ✅ TESTED
- `NoteCard.richContent: String?` — Quill Delta JSON; DB v6→v7
- **`CardEditorScreen`** (new): full-screen flutter_quill editor
  - Bold / italic / underline / font size / text color / undo / redo / clear format
  - Image insert: gallery → `card_images/` → `BlockEmbed.image()` + `_LocalImageEmbedBuilder`
  - Word counter (X / 100 字); mixed CJK+English; save disabled when >100
  - Saves `richContent` (Delta JSON) + `aiSummary` (plain text mirror)
- `CardsTab`: tap → `CardEditorScreen` (replaced view dialog)
- `CardBuilderDialog`: AI prompt updated to `不超过100个字`; word counter added
- `CardRenderer._extractPlainText()`: `richContent > aiSummary > entry.content`
- **Localizations fix**: `FlutterQuillLocalizations.delegate` added to `MaterialApp.localizationsDelegates` in `app.dart` (required by flutter_quill; without it `QuillEditor` throws `UnimplementedError`)

---

## Pending Items

| Priority | Item | Notes |
|----------|------|-------|
| P2 | Wire image picker → entry media | `FileService` exists; `_recordMedia()` is snackbar stub |
| P2 | Audio recording | `flutter_sound ^9.16.3` in pubspec; stub only |
| P2 | Dedicated entry detail / read-only view | `AddEntryScreen` reused for editing via onTap |
| P3 | Firebase / Cloud Sync | Deps commented out in pubspec |
| P3 | Tests | Single placeholder test |
| P3 | CSV export UI | `csv_utils.dart` exists; no trigger |
| P3 | Backup import UI | `ExportService` import logic exists; no screen |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `AppProvider` deleted | Dead code; caused data inconsistency risk |
| DB sequential `if (oldVersion < N)` blocks | Handles all upgrade paths without branching |
| LLM config: merge-on-load | Preserves user API keys across app updates |
| `tag_reflection` id is stable | Hardcoded in `AssistantScreen._saveReflection()` |
| `richContent` + `aiSummary` both saved | `richContent` = canonical Delta JSON; `aiSummary` = plain-text mirror for grid thumbnails and backwards compat |
| Built-in template → copy-on-write | `copyBuiltInTemplate()` creates `isBuiltIn: false` copy |
| `note_card_entries` immutable | Original diary entries never altered by card operations |
| `FlutterQuillLocalizations.delegate` in `app.dart` | Must be in `MaterialApp.localizationsDelegates`; spread pattern preserves existing delegates |
| Word count = CJK chars + English tokens | Mixed-language fairness; both Chinese and English users get full 100-word capacity |

---

## DB Version History

| Version | Block | Changes |
|---------|-------|---------|
| 1 | initial | entries, routines, tags, completions |
| 2 | `< 2` | entries.metadata_json, routines.description |
| 3 | `< 3` | entries.emotion, routines.category |
| 4 | `< 4` | card_folders, templates, note_cards, note_card_entries tables |
| 5 | `< 5` | routines.scheduled_days_of_week, routines.scheduled_date |
| 6 | `< 6` | templates.custom_image_path, note_cards.ai_summary |
| 7 | `< 7` | note_cards.rich_content |

## Build Artifacts

| Version | Commit | APK |
|---------|--------|-----|
| v1.0.4 | 78d2c7b | Phase 1 habit overhaul |
| v1.0.5 | 7bb251c | Phases 2–4 (latest pre-v1.0.6) |
| v1.0.6 | 85f8dbf | Rich editor + bug fixes (latest) |
