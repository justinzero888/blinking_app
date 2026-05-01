# PROP-9: Daily Checklist Entry — User Acceptance Testing (UAT)

**Build:** v1.1.0-beta.5+20 | **Date:** 2026-05-01 | **Tester:** _______________ | **Result:** PASS / FAIL

---

## Setup

- [ ] App installed on Android device/emulator and opens without crash
- [ ] App language can be switched between English and Chinese (Settings → Language)

---

## TC-1: Toggle Between Note and List Modes

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap **+** FAB on Calendar | Add Entry screen opens |
| 2 | Verify segmented toggle shows | **Note** is selected by default, large text field visible |
| 3 | Tap **List** segment | Text field shrinks, list title field + item entry row appear |
| 4 | Tap **Note** segment | Returns to note mode, previous note text (if any) is preserved |
| 5 | Tap **List** again | Returns to list mode |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-2: List Mode — Data Conversion

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a note with text "Groceries\nBuy milk\nBuy eggs" | Note saved |
| 2 | Tap **+**, toggle to **List** | List opens |
| 3 | Switch Note→List: type "My List" in note, then toggle to List | Title field shows "My List" (first 200 chars or first line) |
| 4 | Switch List→Note: add 2 items in list mode, then toggle to Note | Items concatenated as "- item\n- item" in body text |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-3: Add List Items

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Toggle to **List** mode | Title field + item entry row visible |
| 2 | Leave title blank, type "Milk" in Add Item field, tap **+** | "Milk" appears in items list below |
| 3 | Type "Eggs", tap **+** | "Eggs" added to list |
| 4 | Type "Bread", tap **+** | "Bread" added to list |
| 5 | Verify item count | 3 items visible with drag handles |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-4: List Item Management

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | With 3 items above, tap ✕ on "Milk" | Item removed, list shows 2 items |
| 2 | Long-press drag handle on "Bread" | Drag up to reorder |
| 3 | Release above "Eggs" | Order is now: Bread, Eggs |
| 4 | Try adding empty item (type nothing, tap +) | Nothing happens |
| 5 | Try adding item with 201+ chars | Item not added (200 char limit) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-5: Save List Entry

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | With 0 items, note that save button (✓) should be disabled | Save does nothing, snackbar: "Add at least one item" |
| 2 | Add 1 item, tap **✓** | Entry saved, returns to Calendar |
| 3 | Verify list appears | Calendar day view shows list with 📋 Lists header |
| 4 | Title defaults | If title was blank, a date/time default title is shown |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-6: Calendar Day View — List Rendering

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | View today's Calendar | Lists section appears **above** Habit Check-in |
| 2 | List card shows | Title, checkbox items, "X/Y done" summary |
| 3 | Verify layout | Lists → Habits → Notes → Emoji Jar (in that order) |
| 4 | Switch to a day with only notes | No Lists section shown |
| 5 | Switch to a day with only lists | Lists section shows, no Notes section shown |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-7: Checkbox Toggle — EntryCard

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap empty checkbox ☐ on a list item | Checkbox changes to ☑, text gets strikethrough + greyed |
| 2 | Tap filled checkbox ☑ on same item | Returns to ☐, text returns to normal |
| 3 | Watch "X/Y done" counter | Updates in real time (1/3 → 2/3 → 1/3) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-8: Entry Detail Screen — Interactive List

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap a list entry card in Calendar | EntryDetailScreen opens |
| 2 | Verify title shown | Title displayed prominently |
| 3 | Verify checkboxes are tappable | Tap toggles state (same as EntryCard) |
| 4 | Verify strikethrough | Done items show strikethrough |
| 5 | Verify "X/Y done" | Summary shown at bottom |
| 6 | Tap the edit ✏️ button | Navigates to AddEntryScreen with list items pre-populated |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-9: Moments Screen — List Rendering

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Moments tab | All entries shown |
| 2 | Find a list entry | Same checkbox rendering as Calendar |
| 3 | Tap checkbox | Toggles in real time |
| 4 | Tap list entry row | Navigates to EntryDetailScreen |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-10: Edit Existing List Entry

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap a list entry → tap ✏️ | AddEntryScreen opens |
| 2 | Verify pre-population | Title field shows saved title, items list shows saved items |
| 3 | Add a new item, remove one, reorder | All operations work |
| 4 | Toggle an item's text by... | Should not be possible (edit from detail only) |
| 5 | Save changes | Entry updated, Calendar reflects changes |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-11: Carry-Forward (Requires Date Manipulation)

⚠️ **Setup:** Change device date to yesterday, create a list with some items left unchecked, then change date back to today.

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set device date to **yesterday** | |
| 2 | Create a list with 3 items, check 1 as done | 2 items unchecked |
| 3 | Set device date to **today** | |
| 4 | Open app / pull to refresh | New list entry appears for today |
| 5 | Verify banner | "2 items carried over from yesterday" banner on the new list |
| 6 | Dismiss banner with ✕ | Banner disappears |
| 7 | Verify new list | 2 unchecked items from yesterday (reset to unchecked) |
| 8 | Verify original list | Original yesterday list preserved (1 done, 2 unchecked) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-12: Bilingual UI

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set language to **English** | All list UI shows English labels |
| 2 | Toggle in AddEntryScreen | "Note" / "List" shown |
| 3 | List title placeholder | "List title" |
| 4 | Add item placeholder | "Add item" |
| 5 | Done counter | "X / Y done" |
| 6 | Carried-over banner | "N items carried over from yesterday" |
| 7 | Switch language to **中文** | All labels switch to Chinese |
| 8 | Verify Chinese labels | 笔记/清单, 清单标题, 添加事项, X/Y 已完成, N 个事项从昨天转入 |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-13: Emotion + Tags on List Entries

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a list, select emotion 😊 | Emotion saved |
| 2 | Select one or more tags | Tags saved |
| 3 | Attach a photo | Photo saved with list |
| 4 | Verify on detail view | Emotion, tags, and photo all display |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-14: Export/Import Round-Trip

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create 2 list entries with items | Data saved |
| 2 | Settings → Export → Backup to ZIP | ZIP file generated |
| 3 | Settings → Import → select ZIP | Data restored |
| 4 | Verify lists restored | List entries appear with items, checkbox states, and format preserved |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-15: Regression — Existing Features Unaffected

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a regular Note entry | Works as before |
| 2 | Complete a routine | Habit check-in works normally |
| 3 | AI Assistant chat | Works normally |
| 4 | Card creation/editing | Works normally |
| 5 | Emoji jar display | Shows correct emotions |
| 6 | Summary charts | Note counts include list entries |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Summary

| # | Test Case | Result |
|---|-----------|--------|
| 1 | Toggle Between Note/List Modes | ☐ PASS ☐ FAIL |
| 2 | Data Conversion on Toggle | ☐ PASS ☐ FAIL |
| 3 | Add List Items | ☐ PASS ☐ FAIL |
| 4 | List Item Management | ☐ PASS ☐ FAIL |
| 5 | Save List Entry | ☐ PASS ☐ FAIL |
| 6 | Calendar Day View Rendering | ☐ PASS ☐ FAIL |
| 7 | Checkbox Toggle (EntryCard) | ☐ PASS ☐ FAIL |
| 8 | Entry Detail Interactive List | ☐ PASS ☐ FAIL |
| 9 | Moments Screen Rendering | ☐ PASS ☐ FAIL |
| 10 | Edit Existing List | ☐ PASS ☐ FAIL |
| 11 | Carry-Forward | ☐ PASS ☐ FAIL |
| 12 | Bilingual UI | ☐ PASS ☐ FAIL |
| 13 | Emotion + Tags | ☐ PASS ☐ FAIL |
| 14 | Export/Import Round-Trip | ☐ PASS ☐ FAIL |
| 15 | Regression | ☐ PASS ☐ FAIL |

**Overall UAT Result:** ☐ PASS ☐ FAIL

**Tester Signature:** _______________ **Date:** _______________
