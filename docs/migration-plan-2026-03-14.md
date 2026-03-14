# Data Migration Plan — Phase 1 (2026-03-14)

**Scope:** Phase 1 of `IMPLEMENTATION-PLAN-2026-03-14.md`
**DB version:** 2 → 3
**Risk level:** Low — additive-only schema changes, no existing data touched

---

## What changes

Phase 1 adds two nullable columns to the existing SQLite database:

| Table | New column | Type | Default |
|-------|-----------|------|---------|
| `entries` | `emotion` | `TEXT` | `NULL` |
| `routines` | `category` | `TEXT` | `NULL` |

### Current schema (v2)

```
entries:   id | type | content | media_json | metadata_json | created_at | updated_at
routines:  id | name | name_en | icon | description | description_en | frequency |
              reminder_time | is_active | target_count | current_count | is_counter |
              unit | created_at | updated_at
```

### Target schema (v3)

```
entries:   id | type | content | media_json | metadata_json | created_at | updated_at | emotion
routines:  id | name | name_en | icon | description | description_en | frequency |
              reminder_time | is_active | target_count | current_count | is_counter |
              unit | created_at | updated_at | category
```

---

## Why existing data is safe

SQLite's `ALTER TABLE ... ADD COLUMN` is non-destructive by design:
- Never rewrites or touches existing rows
- New column defaults to `NULL` for all pre-existing rows
- Both new columns are nullable in the Dart model — `NULL` means "no emotion set" / "auto-detect category from name at display time"
- No data is deleted, moved, or transformed

---

## Code changes in `database_service.dart`

Three spots require edits:

### 1. Bump version `2 → 3`

```dart
return await openDatabase(
  path,
  version: 3,       // was 2
  onCreate: _onCreate,
  onUpgrade: _onUpgrade,
);
```

### 2. Add v3 block to `_onUpgrade`

Handles devices already running v1.0 (DB version 2). The existing `if (oldVersion < 2)` block stays unchanged — devices still on v1 run both blocks in sequence.

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute('ALTER TABLE entries ADD COLUMN metadata_json TEXT');
    await db.execute('ALTER TABLE routines ADD COLUMN description TEXT');
    await db.execute('ALTER TABLE routines ADD COLUMN description_en TEXT');
  }
  if (oldVersion < 3) {
    await db.execute('ALTER TABLE entries ADD COLUMN emotion TEXT');
    await db.execute('ALTER TABLE routines ADD COLUMN category TEXT');
  }
}
```

### 3. Update `_onCreate` for fresh installs

Fresh installs never hit `_onUpgrade`, so `_onCreate` must always reflect the full current schema. Add the new columns to the `CREATE TABLE` statements:

```dart
// In the entries CREATE TABLE:
await db.execute('''
  CREATE TABLE entries (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    content TEXT,
    media_json TEXT,
    metadata_json TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    emotion TEXT              -- new in v3
  )
''');

// In the routines CREATE TABLE:
await db.execute('''
  CREATE TABLE routines (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    name_en TEXT,
    icon TEXT,
    description TEXT,
    description_en TEXT,
    frequency TEXT NOT NULL,
    reminder_time TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    target_count INTEGER,
    current_count INTEGER DEFAULT 0,
    is_counter INTEGER NOT NULL DEFAULT 0,
    unit TEXT,
    category TEXT,            -- new in v3
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
''');
```

---

## Subtlety: category auto-detection is display-time only

After migration, all existing routines have `category = NULL` in the DB. The auto-detect logic (routine name → keyword match → category → default icon) runs **at display time in the UI** — it does not write back to the DB unless the user explicitly saves a routine edit. This means:

- Existing routines immediately show auto-detected icons after the update
- No forced write-back to the DB for existing data
- No risk of incorrect categorisation being silently persisted
- The `category` column is only written when the user confirms a save

---

## Before installing the new APK — back up your data

Your data lives in the SQLite file in the app's private storage directory. Android does not expose this directly. Use the in-app backup before proceeding:

1. Open the current v1.0 app
2. Settings → 完整备份 (ZIP) → share/save the ZIP to Files or Google Drive
3. Note the filename (it contains a timestamp)

The ZIP contains `data.json` (all entries, tags, routines, completions) and all media files. If anything goes wrong, restore via Settings → 恢复数据.

---

## Installing the new APK

Install **over** the existing app using the same package ID (`com.blinking.blinking`). Android treats this as an upgrade and preserves the app's private data directory, including the SQLite file. The migration runs automatically on first launch.

```bash
# Via ADB (keeps user data)
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Build first if needed
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Alternatively: copy the APK to the device, open it, tap Install — Android will show "Update" rather than "Install new app".

---

## Test plan

### Step 0 — Pre-install baseline (do on current v1.0)

Note down before installing:
- [ ] Total entry count (Moment → 全部)
- [ ] Routine names and which ones have completions today
- [ ] Tags that exist in Settings

---

### Step 1 — Verify migration ran cleanly

Launch the app after installing. Watch for:
- [ ] App opens without crash or white screen
- [ ] Moment screen loads — **same entry count as baseline**
- [ ] Routine screen loads — **same routines as baseline**
- [ ] No entries are missing or duplicated
- [ ] No SQLite errors in logcat:
  ```bash
  adb logcat | grep -iE "sqlite|database|blinking|exception"
  ```

---

### Step 2 — A2: Routine list split (active / completed-today)

- [ ] Routine screen shows active routines at the top
- [ ] If a routine was already completed today in v1.0, it appears in the "已完成" section at the bottom
- [ ] Complete a routine → it moves from active to completed section immediately, without restart
- [ ] The completed section does not disappear when you add/delete an active routine

---

### Step 3 — A1: Routine auto-detect icons

- [ ] Every routine shows an icon (auto-detected or previously set)
- [ ] `维生素` → 💊 (health)
- [ ] `5000步` → 🏃 (fitness)
- [ ] `喝水` → 💊 (health)
- [ ] Open edit dialog for any routine — category override chips are visible
- [ ] Change the category → save → icon updates
- [ ] Reopen the edit dialog — the saved category is pre-selected

---

### Step 4 — C1: Emotion picker on entries

- [ ] Open an **existing** entry — opens without crash
- [ ] Emotion picker row is visible (10 emoji chips)
- [ ] No emotion is pre-selected (existing entries have NULL emotion — correct)
- [ ] Tap an emoji → it highlights; save → entry card shows the emotion emoji
- [ ] Reopen that entry → saved emotion is still selected
- [ ] Create a **new** entry with an emotion → saves correctly
- [ ] Create a **new** entry **without** selecting an emotion → saves without crash

---

### Step 5 — C2: Emoji of the day

- [ ] Tag 2–3 of today's entries with emotions, then go to Home screen
- [ ] Selected date header shows the dominant emotion (e.g. `今天 · 😊`)
- [ ] Tap a past date with entries but no emotions → no emoji badge (graceful null)
- [ ] Calendar view: today's cell shows the dominant emotion emoji
- [ ] A date with no entries shows no emoji on the calendar

---

### Step 6 — Data integrity final check

- [ ] Export a new Full Backup (ZIP) from Settings
- [ ] Entry count in new backup matches pre-install baseline
- [ ] Open the ZIP → inspect `data.json`:
  - Entries have `"emotion": null` for old ones and a value for newly tagged ones
  - Routines have `"category": null` for untouched ones and a value for edited ones

---

## Rollback procedure

**If you can still reach the Settings screen:**
1. Settings → 恢复数据 → pick the backup ZIP made in Step 0

**If the app is crashing on launch:**
```bash
# Last resort — wipes all app data, then reinstall and restore from backup
adb shell pm clear com.blinking.blinking
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
Then restore from the ZIP via Settings → 恢复数据.

---

## Risk summary

| Risk | Severity | Mitigation |
|------|---------|-----------|
| Existing entries disappear | None — `ALTER TABLE ADD COLUMN` never touches existing rows | ZIP backup before install |
| App crashes on launch | Low — both new columns are nullable; no code reads them as required | Logcat to diagnose; rollback via restore |
| Routine category auto-detected incorrectly | Cosmetic only — display-time only, never overwrites DB without user action | User can override in edit dialog |
| Emotion lost after save | Medium — caught by test Step 4 | Covered by test plan |
| Fresh install missing columns | None — `_onCreate` updated to include both new columns | Covered by schema update |
