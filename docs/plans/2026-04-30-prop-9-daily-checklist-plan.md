# PROP-9: Daily Checklist Entry — Revised Implementation Plan

> **Priority:** P2+ (after PROP-6 trial API key; higher value than original P3 designation)
> **Effort:** ~17–19 hours (~2.5 development days)
> **Type:** New feature
> **DB Migration:** v11 → v12
> **Design Review:** 2026-04-30 — see evaluation findings embedded below

**Goal:** Add ad-hoc daily checklists to the app. Users create dated to-do lists inside the Add Entry screen (via a Note/List toggle). Items can be checked off throughout the day with immediate save. Unchecked items auto-carry-forward to a new list for the next day on app open — no user action required.

**Architecture:** Extends the existing `entries` table with three new columns. Reuses the Entry model, provider, repository, and export pipeline. No new screen — the toggle lives inside the existing `AddEntryScreen`. List rendering goes into existing `EntryCard` and `EntryDetailScreen` widgets.

**Tech Stack:** Flutter/Dart, sqflite, provider, share_plus, flutter_test

---

## Design Revisions (from 2026-04-30 review)

These revisions address issues found in the original design doc (PROJECT-STATUS-2026-04-29.md, lines 260–386).

| # | Issue | Severity | Resolution |
|---|-------|----------|------------|
| R1 | `EntryType` enum name collision (existing = `routine \| freeform`, proposed = `note \| list`) | Critical | New enum named `EntryFormat` with values `note`, `list`. New DB column named `entry_format` (not `entry_type`). Model field named `format`. Existing `type` field unchanged. |
| R2 | Migration version stated as "v11" — but v11 already exists (indexes) | Critical | Migration is **v12**. `_onCreate` updated to include new columns. `kSchemaVersion` bumped to 12. |
| R3 | Toggle List→Note: what happens to list items? | High | List items concatenated into body text as `"- item text\n"` lines. Preserves user data on mode switch. |
| R4 | Toggle Note→List: long note text becomes title | High | Title field capped at first 200 chars (or first line break, whichever comes first) when switching Note→List. Remainder discarded. |
| R5 | Carry-forward logic in `EntryProvider.loadEntries()` violates layering (Provider→DB direct) | High | New method `checkAndCarryForward()` on `EntryRepository`. Provider calls `_repository.checkAndCarryForward()` in `loadEntries()`. |
| R6 | `date(created_at) < date('now')` uses UTC — off-by-one near midnight for non-UTC users | Medium | Date comparison done in Dart using local `DateTime.now()` stripped to date-only. SQLite `date()` not used for carry-forward gate. |
| R7 | `loadEntries()` runs carry-forward on every call, not just app open | Medium | `EntryProvider` gains `bool _carryForwardChecked = false` guard. Runs only once per session. |
| R8 | List items have no max length | Low | 200 chars per item enforced in UI + model validation. |
| R9 | No min-item guard on save | Low | Save button disabled when list mode has zero items (title-only list is pointless). |
| R10 | Calendar badge hedged as "nice-to-have" | Low | Deferred to v1.1 follow-up. Not in this plan's scope. |

---

## Task 1: Database Migration v11 → v12 + Models

**Files:**
- Modify: `lib/core/services/database_service.dart`
- Modify: `lib/models/entry.dart`
- New: `lib/models/list_item.dart`
- New: `test/core/db_version_test.dart` (extend existing)
- New: `test/models/list_item_test.dart`

**Schema changes — three new columns on `entries`:**

```sql
ALTER TABLE entries ADD COLUMN entry_format TEXT NOT NULL DEFAULT 'note';
ALTER TABLE entries ADD COLUMN list_items TEXT;        -- JSON, null for note entries
ALTER TABLE entries ADD COLUMN list_carried_forward INTEGER NOT NULL DEFAULT 0;
```

### Step 1: Add migration block + bump version

In `DatabaseService`:
- Change `kSchemaVersion` from `11` to `12`.
- Add `if (oldVersion < 12)` block in `_onUpgrade()` with the three `ALTER TABLE` statements above.
- Add the three columns to the `entries` table definition in `_onCreate()`.
- Update `createTestDatabase()` to use version 12 and include new columns in `_onCreate`.
- Update `runMigration()` to target version 12.

### Step 2: Create `ListItem` model (`lib/models/list_item.dart`)

```dart
class ListItem {
  final String id;
  final String text;
  final bool isDone;
  final int sortOrder;

  const ListItem({
    required this.id,
    required this.text,
    this.isDone = false,
    required this.sortOrder,
  });

  ListItem copyWith({String? id, String? text, bool? isDone, int? sortOrder}) {
    return ListItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'is_done': isDone,
    'sort_order': sortOrder,
  };

  factory ListItem.fromJson(Map<String, dynamic> json) => ListItem(
    id: json['id'] as String,
    text: json['text'] as String,
    isDone: json['is_done'] as bool? ?? false,
    sortOrder: json['sort_order'] as int? ?? 0,
  );

  static List<ListItem> listFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => ListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String? listToJson(List<ListItem>? items) {
    if (items == null || items.isEmpty) return null;
    return jsonEncode(items.map((e) => e.toJson()).toList());
  }
}
```

Validation: `text` must be non-empty and ≤ 200 chars. Enforced in factory/constructor.

### Step 3: Update `Entry` model (`lib/models/entry.dart`)

- Add `EntryFormat` enum with values `note`, `list`.
- Add three new fields to `Entry`:
  - `final EntryFormat format;` (default `EntryFormat.note`)
  - `final List<ListItem>? listItems;`
  - `final bool listCarriedForward;` (default `false`)
- Update constructor with defaults.
- Update `copyWith()` to include new fields.
- Update `toJson()` to serialize `format`, `listItems`, `listCarriedForward`.
- Update `factory Entry.fromJson()` to deserialize new fields with safe defaults.
- **Do NOT rename or remove existing `EntryType` enum or `type` field.** The two enums coexist: `type` = source (routine/freeform), `format` = content shape (note/list).

### Step 4: Write migration test

Extend `test/core/db_version_test.dart`:
- Test that a fresh v12 DB has the three new columns with correct defaults.
- Test that migrating from v11→v12 applies the three `ALTER TABLE` statements without data loss (create v11 DB with sample entry, migrate, verify entry intact + new columns defaulted).

### Step 5: Write `ListItem` model tests

- `toJson()` / `fromJson()` round-trip.
- `listFromJson()` handles null, empty string, valid JSON.
- `listToJson()` handles null, empty list, populated list.
- `copyWith()` preserves unchanged fields.
- 200-char validation on text.

**Commit:** `feat: add ListItem model + DB migration v12 for daily checklist entries`

---

## Task 2: StorageService CRUD + EntryRepository Carry-Forward

**Files:**
- Modify: `lib/core/services/storage_service.dart`
- Modify: `lib/repositories/entry_repository.dart`
- New/modify: `test/core/storage_service_test.dart` (extend)

### Step 1: Update `StorageService` entry serialization

In `getEntries()`: when reading rows, parse `entry_format`, `list_items`, `list_carried_forward` from the column map into the `Entry` model. Backward-compatible: missing columns → defaults.

In `addEntry()` / `updateEntry()`: write `entry_format`, `list_items` (JSON string), `list_carried_forward` (0/1 int) to the insert/update map.

### Step 2: Add `toggleListItem()` to StorageService

```dart
Future<void> toggleListItem(String entryId, String itemId) async {
  final db = await _dbService.database;
  final rows = await db.query('entries', where: 'id = ?', whereArgs: [entryId]);
  if (rows.isEmpty) return;
  final items = ListItem.listFromJson(rows.first['list_items'] as String?);
  final updatedItems = items.map((item) {
    if (item.id == itemId) return item.copyWith(isDone: !item.isDone);
    return item;
  }).toList();
  await db.update(
    'entries',
    {'list_items': ListItem.listToJson(updatedItems), 'updated_at': DateTime.now().toIso8601String()},
    where: 'id = ?',
    whereArgs: [entryId],
  );
}
```

### Step 3: Add `markListCarriedForward()` to StorageService

```dart
Future<void> markListCarriedForward(String entryId) async {
  final db = await _dbService.database;
  await db.update(
    'entries',
    {'list_carried_forward': 1},
    where: 'id = ?',
    whereArgs: [entryId],
  );
}
```

### Step 4: Add `checkAndCarryForward()` to EntryRepository

New method on `EntryRepository`:

```dart
/// Returns the number of items carried forward (0 = nothing to carry).
Future<int> checkAndCarryForward() async {
  final allEntries = await getAll();
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  int totalCarried = 0;

  // Find list entries eligible for carry-forward
  for (final entry in allEntries) {
    if (entry.format != EntryFormat.list) continue;
    if (entry.listCarriedForward) continue;
    final entryDate = DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
    if (!entryDate.isBefore(todayDate)) continue;
    final unchecked = (entry.listItems ?? []).where((item) => !item.isDone).toList();
    if (unchecked.isEmpty) continue;

    // Create new list entry for today with unchecked items (reset to undone)
    final carriedItems = unchecked.asMap().entries.map((e) =>
      e.value.copyWith(isDone: false, sortOrder: e.key)
    ).toList();

    await create(
      type: EntryType.freeform,
      content: entry.content, // title carries over
      format: EntryFormat.list,
      listItems: carriedItems,
      listCarriedForward: false,
    );
    await _storage.markListCarriedForward(entry.id);
    totalCarried += carriedItems.length;
  }
  return totalCarried;
}
```

Key points:
- Date comparison uses **Dart local time**, not SQLite UTC.
- Unchecked items carry forward with `isDone: false` and re-indexed `sortOrder`.
- Original entry marked `list_carried_forward = 1` to prevent double-processing.
- New entry has `listCarriedForward: false` so it can chain-carry to the next day if needed.
- Title (`content`) carries over so the user recognizes the list.
- `type` is `EntryType.freeform` (this is a user-created list, not a routine completion).

Note: `create()` signature must be extended to accept optional `EntryFormat format` and `List<ListItem>? listItems` and `bool listCarriedForward`.

### Step 5: Update EntryRepository.create() signature

Add optional parameters:
- `EntryFormat format = EntryFormat.note`
- `List<ListItem>? listItems`
- `bool listCarriedForward = false`

Pass these through to the `Entry` constructor.

### Step 6: Write StorageService tests

- Test `toggleListItem()`: creates entry with 2 items, toggles one, verifies `isDone` flipped.
- Test `markListCarriedForward()`: creates entry, marks it, verifies flag is 1.
- Test `getEntries()` reads back list items and format correctly.
- Test backward compat: entry without `entry_format` column → defaults to `EntryFormat.note`, null `listItems`.

### Step 7: Write EntryRepository carry-forward tests

- Test that a list entry with unchecked items from yesterday creates new entry for today.
- Test that a list entry with all items done does NOT create new entry.
- Test that `list_carried_forward = 1` entries are skipped.
- Test chain carry: day-2 entry (created by carry-forward) carries forward to day 3.
- Test that original entry's items are preserved unchanged.

**Commit:** `feat: add carry-forward logic + list item CRUD in StorageService and EntryRepository`

---

## Task 3: EntryProvider + Auto-Carry-Forward Integration

**Files:**
- Modify: `lib/providers/entry_provider.dart`
- New: `test/providers/entry_provider_test.dart` (extend existing)

### Step 1: Add guard flag to EntryProvider

```dart
bool _carryForwardChecked = false;
```

### Step 2: Add carry-forward call to loadEntries()

In `loadEntries()`, after loading entries from repository:

```dart
if (!_carryForwardChecked) {
  _carryForwardChecked = true;
  final carried = await _repository.checkAndCarryForward();
  if (carried > 0) {
    // Re-load to include newly created entries
    _entries = await _repository.getAll();
    _lastCarriedCount = carried; // for UI banner (see Task 5)
  }
}
```

### Step 3: Add carried-over banner state

```dart
int _lastCarriedCount = 0;
int get lastCarriedCount => _lastCarriedCount;
void clearCarriedBanner() => _lastCarriedCount = 0;
```

### Step 4: Add `toggleListItem()` to provider

```dart
Future<void> toggleListItem(String entryId, String itemId) async {
  try {
    await _storageService.toggleListItem(entryId, itemId); // needs access — see note below
    // Refresh the entry in _entries list
    final updatedEntry = await _repository.getById(entryId);
    if (updatedEntry != null) {
      final index = _entries.indexWhere((e) => e.id == entryId);
      if (index != -1) {
        _entries[index] = updatedEntry;
        notifyListeners();
      }
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}
```

**Architectural note:** `EntryProvider` currently only holds `EntryRepository`. To call `StorageService.toggleListItem()` directly, either:
- **Option A (Recommended):** Add `toggleListItem()` to `EntryRepository` as a pass-through, keeping the existing layering.
- **Option B:** Store `StorageService` reference in `EntryProvider`.

Use **Option A** — consistent with current architecture.

### Step 5: Write provider tests

- Test `loadEntries()` triggers carry-forward (mock repository).
- Test `loadEntries()` only runs carry-forward once (guard flag).
- Test `toggleListItem()` updates item and notifies listeners.
- Test `lastCarriedCount` and `clearCarriedBanner()`.

**Commit:** `feat: integrate carry-forward into EntryProvider with guard flag and toggleListItem`

---

## Task 4: Add Entry Screen — Note/List Toggle + List Builder

**Files:**
- Modify: `lib/screens/add_entry_screen.dart`
- New: `test/screens/add_entry_screen_test.dart` (extend existing)

### Step 1: Add toggle state + controllers

```dart
EntryFormat _selectedFormat = EntryFormat.note;
final TextEditingController _titleController = TextEditingController();
final TextEditingController _itemController = TextEditingController();
final List<ListItem> _listItems = [];
```

When editing an existing list entry, pre-populate `_selectedFormat`, `_titleController`, and `_listItems`.

### Step 2: Build segmented toggle widget

At the top of the screen (between AppBar and the existing content area), add a `CupertinoSegmentedControl<EntryFormat>` or custom segmented button:

```dart
Row(
  children: [
    Expanded(
      child: SegmentedButton<EntryFormat>(
        segments: [
          ButtonSegment(value: EntryFormat.note, label: Text('Note')),
          ButtonSegment(value: EntryFormat.list, label: Text('List')),
        ],
        selected: {_selectedFormat},
        onSelectionChanged: (format) => _switchFormat(format.first),
      ),
    ),
  ],
)
```

### Step 3: Implement `_switchFormat()`

```dart
void _switchFormat(EntryFormat newFormat) {
  if (newFormat == _selectedFormat) return;
  if (_selectedFormat == EntryFormat.note && newFormat == EntryFormat.list) {
    // Note → List: text becomes title (first 200 chars or first line break)
    final noteText = _textController.text;
    final lineBreak = noteText.indexOf('\n');
    _titleController.text = lineBreak > 0
        ? noteText.substring(0, lineBreak < 200 ? lineBreak : 200)
        : noteText.substring(0, noteText.length < 200 ? noteText.length : 200);
    _textController.clear();
  } else if (_selectedFormat == EntryFormat.list && newFormat == EntryFormat.note) {
    // List → Note: concatenate list items into body text
    final bodyLines = _listItems.map((item) => '- ${item.text}').join('\n');
    _textController.text = _titleController.text.isNotEmpty
        ? '${_titleController.text}\n\n$bodyLines'
        : bodyLines;
    _titleController.clear();
    _listItems.clear();
  }
  setState(() => _selectedFormat = newFormat);
}
```

### Step 4: Build list mode UI

When `_selectedFormat == EntryFormat.list`:

1. **Title field** — replaces the large text input. Placeholder: "List title" / "清单标题". Default value when empty: formatted date/time string (e.g. "Apr 29, 9:14 AM").

2. **Item entry row** — `TextField` with "Add item" / "添加事项" placeholder + an `IconButton` (add / `+` icon). On submit or button tap:
   - Validate text is non-empty and ≤ 200 chars.
   - Add `ListItem(id: uuid, text: trimmed, isDone: false, sortOrder: _listItems.length)` to `_listItems`.
   - Clear item TextField.
   - `setState(() {})`.

3. **ReorderableListView** — displays `_listItems` below the entry row.
   - Each row: drag handle (left), item text (center), delete icon button (right).
   - Delete removes item from `_listItems` and calls `setState()`.
   - Drag reorder updates `sortOrder` on all items.

4. **Save button** — disabled when `_listItems.isEmpty`. On save:
   - Create entry with `format: EntryFormat.list`, `content: _titleController.text` (the list title), `listItems: _listItems`.
   - Emotion and tags still apply (shared between both modes).

### Step 5: Adjust existing Note mode

When `_selectedFormat == EntryFormat.note`, the existing UI is unchanged. The large text input uses `_textController` as before.

### Step 6: Add localization strings

In `lib/l10n/app_en.arb` and `app_zh.arb`:
- `"noteMode": "Note"` / `"笔记"`
- `"listMode": "List"` / `"清单"`
- `"listTitleHint": "List title"` / `"清单标题"`
- `"listItemHint": "Add item"` / `"添加事项"`
- `"itemsDone": "{done} / {total} done"` / `"{done} / {total} 已完成"`
- `"carriedOverBanner": "{count, plural, =1{1 item carried over from yesterday} other{{count} items carried over from yesterday}}"` / `"{count, plural, other{{count} 个事项从昨天转入}}"`

Run `flutter gen-l10n` after adding strings.

### Step 7: Write UI tests

- Test toggle Note→List preserves text as title.
- Test toggle List→Note concatenates items into body.
- Test adding and removing list items.
- Test save is disabled when list has zero items.
- Test editing an existing list entry pre-populates items.
- Test title defaults to formatted date/time when left blank.

**Commit:** `feat: add Note/List toggle + list builder UI to AddEntryScreen`

---

## Task 5: Entry Card — List Rendering + Carried-Over Banner

**Files:**
- Modify: `lib/widgets/entry_card.dart`

### Step 1: Detect list entry in EntryCard

At the top of `build()`, check `entry.format == EntryFormat.list`.

### Step 2: Render list items

When format is `list`:
- Show **title** as the card header (instead of the time-only header for notes). Title = `entry.content`. If empty, fall back to formatted date/time.
- Below title, show items as rows:
  - Each row: checkbox icon (`check_box` / `check_box_outline_blank`) + item text.
  - Done items: strikethrough on text (`TextDecoration.lineThrough`), greyed out.
  - Undone items: normal text.
  - Tapping a row calls `entryProvider.toggleListItem(entry.id, item.id)`.
- Below the items, show **"X / Y done"** summary text (e.g. "3 / 5 done").

### Step 3: Render carried-over banner

If the entry was created by carry-forward (we need to detect this — see note below):

Show a small banner at the top of the card: *"2 items carried over from yesterday"* / *"2 个事项从昨天转入"* with a dismiss (×) button.

**Detection approach:** Use `EntryProvider.lastCarriedCount`. When a new entry is created by carry-forward in `loadEntries()`, the provider holds the count. The first `EntryCard` for today that is a list entry should show the banner. After display, call `provider.clearCarriedBanner()`.

Alternative simpler approach: Add `int? carriedOverCount` to the `Entry` model (non-persisted, set by provider). This avoids needing to pass the banner state separately. But this pollutes the model. Use the provider approach.

Better: The `EntryCard` widget can accept an optional `int? carriedOverCount` parameter. The home screen (which knows about the provider's `lastCarriedCount`) passes it down. The Moments feed screen passes `null`. This way the banner only shows on the Calendar day view — which is where it matters most.

### Step 4: Handle media in list entries

If `entry.mediaUrls` is non-empty for a list entry, show them below the items list (same as current `_buildMedia()`).

**Commit:** `feat: render list entries with checkboxes, strikethrough, and carried-over banner`

---

## Task 6: Entry Detail Screen — Interactive List View

**Files:**
- Modify: `lib/screens/moment/entry_detail_screen.dart`

### Step 1: Detect list entry

Check `entry.format == EntryFormat.list` in `build()`.

### Step 2: Build list detail view

When format is `list`:
- Show title prominently at top.
- Below title, show all items as tappable rows (same checkbox + strikethrough pattern as EntryCard).
- Tapping toggles item → calls `entryProvider.toggleListItem(entry.id, item.id)` → UI updates reactively.
- Show "X / Y done" summary.
- Edit button navigates to `AddEntryScreen(existingEntry: entry)` — the existing edit flow works because `_loadExistingEntry()` will be extended in Task 4 to pre-populate list items.

### Step 3: Keep existing note behavior unchanged

When format is `note`, the existing read-only content view is used unchanged.

### Step 4: Write tests

- Test list entry shows interactive checkboxes.
- Test toggle updates UI in real time.
- Test edit button passes entry with list items to AddEntryScreen.
- Test note entries render unchanged (regression).

**Commit:** `feat: add interactive list view to EntryDetailScreen with toggle support`

---

## Task 7: Home Screen — Pin List Entries Above Habits

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

### Step 1: Split day entries into lists and notes

In `_buildTodayOverview()`, after computing `dayEntries`:

```dart
final dayListEntries = dayEntries.where((e) => e.format == EntryFormat.list).toList();
final dayNoteEntries = dayEntries.where((e) => e.format != EntryFormat.list).toList();
```

### Step 2: Insert list entries section above habits

Current layout order in `_buildTodayOverview`:
1. Date Header
2. Routines Section (✅ Habit Check-in)
3. Entries Section (📝 Today's Entries)
4. Emoji Jar
5. Empty State

New layout order:
1. Date Header
2. **List Entries Section** (new — pinned above habits)
3. Routines Section (✅ Habit Check-in)
4. **Note Entries Section** (renamed from "Entries" to "Notes" / "笔记")
5. Emoji Jar
6. Empty State

### Step 3: Pass carried-over banner to list entries

```dart
final entryProvider = context.read<EntryProvider>();
final carriedCount = entryProvider.lastCarriedCount;
// ... pass carriedCount to first list EntryCard of today
// After rendering, call entryProvider.clearCarriedBanner();
```

Use `WidgetsBinding.instance.addPostFrameCallback` to clear the banner after build.

### Step 4: Section separators

Add a subtle header above list entries: "📋 Lists" / "📋 今日清单". Only show if there are list entries for the selected day.

**Commit:** `feat: pin daily list entries above habits in Calendar day view`

---

## Task 8: Export / Import Compatibility

**Files:**
- Verify: `lib/core/services/export_service.dart` (no changes needed, but verify)

### Step 1: Verify export

`Entry.toJson()` includes `format`, `listItems`, `listCarriedForward`. The existing export pipeline serializes `Entry.toJson()` for each entry. No changes needed.

### Step 2: Verify import

`Entry.fromJson()` handles the new fields with safe defaults. The restore pipeline uses `Entry.fromJson()`. No changes needed.

### Step 3: Write export/import test

- Create a list entry, export to ZIP, import back, verify items and format preserved.

**Commit:** `test: verify list entries survive export/import round-trip`

---

## Task 9: Full Integration Testing

### Step 1: End-to-end flow test

1. Open app → Add Entry → toggle to List.
2. Add 3 items, set emotion, save.
3. Verify list appears on Calendar day view above habits.
4. Toggle 1 item done → verify strikethrough + "1/3 done".
5. Navigate to Moments → verify list appears in feed with correct rendering.
6. Tap list → EntryDetailScreen → toggle another item → verify detail updates.
7. Simulate next day (in test, manipulate dates) → verify carry-forward creates new entry with 2 unchecked items.
8. Verify original list preserved unchanged.

### Step 2: Regression tests

- Existing note entries render unchanged in EntryCard and EntryDetailScreen.
- Existing AddEntryScreen flow (Note mode) works identically.
- Routine completions (`EntryType.routine`) unaffected.
- SummaryProvider charts unaffected (list entries count toward note counts like any freeform entry).

### Step 3: Edge case tests

- Empty list can't be saved.
- 200+ char item text truncated/rejected.
- Switching Note↔List↔Note preserves data correctly.
- Carried-forward list that gets all items done today does NOT carry forward tomorrow.
- List entry with images renders correctly.
- Editing a list entry via AddEntryScreen preserves all items.

### Step 4: Run full test suite

```bash
flutter test
flutter analyze --no-pub
```

Target: 0 analysis errors, all existing tests pass, new tests pass (~+15–20 tests expected).

**Commit:** `test: add integration and edge-case tests for daily checklist feature`

---

## Files Changed Summary

| File | Change | Effort |
|------|--------|:------:|
| `lib/models/list_item.dart` | **New** — ListItem data class | 0.5h |
| `lib/models/entry.dart` | Add `EntryFormat` enum, `format`, `listItems`, `listCarriedForward` | 1h |
| `lib/core/services/database_service.dart` | Bump to v12, migration block, `_onCreate` columns | 0.5h |
| `lib/core/services/storage_service.dart` | Serialize new columns; `toggleListItem()`, `markListCarriedForward()` | 1.5h |
| `lib/repositories/entry_repository.dart` | `checkAndCarryForward()`, extend `create()` signature | 1.5h |
| `lib/providers/entry_provider.dart` | Guard flag, carry-forward call, `toggleListItem()`, banner state | 1.5h |
| `lib/screens/add_entry_screen.dart` | Note/List toggle, title field, item entry, reorderable list | 3.5h |
| `lib/widgets/entry_card.dart` | List entry rendering: checkboxes, strikethrough, count, banner | 2h |
| `lib/screens/moment/entry_detail_screen.dart` | Interactive list view with tappable checkboxes | 1.5h |
| `lib/screens/home/home_screen.dart` | Split entries, pin lists above habits, banner display | 1h |
| `lib/l10n/app_en.arb + app_zh.arb` | New i18n strings | 0.5h |
| Various test files | ~20 new tests across models, services, providers, screens | 3h |
| **Total** | | **~18h** |

---

## Dependencies & Sequencing

```
Task 1 (DB + Models)
  └──► Task 2 (StorageService + Repository)
          └──► Task 3 (EntryProvider)
                  ├──► Task 4 (AddEntryScreen toggle + builder)
                  ├──► Task 5 (EntryCard list rendering)
                  ├──► Task 6 (EntryDetailScreen interactive list)
                  └──► Task 7 (HomeScreen pinning)
                          └──► Task 8 (Export/Import verification)
                                  └──► Task 9 (Integration + regression testing)
```

Tasks 4, 5, 6, 7 can run in parallel after Task 3 is complete.

---

## Out of Scope (V1)

- Reminders or notifications tied to list items
- Recurring list templates (use Habits instead)
- Nested sub-lists
- Per-item due times
- Push to specific future date (auto-carry-forward to next day only)
- Calendar checkbox badge indicator (deferred to v1.1 follow-up)
- Drag-to-reorder on EntryCard or EntryDetailScreen (reorder only in AddEntryScreen editor)
