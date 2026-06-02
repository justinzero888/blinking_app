# v1.2.0+54 — Release Deployment Plan

**Date:** 2026-06-02  
**Status:** ✅ Ready for release  
**Previous production:** v1.1.0+40 (live on App Store + Google Play)  
**In review:** v1.2.0+51 (App Store + Google Play)

---

## Pre-Flight Checklist

| # | Check | Status |
|---|-------|--------|
| 1 | `flutter analyze --no-pub` — 0 errors, 265 issues | ✅ |
| 2 | `flutter test` — 557 pass, 8 pre-existing flaky | ✅ |
| 3 | Maestro UAT — 36/36 flows (12 per platform × 3) | ✅ |
| 4 | Purchase flow validated on iPad (local device) | ✅ |
| 5 | Keepsake save validated on all 3 sims | ✅ |
| 6 | Voice notifications — global + per-routine toggle | ✅ |
| 7 | Google Play media permissions stripped | ✅ |
| 8 | Onboarding reflects Pro state after purchase | ✅ |
| 9 | Dead code removed (`resetIdentity`, `_storedKey`) | ✅ |
| 10 | `.gitignore` synced (`dev/cards-raw/`, `*.bak`) | ✅ |

---

## What's Changed Since v1.1.0

### Features
- 8-template Keepsake Cards (CardBuilderSheet, CardPreviewScreen, badge on EntryDetailScreen)
- Dynamic pricing from RevenueCat (`$7.99` via `proPriceString`)
- 31 seed routines, 9 categories with PNG icons
- Voice notifications (flutter_tts, global + per-routine toggle)
- Onboarding Screen 2: "Everything in My Day" + privacy anchor

### Critical Fixes
- **RC single source of truth** — `EntitlementService` synced from `PurchasesService.isPro` on init
- **Purchase flow** — RC state syncs on app start, purchase result is authoritative (no `refreshCustomerInfo` race)
- **Offerings refresh** — `getOfferings()` before purchase with 30s timeout (prevents stale cache after price changes)
- **Onboarding** — reflects Pro state after purchase (banner + button text)
- **Media permissions** — all stripped from Android manifest per Google Play policy
- **AI Rewrite CTA** removed from card builder
- **Save as Keepsake** removed from Reflection screen
- **Crash guard** — fatal exception if RC key missing in release builds

---

## Build Commands

```bash
# Clean once
flutter clean && flutter pub get

# iOS (build first, survives Android build)
flutter build ipa --release \
  --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT \
  --dart-define=TRIAL_API_KEY=$TRIAL_API_KEY661281c570108621d57a9a9f26d63c8cb0ef7daf0b8bf3b5c8a5fce \
  --dart-define=PRO_API_KEY=$PRO_API_KEY2290404d73920592916a5ac9092cfc94443620123fb216745ad3d

# Android (build second, never clean between)
flutter build appbundle --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioitim \
  --dart-define=TRIAL_API_KEY=$TRIAL_API_KEY661281c570108621d57a9a9f26d63c8cb0ef7daf0b8bf3b5c8a5fce \
  --dart-define=PRO_API_KEY=$PRO_API_KEY2290404d73920592916a5ac9092cfc94443620123fb216745ad3d
```

---

## Post-Build Verification

- [ ] `ls -lh build/ios/ipa/blinking.ipa` — existed
- [ ] `ls -lh build/app/outputs/bundle/release/app-release.aab` — existed
- [ ] Merged manifest: no `READ_MEDIA_*`, `READ_EXTERNAL_STORAGE`, or `CAMERA`

---

## Upload

- [ ] iOS: Transporter or `xcrun altool` → TestFlight
- [ ] Android: Play Console → Internal Testing / Closed Testing → Production

---

## Post-Upload Validation (Real Device)

Complete `docs/plans/uat/real-device-purchase-checklist.md` (17 checkpoints) on real iPhone + Android before promoting to production.

---

## Rollback Plan

If critical issue found:
- **iOS:** Do not promote TestFlight build to production. Submit fix as new build.
- **Android:** Halt rollout in Play Console. Submit fix as new build.
- v1.1.0+40 remains live — no rollback needed unless v1.2.0 is promoted.
