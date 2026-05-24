# Phase 3 — Keepsake Cards UAT

> **Scope:** v1.2.0 Keepsake-only | **Updated:** May 23, 2026  
> **Test framework:** Maestro (`.yaml` flows on simulators) + Manual (real devices)  
> **Flow root:** `maestro-tests/apps/blink-notes/flows/uat/`

---

## Maestro-Automatable (22 cases)

These can be automated with Maestro flows on iPhone/iPad/Android simulators.
Add flows in `maestro-tests/apps/blink-notes/flows/uat/`.

### Core Creation Flow (P0)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-1 | Create keepsake from entry | iPhone | 1. Create entry with emotion + tags. 2. EntryDetail → tap "Save as Keepsake" (🖼️ icon). 3. Builder opens — verify pre-filled content. 4. Select 墨韵 template. 5. Toggle mood ON. 6. Scroll to "保存纪念" → tap. 7. Wait for snackbar "纪念已保存". 8. Dismiss builder. | Builder opens with pre-filled content. Save completes. Badge appears on EntryDetail. |
| MK-2 | Create keepsake from entry | iPad | Same as MK-1 | Same result. No layout issues on iPad. |
| MK-3 | Create keepsake from AI reflection | iPhone | 1. AI → Run Daily Reflection. 2. Wait for content. 3. Tap "Save Reflection". 4. Tap "保存为纪念" button. 5. Pick 月色 template. 6. Tap "保存纪念". | Reflection text pre-filled. Moonlight template renders. Badge visible on saved entry. |
| MK-4 | Create keepsake from Assistant | iPhone | 1. Assistant → multi-turn chat. 2. Tap "Save reflection" in AppBar. 3. Wait for snackbar. 4. Tap "保存为纪念" icon in AppBar. 5. Pick 茶语 template. 6. Save. | Assistant reflection pre-filled in builder. Saves correctly. |

### Template Browsing (P0)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-5 | Browse all 8 templates | iPhone | 1. Open builder from any entry. 2. Scroll template picker horizontally. 3. Verify 8 thumbnails visible. 4. Tap each one — selection highlight changes. 5. Create card with each of 8 templates. | 8 thumbnails shown. Each selectable. All 8 templates produce valid cards without crash. Visual fidelity is manual verification. |

### Badge Visibility & Preview (P0)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-6 | Keepsake badge visible | iPhone | 1. After MK-1, return to EntryDetailScreen. 2. Scroll to bottom. | Badge chip visible with text "纪念 · 墨韵". |
| MK-7 | Badge tap → CardPreviewScreen | iPhone | 1. Tap badge chip. 2. Wait for navigation. | CardPreviewScreen opens. Image displayed (or re-render placeholder). AppBar shows "纪念预览". Share + Edit icons visible. |
| MK-8 | No badge on entry without card | iPhone | 1. Create entry without saving as keepsake. 2. Navigate to EntryDetailScreen. | No badge chip visible anywhere. |
| MK-9 | Badge shows correct template name | iPhone | 1. Create keepsakes on 2 entries with different templates. 2. Check badge on each. | Badge text matches the template used (e.g. "纪念 · 月色" for Moonlight, "纪念 · 朱砂" for Seal). |

### Photo Integration (P0-P1)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-10 | Photo as background (hero template) | iPhone | 1. Create entry with photo. 2. Save as Keepsake → 墨韵 template. 3. Preview. | Photo appears as background. Text readable with backdrop. |
| MK-11 | Photo inline (journal template) | iPhone | 1. Entry with photo → Save as Keepsake → 素笺 template. 2. Preview. | Photo appears as inline thumbnail below text. |
| MK-12 | No photo entry → clean template | iPhone | 1. Text-only entry → Save as Keepsake → any template. 2. Preview. | Clean gradient background. No broken image placeholder. |

### Toggle Overlays (P1)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-13 | Emotion emoji ON/OFF | iPhone | 1. Entry with 😊 → Builder → toggle mood OFF → save. 2. Preview. 3. Edit → toggle mood ON → save. 4. Preview. | OFF: no 😊 on card. ON: 😊 visible. |
| MK-14 | Tags as hashtags ON/OFF | iPhone | 1. Entry with #日记 #日常 → Builder → tags ON → save. 2. Preview. 3. Edit → tags OFF → save. 4. Preview. | ON: "#日记 #日常" at bottom. OFF: not present. |
| MK-15 | System tags excluded | iPhone | 1. Entry with tag_synthesis tag. 2. Save as Keepsake → tags ON. 3. Preview. | "synthesis" or "tag_synthesis" NOT in hashtags on card. |
| MK-16 | Date stamp ON/OFF | iPhone | 1. Builder → date ON → save. 2. Preview. 3. Edit → date OFF → save. 4. Preview. | ON: date text visible. OFF: not present. |
| MK-17 | Footer ON/OFF | iPhone | 1. Builder → footer ON → save → preview → "Blinking Notes" visible. 2. Edit → footer OFF → save → preview → footer absent. | Toggle works correctly. |

### Edit & Share (P1)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-18 | Edit keepsake | iPhone | 1. Badge → Preview. 2. Tap edit icon (✏️). 3. Builder opens with pre-filled content + config. 4. Change template to 素笺, edit text. 5. Save. 6. Check badge now shows "纪念 · 素笺". | Builder opens with prior content/config. Updated card saves. Badge reflects new template. |
| MK-19 | Share keepsake | iPhone | 1. Badge → Preview. 2. Tap share icon. 3. System share sheet opens. | Share sheet opens with PNG file attached. Excluded on iPad (UIPopover limitation). |

### Locale (P1)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-20 | ZH locale template names | iPhone | 1. Set locale to 中文. 2. Open builder. 3. Browse templates. | Names: 墨韵, 素笺, 竹影, 月色, 青花, 茶语, 朱砂, 山水. |
| MK-21 | EN locale template names | iPhone | 1. Set locale to English. 2. Open builder. 3. Browse templates. | Names: Ink Rhythm, Plain Paper, Bamboo Shadow, Moonlight, Blue Porcelain, Tea Whisper, Cinnabar Seal, Landscape. |
| MK-22 | ZH locale builder labels | iPhone | 1. Locale = 中文 → open builder. | Title: "保存为纪念". Labels: "选择模板", "内容", "心情", "日期", "标签", "水印", "AI 润色", "保存纪念". |
| MK-23 | EN locale builder labels | iPhone | 1. Locale = EN → open builder. | Title: "Save as Keepsake". Labels: "Choose Template", "Content", "Mood", "Date", "Tags", "Footer", "AI Rewrite", "Save Keepsake". |

### Android (P0)

| ID | Description | Device | Steps | Expected |
|----|-------------|--------|-------|----------|
| MK-24 | Create keepsake on Android | Android | Same as MK-1. | Same result. Share sheet opens on Android. |

---

## Manual-Only (8 cases)

Cannot be automated — requires human visual inspection, app reinstall, real-time LLM calls, or external tooling.

### Visual Rendering Fidelity

| ID | Description | Device | Steps | Expected | Why Manual |
|----|-------------|--------|-------|----------|------------|
| MV-1 | All 8 templates visual QA | iPhone + iPad | 1. Create keepsake with each template. 2. Preview each. 3. Check: gradient correct, colors match spec, text readable, overlays positioned. | Each template matches design specs (ink wash gradient, crescent moon, bamboo leaf, porcelain borders, steam curves, seal stamp, mountain silhouettes, rice paper texture). | Maestro cannot verify pixel-level visual fidelity. |
| MV-2 | Decorative motifs render | iPhone | 1. Create card with 竹影 → check bamboo leaf visible. 2. 朱砂 → red seal visible. 3. 山水 → mountain silhouettes. 4. 月色 → crescent moon. 5. 茶语 → steam curves. 6. 青花 → porcelain borders. | Each decorative element is visually distinct and correctly positioned. | Maestro cannot verify SVG/gradient rendering. |
| MV-3 | Style override: font color | iPhone | 1. Builder → Style → change font color to red. 2. Save → Preview. | Text color is correct hex. | Maestro cannot verify color output. |
| MV-4 | Dark mode consistency | iPhone | 1. Switch to dark theme. 2. Create keepsake with 月色 template. 3. Check all templates. | Templates render consistently (dark backgrounds stay dark, light stay light). Text readable. | Maestro can toggle theme but cannot verify visual consistency. |

### Device-Specific

| ID | Description | Device | Steps | Expected | Why Manual |
|----|-------------|--------|-------|----------|------------|
| MV-5 | iPad share keepsake | Real iPad | 1. Create keepsake on iPad. 2. Badge → Preview → tap share. | Share sheet opens on iPad. File attached. | iPad UIPopover — XCTest cannot traverse iPads `UIActivityViewController`. |
| MV-6 | Restore — keepsake survives re-render | iPhone | 1. Create 3 keepsakes. 2. Export backup. 3. Uninstall app. 4. Reinstall. 5. Restore backup. 6. Open entry with keepsake → badge visible. 7. Tap badge → re-renders correctly. | Badge visible after restore. Tap badge → card re-renders with correct template + content. | Requires uninstall → reinstall cycle. |
| MV-7 | Backup size — no PNG bloat | iPhone | 1. Create 5 keepsakes. 2. Export backup. 3. Check ZIP file size externally. | Backup < 200KB larger than without keepsakes (metadata-only, ~2KB per card). | Requires external file system inspection. |

### AI-Dependent

| ID | Description | Device | Steps | Expected | Why Manual |
|----|-------------|--------|-------|----------|------------|
| MV-8 | AI Rewrite button works | iPhone | 1. Entry → Save as Keepsake → Builder. 2. Tap "AI 润色". 3. Wait for LLM response. | Content changes to AI-rewritten version. Loading spinner displays during call. Button disabled during loading. Error handling if AI unavailable. | Requires real-time LLM call with variable latency. |

---

## Entry Point Matrix

Verify all keepsake entry points work:

| Entry Point | Screen | Action | Manual / Maestro |
|-------------|--------|--------|:---:|
| Entry detail | `EntryDetailScreen` | AppBar 🖼️ icon → CardBuilderSheet | MK-1, MK-2 |
| AI reflection | `ReflectionSessionScreen` | "保存为纪念" button after save | MK-3 |
| Assistant chat | `AssistantScreen` | AppBar 🖼️ icon after save reflection | MK-4 |
| Keepsake badge | `EntryDetailScreen` | Chip tap → CardPreviewScreen | MK-7 |
| Card preview share | `CardPreviewScreen` | Share icon → system share sheet | MK-19 |
| Card preview edit | `CardPreviewScreen` | Edit icon → CardBuilderSheet | MK-18 |

---

## Priority Order for Flow Creation

| Priority | Flow | Cases Covered | Effort |
|:--------:|------|:---:|:------:|
| P0 | `k1-core-create` | MK-1, MK-6, MK-7 | Medium |
| P0 | `k2-ipad-create` | MK-2 | Low |
| P0 | `k3-android-create` | MK-24 | Low |
| P1 | `k4-template-browse` | MK-5 | Medium |
| P1 | `k5-toggle-overlays` | MK-13, MK-14, MK-16, MK-17 | Medium |
| P1 | `k6-edit-keepsake` | MK-18 | Low |
| P1 | `k7-locale` | MK-20, MK-21, MK-22, MK-23 | Low |
| P1 | `k8-reflection-entry` | MK-3, MK-4 | Medium |
| P1 | `k9-photo-integration` | MK-10, MK-11, MK-12 | Medium |
| P1 | `k10-badge-mapping` | MK-8, MK-9, MK-15 | Low |

---

## Summary

| Category | Count |
|----------|:----:|
| Maestro-automatable | 22 (MK-1 to MK-24) |
| Manual-only | 8 (MV-1 to MV-8) |
| **Total UAT cases** | **30** |
| Maestro flows to build | 10 |
