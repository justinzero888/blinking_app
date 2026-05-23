# v1.2.0 — Phased Execution Plan

> **Target Production Date:** June 18, 2026  
> **Start Date:** May 22, 2026  
> **Duration:** 28 days  
> **Version:** 1.2.0+41
> **Revision:** May 23, 2026 — Phase 3 scope reduced (Keepsake-only, 11 days)

---

## Overview

| Phase | Dates | Work | Duration | Risk |
|-------|-------|------|----------|------|
| **1** | May 22–24 | Quick fixes + audit | 3 days | ✅ Complete |
| **2** | May 25–28 | Stream restore + voice notification | 4 days | ✅ Complete (May 22-23) |
| **3** | May 29 – Jun 8 | Card revitalization (Keepsake) | 11 days | Medium |
| **4** | Jun 9–13 | Full regression + UAT + buffer | 5 days | Low |
| **5** | Jun 16 | Build, submit, smoke test | 1 day | Low |
| **6** | Jun 17+ | Post-deployment validation | Ongoing | Low |

Phase 3 reduced from 17 to 11 days after use-case scoping (Keepsake-only, v1.2.0). Phase 4 expanded to absorb buffer. Target still June 18.

---

## Phase 1: Quick Fixes + Audit (May 22–24)

**Status: ✅ Complete**

All tasks finished May 22-23. See session summary for details.

---

## Phase 2: Restore Stream + Voice Notification (May 25–28)

**Status: ✅ Complete (May 22-23)**

Both T-1 (restore streaming) and T-6 (voice notification) shipped ahead of schedule. DB migration v14 (voice_enabled on routines) is in place.

---

## Phase 3: Card Revitalization — Keepsake (May 29 – June 8)

**Goal:** Build the Keepsake card system — template engine, renderer, builder UI, preview, entry badge indicator. Single-page only. XHS Export deferred to v1.3.0.

**Design doc:** [`card-system-design-v1.2.0.md`](./card-system-design-v1.2.0.md) — 14 decisions locked, v1.2.0 Keepsake-only scope.

### Week 1: Foundation (May 29 – June 1)

#### Day 9–10 — May 29-30: DB Migration + Models

| Task | Detail | Time |
|------|--------|------|
| DB migration v15 | Add columns to `note_cards` + `templates`. See design doc §10.2. (v14 consumed by T-6 voice columns.) | 1h |
| Update `NoteCard` model | Add `cardContent`, `emotion`, `displayTags`, `showMood`, `showDate`, `showTags`, `showFooter`, `templateOverrides` | 30min |
| Update `CardTemplate` model | Add `layout`, `accentColor`, `textAreaOpacity`, `textBackdropColor`, `footerText`, show toggles, `cornerStyle`, `decorationStyle` | 30min |
| Replace seed templates | Delete 6 old color-only templates. Seed 8 new templates (墨韵–山水). See design doc §5.3 + technical spec §2. | 1h |
| Register `CardProvider` in app.dart | Add `ChangeNotifierProvider<CardProvider>` to provider tree | 15min |
| Unit tests | Migration up/down, model serialization, seed data validation (8 templates, all fields) | 1h |

#### Day 11–12 — May 31 – June 1: Template Engine + Renderer

| Task | Detail | Time |
|------|--------|------|
| Create `CardRenderService` | Single entry point: `Future<String> renderCard({NoteCard card, CardTemplate template, ...})` → returns rendered PNG file path | 30min |
| Implement layout engine | Support 4 layouts: `hero_image` (full-bleed bg + text overlay), `centered` (gradient bg + centered text), `left_aligned` (accent bar + text), `two_column` (image left, text right) | 3h |
| Implement text rendering | Auto-font sizing (96px→9px via TextPainter). CJK+English word aware. Text backdrop with opacity. | 2h |
| Implement overlay elements | Mood emoji badge, date stamp, tag hashtags, footer text. Respect show toggles. | 1h |
| Implement re-render-on-restore logic | `getCardImage()` — check cached PNG exists, else re-render from stored metadata. See design doc §7.3. | 30min |
| Implement template decorative motifs | 墨韵: ink wash + cinnabar line. 竹影: bamboo leaf silhouette. 月色: crescent moon. 青花: porcelain border. 茶语: steam curves. 朱砂: red seal stamp. 山水: mountain silhouettes. | 4h |
| Output | 3:4 portrait PNG at 1080×1440. Offscreen via `RepaintBoundary` + `toImage()`. | 1h |
| Unit tests | Each layout renders without crash. Text fits within bounds. Overlay elements positioned correctly per toggle. Render-render produces identical output. | 2h |

### Week 2: UI (June 2–5)

#### Day 13–14 — June 2-3: Template Picker + Builder Sheet

| Task | Detail | Time |
|------|--------|------|
| Create `CardTemplatePicker` widget | Horizontal scroll of 8 template thumbnails. Each thumbnail: bg gradient preview + template name. Selected state with border highlight. Locale-aware names (ZH/EN). | 2h |
| Create `CardBuilderSheet` | `showModalBottomSheet`. Sections: (1) template picker at top, (2) content editor — pre-filled text, editable, (3) photo section — show entry photo with full-bleed/header toggle per template, (4) toggle row — mood/date/tags/footer, (5) "AI Rewrite" button, (6) "Save Keepsake" button | 5h |
| Wire entry point: EntryDetailScreen | "Save as Keepsake" button → opens sheet with entry content, emotion, tags, photo pre-filled | 1h |
| Wire entry point: ReflectionSessionScreen | "Save as Keepsake" button → opens sheet with AI reflection text pre-filled | 30min |
| Wire entry point: AssistantScreen | "Save as Keepsake" button on saved reflection messages → opens sheet | 30min |
| Widget tests | Sheet opens/closes, content editable, toggles work, template selection, photo toggle, "Save Keepsake" triggers render | 1.5h |

#### Day 15–16 — June 4-5: Preview + Entry Badge

| Task | Detail | Time |
|------|--------|------|
| Create `CardPreviewScreen` | Full-screen PNG preview. AppBar: Back, Share, Edit (re-opens builder). Single page only — no page strip. | 2h |
| Share flow | `SharePlus.instance.share(ShareParams(files: [XFile(renderedPngPath)]))` — reuse migrated API from Phase 1 | 30min |
| Save to camera roll | Save rendered PNG to device photos alongside DB persist | 30min |
| Create Keepsake badge on EntryDetailScreen | If entry has linked `NoteCard` → show chip badge with template name. Tap → `CardPreviewScreen`. | 1.5h |
| Wire save flow | `CardBuilderSheet` → "Save Keepsake" → render → persist NoteCard to DB → save to camera roll → pop sheet | 1h |
| Widget tests | Preview renders, share sheet opens, edit re-opens builder, badge appears/disappears correctly | 2h |

### Week 3: Polish + Tests (June 6–8)

#### Day 17–18 — June 6-7: Integration Tests + Visual QA

| Task | Detail | Time |
|------|--------|------|
| Full flow test: Entry → Keepsake | Create entry → tap Save as Keepsake → pick template → edit content → toggles → Save → verify in DB + camera roll → badge appears on entry detail | 1.5h |
| Full flow test: AI Reflection → Keepsake | Run reflection → Save as Keepsake → pick template → AI Rewrite → Save | 1h |
| Full flow test: Re-render on restore | Export backup → delete app + data → reinstall → restore backup → open entry detail → badge visible → tap → re-renders correctly | 1h |
| Full flow test: Edit existing keepsake | Entry with keepsake → badge → Edit → change template + content → Save → verify updated | 30min |
| Edge case tests | Empty content warning, max content length, no photo entry, entry with multiple photos (uses first), system tags excluded | 1h |
| Performance test | Render 10 cards sequentially, verify no memory leak. PNG size < 2MB. | 30min |
| Template visual QA | All 8 templates render correctly on iPhone SE, iPhone 17 Pro, iPad. Text readable, colors correct, decorations visible, overlays positioned. | 2h |
| Layout edge cases | Very long text (auto-font floors at 9px), very short text (large font, centered), CJK-only text, mixed CJK+English, emoji in text. Single-page only — text truncated with "..." at overflow. | 1h |
| Dark mode | Templates render consistently in light and dark themes | 30min |
| Accessibility | VoiceOver reads card content, template names | 1h |
| Bug fixes | Buffer day for issues found during QA | 3h |

#### Day 19 — June 8: Phase 3 Gate

| Gate | Criteria |
|------|----------|
| All unit tests pass | `flutter test` — target all new card tests passing |
| All widget tests pass | Card builder, preview, badge widget tests |
| All integration tests pass | Full flow tests (entry, reflection, restore, edit) |
| Zero analyze warnings | `flutter analyze --no-pub` |
| Visual QA signed off | All 8 templates on 3 device sizes |
| Restore test | Backup/restore loop — cards survive without PNGs, re-render correctly |

---

## Phase 4: Full Regression + UAT (June 9–13)

### Day 20–22 — June 9-11: Automated Regression + Manual UAT

| Suite | Command | Expected |
|-------|---------|----------|
| Full test suite | `flutter test` | 454+ new card tests, all passing |
| Static analysis | `flutter analyze --no-pub` | 0 errors, 0 warnings |
| Server tests | `cd ../chorus/chorus-api && npm test` | 370+ tests passing |
| Build check | `flutter build ipa --release --no-codesign` | Builds without error |

### Day 23–24 — June 12-13: Buffer

Two full days of buffer before build. Covers:
- Any Phase 3 spillover
- Additional UAT on real devices
- Platform-specific issues discovered in regression

### UAT Test Cases

| ID | Test | Device | Priority |
|----|------|--------|----------|
| C-1 | Create keepsake from entry | iPhone 17 Pro sim | P0 |
| C-2 | Create keepsake from entry | iPad Air 11" sim | P0 |
| C-3 | Create keepsake from AI reflection | iPhone 17 Pro sim | P0 |
| C-4 | All 8 templates render correctly | iPhone 17 Pro sim | P0 |
| C-5 | Emotion emoji visible/hidden toggle | iPhone 17 Pro sim | P0 |
| C-6 | Tags as hashtags visible/hidden | iPhone 17 Pro sim | P0 |
| C-7 | System tags excluded from hashtags | iPhone 17 Pro sim | P1 |
| C-8 | Date stamp visible/hidden toggle | iPhone 17 Pro sim | P1 |
| C-9 | Footer watermark visible/hidden | iPhone 17 Pro sim | P1 |
| C-10 | Photo as background (hero template) | iPhone 17 Pro sim | P0 |
| C-11 | Photo inline (journal template) | iPhone 17 Pro sim | P0 |
| C-12 | AI Rewrite button works | iPhone 17 Pro sim | P1 |
| C-13 | Keepsake badge visible on entry with card | iPhone 17 Pro sim | P0 |
| C-14 | Badge tap → card preview → share | iPhone 17 Pro sim | P0 |
| C-15 | Edit keepsake (change template + content) | iPhone 17 Pro sim | P1 |
| C-16 | Backup/restore → card survives (re-render) | iPhone 17 Pro sim | P0 |
| C-17 | Chinese template names (ZH locale) | iPhone 17 Pro sim | P1 |
| C-18 | English template names (EN locale) | iPhone 17 Pro sim | P1 |
| C-19 | Dark mode compatibility | iPhone 17 Pro sim | P1 |
| C-20 | Decorative motifs render (bamboo, seal, moon, mountains, porcelain, tea, ink) | iPhone 17 Pro sim | P1 |
| C-21 | Keepsake from Assistant saved reflection | iPhone 17 Pro sim | P1 |
| C-22 | Keepsake creation on Android | Android emulator | P0 |
| C-23 | Long text truncated with "..." | iPhone 17 Pro sim | P1 |

---

## Phase 5: Build + Deploy (June 16)

### Day 25 — June 16: Production Build

| Task | Command | Time |
|------|---------|------|
| Bump version | `pubspec.yaml`: `1.2.0+41`. `constants.dart`: `AppConstants.appVersion = '1.2.0'`. Settings screen version subtitle. `ios/Runner/Info.plist`: `CFBundleShortVersionString = 1.2.0` | 10min |
| Build iOS | `flutter build ipa --release --dart-define=RC_API_KEY=appl_... --dart-define=TRIAL_API_KEY=$TRIAL_API_KEY --dart-define=PRO_API_KEY=$PRO_API_KEY` | 20min |
| Build Android | `flutter build appbundle --release --dart-define=RC_API_KEY=goog_... --dart-define=TRIAL_API_KEY=$TRIAL_API_KEY --dart-define=PRO_API_KEY=$PRO_API_KEY` | 15min |
| Validate IPA | Check bundle ID, version, entitlements, provisioning profile | 10min |
| Validate AAB | Check version code, version name, signing | 10min |
| Upload iOS | App Store Connect → TestFlight (internal first) | 15min |
| Upload Android | Google Play Console → Internal Testing track | 10min |

---

## Phase 6: Post-Deployment Validation (June 17+)

### Immediate — Release Day

| Check | How |
|-------|-----|
| TestFlight install | Install on real iPhone + iPad. Verify version 1.2.0+41 |
| iPad share test | **Real iPad only** — share entry, share backup, share habit export. All 3 share sheets open + function. |
| Keepsake creation | Create keepsake from entry, AI reflection. Share to system sheet. |
| Keepsake badge | Badge visible on entries with cards. Tap → preview. |
| Restore + re-render | Export backup, uninstall, reinstall, restore. Keepsake badge visible. Tap → card re-renders correctly. |
| Voice notification | Set routine reminder 2min from now, verify TTS speaks |
| IAP purchase | RevenueCat sandbox — purchase flow still works |
| Quick smoke | Calendar, AI assistant, insights, routines — no crashes |

### 24 Hours Post-Release

| Check | How |
|-------|-----|
| Crash rate | App Store Connect → Xcode Organizer → Crashes. Target: 0 new crashes. |
| ANR rate | Google Play Console → Android vitals → ANRs. Target: 0 new ANRs. |
| RevenueCat dashboard | Verify purchase events flowing, no errors |
| Server health | `curl https://blinkingchorus.com/api/config` → 200 OK |

### 72 Hours Post-Release

| Check | How |
|-------|-----|
| App Store reviews | Monitor for bugs reported by users |
| Google Play reviews | Same |
| Feedback email | `blinkingfeedback@gmail.com` — check for issues |
| Promoted to Production | If no issues in 72h, promote from TestFlight/Internal Testing to Production on both stores |

---

## Risk Matrix

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Template decorative motifs take longer than estimated | Delays Phase 3 by 1-2 days | Medium | Simplify motifs to static SVG overlays if needed. 4h buffer in timeline. |
| Card re-render produces different output than original | Restored cards look different | Low | Deterministic rendering from stored metadata. Unit test verifies re-render matches. |
| iPad share still broken after fix | Blocks release | Low | Test on real iPad in Phase 4 before building production IPA |
| Restore streaming breaks existing restore | Data loss | Very Low | Extensive tests with real backups. Re-render approach keeps card data tiny. |
| Voice TTS unavailable on some devices | Feature gap | Medium | Graceful fallback — silent notification with visual only |
| App Store review delay | Delays release by 1-3 days | Medium | June 16 build, 2-day buffer before June 18 target |

---

## Contingency: Scope Reduction

Phase 3 scope is already reduced (Keepsake-only, single-page, no history). Further cuts available:

| Cut | Impact | Time Saved | Ship When |
|-----|--------|------------|-----------|
| Decorative motifs → simple gradients | Bamboo, seal, mountains, etc. replaced with plain gradient backgrounds | ~4h | v1.3.0 |
| 8 → 4 templates | Ship 墨韵 + 月色 + 素笺 + 朱砂 only | ~1.5d | v1.2.1 |
| Remove photo integration | Templates use built-in gradients only, no entry photos on cards | ~2h | v1.3.0 |
| AI Rewrite button | Removes AI differentiation | ~1h | v1.2.1 (not recommended) |

**Core non-negotiable:** Single-entry + AI reflection Keepsake cards with template engine, renderer, builder sheet, preview, share, and entry detail badge indicator.

---

## Summary: v1.2.0 Changes from Original Plan

| Change | Before | After |
|--------|--------|-------|
| Phase 3 scope | Card system (17 days) — Keepsake + XHS Export + History + Multi-page + Multi-entry merge | Keepsake-only (11 days) — single-page, single-entry, entry badge |
| DB migration | v14 (card + voice columns) | v14 (voice, T-6) + v15 (card columns) |
| Multi-entry merge | Included | Deferred to v1.3.0 |
| Card History screen | Included | Replaced by entry detail badge. Grid deferred to v1.2.1. |
| Multi-page support | Hybrid auto-paginate | Deferred to v1.3.0 (XHS Export) |
| Aspect ratio toggle | 3:4 + 1:1 | 3:4 fixed. 1:1 deferred to v1.3.0. |
| Custom backgrounds | User photo upload | Entry photos only (already in backup). Custom upload deferred to v1.3.0. |
| Backup impact | Rendered PNGs in backup (~2MB/card) | Metadata only (~2KB/card). Re-render lazily on restore. |
| Phase 4 timeline | Jun 15-16 (2 days) | Jun 9-13 (5 days, includes 2-day buffer) |
