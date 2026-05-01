# Blinking Notes — Project Status
**Date:** 2026-04-29 (Updated: PROP-1 & PROP-2 Complete)
**Version:** 1.1.0-beta.3+18
**Tests:** 73/73 passing (57 existing + 16 new from PROP-1/2)
**Platforms:** Android (release-ready) · iOS (blocked — see §4)

---

## 1. Feature Completeness

### Core App Features
| Feature | Status | Notes |
|---------|--------|-------|
| Entry creation / editing | ✅ Done | Emotion picker, tags, media, bilingual |
| Entry detail screen (read-only) | ✅ Done | `entry_detail_screen.dart` — Edit + Share + Post to Chorus |
| Post to Chorus (global feed) | ✅ Done | Globe icon in entry detail → `PostToChorusSheet`; posts to blinkingchorus.com |
| Calendar with emotion badges | ✅ Done | |
| Routine tracking (4 frequency types) | ✅ Done | Daily / Weekly / Scheduled / Adhoc |
| Emotion jar (yearly shelf) | ✅ Done | |
| Note cards + rich editor | ✅ Done | flutter_quill, 100-word limit, template system |
| Card share (PNG) | ✅ Done | |
| Summary charts | ✅ Done | Day/Week/Month scope; hides when all-zero |
| AI assistant (multi-turn LLM chat) | ✅ Done | OpenRouter-first; Save Reflection |
| AI Secrets tag (exclude private notes) | ✅ Done | `tag_secrets` system tag; excluded from AI context |
| Bilingual UI (EN / ZH) | ✅ Done | Full l10n coverage via ARB |
| Export / Backup (ZIP + JSON) | ✅ Done | Date range picker + live progress bar |
| Import / Restore (ZIP + JSON) | ✅ Done | Two-phase dialog: confirmation → progress bar with percentage & time estimate (PROP-2) |
| Habit import/export (JSON) | ✅ Done | |
| Theme (light / dark) | ✅ Done | Brand teal `#2A9D8F` |
| AI personalization (name + personality) | ✅ Done | |
| Legal docs (Privacy Policy + ToS) | ✅ Done | |
| Send Feedback | ✅ Done | mailto `blinkingfeedback@gmail.com` |
| First-launch onboarding banner | ✅ Done | Calendar screen; one-time, dismissible |

### UX Improvements (from 2026-03-23 UX Review)
| ID | Item | Status |
|----|------|--------|
| P1-1 | Robot smart visibility (hides on Keepsakes/Settings) + API-key-awareness | ✅ Done |
| P1-2 | Calendar day-of-week + month header localization | ✅ Done |
| P1-3 | AI chip truncation fix | ✅ Done |
| P1-4 | Pending habit icon (○ instead of ❌) | ✅ Done |
| P1-5 – P1-10 | Remaining Phase 1 language + UX fixes | ✅ Done |
| P2-1 | Brand teal color (replaced iOS blue) | ✅ Done |
| P2-2 | Keepsakes tab rename → Insights | ❌ Deferred | Intentional — revisit post-beta |
| P2-3 | Mood emoji label on selection | ✅ Done |
| P2-4 | Habit completion chart hides when all-zero | ✅ Done |
| P2-5 | Cards empty state improved | ✅ Done |
| P2-6 | AI Secrets tag | ✅ Done |
| P2-7 | OpenRouter onboarding (first in list + free key link) | ✅ Done |
| P2-BUG-1 | Robot doesn't re-check API key after save | ✅ Done | `LlmConfigNotifier` |
| P2-BUG-2 | Active provider not visually distinct | ✅ Done | Teal background + "Active" badge |
| M1 | Nav label "Moment" vs screen title "Moments" | ✅ Done | ARB: `moment = "Moments"` |
| M3 | "我的卡片" chip in English UI | ✅ Done | Default folder shows "My Cards" in EN |
| M4 | Add Tag misplaced at top of Settings | ✅ Done | Now in Tag Management section |
| M5 | Heavy bordered text field in Add Memory | ✅ Done | `BorderSide.none` |
| M6 | Completed habits no visual feedback in Today tab | ✅ Done | Strikethrough + grey text |
| M7 | First-launch onboarding card | ✅ Done | Calendar screen banner |

---

## 2. Known Bugs

### ✅ BUG-1 — Backup date range does not filter media files (FIXED by PROP-1)
**Status:** RESOLVED  
**Fix:** Media files are now filtered by date range. `ExportService.exportAll()` collects media URLs from filtered entries and only includes referenced files in the ZIP. "Last month" backup is now meaningfully faster and smaller than "All data".  
**Commits:** `9340a26`, `96724df`, `763a255`

### ✅ BUG-2 — Restore shows a plain spinner with no progress feedback (FIXED by PROP-2)
**Status:** RESOLVED  
**Fix:** `restoreFromBackup()` now accepts optional `onProgress` callback. UI displays non-dismissible progress dialog with LinearProgressIndicator, percentage, time estimate, and "Do not close the app" warning.  
**Commits:** `1ada66d`, `cd029d0`, `cfd0bd0`

---

## 3. Technical Debt / Housekeeping

| Item | Notes |
|------|-------|
| CLAUDE.md P2 item "Dedicated entry detail / read-only view" | Stale — entry detail is fully implemented. Should be removed. |
| `docs/plans/2026-04-22-card-cleanup-db-indexes-entry-detail-plan.md` | The entry detail portion is done. Card PNG cleanup and DB indexes (v9 migration) are still pending. |
| `docs/TODO-2026-03-23.md` | Most items resolved. "Summary analytics Chinese" appears fixed (titles use ARB keys). "Secrets tag" done. Remaining open: trial API key source, UX review tooling. |

---

## 4. Release Pipeline

### Android — v1.1.0-beta.3+18
| Step | Status |
|------|--------|
| AAB built and tested | ✅ Done |
| Upload to Play Console | ✅ Done |
| Smoke test on physical device | ✅ Done |
| Promote to Closed Testing (beta) | ✅ Active — in closed testing now |
| Promote to Production | ⬜ Pending — wait for beta soak |

**Next step:** Monitor closed testing for crash reports and feedback. Promote to Production once stable.

### iOS — blocked
| Blocker | Detail |
|---------|--------|
| Flutter stable doesn't support Xcode 26 yet | Flutter 3.41.2 (Feb 2026) predates Xcode 26; deprecated API fixes expected in next stable (~May 2026) |
| Xcode 26.4.1 not yet installed | Available, but installing before Flutter is ready wastes effort |

Full iOS plan: `docs/plans/2026-04-28-infrastructure-upgrade-ios-release.md`

---

## 5. Proposed Work Items

Priority tiers: **P0** = blocking / must fix · **P1** = high value, do next · **P2** = medium, schedule soon · **P3** = nice to have / post-beta

---

### ✅ PROP-1 — Fix backup date range: filter media files by selected range (COMPLETE)
**Priority:** P1  
**Status:** MERGED TO MASTER  
**Type:** Bug fix

**Summary:** Media files are now properly filtered by the selected date range. When backing up, only media referenced by entries within the selected date range are included in the ZIP file. This makes "Last month" backups significantly faster and smaller than "All data" backups.

**Implementation:**
- `ExportService.exportAll()` now filters media files by collecting referenced URLs from filtered entries
- Unused media files are skipped during ZIP creation
- "All data" range still includes all media (backward compatible)
- Added onProgress callback for progress tracking (foundation for restore progress)

**Commits:** `9340a26`, `96724df`, `763a255`, plus storage cleanup: `e31a023`, `0ade10d`

**Impact:** Users can now create meaningfully smaller and faster backups when selecting a date range. Storage efficiency improved.

---

### ✅ PROP-2 — Add progress bar to Restore (COMPLETE)
**Priority:** P1  
**Status:** MERGED TO MASTER  
**Type:** UX consistency / feature parity with backup

**Summary:** Restore feature now shows a non-dismissible progress dialog with percentage, time estimate, and warning message — matching the UX of the backup feature. Users get real-time feedback during restoration instead of a blank spinner.

**Implementation:**
- `StorageService.restoreFromBackup()` accepts optional `onProgress` callback
- Progress tracked during ZIP file extraction (media/avatar files)
- `SettingsScreen._handleRestore()` refactored with two-phase dialog:
  - Phase 0: Confirmation dialog warning that restore will replace all data
  - Phase 1: Non-dismissible progress dialog with LinearProgressIndicator, percentage (0–100%), time estimate, and "Do not close the app" warning
- Reused existing `_BackupEstimator` class for time estimation
- Full bilingual support (English/Chinese)

**Commits:** `1ada66d` (onProgress callback), `cd029d0` (progress dialog), `e128cf9` (type fix), plus 16 new tests: `b7cb37e`, `e8a7cbb`, `cfd0bd0`

**Test Coverage:** 73 total tests (57 existing + 16 new: 5 StorageService + 6 widget + 5 integration)

**Impact:** Restore is no longer a black box. Users know the app is working and how long to wait, reducing the risk of force-quitting and corrupting data.

---

### PROP-3 — Promote Android to Production on Google Play
**Priority:** P1  
**Effort:** ~15 minutes (manual steps in Play Console, no code changes)  
**Type:** Release

**Background:** v1.1.0-beta.3+18 was uploaded to Google Play and is currently in Closed Testing (beta). The app is live and accessible to invited testers. The next step is to watch for issues during the soak period, then promote to Production rollout.

**What:** Once the closed testing period shows no crash spikes or critical feedback, promote the build to Production in Play Console. This makes the app publicly available on the Play Store.

**How:** In Play Console → Release → Production → Create new release → Promote from beta. Start at 10–20% rollout to catch any issues before full distribution.

**Dependency:** Requires a clean soak period (no critical bugs from beta testers). No code changes needed unless a bug is found during testing.

**Impact:** App publicly available on Android. First real-world user base.

---

### PROP-4 — Card PNG cleanup (delete orphaned renders on card delete/update)
**Priority:** P2  
**Effort:** ~1 hour  
**Type:** Bug fix / storage hygiene

**Background:** The Keepsakes tab → Cards section lets users create memory cards — richly formatted cards combining text, templates, and background images. When a user saves or previews a card, the app renders it as a PNG image file so it can be shared. Each time the card is saved again (e.g. after editing), a new PNG is generated. The old PNG file is left behind on the device and never cleaned up. Similarly, when a user deletes a card entirely, the PNG file stays on disk even though the card no longer exists.

**The problem:** Over time — especially for users who edit cards frequently — the app accumulates many invisible PNG files that are never used. These take up storage space with no benefit.

**Fix:** Two small changes to the card management code:
- When a card is deleted, also delete its PNG file from disk.
- When a card is saved with a new render, delete the previous PNG file before replacing it.

No database changes required. This is purely cleaning up files that should have been deleted already.

**Impact:** Prevents unbounded storage growth for users who frequently create, edit, or regenerate card previews. Invisible to the user — they just benefit from smaller app storage usage.

---

### PROP-5 — DB indexes (migration v9)
**Priority:** P2  
**Effort:** ~1 hour (including migration test)  
**Type:** Performance / maintenance

**Background:** The app stores all entries, habits, and habit completion history in a local SQLite database. Every time the Calendar loads, the Moments list refreshes, or the Summary charts render, the app runs queries against that database. Currently, the most frequently queried columns — entry date, tag associations, and habit completion records — have no database indexes. An index is a behind-the-scenes data structure that makes lookups dramatically faster, similar to how a book's index lets you find a topic without reading every page.

**The problem:** With a small amount of data this is unnoticeable. But as a user builds up months or years of entries and daily habit completions, these unindexed queries get progressively slower. The Calendar, Moments, and Summary screens could become sluggish for power users.

**Fix:** Add three indexes to the database. This is done via a database migration (version 8 → 9) — a one-time upgrade that runs automatically when existing users update the app. No data is changed; it only adds lookup speed. Fresh installs get the indexes from day one.

**Impact:** Keeps the app fast as data accumulates. Completely invisible to the user — screens just stay snappy over time.

---

### PROP-6 — Trial API key flow (7-day free trial) ✅ COMPLETE
**Priority:** P2  
**Effort:** App-side ~12h | Backend ~5h | Total ~17h  
**Type:** Growth / onboarding  
**Status:** ✅ Complete (app + backend, 2026-04-30)

**Implementation:**
- **Backend:** Cloudflare Worker endpoints `POST /api/trial/start` and `POST /api/trial/chat` at `blinkingchorus.com`, using KV for trial state storage, OpenRouter (qwen3.5-flash) proxy with rate limiting (20/day, 7-day expiry), kill switch via `TRIAL_ENABLED` secret
- **App:** `DeviceService` (anonymous install ID), `TrialService` (trial lifecycle), modified `LlmService` (trial config fallback + error types), `SettingsScreen` (trial banner + provider entry), `FloatingRobotWidget` (trial states), `AssistantScreen` (expiry banner), 13 i18n strings
- **Tests:** 14 backend tests (Vitest) + existing 94 Flutter tests passing
- **Docs:** `docs/plans/2026-04-30-prop-6-trial-api-key-plan.md`, `docs/plans/2026-04-30-prop-6-backend-plan.md`, `docs/plans/2026-04-30-trial-api-key-uat.md`

**Background:** The AI assistant (the 🤖 robot button) is one of the app's most distinctive features — it reads your entries and habits, and you can have a real conversation with it about your life. However, using it requires the user to set up their own API key from a third-party AI provider like OpenRouter. This is a technical step that many non-technical users will not complete. As a result, a large portion of new users may never experience the AI feature at all.

**What:** Offer a "Try for free — 7 days" option in the AI Provider settings so new users can experience the AI assistant immediately without needing their own API key. After 7 days, the trial expires and the user is prompted to add their own key to continue.

**How it works from the user's perspective:**
1. New user opens Settings → AI Provider.
2. Instead of (or alongside) the "Get a free API key →" link, there is a "Try for free — 7 days" button.
3. Tapping it contacts a backend service, which issues a temporary, rate-limited API key tied to that install.
4. The key is saved automatically. The AI assistant works immediately.
5. The provider list shows "Trial — X days remaining." When expired, the assistant is disabled with a message prompting the user to add their own key.

**Dependency:** Requires a small backend service to issue and rate-limit trial keys (to control cost). The backend design needs to be scoped separately. The app-side UI can be built and tested against a placeholder first.

**Impact:** Removes the single biggest onboarding barrier for non-technical users. Users who experience the AI assistant are far more likely to invest in setting up a long-term API key and become retained users.

---

### PROP-7 — AI Secrets tag: add visible privacy indicator on entries
**Priority:** P3  
**Effort:** ~1 hour  
**Type:** UX polish

**Background:** The app has a built-in "Secrets" (私密) tag that users can apply to any entry. Entries marked with this tag are silently excluded when the AI assistant reads your notes — so the AI never sees or discusses those private entries. This feature is already fully implemented and working.

**The gap:** There is currently no visual indicator anywhere in the app that a given entry has been marked private. In the Moments list and in the entry detail view, a "Secrets"-tagged entry looks identical to any other entry. A user who tagged something private months ago has no easy way to see which of their entries the AI cannot access, and may not remember which ones they marked.

**Fix:** Show a small lock icon next to "Secrets"-tagged entries in the Moments list and on the entry detail screen. The icon is subtle — it doesn't change the entry's appearance significantly, but makes the privacy status visible at a glance.

**Impact:** Makes the privacy feature discoverable and trustworthy. Users can confirm at a glance that their private entries are protected, which increases confidence in using the AI assistant with sensitive notes nearby.

---

### PROP-8 — Keepsakes tab rename (deferred, revisit post-beta)
**Priority:** P3  
**Effort:** ~30 minutes  
**Type:** UX / naming

**Background:** The fourth tab in the bottom navigation bar is currently labelled "珍藏" in Chinese and "Keepsakes" in English. This tab actually contains three different sub-sections: the yearly emotion Jar (shelf of emotion jars by year), the Cards section (rich memory cards you create and share), and the Summary charts (habit completion rates, mood trends, top tags). The word "Keepsakes" fits the jar and cards sections well but doesn't describe the analytics/summary section. During the March UX review, "Insights" was proposed as an alternative but rejected because it only fits the summary section and misses the keepsake/memory angle of the other two.

**Decision so far:** Keep "Keepsakes" for now. The tab name is not wrong — it just isn't perfect. A rename should only happen once there is clearer direction from real users about which part of this tab they value most.

**Dependency:** Collect at least one round of feedback from closed beta testers. If users are confused about what this tab contains, revisit naming. If nobody mentions it, defer further.

**Impact:** Cosmetic only. A more accurate tab name would reduce new-user confusion, but this is low urgency compared to bug fixes and feature gaps.

---

### PROP-9 — Daily Checklist Entry (ad-hoc daily lists)
**Priority:** P3 — post-production launch, after trial key (PROP-6)
**Effort:** ~12–15 hours (~2 development days)
**Type:** New feature

---

#### What this feature does

A way to create and manage an ad-hoc to-do list for the day — distinct from Habits. Each list is date-bound to the day it was created. Users check items off throughout the day. When the app is opened on a new day (any time after midnight), any list from a previous day that still has unchecked items is automatically carried forward as a fresh list for today — no user action required.

---

#### How this is different from Habits

Habits (the Routine tab) are recurring behaviors tracked over time: daily exercise, reading, water intake. The app measures streaks, completion rates, and missed days. They are structured and long-lived.

Daily lists are disposable and contextual: "things I need to do today." No streak tracking. No recurrence. A list for Monday is entirely separate from a list for Tuesday, even if some items carry over. The two features solve different problems and remain separate.

---

#### Design decisions (finalized)

**Q1 — How to create a list:** Inside the Add Entry screen, a segmented toggle at the top switches between **Note** and **List** mode. Default is Note (current behavior unchanged). Tapping "List" restructures the screen: the large text input becomes a title field, and an item-entry area appears below it. The user can switch modes before saving; existing typed text is preserved as the title if they switch to List.

**Q2 — Title:** Every list entry has a title. When the user creates a new list without entering a title, it defaults to the current date and time (e.g. "Apr 29, 9:14 AM"). The user can edit this at any time.

**Q3 — Calendar badge:** A subtle ☑ indicator on calendar days that have a list entry. Implementation must keep the calendar clean — the indicator should be small and secondary to the emotion emoji. Treat this as a nice-to-have: implement only if it doesn't create visual clutter on the calendar grid.

**Q4 — Auto-carry-forward:** No manual "push to tomorrow" button. Instead, the carry-forward is fully automatic. When the user opens the app and the current date is later than a list entry's date, and that list has unchecked items that have not yet been carried forward, the app silently creates a new list entry for today containing only those unchecked items (all reset to undone, order preserved). A small banner — *"2 items carried over from yesterday"* — appears at the top of the carried-forward list so the user knows it happened. The original list remains in the Moments feed as a permanent record of what was planned and what was completed. No background processing needed — the check runs only on app open.

---

#### Full user flow

1. User taps `+`, arrives at Add Entry screen, taps "List" toggle at the top.
2. Screen restructures: title field (defaults to today's date/time, editable) + item-entry area.
3. User types items one at a time. Each item is added to a reorderable list below.
4. User saves. The list appears in the Moments feed **above habits** for today — it is the first thing they see when checking the day.
5. Throughout the day, user opens the app and taps items to check them off. Done items show strikethrough. State saves immediately on each tap.
6. At some point after midnight, user opens the app. If any items were unchecked, a new list entry for today is created automatically. The banner "X items carried over from yesterday" shows on the new entry. The previous day's list is preserved exactly as-is in Moments.
7. If all items were checked off, nothing is carried forward — no new entry created.

---

#### Technical approach

**Database (migration v11):**
Two new columns added to the existing `entries` table — no new table needed:
```sql
ALTER TABLE entries ADD COLUMN entry_type TEXT NOT NULL DEFAULT 'note';
ALTER TABLE entries ADD COLUMN list_items TEXT;  -- JSON, null for note entries
```

`entry_type` is `'note'` (default — all existing entries unaffected) or `'list'`.
`list_items` stores a JSON array when `entry_type = 'list'`:
```json
[
  {"id": "uuid-1", "text": "Call dentist",   "is_done": false, "sort_order": 0},
  {"id": "uuid-2", "text": "Buy groceries",  "is_done": true,  "sort_order": 1}
]
```

A third column tracks carry-forward state to prevent double-processing:
```sql
ALTER TABLE entries ADD COLUMN list_carried_forward INTEGER NOT NULL DEFAULT 0;
```
Set to `1` after the app has created a carry-forward entry for this list, so re-opening the app the same day doesn't create duplicates.

**New model — `ListItem`:** A small data class with `id`, `text`, `isDone`, `sortOrder`. Serializes to/from the JSON above.

**Entry model:** Gains three new fields — `entryType: EntryType` (enum: `note | list`), `listItems: List<ListItem>?`, and `listCarriedForward: bool`. All backward-compatible: existing entries default to `entryType.note`, `listItems: null`, `listCarriedForward: false`.

**Auto-carry-forward logic:** Runs in `EntryProvider.loadEntries()` (called on app start). After loading all entries, it queries for any list entries where `entry_type = 'list'` AND `list_carried_forward = 0` AND `date(created_at) < date('now')` AND at least one item has `is_done = false`. For each such entry, it creates a new list entry for today with the unchecked items, then marks the original as `list_carried_forward = 1`.

**Ordering in Calendar and Moments:** List entries for today are pinned above habit entries in the Calendar day view. In the Moments feed, list entries sort by `createdAt` like all entries; the Calendar-level pinning is the primary "stays on top" surface.

**Files changed:**
| File | Change |
|------|--------|
| `lib/models/entry.dart` | Add `EntryType` enum, `listItems`, `listCarriedForward` fields |
| `lib/models/list_item.dart` | New — `ListItem` data class |
| `lib/core/services/database_service.dart` | Migration v11: three new columns on `entries` |
| `lib/core/services/storage_service.dart` | Serialize/deserialize `listItems`; add `toggleListItem(entryId, itemId)`; add `markListCarriedForward(entryId)` |
| `lib/providers/entry_provider.dart` | Auto-carry-forward logic on `loadEntries()`; expose `toggleListItem()` |
| `lib/screens/add_entry_screen.dart` | Note/List toggle at top; list mode: title field + item-entry + reorderable list |
| `lib/widgets/entry_card.dart` | List entry card: show title, item rows with strikethrough, "X / Y done" count; carried-over banner |
| `lib/screens/moment/entry_detail_screen.dart` | Full list view with tappable checkboxes; immediate save on toggle |
| `lib/screens/home/home_screen.dart` | Pin today's list entry above habits in the Calendar day section |
| `lib/l10n/app_en.arb` + `app_zh.arb` | New strings: "Note" / "List" toggle labels, item placeholder, "X / Y done", carried-over banner |

**Export / backup:** `ListItem` fields serialize through the existing `Entry.toJson()` / `fromJson()` path. No changes to `ExportService` or `StorageService.restoreFromBackup()`.

---

#### What is intentionally out of scope for v1

- No notification or reminder tied to a list — belongs in a later iteration.
- No recurring list templates — if a user makes the same list every day, those items should become Habits.
- No sub-lists or nested items — flat list only.
- No due times on individual items — day-granular only.
- No push to a specific future date — auto-carry-forward to the next day only.

---

## 6. Work Completion Status

**Completed:**
- ✅ PROP-1 (backup media filter bug) — Merged to master, 4 commits
- ✅ PROP-2 (restore progress bar) — Merged to master, 6 commits + 16 tests
- ✅ PROP-4 (card PNG cleanup) — Merged (orphan file deletion on card/folder/template delete)
- ✅ PROP-5 (DB indexes v11) — Merged (indexes on entry_tags + note_card_entries)
- ✅ PROP-6 (trial API key — full stack) — Completed 2026-04-30, app + backend deployed

**Next in Pipeline:**
```
PROP-3 (Play Store → Production)    ← promote to production when beta is stable
  ↓
PROP-9 (daily checklist entries)    ← design finalized; ready to implement
  ↓
PROP-7, PROP-8                      ← polish; schedule around beta feedback
  ↓
Monitor Flutter stable for Xcode 26 support
  → Execute iOS plan when unblocked (parallel track)
```
