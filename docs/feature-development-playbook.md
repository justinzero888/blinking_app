# Feature Development Playbook — Blinking Notes

> Based on Phase 3 (Keepsake Cards), May 2026. Derived from 10 lessons learned and 8 commits of implementation. Applicable to any feature in this codebase.

---

## Phase 0: Scoping & Design (before any code)

### 0.1 Separate Use Cases

Before opening the editor, write down the user's goal as a single sentence. If you find two goals, split them into separate use cases. Keepsake (preserve memory) and XHS Export (social sharing) were conflated — separating them shrank scope from 17 days to 11 and eliminated conflicting requirements.

```
❌ "Build shareable image cards"
✅ "Build keepsake cards (photo+text, single page, in-app)" + "Build XHS export (multi-page, social, camera roll)" — ship #1 first
```

### 0.2 Lock Decisions Before Coding

List every ambiguous choice as a numbered decision (D1, D2, ...). Get explicit answers from stakeholders before writing code. Phase 3 had 14 decisions (D1–D14). None were changed during implementation because each was locked upfront.

| Decision | Question | Resolution |
|----------|----------|------------|
| D1 | Replace or augment old templates? | Replace all 6 with 8 new |
| D6 | Aspect ratio? | 3:4 fixed for v1.2.0 |
| D8 | Multi-page? | Defer to v1.3.0 |

**Rule:** If you think "I'll figure this out during implementation" — stop and decide now. The implementer should not be the decision-maker.

### 0.3 Identify Deferrable Scope

List every sub-feature that could be cut without breaking the core user goal. Rank by effort, risk, and user impact. For Phase 3:

| Rank | Cut | Effort Saved | Why Safe to Defer |
|:----:|-----|:---:|------|
| 1 | Card History screen | 3h | Camera roll already serves as history |
| 2 | Multi-entry merge | 1.5h | Serves no core use case |
| 3 | Custom backgrounds | 2h | Entry photos cover primary need |

**Rule:** The core non-negotiable must work end-to-end. Everything else is deferrable.

### 0.4 Design Backup/Restore Impact

For any feature that stores user data, answer: what goes in the backup ZIP? Phase 3's answer: metadata only (~2KB per card), never rendered PNGs (~2MB each). Use "store the recipe, not the cake" — back up inputs, regenerate outputs on restore.

### 0.5 Write Test Cases Before Code

Write the test cases (both automated and UAT) as part of the design document. Phase 3 had 27 UAT cases + 44 unit/widget tests specified before any code was written. This serves as both a contract and a checklist.

---

## Phase 1: Foundation (models, data, migration)

### 1.1 Models First, DB Migration Last

Order: enums → models → test helpers → seed data → DB migration.

- **Enums first** because models reference them
- **Models with fromJson/toJson** to ensure DB column mapping is explicit
- **Test helpers** (`@visibleForTesting` methods) to enable testing without full DB setup
- **Seed data** in `StorageService._getDefault*()` — one canonical source per dataset
- **DB migration last** — only after models and seeds are finalized

### 1.2 JSON-Encode Complex Types for SQLite

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

### 1.3 `ALTER TABLE ADD COLUMN` Is Not Idempotent

Migrations using `ALTER TABLE ADD COLUMN` cannot be run twice. Don't write idempotency tests for them. Earlier migrations using `CREATE TABLE IF NOT EXISTS` ARE idempotent — don't mix the patterns.

```dart
if (oldVersion < 15) {
  await db.execute('ALTER TABLE templates ADD COLUMN name_en TEXT');
  // This will fail if run a second time
}
```

### 1.4 Seed Data: One Source, Zero Duplication

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

## Quick Reference: Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|----------|-----|
| Missing Provider in widget test | Silent failure or crash | Add provider to test's `MultiProvider` |
| Raw List in SQLite INSERT | `Invalid sql argument type` | `jsonEncode()` before insert |
| `BuildOwner.flushPaint()` | `undefined_method` error | Use `PipelineOwner.flushPaint()` |
| Redundant `buildScope()` | `_debugStateLocked` assertion | Remove — `mount()` calls it internally |
| `scrollUntilVisible` with nested scrollables | `Bad state: Too many elements` | Specify `scrollable: find.byType(Scrollable).first` |
| `toImage()` without paint | `!debugNeedsPaint` assertion | Ensure `pipelineOwner.flushPaint()` ran |
| Unregistered provider | Widget silently has no data | Register in `app.dart` MultiProvider |
| Hardcoded IDs in logic | Breaks on rename | Use named constants from model |
| Seed data in two places | Drift between sources | One canonical `_getDefault*()` method |
| `ALTER TABLE ADD COLUMN` run twice | `duplicate column name` error | Don't test idempotency for column additions |
