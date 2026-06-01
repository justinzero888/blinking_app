# Real-Device Purchase Validation Checklist

> **Gate:** Must be completed before any build is submitted to Internal Testing, Closed Testing, or production.
> **Reason:** Simulator StoreKit/Play test environments are isolated from live stores. Price changes,
> stale product references, and billing flow failures only surface on real devices against live store APIs.

## Devices Required
- 1× real iPhone signed in with Apple Sandbox test account
- 1× real Android phone signed in with Google Play test account

## Checklist

### Pre-Purchase Validation
- [ ] 1. Install release build on real iPhone via TestFlight / direct install
- [ ] 2. Install release build on real Android via Play Internal Testing
- [ ] 3. Launch both apps. Confirm "Store unavailable" warning is NOT shown on paywall
- [ ] 4. Confirm price on paywall matches current App Store Connect / Play Console price

### Purchase Flow — Cancel
- [ ] 5. iPhone: tap "Get Pro" → Apple payment sheet appears with correct price → tap Cancel
- [ ] 6. iPhone: confirm paywall recovers cleanly (not stuck, not dismissed)
- [ ] 7. Android: tap "Get Pro" → Google Play payment sheet appears with correct price → tap Cancel
- [ ] 8. Android: confirm paywall recovers cleanly

### Purchase Flow — Complete
- [ ] 9. iPhone (sandbox): tap "Get Pro" → complete purchase → "Welcome to Pro!" SnackBar + paywall closes
- [ ] 10. Android (test): tap "Get Pro" → complete purchase → same check
- [ ] 11. Force-kill both apps. Reopen. Confirm Pro features unlocked (entitlement persisted)

### Restore Flow
- [ ] 12. iPhone: fresh install on same sandbox account → "Restore Purchases" → Pro restored
- [ ] 13. Android: same check

### Price-Change Resilience
> Required if prices changed after last build cut.
- [ ] 14. With app running (no restart), change price in App Store Connect / Play Console
- [ ] 15. Without restarting, tap "Get Pro"
- [ ] 16. Confirm payment sheet appears with NEW price (offerings refreshed before purchase)
- [ ] 17. Cancel. Confirm paywall recovers cleanly

---

**Tester:** _______
**Date:** _______
**Build:** _______
**Result:** PASS / FAIL
