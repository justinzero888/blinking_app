# Blinking — Project TODO — 2026-05-08

**Version:** 1.1.0-beta.8+25 | **Tests:** 135/135 | **Lint:** 0 errors

---

## 🔴 Block 1: iOS IAP — Unblock RevenueCat

| # | Task | Status |
|---|------|--------|
| 1.1 | Try Chrome incognito (or Safari private) → RevenueCat → Apps & Providers → iOS → re-enter all credentials → Save | ⬜ |
| 1.2 | If save works: Products → Import from App Store → `blinking_pro` → attach to `pro_access` | ⬜ |
| 1.3 | Build IPA v26 with diagnostic logging removed (`goog_` key) | ⬜ |
| 1.4 | Upload to TestFlight via Transporter | ⬜ |
| 1.5 | Test purchase on device with sandbox account | ⬜ |
| 1.6 | **Fallback:** If save still fails, try deleting current project and using fresh approach (verify with test key first) | ⬜ |

## 🔴 Block 2: Google Play — Complete Testing

| # | Task | Status |
|---|------|--------|
| 2.1 | Upload AAB v25 to Internal Testing → create new release | ⬜ |
| 2.2 | Setup → License testing → add tester Google account | ⬜ |
| 2.3 | Install from Play Store internal link on Android device | ⬜ |
| 2.4 | Test: debug toggle → restricted → paywall → purchase | ⬜ |
| 2.5 | Verify RevenueCat → Customers shows sandbox transaction | ⬜ |

## 🟡 Block 3: Server Deploy

| # | Task | Status |
|---|------|--------|
| 3.1 | `wrangler secret put JWT_SECRET` | ⬜ |
| 3.2 | `wrangler secret put ENTITLEMENT_ENABLED true` | ⬜ |
| 3.3 | Run D1 migrations | ⬜ |
| 3.4 | `npm run deploy` | ⬜ |
| 3.5 | Verify: `curl https://blinkingchorus.com/api/entitlement/init` | ⬜ |

## 🟢 Block 4: Launch

| # | Task | Status |
|---|------|--------|
| 4.1 | Google Play → Promote Internal Testing → Production | ⬜ |
| 4.2 | App Store Connect → Submit for App Review | ⬜ |
| 4.3 | Monitor crash reports + reviews | ⬜ |

## ⚪ Post-Launch Queue

| # | Task | Effort |
|---|------|--------|
| P1 | M4 Top-ups — consumable IAP ($4.99/500 AI) | ~3h |
| P2 | Restore streaming refactor — OOM on large backups | ~2h |
| P3 | Feature gates — enforce restricted-mode UI blocks | ~2h |
| P4 | Firebase / Cloud Sync | Large |

---

## Build Commands

```bash
# iOS TestFlight
flutter build ipa --release \
  --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT \
  --dart-define=TRIAL_API_KEY=... \
  --dart-define=PRO_API_KEY=...

# Android Play Store
flutter build appbundle --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioitim \
  --dart-define=TRIAL_API_KEY=... \
  --dart-define=PRO_API_KEY=...
```
