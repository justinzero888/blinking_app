# App Trial and Purchase Flow Design
**Created:** 2026-05-03
**Status:** Design phase
**Source:** UX Issues #8 (Robot trial/error states) + #12 (Settings trial banner dismiss)

---

## Overview

Design a coherent trial → purchase flow covering the floating robot, Settings banner, and any future purchase UI. The robot and Settings banner are the two touchpoints for trial/purchase communication; they should work together, not in isolation.

---

## Current State

| Touchpoint | What it shows |
|-----------|---------------|
| **Floating robot** | Bobbing 🤖 icon. States: active (tappable), no-key (dimmed + "!"), trial expired (dimmed + badge). Tap opens Assistant or shows snackbar. |
| **Settings banner** | Trial status card: "Start trial" / "X days remaining" / "Trial expired". Always shown when trial is relevant. No dismiss. |
| **Assistant screen** | Shows expiry banner when trial ended. "Save Reflection" works regardless. |

### Problems

1. Robot expired-state tap shows snackbar — extra tap to reach Settings
2. Settings banner not dismissible — feels naggy when user has own key
3. No unified purchase flow — trial, key entry, and future payment are separate mental models
4. Robot state doesn't re-check on app resume (lifecycle gap)

---

## Design Goals

1. **Single mental model:** Trial → Own key → (future) Subscription. Linear progression.
2. **Non-intrusive:** Banner dismissible when non-critical. Robot is the persistent indicator.
3. **Action-oriented:** Every state has a clear next action — no dead ends.
4. **Lifecycle-aware:** States update on app resume, not just tab switch.

---

## Flow Design

### State Machine

```
                    ┌──────────────────────────────────────┐
                    │          APP FIRST LAUNCH             │
                    └──────────────────────────────────────┘
                                     │
                                     ▼
                    ┌──────────────────────────────────────┐
                    │      Has own API key configured?      │
                    └──────────────────────────────────────┘
                         │                    │
                         ▼                    ▼
                        YES                  NO
                         │                    │
                         ▼                    ▼
              ┌──────────────────┐   ┌──────────────────┐
              │  FULL AI ACCESS   │   │  Has used trial?  │
              │  Robot: normal    │   └──────────────────┘
              │  Banner: hidden   │        │         │
              │  (everything just │        ▼         ▼
              │   works)          │       YES       NO
              └──────────────────┘        │         │
                                          ▼         ▼
                                   ┌──────────┐  ┌──────────────┐
                                   │ Trial    │  │ Trial never   │
                                   │ status?  │  │ used          │
                                   └──────────┘  └──────────────┘
                                    │       │           │
                                    ▼       ▼           ▼
                                  ACTIVE  EXPIRED    ┌──────────────┐
                                    │       │        │ Banner:      │
                                    ▼       ▼        │ "Try AI free"│
                              ┌──────────┐ ┌───────┐ │ + Start btn  │
                              │Robot:    │ │Robot: │ │ Dismissible  │
                              │bobbing   │ │dim 50%│ └──────────────┘
                              │Badge:    │ │Badge: │
                              │"N days"  │ │"Exp." │
                              │Tap: chat │ │Tap:   │
                              │          │ │Settings│
                              │Banner:   │ │Banner:│
                              │"N days"  │ │"Trial │
                              │Dismiss: ✓│ │ended" │
                              └──────────┘ │Dismiss:│
                                           │   ✗    │
                                           └────────┘
```

### Robot States (Detailed)

| State | Opacity | Animation | Badge | Tap Action | Long-Press |
|-------|:-------:|:---------:|:-----:|------------|------------|
| **Key active** | 100% | Bobbing | None | Open Assistant | — |
| **Trial active** | 100% | Bobbing | "N days" chip | Open Assistant | — |
| **Trial expired** | 50% | Slow pulse | "Expired" | **Navigate to Settings** | Tooltip |
| **No key, no trial** | 50% | Still | "!" | **Navigate to Settings** | Tooltip |
| **Loading/checking** | 100% | None | None | None | — |

### Settings Banner States (Detailed)

| State | Banner Content | Dismissible? | Reappears if... |
|-------|---------------|:------------:|-----------------|
| **Key active** | Hidden | N/A | Key removed |
| **Trial never used** | "Try AI for Free — 7 Days" + Start button | Yes | Key removed, trial not started |
| **Trial active** | "X days remaining · 20 req/day" | Yes | Key removed |
| **Trial expired** | "Trial ended — add your own key" + Link | **No** | Always (critical info) |

---

## Implementation Plan

### Phase 1: Robot State Polish (~1h)

1. **Expired/no-key tap → navigate to Settings (AI Providers section)**
   - Replace snackbar with `Navigator.push` or tab switch + scroll
   - Remove the extra interaction step

2. **Tooltip on long-press** (all non-active states)
   - EN: "Add your own API key to use the AI assistant"
   - ZH: "添加你自己的 API Key 以使用 AI 助手"

3. **Lifecycle re-check**
   - Add `WidgetsBindingObserver` to `FloatingRobotWidget`
   - On `didChangeAppLifecycleState(resumed)`, re-check trial/key status

### Phase 2: Settings Banner Polish (~45min)

1. **Hide banner when own key configured**
   - Check `LlmConfigNotifier` for provider count > 0
   - Banner display logic moved to a single `_shouldShowBanner()` method

2. **Dismiss button** (active trial + never-used states only)
   - "Dismiss" / "不再显示" text button trailing
   - Persisted to `SharedPreferences` key `trial_banner_dismissed`
   - Reset when key is removed

3. **No dismiss for expired state**
   - Expired = critical info, must persist until user adds key

### Phase 3: Future Purchase Flow (v1.2+)

When a subscription/purchase model is introduced:

1. **Robot becomes purchase CTA** when trial expired AND purchase flow exists
2. **Settings gets "AI Pass" section** with subscription management
3. **Assistant screen** gets inline upgrade prompt (not banner)
4. **RevenueCat or similar** SDK integration for IAP

---

## Files

| File | Phase | Changes |
|------|:----:|---------|
| `lib/widgets/floating_robot.dart` | 1 | Tap behavior, tooltip, lifecycle observer |
| `lib/screens/settings/settings_screen.dart` | 2 | Banner logic, dismiss, scroll to AI section |
| `lib/core/services/trial_service.dart` | 2 | Expose `neverUsed` status if needed |
| `lib/l10n/app_en.arb` / `app_zh.arb` | 1 | Tooltip string (1 new) |

---

## Decisions Needed

1. **Expired robot tap:** Navigate to Settings tab, or open Settings screen directly?
   - Recommend: Switch to Settings tab (index 4) + scroll to AI Providers section

2. **Banner dismiss persistence:** Permanent (never show again for this trial state) or per-session?
   - Recommend: Permanent for "never used" and "active". Reset on key removal.

3. **Purchase integration timeline:** v1.2 or later?
   - Defer to post-launch assessment
