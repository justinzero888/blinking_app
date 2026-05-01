# Session Summary — 2026-04-30

## Goal
Implement PROP-6: 7-day free trial API key flow (full stack: app + backend)

## Outcome
**COMPLETE.** Trial feature is fully implemented, tested, and deployed. Backend is live at `blinkingchorus.com`. App built as v1.1.0-beta.5+20 (APK + AAB).

---

## Implementation Summary

### Phase 1: App-Side (~6h)
| Step | What | Status |
|------|------|--------|
| Task 0 | `DeviceService` — anonymous install UUID generation | ✅ |
| Task 1 | `TrialService` — trial lifecycle, demo mode for dev | ✅ |
| Task 2 | `SettingsScreen` — trial banner (start/active/expired), provider entry, start flow, info dialog | ✅ |
| Task 3 | `LlmService` — `trialExpired` error type, trial config fallback, trial endpoint URL handling | ✅ |
| Task 4 | `FloatingRobotWidget` — trial active (animated) + expired (grey + clock badge) states | ✅ |
| Task 5 | `AssistantScreen` — persistent expiry banner with dismiss + navigation | ✅ |
| Task 6 | Export/import verification — trial data excluded from backup/restore | ✅ |
| i18n | 13 new EN/ZH strings in ARB files | ✅ |

### Phase 2: Backend (~3h)
| Step | What | Status |
|------|------|--------|
| B1 | `types.ts` — added `OPENROUTER_API_KEY`, `TRIAL_ENABLED` to Env | ✅ |
| B2 | `routes/trial.ts` — `handleTrialStart()` + `handleTrialChat()` (204 lines) | ✅ |
| B3 | `index.ts` — registered 2 trial routes | ✅ |
| B4 | `trial.test.ts` — 12 unit tests (Vitest) | ✅ |
| B5 | Deploy + secrets + curl smoke tests | ✅ |

### Phase 3: Debugging & E2E (~2h)
| Issue | Root Cause | Fix |
|-------|-----------|-----|
| "Start Free Trial" failed | Backend not deployed yet | Added demo mode fallback |
| Chat endpoint returned 502 | `OPENROUTER_API_KEY` not set in production | Set via `wrangler secret put` |
| OpenRouter returned 401 | OpenAI key (`sk-proj-`) not accepted by OpenRouter | User provided OpenRouter key (`sk-or-v1-`) |
| "An unexpected error occurred" in assistant | Backend expected `token` in JSON body, app sent it in `Authorization` header | Changed backend to read token from `Authorization: Bearer` header |
| Vitest fetch mocking failed | Workers pool doesn't support `global.fetch` mocking | Restructured tests to validate without OpenRouter calls |

---

## Files Created

### App
- `lib/core/services/device_service.dart`
- `lib/core/services/trial_service.dart`

### Backend
- `src/routes/trial.ts`
- `src/routes/__tests__/trial.test.ts`

### Docs
- `docs/plans/2026-04-30-prop-6-trial-api-key-plan.md`
- `docs/plans/2026-04-30-prop-6-backend-plan.md`
- `docs/plans/2026-04-30-trial-api-key-uat.md`
- `docs/release-notes/v1.1.0-beta.5.md`

---

## Files Modified

### App
- `lib/core/services/llm_service.dart` — trialExpired error + trial fallback
- `lib/screens/settings/settings_screen.dart` — trial banner + provider + start flow
- `lib/widgets/floating_robot.dart` — trial states
- `lib/screens/assistant/assistant_screen.dart` — expiry banner
- `lib/main.dart` — device ID init
- `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb` — 13 new strings
- `lib/core/config/constants.dart` — version bump
- `pubspec.yaml` — version bump
- `docs/plans/PROJECT-STATUS-2026-04-29.md` — status update
- `CLAUDE.md` — version + feature docs

### Backend
- `src/types.ts` — new env bindings
- `src/index.ts` — trial routes
- `src/lib/__tests__/city.test.ts` — env mock update
- `wrangler.toml` — route patterns
- `.dev.vars` — local dev secrets

---

## Test Results

| Suite | Tests | Status |
|-------|-------|--------|
| Flutter | 94 | All passing |
| Backend (Vitest) | 343 | All passing |
| Flutter analyze | 0 errors | ✅ |
| E2E smoke (curl) | Trial start + chat | ✅ |
| E2E (emulator) | Full lifecycle | ✅ |

---

## Version

**v1.1.0-beta.5+20** (from `v1.1.0-beta.4+19`)

Build artifacts:
- `build/app/outputs/flutter-apk/app-release.apk` (70.5MB)
- `build/app/outputs/bundle/release/app-release.aab` (54.7MB)

---

## Deployed Backend

- Worker: `chorus-api` on Cloudflare Workers
- Routes: `blinkingchorus.com/api/trial/*`, `blinkingchorus.com/api/v1/*`
- Storage: KV (trial state)
- Proxy: OpenRouter → `qwen/qwen3.5-flash`
- Kill switch: `TRIAL_ENABLED` secret (current: `true`)

---

## Next Steps

1. Commit and push code
2. Upload AAB to Google Play Console (internal/beta track)
3. Monitor trial usage and OpenRouter costs
4. PROP-9: Daily checklist entries (when ready)
