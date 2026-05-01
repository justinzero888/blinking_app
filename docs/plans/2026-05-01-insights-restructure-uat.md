# PROP-8: Keepsakes → Insights Restructure — User Acceptance Testing (UAT)

**Build:** v1.1.0-beta.5+20 | **Date:** 2026-05-01 | **Tester:** _______________ | **Result:** PASS / FAIL

---

## What Changed

The Keepsakes tab (珍藏) has been replaced with a focused Insights tab (洞察). Removed: emotion jar shelf browsing, yearly/monthly jar drill-down, card creation and editing, formatted keepsake card grid, "Make card" button in Moments. Kept: summary charts (4 chart types), yearly emoji jar carousel on Insights screen, HomeScreen emoji jar. The floating AI robot now appears on this tab. The "+" FAB is hidden on this tab.

---

## Setup

- [ ] App installed on Android emulator and opens without crash
- [ ] App has some existing data (entries with emotions, habits, tags) for charts to render
- [ ] App language can be switched between English and Chinese (Settings → Language)

---

## TC-1: Tab Label and Icon

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open the app | Bottom nav shows 5 tabs |
| 2 | Look at tab 4 (between Routine and Settings) | Label reads **"Insights"** (EN) or **"洞察"** (ZH). Icon is `Icons.insights` (lightbulb chart icon). |
| 3 | Switch language to Chinese (设置 → 语言 → 中文) | Tab 4 reads **"洞察"** |
| 4 | Switch back to English | Tab 4 reads **"Insights"** |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-2: Tab Navigation — Single View (No Sub-Tabs)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap the **Insights** tab | Screen loads with AppBar showing "Insights" (or "洞察"). **No TabBar** with sub-tabs (Shelf/Cards/Summary). Just one scrollable screen. |
| 2 | Scroll down | Content scrolls as a single list — emoji jar section at top, then summary charts below |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-3: Emoji Jar Carousel

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Look at the top of the Insights screen | Section header "🫙 Mood Jars" (EN) or "🫙 情绪罐" (ZH) |
| 2 | Below the header | Horizontal scrollable row of jars, one per year of data |
| 3 | Each jar card shows | A mini emoji jar (visual painting of emojis), the year number below it, and entry count (e.g. "43 entries" / "43 条记录") |
| 4 | Scroll horizontally through years | All years with data are shown, sorted newest first |
| 5 | Verify jars are NOT tappable | Tapping a jar does nothing (no drill-down to month detail) |
| 6 | Verify no "Ask AI" button on these jars | Mini jars are decorative only — no AI button below them |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-4: Summary Charts — Scope Picker

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scroll down past the emoji jar section | See Scope Picker with three chips: **Day / Week / Month** (EN) or **日 / 周 / 月** (ZH) |
| 2 | Tap **Day** | Charts update to show 7-day data. Day chip is selected/highlighted. |
| 3 | Tap **Week** | Charts update to show 8-week data. Week chip selected. |
| 4 | Tap **Month** | Charts update to show 6-month data. Month chip selected. |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-5: Note Count Bar Chart

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Look for "Note Counts" section (or i18n equivalent) | Section header visible |
| 2 | Below header | Bar chart showing entries per period (dates on x-axis, counts as bars) |
| 3 | Verify bars are teal `#2A9D8F` | Consistent with app's brand color |
| 4 | Tap a bar | Tooltip shows the exact count number |
| 5 | If no entries exist in scope | Shows "No data yet" (EN) / "暂无数据" (ZH) placeholder instead of empty chart |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-6: Habit Completion Rate Chart

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Look for "Habit Completion" section (or i18n equivalent) | Section header visible |
| 2 | Below header | Horizontal bar chart (one bar per habit routine) showing completion rate (0–100%) |
| 3 | Verify bars are teal `#2A9D8F` | Each bar represents one routine's completion rate |
| 4 | Tap a bar | Tooltip shows percentage value (e.g. "71%") |
| 5 | If no habits exist or all-zero | Shows "No data yet" placeholder |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-7: Mood Trend Line Chart

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Look for "Mood Trend" section (or i18n equivalent) | Section header visible |
| 2 | Below header | Line chart showing emotion scores over time (dates on x-axis, 1–5 score on y-axis) |
| 3 | Verify line is teal `#2A9D8F` with shaded area below | Curved line with 15% opacity teal fill underneath |
| 4 | Tap a data point | Tooltip shows emotion emoji corresponding to the score (😡=1, 😢=2, 😐=3, 😌=4, 😊=5) |
| 5 | If no emotion data exists | Shows "No data yet" placeholder |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-8: Top Tags Bar Chart

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Look for "Top Tags" section (or i18n equivalent) | Section header visible |
| 2 | Below header | Horizontal bar chart showing top 5 tags by usage count |
| 3 | Verify bars are colored per tag | Each bar uses its tag's assigned color (e.g. health=green, work=blue) |
| 4 | Verify tag names appear on y-axis | Shows localized tag name (EN name when English locale, ZH name when Chinese) |
| 5 | Tap a bar | Tooltip shows usage count |
| 6 | If no tags used | Shows "No data yet" placeholder |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-9: FAB Hidden on Insights Tab

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to Calendar tab (tab 0) | Green "+" FAB is visible at bottom-right |
| 2 | Navigate to Moments tab (tab 1) | FAB still visible |
| 3 | Navigate to Routine tab (tab 2) | FAB still visible |
| 4 | Navigate to **Insights tab** (tab 3) | **FAB is NOT visible** — no "+" button on this tab |
| 5 | Navigate to Settings tab (tab 4) | **FAB is NOT visible** |
| 6 | Return to Calendar | FAB reappears |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-10: Floating AI Robot on Insights Tab

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure AI is configured (valid API key or active trial) | Robot shows full opacity with bobbing animation on Calendar tab |
| 2 | Navigate to **Insights tab** | Robot is **visible** — same position (bottom-right above where FAB would be), bobbing animation |
| 3 | Tap the robot on Insights tab | Opens AI Assistant screen — can chat with AI about your insights |
| 4 | Navigate to Settings tab | Robot is **hidden** (returns to visible when leaving Settings) |
| 5 | Navigate back to Insights tab | Robot reappears |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-11: No "Make Card" Button in Moments

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to **Moments** tab | List of entries displayed |
| 2 | Look at any entry row | Entry shows content preview, date, tags |
| 3 | Check trailing area of each entry | Only tag count badge is visible. **No** `Icons.style_outlined` "Make card" button. |
| 4 | Long-press an entry | Delete dialog appears (same as before) |
| 5 | Tap an entry | Opens Entry Detail screen (same as before) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-12: HomeScreen Emoji Jar Still Works

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Navigate to **Calendar** tab | Calendar with today selected |
| 2 | Scroll down in the day view | Day view shows Lists, Habits, Notes sections |
| 3 | Look for the emoji jar section | Emoji jar widget with "Ask AI" button is visible when there are entries/emotions for the day |
| 4 | Tap "Ask AI" on the jar | Opens AI assistant with context about the selected day |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-13: Empty State (No Data)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | If possible, test with a fresh install (no data) | Insights tab shows centered icon + message |
| 2 | Verify empty state message | "Start journaling to see insights" (EN) / "开始记录即可查看洞察" (ZH) |
| 3 | Verify no charts or jar carousel shown | Only the empty state message and icon (`Icons.insights`) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-14: Dark Mode

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Switch to dark theme (Settings → Theme) | App switches to dark mode |
| 2 | Navigate to Insights tab | All elements render correctly against dark background — section headers, chart axes, jar labels visible |
| 3 | Verify chart colors adapt | Teal bars/line remain visible, empty state text readable |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-15: Chinese Locale

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Switch to Chinese (设置 → 语言 → 中文) | UI switches to Chinese |
| 2 | Navigate to Insights tab | Tab label: **"洞察"**, AppBar title: **"洞察"** |
| 3 | Verify jar section header | **"🫙 情绪罐"** |
| 4 | Verify scope picker | **"日" / "周" / "月"** |
| 5 | Verify chart section titles | All in Chinese (笔记数量, 习惯完成率, 情绪趋势, 热门标签) |
| 6 | Verify empty states | **"暂无数据"** and **"开始记录即可查看洞察"** |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Summary

| Test Case | Description | Result |
|:---------:|-------------|:------:|
| TC-1 | Tab label and icon — "Insights" / "洞察" | ☐ PASS ☐ FAIL |
| TC-2 | Single-view — no sub-tabs | ☐ PASS ☐ FAIL |
| TC-3 | Emoji jar carousel — scrollable, non-interactive | ☐ PASS ☐ FAIL |
| TC-4 | Scope picker — Day / Week / Month | ☐ PASS ☐ FAIL |
| TC-5 | Note count bar chart | ☐ PASS ☐ FAIL |
| TC-6 | Habit completion rate chart | ☐ PASS ☐ FAIL |
| TC-7 | Mood trend line chart with emoji tooltips | ☐ PASS ☐ FAIL |
| TC-8 | Top tags chart with per-tag colors | ☐ PASS ☐ FAIL |
| TC-9 | FAB hidden on Insights tab | ☐ PASS ☐ FAIL |
| TC-10 | Floating robot visible on Insights, hidden on Settings | ☐ PASS ☐ FAIL |
| TC-11 | No "Make card" button in Moments | ☐ PASS ☐ FAIL |
| TC-12 | HomeScreen emoji jar still works | ☐ PASS ☐ FAIL |
| TC-13 | Empty state (fresh install / no data) | ☐ PASS ☐ FAIL |
| TC-14 | Dark mode rendering | ☐ PASS ☐ FAIL |
| TC-15 | Chinese locale — all labels correct | ☐ PASS ☐ FAIL |

**Overall Result:** ☐ PASS ☐ FAIL

**Tester Signature:** _______________ **Date:** _______________
