# Session Summary — 2026-05-08

**App:** Blinking (记忆闪烁) v1.1.0-beta.8+25  
**Tests:** 147/147 passing  
**Lint:** 0 errors  
**Scope:** AI Architecture Refactor — Quota language strip, Surface B (Reflection Session), Surface A (Mood Moment)

---

## Phase 0 — Foundation (DB v13 + Feature Switch)

- `kUseMultiTurnChat = false` feature switch in `constants.dart`
- New DB tables: `lens_sets`, `active_lens_set`, `ai_identity`, `ai_call_log`, `trial_milestones`
- New models: `AiIdentity`, `LensSet`, `AiCallLog`, `TrialMilestone`
- Default lens set changed from Honest Weather → **Zengzi's Three** (better daily reflection questions)
- DB migration v12→v13 — additive only, no impact on existing notes/habits

## Phase 1 — Strip Numeric Quota Language

Removed all numeric AI quota language across ~20 files:
- `entitlement_service.dart`: Removed quota counting (`_quotaRemaining`, `_quotaSource`, `_quotaRefill`). `canUseAI` is now a pure boolean state check
- `settings_screen.dart`: Rewritten `_buildEntitlementBanner()` — no numbers, no BYOK
- `onboarding_screen.dart`: Screen 3 — "Start your trial" (was "Start your 21 days")
- `transition_screen.dart`: "Your trial is complete" (was "21 天预览已完成")
- `paywall_screen.dart`: Removed "1,200 AI/year", BYOK/top-up footer
- `floating_robot.dart`: Simplified long-press menu (no quota counts)
- `legal_content.dart`: Removed all "API key" / BYOK language (EN + ZH)
- `app_en.arb` / `app_zh.arb`: Cleaned 20+ legacy trial/quota/BYOK strings
- `trial_service.dart`: **Deleted** (deprecated 7-day trial)
- `llm_service.dart`: Simplified `trialExpired` message

### Bug Fixes (Phase 1)
- **Debug toggle broken**: `EntitlementService.init()` was calling `_callInit()` (10s server timeout) before `notifyListeners()`. Fix: apply local state immediately, fire-and-forget server call
- **Paywall "Test valid purchase" not transitioning**: `_markEntitlementPaid` now skips server call for paid/restricted states. Purchase handler now accepts `info != null` as valid purchase
- **Version text tap target too small**: Added `HitTestBehavior.opaque` + padding

## Phase 2 — Surface B: Reflection Session

### Files created
- `lib/core/services/prompt_assembler.dart`: Builds Stage 1 (3 lens cards) and Stage 2 (deep read) prompts with context window algorithm (4 branches: daily/regular/occasional/sparse), token truncation, mood/habit summaries, personality injection
- `lib/screens/reflection/reflection_session_screen.dart`: Full-screen with persona avatar/name, 3 lens cards (show instantly), background AI loading (Stage 1), tap-for-deep-read (Stage 2), "Keep this" saves to journal, context window dropdown (Auto/Recent/Month/Longer)

### Bug Fixes (Phase 2)
- **`_parseJson` returned string instead of parsed JSON**: Core parser bug — LLM responses silently failed to parse. Fixed with `jsonDecode()`
- **Prompt in wrong role**: Entire prompt was in `role: user` instead of `role: system`. Fixed by passing as `systemPrompt` parameter
- **Timeout too long**: Set to 30s, added `max_tokens` limits (300 Stage 1, 500 Stage 2)
- **Empty entries wasted API call**: Skip AI call and show empty state immediately if no entries
- **iOS lens migration**: Existing installs auto-migrate from Honest Weather → Zengzi's Three
- **Android stale APK**: Multiple build failures caused old APK deployment — resolved with clean release build + `-r -d -g` flags

## Phase 3 — Surface A: Mood Moment

### Files created
- `lib/screens/reflection/mood_moment_sheet.dart`: Bottom sheet with 3 posture cards (Notice/Soften/Stay), single-turn AI reflection, "Keep this" saves to journal

### Design Change
- Initially auto-triggered after every emotion save. **Redesigned** per user feedback: now triggered manually via the **"Ask AI ✨" button on the emoji jar** widget on My Day tab. Reactive, not proactive.

### Emoji jar modification
- `lib/widgets/emoji_jar.dart`: "Ask AI" button now opens `MoodMomentSheet` (3-posture) instead of old 3-tab generic AI bottom sheet

---

## Files Changed (Complete List)

| File | Change |
|------|--------|
| `lib/core/config/constants.dart` | +`kUseMultiTurnChat` |
| `lib/models/ai_identity.dart` | **New** |
| `lib/models/lens_set.dart` | **New** (default→Zengzi's Three) |
| `lib/models/ai_call_log.dart` | **New** |
| `lib/models/trial_milestone.dart` | **New** |
| `lib/models/models.dart` | +4 exports |
| `lib/core/services/database_service.dart` | v13 migration (5 tables) |
| `lib/core/services/storage_service.dart` | Lens seeding + CRUD + migration |
| `lib/core/services/entitlement_service.dart` | Quota removed, immediate state |
| `lib/core/services/llm_service.dart` | +`maxTokens`, timeout 30s, systemPrompt fix |
| `lib/core/services/prompt_assembler.dart` | **New** — Surface A + B prompts |
| `lib/core/services/trial_service.dart` | **Deleted** |
| `lib/screens/reflection/reflection_session_screen.dart` | **New** — Surface B |
| `lib/screens/reflection/mood_moment_sheet.dart` | **New** — Surface A |
| `lib/screens/settings/settings_screen.dart` | Banners rewritten, BYOK removed |
| `lib/screens/onboarding/onboarding_screen.dart` | Screen 3 rewritten |
| `lib/screens/onboarding/transition_screen.dart` | Quota language removed |
| `lib/screens/purchase/paywall_screen.dart` | Quota/BYOK/top-up removed |
| `lib/widgets/floating_robot.dart` | Menu simplified, routes to new screens |
| `lib/widgets/emoji_jar.dart` | Ask AI → MoodMomentSheet |
| `lib/screens/add_entry_screen.dart` | Mood moment trigger (then removed) |
| `lib/l10n/app_en.arb` | ~20 keys cleaned |
| `lib/l10n/app_zh.arb` | ~20 keys cleaned |
| `lib/core/constants/legal_content.dart` | BYOK language removed |
| `lib/app.dart` | Removed trial_service import |
| `lib/main.dart` | Removed quota refs in restore |
| `test/core/db_version_test.dart` | v12→v13 |
| `test/models/lens_set_test.dart` | **New** |
| `test/models/ai_identity_test.dart` | **New** |
| `test/models/ai_call_log_test.dart` | **New** |
| `test/models/trial_milestone_test.dart` | **New** |

---

## Pending (Next Session)

| Phase | Item | Effort |
|-------|------|--------|
| 4 | Lens configuration UI in Settings ("Your Three") | ~2h |
| 5 | Hide BYOK surfaces completely | ~1h |
| 9 | Tests sweep + lint + IAP verification | ~2h |

---

## Build Commands (Android Release)

```bash
flutter build apk --release \
  --dart-define=RC_API_KEY=goog_ITjNhBQowFMaFwdyZYvaCGqqioi \
  --dart-define=TRIAL_API_KEY=<key> \
  --dart-define=PRO_API_KEY=<key>
```

## Build Commands (Android Debug)

```bash
flutter build apk --debug \
  --dart-define=TRIAL_API_KEY=<key> \
  --dart-define=PRO_API_KEY=<key>
```

## Key Architectural Decisions

1. **AI surfaces use `role: system` for prompts** — prompts assembled on-device, sent as system message with minimal user instruction
2. **Cards render instantly** — lens labels load from local DB immediately, AI observations fill in asynchronously
3. **No numeric quota language anywhere** — product decision: focus on self-discovery journaling, AI is behind-scenes helper
4. **Zengzi's Three as default lens** — Confucian daily self-examination: "Have I been true to others? / Been trustworthy with friends? / Practiced what I learned?"
5. **BYOK hidden but not deleted** — behind `kUseMultiTurnChat` switch
