# Implementation Plan — 2026-03-15 Feature Set

**Based on:** `docs/TODO-2026-03-15.md`
**Deferred:** WeChat native SDK, Rednote integration
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

The screen gains a tab bar:

```
┌─────────────────────────────────────┐
│  日常           [全部] [今日] [记录] │
├─────────────────────────────────────┤
│ Tab 1 — 全部 (Available list)        │
│   Active habits (all frequencies)   │
│   + Paused habits section           │
│   [+ 添加] FAB or AppBar action     │
│                                     │
│ Tab 2 — 今日 (Daily list)            │
│   Auto-populated for today          │
│   ○ Pending section                 │
│   ✓ Completed section               │
│   [手动添加] button → adhoc picker  │
│                                     │
│ Tab 3 — 记录 (History)              │
│   Date picker to view any past day  │
│   Each routine shown as:            │
│     [icon]  Name     [✓] or [✗]     │
│   Read-only; cannot toggle          │
└─────────────────────────────────────┘
```

**Tab 1 — 全部 (Available list)**
- Shows all routines grouped: Active / Paused
- Shows frequency badge: 每天 / 每周六 / 2026-03-20 / 随时
- Edit / Pause / Delete via popup menu (unchanged)
- Add dialog gains frequency selector: 每天 / 指定星期 / 指定日期 / 随时

**Tab 2 — 今日 (Daily list)**
- `getRoutinesForDate(DateTime.now())` drives the list
- Split: 待完成 / 已完成 (same as current RoutineScreen)
- "手动加入" button opens a dialog to pick an `adhoc` routine or any routine for today only
- Each item shows: `[effectiveIcon]  Name  frequency-badge  [checkbox]`
- Item tile also has a small icon representation (emoji from `effectiveIcon`) always visible

**Tab 3 — 记录 (History)**
- `CalendarDatePicker` or a date chip row to navigate days
- Shows routines that were scheduled for that day via `getRoutinesForDate(selectedDate)`
- Each entry renders: icon, name, ✓ (green) / ✗ (red) / — (not applicable)
- Immutable — no tap gesture on check boxes

**Add/edit dialog changes:**
```
Name:          [          ]
Frequency:     [每天 ▼]   (dropdown: 每天 / 每周 / 指定日期 / 随时)
  if weekly:   [Mon][Tue][Wed][Thu][Fri][Sat][Sun]  (multi-select chips)
  if scheduled: [Date picker]
Reminder:      [HH:mm]  (optional)
Category:      [chip picker]  (unchanged)
```

---

### 2.5 Files changed — Phase 1

| File | Change |
|------|--------|
| `lib/models/routine.dart` | Add `scheduledDaysOfWeek`, `scheduledDate` fields; extend `RoutineFrequency` enum with `scheduled`, `adhoc`; update `copyWith`, `toJson`, `fromJson` |
| `lib/core/services/database_service.dart` | v4→v5 migration: `ALTER TABLE routines ADD COLUMN scheduled_days_of_week TEXT`, `ADD COLUMN scheduled_date TEXT` |
| `lib/core/services/storage_service.dart` | Include new columns in routine insert/update/select |
| `lib/repositories/routine_repository.dart` | Propagate new fields in `create()` and `update()` |
| `lib/providers/routine_provider.dart` | Replace `getActiveRoutinesForToday()` with `getRoutinesForDate(DateTime)`; add `isMissedOn(Routine, DateTime)` helper |
| `lib/screens/routine/routine_screen.dart` | Full rewrite: `DefaultTabController(3)` with 全部 / 今日 / 记录 tabs; new add/edit dialog with frequency/day pickers |

---

## 3. Phase 2 — Card Enhancements

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

## 4. Phase 3 — Social Sharing

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

## 5. Phase 4 — AI Assistant Personalization

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

### Phase 2 — Card enhancements
*DB v5 migration (templates + note_cards). New image_picker dep.*
- [ ] `NoteCard.aiSummary` field + DB migration
- [ ] `CardTemplate.customImagePath` field + DB migration
- [ ] `StorageService` + `CardProvider` propagate both new fields
- [ ] `CardRenderer` supports image background
- [ ] `CardBuilderDialog`: pre-fill for edit mode + AI merge toggle
- [ ] `CardsTab`: Edit entry point (long press / menu)
- [ ] Template editor bottom sheet (name, font, bg color or image)

### Phase 3 — Social sharing
*No DB changes. New share_plus dep.*
- [ ] `share_plus` added to pubspec
- [ ] Share icon on `EntryCard`
- [ ] Share option in `CardsTab` card tile menu

### Phase 4 — AI personalization
*No DB changes. No new deps.*
- [ ] Settings "AI 个性化" section (name + personality fields)
- [ ] `AssistantScreen` reads name/personality, builds dynamic system prompt
- [ ] `FloatingRobotWidget` enhanced with pulse + tap-wave animations

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
| `lib/widgets/entry_card.dart` | | | ✓ | |
| `lib/widgets/floating_robot.dart` | | | | ✓ |
| `pubspec.yaml` | | ✓ | ✓ | |

**New files — none required.** All changes are additive to existing files, except the optional `_TemplateEditorSheet` which can live as a private class in `cards_tab.dart`.

---

## 10. Open questions (need PM answers before implementation)

| # | Question | Default if not answered |
|---|----------|------------------------|
| Q1 | For "记录" tab history view — should the date picker show a calendar grid or a simple prev/next day navigator? | Day navigator (simpler) |
| Q2 | Can a user add a single `adhoc` routine to multiple days, or is each "add to day" a separate entry? | Each add = separate manual inclusion for that day; the routine definition is shared |
| Q3 | For the AI card merge — should the original entry text still be visible on the card (below the poem), or replaced entirely? | Replaced entirely; original entries accessible via `note_card_entries` links |
| Q4 | Template editor: should editing a built-in template create a copy (leaving built-in intact) or mutate it? | Create a copy with `isBuiltIn = false` |
| Q5 | For the tap-wave robot animation — should it play every tap (including when opening AI chat), or only on a separate "wave" trigger? | Every tap |
