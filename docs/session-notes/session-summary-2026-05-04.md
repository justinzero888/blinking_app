# Session Summary — 2026-05-04

**App:** Blinking (记忆闪烁) v1.1.0-beta.7+22  
**Duration:** Full session  
**Tests:** 96/96 passing (client), 352/352 passing (server)  
**Scope:** Insights Phase 2 (CT1-CT4) + M1-M2 Trial/Purchase foundation

---

## What We Did

### Phase 1: Insights Tab — CT1 + CT3

- **CT1 — Writing Stats:** New section between heatmap and mood donut. 3 mini stat cards: avg words/entry (CJK+EN word counting), most active weekday, peak writing hour.
- **CT3 — Tag-Mood Correlation:** New section between trends and mood jars. Top 5 tags by avg mood score, colored bars + emoji, min 3 entries threshold.
- **Bug fix:** Hero stats row 4th card clipped on iPhone — replaced with `Expanded` + `LayoutBuilder`.
- **UAT:** 12/12 test cases passed.

### Phase 2: Insights Tab — CT2 + CT4

- **CT2 — Checklist Analytics:** New section between trends and tag impact. 4 stats: total lists, avg completion rate, carried forward items, most common checklist item.
- **CT4 — AI-Generated Insights:** New section at bottom of Insights tab. LLM-powered insights via `LlmService.chat()` with fingerprint-based caching. Rule-based fallback when no LLM available. "Refresh Insights" manual trigger.
- **UAT:** 8/8 test cases passed (CT2), CT4 visually verified.

### Phase 3: M1 Foundation — Trial → Purchase

- **EntitlementService:** New `lib/core/services/entitlement_service.dart` — state machine (preview/restricted/paid), server-authoritative via JWT, calls `POST /api/entitlement/init`, `GET /api/entitlement/status`, `POST /api/entitlement/chat`.
- **Server: entitlement endpoints:** Created `src/routes/entitlement.ts` (330 lines) + `src/lib/jwt.ts` (100 lines). 3 endpoints: init, status, chat. Quota tracking: preview 9/day, restricted 3/month, paid 1,200/year. PREVIEW→RESTRICTED auto-transition after 21 days.
- **Floating robot rewrite:** `floating_robot.dart` — replaced single-condition "has API key?" check with entitlement-aware state matrix. Long-press status overlay. DORMANT tap → Paywall for RESTRICTED state.
- **BYOK setup screen:** `byok_setup_screen.dart` — 6 providers (OpenAI, Anthropic, OpenRouter, Google Gemini, DeepSeek, Groq) with dropdown selector. Ping validation with correct API format per provider. Privacy disclosure bottom sheet. url_launcher for "Where to get key" link.
- **Settings → AI rewrite:** Replaced old 7-day trial banner with entitlement-aware banner (PREVIEW/RESTRICTED/BYOK). "Use my own key" entry point navigates to BYOK screen. "Get Pro" opens paywall.

### Phase 4: M2 Purchase

- **Paywall screen:** `lib/screens/purchase/paywall_screen.dart` — Tessera gradient art, $9.99 price, feature checklist, "Even without Pro" free summary, in-app legal docs (Privacy/Terms via LegalDocScreen), back + close buttons.
- **Day 21 Transition screen:** `lib/screens/onboarding/transition_screen.dart` — "Your 21 days are complete" with what stays vs what pauses. [Get Pro] → paywall, [Continue free] → dismiss. One-time guard via SharedPreferences.
- **Server: receipt validation:** Created `src/routes/receipt.ts` (332 lines). `POST /api/entitlement/purchase` validates Apple (verifyReceipt) and Google (Play Developer API) receipts. `POST /api/entitlement/restore` cross-references receipts. Deduplication via `receipts` D1 table.
- **Client IAP:** Added `purchases_flutter` (RevenueCat). Created `PurchasesService` — init, purchase, restore, server validation. Wired paywall "Get Pro" and "Restore Purchases" buttons to real IAP flow.

### Phase 5: Documentation + Planning

- **Gap analysis:** Full comparison of design flows doc vs implementation. 5 sections analyzed, 60+ items status-tagged.
- **Implementation plan rewritten:** `trial-purchase-implementation-plan.md` aligned with design flows doc. 4 milestones, ~14.5h remaining.
- **IAP setup guide:** `iap-setup-guide.md` — 5-step guide for RevenueCat, App Store Connect, Play Console, server deploy.
- **Launch plan updated:** Added A0/S0 "Setup IAP (human)" tasks.
- **All docs synced:** PROJECT_PLAN.md, CLAUDE.md, launch plan, active plans.

---

## Files Changed (Client)

| File | Change |
|------|--------|
| `lib/core/services/entitlement_service.dart` | New — state machine + server sync |
| `lib/core/services/purchases_service.dart` | New — RevenueCat IAP wrapper |
| `lib/widgets/floating_robot.dart` | Major rewrite — entitlement-aware + long-press |
| `lib/screens/settings/settings_screen.dart` | Rewrite AI section — entitlement banner + BYOK |
| `lib/screens/settings/byok_setup_screen.dart` | New — 6-provider BYOK with dropdown |
| `lib/screens/cherished/cherished_memory_screen.dart` | +CT1 WritingStats, +CT2 Checklist, +CT3 TagMood, +CT4 AI Insights |
| `lib/screens/purchase/paywall_screen.dart` | New — Pro paywall |
| `lib/screens/onboarding/transition_screen.dart` | New — Day 21 transition |
| `lib/providers/summary_provider.dart` | +12 computed properties + insightsData() |
| `lib/app.dart` | +EntitlementService +PurchasesService + transition check |
| `lib/l10n/app_en.arb` / `app_zh.arb` | ~20 new keys |
| `pubspec.yaml` | +purchases_flutter |

## Files Changed (Server — chorus-api)

| File | Change |
|------|--------|
| `src/routes/entitlement.ts` | New — init, status, chat handlers |
| `src/routes/receipt.ts` | New — purchase, restore handlers |
| `src/lib/jwt.ts` | New — HMAC-SHA256 JWT sign/verify |
| `src/types.ts` | +EntitlementState, EntitlementRow, JWT_SECRET, ENTITLEMENT_ENABLED, GOOGLE_PLAY_SA_KEY |
| `src/index.ts` | +5 entitlement/receipt routes |
| `wrangler.toml` | +entitlement route |
| `migrations/0010_entitlements.sql` | New D1 table |
| `migrations/0011_receipts.sql` | New D1 table |

## Current State

**Client:** 96/96 tests, 0 analyze errors. M1 Foundation + M2 Purchase complete.  
**Server:** 352/352 tests, 0 TypeScript errors in src/. Entitlement + receipt endpoints ready.  
**Deploy status:** Server not yet deployed (needs JWT_SECRET + D1 migrations). IAP not yet configured (needs RevenueCat + store products).

## What's Remaining

| # | Item | Who | Effort |
|---|------|:--:|:------:|
| 1 | Setup IAP — RevenueCat, App Store Connect, Play Console | Human | ~2h |
| 2 | Server deploy — secrets + D1 migrations + `npm run deploy` | Human | ~10min |
| 3 | PROP-3 — Android Play Store production | Both | ~1.5h |
| 4 | M3 Onboarding — 3-screen flow, soft prompts, re-engagement | Dev | ~3.5h |
| 5 | M4 Top-ups — denial sheet, consumable IAP | Dev | ~3h |
