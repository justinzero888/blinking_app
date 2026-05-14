# Blinking — Session Summary 2026-05-13

**Version:** 1.1.0+36 | **Tests:** 164/164 | **Lint:** 0 errors

---

## Production Status

| Store | Build | Status |
|-------|-------|--------|
| Google Play | 1.1.0 (AAB) | ✅ Submitted for review |
| iOS App Store | 1.1.0+35 | ✅ Submitted for review |

---

## Completed Today (May 13)

### IAP App Review Fix
- Diagnosed missing `RC_API_KEY` in production IPA build command
- Converted paywall from `StatelessWidget` → `StatefulWidget` with loading spinner + disabled buttons
- Fixed cancellation detection (`PlatformException` code matching)
- Removed debug SnackBar leaking internal state
- Added inline "Store unavailable" warning
- Built `scripts/build_ios.sh` with key validation
- Verified sandbox purchase on TestFlight build 35 after Paid Apps Agreement activation
- Resubmitted for App Review

### Device Identity (Preview Abuse Prevention)
- D1 table `device_fingerprints` + fingerprint check in `/api/entitlement/init`
- iOS: `UIDevice.identifierForVendor` → sha256 via platform channel
- Android: `Settings.Secure.ANDROID_ID` → sha256 via platform channel
- Client: `DeviceFingerprintService` sends fingerprint with `_callInit()`
- Logic: blocks reinstall only after 21-day expiry; Pro users bypass; factory reset allows fresh preview
- Decision documented: factory reset intentionally allows fresh preview ($19.99 price, journaling niche)

### UAT Fixes (from May 13 UAT)
- **Banner text**: "Full access trial active" → "21-Day Preview — X days left" in both Settings banner and robot menu
- **Robot avatar regression**: Changed `context.read` → `context.watch<AiPersonaProvider>` + added `LocaleProvider` import
- **Annual Reflection**: `_saved` flag disables "Save to Journal" after first save; resets on regenerate
- **Feedback version**: Hardcoded `1.1.0-beta.7` → `AppConstants.appVersion` in both display and email subject
- **iOS feedback**: Added `LaunchMode.externalApplication` + `launched` return value check for fallback snackbar
- **iOS crash fix**: `window?.rootViewController as!` → optional binding for implicit engine startup
- **iOS icon**: Updated all 21 sizes in `Assets.xcassets/AppIcon.appiconset`
- **Android icon**: Updated foreground + legacy PNGs for all 5 densities

### Chinese Locale + Personas
- Added `nameZh`, `avatarAssetCn` fields to `ReflectionStyle`
- Updated all 4 presets with Chinese names from `AI Personas.json`:
  - 楷迩 (Kael) · 依澜 (Elara) · 如溯 (Rush) · 墨克 (Marcus)
- Updated vibes, lens questions, and system prompts with Chinese content
- CN avatars auto-switch when locale is 中文 (`avatarAssetFor(bool isZh)`)
- `AiPersonaProvider.displayNameFor` now locale-aware
- Settings preview card + style selection cards use `displayName(isZh)`
- Reflection session screen uses provider's `displayNameFor`
- Floating robot uses `styleAvatarAssetFor(isZh)`

### AI Cost Benchmark
- Tested all 4 personas with DeepSeek V3 on OpenRouter
- Average: 7.4s response time, $0.00015 per reflection
- 21-day trial (63 calls/user): **$0.01/user**
- 1,000 users: **~$10 total AI cost**
- Chinese entries produce 30% fewer output tokens (more concise AI responses)

### Data Portability Gate Fix
- Fixed cancel-bypasses-gate bug: all 6 export/backup/restore items now always block after re-engage
- Subsequent taps go straight to paywall (no dead tap)

---

## Remaining Gaps (Non-Blocking)

| # | Gap | Priority |
|---|-----|----------|
| G2 | Production IPA hardcoded `'receipt': 'revenuecat_validated'` | P3 |
| G3 | No `addCustomerInfoUpdateListener` in RevenueCat | P3 |
| D1 | #6 — Personas web page at `blinkingchorus.com/personas` | P2 |

---

## Files Changed

**New files (13):**
- `scripts/build_ios.sh`
- `scripts/benchmark_personas.py`
- `scripts/benchmark_locale.py`
- `scripts/generate_avatars.py`
- `lib/core/services/device_fingerprint_service.dart`
- `assets/avatars/kael_cn.png`, `elara_cn.png`, `rush_cn.png`, `marcus_cn.png`
- `docs/plans/uat-may13-final-2026-05-13.md`
- `docs/plans/uat-iap-fix-2026-05-12.md`
- `docs/plans/device-identity-2026-05-12.md`
- `docs/plans/iap-app-review-checklist-2026-05-12.md`
- `docs/plans/iap-sandbox-testing-guide-2026-05-12.md`
- `chorus-api/migrations/0012_device_fingerprints.sql`

**Modified source files (15):**
- `lib/screens/settings/settings_screen.dart` — custom persona, CN locale, gates, feedback, banner
- `lib/screens/purchase/paywall_screen.dart` — IAP loading state
- `lib/core/services/purchases_service.dart` — IAP fixes, gate
- `lib/core/services/entitlement_service.dart` — fingerprint, canExport fix
- `lib/models/reflection_style.dart` — nameZh, avatarAssetCn, avatarAssetFor
- `lib/providers/ai_persona_provider.dart` — locale-aware displayName, styleAvatarAssetFor
- `lib/widgets/floating_robot.dart` — locale avatar, preview menu text, context.watch
- `lib/screens/assistant/assistant_screen.dart` — locale avatar
- `lib/screens/reflection/reflection_session_screen.dart` — locale avatar + displayName
- `lib/screens/cherished/cherished_memory_screen.dart` — save-once, canUseAI gate
- `lib/screens/routine/routine_screen.dart` — history fix, restricted gates
- `lib/providers/summary_provider.dart` — earliestDataDate
- `lib/core/services/storage_service.dart` — tag_welcome
- `lib/app.dart` — welcome entry, add habit gate
- `ios/Runner/AppDelegate.swift` — IDFV method channel
- `android/app/src/main/kotlin/.../MainActivity.kt` — ANDROID_ID method channel
- `pubspec.yaml` — crypto dep, assets/avatars/
