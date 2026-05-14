# UAT — May 12 Changes (Build 1.1.0+36)

**Devices:** iPhone 17 Pro Simulator, iPad Air 11" (M4) Simulator, Android Emulator  
**Build:** `flutter build ios --debug --simulator` / `flutter build apk --debug`  
**RevenueCat:** Test Store key (no RC_API_KEY — simulator builds use `test_` key)

---

## UAT-1: Avatars (Task 2)

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 1.1 | Launch app → onboarding → main screen | Floating robot shows style avatar (not 🤖 emoji) | | | |
| 1.2 | Settings → AI tab | Active style preview card shows style avatar image | | | |
| 1.3 | Style selection cards | Each card shows the correct avatar (Kael 📝, Elara 🌿, Rush ⚡, Marcus ⚔️) | | | |
| 1.4 | Select different style (e.g., Kael) | Preview card updates; floating robot updates avatar | | | |
| 1.5 | Tap floating robot → AssistantScreen | AppBar shows avatar if style avatar exists, or style icon | | | |
| 1.6 | Reflection Session (via robot menu) | AppBar CircleAvatar shows style avatar | | | |

---

## UAT-2: Welcome Entry (Task 3)

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 2.1 | Delete app + reinstall (or reset prefs) | Fresh onboarding appears | | | |
| 2.2 | Complete onboarding | Main screen appears | | | |
| 2.3 | Go to My Day tab | **Welcome entry visible** titled "Welcome to Blinking Notes ✨" with instructions and tag "Welcome" | | | |
| 2.4 | Delete + reinstall again → complete onboarding | Welcome entry should NOT appear a second time (seeded flag) | | | |

---

## UAT-3: Custom AI Persona (Task 5)

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 3.1 | Settings → AI tab → scroll to style selection | "Create Custom Style" button visible below the 4 presets | | | |
| 3.2 | Tap "Create Custom Style" | Full-screen form opens with AppBar: title "Custom Style", Cancel button, Save button at bottom | | | |
| 3.3 | Tap Save with empty Name | Red snackbar "Name is required" | | | |
| 3.4 | Tap Save with empty Lenses | Red snackbar "All 3 lenses are required" | | | |
| 3.5 | Fill all fields → Save | Green snackbar "Custom style saved" | | | |
| 3.6 | Check style picker | Custom style card appears with edit + delete icons | | | |
| 3.7 | Tap custom style card | Style activates, preview card updates, check_circle appears | | | |
| 3.8 | Tap edit icon on custom card | Full-screen form re-opens with current values pre-filled | | | |
| 3.9 | Edit + save | Values update, card reflects changes | | | |
| 3.10 | Tap delete icon → confirm | Style removed, reverts to Elara, custom card gone | | | |
| 3.11 | Personality field limit | Cannot exceed 150 characters | | | |
| 3.12 | Vibe field appears below name | "Style (vibe)" input with hint "e.g. Slow & Meditative" | | | |
| 3.13 | Avatar section | Upload Image button + emoji grid (32 options) with selected preview | | | |

---

## UAT-4: Routine History Fix (Task 7)

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 4.1 | Routine tab → Reflect tab | Only shows dates from routine creation onward (not 60 blank days) | | | |
| 4.2 | Quick test: create a new routine today | Reflect tab shows exactly 1 day (today) | | | |
| 4.3 | Insights tab → Summary charts | Charts start from earliest data, not 6 months of empty bars | | | |

---

## UAT-5: Restricted Mode Gates (Task 8)

First toggle to restricted: Settings → About → tap version 5x → "Switched to restricted mode"

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 5.1 | Routine tab FAB (+) tap | Paywall opens (blocks adding habits) | | | |
| 5.2 | Routine → Build tab → tap edit (⋮) on a habit | Paywall opens (blocks editing) | | | |
| 5.3 | Routine → Build tab → toggle active/inactive switch | Paywall opens (blocks toggle) | | | |
| 5.4 | Routine → Do tab → tap "Manual Add" button | Paywall opens (blocks manual add) | | | |
| 5.5 | Settings → tap "Full Backup (ZIP)" | Paywall opens (blocks backup) | | | |
| 5.6 | Settings → tap "Export to CSV" | Paywall opens (blocks export) | | | |
| 5.7 | Settings → tap "Export to JSON" | Paywall opens (blocks export) | | | |
| 5.8 | Settings → tap "Restore Data" | Paywall opens (blocks restore) | | | |
| 5.9 | Settings → tap "Export Habits" | Paywall opens (blocks habit export) | | | |
| 5.10 | Settings → tap "Import Habits" | Paywall opens (blocks habit import) | | | |
| 5.11 | Insights → Annual Reflection → tap "Generate" | Paywall opens (blocks AI generation) | | | |
| 5.12 | Floating robot | Dormant (no bobbing), tap → paywall | | | |
| 5.13 | Entry FAB (+) and checking existing habits | Still allowed (no gate) | | | |
| 5.14 | Settings → AI tab in restricted mode | Shows "AI features require Pro" locked banner with "Get Pro" button | | | |
| 5.15 | Settings → Tags tab in restricted mode | "Add Tag" shows lock icon + "Upgrade to Pro" text | | | |
| 5.16 | Data portability — tap backup, cancel dialog → tap again | Second tap goes straight to paywall (no dead tap) | | | |

Toggle back to preview: Settings → About → tap version 5x → all gates lifted.

---

## UAT-6: Annual Reflection (Task 1) — Logic Only

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 6.1 | Insights → Annual Reflection card | Visible at bottom of Insights | | | |
| 6.2 | With < 30 total entries | "Generate" button shows "Need more entries" (grey) | | | |
| 6.3 | With > 30 entries (seed data has entries) | Button enabled "Generate Annual Reflection" | | | |

---

## UAT-7: Paywall UI (IAP Fix)

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 7.1 | Toggle to restricted → tap dormant robot → Paywall | Paywall appears with "Get Pro" button ENABLED | | | |
| 7.2 | Check NO "Store unavailable" orange message | No orange warning (Test Store works) | | | |
| 7.3 | Tap "Get Pro" | Button shows **spinner** immediately, button disabled | | | |
| 7.4 | "Restore Purchases" during purchase | Also disabled (greyed out) | | | |
| 7.5 | Back/Close buttons in AppBar | Disabled during purchase | | | |
| 7.6 | Test Store dialog appears | 3-button dialog shown with purchase options | | | |
| 7.7 | Tap "Test valid purchase" | "Welcome to Pro!" green snackbar, paywall dismisses | | | |
| 7.8 | **NO debug SnackBar** | No "Purchase returned: info=..." message | | | |
| 7.9 | Cancel purchase (Test Store → Cancel) | Button re-enables, no error message | | | |
| 7.10 | iPad: paywall in landscape | Layout fits, no overflow, full-width buttons | | | |
| 7.11 | iPad: system purchase dialog | Full IAP sheet, not clipped | | | |

---

## UAT-8: Trial Duration (Task 4) — Verify Only

| # | Step | Expected | iPhone | iPad | Android |
|---|------|----------|--------|------|---------|
| 8.1 | Settings → AI banner | "21-Day Preview" with countdown | | | |
| 8.2 | Settings → About → tap version 5x twice (preview → restricted → preview) | Preview banner returns | | | |  
| 8.3 | Robot long-press menu in preview mode | "Preview: X days left" shown | | | |

---

## Quick Reference

| Action | How |
|--------|-----|
| Force restricted | Settings → About → tap version 5x |
| Force preview | Settings → About → tap version 5x again |
| Reinstall app | `xcrun simctl uninstall booted com.blinking.blinking && xcrun simctl install booted build/ios/iphonesimulator/Runner.app` |
| Android reinstall | `adb -s emulator-5554 uninstall com.blinking.blinking && adb -s emulator-5554 install build/app/outputs/flutter-apk/app-debug.apk` |
