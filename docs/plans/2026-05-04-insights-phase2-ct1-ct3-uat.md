# Insights Phase 2 — CT1 & CT3: User Acceptance Testing (UAT)

**Build:** v1.1.0-beta.7+22 | **Date:** 2026-05-04 | **Tester:** Justin | **Result:** PASS ✅

---

## What Changed

Two new sections added to the Insights tab (洞察):

1. **CT1 — Writing Stats:** New section between the calendar heatmap and mood distribution. Shows 3 stat cards: avg words per entry, most active day of the week, peak writing hour.
2. **CT3 — Tag Impact on Mood:** New section between the trends and mood jars. Shows which tags correlate with higher/lower mood scores (min 3 entries per tag).

---

## Setup

- [x] App installed on Android emulator and opens without crash
- [x] App has entries with emotions and tags attached (for CT3 to show data)
- [x] App language can be switched (Settings → Language)

---

## CT1: Writing Stats Section

### TC-1: Section Presence and Position

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app → Insights tab | Insights screen loads |
| 2 | Scroll down past the hero stats cards and calendar heatmap | **"🔥 Writing Stats"** (EN) or **"🔥 写作统计"** (ZH) section header is visible |
| 3 | Check position | Section appears **after** the calendar heatmap and **before** the mood distribution donut |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-2: Writing Stats Cards (3 cards in a row)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Look at the Writing Stats section | 3 mini stat cards in a horizontal row |
| 2 | Card 1 (left) | Icon (text_fields), value shows avg words per entry (e.g. "12.5"), label "avg words" (EN) / "平均字数" (ZH) |
| 3 | Card 2 (center) | Icon (calendar_today), value shows most active weekday (e.g. "Sun" or "周日"), label "most active" (EN) / "最活跃日" (ZH) |
| 4 | Card 3 (right) | Icon (schedule), value shows peak hour (e.g. "14:00"), label "peak hour" (EN) / "最活跃时段" (ZH) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-3: Writing Stats — No Data State

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open a fresh install with no entries | Insights tab shows empty state |
| 2 | Add 1 entry, go to Insights | Writing Stats section appears with avg words ≈ content word count, active day = the day of the entry, peak hour = hour of the entry |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-4: Writing Stats — Bilingual Labels

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set language to English (Settings → Language → English) | Card labels: "avg words", "most active", "peak hour". Most active day shows English abbreviation (Mon, Tue, etc.) |
| 2 | Set language to Chinese (设置 → 语言 → 中文) | Card labels: "平均字数", "最活跃日", "最活跃时段". Most active day shows Chinese (周一, 周二, etc.) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-5: Writing Stats — Value Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app with known entry data | Verify avg words is total words / total entries (CJK + English word counting: each CJK char = 1 word, English words = whitespace tokens) |
| 2 | Check most active day | Verify the weekday shown has the highest entry count across all time |
| 3 | Check peak hour | Verify the hour shown has the highest entry count (24h format, e.g. "14:00") |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## CT3: Tag Impact on Mood Section

### TC-6: Section Presence and Position

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app → Insights tab | Insights screen loads |
| 2 | Scroll down past the trends section (4 charts with Day/Week/Month scope picker) | **"🔬 Tag Impact on Mood"** (EN) or **"🔬 标签与情绪"** (ZH) section header is visible |
| 3 | Check position | Section appears **after** the trends charts and **before** the mood jars carousel |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-7: Tag-Mood Rows (with data)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure app has ≥3 entries with both a tag AND an emotion attached to the same tag | Tag-mood rows appear |
| 2 | Each row shows from left to right: tag name → colored mood bar → mood emoji → score (e.g. "4.2/5") | All elements rendered correctly |
| 3 | Rows are sorted by score descending | Happiest tag (highest avg mood) is at the top |
| 4 | Bar color reflects mood level: 😡 (1) red, 😢 (2) blue, 😐 (3) yellow, 😌 (4) teal light, 😊 (5) green | Colors are appropriate for each score tier |
| 5 | Max 5 tags shown | If more than 5 tags qualify, only top 5 are displayed |
| 6 | Footnote at bottom | "Tags with ≥3 entries shown" (EN) / "显示出现 3 次以上的标签" (ZH) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-8: Tag-Mood — Empty State

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app with no entries, or entries with no tags, or no emotions, or <3 entries per tag | Section shows placeholder text |
| 2 | EN locale | "Need more entries with tags & emotions" |
| 3 | ZH locale | "需要更多带标签和情绪的记录" |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-9: Tag-Mood — Minimum Threshold (3 entries)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a tag with only 2 entries (both with emotions) | That tag does NOT appear in the Tag Impact section |
| 2 | Add a 3rd entry with that tag + emotion | The tag now appears in the Tag Impact section |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-10: Tag-Mood — Bilingual Labels

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set language to English | Section title: "🔬 Tag Impact on Mood". Footnote: "Tags with ≥3 entries shown". Tag names use English names if available |
| 2 | Set language to Chinese | Section title: "🔬 标签与情绪". Footnote: "显示出现 3 次以上的标签". Tag names use Chinese names |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-11: Tag-Mood — Correlation Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a tag "Exercise" with 3 entries, all with emotion 😊 (score 5) | Avg score = 5.0. Row shows 😊 emoji and "5.0/5" with full green bar |
| 2 | Create a tag "Work" with 3 entries: 😊, 😐, 😡 (scores 5, 3, 1) | Avg score = 3.0. Row shows 😐 emoji and "3.0/5" with half yellow bar |
| 3 | "Exercise" tag should appear above "Work" tag | Sorting by avg score descending works correctly |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

### TC-12: Overall Insights Layout Integrity

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Insights tab and scroll top to bottom | Layout order: Hero stats cards → Calendar heatmap → **Writing Stats (NEW)** → Mood distribution donut → Trends (4 charts) → **Tag Impact on Mood (NEW)** → Mood jars carousel |
| 2 | All sections render without overflow | No yellow/black overflow stripes. No render exceptions. |
| 3 | Switch between Day/Week/Month scope in trends | No crash. Trends charts update correctly. |
| 4 | Switch language | All new section labels and content update correctly |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Summary

| TC | Description | Result |
|----|-------------|:------:|
| TC-1 | CT1 section presence and position | ✅ PASS |
| TC-2 | CT1 3 stat cards rendered correctly | ✅ PASS |
| TC-3 | CT1 no data state | ✅ PASS |
| TC-4 | CT1 bilingual labels | ✅ PASS |
| TC-5 | CT1 value accuracy | ✅ PASS |
| TC-6 | CT3 section presence and position | ✅ PASS |
| TC-7 | CT3 tag-mood rows with data | ✅ PASS |
| TC-8 | CT3 empty state | ✅ PASS |
| TC-9 | CT3 3-entry threshold | ✅ PASS |
| TC-10 | CT3 bilingual labels | ✅ PASS |
| TC-11 | CT3 correlation accuracy | ✅ PASS |
| TC-12 | Overall layout integrity | ✅ PASS |

