# Session Summary — 2026-05-09

**App:** Blinking (记忆闪烁) v1.1.0+30  
**Tests:** 147/147 passing  
**Lint:** 0 errors  
**Scope:** Production release — cleanup, version bump, server config, iOS submission prep

---

## Phase 5 — Hide BYOK Surfaces
- Disabled `hasActiveBYOK` path in `canUseAI`, `buttonVisual`, and `_loadConfig()`
- Robot always dormant in restricted state (no BYOK bypass)
- LlmService never loads user BYOK keys — trial/pro built-in keys only

## Phase 9 — Final Regression
- 147/147 tests pass, 0 lint errors
- Auto-restore debug code removed from main.dart
- Test store key fallback restricted to debug mode only (`kDebugMode`)

## Settings Tab Reorganization
- 3-tab layout: **AI Personalization** | **Tags** | **General**
- Entitlement banner stays visible above tabs
- Language, backup, export/import, about moved to General tab

## Insights AI Branding
- "🤖 AI Insights" → "💡 Insights"
- "AI-generated" → "Based on your data"
- Content is rule-based — labels now reflect that

## Server Config — Cloudflare Worker
- New endpoint: `https://blinkingchorus.com/api/config`
- Returns AI keys + models for trial and pro users
- Supports multi-key failover (array format)
- Keys stored as Cloudflare Secrets (`BLINKING_TRIAL_KEYS`, `BLINKING_PRO_KEYS`)
- Client fetches on cold start, caches 24h, falls back to dart-define

### Multi-Key Failover
- Keys tried in array order; on 401/429/5xx/timeout → next key
- Network errors stop the chain (no retry)
- All keys exhausted → last error shown

## Production Release — v1.1.0+30
- Version: `1.1.0-beta.8+28` → `1.1.0+29` → `1.1.0+30`
- Dropped beta tag — first stable release
- Production artifacts built with platform RC keys:
  - Android AAB (52MB) — uploaded to Google Play
  - Android APK (64MB)
  - iOS IPA (32MB) — ready for App Store submission

### Bug: Model name `qwen/qwen3.5-flash` → `qwen/qwen3.5-flash-02-23`
- Model name changed during refactor → OpenRouter rejected it with unhandled status
- Fixed in app code + server config + rebuilt all artifacts (v30)

---

## Files Changed

| File | Change |
|------|--------|
| `lib/main.dart` | Removed AUTO_RESTORE, test store fallback debug-gated |
| `lib/core/services/llm_service.dart` | Multi-key failover, server config priority, model fix |
| `lib/core/services/config_service.dart` | **New** — server config fetch + cache |
| `lib/core/services/entitlement_service.dart` | BYOK paths disabled in canUseAI/buttonVisual |
| `lib/screens/settings/settings_screen.dart` | 3-tab layout (AI/Tags/General) |
| `lib/screens/cherished/cherished_memory_screen.dart` | AI branding removed |
| `lib/core/config/constants.dart` | Version → 1.1.0 |
| `pubspec.yaml` | Version → 1.1.0+30 |
| `chorus/chorus-api/src/routes/ai-config.ts` | **New** — server config endpoint |
| `chorus/chorus-api/src/index.ts` | +`/api/config` route |
| `chorus/chorus-api/wrangler.toml` | +`/api/config` route |
| `chorus/chorus-api/src/types.ts` | +`BLINKING_TRIAL_KEYS`, `BLINKING_PRO_KEYS` |
| `docs/server-config-guide.md` | **New** — config deployment guide |
| `docs/session-notes/session-summary-2026-05-09.md` | **New** — this file |
| `CLAUDE.md` | Updated version, DB v13, test count, feature status |

---

## Pending

| Item | Status |
|------|--------|
| Google Play — upload v30 AAB for closed beta | AAB ready |
| iOS — upload IPA, submit for App Store review | IPA ready, API key needed |
| Server config — test 24h cache refresh | Endpoint live |

## Key Decisions

1. **No numeric quota language** — product decision: focus on self-discovery, AI is behind-scenes
2. **BYOK hidden, not deleted** — behind `kUseMultiTurnChat` switch
3. **Reactive AI (not proactive)** — user consciously triggers AI, no interruptions
4. **3-per-day limits** — both Daily Reflection (saves) and Mood Moment (postures)
5. **Server-configurable keys** — update AI keys/models anytime without app deploy
6. **Multi-key failover** — graceful degradation across multiple OpenRouter accounts
