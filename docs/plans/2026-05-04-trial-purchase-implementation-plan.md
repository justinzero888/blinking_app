# Trial → Free → Purchase → BYOK — Implementation Plan

**Created:** 2026-05-04 | **Updated:** 2026-05-04 (post gap analysis)  
**Status:** M1 Foundation done — M2 Purchase + M3 Onboarding + M4 Polish remaining  
**Source:** `2026-05-04-Blinking-Trial-Purchase-Design-Flows.md` (authoritative)

---

## Model Summary

```
PREVIEW (21d, auto)  →  RESTRICTED (free forever)  →  PAID ($9.99 one-time, lifetime)
                                                          ├─ AI: 1,200/year included
                                                          ├─ BYOK ($0, own key, unlimited)
                                                          └─ Top-ups ($4.99/500, never expire)
BYOK is available to EVERYONE as an alternative to managed AI, at any tier.
```

| Tier | AI (managed) | Features | Price |
|------|:-----------:|----------|:-----:|
| PREVIEW (21d, auto) | 9/day (189 total) | Full access | $0 |
| RESTRICTED | 3/month | Notes, check-in habits | $0 forever |
| PAID (Pro) | 1,200/year | Everything | $9.99 one-time |
| BYOK (any tier) | Unlimited | — | $0 + API key |
| Top-up (Pro only) | +500 | — | $4.99 |

---

## What's Implemented (M1 Foundation — Done)

| Component | Status | Notes |
|-----------|:------:|-------|
| Server: `POST /api/entitlement/init` | Done | Creates PREVIEW, returns JWT |
| Server: `GET /api/entitlement/status` | Done | State + quota + fresh JWT |
| Server: `POST /api/entitlement/chat` | Done | Proxy to OpenRouter, decrement quota |
| Server: PREVIEW→RESTRICTED auto-transition | Done | `computeState()` checks 21d elapsed |
| Server: Quota: 9/day preview, 3/month restricted, 1,200/yr paid | Done | |
| Client: `EntitlementService` state machine | Done | Syncs from server JWT |
| Client: Floating robot AI button core routing | Done | 7 of 13 rows implemented |
| Client: BYOK setup screen (privacy + provider + key + test) | Done | Missing: url_launcher link, secure storage |
| Client: Settings → AI entitlement banner | Done | PREVIEW / RESTRICTED / BYOK states |
| Client: Settings → "Use my own key" entry point | Done | Navigates to ByokSetupScreen |
| Client: CT4 AI Insights section | Done | Fallback rules + manual refresh |
| Client: Provider tree wired (EntitlementService) | Done | `app.dart` |

---

## Implementation Order (remaining)

### Milestone 2: Purchase & BYOK Polish (~8h)

Items needed for a user to go from RESTRICTED → PAID and for BYOK to feel complete.

#### 2.1: Server Receipt Validation — ~2.5h

| # | Task | Priority |
|---|------|:--------:|
| 2.1a | `POST /api/entitlement/purchase` — validate Apple IAP receipt, transition to PAID | P1 |
| 2.1b | `POST /api/entitlement/purchase` — validate Google IAP receipt | P1 |
| 2.1c | `POST /api/entitlement/restore` — cross-reference receipt, return state | P1 |
| 2.1d | Receipt deduplication (transactionId unique constraint) | P1 |

#### 2.2: IAP Integration (Client) — ~2h

| # | Task | Priority |
|---|------|:--------:|
| 2.2a | Add `in_app_purchase` or RevenueCat SDK to pubspec | P1 |
| 2.2b | Define products: `blinking_pro` ($9.99 non-consumable), `blinking_topup_500` ($4.99 consumable) | P1 |
| 2.2c | Register products in App Store Connect + Play Console | P1 |
| 2.2d | Implement purchase flow in `EntitlementService`: buy → receipt → server validate → state→PAID | P1 |
| 2.2e | Sandbox testing (Apple Sandbox + Google Test Track) | P1 |

#### 2.3: Paywall Screen — §1.5 — ~1h

| # | Task | Priority |
|---|------|:--------:|
| 2.3a | New `lib/screens/purchase/paywall_screen.dart` | P1 |
| 2.3b | Above fold: Tessera fragment + "Blinking Pro" + $9.99 + [Get Pro] + [Restore Purchases] | P1 |
| 2.3c | Below fold: feature checklist (what you get vs what stays free) + "No subscription" + policy links | P1 |
| 2.3d | Wire `[Get Pro]` → native StoreKit/Play Billing sheet → receipt → PAID | P1 |

#### 2.4: Restore Purchases — §1.7 — ~30min

| # | Task | Priority |
|---|------|:--------:|
| 2.4a | Restore button on paywall + Settings → Account | P1 |
| 2.4b | Call platform restore → server `/restore` → PAID toast or "not found" alert | P1 |

#### 2.5: BYOK Polish — ~1h

| # | Task | Priority |
|---|------|:--------:|
| 2.5a | Wire url_launcher for "Where do I get a key?" link | P2 |
| 2.5b | Managed ↔ BYOK toggle in Settings: "Switch back to included quota" | P2 |
| 2.5c | BYOK key display: masked key (sk-ant-••••dEf) + Replace/Remove buttons | P2 |
| 2.5d | AI button badge: `[1,200 left]` (managed) vs `[your key]` (BYOK) | P2 |

#### 2.6: Day 21 Transition Screen — §1.4 — ~30min

| # | Task | Priority |
|---|------|:--------:|
| 2.6a | New `lib/screens/onboarding/transition_screen.dart` | P1 |
| 2.6b | "What stays: ✓ all notes + check-in habits. What pauses: new habits, AI, backup" | P1 |
| 2.6c | CTA: [Get Pro — $9.99] / [Continue free] | P1 |
| 2.6d | One-time-only guard (SharedPreferences) | P1 |

---

### Milestone 3: Onboarding & Engagement (~3.5h)

#### 3.1: First-Launch Onboarding — §1.1 — ~1h

| # | Task | Priority |
|---|------|:--------:|
| 3.1a | New `lib/screens/onboarding/onboarding_screen.dart` | P1 |
| 3.1b | Screen 1: Tessera fragment animation (or branded illustration). Two lines: "Your life is fragments of time..." / "Blinking is a quiet place to assemble them." CTA: [Continue]. No skip. | P1 |
| 3.1c | Screen 2: Three icons + one line each: Notes, Habits, Reflection. CTA: [Continue] + [Skip] | P1 |
| 3.1d | Screen 3: The deal — 21 days free, then free forever with limits, Pro $9.99 one-time. CTA: [Start your 21 days] + [Already have Pro? Restore] | P1 |
| 3.1e | One-time guard in SharedPreferences (`onboarding_completed`) | P1 |

#### 3.2: Soft Purchase Prompts — §1.3 — ~45min

| # | Task | Priority |
|---|------|:--------:|
| 3.2a | Day 18 prompt (celebration): trigger on habit streak or AI reflection. "It's been three weeks..." + [See Pro] / [Maybe later] | P2 |
| 3.2b | Day 19 prompt (value): trigger on AI reflection completed. "You used AI K times..." + [Get Pro] / [Maybe later] | P2 |
| 3.2c | Day 20 prompt (last call): trigger on habit check-in or note save. "Tomorrow your preview ends..." + [Go Pro now] / [I'll decide tomorrow] | P2 |
| 3.2d | Dismissal counter: 1 per 24h window. `SharedPreferences` key per day | P2 |

#### 3.3: Re-Engagement Triggers — §1.6 — ~30min

| # | Task | Priority |
|---|------|:--------:|
| 3.3a | Wire `canAddHabit` gate in home/routine screens | P2 |
| 3.3b | Wire `canEditNote` gate in entry detail screen | P2 |
| 3.3c | Wire `canBackup` gate in settings export/restore | P2 |
| 3.3d | Each trigger: calm modal with explanation + [Get Pro] CTA + [Not now], 1 per 7 days | P2 |

#### 3.4: AI Button Polish — §2.2-2.6 — ~1h

| # | Task | Priority |
|---|------|:--------:|
| 3.4a | RESTRICTED DORMANT tap → open paywall (not snackbar) | P1 |
| 3.4b | Hide button during onboarding screens and modal screens (paywall, BYOK setup) | P2 |
| 3.4c | Centralized localisation table for all 9 copy strings (§2.9) | P2 |
| 3.4d | Long-press overlay: richer format with annual quota breakdown, provider name, refill date | P2 |
| 3.4e | Animation polish: AI-call-in-flight pulse (600ms), call-failure shake (250ms), state-transition cross-fade (200ms) | P3 |
| 3.4f | Secure key storage: iOS Keychain + Android EncryptedSharedPreferences (§3.6) | P2 |

---

### Milestone 4: Top-Ups & Refinement (~3h)

#### 4.1: Denial Moment Sheet — §4.2 — ~45min

| # | Task | Priority |
|---|------|:--------:|
| 4.1a | Trigger: PAID user exhausts all quota → open denial sheet | P3 |
| 4.1b | Three options: Top-up $4.99/500, BYOK (free, unlimited), Wait for refill | P3 |
| 4.1c | Magic moment: auto-retry AI call after top-up purchase | P3 |

#### 4.2: Top-Up IAP — §4.3-4.7 — ~1.5h

| # | Task | Priority |
|---|------|:--------:|
| 4.2a | Consumable IAP: `blinking_topup_500` | P3 |
| 4.2b | Post-purchase: receipt → server → credits → toast → auto-retry | P3 |
| 4.2c | Credit display: Settings → AI annual + top-up breakdown | P3 |
| 4.2d | Edge cases: refund, reinstall restore, stacking, PREVIEW block | P3 |

#### 4.3: BYOK Key Validation on Use — ~45min

| # | Task | Priority |
|---|------|:--------:|
| 4.3a | Proactive re-validation: on AI call failure (401/403), set `entitlement_byok_validated = false` | P3 |
| 4.3b | Provider-down detection in BYOK mode: don't fallback to managed (would silently spend quota) | P3 |

---

## Total Remaining Effort

| Milestone | Hours | Blocks Launch? |
|-----------|:-----:|:--------------:|
| M2: Purchase + BYOK Polish | 8h | **Yes** |
| M3: Onboarding + Engagement | 3.5h | No (can ship without) |
| M4: Top-Ups + Refinement | 3h | No (post-launch) |
| **Total** | **~14.5h** | |

---

## Previous Gaps Now Closed

These items from earlier plan versions are done:

| Item | Status |
|------|:------:|
| Server entitlement endpoints (init / status / chat) | Done |
| Client EntitlementService state machine | Done |
| Floating robot AI button core routing (7 of 13 rows) | Done |
| BYOK setup screen | Done |
| Settings → AI entitlement banner (PREVIEW / RESTRICTED / BYOK) | Done |
| CT4 AI Insights section | Done |
| Provider tree wired | Done |

---

## Cost Assessment

**Total infrastructure cost: $0.** Server runs on Cloudflare free tier. Managed AI uses `qwen/qwen3.5-flash` on OpenRouter — permanently free, no usage limits.

IAP platform fees (Apple 15-30%, Google 15-30%) apply only to actual purchase revenue — not operating cost.
