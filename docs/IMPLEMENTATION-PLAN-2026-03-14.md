# Implementation Plan — 2026-03-14 Feature Set

**Based on:** `docs/TODO-2026-03-14.md`
**PM answers incorporated:** 2026-03-14
**Status:** Ready for implementation

---

## 1. Navigation Architecture (breaking change — do first)

The most structurally impactful decision from the PM answers is **Q7**: the AI Assistant tab is removed from the bottom nav and replaced with a floating animated robot. A new "Cherished Memory" (珍藏) tab takes its slot.

### Current nav (5 tabs)
```
Calendar | Moment | Routine | AI Assistant | Settings
```

### New nav (5 tabs + floating robot)
```
Calendar | Moment | Routine | 珍藏 | Settings
                                       [🤖 floating animated robot — AI chat]
```

The current `FloatingActionButton` (Add Note) stays. The robot is a **separate** overlay widget, positioned bottom-right above the FAB or at a distinct corner.

**`lib/app.dart` changes:**
- Remove `AssistantScreen` from `_screens` list
- Add `CherishedMemoryScreen` (new) to slot 4
- Update bottom nav label/icon: `Icons.auto_awesome` or `Icons.favorite_border`, label "珍藏"
- Add a global `FloatingRobotWidget` overlaid on `MainScreen`'s `Scaffold`

**`lib/screens/cherished/cherished_memory_screen.dart`** — new tabbed screen with three sub-sections:
- **Shelf** (yearly emoji jars)
- **Cards** (card folders)
- **Summary** (visual charts)

---

## 2. Feature Plans

---

### A1 — Routine auto-detect icon (Small)

**PM decision:** Auto-detect type via keyword matching; user can override.

**Design:**
Define a `RoutineCategory` enum and a keyword → category map. When a routine is created or its name is edited, run a keyword match pass to suggest a category and default icon. The creation/edit dialog shows a category chip row the user can tap to override.

```dart
enum RoutineCategory { health, sleep, work, learning, fitness, family, custom }

const Map<RoutineCategory, String> kCategoryIcon = {
  RoutineCategory.health:   '💊',
  RoutineCategory.sleep:    '😴',
  RoutineCategory.work:     '💼',
  RoutineCategory.learning: '📚',
  RoutineCategory.fitness:  '🏃',
  RoutineCategory.family:   '👨‍👩‍👧',
  RoutineCategory.custom:   '⭐',
};

const Map<RoutineCategory, List<String>> kCategoryKeywords = {
  RoutineCategory.health:   ['维生素', '药', 'vitamin', 'medicine', 'water', '喝水', '步', 'steps'],
  RoutineCategory.sleep:    ['睡眠', '睡觉', 'sleep', 'bed', '早起'],
  RoutineCategory.work:     ['工作', 'work', 'meeting', '会议', '汇报'],
  RoutineCategory.learning: ['学习', 'study', 'read', '阅读', '英语', 'english'],
  RoutineCategory.fitness:  ['运动', 'exercise', '健身', 'gym', 'run', '跑步'],
  RoutineCategory.family:   ['家庭', 'family', '孩子', 'child', '陪'],
};
```

If `icon` is explicitly set by the user it takes priority over the category default.

**Files changed:**
| File | Change |
|------|--------|
| `lib/models/routine.dart` | Add `RoutineCategory` enum + `category` field + `kCategoryIcon` + `kCategoryKeywords` + `autoDetectCategory(String name)` static method |
| `lib/core/services/database_service.dart` | `onUpgrade` v2: `ALTER TABLE routines ADD COLUMN category TEXT` |
| `lib/core/services/storage_service.dart` | Include `category` in insert/update/select |
| `lib/repositories/routine_repository.dart` | Propagate `category` field |
| `lib/screens/routine/routine_screen.dart` | Show category icon in list tile; add category picker row in add/edit dialog |

---

### A2 — Routine list: active / completed-today split (Small)

**PM decision:** When completed today, routine moves to a "Completed" section at the bottom. The two sections are independent.

**Design:** `RoutineScreen` (already a `StatelessWidget` reading `routineProvider.routines`) splits the list:
```dart
final active    = routines.where((r) => !r.isCompletedToday).toList();
final completed = routines.where((r) =>  r.isCompletedToday).toList();
```
Render `active` items normally, then a `_SectionHeader('已完成')` divider, then `completed` items with a `Icons.check_circle` icon tinted green and the item slightly dimmed (`opacity: 0.6`). No model or DB changes required — `isCompletedToday` already exists on `Routine`.

**Files changed:**
| File | Change |
|------|--------|
| `lib/screens/routine/routine_screen.dart` | Split list render + section header + completed item styling |

---

### C1 — Emotion attribute on notes (Medium)

**PM decision:** Fixed emoji set, extensible in future.

**Design:**
```dart
// lib/core/config/emotions.dart  (new)
const List<String> kDefaultEmotions = [
  '😊', '🥰', '🤩', '😌', '😔', '😢', '😡', '😰', '😤', '😴',
];
// Extensible: future sets loaded from SharedPreferences or remote config
```

Add `emotion` (nullable `String`) to `Entry`. In `AddEntryScreen`, show a single horizontal row of `kDefaultEmotions` chips above the tag selector. Tapping selects/deselects. Existing entries without emotion display nothing (nullable is fine).

**Files changed:**
| File | Change |
|------|--------|
| `lib/core/config/emotions.dart` | New — defines `kDefaultEmotions` |
| `lib/models/entry.dart` | Add `emotion` field + `copyWith` + `toJson`/`fromJson` |
| `lib/core/services/database_service.dart` | v2 migration: `ALTER TABLE entries ADD COLUMN emotion TEXT` |
| `lib/core/services/storage_service.dart` | Include `emotion` in entry insert/update/select |
| `lib/repositories/entry_repository.dart` | Propagate `emotion` |
| `lib/screens/add_entry_screen.dart` | Emotion picker row |
| `lib/widgets/entry_card.dart` | Show emotion emoji badge if set |

---

### C2 — Emoji of the day on Home & Calendar (Medium)

**Design:** Add `getDayEmotion(DateTime date) → String?` to `EntryProvider`. It scans all entries for the given date, collects non-null emotions, and returns the most frequent (first alphabetically if tied). If no emotions exist for that day, returns null.

Display:
- **Home screen:** Emotion badge next to the selected date header (e.g. `今天 · 😊`)
- **Calendar widget:** Each date cell that has entries gets a small emoji beneath the date number. If no emotion data, the existing dot indicator stays.

**Files changed:**
| File | Change |
|------|--------|
| `lib/providers/entry_provider.dart` | Add `getDayEmotion(DateTime)` |
| `lib/screens/home/home_screen.dart` | Emotion badge in day header |
| `lib/widgets/calendar_widget.dart` | Per-cell emotion overlay |

---

### D1 — Emoji jar widget (Large)

**Design:** A `EmojiJarWidget` renders a stylised glass jar using `CustomPainter`. The jar body contains a `Wrap` of all emoji collected from entries on a given date. The jar has a subtle glass shimmer (a semi-transparent white gradient overlay). Jar size is fixed; if emoji overflow, they scroll inside the jar body (clipped `SingleChildScrollView`).

Placement: On the `HomeScreen`, below the selected-day entry list, in a collapsible section "今日情绪罐".

**New files:**
| File | Purpose |
|------|---------|
| `lib/widgets/emoji_jar.dart` | `EmojiJarWidget(date: DateTime)` — CustomPainter jar + emoji content |

**Files changed:**
| File | Change |
|------|--------|
| `lib/screens/home/home_screen.dart` | Embed `EmojiJarWidget` for selected date |

---

### D2 — AI messages from jar (Medium)

**PM decision:** AI generates text (mood description, encouragement, inspiration, motivation) — no image generation API.

**Prerequisites:** `LlmService` must be extracted first (see E1 section).

**Design:** Inside the jar view on Home screen, a small "✨ 问问 AI" button. Tapping it opens a bottom sheet with three tabs: 鼓励 / 灵感 / 动力. Each tab has a "Generate" button. The prompt sent to the LLM includes the day's emoji list and optionally the entry contents. The response is displayed in the sheet with a copy/share button.

The jar design suggestion (Q8-A): AI returns a short text like "今天的心情偏向平静" which is shown as a subtitle under the jar. The jar painter optionally tints based on a keyword-to-color map derived from this text (e.g. "平静" → blue tint, "快乐" → yellow tint). No image generation needed.

**Files changed:**
| File | Change |
|------|--------|
| `lib/widgets/emoji_jar.dart` | Add AI message bottom sheet trigger + color tint logic |
| `lib/core/services/llm_service.dart` | Used here (see E1) |

---

### D3 + D4 — Yearly jars & Shelf screen (Medium)

**Design:** The Shelf is the first sub-tab of `CherishedMemoryScreen`.

A `JarProvider` (new) exposes:
```dart
List<int> get yearsWithData  // sorted desc
List<String> getDayEmotions(int year, int month, int day)
Map<int, Map<int, String?>> getYearEmotionMap(int year) // month → day → dominantEmoji
```
Computed from `EntryProvider.allEntries` — no new DB table.

The Shelf screen shows a vertical list of year cards. Each year card contains a miniature jar `CustomPainter` rendering a sample of that year's emojis (first 30), the year label, and entry count. Tapping a year card opens a `YearJarDetailScreen` with a month grid.

**New files:**
| File | Purpose |
|------|---------|
| `lib/providers/jar_provider.dart` | Year/month/day emoji aggregation |
| `lib/screens/cherished/shelf_tab.dart` | Year card list |
| `lib/screens/cherished/year_jar_detail_screen.dart` | Month-by-month breakdown |

---

### B2 — Template system (Large)

**PM decision:** Built-in templates = designer assets bundled in `assets/templates/`. Users can also upload any image from gallery as background.

**New model: `CardTemplate`**
```dart
class CardTemplate {
  final String id;
  final String name;
  final String icon;           // emoji
  final String? assetPath;     // bundled asset (built-in)
  final String? customImagePath; // user-uploaded (internal storage)
  final String fontFamily;     // 'default', 'serif', 'mono'
  final String fontColor;      // hex
  final bool isBuiltIn;
  final DateTime createdAt;
}
```

**Built-in templates (create 6 defaults):**

| Name | Icon | Background | Font Color |
|------|------|-----------|-----------|
| 春日晴天 | 🌸 | assets/templates/spring.jpg | #333333 |
| 午夜蓝调 | 🌙 | assets/templates/midnight.jpg | #FFFFFF |
| 暖阳橙 | ☀️ | assets/templates/warm.jpg | #FFFFFF |
| 简约白 | 📄 | assets/templates/minimal.jpg | #222222 |
| 森林绿 | 🌿 | assets/templates/forest.jpg | #FFFFFF |
| 自定义 | 🎨 | user-uploaded | user-chosen |

**Files:**
| File | Purpose |
|------|---------|
| `lib/models/card_template.dart` | New model |
| `lib/providers/template_provider.dart` | CRUD + built-in seed |
| `lib/core/services/database_service.dart` | New `templates` table (v3) |
| `lib/screens/cherished/template_tab.dart` | List + "New Template" button |
| `lib/screens/cherished/template_editor_screen.dart` | Create/edit user templates |
| `assets/templates/` | 5 background JPGs (designer to provide) |
| `pubspec.yaml` | Add `assets/templates/` path |

---

### B1 — Card generation from notes (Large)

**PM decision:** A card can contain one or more notes. Entry point is a "Card" button on each note, but the builder lets users add more notes before generating.

**New model: `NoteCard`**
```dart
class NoteCard {
  final String id;
  final List<String> entryIds;   // 1+ notes included
  final String templateId;
  final String folderId;
  final String? renderedImagePath; // internal storage path of rendered PNG
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Card generation flow:**
1. User taps card icon on an entry in `MomentScreen`
2. `CardBuilderDialog` opens — shows the note pre-selected + "Add more notes" button
3. User optionally picks additional notes from a filtered list
4. User picks template (thumbnail grid from `TemplateProvider`)
5. User taps "Generate" → a `RepaintBoundary` widget renders the card off-screen to a `ui.Image`, which is compressed to PNG and saved via `FileService`
6. `NoteCard` record saved with rendered path + entryIds + templateId + folderId
7. User can share immediately or find it in the Cards folder

**Card renderer widget (`CardRenderer`):**
```
┌─────────────────────────┐
│   [template background] │
│                         │
│  "Entry content here…"  │
│  (if multiple entries,  │
│   each in a block)      │
│                         │
│  😊  2026-03-14  Blinking│
└─────────────────────────┘
```

**Files:**
| File | Purpose |
|------|---------|
| `lib/models/note_card.dart` | New model |
| `lib/models/models.dart` | Export new models |
| `lib/providers/card_provider.dart` | CRUD for NoteCard |
| `lib/core/services/database_service.dart` | New `note_cards` table (v3) |
| `lib/screens/cherished/cards_tab.dart` | Cards folder browser |
| `lib/screens/cherished/card_builder_dialog.dart` | Multi-note picker + template picker + generate |
| `lib/widgets/card_renderer.dart` | Off-screen render widget (RepaintBoundary) |
| `lib/screens/moment/moment_screen.dart` | Add card icon to each entry tile |

---

### B3 — Folder management (Medium)

**PM decision:** Folders are only for generated cards. Notes stay unchanged.

**New model: `CardFolder`**
```dart
class CardFolder {
  final String id;
  final String name;
  final String icon;       // emoji
  final bool isDefault;    // "我的卡片" default folder
  final DateTime createdAt;
}
```

A default folder "我的卡片 🗂️" is seeded in `DatabaseService.init()` alongside default tags. Users can create/rename/delete custom folders from the Cards tab. Folders are listed as chips at the top of `CardsTab`; tapping filters the card grid below.

**Files:**
| File | Purpose |
|------|---------|
| `lib/models/card_folder.dart` | New model |
| `lib/providers/card_provider.dart` | Include folder CRUD |
| `lib/core/services/database_service.dart` | New `card_folders` table (v3) |
| `lib/screens/cherished/cards_tab.dart` | Folder chip filter + card grid |

---

### E1 — AI: extract LlmService + save conversations as Reflection notes (Medium)

**PM decision:** After AI conversation, a "Save" button triggers the AI to generate a summary, saved as a freeform entry with the "Reflection" tag. No new `EntryType`. The "Reflection" tag is added to the default tag seed.

**LlmService (new):**
```dart
// lib/core/services/llm_service.dart
class LlmService {
  Future<String> complete(String prompt) async {
    // reads saved provider config from SharedPreferences
    // makes HTTP POST to baseUrl with API key + model
    // returns response text
  }
}
```
This service is shared by `AssistantScreen`, the jar AI messages, and the summary narration.

**Requires new dependency:** `http: ^1.2.0` (no HTTP client currently in pubspec).

**AssistantScreen changes:**
- Wire real LLM calls via `LlmService` (replaces hardcoded stub)
- Add "Save Reflection" button in the chat app bar
- On tap: call `LlmService` with a summarize prompt of the conversation → save as `EntryProvider.addEntry(type: freeform, content: summary, tagIds: ['tag_reflection'])`
- Remove `_loadDailySummary()` stub (daily/weekly/monthly text summaries removed per PM Q10)

**Default tag addition:**
In `StorageService._getDefaultTags()`, add:
```dart
Tag(id: 'tag_reflection', name: '反思', nameEn: 'Reflection', color: '#5856D6', category: 'system', createdAt: DateTime.now()),
```

**Files:**
| File | Change |
|------|--------|
| `lib/core/services/llm_service.dart` | New |
| `lib/screens/assistant/assistant_screen.dart` | Real LLM calls + Save Reflection button + remove stub summaries |
| `lib/core/services/storage_service.dart` | Add Reflection to default tags |
| `pubspec.yaml` | Add `http: ^1.2.0` |

---

### Q7 — Floating animated robot (Medium)

**Design:** A global `FloatingRobotWidget` is added to `MainScreen`'s `Stack`. It is a draggable widget (optional: fixed position bottom-right) showing a robot PNG/SVG asset with a gentle idle animation (bobbing up/down using `AnimationController` + `Transform.translate`). Tapping it pushes `AssistantScreen` as a full-screen modal route.

If a new notification/reminder arrives (future feature), the robot can play a different animation (shake/wave) — the animation state is managed by a `RobotProvider` (simple `ChangeNotifier`).

```
MainScreen Scaffold
├── body: IndexedStack(...)         ← current 5 screens
├── floatingActionButton: AddNote   ← existing FAB (unchanged)
└── Stack overlay:
    └── FloatingRobotWidget         ← new, positioned bottom-right corner
                                       above FAB + nav bar
```

**New files:**
| File | Purpose |
|------|---------|
| `lib/widgets/floating_robot.dart` | Animated robot widget |
| `lib/providers/robot_provider.dart` | Animation state (idle/notify) |
| `assets/images/robot_idle.png` | Robot asset (to be created) |

**Files changed:**
| File | Change |
|------|--------|
| `lib/app.dart` | Remove AI tab; add 珍藏 tab; add `FloatingRobotWidget` to Stack |

---

### E2 — Visual summary screen (Large)

**PM decision:** Chart-based (fl_chart). Metrics: note count, routine completion, emotion tendency, tag highlights. Scopes: daily, weekly, monthly.

**Design:** `SummaryTab` is the third sub-tab of `CherishedMemoryScreen`.

**Charts per scope:**
1. **Notes created** — vertical bar chart (one bar per day/week/month)
2. **Routine completion rate** — horizontal bar chart (one bar per routine, % complete)
3. **Emotion tendency** — line chart of dominant emotion per day (encoded as a numeric "mood score": 😊=5, 😌=4, 😔=3, 😢=2, 😡=1, default=3)
4. **Tag highlights** — pie chart or chip frequency list showing top 5 tags used

Scope selector: three `ChoiceChip`s at the top (日 / 周 / 月). A `SummaryProvider` (new) computes all metrics from `EntryProvider.allEntries` and `RoutineProvider.routines` on demand.

**New dependency:** `fl_chart: ^0.70.0`

**New files:**
| File | Purpose |
|------|---------|
| `lib/providers/summary_provider.dart` | Compute metrics for each scope |
| `lib/screens/cherished/summary_tab.dart` | Chart UI, scope picker |

---

## 3. Cherished Memory Screen structure

```
CherishedMemoryScreen (new tab 4)
├── TabBar: [书架 Shelf] [卡片 Cards] [总结 Summary]
├── ShelfTab
│   ├── Yearly jar cards (vertical list)
│   └── → YearJarDetailScreen (month grid)
├── CardsTab
│   ├── Folder filter chips
│   ├── Card grid (generated note cards)
│   └── → CardDetailScreen (view/edit/share/delete)
└── SummaryTab
    ├── Scope picker (日/周/月)
    └── fl_chart visualizations (4 charts)
```

---

## 4. Database migration plan

| DB Version | Table | Change |
|-----------|-------|--------|
| v1 → v2 | `entries` | `ADD COLUMN emotion TEXT` |
| v1 → v2 | `routines` | `ADD COLUMN category TEXT` |
| v2 → v3 | `templates` | New table |
| v2 → v3 | `card_folders` | New table |
| v2 → v3 | `note_cards` | New table |
| v2 → v3 | `note_card_entries` | New join table (card ↔ entries many-to-many) |

All migrations go in `DatabaseService.onUpgrade(db, oldVersion, newVersion)` as sequential `if (oldVersion < N)` blocks.

---

## 5. New dependencies

Add to `pubspec.yaml`:

```yaml
# HTTP client for LLM API calls
http: ^1.2.0

# Charts for visual summary
fl_chart: ^0.70.0

# Animation helpers for floating robot (optional — can use AnimationController only)
flutter_animate: ^4.5.0
```

Add to `pubspec.yaml` flutter assets section:
```yaml
flutter:
  assets:
    - assets/templates/
    - assets/images/
```

---

## 6. Phased delivery order

### Phase 1 — Data foundation + routine polish ✅ DONE (v1.0.1)
*Touches models and existing screens only. Low risk.*
- [x] A1: Routine category enum, auto-detect, DB migration v2→v3
- [x] A2: Routine list active/completed-today split (今日待完成 / 已完成 / 已暂停)
- [x] C1: `emotion` field on Entry, DB migration v2→v3, emotion picker in AddEntryScreen, badge on EntryCard
- [x] C2: `getDayEmotion()` in EntryProvider, emotion badge on Home date header, emoji per cell in CalendarWidget
- [x] Add "Reflection" (`tag_reflection`) to default tag seed
- [x] Add `http: ^1.2.0` dependency

### Phase 2 — Navigation restructure + AI floating robot ✅ DONE (v1.0.2)
*Breaking change to app shell.*
- [x] Add `CherishedMemoryScreen` shell with 3 placeholder tabs (书架 / 卡片 / 总结)
- [x] Remove AI tab from bottom nav; add 珍藏 tab (`Icons.auto_awesome`)
- [x] Add `FloatingRobotWidget` to MainScreen (bobbing 🤖, tap → AssistantScreen modal)
- [x] Extract `LlmService` with real HTTP calls (OpenAI-compatible `/chat/completions`)
- [x] Wire `AssistantScreen` to `LlmService` — multi-turn chat with full history, loading spinner, error messages in Chinese
- [x] E1: "Save Reflection" (💾) button — LLM summarises conversation → saved as freeform entry with `tag_reflection`
- [x] Add "Open Router" (qwen/qwen3.5-flash-02-23) as 4th default LLM provider
- [x] Version display in Settings updated to 1.0.2

### Phase 3 — Emoji jar + shelf ✅ TESTED & PASSED (v1.0.3)
*Depends on Phase 1 (emotion data) and Phase 2 (LlmService for AI messages).*
- [x] D1: `EmojiJarWidget` on Home screen for selected date
- [x] D2: AI messages panel (encouragement/inspiration/motivation) via LlmService
- [x] D3/D4: `JarProvider`, `ShelfTab`, `YearJarDetailScreen`

### Phase 4 — Templates + cards + folders ✅ TESTED & PASSED (v1.0.3)
*Self-contained. Depends only on Phase 2 for navigation home.*
- [x] B2: `CardTemplate` model, DB migration v4, 6 built-in templates (solid bg colors), `CardProvider`
- [x] B3: `CardFolder` model, DB migration v4, `CardProvider` (folders), default folder seed
- [x] B1: `NoteCard` model, join table, `CardProvider` (cards), `CardBuilderDialog`, `CardRenderer`, `CardsTab`
- [x] Add card button (style icon) to Moment screen entry tiles

### Phase 5 — Visual summary ✅ TESTED & PASSED (v1.0.3)
*Depends on Phase 1 (emotion data), Phase 3 (jar data), Phase 4 (tag data).*
- [x] Add `fl_chart: ^0.70.0` dependency
- [x] `SummaryProvider` with daily/weekly/monthly metric computation
- [x] `SummaryTab` with 4 fl_chart visualizations (note count, routine rate, emotion trend, tag highlights)

### Post-release UI fixes (v1.0.3 patch — committed a204bcd)
- [x] ActionChip icon and label colors set to `Colors.black87` in `AssistantScreen` (white-on-light visibility fix)

---

## 7. File impact matrix

Legend: ✅ shipped & tested

| File | A1 | A2 | C1 | C2 | D1 | D2 | D3/D4 | B1 | B2 | B3 | E1 | E2 |
|------|----|----|----|----|----|----|-------|----|----|----|----|-----|
| `lib/app.dart` | | | | | | | | | | | ✅ | ✅ |
| `lib/models/entry.dart` | | | ✅ | | | | | | | | | |
| `lib/models/routine.dart` | ✅ | | | | | | | | | | | |
| `lib/core/services/database_service.dart` | ✅ | | ✅ | | | | | ✅ | ✅ | ✅ | | |
| `lib/core/services/storage_service.dart` | ✅ | | ✅ | | | | | | | | ✅ | |
| `lib/core/services/llm_service.dart` | | | | | | ✅ | | | | | ✅ | |
| `lib/providers/entry_provider.dart` | | | | ✅ | | | | | | | | |
| `lib/providers/jar_provider.dart` | | | | | | | ✅ | | | | | |
| `lib/providers/card_provider.dart` | | | | | | | | ✅ | ✅ | ✅ | | |
| `lib/providers/summary_provider.dart` | | | | | | | | | | | | ✅ |
| `lib/screens/routine/routine_screen.dart` | ✅ | ✅ | | | | | | | | | | |
| `lib/screens/add_entry_screen.dart` | | | ✅ | | | | | | | | | |
| `lib/screens/home/home_screen.dart` | | | | ✅ | ✅ | | | | | | | |
| `lib/screens/assistant/assistant_screen.dart` | | | | | | | | | | | ✅ | ✅ |
| `lib/screens/moment/moment_screen.dart` | | | | | | | | ✅ | | | | |
| `lib/screens/settings/settings_screen.dart` | | | | | | | | | | | ✅ | |
| `lib/widgets/calendar_widget.dart` | | | | ✅ | | | | | | | | |
| `lib/widgets/entry_card.dart` | | | ✅ | | | | | | | | | |
| `lib/widgets/emoji_jar.dart` | | | | | ✅ | ✅ | | | | | | |
| `lib/widgets/floating_robot.dart` | | | | | | | | | | | ✅ | |
| `pubspec.yaml` | | | | | | | | | ✅ | | ✅ | ✅ |

**New files — shipped & tested (all phases):**
- Phase 1+2: `lib/core/config/emotions.dart`, `lib/core/services/llm_service.dart`, `lib/widgets/floating_robot.dart`, `lib/screens/cherished/cherished_memory_screen.dart`
- Phase 3: `lib/providers/jar_provider.dart`, `lib/widgets/emoji_jar.dart`, `lib/screens/cherished/shelf_tab.dart`, `lib/screens/cherished/year_jar_detail_screen.dart`
- Phase 4: `lib/models/card_template.dart`, `lib/models/card_folder.dart`, `lib/models/note_card.dart`, `lib/providers/card_provider.dart`, `lib/widgets/card_renderer.dart`, `lib/screens/cherished/cards_tab.dart`, `lib/screens/cherished/card_builder_dialog.dart`
- Phase 5: `lib/providers/summary_provider.dart`, `lib/screens/cherished/summary_tab.dart`

**Note:** `template_provider.dart` was merged into `card_provider.dart` (templates and cards managed by single provider).
