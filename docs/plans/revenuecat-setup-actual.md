# RevenueCat IAP Setup — Actual Process (2026-05-06)

**Status:** Test Store verified end-to-end on iOS simulator. Production stores pending.

This documents the **actual** RevenueCat setup process as experienced, replacing the original guide's assumptions that were outdated by RevenueCat's current UI and Test Store flow.

---

## Key Takeaways (Read This First)

1. **Every new RevenueCat project comes with a Test Store** — a pre-provisioned sandbox with a `test_` SDK API key. No store credentials needed for development.
2. **You do NOT get platform-specific keys (`appl_`/`goog_`) initially.** They appear only after connecting stores under **Apps & Providers**.
3. **Test Store purchases work like real ones** — go through the full native purchase dialog, no real charge.
4. **Three distinct things must be linked correctly:**
   - **Entitlement** (e.g., `pro_access`) — the right/permission
   - **Product** (e.g., `blinking_pro`) — the IAP item
   - **Offering** (e.g., `ofrng88832e4ac2`) — the package bundle presented to users
5. **The offering must be set as "Current"** for `Purchases.getOfferings().current` to work.
6. **The entitlement identifier** (not display name) is what the SDK checks — must match code exactly.
7. **purchases_flutter SDK must be ≥ 9.8.0** for Test Store support. Version 8.x does NOT work.
8. **Test Store transactions appear under Customers → Sandbox tab**, not the main Customers view.

---

## Step-by-Step: What We Actually Did

### Step 1: Create RevenueCat Project

1. Go to [app.revenuecat.com](https://app.revenuecat.com) and log in
2. Create a project called "Blinking"
3. The project comes with:
   - A **Test Store** automatically provisioned
   - A **Test Store API key** (starts with `test_`) found at: **Project Settings → API Keys**
   - This key works immediately — no App Store Connect or Google Play Console needed

### Step 2: Create Entitlement

1. **Entitlements** tab → + New
2. **Identifier:** `pro_access` (this exact string — the SDK checks for this)
3. Display name: `Blinking Notes Pro` (cosmetic only)
4. **Important:** The identifier, not the display name, is what the code checks. We initially created one with identifier "Blinking Notes Pro" which caused a mismatch. Had to create a new one with the correct identifier.

### Step 3: Create Product

1. **Products** tab → + New (under Test Store)
2. Store Product ID: `blinking_pro` (this exact string)
3. Type: Non-consumable
4. Attach to entitlement: select `pro_access`
5. Display name: `One-time purchase launch promo` (cosmetic)
6. REST API identifier is auto-generated (e.g., `prode42753c65f`) — ignore this, the SDK uses the Store Product ID

### Step 4: Create Offering

1. **Offerings** tab → + New
2. The offering gets a REST API identifier (e.g., `ofrng88832e4ac2`)
3. Add `blinking_pro` as a package
4. **Critical:** Click the ⋮ menu → **Set as Current**
5. Without this, `Purchases.getOfferings().current` returns null

### Step 5: Configure the App

#### 5a. Upgrade purchases_flutter SDK

```yaml
# pubspec.yaml — must be ≥ 9.8.0 for Test Store support
purchases_flutter: ^9.8.0
```

We were on 8.4.0 which caused `CONFIGURATION_ERROR` because the SDK tried real StoreKit instead of Test Store.

#### 5b. Add API key to main.dart

```dart
// RevenueCat Test Store API key
const _rcTestApiKey = String.fromEnvironment(
  'RC_API_KEY',
  defaultValue: 'test_YOUR_KEY_HERE',
);

void main() async {
  // ...
  final purchasesService = PurchasesService();
  await purchasesService.init(unifiedKey: _rcTestApiKey);
  // ...
}
```

#### 5c. Update PurchasesService

- Added `unifiedKey` parameter for single-key Test Store init
- `purchasePackage()` now returns `PurchaseResult` (not `CustomerInfo`) in 9.x — use `result.customerInfo`
- Added fallback to search all offerings (not just current)
- Wrapped `getCustomerInfo()`/`getOfferings()` in try-catch

#### 5d. iOS CocoaPods

```bash
cd ios
pod repo update
pod update PurchasesHybridCommon
```

Upgrading from 8.x → 9.x changed `PurchasesHybridCommon` from 14.3.0 → 17.55.1, requiring a CocoaPods update.

### Step 6: Test on Simulator

#### 6a. Build and Run

```bash
flutter run -d "iPhone 17 Pro" --debug
```

#### 6b. Debug Toggle (for testing paywall)

The app normally starts in 21-day preview mode (free AI). To test the paywall:

1. Go to **Settings → About**
2. Tap **"Version 1.1.0-beta.8"** 5 times quickly
3. Snackbar: "Debug: Switched to restricted mode"
4. Tap the floating robot 🤖 → paywall appears

**Note:** `_applyLocalPreview()` in `EntitlementService` was overriding the restricted state. Fixed by adding an early return when `_state` is already `restricted` or `paid`.

#### 6c. Test Purchase Flow

1. Paywall → **Get Pro — $9.99**
2. Native purchase sheet appears with 3 buttons:
   - **Test valid purchase** — simulates success (should show "Welcome to Pro!")
   - **Test failed purchase** — also returns success in Test Store (production will fail correctly)
   - **Cancel** — dismisses without change
3. "Welcome to Pro!" snackbar confirms successful purchase
4. Verify: RevenueCat → Customers → **Sandbox** tab shows the transaction

#### 6d. Test Restore Purchases

1. On paywall → **Restore Purchases**
2. Should show "Pro restored." on success
3. Or "No previous Pro purchase found." if no purchase exists for that device

---

## Gotchas & Fixes Applied

| Issue | Cause | Fix |
|-------|-------|-----|
| `CONFIGURATION_ERROR` on launch | `purchases_flutter 8.x` doesn't support Test Store | Upgrade to `≥ 9.8.0` |
| `purchasePackage` return type mismatch | API changed in 9.x: returns `PurchaseResult` not `CustomerInfo` | Use `result.customerInfo` |
| CocoaPods conflict | `PurchasesHybridCommon` pinned to 14.3.0 from 8.x | `pod update PurchasesHybridCommon` |
| "blinking_pro not found" | Offering not set as Current | Set offering as Current in RevenueCat |
| Paywall doesn't appear after debug toggle | `_applyLocalPreview()` overriding restricted state | Early return when `_state == restricted` |
| Purchase returns but no "Welcome" snackbar | `isPro` check on stale `_customerInfo` | Call `refreshCustomerInfo()` after purchase |
| "No previous purchase found" on restore | Entitlement identifier mismatch (used "Blinking Notes Pro" vs `pro_access`) | Created new entitlement with correct identifier |

---

## Production Keys (Next Steps)

### iOS — ✅ Verified (App Store Sandbox)
1. App Store Connect → In-App Purchases → created `blinking_pro` (Non-Consumable, $9.99)
2. App Store Connect → App Information → Shared Secret: `cb7d69f2d98245de95e9eab7b4e0bbaf`
3. App Store Connect → Users & Access → Keys → In-App Purchase Key: ID `S7GU3FWWH5`, Issuer `8525f01e-0925-49f8-9862-739031df8d50`
4. RevenueCat → Apps & Providers → App Store → connected with above credentials
5. Production key obtained: `appl_vgTGaiNtCARgmdgOzpJcZyITNAT`
6. Sandbox purchase verified: "Welcome to Pro!" with sandbox tester account

### Android
1. Google Play Console → Your App → Monetize → Products → In-app products → ID: `blinking_pro`
2. Google Play Console → Setup → Service accounts → create + download JSON
3. RevenueCat → Apps & Providers → + New → Google Play → enter Package Name + upload JSON
4. The `goog_` key will appear

### Switching to Production
```bash
# Build with production keys
flutter build appbundle --release --dart-define=RC_API_KEY=goog_YOUR_KEY
flutter build ipa --release --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT
```

---

## File Reference

| File | What changed |
|------|-------------|
| `lib/main.dart` | Added `PurchasesService.init(unifiedKey:)` with test key |
| `lib/app.dart` | `PurchasesService` injected as `Provider.value` |
| `lib/core/services/purchases_service.dart` | `unifiedKey` param, `PurchaseResult` fix, error handling, offering fallback search |
| `lib/core/services/entitlement_service.dart` | `_applyLocalPreview()` early return for restricted/paid state |
| `lib/screens/purchase/paywall_screen.dart` | `refreshCustomerInfo()` after purchase, better error messaging |
| `lib/screens/settings/settings_screen.dart` | Debug toggle (5-tap version text), version bump to 1.1.0-beta.8 |
| `pubspec.yaml` | `purchases_flutter: ^9.8.0` (currently 9.16.1) |
| `ios/Podfile.lock` | Updated CocoaPods (PurchasesHybridCommon 17.55.1) |
