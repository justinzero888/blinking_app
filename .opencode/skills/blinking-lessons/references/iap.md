# IAP / Store Configuration — Lessons Learned

## Production API Keys (Source of Truth)

| Platform | Key | Prefix |
|----------|-----|--------|
| **Google Play** | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` | `goog_` |
| **Apple App Store** | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` | `appl_` |
| **Test Store (debug)** | `test_FFZAekOZQXGwwReuLkrvQLTjyOP` | `test_` |

> ⚠️ **Verify key character-for-character from RevenueCat → Project Settings → API Keys.** These keys cannot be re-downloaded — if lost, revoke and recreate. A single wrong character causes `getOfferings()` to return empty — "No offerings from store" error. This has wasted multiple testing cycles.

## RevenueCat Setup Order (Must Follow)

1. Create RevenueCat project → Test Store + test key (Project Settings → API Keys)
2. Create **Entitlement** (`pro_access`) + **Product** (`blinking_pro`, non-consumable, attach to entitlement)
3. Create **Offering** → add product → Set as Current (⋮ menu) — CRITICAL for `getOfferings().current`
4. Configure SDK: `purchases_flutter ≥ 9.8.0`, `PurchasesConfiguration(apiKey)`
5. Connect platform stores for production keys:
   - **Apple:** Bundle ID + Shared Secret + IAP Key (.p8) + Key ID + Issuer ID
   - **Google:** Package Name + Service Account JSON
6. Production keys (`appl_`, `goog_`) appear after successful connection

## App Store Connect Bugs

### Price Must Be Free for Trial Model
- The app itself must be **Free** (Tier 0) for the 21-day preview to work
- The $19.99 IAP (`blinking_pro`) is separate — users buy after preview expires
- A paid app price blocks download entirely, making the trial useless

### IAP "Missing Metadata" Bug
- Even with all fields filled, status may show "Missing Metadata"
- Workaround: shorten descriptions to <45 chars, save each localization separately

### Save Button Greyed Out
- App Store Connect UI bug — click outside the text field (tab out) before clicking save
- Alternative: different browser (Chrome incognito, Safari)

### Xcode Signing Wiped
- Xcode reinstall deletes all signing certificates and profiles
- Connect a device to register it. Xcode → Settings → Accounts → Manage Certificates → + → Apple Distribution
- `flutter build ipa` requires a development provisioning profile (at least one registered device)

### API Key One-Time Download
- App Store Connect API keys can only be downloaded once
- If lost: revoke and recreate. Issuer ID never changes for the same developer account

## Google Play Console Bugs

### IAP Menu Hidden
- "Monetize → In-app products" greyed out
- Fix: Upload APK/AAB with `com.android.vending.BILLING` permission first, wait for processing

### Product ID Rules
- Product ID: lowercase letters, numbers, underscores, periods
- Purchase option ID: does NOT allow underscores — use hyphens

### Service Accounts
- Google Cloud: must enable Pub/Sub API
- Play Console permissions: View financial data + Manage orders
- JSON key: download once

### Re-testing After Purchase
- Non-consumables can only be purchased once per Google account
- "You already own this item" = purchase went through, just not synced
- Refund via Play Console → Orders → find transaction → Refund
- Alternative: add different Google email to license testers

## RevenueCat Bugs

### Credentials Save Fails (Blue Button)
- "Save Change" button stays blue/unclickable
- Symptom: `getOfferings()` returns empty
- Workaround: Chrome incognito, Safari, or different network. Refresh page.

### Test Store Product Blocks App Store Import
- Same product ID across Test Store and App Store
- Fix: create separate iOS product manually, or delete Test Store product first

## Price Gate (Most Common Miss)

**The #1 post-release issue:** App Store Connect → Pricing and Availability has the app listed as paid instead of free. Users can't download without paying → 21-day preview never starts. The app must be **Free**, with the IAP handling the $19.99 upgrade.

## Key IDs Reference

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
| Apple ID (App Store link) | `6765900648` |
| App Store URL | `https://apps.apple.com/app/id6765900648` |

## Build Commands

```bash
# Debug (Test Store)
flutter run -d "iPhone 17 Pro" --debug --dart-define=RC_API_KEY=test_...

# Production iOS
flutter build ipa --release --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT

# Production Android
flutter build appbundle --release --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioitim
```
