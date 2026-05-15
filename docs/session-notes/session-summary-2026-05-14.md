# Blinking — Session Summary 2026-05-14 (Final)

**Version:** 1.1.0+36 | **Tests:** 164/164 | **Lint:** 0 errors  
**GitHub:** ✅ Committed and pushed

---

## Production Builds

| Platform | Build | Size |
|----------|-------|:---:|
| iOS IPA | `build/ios/ipa/blinking.ipa` | — |
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` | 58.6MB |

---

## Completed Today

### Category + Routine Refresh
- 9 category PNG icons (128×128, transparent) from SVGs
- `RoutineCategory` enum: health, fitness, nutrition, sleep, mindfulness, reflection, restraint, connection, other
- Chinese names: 养劲食息心省戒缘杂
- 31 seed routines from `routine_setup_file_0513.json`
- 3 active by default (Drink water, Read 15 min, Write a note), 28 paused
- Category icons in dialog chips only; tabs show routine emojis
- Custom routines default to Other/杂

### Tags Refresh
- 6 default tags: family, insight, gratitude, daily, wellness, learning
- System tags: AI综整 (synthesis, hidden), 私密 (private, locked), 欢迎 (welcome, hidden)
- `tag_reflection` → `tag_synthesis` globally
- `tag_secrets` → `tag_private` globally
- `DefaultTags.defaults` synced

### Chinese Locale + Personas
- 楷迩 (Kael), 依澜 (Elara), 如溯 (Rush), 墨克 (Marcus)
- `nameZh` field, `displayName(isZh)`, CN avatars auto-switch
- System prompts, vibes, lens questions from `AI Personas.json`
- Default persona changed to Kael/楷迩
- Fixed reversed description locale (was showing EN in ZH and vice versa)
- Edit dialog loads + saves locale-aware name/description
- Reminder field: digit-only input, HH:MM format validation

### Private Tag Filter — AI Privacy
- `JarProvider.getDayEmotions()` — excludes `tag_private` emotions
- `ReflectionSessionScreen._loadContextAndGenerate()` — excludes private entries from AI context
- `emoji_jar.dart` Ask AI — excludes private entries
- `cherished_memory_screen.dart` Annual Reflection — excludes private entries
- `AssistantScreen` — already had filter (dormant, not reachable)
- Daily reflection counter only increments on API success (not timeout)

### Notifications
- `flutter_local_notifications` integration (local-only)
- `NotificationService`: init, scheduleRoutine, cancelRoutine, rescheduleAll
- One-shot scheduling (no `matchDateTimeComponents` — broken on iOS)
- Daily repeat via reschedule on app launch (`rescheduleAll()` in `loadRoutines()`)
- Fixed: timezone detection (EDT → America/New_York)
- Fixed: `cancelAll()` race condition removed from `rescheduleAll()`
- Verified: fires when app in background (browser, home screen, other apps)
- Behavior: notification fires once at reminder time; reschedules on next app launch
- Known: suppresses in foreground (standard iOS behavior — intentional UX)

### UAT Fixes
- `routine_item.dart` locale-aware (6 hardcoded EN strings)
- Reminder format validation (HH:MM, no garbage input)
- Description locale display fixed (was reversed)

### Audit
- CLAUDE.md: version, tests, persona, price, stable tag ID updated
- `DefaultTags.defaults` synced (was stale with 8 old tags)
- 5 AI entry points audited for private tag filtering
- AI benchmark: $0.00014/call, $0.01/trial, ~7s avg

---

## Known Limitations

| Item | Detail |
|------|--------|
| Notifications | Fire in background only (standard iOS). Reschedule on app launch for daily repeat. |
| Android notifications | Untested on emulator (needs Play Services). APK built, real device TBD. |
| `matchDateTimeComponents` | Broken on iOS. Workaround: one-shot + reschedule on launch. |
| `Icon accessibility` | Android emulator icon cache persistent. Source files verified correct. |

---

## Remaining (P2/P3)

| # | Item |
|---|------|
| D1 | Personas web page `blinkingchorus.com/personas` |
| G2 | Hardcoded receipt string in server validation |
| G3 | `addCustomerInfoUpdateListener` in RevenueCat |

---

## App Review Status

| Store | Status |
|-------|--------|
| iOS App Store | ✅ Approved — 1.1.0 ready for distribution |
| Google Play | Submitted for review |
