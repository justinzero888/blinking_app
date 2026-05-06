# Session Summary — 2026-05-05

**App:** Blinking (记忆闪烁) v1.1.0-beta.8+23  
**Duration:** Full session (~10 hours)  
**Tests:** 106/106 passing  
**Scope:** Image compression, backup optimization, persona fix, local offline preview, M3 onboarding, Routine redesign (Build/Do/Reflect), Settings cleanup, seed data, version bump, APK builds, Routine redesign (Build/Do/Reflect), Settings cleanup, seed data

---

## What We Did

### Phase 1: Image Compression & Backup Optimization
- Root cause: 1.6 GB backup from 204 uncompressed 12MP photos. `FileService.saveFile()` did raw copy. `image_picker` had no resize params.
- Option A — Added `flutter_image_compress` (^2.4.0). Three compression layers: pick time (1920px q85), save time (`FileService.compressImage()`), export time (compress before ZIP).
- Option B — "Include photos" toggle in backup dialog (default: OFF). Text-only backup ~200 KB.
- Result: 6-image test backup went from estimated ~48 MB → **4.8 MB**.

### Phase 2: Persona Backup/Restore Bug Fix
- Bug 1: `Navigator.pop(dialogContext)` called BEFORE `AiPersonaProvider.reload()` — UI rebuilt with stale values.
- Bug 2: `manifest.json` hardcoded `hasMedia: true`.
- Bug 3: No error handling around `persona.json` parsing during restore.
- 8 new tests (5 export + 3 restore).

### Phase 3: Local Offline Preview + Quota Change
- Quota: 9 → 3 AI/day. Settings banner shows dynamically: "3 AI/day · 63 total over 21 days."
- Offline fallback: `_applyLocalPreview()` enters local PREVIEW (21 days, 3 AI/day) when server unreachable.
- Daily quota tracking via `entitlement_quota_date` SharedPreferences key.
- Preview days persistence bug fix: was only recalculated on `restricted` state; now always runs when no JWT.
- Trial token bridge: stores `trial_token` for `LlmService` compatibility; local preview shows clear server-unavailable message instead of misleading "invalid key."

### Phase 4: M3 Onboarding
- 3-screen PageView: philosophy (no skip), what's inside (skip), the deal (skip).
- Language detection from system locale, toggle on screen 1.
- Pro $9.99 tappable link on screen 3 → PaywallScreen.
- Soft prompts (days 18/19/20, 1-per-24h) wired into habit completion + AI reflection save.
- Re-engagement triggers (backup/habit gates, 1-per-7d) via `SoftPromptService`.

### Phase 5: Routine Redesign — Build/Do/Reflect
- Tabs renamed: 建造/Build, 执行/Do, 反思/Reflect. Do as default (`initialIndex: 1`).
- **Do tab:** Tap-to-complete (haptic + flash), progress bar, motivational copy (time-of-day), visual hierarchy (pending teal, done muted), grace reminders, personal best streak banner.
- **Build tab:** Active/inactive toggle with Switch, "why" description (120 chars) in edit dialog, count badges, empty state.
- **Reflect tab:** Three-state circle encoding (● teal = done, ✕ coral = missed, blank = not yet created), periodic summary (total completions, best streak, active habits), per-habit summary cards (streak, month %, strongest/weakest day), habit detail dialog on tap.
- **Streak grace:** 1-day auto grace allows one missed day without streak reset. Note-earned extension: writing an entry on a missed day extends grace by +1 day (up to 2 extra).

### Phase 6: Polish & Bug Fixes
- Heatmap colors: alpha-based → solid teal shades; cells 13px → 16px; date range now starts at earliest entry month, not 365 days ago.
- Settings AI section: removed individual provider list + "Add AI Provider" + yellow info box from main page; consolidated into BYOK setup screen with disclaimer at bottom.
- Seed data: ~50 entries across 30 days + 3 routines with ~28 completions each, auto-created on first launch.

### Phase 7: Onboarding UX Feedback
- Language toggle on screen 1, Pro price tappable on screen 3.
- Routine Do tab layout matched to Reflect tab (icon + name).
- Cross-tab sync fix: TabController listener forces rebuild on tab switch.

### Phase 8: Settings AI Section Cleanup
- Removed individual provider list items, "Add AI Provider" button, and yellow info box from main settings page.
- Consolidated all provider config + yellow disclaimer into BYOK setup screen.
- Settings → AI now shows only: entitlement banner + "Use my own key" entry point.

### Phase 9: Preview Days & Trial Token Fixes
- Preview days showing 0 on fresh install: `_applyLocalPreview()` only ran when state was `restricted`. Fixed to always run when no JWT. Also persisted `_previewDaysRemaining` via `_saveState()`.
- AI "invalid API key" message: local preview token was sent to server getting 401. Fixed by detecting local preview in `LlmService` and showing clear server-unavailability message.
- Trial expiry in `LlmService`: 7 days → 21 days to match new entitlement system.

### Phase 10: Version Bump & APK Builds
- Version: `1.1.0-beta.7+22` → `1.1.0-beta.8+23`
- Seed data removed from production code before final build.
- Built debug APK (159 MB) and release APK (65 MB).
- All version sync checks pass (pubspec.yaml, constants.dart).

### Phase 11: Lessons Learned
- Documented at `docs/lessons-learned-2026-05-05.md`
- Key takeaways: nuclear clean for stubborn deploys, seed data in main.dart only, persist all computed state, verify error messages match root cause.

---

## Files Changed

| File | Change |
|------|--------|
| `pubspec.yaml` | +`flutter_image_compress: ^2.4.0` |
| `lib/main.dart` | +seed data (entries + routines with completions), then removed for release |
| `pubspec.yaml` | +`flutter_image_compress`, version → 1.1.0-beta.8+23 |
| `lib/core/config/constants.dart` | appVersion → 1.1.0-beta.8 |
| `lib/core/services/file_service.dart` | +`compressImage()`, saveFile compresses images |
| `lib/core/services/export_service.dart` | +excludeMedia, +compress during export, manifest fix |
| `lib/core/services/entitlement_service.dart` | Quota 9→3, +local preview fallback, persist preview days |
| `lib/core/services/llm_service.dart` | Trial expiry 7→21d, local preview detection |
| `lib/core/services/soft_prompt_service.dart` | **New** — soft prompts + re-engagement |
| `lib/screens/onboarding/onboarding_screen.dart` | **New** — 3-screen PageView + lang toggle + Pro link |
| `lib/screens/routine/routine_screen.dart` | **Major rewrite** — Build/Do/Reflect tabs, all P0–P3 items |
| `lib/models/routine.dart` | +inGrace, +graceDaysLeft, +consecutiveMissedDays, streak with grace |
| `lib/screens/settings/settings_screen.dart` | Media toggle, persona reload fix, re-engagement gate, AI section cleanup |
| `lib/screens/settings/byok_setup_screen.dart` | +disclaimer box at bottom |
| `lib/screens/home/home_screen.dart` | Wire soft prompt on habit completion |
| `lib/screens/assistant/assistant_screen.dart` | Wire soft prompt after AI reflection save |
| `lib/screens/cherished/cherished_memory_screen.dart` | Heatmap colors/size/range fix, entry count, loading spinner |
| `lib/screens/add_entry_screen.dart` | pickImage() +maxWidth/maxHeight/q85 |
| `lib/providers/locale_provider.dart` | System locale detection |
| `lib/providers/summary_provider.dart` | +isLoading getter |
| `lib/providers/routine_provider.dart` | (seed moved to main.dart) |
| `lib/providers/entry_provider.dart` | +seed test data (entries across 30 days) |
| `lib/repositories/entry_repository.dart` | +optional createdAt/updatedAt params |
| `lib/app.dart` | +OnboardingScreen gate |
| `lib/core/services/storage_service.dart` | Persona.json error handling |
| `test/core/export_service_progress_test.dart` | +5 persona export tests |
| `test/core/storage_service_restore_test.dart` | +3 persona restore tests |

---

## Current State

**Client:** 106/106 tests, 0 analyze errors. All M1–M3 done. Routine redesign P0–P3 done.  
**Server:** Deploy-ready, not deployed. AI requires server deployment or BYOK.

## What's Remaining

| # | Item | Who | Effort |
|---|------|:--:|:------:|
| 1 | Setup IAP — RevenueCat, App Store Connect, Play Console | Human | ~2h |
| 2 | Server deploy — secrets + D1 migrations + `npm run deploy` | Human | ~10min |
| 3 | PROP-3 — Android Play Store production | Human | ~1.5h |
| 4 | M4 Top-ups — denial sheet, consumable IAP | Dev | ~3h |
