# Lesson Learned — Stale RevenueCat Offerings After Price Change

**Incident IDs:** May 7 (TestFlight), June 1 (Closed Testing)  
**Severity:** Critical — revenue-blocking, silent failure  
**Status:** Code fixed, process rules established

---

## Recurring Pattern

This is the **second time** the same class of bug has blocked a store submission:

| Date | Incident | Symptom |
|------|----------|---------|
| 2026-05-07 | RevenueCat credentials not saving → TestFlight returns "No offerings" | Buy button does nothing, no error |
| 2026-06-01 | Price changed from $19.99→$7.99 AFTER v1.2.0+47 deployed to Closed Testing | iOS: silent dismiss. Android: button frozen. |

In both cases, the paywall appeared normal (price displayed, no "Store unavailable" warning) but the purchase button was non-functional with zero user feedback. Both were caught in store testing, never reached production.

---

## Root Cause

`PurchasesService.init()` fetches `_offerings` once at app startup and caches them. The `StoreProduct` references inside these offerings are live pointers into the platform store catalog at fetch time. When store prices change AFTER the cache is populated:

- iOS StoreKit2 rejects the stale reference → maps to `PURCHASE_CANCELLED`
- Android Play Billing returns empty results → billing flow never launches → `await` hangs permanently

The May 7 incident had the same mechanism — stale/incomplete RevenueCat configuration caused offerings to return empty/null, triggering the same silent failure path.

---

## Why Simulator + Maestro Didn't Catch It

1. **Simulators use local test environments** (Xcode `.storekit`, Google Play local test billing) — completely isolated from App Store Connect and Play Console. Price changes in live stores have zero effect on simulators.

2. **Maestro `p1-paywall-ready` validates pre-purchase state only** — store initialized, price displayed, button enabled. It does not tap "Get Pro" because native OS payment sheets cannot be traversed by XCTest/Maestro.

3. **`clearState: true` cold-starts the app** on every Maestro run, causing fresh `init()` and fresh offerings fetch. The stale-cache condition cannot occur in automated tests.

---

## Code Fix (Applied)

Two changes in `lib/core/services/purchases_service.dart` `purchaseProduct()`:

1. **Refresh offerings before purchase:**
```dart
try {
    _offerings = await Purchases.getOfferings();
    notifyListeners();
} catch (_) {
    // Non-fatal: proceed with cached offerings if refresh fails
}
```

2. **90-second timeout on `Purchases.purchase()`:**
```dart
final result = await Purchases.purchase(PurchaseParams.package(pkg))
    .timeout(const Duration(seconds: 90), onTimeout: () => throw PlatformException(
        code: 'PURCHASE_TIMEOUT',
        message: 'Purchase timed out — please try again.',
    ));
```

These are defense-in-depth. The code can now recover from stale offerings — but the process should prevent the condition entirely.

---

## Process Rules (Mandatory)

### Rule 1: Price changes before build
```
✅ Price change → wait for propagation → build → deploy
❌ Build → deploy → price change (causes stale cache)
```

### Rule 2: Real-device purchase test before ANY store submission
Complete `docs/plans/uat/real-device-purchase-checklist.md` (17 checkpoints) on:
- 1× real iPhone with sandbox Apple ID
- 1× real Android with Play test account

No build may enter TestFlight, Closed Testing, or production without a signed-off checklist.

### Rule 3: Price-change resilience re-validation
If prices are changed after a build is cut, re-run checkpoints 14-17 of the real-device checklist on that build before promotion.

---

## Documents Created
- `docs/plans/uat/real-device-purchase-checklist.md` — 17-point pre-submission checklist
- `maestro-tests/apps/blink-notes/flows/uat/p2-paywall-cta-smoke.yaml` — SDK round-trip smoke test
