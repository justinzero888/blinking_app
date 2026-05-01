# PROP-6 Trial API Key Flow — UAT Test Cases

> **Test Date:** 2026-04-30
> **Version:** 1.1.0-beta.4+19
> **Backend:** Mock (no real backend yet — trial start will fail with network error)

## Prerequisites
- Fresh install of the app on test device/emulator
- No llm_providers configured (default state)
- Internet access (for future real backend testing)

---

## UAT-1: Trial Banner — Initial State (No Trial)

**Given:** Fresh install, no trial data
**When:** Navigate to Settings → AI Provider section
**Then:**
- [ ] Purple/blue gradient banner is visible: "Try AI for Free — 7 Days" / "免费试用 AI — 7 天"
- [ ] Subtitle: "No setup needed. Start chatting now." / "无需设置，立即开始聊天。"
- [ ] Blue "Start Free Trial →" / "开始免费试用 →" button is visible and active
- [ ] Trial provider is NOT in the provider list
- [ ] Standard 4 providers (Open Router, OpenAI, Claude, Gemini) are visible below
- [ ] Floating robot shows grey `!` badge (no API key)
- [ ] Tapping robot shows snackbar about adding API key

---

## UAT-2: Start Trial Button States

**Given:** Fresh install, trial banner showing "Start Free Trial →"
**When:** Tap "Start Free Trial →" button
**Then:**
- [ ] Button shows loading spinner (CircularProgressIndicator, white)
- [ ] Button is disabled during loading
- [ ] On backend response: screen updates to show active trial state OR error message
- [ ] (Currently expected: network error snackbar because backend not deployed)
- [ ] After error/dismiss: button returns to enabled state

---

## UAT-3: Trial Banner — Active Trial State

**Given:** Trial token and started_at are set in SharedPreferences (manually set for testing, or real backend response)
**When:** Navigate to Settings → AI Provider section
**Then:**
- [ ] Green banner is visible: "✅ Trial Active — X days remaining"
- [ ] Subtitle: "20 requests/day · You can add your own key anytime"
- [ ] No "Start Free Trial" button (action area is just info)
- [ ] Trial provider "7-Day Trial" / "7 天试用" appears at top of provider list
- [ ] Trial provider has green "Trial" / "试用" chip badge
- [ ] Trial provider shows "X days remaining · 20 requests/day" subtitle
- [ ] Trial provider has info icon (ℹ) instead of edit icon
- [ ] Tapping info icon shows read-only trial details dialog
- [ ] User providers below trial entry remain functional

---

## UAT-4: Trial Banner — Expired Trial State

**Given:** Trial started_at is set to 8+ days ago in SharedPreferences
**When:** Navigate to Settings → AI Provider section
**Then:**
- [ ] Orange banner is visible: "⏰ Trial Expired" / "⏰ 试用已过期"
- [ ] Subtitle guides user to add own API key
- [ ] "Get a free key →" / "免费获取 Key →" button opens openrouter.ai/keys
- [ ] Trial provider is NOT in the provider list (removed after expiry)
- [ ] Floating robot shows grey state with 🕐 badge
- [ ] Tapping robot shows snackbar: "Your trial has ended. Add your API key..."

---

## UAT-5: Trial Provider Info Dialog

**Given:** Trial is active, trial provider visible in list
**When:** Tap ℹ info icon on trial provider
**Then:**
- [ ] Dialog titled "Trial Details" / "试用详情" opens
- [ ] Shows model: qwen/qwen3.5-flash
- [ ] Shows "Proxied by Blinking trial backend"
- [ ] Shows rate limit info: "20 requests/day for 7 days"
- [ ] Shows "Trial provider cannot be edited."
- [ ] "Close" / "关闭" button dismisses dialog

---

## UAT-6: Floating Robot — Trial Active

**Given:** Trial is active, no user API key configured
**When:** View Calendar/Moments/Routine tabs
**Then:**
- [ ] Robot shows FULL COLOR (animated: bobbing, pulsing)
- [ ] No `!` or 🕐 badge
- [ ] Tapping robot opens AssistantScreen (no snackbar)
- [ ] Send a message in assistant: trial token is used for API call

---

## UAT-7: Floating Robot — Trial Expired

**Given:** Trial is expired (8+ days), no user API key configured
**When:** View Calendar/Moments/Routine tabs
**Then:**
- [ ] Robot shows GREY (50% opacity, no animation)
- [ ] Grey 🕐 badge (not orange `!`)
- [ ] Tapping robot shows snackbar about trial expired (different from "no key" message)

---

## UAT-8: AssistantScreen — Trial Expiry Banner

**Given:** Trial just expired, user opens assistant (or trial expires mid-session)
**When:** User sends a message and receives trial_expired error
**Then:**
- [ ] Orange banner appears at top of chat (below quick actions, above messages)
- [ ] Banner text: "Your 7-day trial has ended. Add your own API key..."
- [ ] "Settings →" / "设置 →" button pops back to main screen
- [ ] × dismiss button hides banner
- [ ] Next failed request: banner reappears

---

## UAT-9: Language Switching

**Given:** Trial banner is visible in English
**When:** Switch app language to Chinese (设置 → 通用设置 → 语言 → 中文)
**Then:**
- [ ] Trial banner text switches to Chinese
- [ ] Trial provider shows "7 天试用" with "试用" chip
- [ ] Trial info dialog shows Chinese text
- [ ] Switch back to English: all text reverts
- [ ] Robot snackbar messages use correct language

---

## UAT-10: Export/Import — Trial Data Excluded

**Given:** Trial is active (trial_token set in SharedPreferences)
**When:** Export a full backup (ZIP) and then inspect or restore on same device
**Then:**
- [ ] Backup ZIP does NOT contain trial_token or trial_started_at
- [ ] After restore: trial data is unchanged (still active, same token)
- [ ] After restore: persona data (name, personality, avatar) is restored correctly

---

## UAT-11: User Has Own API Key — Trial Coexistence

**Given:** User has configured a valid API key (e.g., OpenRouter with real key)
**When:** Navigate to Settings → AI Provider
**Then:**
- [ ] Trial banner shows as normal (start/active/expired based on state)
- [ ] Selected user provider shows "Active" / "使用中" chip
- [ ] Trial provider shows info icon (not radio button)
- [ ] Robot shows active (user key works)
- [ ] Assistant uses user's own API key, not trial

---

## UAT-12: Reinstall / Clear Data

**Given:** App has used trial, trial is expired
**When:** Clear all app data (via Android Settings → Apps → Blinking → Clear Data)
**Then:**
- [ ] App generates new device_id on fresh launch
- [ ] Trial banner shows "Start Free Trial →" (server-enforced — actual start depends on backend)
- [ ] Previous trial token is gone (cleared with SharedPreferences)

---

## Smoke Test Verification

- [ ] `flutter analyze --no-pub` — 0 errors
- [ ] `flutter test` — all 94 tests pass
- [ ] App launches without crash
- [ ] Bottom nav: all 5 tabs work
- [ ] FAB works for adding entries
- [ ] Existing features (calendar, moments, routine, keepsakes, settings) unaffected
