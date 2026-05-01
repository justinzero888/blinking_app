# PROP-6: Trial API Key Flow (7-Day Free Trial) — Implementation Plan

> **Priority:** P2 (growth / onboarding — removes biggest barrier to AI feature discovery)
> **Effort:** ~10–12 hours app-side + ~8–10 hours backend (total ~18–22h)
> **Type:** Growth / onboarding feature with backend dependency
> **Design Review:** 2026-04-30 — original high-level description evaluated, gaps filled, full design below

**Goal:** Offer new users a zero-configuration "Try for free — 7 days" option so they can experience the AI assistant immediately without setting up their own third-party API key. The trial is a time-limited, rate-limited proxy to an AI provider, managed by our backend.

**Backend Dependency:** Requires a new backend service to issue trial tokens and proxy/rate-limit AI requests. This plan includes a complete backend design (Section A) so the app-side and backend-side can be built in parallel or sequentially.

---

## A. Backend Design (NEW — not in original spec)

### A.1 Infrastructure

**Hosting:** Co-deploy with the existing Chorus backend on Cloudflare Workers (`blinkingchorus.com`). The app already calls `https://blinkingchorus.com/api/notes` for Chorus posting. The trial endpoints live alongside:

```
https://blinkingchorus.com/api/trial/start    ← POST: issues trial token
https://blinkingchorus.com/api/trial/chat     ← POST: proxies AI request
```

**Storage:** Cloudflare D1 or KV (already available in the Chorus infra). Stores:
- `trial_tokens` table: `device_id TEXT PRIMARY KEY`, `token TEXT`, `created_at TEXT`, `request_count INTEGER DEFAULT 0`, `last_request_date TEXT`

### A.2 Endpoints

#### `POST /api/trial/start`

**Request:**
```json
{
  "device_id": "uuid-from-client",
  "app_version": "1.1.0-beta.4"
}
```

**Response (200):**
```json
{
  "token": "tr_xxxxxxxxxxxxxx",
  "expires_after_days": 7,
  "max_requests_per_day": 20,
  "message": "Your 7-day trial has started!"
}
```

**Error (429 — already used trial):**
```json
{
  "error": "trial_already_used",
  "message": "This device has already used its free trial."
}
```

**Logic:**
1. Check if `device_id` already has a trial token (one trial per device).
2. If yes and trial is active or expired → return 429.
3. If no → generate a random 32-char token, store in D1/KV, return it.
4. Token is valid for 7 days from `created_at`.

#### `POST /api/trial/chat`

**Request:**
```json
{
  "token": "tr_xxxxxxxxxxxxxx",
  "model": "qwen/qwen3.5-flash-02-23",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ]
}
```

**Response (200):** Standard OpenAI-compatible chat completions response (streamed or single).

**Error (403 — expired):**
```json
{
  "error": "trial_expired",
  "message": "Your 7-day trial has ended. Add your own API key in Settings to continue."
}
```

**Error (429 — daily limit):**
```json
{
  "error": "daily_limit_reached",
  "message": "You've reached the daily limit (20 requests). Try again tomorrow."
}
```

**Logic:**
1. Look up `token` in D1/KV.
2. Check `created_at + 7 days` — if expired → 403.
3. Check `request_count` for today (reset midnight UTC or per `last_request_date`).
4. If today's count ≥ 20 → 429.
5. Increment `request_count`, update `last_request_date`.
6. Proxy the request to OpenRouter (using our server-side API key, model fixed to qwen3.5-flash for cost control).
7. Return the AI response.

### A.3 Rate Limiting & Cost Control

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Trial duration | 7 days from first request | Standard free trial length |
| Max requests/day | 20 | ~3 conversations/day; generous enough to evaluate |
| Max tokens/request (input+output) | ~4000 | Keeps per-request cost low |
| Model | `qwen/qwen3.5-flash-02-23` | OpenRouter's cheapest capable model (~$0.02/1M tokens) |
| One trial per device | Enforced by device_id | Prevents abuse |
| Max concurrent trials | Budget-capped | Monitor; add waitlist if needed |

**Estimated cost per trial user:** ~$0.10–$0.20 total over 7 days (assuming 10 requests/day × 2000 tokens avg).

### A.4 Security

- **Trial token:** Opaque 32-char random string (from `crypto.randomUUID()` or equivalent). Not a JWT — no need for client-side decoding.
- **Device ID:** The app generates a random UUID on first launch, stores in SharedPreferences. Used only as a lookup key — not personally identifiable.
- **OpenRouter API key:** Stored as a Cloudflare Workers secret (`wrangler secret put OPENROUTER_API_KEY`), same pattern as the existing `SHARED_SECRET` in ChorusService.
- **Rate limiting:** Server-enforced, not client-trusting. The client could try to forge dates; the server is the authority.

### A.5 Cloudflare Worker Pseudocode

```js
// /api/trial/start
export async function startTrial(request, env) {
  const { device_id, app_version } = await request.json();
  const existing = await env.TRIAL_DB.get(`trial:${device_id}`);
  if (existing) {
    return json({ error: 'trial_already_used', message: '...' }, 429);
  }
  const token = crypto.randomUUID().replace(/-/g, '');
  const now = new Date().toISOString();
  await env.TRIAL_DB.put(`trial:${device_id}`, JSON.stringify({
    token, created_at: now, request_count: 0, last_request_date: now.split('T')[0]
  }));
  await env.TRIAL_DB.put(`token:${token}`, device_id); // reverse lookup
  return json({ token, expires_after_days: 7, max_requests_per_day: 20 });
}

// /api/trial/chat
export async function trialChat(request, env) {
  const { token, messages } = await request.json();
  const deviceId = await env.TRIAL_DB.get(`token:${token}`);
  if (!deviceId) return json({ error: 'invalid_token' }, 403);
  const trial = JSON.parse(await env.TRIAL_DB.get(`trial:${deviceId}`));
  const created = new Date(trial.created_at);
  if (Date.now() - created > 7 * 86400000) {
    return json({ error: 'trial_expired', message: '...' }, 403);
  }
  const today = new Date().toISOString().split('T')[0];
  if (trial.last_request_date !== today) {
    trial.request_count = 0;
    trial.last_request_date = today;
  }
  if (trial.request_count >= 20) {
    return json({ error: 'daily_limit_reached', message: '...' }, 429);
  }
  trial.request_count++;
  await env.TRIAL_DB.put(`trial:${deviceId}`, JSON.stringify(trial));
  // Proxy to OpenRouter
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${env.OPENROUTER_API_KEY}`,
    },
    body: JSON.stringify({
      model: 'qwen/qwen3.5-flash-02-23',
      messages,
      max_tokens: 1024,
      temperature: 0.7,
    }),
  });
  return response;
}
```

**Estimated backend effort:** 8–10 hours (Worker code ~200 lines, D1/KV setup, wrangler config, deployment, testing, monitoring).

---

## B. App-Side Design Revisions

### B.1 Evaluation of Original High-Level Spec

The original description (PROJECT-STATUS-2026-04-29.md lines 208–227) is a good vision statement but missing critical details.

| # | Gap | Severity | Resolution |
|---|-----|----------|------------|
| R1 | No backend design at all | Critical | Full backend spec in Section A above |
| R2 | No trial token lifecycle management | Critical | New `TrialService` class handles start/check/expire |
| R3 | No spec for trial-to-own-key transition | High | User can add own key anytime; trial provider remains in list as "Expired" reference |
| R4 | No spec for what happens at expiry (UX) | High | AssistantScreen shows persistent banner; FloatingRobot returns to "no key" state; trial provider marked "Expired" in settings |
| R5 | "3-4h app-side" estimate is far too low | High | Revised to 10–12h (new service, settings UI, robot changes, assistant changes, error handling, testing) |
| R6 | Trial provider integration with existing provider architecture unclear | Medium | Trial is a special provider entry in the existing `llm_providers` JSON list — no schema changes needed |
| R7 | "Instead of (or alongside) the link" placement ambiguous | Medium | Trial button goes in Settings → AI Provider section as a prominent banner/button ABOVE the provider list (not inside the edit dialog) |
| R8 | Reinstall / data-clear bypass | Medium | Trial eligibility is server-enforced by device_id; local SharedPreferences wipe doesn't grant a new trial (but also means a genuine new device + data restore won't get a new trial — acceptable) |
| R9 | No i18n strings specified | Low | All trial-related strings added to EN/ZH ARB files |
| R10 | No analytics/monitoring for trial conversion | Low | Backend logs trial starts/completions; future iteration could add conversion tracking |
| R11 | OpenRouter's own free credits may obviate need | Medium | Addressed in Section C (Risk Analysis) below |

### B.2 Revised App-Side Architecture

```
                        ┌──────────────────────────┐
                        │      SettingsScreen       │
                        │  (Trial button + banner   │
                        │   + trial provider entry) │
                        └──────────┬───────────────┘
                                   │
                        ┌──────────▼───────────────┐
                        │      TrialService        │  NEW
                        │  startTrial()            │
                        │  getStatus()             │
                        │  trialDaysLeft           │
                        │  isTrialActive            │
                        │  isTrialExpired           │
                        └──────────┬───────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              │                    │                    │
   ┌──────────▼──────┐  ┌─────────▼────────┐  ┌────────▼──────────┐
   │  LlmService     │  │ FloatingRobot    │  │ AssistantScreen   │
   │  (reads trial   │  │ (trial states:   │  │ (expiry banner +  │
   │   provider via  │  │  active/expired/  │  │  error handling)  │
   │   existing      │  │  no-key)          │  │                   │
   │   config path)  │  │                  │  │                   │
   └─────────────────┘  └──────────────────┘  └───────────────────┘
```

---

## C. Risk Analysis

### C.1 OpenRouter Free Credits Overlap

OpenRouter already provides $1 in free credits to new users (enough for ~hundreds of requests). Why build our own trial?

**Counterargument:** The friction is not cost — it's the **setup flow**: visiting openrouter.ai, creating an account, generating a key, copying it to the app. Our trial eliminates all of that. The user taps one button and is chatting with AI in seconds.

**Mitigation:** The trial UX should also link to "Get your own free key →" as a fallback, so users aware of OpenRouter's credits can use them too. The trial and the link coexist.

### C.2 Cost Overrun Risk

If trial adoption is higher than expected, proxy costs could be significant.

**Mitigation:**
1. Daily request cap (20) + token cap per request limits per-user cost to ~$0.02/day.
2. Budget alert: Cloudflare Workers analytics can monitor total requests.
3. Kill switch: a Cloudflare Workers secret (`TRIAL_ENABLED=true`) allows disabling new trial starts without redeploying.
4. Waitlist mode: if trial demand exceeds budget, return 503 with "try again soon" message.

### C.3 Abuse Risk

Someone could script trial starts from many fake device_ids.

**Mitigation:**
1. Rate limit `/api/trial/start` by IP (5/hour).
2. Future: CAPTCHA or device attestation.
3. Token response includes rate limits, so abusers get throttled quickly.

### C.4 Trial vs. Local Date Manipulation

A user could change their device clock to bypass the 7-day expiry.

**Fact:** The expiry check is **server-side** (Section A.2 `/api/trial/chat`). The server's clock is authoritative. The client-side countdown display might show the wrong days remaining, but the actual chat requests will still fail after 7 real-world days.

---

## D. App-Side Implementation Tasks

### Task 0: Device ID Infrastructure

**Files:**
- New: `lib/core/services/device_service.dart`
- Modify: `lib/main.dart` (or `StorageService.init()`)

**Why:** The trial backend needs a stable, anonymous device identifier to enforce one-trial-per-device.

```dart
class DeviceService {
  static const _key = 'device_id';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    return id;
  }
}
```

- Generated once, persisted forever, survives app updates.
- Not tied to any personal data. Not sent anywhere except to our trial backend.
- Survives data export/import (not stored in backup ZIP — in SharedPreferences which is separate).

**Step 1: Create `DeviceService` class**
**Step 2: Call `DeviceService.getDeviceId()` on first `StorageService.init()` to ensure it exists**
**Step 3: Write test**

**Commit:** `feat: add DeviceService for anonymous install identification`

---

### Task 1: TrialService

**Files:**
- New: `lib/core/services/trial_service.dart`
- New: `test/core/trial_service_test.dart`

**Design:**

```dart
enum TrialStatus { none, active, expired }

class TrialService {
  static const _trialBaseUrl = 'https://blinkingchorus.com/api/trial';
  static const _prefsKeyPrefix = 'trial_';
  static const _trialDurationDays = 7;

  final SharedPreferences _prefs;

  TrialService(this._prefs);

  /// Attempt to start a trial. Returns the trial token on success.
  /// Throws [TrialException] on failure (already used, network error, etc).
  Future<String> startTrial() async {
    final deviceId = await DeviceService.getDeviceId();
    final response = await http.post(
      Uri.parse('$_trialBaseUrl/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      await _saveTrialData(token, DateTime.now());
      return token;
    } else if (response.statusCode == 429) {
      throw TrialException('trial_already_used', 'Trial already used on this device.');
    } else {
      throw TrialException('start_failed', 'Failed to start trial (HTTP ${response.statusCode}).');
    }
  }

  /// Returns current trial status.
  TrialStatus getStatus() {
    final token = _prefs.getString('${_prefsKeyPrefix}token');
    if (token == null || token.isEmpty) return TrialStatus.none;
    final startedAtStr = _prefs.getString('${_prefsKeyPrefix}started_at');
    if (startedAtStr == null) return TrialStatus.none;
    final startedAt = DateTime.parse(startedAtStr);
    final expiryDate = startedAt.add(const Duration(days: _trialDurationDays));
    if (DateTime.now().isAfter(expiryDate)) return TrialStatus.expired;
    return TrialStatus.active;
  }

  /// Days remaining in trial, or 0 if expired/none.
  int get trialDaysLeft {
    final startedAtStr = _prefs.getString('${_prefsKeyPrefix}started_at');
    if (startedAtStr == null) return 0;
    final startedAt = DateTime.parse(startedAtStr);
    final expiryDate = startedAt.add(const Duration(days: _trialDurationDays));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// The trial token, for building the provider entry.
  String? get trialToken => _prefs.getString('${_prefsKeyPrefix}token');

  /// Build a provider map entry for the trial.
  Map<String, String> buildTrialProvider() {
    return {
      'name': 'Trial',
      'model': 'qwen/qwen3.5-flash-02-23',
      'apiKey': trialToken ?? '',
      'baseUrl': '$_trialBaseUrl/chat',
    };
  }

  /// Clear trial data (for testing / reset during development).
  Future<void> clearTrial() async {
    await _prefs.remove('${_prefsKeyPrefix}token');
    await _prefs.remove('${_prefsKeyPrefix}started_at');
  }

  Future<void> _saveTrialData(String token, DateTime startedAt) async {
    await _prefs.setString('${_prefsKeyPrefix}token', token);
    await _prefs.setString('${_prefsKeyPrefix}started_at', startedAt.toIso8601String());
  }
}

class TrialException implements Exception {
  final String code;
  final String message;
  TrialException(this.code, this.message);
}
```

**Key design decisions:**
- Trial data stored in SharedPreferences, not SQLite — keeps it separate from the entry/routine data that gets exported/imported.
- `buildTrialProvider()` returns a standard provider map — seamlessly integrates with existing `_llmProviders` list in SettingsScreen.
- The server's clock is authoritative for actual enforcement; the local `trialDaysLeft` is for display only.

**Step 1: Create `TrialService` class**
**Step 2: Write unit tests:**
- `startTrial()` succeeds with valid response (mock HTTP)
- `startTrial()` throws on 429 (already used)
- `getStatus()` returns correct enum for none/active/expired
- `trialDaysLeft` computes correctly at t=0, t=3, t=8
- `buildTrialProvider()` produces correct map
- `clearTrial()` resets state

**Commit:** `feat: add TrialService for trial token lifecycle management`

---

### Task 2: SettingsScreen — Trial UI

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `app_zh.arb`

**Changes:**

#### 2a. Add trial banner above provider list

In the AI Provider section, before the provider `ListTile`s, add:

```
┌──────────────────────────────────────────┐
│  🎉  Try AI for Free — 7 Days           │
│  No setup needed. Start chatting now.   │
│  [Start Free Trial →]                   │
└──────────────────────────────────────────┘
```

When trial is active:
```
┌──────────────────────────────────────────┐
│  ✅  Trial Active — 5 days remaining    │
│  20 requests/day · You can add your     │
│  own key anytime in the provider list.  │
└──────────────────────────────────────────┘
```

When trial is expired:
```
┌──────────────────────────────────────────┐
│  ⏰  Trial Expired                       │
│  Add your own API key below to continue │
│  using the AI assistant.                │
│  [Get a free key →] (links to OpenRouter)│
└──────────────────────────────────────────┘
```

#### 2b. Integrate trial provider in the list

When trial is active, a "Trial" provider entry appears at the top of the provider list:
- Display name: "7-Day Trial" / "7天试用"
- Subtitle: "X days remaining · 20 requests/day"
- Badge: green "Trial" chip instead of the blue "Active" chip
- Radio-selectable (user can switch between trial and their own keys)
- Edit button → shows trial info (read-only model, cannot edit token)
- Cannot be deleted while active
- Marked as "Expired" when time runs out

#### 2c. "Get a free API key →" link

The existing OpenRouter link in the edit dialog stays. Additionally, add a similar link in the expired trial banner.

#### 2d. Implementation approach

The settings screen needs a `TrialService` instance. Since `TrialService` requires `SharedPreferences`, inject it via the existing lazy pattern:

```dart
// In _SettingsScreenState:
late final TrialService _trialService;

@override
void initState() {
  super.initState();
  SharedPreferences.getInstance().then((prefs) {
    _trialService = TrialService(prefs);
    if (mounted) setState(() {}); // re-render with trial state
  });
  _loadLlmSettings();
  _loadAiSettings();
}
```

The `_buildTrialBanner` method reads `_trialService` to render the appropriate state.

The trial provider is NOT saved as a permanent entry in `_llmProviders` (otherwise it would persist after expiry and would be exported/imported). Instead, it's injected into the displayed list at render time:

```dart
List<Map<String, String>> get _displayProviders {
  if (_trialService.getStatus() == TrialStatus.active) {
    return [_trialService.buildTrialProvider(), ..._llmProviders];
  }
  return _llmProviders;
}
```

**Step 1: Add i18n strings (EN + ZH ARB files)**
**Step 2: Build `_buildTrialBanner()` widget**
**Step 3: Wire `_trialService` to `_displayProviders`**
**Step 4: Handle "Start Trial" button → calls `_trialService.startTrial()` → shows loading → updates state**
**Step 5: Handle trial provider tap (select it) and edit (read-only info dialog)**
**Step 6: Write UI tests for trial banner states**

**Commit:** `feat: add trial banner, trial provider entry, and start flow to Settings`

---

### Task 3: LlmService — Trial Error Handling

**Files:**
- Modify: `lib/core/services/llm_service.dart`

**Changes:**

The trial backend returns specific error types. `LlmService` needs to detect and surface these.

#### 3a. Add `LlmErrorType.trialExpired`

```dart
enum LlmErrorType {
  noApiKey,
  invalidApiKey,
  rateLimited,
  serverError,
  networkError,
  timeout,
  emptyResponse,
  trialExpired,   // NEW
  unknown,
}
```

#### 3b. Detect trial errors in HTTP 403 responses

In the `_callChatCompletions` error handler:

```dart
if (status == 401 || status == 403) {
  // Check if this is a trial expiry
  try {
    final err = jsonDecode(response.body);
    if (err['error'] == 'trial_expired') {
      throw LlmException('HTTP $status: $detail', LlmErrorType.trialExpired);
    }
  } catch (_) {}
  throw LlmException('HTTP $status: $detail', LlmErrorType.invalidApiKey);
}
```

#### 3c. Add friendly message for trial expiry

```dart
case LlmErrorType.trialExpired:
  return isZh
      ? '试用已过期。请在设置中添加您自己的 API Key 以继续使用 AI 助手。'
      : 'Your trial has expired. Add your own API key in Settings to continue.';
```

**Commit:** `feat: add trialExpired error type and friendly message to LlmService`

---

### Task 4: FloatingRobotWidget — Trial States

**Files:**
- Modify: `lib/widgets/floating_robot.dart`

**Changes:**

The robot currently has two states: has-key (animated, active) and no-key (grey, `!` badge). Add trial-specific states.

#### 4a. Trial active state

When trial is active and no user API key is configured, the robot should show as AVAILABLE (full color, bobbing) — not greyed out. The trial IS a valid API key.

Logic change in `_checkApiKey()`:
```dart
Future<void> _checkApiKey() async {
  final hasUserKey = await LlmService.hasApiKey(); // checks user-configured providers
  final prefs = await SharedPreferences.getInstance();
  final trialService = TrialService(prefs);
  final trialActive = trialService.getStatus() == TrialStatus.active;
  final hasKey = hasUserKey || trialActive;
  if (mounted && hasKey != _hasApiKey) {
    setState(() => _hasApiKey = hasKey);
  }
}
```

#### 4b. Trial expired state

When trial is expired and no user key: show the robot with a special "expired" badge (clock icon 🕐 instead of `!`). Tapping shows snackbar: *"Your trial has ended. Add your API key in Settings → AI Providers to continue."*

#### 4c. Tap behavior when trial is active

No change — tapping opens `AssistantScreen`. The `LlmService` handles the actual request using whichever provider is selected (which may be the trial provider).

**Step 1: Add `TrialService` check to `_checkApiKey()`**
**Step 2: Add expired badge variant**
**Step 3: Write tests for trial state transitions**

**Commit:** `feat: support trial active/expired states in FloatingRobotWidget`

---

### Task 5: AssistantScreen — Trial Expiry Banner

**Files:**
- Modify: `lib/screens/assistant/assistant_screen.dart`

**Changes:**

When the assistant fails with `LlmErrorType.trialExpired`, show a persistent inline banner at the top of the chat (not just a one-time snackbar).

#### 5a. Catch trial expiry in error handling

The assistant screen already has error handling for LLM failures. When `e.type == LlmErrorType.trialExpired`, set a state flag `_showTrialExpiredBanner = true`.

#### 5b. Banner widget

```
┌──────────────────────────────────────────────┐
│ 🕐 Your 7-day trial has ended.              │
│ Add your own API key in Settings → AI       │
│ Provider to continue chatting. [Settings →]  │
└──────────────────────────────────────────────┘
```

The [Settings →] button navigates directly to the settings screen (and pops back after).

#### 5c. Dismiss and persist

Banner can be dismissed (×), but reappears on the next failed request. It should NOT show if the user has a valid user API key configured (they may have added one after the trial expired).

**Commit:** `feat: show trial expiry banner in AssistantScreen`

---

### Task 6: Export / Import — Exclude Trial Data

**Files:**
- Verify: `lib/core/services/export_service.dart` (should be no-op — trial data is in SharedPreferences, not SQLite, and not in the provider list JSON)

**Verification:**
1. Trial data is stored in `trial_token` and `trial_started_at` SharedPreferences keys.
2. The export/restore pipeline handles SharedPreferences keys for `ai_assistant_name`, `ai_assistant_personality`, `theme_mode`, `locale`, and `llm_providers`. Trial keys are NOT in the restore whitelist and should not be exported.
3. Verify that backup ZIP does NOT include trial token.
4. Verify that restoring a backup does NOT overwrite trial state.

**Step 1: Audit export code for trial key handling**
**Step 2: Write test verifying trial keys excluded from backup**
**Step 3: Write test verifying restore doesn't affect trial state**

**Commit:** `test: verify trial data excluded from backup/restore pipeline`

---

### Task 7: Full Integration Testing

#### 7a. Mock backend for app tests

Create a lightweight mock HTTP server (or use `http.Client` mocking) for testing:
- `POST /api/trial/start` → returns token
- `POST /api/trial/chat` → returns AI response or error based on test scenario

#### 7b. End-to-end test scenarios

1. **First launch → start trial:**
   - Fresh install (no llm_providers, no trial data)
   - Go to Settings → AI Provider
   - Tap "Start Free Trial →"
   - Verify trial provider appears in list as selected
   - Verify robot shows active (animated, no ! badge)
   - Open assistant → send message → verify response (mock)

2. **Trial expired → add own key:**
   - Simulate trial expiry (set `trial_started_at` to 8 days ago)
   - Open assistant → verify expiry banner
   - Verify robot shows expired badge (! → 🕐)
   - Go to Settings → add own API key → select it
   - Verify robot returns to active state
   - Verify assistant works

3. **Trial with own key already configured:**
   - User already has an API key
   - Trial banner should NOT show "Start Free Trial" (or shows a muted "You already have an API key" variant)
   - No duplicate provider entries

4. **Daily rate limit:**
   - Mock backend returns 429 with `daily_limit_reached`
   - Verify friendly error message in assistant
   - Verify next day the limit resets (mock date change)

5. **Reinstall / clear data:**
   - Clear all app data
   - New install gets fresh device_id → can start trial
   - (This is server-enforced; mock backend returns 200 for new device_id)

#### 7c. Regression tests

- Existing user with API key: no trial banner disruption
- Existing provider list unchanged (merge-on-load still works)
- Export/import still works, trial data excluded
- All existing tests pass

**Commit:** `test: add integration tests for trial flow (start, expire, rate-limit, reinstall)`

---

## E. Files Changed Summary

| File | Change | Effort |
|------|--------|:------:|
| `lib/core/services/device_service.dart` | **New** — device ID generation/persistence | 0.5h |
| `lib/core/services/trial_service.dart` | **New** — trial lifecycle management | 2h |
| `lib/core/services/llm_service.dart` | Add `trialExpired` error type + detection | 0.5h |
| `lib/screens/settings/settings_screen.dart` | Trial banner, trial provider entry, start flow | 3h |
| `lib/widgets/floating_robot.dart` | Trial active/expired states, badge variants | 1.5h |
| `lib/screens/assistant/assistant_screen.dart` | Trial expiry banner, Settings link | 1h |
| `lib/l10n/app_en.arb + app_zh.arb` | ~15 new i18n strings | 0.5h |
| `lib/main.dart` or `app.dart` | Wire `TrialService` into provider tree (or lazy-init) | 0.5h |
| Various test files | ~15 new tests across services, screens, widgets | 2.5h |
| **App-side total** | | **~12h** |
| | | |
| **Backend** | | |
| Cloudflare Worker (JS/TS) | `/api/trial/start` + `/api/trial/chat` endpoints | 6h |
| Cloudflare D1/KV setup | Schema, bindings, wrangler config | 1h |
| Backend testing + deployment | Curl/Postman tests, monitoring, kill switch | 2h |
| **Backend total** | | **~9h** |
| | | |
| **Combined total** | | **~21h** |

---

## F. Dependencies & Sequencing

```
Task 0 (DeviceService)
  └──► Task 1 (TrialService)
         ├──► Task 2 (SettingsScreen trial UI)
         │       └──► Task 6 (Export/Import verification)
         ├──► Task 3 (LlmService trial errors)
         ├──► Task 4 (FloatingRobot trial states)
         └──► Task 5 (AssistantScreen expiry banner)
                 └──► Task 7 (Integration testing)

Backend Section A (independent, can run in parallel with app-side)
```

**Critical path:** Backend Section A must be deployed before Tasks 2 and 7 can be tested with real endpoints. Task 2 can be built against a mock backend; Task 7 integration tests need real or mocked endpoints.

**Recommendation:** Build app-side first with a mock HTTP client, then integrate with real backend when ready. The `TrialService` is the only class that makes HTTP calls — mocking it at that boundary isolates the rest of the app.

---

## G. Out of Scope (V1)

- Trial analytics / conversion tracking dashboard
- Push notification: "Your trial ends tomorrow"
- Trial extension (7-day extension codes)
- Different trial tiers (e.g., "Pro trial" with higher limits)
- A/B testing trial placement / messaging
- GPT-4o level model for trial (cost-prohibitive; qwen3.5-flash is sufficient for evaluation)
- Streaming responses for trial (use standard non-streaming to keep proxy simple)
- Refreshing the "Get a free API key" link with OpenRouter's free credits screen

---

## H. Rollout Plan

1. **Phase 1:** Build and deploy backend → internal testing with hardcoded test device_ids
2. **Phase 2:** Build app-side → test against staging backend
3. **Phase 3:** Ship as part of v1.1.0 release (or v1.1.1 if v1.1.0 is already close)
4. **Phase 4:** Monitor backend costs and abuse for 2 weeks; adjust rate limits if needed
5. **Phase 5:** (Post-launch) Add trial conversion analytics to measure impact
