# Insights Phase 2 — CT2: Checklist Analytics — User Acceptance Testing (UAT)

**Build:** v1.1.0-beta.7+22 | **Date:** 2026-05-04 | **Tester:** Justin | **Result:** PASS ✅

---

## What Changed

New **Checklist Insights** section added to the Insights tab (洞察), positioned between the Trends charts and the Tag Impact on Mood section. Shows 4 stats: total lists created, avg completion rate, items carried forward, and the most commonly repeated item.

---

## Setup

- [x] App installed on both emulator and simulator and opens without crash
- [x] App has at least one checklist entry (Note → toggle to List → add items → save)
- [x] App language can be switched (Settings → Language)

---

## TC-1: Section Presence and Position

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app → Insights tab | Insights screen loads |
| 2 | Scroll down past the Trends section (4 charts with Day/Week/Month scope picker) | **"✅ Checklist Insights"** (EN) or **"✅ 清单洞察"** (ZH) section header is visible |
| 3 | Check position | Section appears **after** the Trends charts and **before** the Tag Impact on Mood section |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-2: Checklist Stats — With Data

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create 2 checklist entries with items, some checked off | Checklist Insights section shows stats |
| 2 | Row 1 | Icon (list_alt) + number of checklist entries created + label "lists created" (EN) / "已创建清单" (ZH) |
| 3 | Row 2 | Icon (check_circle_outline) + avg completion % (e.g. "67%") + label "avg completion" (EN) / "平均完成率" (ZH) |
| 4 | Row 3 | Icon (replay) + number of items carried forward + label "carried forward" (EN) / "已结转事项" (ZH) |
| 5 | Row 4 | Icon (push_pin) + most common item text in quotes (e.g. "drink water") + "top item (N×)" label |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-3: Checklist Stats — Empty State

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app with no checklist entries (only notes) | Checklist Insights section shows placeholder: "Create checklists to see insights" (EN) / "创建清单即可查看洞察" (ZH) |
| 2 | Create one checklist entry → return to Insights | Section now shows 1 list created, completion rate, etc. |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-4: Checklist Stats — Completion Rate Accuracy

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a list with 3 items: 2 checked, 1 unchecked | Completion rate for that list = 67% |
| 2 | Create another list with 4 items: all checked | Completion rate for that list = 100% |
| 3 | Go to Insights | Avg completion rate = (0.67 + 1.00) / 2 = 84% (displayed as 84%) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-5: Checklist Stats — Carried Forward Count

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create a list on "yesterday" with 3 unchecked items | — |
| 2 | On today, app prompts to carry forward — tap "Add" | 3 items are added to today's list with `fromPreviousDay = true` |
| 3 | Go to Insights | "carried forward" count = 3 |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-6: Checklist Stats — Top Item

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Create multiple lists with the same item appearing many times (e.g. "Drink water" in 3 different lists) | — |
| 2 | Go to Insights | Top item row shows "Drink water" with count = number of times it appears |
| 3 | Create a new item that appears more times | Top item updates to the new most-common item |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-7: Checklist Stats — Bilingual

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set language to English | Section title: "✅ Checklist Insights". Labels: "lists created", "avg completion", "carried forward", "top item" |
| 2 | Set language to Chinese | Section title: "✅ 清单洞察". Labels: "已创建清单", "平均完成率", "已结转事项", "最常见事项" |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## TC-8: Overall Insights Layout Integrity (post-CT2)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Insights tab and scroll top to bottom | Layout order: Hero stats → Calendar heatmap → Writing Stats → Mood donut → Trends → **Checklist Insights (NEW)** → Tag Impact → Mood jars |
| 2 | All sections render without overflow | No yellow/black overflow stripes. No render exceptions. |
| 3 | Switch language | All labels update correctly including new CT2 section |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Summary

| TC | Description | Result |
|----|-------------|:------:|
| TC-1 | CT2 section presence and position | ✅ PASS |
| TC-2 | CT2 stats with data | ✅ PASS |
| TC-3 | CT2 empty state | ✅ PASS |
| TC-4 | CT2 completion rate accuracy | ✅ PASS |
| TC-5 | CT2 carried forward count | ✅ PASS |
| TC-6 | CT2 top item | ✅ PASS |
| TC-7 | CT2 bilingual labels | ✅ PASS |
| TC-8 | Overall layout integrity | ✅ PASS |

