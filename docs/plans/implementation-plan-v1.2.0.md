# Blinking v1.2.0 — Implementation Plan

> **Target Production Date:** June 18, 2026  
> **Current Version:** 1.1.0+40 (live on iOS App Store + Google Play)  
> **Tests:** 454/454 | **Lint:** 0 errors  
> **Status:** Phase 1+2 complete · Phase 3 design locked (Keepsake-only, May 23 revision) · Target Jun 18

---

## Backlog Items (from audit)

### 1. 🔧 Tech Debt

| ID | Item | Effort | Status |
|----|------|--------|--------|
| T-1 | Restore streaming refactor | ~2h | ✅ Done |
| T-2 | `addCustomerInfoUpdateListener` in RevenueCat | ~15min | ✅ Done |
| T-3 | Hardcoded `'receipt': 'revenuecat_validated'` in server | ~30min | ✅ Done |
| T-4 | DeviceCheck upgrade for iOS | — | **Deferred.** Low ROI for $19.99. |
| T-5 | Platform version audit | ~1h | ✅ Done |
| T-6 | Voice notification for routines | ~2h | ✅ Done |

### 2. 🎨 Card Revitalization — Keepsake Cards (v1.2.0)

**Design doc:** [`card-system-design-v1.2.0.md`](./card-system-design-v1.2.0.md)  
**Technical spec:** [`design-card-technical.md`](./design-card-technical.md)  
**Competitive analysis:** [`competitive-analysis-card-creation.md`](./competitive-analysis-card-creation.md)  
**Effort:** ~11 working days (reduced from 17 after May 23 scope revision)

Revive the dead `NoteCard` system with 8 RedNotes-inspired Keepsake card templates. No competitor combines AI-generated reflection + mood data + tags on shareable visual cards — unique differentiator for Blinking.

#### Two-Use-Case Model

Two distinct user goals identified. v1.2.0 ships Keepsake only.

| | **Keepsake Card** (v1.2.0) | **XHS Export** (v1.3.0) |
|---|---|---|
| Goal | Preserve memory — photo + text, personal | Share on 小红书 — readable, multi-image |
| Multi-page? | ❌ Not needed | ✅ Critical |
| Photo on card? | ✅ Critical | Nice-to-have |
| Where it lives | In-app (linked to entry) + camera roll | Camera roll → RedNotes app |
| Re-edit? | From source entry | N/A |

#### Design Decisions (D1–D14 — ALL LOCKED)

| D# | Decision | Resolution |
|----|----------|------------|
| D1 | Template strategy | Replace all 6 old with 8 new (墨韵–山水) |
| D2 | Customizability | Full per-card font/color/opacity/toggles. Save-as-template deferred to v1.3.0. |
| D3 | Background images | Built-in gradients + entry photo. Custom uploads deferred to v1.3.0. |
| D4 | Content editing | Pre-filled, editable + "AI Rewrite" button |
| D5 | Multi-entry merge | **Deferred to v1.3.0** |
| D6 | Aspect ratio | **3:4 portrait fixed** for v1.2.0 |
| D7 | Persistence | **Metadata only** — re-render PNGs lazily. No backup bloat. |
| D8 | Multi-page support | **Deferred to v1.3.0** (XHS Export) |
| D9 | Image handling | Per-template defaults (full-bleed hero, inline journal) |
| D10 | Page break awareness | **Deferred to v1.3.0** |
| D11 | Custom templates | Built-in only. Save-as-template deferred to v1.3.0. |
| D12 | XHS Export mode | **Deferred to v1.3.0** |
| D13 | Card History screen | **Deferred to v1.2.1** — replaced by Keepsake badge on EntryDetailScreen |
| D14 | Re-render on restore | Metadata only in backup (~2KB/card). PNGs regenerated lazily. |

#### Deliverables (v1.2.0)

`CardTemplatePicker`, `CardBuilderSheet` (keepsake mode, single page), `CardPreviewScreen` (single page), `CardRenderService` (4 layouts + 8 templates + 6 decorative motifs + re-render-on-restore), `EntryDetailScreen` Keepsake badge, DB migration v15, UI entry points in `EntryDetailScreen` + `ReflectionSessionScreen` + `AssistantScreen`.

#### Deferred

| Item | Target |
|------|--------|
| Card History screen (grid) | v1.2.1 |
| XHS Export mode (multi-page, ratio toggle, page breaks) | v1.3.0 |
| Multi-entry merge | v1.3.0 |
| Custom background uploads | v1.3.0 |
| Custom template saving | v1.3.0 |

### 3. 🐛 iPad Share Fix

| ID | Description | Status |
|----|-------------|--------|
| B-1 | `export_service.dart:shareFile()` — missing `sharePositionOrigin` | ✅ Fixed (`128af6e`) |
| B-2 | `settings_screen.dart:_handleExportHabits()` — missing `sharePositionOrigin` | ✅ Fixed |
| B-3 | `entry_detail_screen.dart` + `entry_card.dart` — text share fixed | ✅ Fixed |

All three are fixed in the latest commit (`128af6e`) but not in the v40 production binary.

### 4. ⚠️ Deprecated APIs

Two categories exist:

#### A. Google Play Android Warnings (investigated — nothing actionable)

Google's review feedback flagged system UI deprecations. **Audit result: Project is clean.** None of the deprecated Android APIs are used. Warnings are likely generic for all apps targeting SDK 36+.

#### B. Flutter Dart Deprecations (from `flutter analyze --no-pub`)

11 deprecation warnings across 2 packages. See [execution plan](./execution-plan-v1.2.0.md) for migration patterns. Handled in Phase 1.

---

## ⏸️ Deferred

| ID | Item | Reason |
|----|------|--------|
| D-1 | Firebase / Cloud Sync | **Data privacy is Blinking's highest priority.** Server-side data storage conflicts with local-first privacy guarantee. |
| D-2 | DeviceCheck (T-4) | Low ROI — current IDFV fingerprint sufficient for $19.99 app. |

### Cloud Sync — Privacy Assessment

| Factor | Risk |
|--------|------|
| **Data sovereignty** | All journal entries reside on device. Server sync violates local-first trust model. |
| **E2E encryption** | Required as table stakes — getting it wrong is worse than not having it. |
| **User trust** | "No social media, no accounts, no distraction" — sync requires accounts, breaking this promise. |
| **Implementation cost** | 10x higher than all other v1.2.0 items combined. Backup/restore covers data safety for current user needs. |

**If revisited in v1.3.0+:** Start with iCloud/CloudKit (iOS-only, zero server cost, Apple handles encryption).

---

## 📋 UAT Test Cases

### Regression Suite

| ID | Area | Tests | Priority |
|----|------|-------|----------|
| R-1 | Entry CRUD | Create note/list, edit, delete, emotion picker, tag picker, image attach | P0 |
| R-2 | Routine CRUD | Create/edit/delete, toggle active/paused, mark complete, streak display | P0 |
| R-3 | AI Assistant | Multi-turn chat, save reflection, persona switch, lens responses | P0 |
| R-4 | Insights | Emoji jar carousel, 4 charts (note count, habit, mood, tags), CT1/CT2/CT3/CT4 | P0 |
| R-5 | Calendar | Day navigation, emoji badges, routine checklist, future date lock | P0 |
| R-6 | Settings | Language toggle, theme, tags, export/import, AI persona, about | P0 |
| R-7 | Onboarding | 3-screen flow, language toggle on screen 1, first-launch only | P1 |

### Entitlement & IAP Suite

| ID | Test | Expected | Priority |
|----|------|----------|----------|
| E-1 | Fresh install → preview mode | 21-day preview, 3 AI/day, no paywall | P0 |
| E-2 | Preview day 18-20 | Soft purchase prompts appear | P1 |
| E-3 | Preview day 21 | Transition screen appears | P1 |
| E-4 | Debug toggle → restricted | All 17 AI gates show lock/paywall | P0 |
| E-5 | Restricted → tap robot | Paywall displayed | P0 |
| E-6 | Paywall — loading spinner | Shows during purchase flow | P1 |
| E-7 | Paywall — button disable | Disabled during processing | P1 |
| E-8 | Paywall — cancel | Dismisses, returns to restricted | P1 |
| E-9 | Purchase (sandbox) | "Welcome to Pro!" snackbar, all gates unlock | P0 |
| E-10 | Restore purchases | Restores pro_access entitlement | P1 |
| E-11 | Store unavailable | Graceful error message | P2 |

### Persona Suite

| ID | Test | Expected | Priority |
|----|------|----------|----------|
| P-1 | Preset persona switch (Kael→Elara→Rush→Marcus) | Robot avatar + name changes, lens questions change | P0 |
| P-2 | Custom persona create | Save → card appears as custom_0 | P0 |
| P-3 | Custom persona edit | Pre-filled form, save preserves data | P1 |
| P-4 | Custom persona delete | Card removed, reverts to default if active | P1 |
| P-5 | Custom persona image upload | Shows on form preview + robot | P2 |
| P-6 | CN avatars | Switch with locale setting | P1 |
| P-7 | Private tag filter | AI never references #私密 entries on all 5 surfaces | P0 |

### Share & Export Suite

| ID | Test | Expected | Priority |
|----|------|----------|----------|
| S-1 | Entry share (text) | Opens system share sheet, subject correct | P0 |
| S-2 | Backup export (text-only) | ZIP created, ~200 KB | P0 |
| S-3 | Backup export (with media) | ZIP created with photos | P1 |
| S-4 | Backup restore (text-only) | All entries/routines/tags restored | P0 |
| S-5 | Backup restore (with media) | Media files restored to correct paths | P1 |
| S-6 | Habit export (JSON) | File shared via system sheet | P1 |
| S-7 | Habit import (JSON) | Duplicates skipped, new routines added | P1 |
| **S-8** | **iPad share — entry** | Share sheet opens, content correct | **P0** |
| **S-9** | **iPad share — backup** | Share sheet opens, file attached | **P0** |
| **S-10** | **iPad share — habit export** | Share sheet opens, JSON file attached | **P0** |

### Keepsake Card Suite (v1.2.0)

| ID | Test | Expected | Priority |
|----|------|----------|----------|
| K-1 | Create keepsake from entry | Pick template, edit content, toggle mood/date/tags/footer, Save | P0 |
| K-2 | Create keepsake from AI reflection | Pre-filled with reflection text, pick template, Save | P0 |
| K-3 | Create keepsake from Assistant saved reflection | Works from saved reflection message | P1 |
| K-4 | Keepsake badge on entry detail | Badge visible when entry has linked card. Tap → preview. | P0 |
| K-5 | All 8 templates render correctly | Each template with unique style, decorations visible | P0 |
| K-6 | Photo on keepsake (hero template) | Entry photo appears as full-bleed or hero header | P0 |
| K-7 | Photo on keepsake (journal template) | Photo appears inline | P1 |
| K-8 | Emotion emoji toggle | Visible when ON, hidden when OFF | P0 |
| K-9 | Tags as hashtags toggle | Hashtags visible/hidden per toggle | P0 |
| K-10 | System tags excluded | `tag_synthesis`, `tag_private` never shown | P1 |
| K-11 | Date stamp toggle | Date visible/hidden per toggle | P1 |
| K-12 | Footer watermark toggle | "Blinking Notes" visible/hidden per toggle | P1 |
| K-13 | AI Rewrite button | Content changes to AI-rewritten version with loading spinner | P1 |
| K-14 | Share keepsake | Opens system share sheet with rendered PNG | P0 |
| K-15 | Edit keepsake | Re-opens builder with pre-filled content + config | P1 |
| K-16 | Restore — keepsake survives | Export backup, reinstall, restore → badge visible → tap re-renders | P0 |
| K-17 | Backup size — no PNG bloat | Backup with 10 keepsakes < 200KB larger than without | P1 |
| K-18 | Templates locale-aware | ZH shows 墨韵/素笺/竹影... EN shows Ink Rhythm/Plain Paper... | P1 |
| K-19 | Keepsake on Android | Same flow works on Android | P0 |
| K-20 | Dark mode templates | Templates render consistently in dark theme | P1 |

### Device Matrix

| Test On | Priority |
|---------|----------|
| iPhone 17 Pro (sim) | P0 |
| iPhone SE (sim) | P1 |
| iPad Air 11" M4 (sim) | P0 — share + backup critical path |
| iPad (real device) | P0 — share sheet verification |
| Android emulator (Pixel 7) | P0 |
| Android (real device) | P1 |

---

## Next Steps

1. **Phase 3** — Keepsake card system (May 29 – Jun 8)
2. **Phase 4** — Full regression + UAT + buffer (Jun 9–13)
3. **Phase 5** — Build + deploy (Jun 16)
4. Deferred items tracked for v1.2.1 and v1.3.0
5. **See detailed schedule:** [`execution-plan-v1.2.0.md`](./execution-plan-v1.2.0.md) — 28-day plan with daily tasks, gates, and scope reduction summary
