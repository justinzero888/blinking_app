# IAP Setup — Lessons Learned

**Date:** 2026-05-07 | **Product:** Blinking Pro ($19.99, non-consumable `blinking_pro`)

---

## RevenueCat Setup Flow (Correct Order)

### 1. Create RevenueCat Project
- Every new project comes with a **Test Store** and a pre-generated `test_` API key
- Test Store works immediately for development — no store credentials needed
- Find test key at: **Project Settings → API Keys**

### 2. Create Entitlement + Product + Offering (Test Store)
- **Entitlement:** identifier must match code exactly (`pro_access`)
- **Product:** `blinking_pro`, non-consumable, attach to entitlement
- **Offering:** add product, **must be set as Current** (⋮ menu)

### 3. Configure SDK
- **purchases_flutter must be ≥ 9.8.0** for Test Store support
- `PurchasesConfiguration(apiKey)` — single key, platform detected automatically
- `purchasePackage()` returns `PurchaseResult` (not `CustomerInfo`) in 9.x

### 4. Connect Platform Stores (for production keys)
- **Apple:** Bundle ID + Shared Secret + In-App Purchase Key (.p8) + Issuer ID
- **Google:** Package Name + Service Account JSON
- Production keys (`appl_`, `goog_`) appear after successful connection

---

## App Store Connect — Key Issues

### IAP Metadata "Missing Metadata" Bug
- **Issue:** Even with all fields filled (pricing, localizations, screenshot), status shows "Missing Metadata"
- **Partial fix:** Shorten descriptions to <45 chars, save each localization separately
- **Full fix:** Not fully resolved — "Ready to Submit" achieved but localization still shows "Prepare for Submission"
- **Impact:** Sandbox testing may not work until IAP reaches "Ready to Submit"

### Save Button Greyed Out
- **Issue:** App Store Connect UI bug — save button stays greyed out
- **Workaround:** Click outside the text field (tab out) before clicking save
- **Alternative:** Different browser (Chrome incognito, Safari)

### Xcode Signing Wiped
- **Issue:** Xcode reinstall deletes all signing certificates and profiles
- **Fix 1:** Connect a device (iPhone/iPad) to register in developer portal
- **Fix 2:** Xcode → Settings → Accounts → Manage Certificates → + → Apple Distribution
- **Fix 3:** Developer portal → manually add device UDID
- **Note:** `flutter build ipa` requires a development provisioning profile (needs at least one registered device)

### API Key Management
- **Issue:** App Store Connect API keys can only be downloaded once
- **If lost:** Must revoke and recreate
- **Key types:** In-App Purchase, Admin, App Manager — RevenueCat accepts any with sufficient access
- **Issuer ID never changes** for the same developer account

---

## Google Play Console — Key Issues

### IAP Menu Hidden
- **Issue:** "Monetize → In-app products" greyed out
- **Fix:** Upload APK with `com.android.vending.BILLING` permission first
- **Then:** Wait for build to process, then IAP menu unlocks

### Product ID Naming
- **Product ID:** Allows lowercase letters, numbers, underscores, periods
- **Purchase option ID:** Does NOT allow underscores — use hyphens instead
- **Code:** Match product ID exactly in `purchaseProduct('blinking_pro')`

### Service Accounts
- **Google Cloud:** Must enable Pub/Sub API for RevenueCat
- **Permissions needed:** Play Android Developer → Service Account role
- **Play Console permissions:** View financial data + Manage orders
- **JSON key:** Download once, store securely

---

## RevenueCat — Key Issues

### Credentials Save Fails (Blue Button)
- **Issue:** "Save Change" button stays blue/unclickable after filling all fields
- **Symptoms:** `getOfferings()` returns empty → "No offerings available"
- **Debug:** Diagnostic error message shows whether offerings are empty or specific products missing
- **Possible causes:**
  - RevenueCat page needs refresh
  - Browser extension blocking
  - Field validation not triggered (click outside field)
  - API key issues in background validation
- **Workaround:** Try Chrome incognito, Safari, or different network

### Product Import
- **Test Store product blocks App Store import** (same product ID)
- **Fix:** Create separate iOS product manually, or delete Test Store product first
- **RevenueCat:** Can have same product ID across stores — the SDK uses the platform-appropriate one

### Offering "Current" Status
- **Critical:** Offering must be explicitly set as Current for `getOfferings().current` to work
- **Symptom:** `p.storeProduct.identifier` not found in packages

---

## Testing Flow — Quick Reference

### Simulator (Debug)
```bash
flutter run -d "iPhone 17 Pro" --debug --dart-define=RC_API_KEY=test_...
# Test Store works immediately, no store credentials needed
```

### TestFlight
```bash
flutter build ipa --release --dart-define=RC_API_KEY=appl_...
# Upload via Transporter
# Requires: sandbox tester signed in on device
# Requires: IAP in "Ready to Submit" status
```

### Google Play Internal Testing
```bash
flutter build appbundle --release --dart-define=RC_API_KEY=goog_...
# Upload to Internal Testing track
# Requires: license tester account
# Requires: IAP product created + associated with app version
```

---

## Key IDs Reference (Final)

| Item | Value |
|------|-------|
| App Bundle ID | `com.blinking.blinking` |
| IAP Product ID | `blinking_pro` ($19.99) |
| RevenueCat Entitlement | `pro_access` |
| RevenueCat Offering (Current) | `ofrng88832e4ac2` |
| iOS Production Key | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` |
| Android Production Key | `goog_ITjNhBQowFMaFwdyZYvaCGqqioitim` |
| Test Store Key | `test_FFZAekOZQXGwwReuLkrvQLTjyOP` |
| App Store Key ID | `4UK6U499RC` |
| App Store Issuer ID | `8525f01e-0925-49f8-9862-739031df8d50` |
| App Store Shared Secret | `cb7d69f2d98245de95e9eab7b4e0bbaf` |
| Google Service Account | `2b989a0c9a21ee0daaec4c4e772cb2effa30497b` |
