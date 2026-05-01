# Blinking App — Development Session Summary
**Date:** 2026-04-30
**Session Type:** Design Review & Planning
**Status:** COMPLETE — PROP-6 & PROP-9 fully designed, evaluated, and planned

---

## Executive Summary

Two deferred features were exhaustively evaluated against the existing codebase, their designs completed (or revised), full implementation plans written, and launch sequencing decided.

1. **PROP-9 (Daily Checklist Entry):** The original design from PROJECT-STATUS-2026-04-29.md was reviewed against the current codebase, 10 issues identified (2 critical, 3 high, 3 medium, 2 low), and a revised 9-task implementation plan written. Effort revised from 12–15h to ~18h.

2. **PROP-6 (Trial API Key Flow):** The original high-level description had no backend design, no UX spec for expiry/transition, and was estimated at 3-4h. Full backend architecture designed (Cloudflare Workers, 2 endpoints, rate limiting, cost model), 11 gaps closed, and a 7-task app-side + 3-task backend plan written. Effort revised from 3-4h to ~21h total (12h app + 9h backend).

3. **Launch Sequencing:** Decided PROP-6 goes first (launch-critical for onboarding conversion), PROP-9 is a Week 3 stretch goal, Week 4 reserved for launch readiness. Target: end-of-May production launch on Google Play.

4. **CLAUDE.md:** Updated to reflect latest plans, revised effort estimates, plan file locations, and launch roadmap.

---

## Work Completed

### PROP-9: Daily Checklist Entry — Design Evaluation & Revised Plan

**Source doc evaluated:** `docs/plans/PROJECT-STATUS-2026-04-29.md` lines 260–386

**Codebase reviewed:**
- `lib/models/entry.dart` — EntryType enum (`routine | freeform`), Entry model
- `lib/core/services/database_service.dart` — schema v11, migration pattern
- `lib/core/services/storage_service.dart` — CRUD layer
- `lib/repositories/entry_repository.dart` — provider bridge
- `lib/providers/entry_provider.dart` — state management
- `lib/screens/add_entry_screen.dart` — entry creation UI
- `lib/widgets/entry_card.dart` — list rendering
- `lib/screens/moment/entry_detail_screen.dart` — read-only view
- `lib/screens/home/home_screen.dart` — calendar day view

**Issues found (10 total):**

| # | Issue | Severity |
|---|-------|----------|
| R1 | `EntryType` enum name collision (existing `routine\|freeform` vs proposed `note\|list`) | Critical |
| R2 | Migration version stated as "v11" — v11 already exists | Critical |
| R3 | Toggle List→Note: items lost — no concatenation spec | High |
| R4 | Note→List: long text becomes title with no truncation | High |
| R5 | Carry-forward in EntryProvider breaks layering (Provider→DB direct) | High |
| R6 | `date()` in SQLite uses UTC — off-by-one near midnight | Medium |
| R7 | `loadEntries()` runs carry-forward on every call, not just app open | Medium |
| R8 | No max item text length | Low |
| R9 | No min-item guard on save button | Low |
| R10 | Calendar badge hedged as "nice-to-have" — deferred | Low |

**Resolutions applied in plan:**
- New enum `EntryFormat` (not `EntryType`), DB column `entry_format`
- Migration bumped to v12
- Toggle behavior fully specified (text→title truncation at 200 chars, items→body concatenation)
- Carry-forward moved to `EntryRepository.checkAndCarryForward()` — preserves layering
- Date comparison uses Dart local time, not SQLite UTC
- Guard flag prevents duplicate carry-forward checks
- Calendar badge deferred to v1.1 follow-up

**Plan output:** `docs/plans/2026-04-30-prop-9-daily-checklist-plan.md` (9 tasks, ~18h)

---

### PROP-6: Trial API Key Flow — Full Design & Implementation Plan

**Source doc evaluated:** `docs/plans/PROJECT-STATUS-2026-04-29.md` lines 208–227 + scattered TODO references

**Codebase reviewed:**
- `lib/core/services/llm_service.dart` — LLM provider config, error types, auth gate
- `lib/core/services/chorus_service.dart` — existing backend pattern (Cloudflare Workers)
- `lib/screens/settings/settings_screen.dart` — provider list UI, API key edit dialog, merge-on-load
- `lib/widgets/floating_robot.dart` — `hasApiKey()` gate, animated states
- `lib/screens/assistant/assistant_screen.dart` — chat UI, error handling
- `lib/providers/llm_config_notifier.dart` — config change notifications
- `lib/providers/ai_persona_provider.dart` — persona persistence

**Gaps found (11 total):**

| # | Issue | Severity |
|---|-------|----------|
| R1 | No backend design — endpoints, auth, storage, deployment | Critical |
| R2 | No trial token lifecycle management (start/check/expire) | Critical |
| R3 | No trial-to-own-key transition UX spec | High |
| R4 | No expiry UX spec (what screens change, what messages show) | High |
| R5 | "3-4h app-side" estimate ignores TrialService, settings UI, robot changes, assistant changes, testing | High |
| R6 | Trial provider integration with existing provider architecture unspecified | Medium |
| R7 | Trial button placement ambiguous (edit dialog vs settings list) | Medium |
| R8 | Reinstall/data-clear bypass not addressed | Medium |
| R9 | OpenRouter free credits overlap — risk of duplicated effort | Medium |
| R10 | No i18n strings specified | Low |
| R11 | No monitoring/conversion analytics | Low |

**New sections added to plan:**

- **Section A — Backend Design (entirely new):**
  - Two Cloudflare Worker endpoints (`/api/trial/start`, `/api/trial/chat`)
  - D1/KV storage for trial tokens with per-device enforcement
  - Rate limiting: 20 requests/day, 7-day expiry, ~4000 tokens/request
  - Model: qwen/qwen3.5-flash-02-23 (~$0.02/1M tokens)
  - Estimated cost: ~$0.10–$0.20 per trial user
  - Kill switch via Cloudflare Workers secret (`TRIAL_ENABLED`)
  - IP rate limiting on `/api/trial/start` (5/hr)
  - ~200 lines of Worker JS/TS pseudocode provided

- **Section C — Risk Analysis:**
  - OpenRouter free credit overlap (mitigated: trial eliminates setup friction, not cost)
  - Cost overrun (mitigated: daily caps + budget alert + kill switch)
  - Abuse via fake device_ids (mitigated: IP rate limiting)
  - Clock manipulation bypass (mitigated: server-authoritative expiry check)

- **Sections D–F — 7 App-Side Tasks:**
  - Task 0: DeviceService (anonymous install UUID)
  - Task 1: TrialService (start/status/expiry lifecycle)
  - Task 2: SettingsScreen trial UI (banner, provider entry, start flow)
  - Task 3: LlmService trial error handling (`trialExpired` type)
  - Task 4: FloatingRobotWidget trial states (active/expired badges)
  - Task 5: AssistantScreen expiry banner
  - Task 6: Export/Import verification (trial data excluded)
  - Task 7: Integration testing with mock backend

- **Section H — Rollout Plan (5 phases)**

**Plan output:** `docs/plans/2026-04-30-prop-6-trial-api-key-plan.md` (791 lines, ~21h total)

---

### Launch Sequencing & Critical Path

**Decision:** PROP-6 before PROP-9

| Factor | PROP-6 | PROP-9 |
|--------|:------:|:------:|
| Launch conversion impact | Direct — removes #1 onboarding barrier | Indirect — deepens engagement |
| Without it at launch | New users hit AI wall → bounce | Users journal normally |
| External risk | Backend must deploy | None |
| Effort | ~21h | ~18h |

**4-week critical path to end-of-May launch:**

| Week | Window | Work |
|------|--------|------|
| 1–2 | May 1–14 | PROP-6 backend + app-side build, alpha test |
| 3 | May 15–21 | PROP-9 (stretch goal) + PROP-7/PROP-8 polish |
| 4 | May 22–30 | Launch readiness: Play Store listing, beta crash triage, smoke tests, version bump, release build |

---

## Key Decisions

1. **PROP-9 naming:** `EntryFormat` enum (not `EntryType`) to avoid collision with existing `routine | freeform` enum. New DB column `entry_format`.
2. **PROP-9 migration:** v12 (not v11 — already taken by indexes).
3. **PROP-9 carry-forward:** Implemented in `EntryRepository` (not `EntryProvider` directly) — preserves 3-layer architecture.
4. **PROP-6 backend:** Co-deployed on Cloudflare Workers with existing Chorus infra (`blinkingchorus.com`).
5. **PROP-6 trial model:** Qwen 3.5 Flash on OpenRouter — cheapest capable model, ~$0.02/1M tokens.
6. **PROP-6 trial provider:** Injected into provider list at render time, NOT persisted in `llm_providers` JSON — avoids export/restore pollution.
7. **PROP-6 expiry enforcement:** Server-authoritative (app-side day counter is display-only).
8. **PROP-9 priority:** Demoted from "must-ship" to "stretch goal" for v1.1.0. Ships in v1.1.1 if Week 3 runs over.
9. **iOS:** Remains blocked. No change.

---

## Files Created

| File | Lines | Purpose |
|------|:-----:|---------|
| `docs/plans/2026-04-30-prop-9-daily-checklist-plan.md` | ~580 | Revised PROP-9 design + 9-task implementation plan |
| `docs/plans/2026-04-30-prop-6-trial-api-key-plan.md` | 791 | Complete PROP-6 design (backend + app-side) + 7+3 task plan |
| `docs/session-notes/session-summary-2026-04-30-prop-6_9_design_planning.md` | — | This file |

## Files Modified

| File | What changed |
|------|-------------|
| `CLAUDE.md` | Updated pending items table (PROP-6/PROP-9 plans + effort), added launch roadmap section |

---

## Next Actions (Recommended)

1. **Immediate:** Begin PROP-6 backend build (Cloudflare Worker — 9h, independent of app-side)
2. **Parallel:** Begin PROP-6 app-side Task 0 (DeviceService) and Task 1 (TrialService) with mock backend
3. **When backend ready:** Complete PROP-6 Tasks 2–7, alpha test end-to-end
4. **Week 3 gate:** If PROP-6 is complete and tested, begin PROP-9. If not, defer PROP-9 to v1.1.1
5. **Week 4:** No new features — launch readiness only
