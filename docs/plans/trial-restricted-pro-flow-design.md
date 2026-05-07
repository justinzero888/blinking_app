# Blinking — Trial → Restricted → Pro Flow Design

**Date:** 2026-05-06 | **Version:** 1.1.0 | **Status:** Draft for Review

---

## State Machine

```
                    ┌──────────────────────────────────────────┐
                    │            Fresh Install                  │
                    │    storageService.init() → empty DB       │
                    └─────────┬────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │    3-Page M3        │
                    │    Onboarding       │
                    └─────────┬───────────┘
                              │ onboarding_completed = true
                              ▼
              ┌───────────────────────────────┐
              │         PREVIEW (21 days)      │
              │  ┌───────────────────────────┐ │
              │  │ AI: trial key auto-applied│ │
              │  │ Robot: active             │ │
              │  │ Countdown: X days left    │ │
              │  │ 3 AI requests/day         │ │
              │  │ All features unlocked     │ │
              │  └───────────────────────────┘ │
              └───────────────┬───────────────┘
                              │ day 22 OR quota exhausted
                              ▼
    ┌─────────────────────────────────────────────────┐
    │              RESTRICTED                          │
    │  ┌─────────────────────────────────────────────┐│
    │  │ ALLOWED:                                    ││
    │  │  • Add notes/checklists                     ││
    │  │  • Check existing habits                    ││
    │  │  • View history                             ││
    │  │  • 3 AI requests/month (pro key)            ││
    │  │                                             ││
    │  │ BLOCKED:                                    ││
    │  │  • Edit/delete habits                       ││
    │  │  • Edit/delete tags                         ││
    │  │  • Add new habits                           ││
    │  │  • Backup / Restore                         ││
    │  │  • Edit existing notes                      ││
    │  │  • Share to Chorus                          ││
    │  └─────────────────────────────────────────────┘│
    │  Robot: active if quota > 0, otherwise dormant   │
    │  Settings: orange banner with "Get Pro" button   │
    │  AI quota: 3/month, no count shown to user       │
    └───────────────┬─────────────────────────────────┘
                    │ purchase blinking_pro
                    ▼
    ┌─────────────────────────────────────────────────┐
    │              PRO (lifetime)                      │
    │  ┌─────────────────────────────────────────────┐│
    │  │ AI: pro key auto-applied                    ││
    │  │ Robot: active                               ││
    │  │ All features unlocked permanently           ││
    │  │ Settings: green "Pro — Lifetime" banner     ││
    │  │ 1,200 AI/year quota                         ││
    │  └─────────────────────────────────────────────┘│
    │  BYOK still available as override               │
    └─────────────────────────────────────────────────┘
```

## API Keys

| State | Key | Source |
|-------|-----|--------|
| Trial (preview) | `sk-or-v1-e902497ff66128...` | `--dart-define=TRIAL_API_KEY` |
| Pro (paid) | `sk-or-v1-e75d7a22513229...` | `--dart-define=PRO_API_KEY` |

- Both keys route through `https://openrouter.ai/api/v1`
- Model: `qwen/qwen3.5-flash-02-23`
- BYOK always overrides the built-in key if configured
- No duplication of BYOK in providers list

## Feature Gates

| Feature | Preview | Restricted | Pro | BYOK |
|---------|---------|------------|-----|------|
| Add note/checklist | ✅ | ✅ | ✅ | ✅ |
| Check habit | ✅ | ✅ | ✅ | ✅ |
| View history | ✅ | ✅ | ✅ | ✅ |
| AI assistant | ✅ | ❌ | ✅ | ✅ |
| Edit/delete habit | ✅ | ❌ | ✅ | ✅ |
| Add new habit | ✅ | ❌ | ✅ | ✅ |
| Edit/delete tags | ✅ | ❌ | ✅ | ✅ |
| Edit existing notes | ✅ | ❌ | ✅ | ✅ |
| Backup / Restore | ✅ | ❌ | ✅ | ✅ |
| Share to Chorus | ✅ | ❌ | ✅ | ✅ |
| Insights | ✅ | ❌ | ✅ | ✅ |
| Calendar/heatmap | ✅ | ✅ | ✅ | ✅ |

## UI States

### Settings → AI Section

| State | Banner | Color | Action |
|-------|--------|-------|--------|
| Preview | "21-Day Preview — X days left" + day count | Blue/Purple gradient | None |
| Restricted | "Free Mode — AI: 0/3 month" | Orange | "Get Blinking Pro" button |
| Paid | "Blinking Pro — Lifetime" + quota | Green gradient | None |
| BYOK active | "Using your own key" | Green light | Manage button |

### Floating Robot

| State | Visual | Tap Action |
|-------|--------|------------|
| Preview + quota > 0 | Active (bobbing) | Open AI assistant |
| Preview + quota = 0 | Dormant + warn | "Quota used, refreshes tomorrow" |
| Restricted | Dormant | Open paywall |
| Paid + quota > 0 | Active | Open AI assistant |
| BYOK active | Active | Open AI assistant |

## Implementation Plan

### Phase 1: Auto-Restore & Entitlement Reset (Fix current blockers)

**Files:** `lib/main.dart`

- [ ] 1.1 Reset SharedPreferences entitlement keys + onboarding before auto-restore (DONE in `f54bfc9`)
- [ ] 1.2 Copy backup to app container before rebuild
- [ ] 1.3 Verify data loads on both platforms after rebuild

### Phase 2: AI Key Management

**Files:** `lib/core/services/llm_service.dart`

- [ ] 2.1 Add `PRO_API_KEY` const from `String.fromEnvironment('PRO_API_KEY')`
- [ ] 2.2 `_loadConfig()`: use trial key during preview, pro key when paid, fallback to BYOK
- [ ] 2.3 Remove any stale trial API key references from provider list (no duplication)
- [ ] 2.4 Ensure BYOK takes priority over built-in keys

### Phase 3: Feature Gates

**Files:** `lib/core/services/entitlement_service.dart`

- [ ] 3.1 Verify `canEditNote` gate (should return false for restricted)
- [ ] 3.2 Verify `canAddHabit` gate (should return false for restricted)
- [ ] 3.3 Verify `canBackup` gate (should return false for restricted)
- [ ] 3.4 Add `canEditTag` gate
- [ ] 3.5 Add `canEditHabit` gate
- [ ] 3.6 Apply gates to Settings screen (disable/edit/hide buttons)

### Phase 4: UI Consistency

**Files:** `lib/screens/settings/settings_screen.dart`, `lib/widgets/floating_robot.dart`, `lib/screens/home/home_screen.dart`

- [ ] 4.1 Settings banner: preview → restricted → paid → BYOK (no duplication)
- [ ] 4.2 Floating robot: correct visual state per entitlement
- [ ] 4.3 Home screen: hide edit/delete controls in restricted mode
- [ ] 4.4 Routine tab: hide add/edit controls in restricted mode
- [ ] 4.5 Tags management: hide add/edit/delete in restricted mode

### Phase 5: Onboarding Flow

**Files:** `lib/app.dart`, `lib/screens/onboarding/onboarding_screen.dart`

- [ ] 5.1 Ensure 3-page onboarding shows on fresh install
- [ ] 5.2 Onboarding completion triggers 21-day preview start
- [ ] 5.3 Verify onboarding_completed key is set after onboarding

### Phase 6: Platform Parity

- [ ] 6.1 Build and deploy same code to iOS and Android
- [ ] 6.2 Verify identical behavior on both platforms
- [ ] 6.3 UAT test cases pass on both

## Current Issues to Resolve

| Issue | Platform | Root Cause | Fix |
|-------|----------|------------|-----|
| Data not restored on iOS | iOS | Entitlement resets after `flutter run` creates new container; auto-restore didn't run | Phase 1 |
| Orange restricted banner shows | Both | Old SharedPreferences from previous install | Phase 1 (DONE) |
| 7/6 done count | Android | April 30 included in month filter | Fixed in `b42fe46` |
| AI shows "no API key" | Both | `preview_local` returned empty config | Phase 2 |
| BYOK duplicated in provider list | Both | Merge-on-load appends defaults | Phase 2.3 |

## Build Commands

```bash
# iOS (with auto-restore + trial key)
flutter run -d "iPhone 17 Pro" --debug \
  --dart-define=TRIAL_API_KEY="sk-or-v1-e902497ff66128..." \
  --dart-define=PRO_API_KEY="sk-or-v1-e75d7a22513229..." \
  --dart-define=AUTO_RESTORE="/path/to/auto_restore.zip"

# Android (with auto-restore + trial key)
flutter run -d emulator-5554 --debug \
  --dart-define=TRIAL_API_KEY="sk-or-v1-e902497ff66128..." \
  --dart-define=PRO_API_KEY="sk-or-v1-e75d7a22513229..." \
  --dart-define=AUTO_RESTORE="/data/local/tmp/auto_restore.zip"
```
