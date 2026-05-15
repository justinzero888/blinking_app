# UAT — May 14/15 Changes (Final)

**Build:** 1.1.0+38 | **Tests:** 440/440 | **Lint:** 0 errors  
**Devices:** iPhone 17 Pro · iPad Air 11" (M4) · Android

---

## UAT-1: Multi-Custom Persona

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 1.1 | Settings → AI → scroll down | Presets: 楷迩, 依澜, 如溯, 墨克 | |
| 1.2 | Create Custom Style — fill name, vibe, emoji, personality, 3 lenses | Save → style card appears as custom_0 | |
| 1.3 | Create second custom style | Second card appears as custom_1 | |
| 1.4 | Activate custom_0 | Preview card shows custom_0 name/vibe/lenses | |
| 1.5 | Activate custom_1 | Preview card switches to custom_1 | |
| 1.6 | Edit custom_0 | Form opens pre-filled, save preserves data | |
| 1.7 | Delete custom_1 | Card removed, reverts to default if active | |
| 1.8 | Upload image for custom style | Avatar shows on form preview, custom card, floating robot | |
| 1.9 | Switch to preset → back to custom | Custom style + lenses preserved | |

## UAT-1B: Persona-Specific Lens Mapping

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 1B.1 | Activate Kael → tap robot | Lens questions match Kael (facts, learning, control) | |
| 1B.2 | Activate Elara → tap robot | Lens questions match Elara (heart, care, forgive) | |
| 1B.3 | Activate Rush → tap robot | Lens questions match Rush (head, avoid, unfiltered) | |
| 1B.4 | Activate Marcus → tap robot | Lens questions match Marcus (change, desire, face) | |
| 1B.5 | Activate custom with own lenses | Lens questions match custom style's lenses | |
| 1B.6 | Switch between personas | Lenses change each time | |

## UAT-2: Private Tag AI Filter

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 2.1 | Add entry tagged #私密 with content "secret" | Entry shows lock icon | |
| 2.2 | Add open entry | No lock icon | |
| 2.3 | Tap floating robot (Daily Reflection) | AI never references "secret" content | |
| 2.4 | Emoji jar → Ask AI | AI never references "secret" | |
| 2.5 | Scenarios → Annual Reflection → Generate | AI never references "secret" | |
| 2.6 | Private tag #私密 visible in tag picker | Selectable, shows in list | |
| 2.7 | #AI综整, #欢迎 NOT in tag picker | Hidden from add-entry screen | |

## UAT-3: Notifications

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 3.1 | Create routine → reminder 2 min from now | 📢 log shows "Scheduled: ..." | |
| 3.2 | Wait for time | Banner appears in background | |
| 3.3 | Reminder field validation | Only digits + colon accepted, HH:MM required | |
| 3.4 | Reminder cleared → saved | Old notification cancelled | |

## UAT-4: Category + Routine Refresh

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 4.1 | Fresh install → Routine → Build | 31 routines, 3 active (喝水, 读书15分钟, 写一则笔记) | |
| 4.2 | Category names (EN) | Health, Fitness, Nutrition, Sleep, Mind, Reflection, Restraint, Connection | |
| 4.3 | Category names (ZH) | 养, 劲, 食, 息, 心, 省, 戒, 缘 | |
| 4.4 | Add/Edit dialog category chips | Show PNG icons with locale names | |
| 4.5 | Custom routine no category | Defaults to Other/杂 | |
| 4.6 | Descriptions locale-aware | ZH shows Chinese, EN shows English | |

## UAT-5: Default Persona + Locale

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 5.1 | Fresh install → default persona | Kael/楷迩 active | |
| 5.2 | Style selection cards (ZH) | Show Chinese names 楷迩, 依澜, 如溯, 墨克 | |
| 5.3 | Style selection cards (EN) | Show English names Kael, Elara, Rush, Marcus | |
| 5.4 | Edit dialog (ZH) | Name + Why fields show Chinese text | |
| 5.5 | Edit dialog (EN) | Name + Why fields show English text | |

## UAT-6: Restricted Mode Gates (Regression)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 6.1 | 5x tap → restricted | All gates from May 13 UAT still work | |
| 6.2 | AI tab shows locked banner | "AI features require Pro" | |
| 6.3 | Tags tab shows lock icon | "Upgrade to Pro" text | |

## UAT-7: Feedback + About

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 7.1 | Settings → About → version | Shows from AppConstants.appVersion | |
| 7.2 | Send Feedback | Opens mail or shows fallback snackbar | |

## UAT-8: Paywall + IAP (Regression)

| # | Step | Expected | ✅ |
|---|------|----------|:--:|
| 8.1 | Restricted → robot → Paywall | Loading spinner, button disable, cancel works | |
| 8.2 | Test Store purchase | "Welcome to Pro!" snackbar | |
