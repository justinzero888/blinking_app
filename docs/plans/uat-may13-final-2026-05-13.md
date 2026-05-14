# UAT — May 13 Final (Build 1.1.0+36)

**Devices:** iPhone 17 Pro · iPad Air 11" (M4) · Android Emulator  
**Build:** `flutter build --debug --simulator` · RevenueCat Test Store

---

## UAT-A: Avatars (Task 2)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| A.1 | Launch → onboarding → main screen | Floating robot shows style avatar (not 🤖 emoji) | |
| A.2 | Settings → AI tab | Preview card shows avatar image for active style | |
| A.3 | Tap different style (e.g., Rush ⚡) | Preview card avatar + floating robot update | |
| A.4 | Tap floating robot → chat | AppBar shows avatar | |
| A.5 | Robot menu → Reflection | AppBar CircleAvatar shows avatar | |

---

## UAT-B: Welcome Entry (Task 3)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| B.1 | Fresh install → complete onboarding | Main screen appears | |
| B.2 | My Day tab | Welcome entry "Welcome to Blinking Notes ✨" with tag Welcome | |
| B.3 | Welcome content | Lists: Jot, Habits, Insights, AI Companion | |
| B.4 | Force-kill app → reopen | Welcome entry NOT duplicated (single entry) | |

---

## UAT-C: Custom AI Persona (Task 5)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| C.1 | Settings → AI → "Create Custom Style" | Full-screen form opens: AppBar "Custom Style", Cancel | |
| C.2 | Enter Name: "Vesper" | Accepts text | |
| C.3 | Enter Style: "Slow & Meditative" | Vibe field below name | |
| C.4 | Tap Upload Image → pick photo | Circular preview shows, emoji grid hidden | |
| C.5 | Tap Clear on image preview | Emoji grid returns | |
| C.6 | Tap emoji in grid | Selected emoji highlights orange | |
| C.7 | Enter Personality text | 150 char max enforced | |
| C.8 | Enter 3 Lens questions | All fields accept text | |
| C.9 | Tap Save with empty Name | "Name is required" snackbar | |
| C.10 | Tap Save with empty Lens | "All 3 lenses are required" snackbar | |
| C.11 | Fill all fields → Save | "Custom style saved" snackbar, card appears | |
| C.12 | Custom style card | Shows name "Vesper", vibe "Slow & Meditative", emoji | |
| C.13 | Tap custom style card | Style activates, preview card updates | |
| C.14 | Tap edit icon ✏️ on card | Form opens pre-filled with current values | |
| C.15 | Tap delete 🗑 → confirm | Style removed, reverts to Elara | |
| C.16 | Cancel button (AppBar) | Returns to settings without saving | |

---

## UAT-D: Routine History Fix (Task 7)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| D.1 | Routine tab → Reflect | Shows only dates from routine creation onward | |
| D.2 | Create a routine today → Reflect | Shows exactly today (1 day of history) | |
| D.3 | Insights → charts | Charts start from earliest data, no empty months | |

---

## UAT-E: Restricted Mode (Task 8)

Toggle: Settings → About → tap version 5x → "Switched to restricted mode"

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| E.1 | Routine FAB (+) | Paywall opens | |
| E.2 | Build tab → edit (⋮) on habit | Paywall opens | |
| E.3 | Build tab → toggle active switch | Paywall opens | |
| E.4 | Do tab → Manual Add | Paywall opens | |
| E.5 | Settings → Full Backup (ZIP) | Paywall opens | |
| E.6 | Settings → Export CSV | Paywall opens | |
| E.7 | Settings → Export JSON | Paywall opens | |
| E.8 | Settings → Restore Data | Paywall opens | |
| E.9 | Settings → Export Habits | Paywall opens | |
| E.10 | Settings → Import Habits | Paywall opens | |
| E.11 | Insights → Annual Reflection → Generate | Paywall opens | |
| E.12 | Floating robot | Dormant (no bobbing), tap → paywall | |
| E.13 | Entry FAB (+) add new entry | Works normally (allowed) | |
| E.14 | Check existing habits | Works normally (allowed) | |
| E.15 | Settings → AI tab | Locked banner: "AI features require Pro" + Get Pro button | |
| E.16 | Settings → Tags tab | Lock icon + "Upgrade to Pro" instead of "Add Tag" | |
| E.17 | Data portability: tap → cancel → tap again | Second tap goes straight to paywall | |

Toggle back: tap version 5x → preview mode restored

---

## UAT-F: Paywall (IAP Fix)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| F.1 | Restricted → dormant robot → Paywall | "Get Pro — $19.99" button enabled | |
| F.2 | No orange "Store unavailable" message | No warning text below button | |
| F.3 | Tap "Get Pro" | Spinner appears immediately, button disabled | |
| F.4 | Restore button during purchase | Greyed out | |
| F.5 | Back/Close buttons | Disabled during purchase | |
| F.6 | Test Store dialog | 3-button dialog appears | |
| F.7 | Tap "Test valid purchase" | "Welcome to Pro!" green snackbar, paywall dismisses | |
| F.8 | No debug SnackBar | No "Purchase returned: info=..." message | |
| F.9 | Cancel purchase | Button re-enables, no error message | |
| F.10 | iPad landscape | No layout overflow, full-width buttons | |

---

## UAT-G: Annual Reflection (Task 1)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| G.1 | Insights → scroll bottom | Annual Reflection card visible | |
| G.2 | < 30 entries | Button grey "Need more entries for annual review" | |
| G.3 | > 30 entries | Button enabled "Generate Annual Reflection" | |

---

## UAT-H: Trial + Banner

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| H.1 | Settings → AI banner | "21-Day Preview — X days left" | |
| H.2 | Robot long-press | "Preview: X days left" in menu | |
| H.3 | 5x tap: preview → restricted → preview | Preview banner returns | |
