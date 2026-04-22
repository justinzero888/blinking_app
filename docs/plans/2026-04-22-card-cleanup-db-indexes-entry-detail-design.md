# Design: Card PNG Cleanup, DB Indexes, Entry Detail Screen

**Date:** 2026-04-22
**Version target:** 1.1.0-beta.2+12 (test APK) → commit after validation

---

## 1. P2 — Card PNG Cache Cleanup

**Problem:** Every card save via `CardPreviewScreen._save()` generates a new PNG and updates `renderedImagePath` in the DB. The old PNG file is never deleted. On delete, `CardProvider.deleteCard()` removes the DB row but leaves the file on disk. Over time, orphaned PNGs accumulate.

**Fix — `CardProvider`:**

- `deleteCard(id)`: look up `renderedImagePath` from `_cards` before removing. Delete the file from disk if it exists.
- `updateCard(card)`: compare incoming `renderedImagePath` against the existing card's path in `_cards`. If they differ and the old path is non-null, delete the old file.

**Scope:** Two method additions in `lib/providers/card_provider.dart`. No schema changes, no new models.

---

## 2. P3 — DB Indexes (migration v9)

**Problem:** `entries.created_at`, `entry_tags.tag_id`, and `completions.routine_id` are queried frequently but have no indexes. Performance degrades as data grows.

**Fix — `DatabaseService`:**

- Bump `openDatabase` version: `8` → `9`
- Add `if (oldVersion < 9)` block in `_onUpgrade`:
  ```sql
  CREATE INDEX IF NOT EXISTS idx_entries_created_at ON entries(created_at);
  CREATE INDEX IF NOT EXISTS idx_entry_tags_tag_id ON entry_tags(tag_id);
  CREATE INDEX IF NOT EXISTS idx_completions_routine_id ON completions(routine_id);
  ```
- Add same three indexes to `_onCreate` for fresh installs.

**Scope:** `lib/core/services/database_service.dart` only. Migration is additive and safe.

---

## 3. P3 — Entry Detail Screen (read-only view)

**Problem:** Tapping an entry in Moments goes directly to `AddEntryScreen` (edit mode). Users can accidentally modify entries when they only want to read them.

**New file:** `lib/screens/moment/entry_detail_screen.dart`

**Layout:**
- `AppBar`: full date + time as title; **Edit** button (top-right) → `AddEntryScreen(existingEntry: entry)`; back arrow
- Scrollable body:
  - Emotion emoji at 32px if present
  - Full entry content (no `maxLines` truncation)
  - `TagChip` row for tags (matches existing `EntryCard` style)
  - Full-width media images, tappable via `OpenFilex`
  - Share icon (text content only, same behavior as `EntryCard`)

**Navigation change — `MomentScreen._buildEntryCard`:**
- `onTap`: was `AddEntryScreen` → now `EntryDetailScreen`
- Long-press delete: unchanged

**Edit flow from detail:**
- Edit button pushes `AddEntryScreen(existingEntry: entry)`
- On return, detail screen reflects changes automatically via `EntryProvider`

---

## Regression Tests

Update `test/` to cover:
- `CardProvider.deleteCard` deletes the PNG file from disk
- `CardProvider.updateCard` deletes old PNG when `renderedImagePath` changes
- DB migration v8 → v9 creates the three indexes
- `EntryDetailScreen` renders entry content, emotion, tags
- Tapping Edit from detail navigates to `AddEntryScreen`

---

## Build & Validation

After implementation: build release APK, run full test suite (`flutter test`), then manual regression on Android emulator.
