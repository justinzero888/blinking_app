# Keepsake Cards — UAT Automation Catalog

> **Phase 3 | Scope:** v1.2.0 Keepsake-only | **Updated:** May 23, 2026  
> **Master doc:** `uat_automation.md`

---

## Maestro-Automatable (20 cases)

These can be automated with Maestro flows. Add a flow in `maestro-tests/apps/blink-notes/flows/uat/`.

| ID | UAT Ref | Description | Effort | Notes |
|----|---------|-------------|--------|-------|
| k1-iphone | K-1 | Create keepsake from entry (iPhone) | Low | EntryDetail → tap "Save as Keepsake" → pick template → toggle mood ON → Save → assert badge visible |
| k2-ipad | K-2 | Create keepsake from entry (iPad) | Low | Same flow on iPad simulator |
| k3-reflection | K-3 | Create keepsake from AI reflection | Low | AI → Save Reflection → tap Save as Keepsake → pick template → Save |
| k4-assistant | K-4 | Create keepsake from Assistant saved reflection | Medium | Multi-turn chat then save reflection → tap Create Keepsake |
| k5-templates | K-5 | All 8 templates render (flow check) | Medium | Create card with each template, assert no crash/error state. Visual fidelity is manual. |
| k6-badge | K-6 | Keepsake badge visible on entry | Low | After K-1, return to EntryDetail → assert badge visible |
| k7-badge-tap | K-7 | Keepsake badge tap → preview | Low | Tap badge → assert CardPreviewScreen opens with image |
| k8-no-badge | K-8 | No badge on entry without keepsake | Low | Navigate to entry without card → assert badge absent |
| k9-photo-hero | K-9 | Photo as background (hero template) | Low | Entry with photo → Save as Keepsake → hero template → assert preview opens |
| k10-photo-inline | K-10 | Photo inline (journal template) | Medium | Entry with photo → 素笺 template → assert preview opens |
| k11-emotion-on | K-11 | Emotion emoji visible toggle | Low | showMood ON → assert 😊 visible on preview |
| k12-emotion-off | K-12 | Emotion emoji hidden toggle | Low | showMood OFF → assert emoji absent |
| k13-tags-on | K-13 | Tags visible toggle | Low | showTags ON → assert "#tag" visible |
| k14-tags-system | K-14 | System tags excluded | Low | Entry with tag_synthesis → assert it NOT on card |
| k15-date-on | K-15 | Date stamp visible toggle | Low | showDate ON → assert date text visible |
| k16-footer-on | K-16 | Footer visible toggle | Low | showFooter ON → assert "Blinking Notes" visible |
| k17-footer-off | K-17 | Footer hidden toggle | Low | showFooter OFF → assert footer absent |
| k20-edit | K-20 | Edit keepsake | Low | Badge → Edit → change template → Save → assert updated |
| k24-android | K-24 | Android keepsake creation | Low | Same as K-1 on Android |
| k25-locale-zh | K-25 | ZH locale template names | Low | Set locale to 中文 → assert 墨韵/素笺/etc visible |
| k26-locale-en | K-26 | EN locale template names | Low | Set locale to EN → assert Ink Rhythm/Plain Paper/etc visible |

---

## Manual-Only (8 cases)

Cannot be automated. Refer to `uat_automation.md` for rationale categories.

### Visual / color verification

Maestro can verify text presence but not color, decoration fidelity, or visual quality.

| UAT Ref | Description | Blocker |
|---------|-------------|---------|
| K-18 | Style override: font color change visually correct | Maestro cannot verify hex color output |
| K-27 | Dark mode compatibility | Maestro can toggle theme but cannot verify visual consistency |

### iPad UIPopover {#ipad-uipopover}

Share sheets on iPad open as UIPopover — XCTest cannot traverse.

| UAT Ref | Description | Blocker |
|---------|-------------|---------|
| K-19 | Share keepsake from preview on iPad | iPad UIPopover — same limitation as S-1, S-2, etc. |

### Backup restore (requires app reinstall)

| UAT Ref | Description | Blocker |
|---------|-------------|---------|
| K-22 | Restore — keepsake survives re-render | Requires uninstall → reinstall cycle |

### External verification

| UAT Ref | Description | Blocker |
|---------|-------------|---------|
| K-23 | Backup size (no PNG bloat) | Requires inspecting ZIP file size externally |

### AI-dependent (real-time LLM call)

| UAT Ref | Description | Blocker |
|---------|-------------|---------|
| K-21 | AI Rewrite button works | Requires real LLM call with variable response time |

### Decorative motifs (visual fidelitt)

| UAT Ref | Description | Blocker |
|---------|-------------|---------|
| K-5 (visual) | Decorative motifs render correctly (bamboo, seal, mountains, porcelain, tea, ink) | Maestro cannot verify rendering fidelity of SVG/gradient decorations |

---

## Summary

| Category | Count |
|----------|:----:|
| Maestro-automatable | 20 |
| Manual-only | 8 |
| **Total** | **27** |

The 20 automatable cases can be implemented as ~8 Maestro flows (some cases share the same flow path). Priority order for flow creation: k1-iphone (core create flow) → k6-k8 (badge visibility) → k11-k17 (toggles) → k25-k26 (locale) → k3-k4 (reflection entry points).
