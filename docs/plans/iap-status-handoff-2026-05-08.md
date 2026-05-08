# IAP Status Handoff — 2026-05-08

**Version:** 1.1.0-beta.8+28 | **Tests:** 135/135 | **Lint:** 0 errors

---

## What's Done (Both Platforms)

### RevenueCat — Universal
- Project configured: entitlement `pro_access`, product `blinking_pro`, offering `ofrng88832e4ac2` (Current)
- Purchase flow code: paywall → Get Pro → native dialog → "Welcome to Pro!" → state updates
- BYOK (bring your own key) → single entry point, no duplication
- Restore Purchases works
- Price: $19.99 (non-consumable)
- Debug toggle: Settings → About → tap version 5x → cycle preview/restricted

### AI Keys (dart-define)
- `TRIAL_API_KEY` — auto-applied during 21-day preview
- `PRO_API_KEY` — auto-applied after purchase or in restricted mode
- Both route through OpenRouter (`qwen/qwen3.5-flash`)

### Android
- BILLING permission added to AndroidManifest
- Product `blinking_pro` ($19.99) created in Google Play Console
- Service account connected to RevenueCat
- `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` production key active
- AAB v27 built and uploaded to Internal Testing
- Product imported into RevenueCat, attached to `pro_access` and offering
- License testing configured

### iOS
- `blinking_pro` in App Store Connect: "Ready to Submit"
- Shared Secret: active
- In-App Purchase API Key: `2Q7R8Q5UPK` (fresh, In-App Purchase access)
- App Store Connect API Key: `4UK6U499RC` (Admin access)
- RevenueCat App Store connection fully saved and verified active
- `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` production key active
- IPA v28 built and ready for TestFlight upload
- StoreKit configuration file created for simulator testing

---

## What's Blocked / Waiting

### iOS — Waiting on Apple App Review
**Blocker:** Apple won't serve IAP to any device (even sandbox) until the IAP is submitted and approved.

**Required action:**
1. Upload IPA v28 to TestFlight via Transporter
2. App Store Connect → Blinking → select version → add `blinking_pro` →
3. Submit for App Review with "Manually release this version"
4. After approval (~1-2 days), IAP becomes available on TestFlight

**Credentials for review notes:**
- Sandbox Tester: blinking.tester@gmail.com / BlinkTest123!
- Debug toggle: Settings → About → tap version 5x → force restricted → tap robot → paywall

### Android — ✅ Verified
**Status:** Purchase flow fully tested: Get Pro → Google Play dialog → purchase → "Welcome to Pro!" → "You already own" on retry → Refund via Play Console → re-purchase works.

**Key finding:** Non-consumable IAPs can only be purchased once per Google account. To retest: refund via Play Console → Orders, or use different license tester account.

**Remaining for production:** Switch `RC_API_KEY` from Test Store to `goog_` in release builds only (debug builds can keep Test Store key).

---

## Key Lessons Learned

### App Store Connect
1. **In-App Purchase Key ≠ App Store Connect API Key** — two separate sections in RevenueCat, each needs its own credentials
2. **Key access type matters** — "Admin" key produces `AuthKey_` filename; "In-App Purchase" produces `SubscriptionKey_`; RevenueCat's In-App Purchase section expects the latter
3. **.p8 files can only be downloaded once** — if lost, must revoke and recreate
4. **Issuer ID never changes** — same for all keys: `8525f01e-0925-49f8-9862-739031df8d50`
5. **"Ready to Submit" IAPs are invisible** — StoreKit won't serve them until Apple approves
6. **App Store Connect UI is buggy** — Save buttons grey out, localization status shows "Prepare for Submission" even when done
7. **Xcode reinstall wipes all signing** — need device registration + certificate regeneration

### Google Play Console
8. **BILLING permission required** in APK before IAP menu unlocks
9. **Product IDs accept underscores** — purchase option IDs don't (use hyphens)
10. **Sideloaded APKs can't use Google Billing** — must install from Play Store
11. **New IAP products need propagation time** — 2-24 hours globally
12. **Google Cloud Pub/Sub API must be enabled** for RevenueCat connection

### RevenueCat
13. **Save button stays blue** — click outside fields, wait, try different browser
14. **Offerings must be "Current"** — green badge required for `getOfferings().current`
15. **Test Store product blocks App Store import** — same product ID can't exist in both
16. **`purchasePackage()` returns `PurchaseResult`** in SDK ≥9.x (not `CustomerInfo`)

---

## Current Build Artifacts

| Platform | Artifact | Version | Key |
|----------|----------|---------|-----|
| iOS IPA (TestFlight) | `build/ios/ipa/blinking.ipa` | v28 (33.8MB) | `appl_` |
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` | v27 (49.9MB) | `goog_` |
| Android APK | `build/app/outputs/flutter-apk/app-release.apk` | v27 (62.9MB) | `goog_` |

---

## All Credentials (Master Reference)

| Category | Item | Value |
|----------|------|-------|
| App Bundle ID | | `com.blinking.blinking` |
| IAP Product ID | | `blinking_pro` ($19.99) |
| RevenueCat Entitlement | | `pro_access` |
| RevenueCat Offering (Current) | | `ofrng88832e4ac2` |
| iOS Production Key | | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` |
| Android Production Key | | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` |
| Test Store Key | | `test_FFZAekOZQXGwwReuLkrvQLTjyOP` |
| App Store Issuer ID | | `8525f01e-0925-49f8-9862-739031df8d50` |
| App Store Shared Secret | | `cb7d69f2d98245de95e9eab7b4e0bbaf` |
| App Store IAP Key ID | | `2Q7R8Q5UPK` |
| App Store Connect API Key ID | | `4UK6U499RC` |
| Google Service Account | | `2b989a0c9a21ee0daaec4c4e772cb2effa30497b` |
| AI Trial Key | | (in password manager — `TRIAL_API_KEY`) |
| AI Pro Key | | (in password manager — `PRO_API_KEY`) |

### Build Commands
```bash
# iOS IPC (App Check)
flutter build ipa --release \
  --dart-define=RC_API_KEY_goog_ITjNhBQowFMaFwdyZYvaCGqqioi \
  --dart-define=TRIAL_API_KEY=<key> \
  --dart-define=PRO_API_KEY=<key>

# Android AAB
flutter build appbundle --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioi \
  --dart-define=TRIAL_API_KEY=<key> \
  --dart-define=PRO_API_KEY=<key>

# Simulator (Test Store)
flutter run -d "iPhone 17 Pro" --debug \
  --dart-define=TRIAL_API_KEY=<key> \
  --dart-define=PRO_API_KEY=<key>
```

---

## Tomorrow's Pickup Points

### Option A — Submit for App Review (iOS)
1. Upload IPA v28 via Transporter
2. App Store Connect → version → add `blinking_pro` → review notes → Submit
3. Choose "Manually release this version"
4. Wait 1-2 days for approval

### Option B — Continue Google Play Testing
1. Clear Play Store cache on device
2. Check if `blinking_pro` is now available (may need 24h since activation)
3. Re-build AAB v28 if needed

### Option C — UI/UX Cleanup Before Submission
1. Polish onboarding flow
2. Review all text/labels for consistency
3. Test all feature gates (restricted mode blocks)
4. Verify AI flow with trial/pro keys

### Option D — Server Deploy (10min)
```bash
cd /path/to/chorus/chorus-api
npx wrangler secret put JWT_SECRET
npx wrangler secret put ENTITLEMENT_ENABLED true
npx wrangler d1 execute ...
npm run deploy
```
