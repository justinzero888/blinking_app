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
- [ ] 14. Note the price shown on paywall at first launch (before any background activity)
- [ ] 15. Change price in App Store Connect / Play Console
- [ ] 16. Without restarting the app, tap "Get Pro"
- [ ] 17. Confirm payment sheet appears with the NEW price (offerings refresh fires before purchase)
- [ ] 18. Cancel. Confirm paywall recovers cleanly

### Already-Pro User Flow
> Required on any change to entitlement routing or purchase gate logic.
- [ ] 19. iPhone: Use debug toggle (Settings → About → tap version 5x from preview) to cycle to restricted, then purchase in sandbox to reach Pro state
- [ ] 20. Force-kill and reopen. Tap robot → confirm AssistantScreen opens, NOT PaywallScreen
- [ ] 21. Navigate to Settings → confirm Pro banner shows, no "Get Pro" prompt visible
- [ ] 22. Android: repeat steps 19–21

### Reinstall Restore Flow
> Required on any change to restorePurchases() or _handleRestore logic.
- [ ] 23. iPhone: Uninstall app. Reinstall from TestFlight using same sandbox account
- [ ] 24. Enter restricted mode via debug toggle → tap robot → paywall opens
- [ ] 25. Tap "Restore Purchases" → SDK round-trip completes → "Pro restored." snackbar + paywall closes
- [ ] 26. Confirm Pro features unlocked (no paywall on next robot tap)
- [ ] 27. Android: repeat steps 23–26 with Play Internal Testing account

---

**Tester:** _______
**Date:** _______
**Build:** _______
**Result:** PASS / FAIL
