# Implementation Plan — 2026-03-15 Feature Set

**Based on:** `docs/TODO-2026-03-15.md`
**Deferred:** WeChat native SDK, Rednote integration
**PM answers incorporated:** 2026-03-15
**Status:** Ready for implementation

---

## 1. Overview

Four phases, roughly in dependency order:

| Phase | Feature area | Size | New deps |
|-------|-------------|------|----------|
| 1 | Habit system overhaul | Large | — |
| 2 | Card enhancements | Medium | `image_picker` |
| 3 | Social sharing | Small | `share_plus` |
| 4 | AI personalization | Small | — |

**DB impact:** single migration block v4 → v5 covering all structural changes.

---

## 2. Phase 1 — Habit System Overhaul

### 2.1 New scheduling model

The current `RoutineFrequency` enum (`daily | weekly | custom`) has no way to express:
- "every Saturday" (weekly on a specific day)
- "Call AJ on March 20" (one-time scheduled date)
- "ad hoc" (user manually adds to any day)

**Changes to `Routine` model and DB:**

Add two nullable fields to `Routine`:
```dart
// Comma-separated weekday indices, 1=Mon … 7=Sun (ISO 8601)
// Used when frequency == weekly
final List<int>? scheduledDaysOfWeek;  // e.g. [6] = every Saturday

// Used when frequency == scheduled (one-time)
final DateTime? scheduledDate;         // e.g. 2026-03-20
```

Add new `RoutineFrequency` values:
```dart
enum RoutineFrequency {
  daily,      // every day (unchanged)
  weekly,     // every week on scheduledDaysOfWeek
  scheduled,  // one-time on scheduledDate  ← NEW
  adhoc,      // no auto-appearance; user adds manually per day ← NEW
}
```

**DB migration v4 → v5:**
```sql
ALTER TABLE routines ADD COLUMN scheduled_days_of_week TEXT;  -- JSON array, e.g. "[6]"
ALTER TABLE routines ADD COLUMN scheduled_date TEXT;           -- ISO8601 date
```

`fromJson` / `toJson` / `copyWith` updated accordingly. Existing daily/weekly routines unaffected (new columns nullable, default NULL).

---

### 2.2 Daily list auto-population

`RoutineProvider` currently has `getActiveRoutinesForToday()` which only returns `daily` routines. Replace with a general `getRoutinesForDate(DateTime date)`:

```dart
List<Routine> getRoutinesForDate(DateTime date) {
  final weekday = date.weekday; // 1=Mon … 7=Sun
  return _routines.where((r) {
    if (!r.isActive) return false;
    switch (r.frequency) {
      case RoutineFrequency.daily:
        return true;
      case RoutineFrequency.weekly:
        return r.scheduledDaysOfWeek?.contains(weekday) ?? false;
      case RoutineFrequency.scheduled:
        final sd = r.scheduledDate;
        return sd != null &&
            sd.year == date.year &&
            sd.month == date.month &&
            sd.day == date.day;
      case RoutineFrequency.adhoc:
        return false; // never auto-appears; manually triggered
    }
  }).toList();
}
```

`adhoc` routines appear in the **Available list** only; the user drags/adds them to a specific day manually (see UI section).

---

### 2.3 ✓ / ✗ display and immutability

**Missed derivation (no new DB column):**
A routine is "missed" for a date if:
- It was scheduled for that date (`getRoutinesForDate(date)` returns it), AND
- `date` is before today (the day is over), AND
- `routine.isCompletedOn(date)` is false

```dart
bool isMissedOn(Routine r, DateTime date) {
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final dateNorm  = DateTime(date.year,  date.month,  date.day);
  return dateNorm.isBefore(todayNorm) &&
         !r.isCompletedOn(date) &&
         getRoutinesForDate(date).any((x) => x.id == r.id);
}
```

**Immutability:**  Past days (date < today) are read-only. The check/uncheck tap gesture is disabled when rendering a past date. The UI displays ✓ (green `Icons.check_circle`) or ✗ (red `Icons.cancel`) as unchangeable icons.

Today's records remain fully interactive until midnight.

---

### 2.4 Three-panel UI redesign (`RoutineScreen`)

The screen gains a `DefaultTabController(length: 3)` tab bar:

```
┌─────────────────────────────────────┐
│  日常           [全部] [今日] [记录] │
├─────────────────────────────────────┤
│ Tab 1 — 全部 (Available list)        │
│   All habits grouped: 活跃 / 已暂停  │
│   Frequency badge on each tile       │
│   [+ 添加] in AppBar                │
│                                     │
│ Tab 2 — 今日 (Daily list)            │
│   Auto-populated via                 │
│     getRoutinesForDate(today)        │
│   ─ 待完成 ─                         │
│   [icon] Vitamin  every day  [  □  ]│
│   [icon] 5000步   every day  [  □  ]│
│   ─ 已完成 ─                        │
│   [✓] Meditation  (green, struck)   │
│   [手动加入] button → adhoc picker  │
│                                     │
│ Tab 3 — 记录 (History)              │
│   Flat reverse-chronological list   │
│   ─── 3月14日 (周五) ───             │
│   💊 维生素     ✓                   │
│   🏃 5000步     ✗                   │
│   ─── 3月13日 (周四) ───            │
│   ...                               │
│   Read-only; no tap on ✓/✗          │
└─────────────────────────────────────┘
```

**Tab 1 — 全部 (Available list)**
- Groups: 活跃 / 已暂停
- Frequency badge per tile: `每天` / `每周六` / `2026-03-20` / `随时`
- Edit / Pause / Delete via popup menu (unchanged flow)
- Add button opens enhanced dialog (see below)

**Tab 2 — 今日 (Daily list) — interactive**
- `getRoutinesForDate(DateTime.now())` drives the list
- Checking an item → calls `completeRoutine(id)` → item disappears from 待完成, appears in 已完成
- Unchecking → calls `unmarkRoutine(id)` → reverses
- "手动加入" opens a dialog listing `adhoc` + any routine not already in today's list
- Each pending tile: `[effectiveIcon]` emoji + name + frequency badge + checkbox

**Tab 3 — 记录 (History) — read-only**
- Flat `ListView` of last 60 days in reverse chronological order
- Days with no scheduled routines are omitted
- Per-day section header: `─── 3月14日 (周五) ───`
- Per-routine row: `effectiveIcon` + name + ✓ (green) or ✗ (red)
- ✓/✗ derived: `isCompletedOn(date)` → ✓; date < today && not completed → ✗
- No date picker; no interactive elements

**Add/edit dialog changes:**
```
Name:          [          ]
Frequency:     [每天 ▼]   (dropdown: 每天 / 每周 / 指定日期 / 随时)
  if 每周:    [一][二][三][四][五][六][日]  (multi-select day chips)
  if 指定日期: [Date picker → YYYY-MM-DD]
Reminder:      [HH:mm]  (optional)
Category:      [chip picker]  (unchanged)
```

**Calendar view — habit status overlay**
`HomeScreen` passes a new `dayHabitStatus` map to `CalendarWidget`:
```dart
Map<DateTime, ({int completed, int total})> _getDayHabitStatus() {
  final result = <DateTime, ({int completed, int total})>{};
  // for each day in focused month:
  //   total = getRoutinesForDate(day).length
  //   completed = how many isCompletedOn(day)
  //   if total > 0: result[day] = (completed: c, total: t)
  return result;
}
```
Calendar cell shows a tiny `✓n/n` badge or mini progress bar below the date number, in addition to (or replacing) the emotion emoji when habit data is present.

---

### 2.5 Files changed — Phase 1

| File | Change |
|------|--------|
| `lib/models/routine.dart` | Add `scheduledDaysOfWeek`, `scheduledDate` fields; extend `RoutineFrequency` enum with `scheduled`, `adhoc`; update `copyWith`, `toJson`, `fromJson` |
| `lib/core/services/database_service.dart` | v4→v5 migration: `ALTER TABLE routines ADD COLUMN scheduled_days_of_week TEXT`, `ADD COLUMN scheduled_date TEXT`; bump `_onCreate` to version 5 |
| `lib/core/services/storage_service.dart` | Include new columns in routine insert/update/select |
| `lib/repositories/routine_repository.dart` | Propagate new fields in `create()` and `update()` |
| `lib/providers/routine_provider.dart` | Replace `getActiveRoutinesForToday()` with `getRoutinesForDate(DateTime)`; add `isMissedOn(Routine, DateTime)` derived helper |
| `lib/screens/routine/routine_screen.dart` | Full rewrite: `DefaultTabController(3)` with 全部 / 今日 / 记录 tabs; new add/edit dialog with frequency/day/date pickers; read-only 记录 list |
| `lib/widgets/calendar_widget.dart` | Add `dayHabitStatus: Map<DateTime, ({int completed, int total})>` parameter; render mini completion badge in day cell |
| `lib/screens/home/home_screen.dart` | Compute `dayHabitStatus` from `RoutineProvider` and pass to `CalendarWidget` |

---

## 3. Phase 2 — Card Enhancements ✅ TESTED

### 3.1 Editable cards

Currently `CardsTab` shows a grid with no edit path. Add a long-press menu (or swipe) with **Edit** option that reopens `CardBuilderDialog` with the card's existing `entryIds`, `templateId`, `folderId` pre-selected.

`CardBuilderDialog` gains an optional `existingCard: NoteCard?` constructor parameter. When set:
- Entry picker pre-selects `existingCard.entryIds`
- Template scroll pre-selects `existingCard.templateId`
- Folder dropdown pre-selects `existingCard.folderId`
- "生成卡片" button calls `CardProvider.updateNoteCard()` instead of `createNoteCard()` and re-renders the image

No DB changes. `CardProvider` already has update logic.

---

### 3.2 Template image upload

**Model change — `CardTemplate`:**
Add `String? customImagePath` field (path to user-uploaded image in app documents directory).

**DB migration v4 → v5:**
```sql
ALTER TABLE templates ADD COLUMN custom_image_path TEXT;
```

**`CardRenderer` change:**
```dart
// Current: solid bgColor box
// New: if customImagePath != null → DecorationImage(image: FileImage(File(path)))
//      else → solid bgColor
decoration: BoxDecoration(
  color: customImagePath == null ? Color(int.parse(bgColor)) : null,
  image: customImagePath != null
      ? DecorationImage(image: FileImage(File(customImagePath!)), fit: BoxFit.cover)
      : null,
),
```

**Template editor UI** (new bottom sheet or dialog, accessed from `CardsTab` settings or "自定义" template):
- Name field
- Font family selector (default / serif / mono)
- Font color picker
- Background: toggle between **Solid color** (color wheel) and **Upload image** (`ImagePicker.pickImage(source: ImageSource.gallery)` → `FileService.saveFile()`)

**New dependency:** `image_picker: ^2.1.0`

**Files changed:**

| File | Change |
|------|--------|
| `lib/models/card_template.dart` | Add `customImagePath` field; update `copyWith`, `toJson`, `fromJson` |
| `lib/core/services/database_service.dart` | v4→v5: `ALTER TABLE templates ADD COLUMN custom_image_path TEXT` |
| `lib/core/services/storage_service.dart` | Include `custom_image_path` in template insert/update/select |
| `lib/providers/card_provider.dart` | `createTemplate()` / `updateTemplate()` accept `customImagePath` |
| `lib/widgets/card_renderer.dart` | Conditional `DecorationImage` vs solid color background |
| `lib/screens/cherished/cards_tab.dart` | "Edit template" entry point + new `_TemplateEditorSheet` widget |
| `pubspec.yaml` | Add `image_picker: ^2.1.0` |

---

### 3.3 AI note merge (poem / summary)

When the user taps "生成卡片" in `CardBuilderDialog` and multiple entries are selected, offer a toggle:

```
Content mode:  [原文]  [AI 生成]
```

In **AI 生成** mode:
1. Collect all selected entry `content` strings
2. Call `LlmService.complete()` with prompt:
   > "将以下日记片段合并为一段简洁优美的文字（可以是诗意的句子）：\n{content1}\n{content2}…"
3. Show result in a preview text field (editable)
4. Store the AI result in `NoteCard.aiSummary`; `note_card_entries` still links to original entries

**DB migration v4 → v5:**
```sql
ALTER TABLE note_cards ADD COLUMN ai_summary TEXT;
```

**`CardRenderer`** renders `aiSummary ?? firstEntry.content` as the card body.

**Files changed:**

| File | Change |
|------|--------|
| `lib/models/note_card.dart` | Add `aiSummary` field; update `copyWith`, `toJson`, `fromJson` |
| `lib/core/services/database_service.dart` | v4→v5: `ALTER TABLE note_cards ADD COLUMN ai_summary TEXT` |
| `lib/core/services/storage_service.dart` | Include `ai_summary` in note_card insert/update/select |
| `lib/providers/card_provider.dart` | Propagate `aiSummary` in create/update |
| `lib/widgets/card_renderer.dart` | Render `aiSummary` when set |
| `lib/screens/cherished/card_builder_dialog.dart` | Content mode toggle + LLM call + editable preview |

---

## 4. Phase 3 — Social Sharing ✅ TESTED

### 4.1 Share via system share sheet

Use `share_plus` package. Covers WeChat, Telegram, and any other app the OS offers.

**New dependency:** `share_plus: ^10.0.0`

**Two share entry points:**

**A. Share a note** (from `MomentScreen` / `EntryCard`):
```dart
Share.share(entry.content ?? '', subject: '来自 Blinking');
// If entry has images: Share.shareXFiles([XFile(path)], text: entry.content)
```
Add a share icon to `EntryCard` trailing row (alongside the existing edit / card icons).

**B. Share a card image** (from `CardsTab` card tile):
```dart
Share.shareXFiles([XFile(card.renderedImagePath!)], text: '来自 Blinking');
```
Add a share icon to the card tile's long-press menu or overlay.

**Telegram-specific:** No extra work. The user picks Telegram from the system share sheet. For direct Telegram URL-scheme deep link (optional enhancement):
```dart
final uri = Uri.parse('tg://msg?text=${Uri.encodeComponent(text)}');
if (await canLaunchUrl(uri)) launchUrl(uri);
```
Requires `url_launcher: ^6.x` (add only if the deep-link path is chosen).

**Files changed:**

| File | Change |
|------|--------|
| `lib/widgets/entry_card.dart` | Add share `IconButton` in header row |
| `lib/screens/cherished/cards_tab.dart` | Add share option in card tile menu |
| `pubspec.yaml` | Add `share_plus: ^10.0.0` |

---

## 5. Phase 4 — AI Assistant Personalization ✅ TESTED

### 5.1 Name and personality

Stored in SharedPreferences:
- Key `ai_assistant_name` — display name (default: `'AI 助手'`)
- Key `ai_assistant_personality` — free-text personality description (default: `''`)

**`AssistantScreen` changes:**
- AppBar title reads `_name` from SharedPreferences (loaded in `initState`)
- `_systemPrompt` becomes a computed getter:
```dart
String get _systemPrompt =>
    '你是 Blinking 日记应用的 AI 助手，名字叫 $_name。'
    '${_personality.isNotEmpty ? "你的性格特点：$_personality。" : ""}'
    '帮助用户回顾每日记录、提供情绪支持和成长建议。请用温暖、简洁的中文回答。';
```

**Settings screen — new "AI 个性化" section:**
```
AI 个性化
────────────────────────
助手名称      [       ]     (TextField, default: AI 助手)
性格描述      [       ]     (TextField, hint: 例如: 温柔、幽默、鼓励型)
[保存]
```
On save: write both keys to SharedPreferences.

No DB changes. No new provider needed (two simple SharedPreferences reads/writes).

---

### 5.2 Richer robot animation

`FloatingRobotWidget` currently has one `AnimationController` (bob: translate Y 0 → -8px, 1800ms repeat-reverse).

Add two more animation layers:

**Idle pulse** (second controller, 3000ms):
```dart
// Subtle scale 1.0 → 1.05 → 1.0
_pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
  CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
);
```

**Tap "wave"** (third controller, single-shot 500ms on tap):
```dart
// Brief rotation ±15 degrees then back
_waveAnimation = TweenSequence([
  TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 0.3, end: -0.3), weight: 2),
  TweenSequenceItem(tween: Tween(begin: -0.3, end: 0.0), weight: 1),
]).animate(CurvedAnimation(parent: _waveController, curve: Curves.easeInOut));
```

Combined in `build`:
```dart
Transform.rotate(
  angle: _waveAnimation.value,
  child: Transform.scale(
    scale: _pulseAnimation.value,
    child: Transform.translate(
      offset: Offset(0, _bobAnimation.value),
      child: _RobotCircle(onTap: _onTap),
    ),
  ),
)
```

**Files changed:**

| File | Change |
|------|--------|
| `lib/screens/assistant/assistant_screen.dart` | Load name/personality from SharedPreferences; dynamic system prompt |
| `lib/screens/settings/settings_screen.dart` | New "AI 个性化" section with name + personality fields |
| `lib/widgets/floating_robot.dart` | Two additional `AnimationController`s: idle pulse + tap wave |

---

## 6. Database migration v4 → v5

Single `if (oldVersion < 5)` block in `DatabaseService.onUpgrade`:

```dart
if (oldVersion < 5) {
  // Phase 1 — Habit scheduling
  await db.execute('ALTER TABLE routines ADD COLUMN scheduled_days_of_week TEXT');
  await db.execute('ALTER TABLE routines ADD COLUMN scheduled_date TEXT');

  // Phase 2 — Template image upload
  await db.execute('ALTER TABLE templates ADD COLUMN custom_image_path TEXT');

  // Phase 2 — AI summary on cards
  await db.execute('ALTER TABLE note_cards ADD COLUMN ai_summary TEXT');
}
```

Also update `_onCreate` to include all four columns in the fresh-install schema (DB version → 5).

All columns are nullable with no DEFAULT constraint, so all existing rows remain valid with NULL values for the new fields.

---

## 7. New dependencies

```yaml
# Phase 2 — template image upload
image_picker: ^2.1.0

# Phase 3 — system share sheet (WeChat / Telegram / etc. via OS)
share_plus: ^10.0.0
```

No new dependencies for Phases 1 and 4.

---

## 8. Phased delivery order

### Phase 1 — Habit system overhaul
*DB v5 migration. Touches Routine model, repository, provider, screen.*
- [ ] Extend `RoutineFrequency` with `scheduled`, `adhoc`
- [ ] Add `scheduledDaysOfWeek`, `scheduledDate` to `Routine` model
- [ ] DB v5 migration (routine columns)
- [ ] `StorageService` + `RoutineRepository` propagate new fields
- [ ] `RoutineProvider.getRoutinesForDate(DateTime)` replaces `getActiveRoutinesForToday()`
- [ ] `RoutineProvider.isMissedOn(Routine, DateTime)` helper
- [ ] `RoutineScreen` rewrite: 3-tab (全部 / 今日 / 记录), new add/edit dialog

### Phase 2 — Card enhancements ✅ TESTED
*DB v5 migration (templates + note_cards). New image_picker dep.*
- [x] `NoteCard.aiSummary` field + DB migration
- [x] `CardTemplate.customImagePath` field + DB migration
- [x] `StorageService` + `CardProvider` propagate both new fields
- [x] `CardRenderer` supports image background
- [x] `CardBuilderDialog`: pre-fill for edit mode + AI merge toggle
- [x] `CardsTab`: Edit entry point (long press / menu)
- [x] Template editor bottom sheet (name, font, bg color or image)

### Phase 3 — Social sharing ✅ TESTED
*No DB changes. share_plus already in pubspec.*
- [x] Share icon on `EntryCard`
- [x] Share option in `CardsTab` card tile menu

### Phase 4 — AI personalization ✅ TESTED
*No DB changes. No new deps.*
- [x] Settings "AI 个性化" section (name + personality fields)
- [x] `AssistantScreen` reads name/personality, builds dynamic system prompt
- [x] `FloatingRobotWidget` enhanced with pulse + tap-wave animations

---

## 9. File impact matrix

| File | Ph1 Habit | Ph2 Cards | Ph3 Share | Ph4 AI |
|------|-----------|-----------|-----------|--------|
| `lib/models/routine.dart` | ✓ | | | |
| `lib/models/card_template.dart` | | ✓ | | |
| `lib/models/note_card.dart` | | ✓ | | |
| `lib/core/services/database_service.dart` | ✓ | ✓ | | |
| `lib/core/services/storage_service.dart` | ✓ | ✓ | | |
| `lib/repositories/routine_repository.dart` | ✓ | | | |
| `lib/providers/routine_provider.dart` | ✓ | | | |
| `lib/providers/card_provider.dart` | | ✓ | | |
| `lib/screens/routine/routine_screen.dart` | ✓ | | | |
| `lib/screens/cherished/cards_tab.dart` | | ✓ | ✓ | |
| `lib/screens/cherished/card_builder_dialog.dart` | | ✓ | | |
| `lib/screens/assistant/assistant_screen.dart` | | | | ✓ |
| `lib/screens/settings/settings_screen.dart` | | | | ✓ |
| `lib/widgets/card_renderer.dart` | | ✓ | | |
| `lib/widgets/calendar_widget.dart` | ✓ | | | |
| `lib/widgets/entry_card.dart` | | | ✓ | |
| `lib/widgets/floating_robot.dart` | | | | ✓ |
| `pubspec.yaml` | | ✓ | ✓ | |

**New files — none required.** All changes are additive to existing files, except the optional `_TemplateEditorSheet` which can live as a private class in `cards_tab.dart`.

---

## 10. PM answers

| # | Question | Answer |
|---|----------|--------|
| Q1 | History view format? | Simple list of past days (most recent first), each showing that day's routines. **Key clarification:** Calendar view must also show daily habit results. Each day starts with a fresh list; checking an item removes it from pending → moves to completed. At end of day the list becomes a read-only record. |
| Q2 | Adhoc routine: one definition, multiple days? | Each add = separate manual inclusion for that day; the routine definition is shared. |
| Q3 | AI card merge: replace or append original text? | Replaced entirely on the card. Original entries must NOT be lost or altered — only the card's display text changes. `note_card_entries` links to originals remain intact. |
| Q4 | Editing built-in template? | Create a copy with `isBuiltIn = false`; leave the original built-in unchanged. |
| Q5 | Tap-wave animation timing? | Every tap (including when opening AI chat). |

---

## 11. Refined design from PM answers

### 11.1 Day-state machine (Q1 clarification)

Each day has exactly one of three states:

```
FUTURE / TODAY (interactive)          PAST (read-only)
─────────────────────────────         ─────────────────
Fresh list = getRoutinesForDate()     Record = completion log snapshot
User checks item → moves to           Completed: ✓ (green)
  Completed section                   Missed: ✗ (red)
User unchecks → moves back to         Cannot toggle
  Pending section
```

"End of day" is not an active transition — it is purely derived: if `date < today` then read-only. No background job or timer needed.

**Immutability rule:** `date < today` → render ✓/✗, disable tap gesture. `date == today` → fully interactive.

### 11.2 Calendar cell — habit completion indicator (Q1)

`CalendarWidget` receives a new parameter:
```dart
final Map<DateTime, ({int completed, int total})> dayHabitStatus;
```

Cell rendering priority (bottom sub-row, below date number):
1. If `dayHabitStatus[day] != null` → show compact ratio badge: `✓ 3/5` or a colored mini progress bar
2. Else if `dayEmotions[day] != null` → show emotion emoji (existing)
3. Else if `hasEntries` → show dot (existing)

`HomeScreen` computes `dayHabitStatus` from `RoutineProvider.getRoutinesForDate(date)` + `isCompletedOn(date)` for each calendar day.

### 11.3 记录 tab — flat day list (Q1)

No date picker. Render a `ListView` of the last N days (e.g., 30) in reverse chronological order:

```
─── 3月14日 (周五) ──────────────────────  ← section header
  💊 维生素       ✓
  🏃 5000步       ✗
  📚 阅读         ✓

─── 3月13日 (周四) ──────────────────────
  💊 维生素       ✓
  ...
```

Each row: `effectiveIcon` + routine name + ✓ or ✗. Tapping a row does nothing (read-only). Days with no scheduled routines are omitted.

### 11.4 Original entries protection (Q3)

- `NoteCard.aiSummary` stores the AI-generated text for **display purposes only**
- `note_card_entries` join table is never modified during card edit
- `Entry` records are never touched by card operations
- `CardRenderer` renders `aiSummary` when set; `note_card_entries` remain the authoritative link to source entries
- Card detail view (future) can show "查看原文" to navigate to the linked entries

### 11.5 Template copy-on-edit (Q4)

When the user taps "Edit" on a built-in template:
1. Create a new `CardTemplate` with `isBuiltIn = false`, name prefixed with "自定义 — {originalName}", all other fields copied
2. Open the template editor with this new copy
3. The original built-in template is never modified
4. The new copy is saved as a user template and immediately available in the template picker

### 11.6 Robot wave on every tap (Q5)

`_onTap` in `FloatingRobotWidget`:
```dart
void _onTap() {
  _waveController.forward(from: 0); // non-blocking, plays 500ms animation
  // then open AssistantScreen
  showModalBottomSheet(...);
}
```
The wave plays concurrently with the modal opening — no delay added to navigation.
