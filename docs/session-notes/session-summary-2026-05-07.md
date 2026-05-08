# Session Summary — 2026-05-07

## Block 1: Google Play Console IAP

| # | Task | Status |
|---|------|--------|
| 1.1 | AAB uploaded with BILLING permission to unlock IAP menu | ✅ |
| 1.2 | Created `blinking_pro` ($19.99, non-consumable) | ✅ |
| 1.3 | English + Chinese titles/descriptions added | ✅ |
| 1.4 | Service account exists (from yesterday) | ✅ |
| 1.5 | Google Cloud Pub/Sub API enabled | ✅ |
| 1.6 | JSON key existed from yesterday | ✅ |
| 1.7 | Permissions granted (View financial data + Manage orders) | ✅ |
| 1.8 | **RevenueCat Google Play connected** → `goog_ITjNhBQowFMaFwdyZYvaCGqqioitim` | ✅ |
| 1.9 | **Product imported from Google Play** → attached to `pro_access`, added to offering | ✅ |
| 1.10 | License tester — pending (after AAB rollout) | ⬜ |
| — | **AAB v25 built with `goog_` key** (49.9MB) | ✅ |
| — | **APK v25 built with `goog_` key** (62.9MB) | ✅ |

## Block 2: App Store Connect IAP

| # | Task | Status |
|---|------|--------|
| 2.1 | IAP `blinking_pro` — status "Ready to Submit" | ✅ |
| 2.2 | Metadata: pricing, localizations fixed, review screenshot generated | ✅ |
| 2.3 | Xcode reinstall → signing certs wiped → fixed via device registration | ✅ |
| 2.4 | API key regenerated (S7GU3FWWH5 → 4UK6U499RC) | ✅ |
| — | **RevenueCat App Store credentials not saving** (blue button) | ❌ Blocked |
| — | **TestFlight purchase returns "No offerings"** | ❌ Blocked |
| — | Diagnostic logging added to PurchasesService for debugging | ✅ |
| — | **iOS IPA v25 built** (33.8MB, uploaded to TestFlight) | ✅ |

## Block 3: Production Build & Deploy

| # | Task | Status |
|---|------|--------|
| 3.1 | Server JWT_SECRET + ENTITLEMENT_ENABLED | ⬜ Deferred |
| 3.2 | D1 migrations | ⬜ Deferred |
| 3.3 | Server deploy | ⬜ Deferred |
| 3.4 | Android release APK built (`goog_` key, v25) | ✅ |
| 3.5 | Android release AAB built (`goog_` key, v25) | ✅ |
| 3.6 | iOS release IPA built (`appl_` key, v25) | ✅ |

## Block 4: App Review & Launch

Deferred — Google Play AAB pending rollout, iOS blocked on RevenueCat credentials.

---

## Key Lessons Learned

1. **Google Play requires BILLING permission in APK** before the IAP menu unlocks
2. **App Store Connect UI is buggy** — Save button greys out even with valid fields; "Missing Metadata" persisted despite all fields filled
3. **RevenueCat credentials MUST save** — if blue button persists, offerings return empty and purchases fail silently
4. **Xcode reinstall wipes all signing** — need device registration + cert regeneration
5. **API keys can't be re-downloaded** — if lost, must revoke and recreate
6. **Google Play product IDs allow underscores**; purchase option IDs don't
7. **RevenueCat Test Store products block App Store imports** — need to manually create/attach iOS product

## New Documents

| Doc | Purpose |
|-----|---------|
| `docs/plans/testflight-iap-uat-guide.md` | Full TestFlight IAP testing guide |
| `docs/plans/ios-iap-blocked-issue.md` | iOS IAP blocker documentation |
| `docs/plans/iap-lessons-learned.md` | Comprehensive IAP setup lessons learned |

## Commits (18)

```
6e77297 docs: iOS IAP blocked issue — moved to Google Play
26ece79 debug: add diagnostic logging to PurchasesService; bump v25
9e2a0ae docs: TestFlight IAP setup & UAT guide
10e882c chore: bump to 1.1.0-beta.8+24; iOS IPA build
795e7b8 docs: project TODO for 2026-05-07
17e7152 fix: add BILLING permission to AndroidManifest
... (earlier commits from yesterday session)
```
