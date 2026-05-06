# Blinking Launch Readiness — Bug Fixes & Flow Validation

**Date:** 2026-05-06 | **Version:** 1.1.0-beta.8+23 → targeting 1.1.0

---

## Current Status

| Area | Status |
|------|--------|
| RevenueCat Test Store | ✅ Verified |
| iOS App Store Sandbox | ✅ Verified |
| Google Play IAP | ⬜ Postponed (service credentials needed) |
| App Store IAP | ⬜ Postponed (IAP metadata + submission) |
| Server deploy | ⬜ Deploy-ready |

---

## Priority 1: UX & Flow Validation

### 1a. Trial → Preview → Restricted → Pro Flow
- [ ] Fresh install → 3 onboarding screens → 21-day preview auto-starts
- [ ] AI requests work with BYOK during preview (or show clear guidance)
- [ ] Preview countdown decreases correctly each day
- [ ] Day 21 → transition screen → restricted mode
- [ ] Restricted: robot dormant → tap → paywall → purchase → robot active
- [ ] Restore Purchases works after reinstall
- [ ] Debug toggle (5-tap version) works: restricted ↔ preview for testing
- [ ] Settings banner shows correct state (preview / restricted / paid)
- **Must test on both simulator and real device**

### 1b. AI Flow During Preview
- [ ] Without BYOK: robot active but AI request shows "No API key configured" → directs to Settings
- [ ] With BYOK: robot active → AI works
- [ ] After purchase: AI quota shows 1,200/year

---

## Priority 2: Routine Calculation Bugs

### 2a. Streak Shows 0 for Active Habit
**Bug:** Vitamin habit checked daily for 20+ days shows streak = 0
**Expected:** Streak should show 20+ for a daily habit completed every day

### 2b. Monthly Completion % Over 100%
**Bug:** Month completion shows over 100% (e.g., 120%)
**Expected:** Max 100%

### 2c. Done Count Overflow
**Bug:** Shows 8/6, 7/6 (more done than required)
**Expected:** Should be at most X/X (done ≤ required)

---

## Priority 3: Insights Tab

### 3a. Trend Charts Missing Y-Axis
**Bug:** All four trend charts (emotion, routine completion, note counts, top tags) have no y-axis labels
**Expected:** Y-axis should show values/percentages

### 3b. AI Insights — Simplify
**Current:** Uses LLM to generate "AI Insights" section with simple statistics
**Issue:** LLM call for basic stats adds latency and requires server/api key
**Fix:** Replace AI-generated insights with rule-based stat summaries. Remove LLM dependency from Insights tab. Keep AI for the chat assistant only.

---

## Priority 4: Release Build

- [ ] Fix IAP metadata in App Store Connect (pricing, localization, screenshot)
- [ ] Build v1.1.0 with fixes
- [ ] Push to TestFlight (iOS) + Internal Testing (Android)
- [ ] Smoke test: fresh install → onboarding → preview → purchase → post-purchase state

---

## Files to Fix

| File | Issue |
|------|-------|
| `lib/core/services/entitlement_service.dart` | Preview countdown, state machine |
| `lib/core/services/llm_service.dart` | Preview AI flow |
| `lib/screens/routine/routine_screen.dart` | Streak calc, completion %, done count |
| `lib/providers/summary_provider.dart` | Completion rate overflow |
| `lib/screens/cherished/cherished_memory_screen.dart` | Chart y-axis, AI insights removal |
| `lib/screens/purchase/paywall_screen.dart` | Post-purchase state update |
| `lib/screens/settings/settings_screen.dart` | PAID banner |

---

## IAP Setup (Postponed)

Blocked on:
- App Store Connect: IAP metadata (pricing, localizations, screenshot)
- Google Play Console: Product creation + service credentials

**Path forward after fixes:**
1. Resolve metadata → IAP reaches "Ready to Submit"
2. Import product into RevenueCat
3. Test sandbox purchase with production key
4. Build release with `--dart-define=RC_API_KEY=appl_...`
5. Submit for App Review
