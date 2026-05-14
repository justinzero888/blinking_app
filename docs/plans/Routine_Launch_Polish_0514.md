# Routine Launch Polish — Design & Plan

**Date:** 2026-05-14 | **Status:** Design · Pending Implementation

---

## 1. Notification Implementation

### Decision

Implement **local-only notifications** using `flutter_local_notifications`. Zero server interaction, zero data leaves device. Aligned with core privacy claim.

### Design

- **Schedule:** One notification per routine at its `reminderTime`
- **Content:** `"{routine.emoji} {routine.displayName(isZh)}"`
- **Package:** `flutter_local_notifications`
- **Permissions:** `POST_NOTIFICATIONS` (Android 13+), no iOS entitlement needed (local only)
- **Lifecycle:** Rescheduled on app start, on routine create/edit/delete

### Implementation

```
pubspec.yaml: add flutter_local_notifications
lib/core/services/notification_service.dart (NEW)
  - init() — request permissions, configure channels
  - scheduleRoutine(Routine) — schedule daily/weekly/scheduled
  - cancelRoutine(String id) — remove on delete
  - rescheduleAll() — called on app start
```

### Notes

- The existing `reminderTime` helper text "仅本地提醒，不发送任何数据" was already correct — just not implemented
- Weekly routines: schedule for each selected day
- Scheduled (one-time): schedule for the one date
- Ad-hoc: no notification needed
- Timezone-aware: use `tz` package

---

## 2. Category Refresh

### New Category Map

| # | Category | EN | ZH | Icon | Color | Meaning |
|---|----------|----|----|------|-------|---------|
| 1 | `health` | Health | 养 | `assets/icons/health.png` | `#6b8e77` (green) | Nourishing, healing |
| 2 | `fitness` | Fitness | 劲 | `assets/icons/fitness.png` | `#c66b4a` (terracotta) | Strength, fire |
| 3 | `nutrition` | Nutrition | 食 | `assets/icons/nutrition.png` | `#6b8e77` (green) | Food as nourishment |
| 4 | `sleep` | Sleep | 息 | `assets/icons/sleep.png` | `#6b8e77` (green) | Rest, restoration |
| 5 | `mindfulness` | Mind | 心 | `assets/icons/mind.png` | `#c66b4a` (terracotta) | Heart-mind center |
| 6 | `reflection` | Reflection | 省 | `assets/icons/reflection.png` | `#c66b4a` (terracotta) | Self-examination |
| 7 | `restraint` | Restraint | 戒 | `assets/icons/restraint.png` | `#c66b4a` (terracotta) | Vigilance, boundary |
| 8 | `connection` | Connection | 缘 | `assets/icons/connection.png` | `#6b8e77` (green) | Relationships |
| 9 | `other` | Other | 杂 | `assets/icons/other.png` | `#55605a` (gray) | Catch-all |

### Changes from Current

- **Removed:** `social` → replaced by `connection`
- **Removed:** `learning` → can use `mind` or `other`
- **Removed:** `finance` → can use `other`
- **Added:** `reflection` — journaling/self-examination
- **Added:** `restraint` — quitting habits, boundaries
- **Renamed:** `mindfulness` stays but ZH becomes 心 (was empty)
- All categories now have dedicated SVG icons (to be rendered to PNG)

### Code Changes

**`lib/models/routine.dart`:**
- Keep `RoutineCategory` enum but add `reflection` and `restraint`; remove `social`, `learning`, `finance`
- Update `routineCategoryName()` with new ZH values (养, 劲, 食, 息, 心, 省, 戒, 缘, 杂)
- Update `kCategoryIcon` → now maps to icon asset paths instead of emojis:
  ```dart
  const Map<RoutineCategory, String> kCategoryIconPath = {
    RoutineCategory.health: 'assets/icons/health.png',
    ...
  };
  ```
- Update `autoDetectCategory()` keyword mapping

**SQLite:** No migration needed — `category` is stored as TEXT. Old enum values (social, learning, finance) will map to `null` → auto-detect → ⭐ fallback.

**UI:** The category chips in the Add/Edit Routine dialog now show PNG icons instead of emojis + localized names.

---

## 3. Icon Generation

The user provided SVG specs. Steps:
1. Render SVGs to 44×44 PNG at @2x (88×88) for chip display
2. Save to `assets/icons/health.png`, `assets/icons/fitness.png`, etc.
3. Add `assets/icons/` to `pubspec.yaml` (already present)

---

## 4. Default Active / Inactive Routine Set

### Active (seeded for new users, active by default)

| Routine | ZH | EN | Icon | Category | Frequency |
|---------|----|----|------|----------|-----------|
| 早起 | 早起 | Wake Early | 🌅 | health (养) | daily |
| 喝水 | 喝水 | Drink Water | 💧 | nutrition (食) | daily (counter 1500ml) |
| 走路 | 走路 | Walk | 🚶 | fitness (劲) | daily (counter 5000步) |
| 阅读 | 阅读 | Read | 📖 | mind (心) | daily |
| 冥想 | 冥想 | Meditate | 🧘 | mindfulness (心) | daily |
| 感恩 | 感恩 | Gratitude | 🙏 | reflection (省) | daily |

### Inactive (seeded but paused)

| Routine | ZH | EN | Icon | Category | Frequency |
|---------|----|----|------|----------|-----------|
| 多吃菜 | 多吃菜 | Eat Greens | 🥬 | nutrition (食) | daily |
| 拉伸放松 | 拉伸放松 | Stretch | 🧘 | fitness (劲) | weekly |
| 写日记 | 写日记 | Journal | ✍️ | reflection (省) | daily |
| 体重记录 | 体重记录 | Track Weight | ⚖️ | health (养) | weekly |

Rules:
- Active habits: small, achievable, friction-free (5-10 min each)
- Inactive habits: slightly more ambitious, opt-in
- All have proper `name` + `nameEn` fields
- All have `category` set to the new category enum values

---

## Tasks — In Order

| # | Task | Effort |
|---|------|--------|
| 1 | Generate 9 category icon PNGs from SVGs | ~30 min |
| 2 | Update `RoutineCategory` enum + `routineCategoryName()` + `kCategoryIconPath` | ~20 min |
| 3 | Update `autoDetectCategory()` keyword mapping | ~15 min |
| 4 | Update category chips in Add/Edit dialog to use PNG icons | ~15 min |
| 5 | Update seed data (`_getDefaultRoutines()`) with new active/inactive sets | ~15 min |
| 6 | Add `flutter_local_notifications` package | ~5 min |
| 7 | Create `NotificationService` (init, schedule, cancel, reschedule) | ~1 hr |
| 8 | Wire notifications into routine lifecycle (create/edit/delete) | ~20 min |
| 9 | Update `routine_item.dart` locale awareness | ~20 min |
| 10 | Build + UAT all changes on 3 sims | ~30 min |

**Total estimated:** ~4 hours
