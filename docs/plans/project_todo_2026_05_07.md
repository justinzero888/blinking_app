# Blinking — Project TODO — 2026-05-07

**Version:** 1.1.0-beta.8+23 | **Tests:** 135/135 | **Lint:** 0 errors

---

## Today's Plan: Complete IAP & Launch Readiness

---

## 🔴 Block 1: Google Play Console IAP (Est. ~1h)

| # | Task | Status |
|---|------|--------|
| 1.1 | Go to [play.google.com/console](https://play.google.com/console) → Blinking → Monetize → In-app products | ⬜ |
| 1.2 | Create product ID: `blinking_pro`, Non-consumable, Price: $19.99 | ⬜ |
| 1.3 | Add English + Chinese titles/descriptions | ⬜ |
| 1.4 | Google Play Console → Setup → Service accounts → Create new → "Blinking RevenueCat" | ⬜ |
| 1.5 | Google Cloud: assign "Play Android Developer → Service Account" role | ⬜ |
| 1.6 | Generate JSON key + download | ⬜ |
| 1.7 | Back in Play Console: Grant "View financial data" + "Manage orders and subscriptions" | ⬜ |
| 1.8 | RevenueCat → Apps & Providers → + New → Google Play → upload JSON → get `goog_` key | ⬜ |
| 1.9 | RevenueCat → Products → Import from Google Play → attach `blinking_pro` to `pro_access` | ⬜ |
| 1.10 | Create license tester for sandbox testing | ⬜ |

## 🔴 Block 2: App Store Connect IAP Fix (Est. ~30min)

| # | Task | Status |
|---|------|--------|
| 2.1 | App Store Connect → Blinking → In-App Purchases → `blinking_pro` | ⬜ |
| 2.2 | Fix "Missing Metadata" — ensure Pricing ($19.99), Localizations (EN+ZH), Review Screenshot all saved | ⬜ |
| 2.3 | Status should show "Ready to Submit" | ⬜ |
| 2.4 | RevenueCat → Products → Import from App Store → attach to `pro_access` | ⬜ |

## 🟡 Block 3: Production Build & Deploy (Est. ~25min)

| # | Task | Status |
|---|------|--------|
| 3.1 | Server: `wrangler secret put JWT_SECRET` + `ENTITLEMENT_ENABLED=true` | ⬜ |
| 3.2 | Server: run D1 migrations | ⬜ |
| 3.3 | Server: `npm run deploy` | ⬜ |
| 3.4 | Build release APK: `flutter build apk --release --dart-define=RC_API_KEY=goog_...` | ⬜ |
| 3.5 | Build release AAB: `flutter build appbundle --release --dart-define=RC_API_KEY=goog_...` | ⬜ |
| 3.6 | Build iOS IPA: `flutter build ipa --release --dart-define=RC_API_KEY=appl_...` | ⬜ |

## 🟢 Block 4: App Review & Launch (Est. ~1.5h)

| # | Task | Status |
|---|------|--------|
| 4.1 | Google Play Console → Upload AAB → Internal testing track → submit | ⬜ |
| 4.2 | App Store Connect → Submit for App Review (include `blinking_pro` IAP in version) | ⬜ |
| 4.3 | RevenueCat → Customers → verify sandbox purchases appear correctly | ⬜ |
| 4.4 | Monitor crash reports + reviews post-launch | ⬜ |

## ⚪ Post-Launch (Next Session)

| # | Task | Effort |
|---|------|--------|
| P1 | M4 Top-ups — consumable IAP ($4.99/500 AI) | ~3h |
| P2 | Restore streaming refactor — OOM on large backups | ~2h |
| P3 | Feature gates — enforce restricted-mode UI blocks | ~2h |
| P4 | Firebase / Cloud Sync | Large |

---

## Build Commands Reference

```bash
# Development (simulator, Test Store key)
flutter run -d "iPhone 17 Pro" --debug \
  --dart-define=TRIAL_API_KEY=... \
  --dart-define=PRO_API_KEY=...

# Production (release, platform keys)
flutter build apk --release --dart-define=RC_API_KEY=goog_YOUR_KEY
flutter build appbundle --release --dart-define=RC_API_KEY=goog_YOUR_KEY
flutter build ipa --release --dart-define=RC_API_KEY=appl_YOUR_KEY

# Tests
flutter test                         # 135 tests
flutter analyze --no-pub             # 0 errors target
```

## Key IDs Reference

| Item | ID/Value |
|------|----------|
| App Bundle ID | `com.blinking.blinking` |
| IAP Product ID | `blinking_pro` ($19.99) |
| RevenueCat Entitlement | `pro_access` |
| RevenueCat Offering | `ofrng88832e4ac2` |
| iOS Production Key | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` |
| Android Production Key | TBD (after Block 1) |
| Test Store Key | `test_FFZAekOZQXGwwReuLkrvQLTjyOP` |
