# Session Summary — 2026-05-31

## Version: v1.2.0+47 (commit `efd9ebf`)

## Changes Made

### 1. RevenueCat crash guard (`v1.2.0+44`)
- `lib/main.dart`: Fatal exception in `kReleaseMode` when `RC_API_KEY` not defined — impossible to ship a key-less build
- `lib/core/services/purchases_service.dart`: `_lastError` propagated when key is null/empty

### 2. Dynamic pricing from RevenueCat (`v1.2.0+44`)
- `PurchasesService.proPriceString` getter reads from `offerings.current.availablePackages`
- 13 hardcoded `$19.99` replaced across 6 files with dynamic `purchases.proPriceString ?? '$7.99'`
- App Store Connect + Google Play Console prices updated to $7.99

### 3. Demo entries removed (`v1.2.0+44`)
- `_seedDemoEntries()` and `_demoEntry()` removed from `lib/main.dart`
- `uuid` and `Entry` imports cleaned up

### 4. Keepsake save pipeline restored (`v1.2.0+45` → `v1.2.0+47`)
- v45: Double postFrameCallback — failed on iOS
- v46: RenderToFile pipeline — failed on ALL platforms (Lesson 13 violation)
- v47: **Reverted to v43 working OverlayEntry pipeline** — UAT passes all 11 flows on all 3 platforms
- Root cause of iOS failure in v44-v46: `objective_c.framework` missing from iOS app bundle — dirty build without `pod install`

### 5. AI Rewrite CTA removed (`v1.2.0+47`)
- `_handleAiRewrite()`, `_stripAiPreamble()`, `_isRewriting` state, `LlmService` import — all removed
- Test updated: "AI Rewrite button is not visible"

### 6. UAT test suite
- New `p1-paywall-ready.yaml` Maestro flow (purchase readiness)
- Manual UAT checklist: `docs/plans/uat/price-change-uat-v44.md`
- Defect logged: `docs/defects/DEF-M-001-save-keepsake-ios.md`
- All 11 Maestro flows pass on iPhone, iPad, Android (v1.2.0+47)

## Test Results
- `flutter analyze --no-pub`: 0 errors, 260 issues (warnings/infos)
- `flutter test`: 563 tests, 561 passing, 2 pre-existing flaky

## Commits
```
efd9ebf remove AI Rewrite CTA from card builder — not aligned with product strategy
94c8268 v1.2.0+47: revert card save to v43 OverlayEntry pipeline — working baseline
50242ee v1.2.0+46: fix DEF-M-001 — replace OverlayEntry with renderToFile (BROKEN)
8a76364 v1.2.0+45: fix DEF-M-001 — double postFrameCallback (BROKEN)
3e3f67b v1.2.0+44: dynamic pricing from RevenueCat, crash guard for missing RC key, price $7.99
```
