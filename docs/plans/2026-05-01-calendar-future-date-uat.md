# Issue #1: Calendar Future Date Lock — User Acceptance Testing (UAT)

**Build:** v1.1.0-beta.5+20 | **Date:** 2026-05-01 | **Tester:** _______________ | **Result:** PASS / FAIL

---

## What Changed

Future dates on the calendar are now visually dimmed (35% opacity), non-tappable, and month navigation is limited to today + 2 months. This prevents users from accidentally interacting with dates that haven't happened yet.

---

## Setup

- [ ] App installed on Android emulator and opens without crash
- [ ] Current date is not the last day of the month (to have visible future dates in current month grid)

---

## TC-1: Future Dates — Visual Dimming (Current Month)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open the app to the Calendar tab | Calendar shows current month with today's date highlighted by a **teal outline** |
| 2 | Look at dates **after today** within the current month | Future dates appear **dimmed** (approximately 35% opacity) — visibly lighter than past dates and today |
| 3 | Look at **today's date** | Today's cell has a **teal border outline** (2px, `#2A9D8F`) — visually distinct from all other cells |
| 4 | Look at dates **before today** within the current month | Past dates appear at **full opacity** with no dimming — entries, emotion badges, habit progress bars visible as normal |
| 5 | Look at dates from **previous months** (navigate left) | Past dates in other months appear at **full opacity** — all indicators visible |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-2: Future Dates — Non-Interactive (Tap Does Nothing)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap a **future date** (any date after today in current month) | **Nothing happens.** The selected date does not change. The day view below does not update. No snackbar, no error — just silence. |
| 2 | Verify the selected date is still **today** (or whatever was selected before) | Today's cell keeps the teal outline (or previous selection highlight remains) |
| 3 | Tap a **past date** (any date before today) | Date selection **changes** — past date cell gets teal fill highlight, day view below updates to show that day's entries |
| 4 | Tap **today's date** | Today is selected — teal outline changes to teal fill highlight, day view shows today's entries and habits |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-3: Future Dates — Habit Check-in Not Rendered

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | If today is selected (default), verify habits appear in the day view below | ✅ Habit Check-in section shows pending/completed habits with checkboxes |
| 2 | Select a **past date** that has habits | ✅ Habit Check-in section shows habits for that date |
| 3 | Attempt to select a **future date** (tap future cell) | ❌ Selection does not change (per TC-2); habit check-in does not render for future dates because the query skips them |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-4: Month Navigation — Forward Limit (Today + 2 Months)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Note the current month (e.g. May 2026) | Month/year header shows current month |
| 2 | Tap **right chevron** to navigate forward one month | Calendar advances to **June 2026** — month header updates, all dates in June are dimmed (future) |
| 3 | Tap **right chevron** again to advance another month | Calendar advances to **July 2026** — all dates dimmed |
| 4 | Tap **right chevron** again | **Right chevron is disabled** (greyed out or non-responsive) — cannot advance past today + 2 months |
| 5 | Verify **left chevron** still works | Tap left chevron to go back to June → May — works normally |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-5: Month Navigation — Today Button Escape

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate forward to future month (e.g. June or July) | Calendar shows future month with all dates dimmed |
| 2 | Tap the **Today icon button** (calendar icon with dot, top-right of AppBar) | Calendar snaps back to **current month**, today's cell highlighted with teal outline |
| 3 | Verify today is selected and interactive | ✅ Today's cell has teal outline, habits and entries render below |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-6: Past Dates — Unrestricted Navigation

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap **left chevron** repeatedly | Can navigate back through past months indefinitely — no back-navigation limit |
| 2 | Navigate to a month from last year (e.g. March 2025) | Calendar shows that month, all dates at full opacity, entries/emotions visible |
| 3 | Tap **Today** button | Returns to current month immediately |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-7: Boundary Edge Case — Month + 2 Crosses Year

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | If testing in November 2026: Navigate right to December (month+1), then January 2027 (month+2) | Right chevron works for Dec and Jan, disabled after Jan |
| 2 | If testing in December 2026: Navigate right to January 2027 (month+1), then February 2027 (month+2) | Right chevron works for Jan and Feb, disabled after Feb |
| 3 | Verify month/year header correctly shows the future year | ✅ Header shows "January 2027" or "February 2027" correctly |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

> **Note:** This test case only applies if the current date is in November or December. Skip if testing in other months — the year-crossing logic in `_maxNavigableMonth()` is already covered by unit tests.

---

## TC-8: Add Entry — Not Blocked on Past Dates

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Select a **past date** on the calendar | Day view updates to show that past date |
| 2 | Tap **+ FAB** to add an entry | Add Entry screen opens — can create a note or list entry normally |
| 3 | Save the entry | Entry is saved with the past date, appears in the day view for that date |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-9: Dark Mode — Future Dates Still Dimmed

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Switch to dark theme (if available in Settings) | Calendar renders in dark mode |
| 2 | Verify future dates in current month | Future dates still appear dimmed (reduced opacity) in dark mode — visually distinct from past dates |
| 3 | Verify today's teal outline | Today's cell has visible teal outline against dark background |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-10: Chinese Locale — All Labels Correct

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Switch app language to Chinese (设置 → 语言 → 中文) | UI switches to Chinese |
| 2 | Verify calendar month header | Shows `yyyy年M月` format (e.g. `2026年5月`) |
| 3 | Verify weekday labels | Show `日 一 二 三 四 五 六` |
| 4 | Verify future dates dimmed | ✅ Future dates dimmed regardless of locale |
| 5 | Verify today button tooltip | Shows `今天` on long-press |
| 6 | Verify habit section labels | Show `📋 今日清单`, `✅ 习惯打卡`, `📝 笔记` |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Summary

| Test Case | Description | Result |
|:---------:|-------------|:------:|
| TC-1 | Future dates visually dimmed | ☐ PASS ☐ FAIL |
| TC-2 | Future dates non-interactive (tap ignored) | ☐ PASS ☐ FAIL |
| TC-3 | Habit check-in not rendered for future | ☐ PASS ☐ FAIL |
| TC-4 | Month nav limited to today+2 | ☐ PASS ☐ FAIL |
| TC-5 | Today button escape from future month | ☐ PASS ☐ FAIL |
| TC-6 | Past dates unrestricted navigation | ☐ PASS ☐ FAIL |
| TC-7 | Year boundary edge case | ☐ PASS ☐ FAIL ☐ N/A |
| TC-8 | Add entry on past dates still works | ☐ PASS ☐ FAIL |
| TC-9 | Dark mode future dimming | ☐ PASS ☐ FAIL |
| TC-10 | Chinese locale labels correct | ☐ PASS ☐ FAIL |

**Overall Result:** ☐ PASS ☐ FAIL

**Tester Signature:** _______________ **Date:** _______________
