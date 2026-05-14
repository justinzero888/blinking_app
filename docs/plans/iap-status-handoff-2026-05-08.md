# IAP Status — 2026-05-09

**Version:** 1.1.0+30 | **Tests:** 147/147 | **Lint:** 0 errors

---

## Production Builds (All Built)

| Platform | Artifact | Version | RC Key |
|----------|----------|---------|--------|
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` | v30 (55MB) | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` |
| Android APK | `build/app/outputs/flutter-apk/app-release.apk` | v30 (68MB) | `goog_...` |
| iOS IPA | `build/ios/ipa/blinking.ipa` | v30 (34MB) | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` |

---

## Submission Status

| Platform | Status |
|----------|--------|
| **Google Play** | ✅ v30 uploaded to Internal Testing |
| **iOS TestFlight** | ✅ v30 IPA processed, validation passed |
| **iOS App Review** | ⬜ Ready — submit with IAP `blinking_pro` |

---

## iOS App Review Checklist

1. App Store Connect → Blinking → **1.1.0** version → Prepare for Submission
2. Add IAP `blinking_pro` ($19.99) to the version
3. Review notes:
   - Sandbox Tester: `blinking.tester@gmail.com` / `BlinkTest123!`
   - Debug toggle: Settings → About → tap version 5x → restricted → robot → paywall
   - IAP: `blinking_pro` ($19.99, non-consumable, entitlement `pro_access`)
4. Submit for App Review
5. Wait 1-2 days for approval

---

## Previous Content (Historical)

### iOS
- IPA v28 built and waiting for TestFlight upload → ✅ Done (v30 uploaded, validated)
- App Store connection verified active in RevenueCat
- `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` production key active

### Android
- AAB v27 built and uploaded to Internal Testing → ✅ v30 uploaded
- Product imported into RevenueCat, attached to `pro_access` and offering
- License testing configured

### Key Lessons Learned
1. **In-App Purchase Key ≠ App Store Connect API Key** — two separate sections in RevenueCat
2. **Key access type matters** — "Admin" key produces `AuthKey_` filename; "In-App Purchase" produces `SubscriptionKey_`
3. **.p8 files can only be downloaded once** — if lost, must revoke and recreate
4. **Issuer ID never changes**: `8525f01e-0925-49f8-9862-739031df8d50`
5. **"Ready to Submit" IAPs are invisible** — StoreKit won't serve them until Apple approves
6. **IAP must be submitted with app version** — cannot be approved separately

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
