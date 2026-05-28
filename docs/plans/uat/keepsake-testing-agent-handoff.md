# Keepsake Cards UAT — Testing Agent Handoff

> **Feature:** Keepsake Cards (v1.2.0)  
> **Date:** May 27, 2026  
> **Target:** v1.2.0+41 production ship  
> **Builds:** iPhone 17 Pro, iPad Air 11" (M4), Android Medium Phone API 36 — all clean builds, installed fresh

---

## 1. Pre-flight

```bash
# Verify Maestro CLI is installed
maestro --version  # expect 1.37+ 

# Verify simulators are running
xcrun simctl list devices | grep "Booted"
# Expected: iPhone 17 Pro, iPad Air 11-inch (M4)

adb devices
# Expected: emulator-5554  device

# Verify app is installed on each
xcrun simctl get_app_container E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA com.blinking.blinking
xcrun simctl get_app_container 39B46CD1-C3B5-43C1-B527-A5BCFECEA773 com.blinking.blinking
adb -s emulator-5554 shell pm list packages | grep blinking
```

---

## 2. Run All Automated Flows

### iPhone (10 flows)
```bash
cd /Users/justinzero/ClaudeDev/blink/blinking_app
./maestro-tests/ci/run-uat-iphone.sh
```

### iPad (10 flows)
```bash
./maestro-tests/ci/run-uat-ipad.sh
```

### Android (10 flows)
```bash
./maestro-tests/ci/run-uat-android.sh
```

### Run a single flow
```bash
maestro test --device <device-uuid> maestro-tests/apps/blink-notes/flows/uat/k1-core-create.yaml
```

---

## 3. Automated Test Cases (Maestro)

All flows use `clearState: true` — each starts from a fresh install with 8 demo entries seeded.

### K1 — Core Keepsake Creation (End-to-End)
**File:** `flows/uat/k1-core-create.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Launch app (clear state) | — |
| 2 | Tap Moment tab | — |
| 3 | Tap first entry "今日阳光正好" | Entry detail opens |
| 4 | Tap `btn_save_keepsake` | Builder sheet opens |
| 5 | Verify sheet title | "Save as Keepsake" visible |
| 6 | Verify template picker | "Choose Template" visible |
| 7 | Tap bamboo template | `template_tpl_bamboo` selected |
| 8 | Toggle mood OFF | `toggle_show_mood` tapped |
| 9 | Tap Save | `btn_card_save` tapped |
| 10 | Wait for save | "Keepsake saved" snackbar |
| 11 | Verify badge | `badge_keepsake` visible |
| 12 | Tap badge | Preview opens |
| 13 | Verify preview | "Keepsake Preview" title |
| 14 | Verify Edit button | `btn_edit_card` visible |
| 15 | Verify Share button | `btn_share_card` visible |
| 16 | Back to entry | Arrow back tapped |

**Expected result:** Card created, badge visible, preview shows Edit+Share, back navigation works.

---

### K2 — All 8 Templates Render & Select
**File:** `flows/uat/k2-template-cycle.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Open builder from first entry | — |
| 2 | Verify all 8 template identifiers | `template_tpl_ink_rhythm` through `template_tpl_landscape` |
| 3 | Tap moonlight | Selection changes |
| 4 | Tap porcelain | Selection changes |
| 5 | Tap landscape | Selection changes |
| 6 | Tap ink_rhythm | Returns to first |
| 7 | Verify Save button | `btn_card_save` still visible |

**Expected result:** All 8 thumbnails in accessibility tree, selection responds to tap, save button never disappears.

**Note:** Visual fidelity of rendered template is manual (MV-1 through MV-8 in manual QA section).

---

### K3 — Toggle Elements On/Off
**File:** `flows/uat/k3-toggle-elements.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Open builder | — |
| 2 | Verify section header | "Show Elements" visible |
| 3 | Verify Mood toggle | Label "Mood" visible |
| 4 | Verify Date toggle | Label "Date" visible |
| 5 | Verify Tags toggle | Label "Tags" visible |
| 6 | Verify Footer toggle | Label "Footer" visible |
| 7 | Tap mood OFF | `toggle_show_mood` |
| 8 | Tap tags OFF | `toggle_show_tags` |
| 9 | Verify Save button | Still visible after toggles |

**Expected result:** All 4 toggles exist, respond to tap, save button functional after changes.

---

### K4 — AI Rewrite Button
**File:** `flows/uat/k4-ai-rewrite.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Open builder from first entry | — |
| 2 | Verify AI Rewrite button | "AI Rewrite" visible |
| 3 | Tap AI Rewrite | Triggers LLM request |
| 4 | Verify content field | "Your words..." still visible |

**Expected result:** Button visible and tappable. Content field remains after rewrite (validates button wiring, not LLM response).

---

### K5 — Empty Content Validation
**File:** `flows/uat/k5-empty-content.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Open builder | — |
| 2 | Clear content field | Erase all text |
| 3 | Tap Save | — |
| 4 | Verify snackbar | Contains "content" (EN) or "内容" (ZH) |

**Expected result:** Save rejected with validation message. Sheet stays open.

---

### K6 — Badge → Preview → Edit/Share → Back
**File:** `flows/uat/k6-badge-preview.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Open builder, save with default template | — |
| 2 | Wait for "Keepsake saved" | Snackbar visible |
| 3 | Tap badge | Preview opens |
| 4 | Verify preview title | "Keepsake Preview" |
| 5 | Verify Edit button | `btn_edit_card` |
| 6 | Verify Share button | `btn_share_card` |
| 7 | Back | Arrow back |
| 8 | Verify return | `btn_save_keepsake` visible again |

**Expected result:** Full round-trip: entry → save → badge → preview → back to entry.

---

### K7 — Photo Keepsake
**File:** `flows/uat/k7-photo-keepsake.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Tap Moment, first entry | — |
| 2 | Open builder | — |
| 3 | Verify builder opens | "Save as Keepsake", save button visible |

**Expected result:** Builder opens normally with photo path forwarded. 

**Manual verification needed:** Create entry with photo → save as keepsake → verify photo renders on card (full-bleed for hero/centered, header for two-column, thumbnail for left-aligned).

---

### K8 — ZH Locale: Chinese UI
**File:** `flows/uat/k8-locale-zh.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Launch app (defaults to ZH) | — |
| 2 | Open builder | — |
| 3 | Verify picker label | "选择模板" |
| 4 | Verify template names | "墨韵", "素笺", "竹影" visible |
| 5 | Verify toggle labels | "心情", "日期", "标签", "水印" |
| 6 | Verify save button | "保存纪念" |

**Expected result:** All UI strings in Chinese when locale is ZH.

---

### K9 — Edit Existing Keepsake
**File:** `flows/uat/k9-edit-keepsake.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | Create card with ink_rhythm template | — |
| 2 | Wait for save | "Keepsake saved" |
| 3 | Tap badge → preview | Preview opens |
| 4 | Tap Edit | Builder re-opens |
| 5 | Change template to seal | `template_tpl_seal` |
| 6 | Save again | "Keepsake saved" |
| 7 | Verify badge | Still present after edit |

**Expected result:** Badge → Edit → re-opens builder → change template → save → badge remains.

---

### K10 — Three Entry Points
**File:** `flows/uat/k10-three-entry-points.yaml`

| Step | Action | Assertion |
|------|--------|-----------|
| 1 | **Entry 1: EntryDetail** | — |
| 2 | Tap Moment, first entry | `btn_save_keepsake` visible |
| 3 | **Entry 2: Assistant** | — |
| 4 | Tap robot emoji | Assistant screen loads |
| 5 | Verify screen | "AI Assistant" visible |
| 6 | Back | Arrow back |
| 7 | **Entry 3: Reflection** | — |
| 8 | Tap robot again | Assistant screen loads |
| 9 | Verify screen | "AI Assistant" visible |

**Expected result:** All 3 keepsake entry points reachable. EntryDetail button always visible. Assistant/Reflection buttons conditional on saved content.

---

## 4. Manual Visual QA (8 Cases)

Maestro can verify element presence and text, but cannot verify visual quality. These 8 cases must be checked manually on every template.

| ID | Template | Check |
|----|----------|-------|
| MV-1 | 🖋️ 墨韵 | Background image renders, text centered, padding ~180px top, no yellow backdrop |
| MV-2 | 📃 素笺 | Left-aligned text, rice paper lines visible, accent bar on left, padding ~160px |
| MV-3 | 🎋 竹影 | Bamboo leaf motif visible at bottom-right, text centered, padding ~140px top |
| MV-4 | 🌙 月色 | Dark night background, crescent moon visible at upper-right, cream text, padding ~200px |
| MV-5 | 🏺 青花 | Porcelain border at top, text centered, padding ~120px top |
| MV-6 | 🍵 茶语 | Steam wisps visible, warm beige background, left-aligned text, padding ~200px |
| MV-7 | 🔴 朱砂 | Red seal stamp at bottom-right, text centered, padding ~200px |
| MV-8 | 🏔️ 山水 | Mountain silhouettes at bottom, text centered, padding ~200px |

### Sequence for each manual case
1. Tap today's entry → Save as Keepsake → select template
2. Verify builder shows correct template name + icon
3. Tap Save → wait for card to render
4. Tap badge → CardPreviewScreen shows
5. Inspect: background, text position, overlay elements, no yellow lines
6. Pinch-to-zoom works, back button works
7. Delete card (tap Edit → close builder — no delete flow yet)

### Cross-platform checklist per template
| Platform | MV-1 | MV-2 | MV-3 | MV-4 | MV-5 | MV-6 | MV-7 | MV-8 |
|----------|------|------|------|------|------|------|------|------|
| iPhone 17 Pro | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| iPad Air 11" | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Android | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

---

## 5. Test Data (Pre-seeded)

Each fresh install creates 8 demo entries:

| # | Content | Emotion | Length |
|---|---------|---------|--------|
| 1 | 今日阳光正好，微风不燥。 | 😊 | 12 chars |
| 2 | 感谢清晨的第一杯咖啡... | 😌 | 45 chars |
| 3 | Sometimes the smallest step... | 😌 | ~50 words |
| 4 | 静。 | 😊 | 1 char |
| 5 | 人生如茶，第一道苦若生命... | 😌 | ~100 chars |
| 6 | 今天的晨跑格外畅快... | 😊 | ~60 chars |
| 7 | The rain tapped softly... | 😢 | ~60 words |
| 8 | Work has been overwhelming... | 😡 | ~80 words |

Use entry 1 for quick tests, entry 5 for overflow testing, entries 3/7 for English rendering.

---

## 6. Semantics Identifiers Reference

These accessibility identifiers are used by Maestro flows:

| Identifier | Element |
|------------|---------|
| `btn_save_keepsake` | Save as Keepsake button (EntryDetail AppBar) |
| `card_builder_content` | Content text field in builder |
| `template_tpl_ink_rhythm` | 🖋️ 墨韵 thumbnail |
| `template_tpl_plain_paper` | 📃 素笺 thumbnail |
| `template_tpl_bamboo` | 🎋 竹影 thumbnail |
| `template_tpl_moonlight` | 🌙 月色 thumbnail |
| `template_tpl_porcelain` | 🏺 青花 thumbnail |
| `template_tpl_tea` | 🍵 茶语 thumbnail |
| `template_tpl_seal` | 🔴 朱砂 thumbnail |
| `template_tpl_landscape` | 🏔️ 山水 thumbnail |
| `toggle_show_mood` | Mood toggle switch |
| `toggle_show_date` | Date toggle switch |
| `toggle_show_tags` | Tags toggle switch |
| `toggle_show_footer` | Footer toggle switch |
| `btn_card_save` | Save Keepsake button in builder |
| `badge_keepsake` | Keepsake badge chip on EntryDetail |
| `btn_edit_card` | Edit button in CardPreviewScreen |
| `btn_share_card` | Share button in CardPreviewScreen |
| `btn_reflection_save_keepsake` | Save as Keepsake in Reflection session |
| `btn_assistant_save_keepsake` | Save as Keepsake in Assistant screen |

---

## 7. Success Criteria (Ship Gate)

- [ ] All 10 Maestro flows pass on iPhone (10/10)
- [ ] All 10 Maestro flows pass on iPad (10/10)
- [ ] All 10 Maestro flows pass on Android (10/10)
- [ ] All 24 manual QA cells checked (8 templates × 3 platforms)
- [ ] No crashes during save on any platform
- [ ] No yellow underline on any template
- [ ] Background images render on all platforms
- [ ] Overlay elements (mood/date/tags/footer) correctly sized
- [ ] Photo cards render correctly (full-bleed/header/thumbnail per layout)
- [ ] AI Rewrite preamble does not appear in card content
