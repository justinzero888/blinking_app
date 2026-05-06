# M1 Foundation — User Acceptance Testing (UAT)

**Build:** v1.1.0-beta.7+22 | **Date:** 2026-05-04 | **Tester:** _______________ | **Result:** PASS / FAIL

---

## What Changed

M1 Foundation implements the new entitlement model (Trial → Free → Purchase → BYOK) plus CT4 AI Insights. Key changes:

1. **EntitlementService** — PREVIEW (21-day) / RESTRICTED / PAID state machine talking to new server endpoints
2. **Floating robot** — rewritten with entitlement-aware AI button state matrix, long-press status overlay, tap behavior changes
3. **BYOK setup screen** — simplified 3-step API key setup with ping validation
4. **CT4 AI Insights** — new section at bottom of Insights tab with LLM-powered personal insights + rule-based fallback

---

## Setup

- [ ] App installed on both iOS simulator and Android emulator
- [ ] App has some data (entries with emotions, tags, checklists) for CT4 to show fallback insights
- [ ] Server: `JWT_SECRET` and `ENTITLEMENT_ENABLED=true` set via `npx wrangler secret put`
- [ ] Server: D1 migration `0010_entitlements.sql` applied via `npx wrangler d1 execute`
- [ ] Server deployed via `cd chorus-api && npm run deploy`

---

## Section 1: Floating Robot (AI Button)

### TC-1: Robot presence and position

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open app on any tab (0-3) | Robot appears at bottom-right, above FAB |
| 2 | Switch to Settings tab (4) | Robot is hidden |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-2: Robot dormant state (no server / no key)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Fresh install or no entitlement initialized | Robot appears dimmed (~55% opacity), no animation, orange "!" badge |
| 2 | Tap robot | Snackbar appears: "AI assistant requires Pro or your own API key." |
| 3 | Long-press robot | Status overlay menu appears showing "Source: None" |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-3: Robot active state (PREVIEW active)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Server returns PREVIEW state with quota > 0 | Robot shows full opacity + slow bobbing animation, primary color background, no badge |
| 2 | Tap robot | Opens AI Assistant chat screen with wave animation |
| 3 | Long-press robot | Status overlay shows "Source: Preview" + "Remaining: N" + "Preview: N days left" |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-4: Robot dormant state (PREVIEW quota exhausted)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Use all daily AI quota (9 calls) | Robot transitions to dormant state (dimmed, no animation) |
| 2 | Tap robot | Snackbar: "You've used today's AI quota. It refreshes tomorrow." |
| 3 | Next day | Robot returns to active state (quota refreshed) |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-5: Robot with BYOK key active

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Add valid API key via Settings → AI Provider | Robot switches to active state (full opacity, bobbing) |
| 2 | Long-press robot | Status shows "Source: Your key" |
| 3 | Remove key in Settings | Robot returns to appropriate state based on entitlement |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-6: Long-press status overlay content

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Long-press robot in any state | Menu appears anchored above robot with: "AI assistant" title, source label, remaining count (if applicable) |
| 2 | "Use my own key" menu item | Visible when no BYOK configured |
| 3 | "Get Pro" menu item | Visible in RESTRICTED state |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Section 2: Insights Tab — CT4 AI Insights

### TC-7: CT4 Section Presence

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Insights tab | Scroll to bottom |
| 2 | Check section position | "🤖 AI Insights" (EN) / "🤖 AI 个性化洞察" (ZH) appears **between** Tag Impact on Mood and Mood Jars carousel |
| 3 | Check section content | Shows fallback rule-based insights or "Start journaling..." if no data |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-8: CT4 Fallback Insights (no LLM available)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Ensure no API key configured + no active PREVIEW | Section shows rule-based insights as bullet points |
| 2 | Check content | Includes relevant stats: streak ("You've written for N days"), longest streak, happiest tag, checklist completion |
| 3 | If no data exists | Shows "Start journaling for AI insights" / "开始记录以获取 AI 洞察" |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-9: CT4 Refresh Button

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Tap "Refresh Insights" button | With no LLM available: button shows loading briefly, then returns to fallback |
| 2 | With LLM available | Button shows spinner → text card appears with AI-generated insights → "AI-generated" label at bottom |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-10: CT4 Bilingual Labels

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Set language to English | Section title: "🤖 AI Insights", button: "Refresh Insights" |
| 2 | Set language to Chinese | Section title: "🤖 AI 个性化洞察", button: "刷新洞察" |
| 3 | Fallback text | Updates to correct language |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-11: CT4 Layout Integrity

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scroll entire Insights tab top to bottom | Order: Hero → Heatmap → Writing Stats → Mood Donut → Trends → Checklist → Tag Impact → **AI Insights** → Mood Jars |
| 2 | All sections render | No overflow stripes, no crashes |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Section 3: BYOK Setup Screen

### TC-12: BYOK Screen Access

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open Settings | Scroll to AI section |
| 2 | Verify "Use my own key" entry point exists | Visible in Settings → AI Providers section |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-13: BYOK Screen — Privacy Banner

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Open BYOK setup screen | Privacy banner at top: "Your data goes straight to the model provider. Blinking never sees it." |
| 2 | Tap "Why?" link | Bottom sheet appears explaining managed vs BYOK privacy |
| 3 | Dismiss sheet | Returns to setup screen |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-14: BYOK Screen — Provider Selection

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Check provider radio buttons | Two options: OpenAI and Anthropic. Default: OpenAI selected |
| 2 | Tap Anthropic | Selection changes to Anthropic (animated radio button) |
| 3 | Key field hint updates | Hint text changes to "sk-ant-" prefix for Anthropic |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-15: BYOK Screen — Key Validation

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Enter invalid key (e.g., "test123") | Tap "Test and save" |
| 2 | Check error | Shows "Key format looks wrong" / "Key 格式不正确" |
| 3 | Enter valid-looking but non-working key | Tap "Test and save" |
| 4 | Check error | Shows auth error message from provider (401/403) |
| 5 | Enter valid working key | Tap "Test and save" |
| 6 | Check success | Snackbar: "Connected. Your AI now uses your own key." → screen closes |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-16: BYOK Screen — Advanced Section

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Scroll to bottom | Advanced section collapsed by default |
| 2 | Tap "Show advanced" | Expands showing model override placeholder |
| 3 | Check description | "Default model is auto-selected..." |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Section 4: Server Integration

### TC-17: Entitlement Init (POST /api/entitlement/init)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `curl -X POST https://blinkingchorus.com/api/entitlement/init -H "Content-Type: application/json" -d '{"device_id":"test-abc123"}'` | Returns `{ token, state: "preview", preview_duration_days: 21, max_requests_per_day: 9 }` |
| 2 | Send again with same device_id | Returns `{ token, state: "preview", message: "Entitlement already exists." }` |
| 3 | Send with invalid device_id (< 8 chars) | Returns 400 with validation error |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-18: Entitlement Status (GET /api/entitlement/status)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `curl https://blinkingchorus.com/api/entitlement/status -H "Authorization: Bearer <JWT from init>"` | Returns `{ state, quota, preview_days_remaining, token: <fresh JWT> }` |
| 2 | Send without Bearer token | Returns 400 |
| 3 | Send with invalid token | Returns 403 "Invalid or expired token" |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-19: Entitlement Chat (POST /api/entitlement/chat)

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Send valid chat request with Bearer token | Returns AI response from OpenRouter with `_entitlement` metadata |
| 2 | Second request — quota decremented | Check status endpoint — quota decreased by 1 |
| 3 | Exhaust daily quota (9 requests) | Returns 429 "quota_exhausted" |
| 4 | Next day | Quota resets to 9 |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

### TC-20: Server Health

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | `curl https://blinkingchorus.com/api/v1/health` | Returns "ok" (existing endpoint, verify not broken) |
| 2 | `curl https://blinkingchorus.com/api/trial/start` (legacy) | Existing trial endpoint still functional |

**Result:** ☐ PASS ☐ FAIL — Notes: _______________

---

## Summary

| TC | Section | Description | Result |
|----|---------|-------------|:------:|
| TC-1 | Robot | Presence and position | ☐ PASS / FAIL |
| TC-2 | Robot | Dormant state (no server/key) | ☐ PASS / FAIL |
| TC-3 | Robot | Active state (PREVIEW) | ☐ PASS / FAIL |
| TC-4 | Robot | Quota exhausted | ☐ PASS / FAIL |
| TC-5 | Robot | BYOK key active | ☐ PASS / FAIL |
| TC-6 | Robot | Long-press overlay | ☐ PASS / FAIL |
| TC-7 | CT4 | Section presence | ☐ PASS / FAIL |
| TC-8 | CT4 | Fallback insights | ☐ PASS / FAIL |
| TC-9 | CT4 | Refresh button | ☐ PASS / FAIL |
| TC-10 | CT4 | Bilingual labels | ☐ PASS / FAIL |
| TC-11 | CT4 | Layout integrity | ☐ PASS / FAIL |
| TC-12 | BYOK | Screen access | ☐ PASS / FAIL |
| TC-13 | BYOK | Privacy banner | ☐ PASS / FAIL |
| TC-14 | BYOK | Provider selection | ☐ PASS / FAIL |
| TC-15 | BYOK | Key validation | ☐ PASS / FAIL |
| TC-16 | BYOK | Advanced section | ☐ PASS / FAIL |
| TC-17 | Server | Init endpoint | ☐ PASS / FAIL |
| TC-18 | Server | Status endpoint | ☐ PASS / FAIL |
| TC-19 | Server | Chat endpoint | ☐ PASS / FAIL |
| TC-20 | Server | Health check + legacy trial | ☐ PASS / FAIL |

