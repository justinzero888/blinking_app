# UAT — May 13 Final (Build 1.1.0+36)

**Devices:** iPhone 17 Pro · iPad Air 11" (M4) · Android Emulator  
**Build:** `flutter build --debug --simulator` · RevenueCat Test Store

---

## UAT-A: Avatars (Task 2)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| A.1 | Launch → onboarding → main screen | Floating robot shows style avatar (not 🤖 emoji) | | x default is Elara. Note: may want different set of avatars for Chinese version. 
| A.2 | Settings → AI tab | Preview card shows avatar image for active style | | x confirmed that default Elara is selected
| A.3 | Tap different style (e.g., Rush ⚡) | Preview card avatar + floating robot update | | x toggle through different styles and confirm the avatar and robot update
| A.4 | Tap floating robot → chat | AppBar shows avatar | | x confirmed that the avatar is displayed in the chat screen
| A.5 | Robot menu → Reflection | AppBar CircleAvatar shows avatar | | x confirmed that the avatar is displayed in the reflection screen

---

## UAT-B: Welcome Entry (Task 3)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| B.1 | Fresh install → complete onboarding | Main screen appears | | x confirmed that the main screen appears after onboarding
| B.2 | My Day tab | Welcome entry "Welcome to Blinking Notes ✨" with tag Welcome | | x confirmed that the welcome entry is displayed in the main screen
| B.3 | Welcome content | Lists: Jot, Habits, Insights, AI Companion | | x confirmed that the welcome content is displayed in the main screen
| B.4 | Reinstall → complete onboarding again | No second welcome entry | | x  force stop and start the app with Android version. After that, the app and its data all returned to before force stop

---

## UAT-C: Custom AI Persona (Task 5)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| C.1 | Settings → AI → "Create Custom Style" | Full-screen form opens: AppBar "Custom Style", Cancel | | x 
| C.2 | Enter Name: "Vesper" | Accepts text | | x 
| C.3 | Enter Style: "Slow & Meditative" | Vibe field below name | | x
| C.4 | Tap Upload Image → pick photo | Circular preview shows, emoji grid hidden | | x
| C.5 | Tap Clear on image preview | Emoji grid returns | |
| C.6 | Tap emoji in grid | Selected emoji highlights orange | |
| C.7 | Enter Personality text | 150 char max enforced | |
| C.8 | Enter 3 Lens questions | All fields accept text | |
| C.9 | Tap Save with empty Name | "Name is required" snackbar | | x
| C.10 | Tap Save with empty Lens | "All 3 lenses are required" snackbar | | x
| C.11 | Fill all fields → Save | "Custom style saved" snackbar, card appears | | x
| C.12 | Custom style card | Shows name "Vesper", vibe "Slow & Meditative", emoji | | x
| C.13 | Tap custom style card | Style activates, preview card updates | | x
| C.14 | Tap edit icon ✏️ on card | Form opens pre-filled with current values | | x
| C.15 | Tap delete 🗑 → confirm | Style removed, reverts to Elara | |
| C.16 | Cancel button (AppBar) | Returns to settings without saving | |

Question: What is the logic for creating system prompt with the custom persona?
---

## UAT-D: Routine History Fix (Task 7)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| D.1 | Routine tab → Reflect | Shows only dates from routine creation onward | | x
| D.2 | Create a routine today → Reflect | Shows exactly today (1 day of history) | |
| D.3 | Insights → charts | Charts start from earliest data, no empty months | | x

---

## UAT-E: Restricted Mode (Task 8)

Toggle: Settings → About → tap version 5x → "Switched to restricted mode"

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| E.1 | Routine FAB (+) | Paywall opens | | x
| E.2 | Build tab → edit (⋮) on habit | Paywall opens | | x 
| E.3 | Build tab → toggle active switch | Paywall opens | | x
| E.4 | Do tab → Manual Add | Paywall opens | | x 
| E.5 | Settings → Full Backup (ZIP) | Paywall opens | |
| E.6 | Settings → Export CSV | Paywall opens | |
| E.7 | Settings → Export JSON | Paywall opens | |
| E.8 | Settings → Restore Data | Paywall opens | |
| E.9 | Settings → Export Habits | Paywall opens | |
| E.10 | Settings → Import Habits | Paywall opens | | x
| E.11 | Insights → Annual Reflection → Generate | Paywall opens | |
| E.12 | Floating robot | Dormant (no bobbing), tap → paywall | | x this is validated on My Day tab. However, on Moment tab, the robot is showing system default avatar instead of the selected avatar.
| E.13 | Entry FAB (+) add new entry | Works normally (allowed) | | x
| E.14 | Check existing habits | Works normally (allowed) | | x
| E.15 | Settings → AI tab | Locked banner: "AI features require Pro" + Get Pro button | | x
| E.16 | Settings → Tags tab | Lock icon + "Upgrade to Pro" instead of "Add Tag" | | x
| E.17 | Data portability: tap → cancel → tap again | Second tap goes straight to paywall | | x

Toggle back: tap version 5x → preview mode restored
Note: when toggling back to preview mode, the robot is showing system default avatar instead of the selected avatar. this is the case for both My Day and Moment tabs.  
---

## UAT-F: Paywall (IAP Fix)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| F.1 | Restricted → dormant robot → Paywall | "Get Pro — $19.99" button enabled | | x
| F.2 | No orange "Store unavailable" message | No warning text below button | | x
| F.3 | Tap "Get Pro" | Spinner appears immediately, button disabled | | x
| F.4 | Restore button during purchase | Greyed out | | x
| F.5 | Back/Close buttons | Disabled during purchase | | x
| F.6 | Test Store dialog | 3-button dialog appears | | x
| F.7 | Tap "Test valid purchase" | "Welcome to Pro!" green snackbar, paywall dismisses | | x
| F.8 | No debug SnackBar | No "Purchase returned: info=..." message | | x
| F.9 | Cancel purchase | Button re-enables, no error message | | x
| F.10 | iPad landscape | No layout overflow, full-width buttons | | x

Note: after the purchase is made, change to restricted mode and go throught the purchase flow, the "restore purchase" button is active, when tapped, it will show "No previous purchases found" snackbar.  
---

## UAT-G: Annual Reflection (Task 1)

| # | Step | Expected | ✅ |    
|---|------|----------|:--:|
| G.1 | Insights → scroll bottom | Annual Reflection card visible | | x
| G.2 | < 30 entries | Button grey "Need more entries for annual review" | |
| G.3 | > 30 entries | Button enabled "Generate Annual Reflection" | | x validated on iPhone sim with generated data entries. However, after save the annual reflection, the button is still enabled. This led to save the same annual reflection twice or potential more times.  Need to disable the button after save the annual reflection.  

---

## UAT-H: Trial + Banner

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| H.1 | Settings → AI banner | "21-Day Preview — X days left" | | Failed. Did not find "21-Day Preview - X days left" banner on Settings → AI tab. 
| H.2 | Robot long-press | "Preview: X days left" in menu | | Failed. Did not find "Preview: X days left" in menu. The message says: "Trial Active - All features available."
| H.3 | 5x tap: preview → restricted → preview | Preview banner returns | | Partially Failed. The banner returns, but the message is "Trial Active - All features available." instead of "21-Day Preview - X days left".  The robot is showing system default avatar instead of the selected avatar. 

## Other observations: 
- 1. iOS App icon is not per Apple spec. Current icon is a circle with rounded corners, but it should be a square with rounded corners.  
