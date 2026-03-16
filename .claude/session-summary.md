# Session Summary — 2026-03-15

## Completed Tasks

### Phase 1 — Habit system overhaul (v1.0.4 · 78d2c7b) ✅ TESTED
- Extended `RoutineFrequency` enum: `daily | weekly | scheduled | adhoc` (removed `custom`)
- Added `scheduledDaysOfWeek: List<int>?` and `scheduledDate: DateTime?` to `Routine` model
- DB migration v4 → v5: `ALTER TABLE routines ADD COLUMN scheduled_days_of_week TEXT`, `ADD COLUMN scheduled_date TEXT`
- `getRoutinesForDate(DateTime)` replaces `getActiveRoutinesForToday()` in `RoutineProvider`
- `isMissedOn(Routine, DateTime)` pure derivation helper (no extra DB column)
- `RoutineScreen` full rewrite: `DefaultTabController(length: 3)` — 全部 / 今日 / 记录
  - 全部: active/paused groups, frequency badge, popup menu (edit/pause/delete)
  - 今日: auto-populated checklist, completed section, "手动加入" for adhoc
  - 记录: flat reverse-chronological 60-day list, read-only ✓/✗ per routine
  - Add/edit dialog: frequency dropdown → day-chip picker (weekly) or date picker (scheduled)
- `CalendarWidget` gains `dayHabitStatus: Map<DateTime, ({int completed, int total})>` — mini `LinearProgressIndicator` per cell
- `HomeScreen._getDayHabitStatus()` computes per-day habit completion, passes to `CalendarWidget`
- Post-release UI fixes:
  - Completed habits consolidated into one green ✓ icon row (no text)
  - Past uncompleted habits consolidated into one red ✗ icon row (no text)

### Phase 2 — Card enhancements (v1.0.5 · 7bb251c) ✅ TESTED
- `CardTemplate.customImagePath: String?` — user-uploaded background image
- `NoteCard.aiSummary: String?` — AI-generated display text (originals preserved in `note_card_entries`)
- DB v5 additions (same `if (oldVersion < 5)` block): `custom_image_path` on templates, `ai_summary` on note_cards
- `StorageService.updateNoteCard()` added; `getNoteCards()` / `addNoteCard()` propagate new fields
- `CardProvider.updateCard(NoteCard)` and `copyBuiltInTemplate(CardTemplate)` added
- `CardRenderer`: conditional `DecorationImage(FileImage(...))` vs solid bgColor; renders `aiSummary ?? firstEntry.content`
- `CardBuilderDialog` full rewrite: edit mode (pre-fills from existingCard), content mode toggle (原文 / AI 生成), LlmService call for merge, `_TemplateEditorSheet` (name, bgColor cycle, image upload via ImagePicker)
- `CardsTab` full rewrite: long-press → Edit / Share / Delete bottom sheet; `_CardTile` supports customImagePath background

### Phase 3 — Social sharing (v1.0.5 · 7bb251c) ✅ TESTED
- `EntryCard`: share button (top-right) via `share_plus` — `Share.share(entry.content)`
- `CardsTab`: share rendered PNG via `Share.shareXFiles([XFile(card.renderedImagePath!)])`
- Both use OS system share sheet (WeChat, Telegram, etc. available automatically)

### Phase 4 — AI personalization (v1.0.5 · 7bb251c) ✅ TESTED
- `Settings` — new "AI 个性化" section: name TextField + personality TextField, saved to SharedPreferences keys `ai_assistant_name` / `ai_assistant_personality`
- `AssistantScreen`: dynamic `_systemPrompt` getter reads name/personality; AppBar title shows custom name
- `FloatingRobotWidget`: `TickerProviderStateMixin`; added `_pulseController` (3000ms idle scale 1.0→1.05) and `_waveController` (500ms rotation TweenSequence on every tap)

---

## Pending Items

| Priority | Item | Notes |
|----------|------|-------|
| P2 | Wire image picker → `FileService.saveFile()` → `entry.mediaUrls` → display in `EntryCard` | `FileService` exists; `add_entry_screen.dart` shows snackbar only |
| P2 | Implement audio recording with `flutter_sound` | `flutter_sound ^9.16.3` in pubspec; `_recordAudio()` is a snackbar stub |
| P2 | Dedicated entry detail / read-only view | `AddEntryScreen` is reused for editing via onTap — no standalone detail view |
| P3 | Firebase / Cloud Sync | All deps commented out in pubspec; Settings sync toggle is no-op |
| P3 | Tests | Single `1+1=2` placeholder; 50+ source files untested |
| P3 | CSV export UI | `csv_utils.dart` exists; no screen triggers it |
| P3 | Backup import UI | `ExportService` import logic exists; no screen calls it |

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| AI tab replaced by floating robot | PM directive — keeps nav clean; robot always accessible as overlay |
| `AppProvider` deleted | Dead code duplicating EntryProvider/TagProvider/RoutineProvider; caused data inconsistency risk |
| DB version 5, sequential `if (oldVersion < N)` blocks | Handles all upgrade paths without branching; Phase 1 + Phase 2 both in same `if (oldVersion < 5)` block |
| LLM config: merge-on-load strategy | Preserves user API keys while appending new default providers added in later releases |
| `tag_reflection` id is stable | Hardcoded in `AssistantScreen._saveReflection()`; must not be renamed |
| No image generation API | PM decision — AI returns text only; jar tint derived from keyword-to-color map |
| `CardTemplate` uses solid `bgColor` (hex) + optional `customImagePath` | Designer assets not available; user can upload own image |
| Emotion encoded as score 1–5 for LineChart | 😊=5 😌=4 😐=3 😢=2 😡=1; missing defaults to 3 (neutral) |
| Missed habit = pure derivation | `date < today && !isCompletedOn(date) && scheduled` — no extra DB column |
| Built-in template edit → copy-on-write | `copyBuiltInTemplate()` creates `isBuiltIn: false` copy; original never mutated |
| `NoteCard.aiSummary` for display only | Original entries in `note_card_entries` never altered by card operations |
| `TickerProviderStateMixin` in FloatingRobotWidget | Required for multiple AnimationControllers (bob + pulse + wave) |

---

## Build Artifacts

| Version | Commit | APK |
|---------|--------|-----|
| v1.0.0 | 42b23e4 | Initial release |
| v1.0.1 | bc3d826 | Emotion picker, routine categories |
| v1.0.2 | 1ea1f96 | Floating robot, LlmService |
| v1.0.3 | a99adc6 | Jar, cards, summary (latest built APK prior to this session) |
| v1.0.4 | 78d2c7b | Phase 1 — habit system overhaul |
| v1.0.5 | 7bb251c | Phases 2–4 — card edit/AI/sharing/personalization (latest built APK) |
