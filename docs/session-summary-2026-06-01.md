# Session Summary — 2026-05-31 to 2026-06-01

## Version: v1.2.0+52 (v1.2.0+51 in production review)

### Completed

#### 1. Dynamic Pricing + Price Change ($19.99 → $7.99)
- `PurchasesService.proPriceString` reads from RevenueCat offerings
- 13 hardcoded `$19.99` strings replaced across 6 files
- App Store Connect + Google Play Console prices updated to $7.99
- RevenueCat: no changes needed (auto-syncs from stores)

#### 2. Release Build Safety
- Crash guard: `kReleaseMode && _rcApiKey.isEmpty` → fatal exception — impossible to ship key-less builds
- `_lastError` propagation when RC key is null/empty
- `build_ios.sh` validates required keys at build time

#### 3. Purchase Flow Bugs (Critical)
- **iOS false-positive Pro:** `|| info != null` always true on TestFlight sandbox → granted Pro without payment. Fixed: `service.isPro` only.
- **Stale offerings cache:** Price change after build cut invalidates cached `StoreProduct` references. Fixed: refresh offerings before every purchase (`Purchases.getOfferings()`).
- **Android hang:** Offerings refresh could hang forever if Play Billing unresponsive. Fixed: 30s timeout.
- **Android dead button:** `refreshCustomerInfo()` exception left `_isPurchasing` stuck. Fixed: try/catch wrap.
- **RC identity persistence:** iOS Keychain survives uninstall — `Purchases.logOut()` + random `appUserID` via debug toggle for testing.

#### 4. Keepsake Save (DEF-M-001)
- v45: Double postFrameCallback — broken on iOS
- v46: `renderToFile`/`_renderOffscreen` — broken on all platforms (violated Lesson 13)
- v47: **Reverted to v43 OverlayEntry pipeline** — all UAT passes (36/36 on all 3 platforms)
- Root cause of iOS failure: `objective_c.framework` missing from app bundle (dirty build without `pod install`)

#### 5. Google Play Compliance
- All media permissions stripped via `tools:node="remove"`: `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE`, `CAMERA`
- App uses system photo picker on Android 13+ (no permission needed)

#### 6. UI Cleanup
- AI Rewrite CTA removed from card builder — not aligned with product strategy
- Save as Keepsake button removed from Reflection screen — never required

#### 7. UAT Infrastructure
- `p1-paywall-ready.yaml` — RC initialization + price display validation
- `p2-paywall-cta-smoke.yaml` — Restore Purchases SDK round-trip
- Real-device purchase checklist (`docs/plans/uat/real-device-purchase-checklist.md`)

### Test Results
- `flutter analyze`: 0 errors, 265 issues
- `flutter test`: 557 pass, 8 pre-existing flaky (same test files as before)
- Maestro UAT: 36/36 flows passed (12 per platform × 3 platforms)

### New Documents
| Document | Purpose |
|----------|---------|
| `docs/process/pre-store-submission-gates.md` | 3-gate process: local device → store upload → store verification |
| `docs/plans/uat/real-device-purchase-checklist.md` | 17-point pre-submission purchase validation |
| `docs/lessons-learned-purchase-stale-offerings.md` | RCA: stale offerings after price change (recurring) |

### Key Commits
```
c0cf4e6  fix: remove non-functional Save as Keepsake from Reflection screen
cf5efcd  fix: use random appUserID after logOut
d652f15  fix: RC identity reset via debug toggle
03d16f6  v1.2.0+52: bump for Android closed testing
a0584d7  v1.2.0+51: strip all media permissions
e7420ad  fix: remove false positive Pro gate (|| info != null)
d0cf8e8  fix: 30s timeout on offerings refresh
e620d98  docs: lesson 21 — local real-device test gate
73b8f8b  docs: lesson 20 — stale offerings after price change
3e3f67b  v1.2.0+44: dynamic pricing + crash guard
```
