# Lessons Learned — Release & Purchase Flow (2026-05-31 to 2026-06-01)

## Lesson 20: Price Changes After Build Cut → Stale RevenueCat Offerings → Silent Purchase Failure (Recurring)

**This is the second occurrence.** May 7 and June 1 — same mechanism, different triggers.

`_offerings` is fetched once at `init()` and cached. `StoreProduct` references inside offerings are pointers into the live store catalog. When prices change AFTER the cache is populated, subsequent `Purchases.purchase()` calls with stale references fail silently — iOS dismisses, Android hangs.

**Code fix:** `purchaseProduct()` now refreshes offerings before every purchase. This is defense-in-depth — stale cache is handled, but shouldn't be the only safeguard.

**Process rule:** Price changes must happen BEFORE the build is cut. If prices change after deployment, re-build and re-validate.

---

## Lesson 21: iOS Keychain Survives Uninstall — RevenueCat Identity Persists

RevenueCat's iOS SDK stores customer identity in the iOS Keychain. App uninstall does NOT clear the Keychain. Same device = same RC customer = `pro_access` survives reinstall.

**Impact:** Testing the purchase flow on a device that previously purchased `blinking_pro` (even in sandbox) auto-restores without showing the payment sheet. Uninstalling, changing sandbox Apple IDs, or regenerating the `appUserID` UUID does NOT bypass this — RC merges by `identifierForVendor` server-side.

**Mitigation:** Debug toggle (5-tap version) now calls `Purchases.logOut()` + configures with random `appUserID`. For true fresh-customer testing: delete the customer from RevenueCat → Customers → Sandbox.

---

## Lesson 22: `info != null` Is a False-Positive Pro Gate on Sandbox IAP

`Purchases.purchase()` on iOS sandbox/TestFlight always returns a non-null `CustomerInfo` — even when no purchase actually completes. Our code checked `info != null` as a success gate, which was always true on TestFlight, granting Pro access without payment.

**Fix:** `service.isPro` (which checks `_customerInfo.entitlements.active.containsKey('pro_access')`) is the only reliable gate. The `|| info != null` was removed.

**Impact if shipped:** Every "Get Pro" cancel/decline would have granted Pro for free — $7.99 per lost sale.

---

## Lesson 23: Play Billing Unavailable → `getOfferings()` Hangs Forever → Dead Button

On Android, `Purchases.getOfferings()` can hang if Play Billing isn't responding (sideloaded APK, Play Services issue). With no timeout, `_purchasing` stays `true` forever, blocking all subsequent taps silently.

**Fix:** 30s timeout + try/catch on the offerings refresh. If it times out, proceeds with cached offerings or shows error.

---

## Lesson 24: `refreshCustomerInfo()` Throw on Android → Silent Dead Button

In `_handlePurchase()`, `refreshCustomerInfo()` was called without try/catch. On Android, if RevenueCat threw an exception (network error, SDK issue), the unhandled exception left `_isPurchasing` stuck at `true` and the button permanently disabled with no user feedback.

**Fix:** Wrapped in try/catch.

---

## Lesson 25: TestFlight Sandbox Returns Non-Null CustomerInfo Even on Cancel

The Apple sandbox IAP environment always returns a `CustomerInfo` object from `Purchases.purchase()` — even when the user cancels or the card is declined. This is fundamentally different from production. The only reliable test is to verify `entitlements.active` on the returned CustomerInfo, not whether CustomerInfo is non-null.

---

## Lesson 26: `renderToFile()` / `_renderOffscreen()` Is Test-Only

Re-confirmed Lesson 13. Manual `PipelineOwner` + `BuildOwner` + `element.mount(null, null)` only works under `TestWidgetsFlutterBinding`, not production `WidgetsFlutterBinding`. In v46, replacing the working OverlayEntry pipeline with `renderToFile` broke card saving on ALL platforms. The v43 OverlayEntry approach (reverted in v47) is the only production-safe off-screen rendering pipeline.
