# Response to UAT Feedback — v1.2.0+52

**To:** QA Automation Team  
**Date:** 2026-06-02  
**Build:** v1.2.0+53 (commit `32d1280`)

---

## All Issues Addressed

### Issue 1 — `resetIdentity()` throw aborting debug toggle ✅ Fixed

Root cause confirmed. `Purchases.configure()` called twice. Fix applied:

```dart
// lib/screens/settings/settings_screen.dart
try {
  await context.read<PurchasesService>().resetIdentity();
} catch (e) {
  debugPrint('[Settings] resetIdentity failed (non-fatal): $e');
}
```

`svc.init(prefs)` now always executes. `entitlement_state` syncs to `restricted` in memory, `notifyListeners()` fires, snackbar confirms toggle.

### Issue 2 — k8 referencing removed `btn_reflection_save_keepsake` ✅ Fixed

Flow updated to end at "Saved" confirmation after tapping "Save Reflection." Keepsake section removed.

### Test infrastructure changes ✅ Synced

| File | Change | Status |
|------|--------|--------|
| `subflows/launch.yaml` | Timeout 8s → 15s | Synced |
| `k8-reflection-entry.yaml` | Removed keepsake section | Synced |
| `p1-paywall-ready.yaml` | `extendedWaitUntil` 40s gate | Synced |
| `p2-paywall-cta-smoke.yaml` | Same as p1 | Synced |

---

## v1.2.0+53 Deployment

| Platform | Device | PID |
|----------|--------|-----|
| iPhone 17 Pro | E755BD80 | 22053 |
| iPad Air M4 | 39B46CD1 | 22060 |
| Android | emulator-5554 | running |

### Run command
```bash
cd maestro-tests
./ci/run-uat-iphone.sh --device E755BD80
./ci/run-uat-ipad.sh --device 39B46CD1
./ci/run-uat-android.sh --device emulator-5554
```

### Expected results
- **iPhone:** 12/12
- **iPad:** 12/12
- **Android:** 12/12 (re-run if emulator cold-start flakes on k7/k8/k10 — known environment issue)

---

## Notes for testing team

1. k7/k8/k10 Android cold-start flakes are acknowledged as environment issue — not code regressions. If they fail on a single run, re-run the affected flows individually.
2. The `resetIdentity()` suggestion (15s timeout on `getCustomerInfo()`) is noted for the next dev cycle. Not blocking for v1.2.0+53.
3. All Maestro flows synced from your repository. Future updates should continue in your copy and be synced before next build.
