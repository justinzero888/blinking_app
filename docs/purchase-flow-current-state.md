# Purchase Flow — Current State (v1.2.0+56)

**Date:** 2026-06-03
**Status:** Code complete. One configuration gap blocks Android end-to-end validation.

---

## 1. Architecture

```
RC (RevenueCat) is the single source of truth for paid state.

PurchasesService.isPro
    │
    ├── true  → EntitlementService → paid state → no "Get Pro" CTA
    │                                   └── Auto-restore on launch (init syncs from RC)
    │
    └── false → EntitlementService → preview/restricted state
                    ├── "Get Pro" CTA visible on paywall, settings, floating robot
                    └── Tap → _handlePurchase()
                              ├── isPro? → skip sheet, auto-restore (defensive)
                              └── !isPro → Purchases.purchase() → native payment sheet
```

### Sync points

| When | What |
|------|------|
| App start | `EntitlementService.init(isPro: purchasesService.isPro)` — RC state wins |
| After purchase | `_customerInfo` set from `PurchaseResult.customerInfo` — authoritative |
| After purchase | `_markEntitlementPaid()` writes `paid` to SharedPreferences + re-inits service |

---

## 2. Code — `_handlePurchase` (paywall_screen.dart:319–363)

```dart
setState(() => _isPurchasing = true);

final info = await service.purchaseProduct('blinking_pro');
setState(() => _isPurchasing = false);

if (info == null && service.lastError == null) {
    return;  // user cancelled — no-op
}

// Purchase result _customerInfo is authoritative. Do NOT refreshCustomerInfo()
// here — it can overwrite with pre-sync server state (race condition).
if (service.isPro || info != null) {
    _markEntitlementPaid(entitlement);
    "Welcome to Pro!"
    Navigator.pop(context);
} else if (service.lastError != null) {
    showSnackBar(lastError);
}
```

### Gate logic

| Scenario | `service.isPro` | `info` | Result |
|----------|:---:|:---:|--------|
| New user, successful purchase | `true` (from purchase result) | non-null | ✅ Pro unlocked |
| Existing owner, purchase already synced in RC | `true` (from RC) | — | ✅ Auto-restored, sheet skipped |
| User cancels payment sheet | `false` | `null` | ✅ No-op |
| Google Play "already owned" (correct RC key) | `true` (from RC sync) | non-null | ✅ Auto-restored |
| Google Play "already owned" (wrong RC key) | `false` | non-null | ❌ **Grants Pro without RC entitlement** |
| Purchase declined | `false` | could be non-null | ⚠️ May grant Pro on sandbox |

---

## 3. `purchaseProduct` (purchases_service.dart:135)

```dart
_purchasing = true;

// Refresh offerings (30s timeout) — prevents stale StoreProduct after price changes
try {
    _offerings = await Purchases.getOfferings().timeout(30s);
} catch (_) { /* proceed with cached */ }

// Product lookup → blinking_pro
// Fallback: search all offerings, then first available package

final result = await Purchases.purchase(PurchaseParams.package(pkg)).timeout(90s);
final customerInfo = result.customerInfo;

// Validate with server (receipt: null — deferred to v1.3)
if (customerInfo.entitlements.active.containsKey('pro_access')) {
    await _validateWithServer();
}

_customerInfo = customerInfo;
_purchasing = false;
notifyListeners();
return customerInfo;
```

---

## 4. Known Issues

### Issue A: `|| info != null` is a false positive on sandbox

On TestFlight/iOS sandbox, `Purchases.purchase()` always returns a non-null `CustomerInfo` — even on cancel/decline. The `info != null` gate grants Pro without verifying entitlement.

**Status:** Known. Does not affect production (on production, cancels return `null`). Accepted risk per v1.1.0 behavior.

### Issue B: Google Play "already owned" with mismatched RC key

If Google Play has a license for `blinking_pro` but RevenueCat doesn't (wrong RC project, disconnected store), tapping "Get Pro" shows the native "You already own this item" dialog. `Restore Purchases` fails because RC can't see the Play Store purchase.

**Status:** Configuration gap. Fix: ensure Google Play is connected to the correct RC project under **RevenueCat → Apps & Providers**.

### Issue C: iOS Keychain persists RC identity across reinstalls

RC stores customer identity in iOS Keychain. Uninstall/reinstall does not clear it. Same device = same RC customer = `pro_access` survives (correct for production, inconvenient for testing).

**Status:** Known. For testing on same device: delete customer from RC → Customers → Sandbox. No code fix needed.

---

## 5. Correct Production Key Configuration

| Platform | Key | Source |
|----------|-----|--------|
| iOS | `appl_vgTGaiNtCARgmdgOzpJcZyITNAT` | RevenueCat → Project Settings → API Keys |
| Android | `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` | RevenueCat → Project Settings → API Keys |

### Build commands

```bash
# iOS
flutter build ipa --release \
  --dart-define=RC_API_KEY=appl_vgTGaiNtCARgmdgOzpJcZyITNAT \
  --dart-define=TRIAL_API_KEY=<trial_key> \
  --dart-define=PRO_API_KEY=<pro_key>

# Android
flutter build appbundle --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioi \
  --dart-define=TRIAL_API_KEY=<trial_key> \
  --dart-define=PRO_API_KEY=<pro_key>
```

---

## 6. Verification Checklist

Before promoting any build to production:

- [ ] iOS: `flutter build ipa` with `appl_` key → TestFlight
- [ ] Android: `flutter build appbundle` with `goog_ITjNhBQowFMaFwdyZYvaCGqqioi` → Closed Testing
- [ ] RevenueCat → Apps & Providers → **Google Play connected** with correct service account JSON
- [ ] RevenueCat → Products → `blinking_pro` attached to `pro_access` under Google Play
- [ ] Real-device test: tap "Get Pro" → native payment sheet → complete → "Welcome to Pro!"
- [ ] Real-device test: restore purchases works
- [ ] SharedPreferences: `entitlement_state = paid` persists after force-kill
- [ ] No "Store unavailable" warning on paywall
