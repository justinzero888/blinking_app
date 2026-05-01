# PROP-6 Backend — Implementation & E2E Testing Plan

> **Date:** 2026-04-30
> **Status:** Ready to implement
> **Effort:** Backend ~5h | E2E testing ~2h | Total ~7h

---

## 0. Existing Infrastructure (Reuse)

The project already has a Cloudflare Worker (`chorus-api`) deployed at `blinkingchorus.com` with:

| Component | Binding | Purpose |
|-----------|---------|---------|
| `DB` | D1 `blinking-chorus-v0` | SQL database (8 migrations) |
| `KV` | KV namespace | Key-value store |
| `RATE_LIMITER` | Durable Object | Per-session rate limiting |
| `CIRCUIT_BREAKER` | Durable Object | OpenAI/Perspective protection |
| `OPENAI_API_KEY` | Secret | OpenRouter API key for moderation |
| `SHARED_SECRET` | Secret | App-server shared auth |

**Router:** `itty-router` v5 `AutoRouter` in `src/index.ts`
**Pattern:** Each endpoint is a handler function in `src/routes/`, exported from `src/index.ts`
**Errors:** Shared in `src/lib/errors.ts` (`errorResponse`, `unauthorized`, `tooManyRequests`, etc.)
**Tests:** Vitest, 280 tests across 21 files, `src/lib/__tests__/`

---

## 1. Data Model

Use **KV** for trial storage (simpler than D1 for this key-value workload). Two key patterns:

```
# Trial data (device → trial)
trial:d:<device_id>  →  JSON { token, created_at, request_count, last_request_date }

# Reverse lookup (token → device)
trial:t:<token>      →  device_id (string)
```

**Why KV over D1:**
- No complex queries needed — just get/set by device_id or token
- KV is already provisioned and used by the cron audit flag
- D1 would require a migration and table, adding complexity
- KV has eventual consistency which is fine for trial data (no concurrent writes per device)

**Why not KV:** KV is eventually consistent. A write to KV might take ~60s to propagate globally. For trial start, this means a user might start a trial and immediately see a 404 on the first chat request if routed to a different colo. Mitigation: call `startTrial` → get token → send first chat request with token → KV read hits the same colo the token was written to (token is unique). Edge case is acceptable.

---

## 2. Secrets

Add one new secret:

```bash
npx wrangler secret put OPENROUTER_API_KEY
```

This is a dedicated OpenRouter API key for trial users. Separating it from the existing `OPENAI_API_KEY` (used for moderation) allows separate cost tracking and rate limiting at the provider level.

**Update `src/types.ts`** to add the new binding:

```typescript
export interface Env {
  // ... existing bindings ...
  OPENROUTER_API_KEY: string;  // NEW
}
```

**Update `wrangler.toml`** — no changes needed (secrets are managed via `wrangler secret put`).

---

## 3. Kill Switch

Add a feature flag for trial — allows disabling trial starts without redeploying:

```bash
npx wrangler secret put TRIAL_ENABLED
```

Value: `true` or `false`. The `POST /api/trial/start` endpoint checks this before issuing tokens.

---

## 4. Endpoints

### 4.1 `POST /api/trial/start`

**File:** `src/routes/trial.ts` (new)

```typescript
import type { Env } from '../types';
import { errorResponse, tooManyRequests } from '../lib/errors';
import { logger } from '../lib/log';

interface TrialData {
  token: string;
  created_at: string;
  request_count: number;
  last_request_date: string;
}

function generateToken(): string {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  const arr = crypto.getRandomValues(new Uint8Array(32));
  return Array.from(arr, (b) => chars[b % chars.length]).join('');
}

export async function handleTrialStart(request: Request, env: Env): Promise<Response> {
  // Kill switch
  if (env.TRIAL_ENABLED !== 'true') {
    return errorResponse('trial_disabled', 'Trial is currently unavailable.', 503);
  }

  let body: { device_id: string; app_version?: string };
  try {
    body = await request.json();
  } catch {
    return errorResponse('validation_failed', 'Invalid JSON body.', 400);
  }

  if (!body.device_id || typeof body.device_id !== 'string' || body.device_id.length < 8) {
    return errorResponse('validation_failed', 'device_id is required.', 400, 'device_id');
  }

  // Check if this device already used a trial
  const existing = await env.KV.get<TrialData>(`trial:d:${body.device_id}`, { type: 'json' });
  if (existing) {
    return errorResponse('trial_already_used', 'This device has already used its free trial.', 429);
  }

  const token = generateToken();
  const now = new Date().toISOString();
  const trialData: TrialData = {
    token,
    created_at: now,
    request_count: 0,
    last_request_date: now.slice(0, 10),
  };

  // Store trial data + reverse lookup
  await Promise.all([
    env.KV.put(`trial:d:${body.device_id}`, JSON.stringify(trialData)),
    env.KV.put(`trial:t:${token}`, body.device_id),
  ]);

  logger.info('Trial started', { device_id: body.device_id, app_version: body.app_version });

  return Response.json({
    token,
    expires_after_days: 7,
    max_requests_per_day: 20,
    message: 'Your 7-day trial has started!',
  });
}
```

### 4.2 `POST /api/trial/chat`

```typescript
async function handleTrialChat(request: Request, env: Env): Promise<Response> {
  let body: { token: string; model: string; messages: { role: string; content: string }[] };
  try {
    body = await request.json();
  } catch {
    return errorResponse('validation_failed', 'Invalid JSON body.', 400);
  }

  if (!body.token || typeof body.token !== 'string') {
    return errorResponse('validation_failed', 'token is required.', 400, 'token');
  }

  // Look up device by token
  const deviceId = await env.KV.get(`trial:t:${body.token}`);
  if (!deviceId) {
    return errorResponse('invalid_token', 'Invalid trial token.', 403);
  }

  // Load trial data
  const trial = await env.KV.get<TrialData>(`trial:d:${deviceId}`, { type: 'json' });
  if (!trial) {
    return errorResponse('invalid_token', 'Trial data not found.', 403);
  }

  // Check expiry (7 days)
  const created = new Date(trial.created_at);
  const sevenDays = 7 * 24 * 60 * 60 * 1000;
  if (Date.now() - created.getTime() > sevenDays) {
    return Response.json(
      { error: 'trial_expired', message: 'Your 7-day trial has ended. Add your own API key in Settings to continue.' },
      { status: 403 }
    );
  }

  // Check daily limit
  const today = new Date().toISOString().slice(0, 10);
  if (trial.last_request_date !== today) {
    trial.request_count = 0;
    trial.last_request_date = today;
  }

  if (trial.request_count >= 20) {
    return Response.json(
      { error: 'daily_limit_reached', message: "You've reached the daily limit (20 requests). Try again tomorrow." },
      { status: 429 }
    );
  }

  // Increment and save
  trial.request_count++;
  await env.KV.put(`trial:d:${deviceId}`, JSON.stringify(trial));

  // Build system message to limit response length
  const limitedMessages = [
    { role: 'system', content: 'Keep responses brief and helpful. Maximum 200 words per response.' },
    ...body.messages.filter(m => m.role !== 'system'),
  ];

  // Proxy to OpenRouter
  const openRouterResponse = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
      'HTTP-Referer': 'https://blinkingchorus.com',
      'X-Title': 'Blinking Trial',
    },
    body: JSON.stringify({
      model: 'qwen/qwen3.5-flash-02-23',
      messages: limitedMessages,
      max_tokens: 1024,
      temperature: 0.7,
    }),
  });

  // Stream the response back (passthrough)
  return new Response(openRouterResponse.body, {
    status: openRouterResponse.status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
```

**Note on the trial chat endpoint URL:** The Flutter app sends requests to `https://blinkingchorus.com/api/trial/chat` directly (not appending `/chat/completions` — the `LlmService._callChatCompletions` method detects the `/chat` suffix and skips the extra path).

### 4.3 Wire into Router

Update `src/index.ts`:

```typescript
// Add import
import { handleTrialStart, handleTrialChat } from './routes/trial';

// Add routes (before the generic fallbacks)
router.post('/api/trial/start', (req, env) => handleTrialStart(req, env as Env));
router.post('/api/trial/chat',  (req, env) => handleTrialChat(req, env as Env));
```

---

## 5. Rate Limiting

The trial endpoints need rate limiting themselves to prevent abuse:

| Endpoint | Limit | Window | Rationale |
|----------|-------|--------|-----------|
| `/api/trial/start` | 5/hour per IP | hour | Prevent bulk trial creation |
| `/api/trial/chat` | Already enforced per-device (20/day) | day | Inside the handler logic |

For IP-based rate limiting on `/api/trial/start`, create a simple in-memory approach using the existing RateLimiter DO with IP as the key, or use a simple KV-based sliding window. Given the low expected volume during beta, a simple check is sufficient:

```typescript
// In handleTrialStart, before issuing token:
const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
const ipKey = `trial:ip:${ip}:${new Date().toISOString().slice(0, 13)}`; // hourly window
const ipCount = await env.KV.get(ipKey);
if (ipCount && parseInt(ipCount) >= 5) {
  return tooManyRequests();
}
await env.KV.put(ipKey, String((ipCount ? parseInt(ipCount) : 0) + 1), { expirationTtl: 3600 });
```

---

## 6. Cost Estimates

| Parameter | Value |
|-----------|-------|
| Model | `qwen/qwen3.5-flash-02-23` |
| Cost per 1M input tokens | $0.02 |
| Cost per 1M output tokens | $0.02 |
| Avg tokens per request | ~2000 input + ~500 output |
| Max tokens per request | 1024 output (enforced) |
| Cost per request | ~$0.00005 |
| Max cost per trial user (20/day × 7 days) | ~$0.007 |
| Max cost for 100 trial users | ~$0.70 |
| Max cost for 1000 trial users | ~$7.00 |

**Cost is negligible at any reasonable beta scale.** The main cost driver would be abuse at large scale, which is mitigated by:
- One trial per device_id
- 20 requests/day hard cap
- IP rate limiting on trial start
- Kill switch via `TRIAL_ENABLED` secret

---

## 7. Implementation Tasks

### Task B1: Add secret + type (15 min)
1. Add `OPENROUTER_API_KEY` and `TRIAL_ENABLED` to `src/types.ts` `Env` interface
2. Run `npx wrangler secret put OPENROUTER_API_KEY` (paste the key)
3. Run `npx wrangler secret put TRIAL_ENABLED` (set to `true`)

### Task B2: Create trial route handler (1.5h)
1. Create `src/routes/trial.ts`
2. Implement `handleTrialStart()` — device validation, KV read/write, token generation
3. Implement `handleTrialChat()` — token lookup, expiry check, daily limit check, OpenRouter proxy
4. Add `generateToken()` helper using `crypto.getRandomValues()`

### Task B3: Register routes in index.ts (5 min)
1. Import trial handlers in `src/index.ts`
2. Add `router.post('/api/trial/start', ...)` and `router.post('/api/trial/chat', ...)`

### Task B4: Unit tests (1.5h)
Create `src/routes/__tests__/trial.test.ts` with:

| Test | Description |
|------|-------------|
| `POST /trial/start` — success | New device, returns token + 200 |
| `POST /trial/start` — duplicate | Same device twice → 429 `trial_already_used` |
| `POST /trial/start` — missing device_id | → 400 |
| `POST /trial/start` — kill switch off | TRIAL_ENABLED ≠ 'true' → 503 |
| `POST /trial/chat` — success | Valid token, under limit → 200 (mocked OpenRouter) |
| `POST /trial/chat` — expired | Token from >7 days ago → 403 `trial_expired` |
| `POST /trial/chat` — daily limit | 20 requests already used today → 429 `daily_limit_reached` |
| `POST /trial/chat` — invalid token | Non-existent token → 403 `invalid_token` |
| `POST /trial/chat` — missing token | → 400 |
| Daily limit reset | After midnight UTC, count resets |
| IP rate limiting | 6 starts from same IP in 1 hour → 429 |
| Token generation | Returns 32-char alphanumeric string |

### Task B5: Deploy & smoke test (30 min)
1. `npm run type-check` — ensure no TS errors
2. `npm run test` — all tests pass
3. `npm run deploy` — deploy to Cloudflare Workers
4. Curl smoke tests against production:

```bash
# Start trial
curl -X POST https://blinkingchorus.com/api/trial/start \
  -H 'Content-Type: application/json' \
  -d '{"device_id":"test-'$(uuidgen)'"}'

# Chat (use returned token)
curl -X POST https://blinkingchorus.com/api/trial/chat \
  -H 'Content-Type: application/json' \
  -d '{"token":"<token>","messages":[{"role":"user","content":"Hi"}]}'

# Expired trial (use expired token)
curl -X POST https://blinkingchorus.com/api/trial/chat \
  -H 'Content-Type: application/json' \
  -d '{"token":"<expired_token>","messages":[{"role":"user","content":"Hi"}]}'
```

---

## 8. End-to-End Testing Plan

### 8.1 Pre-Flight Checklist

- [ ] Cloudflare Worker deployed (`chorus-api` updated with trial routes)
- [ ] `OPENROUTER_API_KEY` secret set in production
- [ ] `TRIAL_ENABLED` secret set to `true` in production
- [ ] App-side built with `flutter build apk --debug`
- [ ] Emulator running (`Medium_Phone_API_36.1`)

### 8.2 E2E Test Scenarios

#### E2E-1: Full trial lifecycle (Happy Path)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Fresh install on emulator | Calendar loads, robot grey with `!` badge |
| 2 | Settings → AI Provider | Purple gradient banner "Start Free Trial →" |
| 3 | Tap "Start Free Trial →" | Spinner → success snackbar → green banner "Trial Active" |
| 4 | Check provider list | "7-Day Trial" with green "Trial" chip at top |
| 5 | Back to Calendar | Robot now animated (full color, bobbing) |
| 6 | Tap robot → opens AssistantScreen | Chat opens, empty state visible |
| 7 | Type "Hello, how are you?" → send | AI responds (real OpenRouter response via trial backend) |
| 8 | Send 3 more messages | All succeed, no rate limit errors |

#### E2E-2: Trial expiry (Manual clock advance)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Set emulator clock +8 days | `adb shell "su 0 date $(date -v+8d +%m%d%H%M%Y.%S)"` |
| 2 | Force-stop + re-open app | Calendar loads |
| 3 | Robot shows grey with 🕐 badge | Clock badge, not `!` |
| 4 | Tap robot | Snackbar: "Your trial has ended..." |
| 5 | Settings → AI Provider | Orange banner "Trial Expired" with "Get a free key →" |
| 6 | AI Provider list | Trial provider NOT visible anymore |
| 7 | Add real API key (OpenRouter) | Provider appears as selectable with "Active" chip |
| 8 | Robot returns to animated state | Robot active with user's key |
| 9 | Send message in assistant | Works using user's own key |

#### E2E-3: Daily rate limit

| Step | Action | Expected |
|------|--------|----------|
| 1 | Start trial (fresh) | Trial active |
| 2 | Send 20+ messages rapidly in assistant | 21st request shows error message about daily limit |
| 3 | Wait or advance clock to next day | Rate limit resets, requests work again |

#### E2E-4: Reinstall resilience

| Step | Action | Expected |
|------|--------|----------|
| 1 | Trial active on device | Working |
| 2 | Clear app data (Android Settings → Apps → Blinking → Clear Data) | All data wiped |
| 3 | Reopen app | Fresh start, new device_id generated |
| 4 | Settings → AI Provider | "Start Free Trial →" button visible |
| 5 | Tap start | Server returns 200 (new device_id, one trial per device enforced server-side) |

#### E2E-5: Trial + own key coexistence

| Step | Action | Expected |
|------|--------|----------|
| 1 | Trial active | Robot animated, trial provider in list |
| 2 | Add OpenRouter API key to Open Router provider | Key appears, user can select it |
| 3 | Select Open Router provider | Assistant uses user's key, not trial |
| 4 | Robot remains animated | No change |
| 5 | Remove user's API key | Falls back to trial automatically |

#### E2E-6: Export/Import doesn't affect trial

| Step | Action | Expected |
|------|--------|----------|
| 1 | Trial active, some entries exist | Trial works |
| 2 | Export full backup (ZIP) | Backup created and shared |
| 3 | Verify ZIP contents | No trial_token or trial_started_at in data.json |
| 4 | Clear app data, reinstall, restore from backup | Entries restored |
| 5 | Check trial state | Trial data unchanged (or fresh if reinstall) |

---

## 9. Files Changed (Backend)

| File | Change | Effort |
|------|--------|:------:|
| `src/types.ts` | Add `OPENROUTER_API_KEY`, `TRIAL_ENABLED` to Env | 5 min |
| `src/routes/trial.ts` | **New** — `handleTrialStart()`, `handleTrialChat()` | 1.5h |
| `src/index.ts` | Import + register 2 trial routes | 5 min |
| `src/routes/__tests__/trial.test.ts` | **New** — ~12 unit tests | 1.5h |
| **Total backend** | | **~3.5h** |

---

## 10. Files Changed (App-Side for E2E)

| File | Change | Effort |
|------|--------|:------:|
| `lib/core/services/trial_service.dart` | Remove demo fallback, restore real `startTrial()` | 15 min |
| `lib/screens/settings/settings_screen.dart` | Remove demo-only logic in `_startTrial()` | 10 min |
| **Total app cleanup** | | **~25 min** |

After backend is deployed and tested, the app should be updated to:
1. Revert the 3-second timeout to 10 seconds (or try real backend first, fallback to demo only if network error)
2. Keep demo mode available as fallback for when backend is unreachable

---

## 11. Rollout Sequence

```
Phase 1 (now):       Implement backend routes + unit tests (~3.5h)
Phase 2 (now):       Deploy to Cloudflare Workers, set secrets (~30 min)
Phase 3 (now):       Curl smoke tests against production (~15 min)
Phase 4 (now):       E2E tests with Flutter app on emulator (~1h)
Phase 5 (post-go):   Remove demo mode from app, keep fallback for network errors (~25 min)
Phase 6 (post-go):   Monitor OpenRouter costs for 2 weeks
Phase 7 (post-go):   Ship as part of v1.1.0-beta.5 release
```

---

## 12. Monitoring & Alerts

| Metric | Source | Alert threshold |
|--------|--------|----------------|
| Trial starts/day | Worker logs | > 1000/day |
| Trial chat requests/day | Worker logs | > 5000/day |
| OpenRouter cost/day | OpenRouter dashboard | > $1/day |
| Error rate (4xx/5xx) | Worker analytics | > 5% |
| KV read/write count | Cloudflare dashboard | Monitor quotas |
| Worker CPU time | Cloudflare dashboard | Within free tier |

**Kill switch procedure:**
```bash
cd chorus/chorus-api
printf "false" | npx wrangler secret put TRIAL_ENABLED
```
This immediately stops new trial starts without redeploying. Existing trials continue until expiry.
