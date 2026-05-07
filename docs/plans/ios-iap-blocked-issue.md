# iOS IAP — Blocked Issue Log

**Date:** 2026-05-07 | **Status:** Blocked — moved to Google Play

## Current State

| Component | Status |
|-----------|--------|
| App Store Connect: `blinking_pro` IAP | Ready to Submit ✅ |
| RevenueCat: Offering `ofrng88832e4ac2` | Current ✅ |
| RevenueCat: Entitlement `pro_access` | Linked ✅ |
| RevenueCat: App Store Connection | **Credentials not saved** ❌ |
| RevenueCat: Offerings fetch | Returns empty → "No offerings available" ❌ |
| TestFlight Build | v1.1.0-beta.8+25 uploaded, diagnostic logging added |

## Root Cause

RevenueCat's "Save Change" button for the App Store connection stays blue/unclickable despite all fields being filled. The In-App Purchase Key section had expired key `S7GU3FWWH5` while the App Store Connect API section had valid key `4UK6U499RC`. Updated both to `4UK6U499RC` but save still fails.

RevenueCat's `getOfferings()` returns empty because the App Store connection was never successfully saved.

## Attempted Fixes

1. Re-entered all credentials fresh (Bundle ID, Shared Secret, Key ID, Issuer ID)
2. Uploaded .p8 file with correct naming (`AuthKey_4UK6U499RC.p8`)
3. Matched both API Key sections to use the same key
4. Tried clicking outside fields before saving
5. Different browsers — not yet tried (Chrome incognito, Safari)

## Next Steps (When Resumed)

1. Try RevenueCat save via Chrome incognito or Safari
2. If save works → rebuild IPA → upload to TestFlight → test
3. If save still fails → contact RevenueCat support or create a new RevenueCat project
4. Alternative: test IAP directly through Xcode (Archive → Distribute → Development)
