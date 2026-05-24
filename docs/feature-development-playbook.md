# Feature Development Playbook — Blinking Notes

> Derived from 50+ lessons learned across 6 sessions (May 5–23, 2026). Covers full lifecycle from scoping through post-launch.

---

## Before You Start: Daily Baseline

```bash
flutter analyze --no-pub    # Must be 0 errors
flutter test                # Must all pass
```

### Mandatory Workflow

```
Issue / Feature
    │
    ├── 1. Root Cause Analysis — understand WHY before touching code
    ├── 2. Propose Solution — 1-2 options with impact assessment
    ├── 3. Evaluate — pick simplest fix; one bug/fix, one feature/ship
    ├── 4. Review Tests — update existing tests BEFORE coding
    ├── 5. Implement — minimal change
    │       flutter analyze → verify 0 errors
    │       flutter test → verify all pass
    ├── 6. Push to Sims — build for all 3 simulators, install fresh
    ├── 7. UAT on Sims — execute test cases on iPhone, iPad, Android
    └── 8. Build Production — only after UAT passes on all 3
```

### Core Rules (from repeated failures)

1. **One edit = one `flutter analyze`** — never chain edits without verifying
2. **Never hardcode IDs** — every ID in logic must be a named constant in its model
3. **SharedPreferences is for settings only** — no data > 1KB, no images (use filesystem)
4. **Seed data: one canonical source per dataset** — never duplicate in tests
5. **Commit after each feature** — not at end of day; enables safe `git checkout` rollback
6. **Simulator ≠ Real Device** — functional testing (notifications, IAP, backup) requires hardware

---

## Phase 0: Scoping & Design (before any code)

### 0.1 Requirement Analysis & Competitive Research

Before any design work, answer three questions:

**1. Is the requirement aligned with the product intent?**
The feature must serve the app's core promise. Blinking is a personal memory/habit-tracking app — "local-first, private, no accounts." Any feature that introduces social complexity, server-side data storage, or public-facing UX must be explicitly justified against this promise.

**2. Is there any ambiguity in the requirement?**
Rewrite the requirement in your own words and check for gaps: Who is the user? What exactly are they trying to accomplish? What does "done" look like? If you can't answer all three, the requirement is ambiguous — push back for clarification before proceeding.

**3. What does the competitive landscape look like?**
Research 3–5 comparable apps. For each, answer: How do they solve this problem? What's their UX flow? Where do they fall short? This reveals table-stakes features vs. differentiators and often surfaces better flows.

Phase 3 example: Competitive analysis of 5 apps (RedNotes, Day One, Stoic, Canva, Notion) found that no competitor combines AI-generated reflection + mood data + tags on shareable visual cards — a unique differentiator. This confirmed the feature's value and shaped the 8-template, photo+text design.

**Output of 0.1:** A 1-page brief covering product alignment, clarified requirement (no ambiguity), and competitive positioning with recommended approach.

### 0.2 Separate Use Cases

Write down each user goal as a single sentence. If you find two goals, split them into separate use cases. Keepsake (preserve memory) and XHS Export (social sharing) were conflated — separating them shrank scope from 17 days to 11 and eliminated conflicting requirements.

```
❌ "Build shareable image cards"
✅ "Build keepsake cards (photo+text, single page, in-app)" + "Build XHS export (multi-page, social, camera roll)" — ship #1 first
```

### 0.3 Lock Decisions Before Coding

List every ambiguous choice as a numbered decision (D1, D2, ...). Get explicit answers from stakeholders before writing code. Phase 3 had 14 decisions (D1–D14). None were changed during implementation because each was locked upfront.

| Decision | Question | Resolution |
|----------|----------|------------|
| D1 | Replace or augment old templates? | Replace all 6 with 8 new |
| D6 | Aspect ratio? | 3:4 fixed for v1.2.0 |
| D8 | Multi-page? | Defer to v1.3.0 |

**Rule:** If you think "I'll figure this out during implementation" — stop and decide now. The implementer should not be the decision-maker.

### 0.4 Identify Deferrable Scope

List every sub-feature that could be cut without breaking the core user goal. Rank by effort, risk, and user impact. For Phase 3:

| Rank | Cut | Effort | Why Safe to Defer |
|:----:|-----|:---:|------|
| 1 | Card History screen | 3h | Camera roll already serves as history |
| 2 | Multi-entry merge | 1.5h | Serves no core use case |
| 3 | Custom backgrounds | 2h | Entry photos cover primary need |

**Rule:** The core non-negotiable must work end-to-end. Everything else is deferrable.

### 0.5 Design Backup/Restore Impact

For any feature that stores user data, answer: what goes in the backup ZIP? Phase 3's answer: metadata only (~2KB per card), never rendered PNGs (~2MB each). Use "store the recipe, not the cake" — back up inputs, regenerate outputs on restore.

### 0.6 Check Dependency APIs Against Design Assumptions

`flutter_local_notifications` v21 removed `onDidReceiveLocalNotification` — a callback our design assumed existed based on pub.dev docs. **After `flutter pub add`, `grep` the installed package's source (not pub.dev) for the API you plan to use.** Run `flutter analyze` immediately.

### 0.7 Write Test Cases Before Code

Write both automated and UAT cases in the design doc. Phase 3 specified 27 UAT + 44 unit/widget tests before implementation. **Design docs listing tests are not the tests — write the test files or coverage is zero.**

---

## Phase 1: Foundation (models, data, migration)

### 1.1 Models First, DB Migration Last

Order: enums → models → test helpers → seed data → DB migration.

- **Enums first** because models reference them
- **Models with fromJson/toJson** to ensure DB column mapping is explicit
- **Test helpers** (`@visibleForTesting` methods) to enable testing without full DB setup
- **Seed data** in `StorageService._getDefault*()` — one canonical source per dataset
- **DB migration last** — only after models and seeds are finalized

### 1.2 Model Field Addition: Full Write-Chain Checklist

Adding one field (`voiceEnabled` to Routine) requires 7 layers. Missing any = data appears to work (in-memory) but is lost on restart.

```
[ ] Model: field + constructor default + fromJson + toJson + copyWith
[ ] DB: _onCreate schema column
[ ] DB: _onUpgrade migration block
[ ] StorageService: INSERT map in add*() method
[ ] StorageService: SELECT map in get*() method
[ ] Repository: pass-through if it maps to model constructor
[ ] Provider: pass-through if it calls repository
[ ] Test: kSchemaVersion in db_version_test.dart
```

### 1.3 Never Hardcode IDs in Business Logic

```dart
// ❌ Breaks on rename — grep-and-replace misses references
if (activeId == 'lens_builtin_zengzi') { ... }

// ✅ Single source of truth
static const kDefaultLensId = 'lens_style_kael';
if (activeId == DefaultLensSets.defaultActiveSetId) { ... }
```

Every ID in logic = named constant in its owning model.

### 1.4 JSON-Encode Complex Types for SQLite

SQLite has no List, Map, or Set type. Always `jsonEncode()` before storing, `jsonDecode()` after reading.

```dart
// In addNoteCard:
'display_tags': card.displayTags != null ? jsonEncode(card.displayTags) : null,

// In NoteCard.fromJson — handle both raw (restore) and encoded (DB):
static List<String>? _parseTagList(dynamic value) {
  if (value == null) return null;
  if (value is List) return List<String>.from(value);
  if (value is String) return List<String>.from(jsonDecode(value) as List);
  return null;
}
```

**Pitfall:** Passing a raw `List<String>` to `db.insert()` throws `Invalid sql argument type` at runtime — sqflite doesn't catch this at compile time.

### 1.5 `ALTER TABLE ADD COLUMN` Is Not Idempotent

Migrations using `ALTER TABLE ADD COLUMN` cannot be run twice. Don't write idempotency tests for them. Earlier migrations using `CREATE TABLE IF NOT EXISTS` ARE idempotent — don't mix the patterns.

```dart
if (oldVersion < 15) {
  await db.execute('ALTER TABLE templates ADD COLUMN name_en TEXT');
  // This will fail if run a second time
}
```

### 1.6 Seed Data: One Source, Zero Duplication

Every built-in dataset must exist in exactly one place. `StorageService._getDefaultTemplates()` is the canonical source. Never duplicate seed data in tests — reference the canonical source or use `@visibleForTesting` accessors.

### 1.5 Register Providers Immediately

Register new providers in `app.dart`'s `MultiProvider` tree as soon as the provider class exists — even if nothing consumes it yet. An unregistered `CardProvider` was the reason the old card system was dead code for months.

---

## Phase 2: Service Layer (business logic)

### 2.1 Make Static Methods Injectable

When a widget calls a static service method that does I/O (file system, network, platform channels), make it injectable for testing.

```dart
// ❌ Hard to test
CardRenderService.renderToFile(...)

// ✅ Testable
final renderFn = widget._renderFn ?? CardRenderService.renderToFile;
await renderFn(...);
```

**Pattern:** Add an optional `@visibleForTesting` parameter that accepts a function with the same signature. Default to the real implementation. Tests inject a mock.

### 2.2 Test at Every Layer

Don't wait until the UI is built to test. Each layer gets its own test file:

| Layer | Test File | What It Validates |
|-------|-----------|-------------------|
| Models | `test/models/card_template_test.dart` | fromJson/toJson, defaults, enums |
| Seed data | `test/core/card_provider_test.dart` | Templates seeded correctly |
| DB migration | `test/core/card_migration_test.dart` | Columns added, old data migrated |
| Service | `test/core/card_render_service_test.dart` | Rendering produces valid output |
| Provider | `test/core/card_provider_test.dart` | CRUD works, getCardByEntryId |

---

## Phase 3: UI (widgets, screens)

### 3.1 Build Bottom→Up

Build widgets in dependency order: leaf components first, containers last.

```
CardTemplatePicker (leaf — no dependencies)
  → CardBuilderSheet (container — uses picker)
    → CardPreviewScreen (container — uses builder output)
      → EntryDetailScreen badge (consumer — uses preview)
```

### 3.2 Widget Tests Need Real Provider Trees

When a widget uses `context.watch<SomeProvider>()`, the widget test MUST provide it. Missing providers cause silent failures that are hard to debug.

```dart
// ❌ Falls — CardProvider not in tree when EntryDetailScreen uses it
testWidgets('displays entry', (tester) async {
  await tester.pumpWidget(MaterialApp(home: EntryDetailScreen(entry: ...)));
});

// ✅ Works
testWidgets('displays entry', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CardProvider(storageService)..loadForTest()),
        // ... all other providers the widget needs
      ],
      child: MaterialApp(home: EntryDetailScreen(entry: ...)),
    ),
  );
});
```

**Pitfall:** Adding one `context.watch` to an existing widget can break 5+ existing tests. Always run the full test suite after adding provider dependencies to an existing widget.

### 3.3 Scrollable Sheets Need Explicit Finders

`DraggableScrollableSheet` wrapping a `ListView` creates multiple scrollable areas. `tester.scrollUntilVisible()` defaults to finding a single scrollable and fails with `Bad state: Too many elements`.

```dart
// ❌ Fails with multiple scrollables
await tester.scrollUntilVisible(find.text('save'), 200);

// ✅ Specify the exact scrollable
await tester.scrollUntilVisible(
  find.text('save'), 200,
  scrollable: find.byType(Scrollable).first,
);
```

### 3.4 Off-Screen Rendering: The Correct Sequence

For headless PNG rendering via `RenderRepaintBoundary`, the sequence is strict:

```dart
final renderObject = RenderRepaintBoundary();
final pipelineOwner = PipelineOwner();
renderObject.attach(pipelineOwner);          // 1. Attach pipeline

final element = RenderObjectToWidgetAdapter(
  container: renderObject,
  child: widget,
).createElement();
element.assignOwner(buildOwner);             // 2. Assign build owner
element.mount(null, null);                   // 3. Mount (calls rebuild internally)

renderObject.layout(constraints);            // 4. Layout
pipelineOwner.flushLayout();                 // 5. Flush layout
pipelineOwner.flushPaint();                  // 6. Flush paint

final image = renderObject.toImage();        // 7. Capture (requires painted state)
```

**Pitfalls:**
- `BuildOwner` has no `flushLayout`/`flushPaint` — those are on `PipelineOwner`
- Calling `buildScope()` after `mount()` is redundant — `mount` calls `_rebuild` internally
- Skipping `pipelineOwner.flushPaint()` causes `'!debugNeedsPaint': is not true`

---

## Phase 4: Integration & UAT

### 4.1 Integration Tests Test Full Flows

These are still `flutter test` (no simulator) but exercise multiple components together:

```dart
test('Entry → Save → Card in DB → getCardByEntryId finds it', () async {
  final card = await cardProvider.addCard(
    entryIds: ['entry_1'],
    templateId: 'tpl_ink_rhythm',
    folderId: 'folder_default',
    cardContent: 'Integration test',
    ...
  );
  final found = cardProvider.getCardByEntryId('entry_1');
  expect(found!.cardContent, 'Integration test');
});
```

### 4.2 UAT: Separate Automatable from Manual

Categorize every UAT case before writing flows:

| Category | Maestro? | Examples |
|----------|:---:|------|
| Tap/navigate/assert-text | ✅ | Badge visible, template selection, locale switch |
| Visual fidelity | ❌ | Color accuracy, gradient rendering, motif positioning |
| Platform limitation | ❌ | iPad share sheet (UIPopover), backup restore (reinstall) |
| Real-time/async | ❌ | AI Rewrite (LLM call), voice notification (audio output) |
| External verification | ❌ | Backup file size, crash rate |

**Rule:** If a human needs to LOOK at the screen to verify correctness, it's manual. If the test can assert text presence, widget counts, or navigation events, it's automatable.

---

## Phase 5: Build & Deploy

### 5.1 Clean Before Building

```bash
flutter clean && flutter build apk --debug  # Android
flutter build ios --simulator --debug        # iOS simulator
flutter build ipa --release                  # iOS production
flutter build appbundle --release            # Android production
```

Never chain `flutter clean` between builds — it deletes the previous build output.

### 5.2 Install on All Target Devices

```bash
xcrun simctl install <device-uuid> build/ios/iphonesimulator/Runner.app
adb -s <device-id> install build/app/outputs/flutter-apk/app-debug.apk
```

### 5.3 Gate Checklist

Before marking a feature complete:

| Gate | Command / Check |
|------|----------------|
| 0 analyze errors | `flutter analyze --no-pub` |
| All tests pass | `flutter test` |
| No new flaky tests | Compare before/after count of `-N` failures |
| DB migration tested | Create DB at old version, migrate, verify columns |
| Seed data verified | Assert correct count, valid fields |
| UAT catalog written | Maestro + manual cases documented |
| Simulators ready | App installed on iPhone, iPad, Android |

---

## Phase 6: Deployment & Post-Launch

### 6.1 Session Summaries ≠ Ground Truth

Post-launch audit found server endpoints documented as "✅ Live" that were never deployed. The app worked because of compile-time fallback keys. Verify with `curl`:

```bash
curl -s https://blinkingchorus.com/api/config | python3 -c "import json,sys; d=json.load(sys.stdin); assert 'trial_keys' in d; print('OK')"
```

### 6.2 Compile-Time Fallbacks Need Observability

AI key fallback (dart-define baked into builds) was so reliable that nobody noticed the server wasn't deployed. Add logging:

```dart
if (config == null) debugPrint('[Config] WARNING: Using fallback keys — server unreachable');
```

### 6.3 KV Secrets Can Drift Without Detection

Cloudflare KV secrets are opaque blobs. Trial keys were set to wrong model during an intermediate switch and never reverted. Add a validation script.

### 6.4 Feature Gates: One Feature, One Gate

Device fingerprinting was blocked behind `ENTITLEMENT_ENABLED` — a lightweight feature gated behind a heavy one. Use separate gates per feature.

### 6.5 Deployment Checklist

```
[ ] git status — clean working tree, all changes committed
[ ] git log -1 — verify the right commit is being deployed
[ ] curl each new endpoint — verify HTTP 200 + correct content type
[ ] curl each modified endpoint — verify no regression
[ ] Check KV secrets match intended config (run validate script)
[ ] Run full test suite (client + server) — 0 failures
[ ] Document deployed commit hash in session summary
[ ] Verify feature gates are correctly configured
```

---

## Phase 7: Debugging & Troubleshooting

### 7.1 File Damage from Cascading Edits

Heavy editing (15+ edits to one file) caused brace mismatches and lost method definitions. **Use `git` to checkpoint between phases.** Prefer targeted edits over large-block replacements.

### 7.2 Async Method Ordering

`rescheduleAll()` called `cancelAll()` which ran AFTER `scheduleRoutine()`. Notifications scheduled then immediately canceled. Never put `cancelAll()` inside a method that runs after user actions. Cancel specific IDs only.

### 7.3 Seed Accumulation in Loops

Loop used `routine.completionLog` (always empty original) instead of accumulating: track a `current` variable that updates across iterations.

### 7.4 Emulator Limitations

- Android TTS crashes on emulator (native library incompatibility)
- iPad simulator has memory constraints for backup
- Android emulator caches old app icons after reinstalls
- Simulators are for UI layout only — functional testing requires real devices

### 7.5 Zsh Variable Name Collisions

`status=$(adb shell ...)` fails silently because `status` is a zsh read-only builtin. Avoid: `status`, `path`, `argv`, `fignore`.

---

## Quick Reference: All Pitfalls

### Compile/Runtime Errors

| Pitfall | Symptom | Fix |
|---------|----------|-----|
| Raw List in SQLite INSERT | `Invalid sql argument type` | `jsonEncode()` before insert |
| `BuildOwner.flushPaint()` | `undefined_method` | Use `PipelineOwner.flushPaint()` |
| Redundant `buildScope()` | `_debugStateLocked` assertion | `mount()` calls it internally |
| `toImage()` without paint | `!debugNeedsPaint` | Run `pipelineOwner.flushPaint()` |
| `ALTER TABLE ADD COLUMN` 2x | `duplicate column name` | Don't test idempotency for ALTER TABLE |
| `const` on method calls | `const_eval_method_invocation` | Remove const; use factory |
| `--no-codesign` on simulator | Icon tap does nothing | Use `--simulator` flag |
| Missing model field write chain | Data lost on restart | Use 7-layer checklist |

### Silent/Subtle Failures

| Pitfall | Symptom | Fix |
|---------|----------|-----|
| Missing Provider in test | Test crash / no data | Add all providers to `MultiProvider` |
| Unregistered provider | Widget silently empty | Register in `app.dart` |
| Hardcoded IDs in logic | Break on rename | Named constant in model |
| Duplicate seed data sources | Drift between sources | One `_getDefault*()` per dataset |
| Provider seed runs in tests | Tests fail unexpectedly | Seed in `main.dart` only |
| Async cancel after schedule | Notifications vanish | Cancel by ID; chain explicitly |
| Fallback masks missing server | Everything works, nothing deployed | Add `debugPrint` on fallback |
| Feature gate blocks unrelated | Simple feature doesn't work | One gate per feature |
| Session summary says "deployed" | `git status` shows uncommitted | `curl` after deploy |
| Maestro: "code fix needed" | Fix already committed | Check `git log` first |
| Seed accumulation in loop | Results show 0 | Track `current` across iterations |
| State machine not persisting | Reverts on restart | `_saveState()` + check stale cache |

### Design/Architecture

| Pitfall | Symptom | Fix |
|---------|----------|-----|
| Conflated use cases | Conflicting requirements | Split; ship one at a time |
| Decisions deferred to code | Rework mid-build | Lock D1, D2, ... before coding |
| SharedPreferences for images | Only last image survives | Filesystem + stored path |
| Backup stores rendered output | Massive ZIP, OOM | Store recipe (metadata), regenerate |
| API assumption without check | Removed callback breaks feature | `grep` installed package source |
| Dependency on pub.dev docs | Shows wrong API version | Check local `pub-cache/hosted/` |
