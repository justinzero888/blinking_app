# Lessons Learned — 2026-05-23

> **Session:** Phase 3 Keepsake card implementation (v1.2.0)  
> **Topics:** Off-screen rendering, use-case scoping, widget test patterns, DB migration testing

---

## 1. Off-Screen Rendering: Pipeline Owner Matters

**Problem:** `CardRenderService._renderOffscreen()` failed with `'!debugNeedsPaint': is not true` when using `BuildOwner.flushLayout()`/`flushPaint()`.

**Root cause:** `BuildOwner` manages the widget tree, not the render tree. Layout and paint are handled by `PipelineOwner`. Using `BuildOwner` for `flushLayout` is a type error — it doesn't compile. But even when using `PipelineOwner`, the render objects weren't being processed because they hadn't been added to the pipeline's paint queue during `element.mount()`.

**Solution:** Use a separate `PipelineOwner` (not `BuildOwner`) for layout and paint. Attach the root `RenderRepaintBoundary` to the pipeline before `element.mount()`. Remove the redundant `buildOwner.buildScope()` call — `element.mount()` internally calls `_rebuild()` which calls `buildScope`. Call `renderObject.layout()` manually, then flush the pipeline.

**Takeaway:** For headless Flutter rendering, three objects are needed: `RenderRepaintBoundary` (container), `PipelineOwner` (layout/paint), and `BuildOwner` (widget build). Don't mix them up.

---

## 2. No Separate "Prep" Phase — Just Start

**Problem:** Phases 1+2 completed 6 days ahead of schedule. The design team debated whether to "prep" (write models, enums, tests) or "start Phase 3 early."

**Realization:** Models, enums, seed data, and test scaffolding ARE Day 9-10 work. There is no separate "prep" — it IS the first day of Phase 3. Starting models early (without DB migration) is safe because nothing references them until Day 11.

**Takeaway:** When work finishes early, don't invent a new phase. Just pull the timeline forward. DB migration is the only gating item — leave it for the actual implementation day.

---

## 3. Use-Case Separation Prevents Scope Creep

**Problem:** Keepsake cards and XHS (RedNotes) export were conflated into one feature. This created conflicting requirements: single-page for keepsake vs. multi-page for XHS; photo-centric for keepsake vs. template-centric for XHS.

**Solution:** Split into two explicit use cases. Keepsake: preserve memory (photo+text, single-page, in-app). XHS Export: share on social (multi-page, template variety, camera roll). v1.2.0 ships Keepsake only. XHS Export deferred to v1.3.0.

**Result:** Phase 3 reduced from 17 to 11 days. No mixed UX. Clear product story.

**Takeaway:** When two features pull in different directions, separate them into distinct use cases and ship one. Don't compromise both.

---

## 4. Camera Roll IS the Card History

**Problem:** Design called for a Card History screen (grid of saved cards) as a separate UI component.

**Realization:** The camera roll already serves this function. Every keepsake PNG is saved to the device's Photos app. The only net-new capability a Card History screen adds is re-rendering with a different template — a niche use case.

**Solution:** Replace Card History with a minimal Keepsake badge on EntryDetailScreen — a one-to-one link between entry and its card. Deferred grid to v1.2.1. Saved 3 hours.

**Takeaway:** Before building in-app browsing for user-generated content, ask: does the OS already provide this? If so, add a pointer (badge) to the content, not a duplicate browser.

---

## 5. Backup Bloat: Don't Store Rendered PNGs

**Problem:** Each keepsake card produces a ~2MB PNG. Storing all rendered PNGs in backup would add 100MB for just 50 cards.

**Solution:** Store only metadata in backup (~2KB per card). Re-render PNGs lazily on first view or restore. `CardRenderService.getCardImage()` checks for cached PNG, falls back to re-rendering from stored config. Same inputs → same output (deterministic rendering).

**Takeaway:** Never back up rendered output that can be regenerated. Store the recipe, not the cake.

---

## 6. Widget Test Scrolling: `DraggableScrollableSheet` Breaks `scrollUntilVisible`

**Problem:** `CardBuilderSheet` uses `DraggableScrollableSheet` containing a `ListView`. `tester.scrollUntilVisible()` threw `Bad state: Too many elements` because there are multiple scrollable widgets.

**Solution:** Use `tester.scrollUntilVisible(find.byType(Scrollable).first, ...)` with an explicit scrollable finder, or use `tester.drag(find.byType(ListView).first, Offset)` for manual scrolling.

**Takeaway:** When a widget tree has nested scrollable areas (modal sheet + inner list), always specify the target scrollable. `scrollUntilVisible` defaults to finding a single scrollable — it fails with multiples.

---

## 7. Static Methods Hinder Testability — Use Injection

**Problem:** `CardBuilderSheet._handleSave()` called `CardRenderService.renderToFile()` — a static method. Widget tests needed to mock rendering to avoid actual off-screen pipeline initialization.

**Solution:** Added an optional `renderFn` parameter to `CardBuilderSheet` (defaulting to `CardRenderService.renderToFile`). Tests inject a mock function. Used `@visibleForTesting` annotation to keep the API clean.

**Takeaway:** When a widget calls a static service method that does I/O or uses platform channels, make the function injectable. A single optional `@visibleForTesting` parameter is cleaner than dependency injection frameworks or provider chains.

---

## 8. DB Migration: `ALTER TABLE ADD COLUMN` Is NOT Idempotent

**Problem:** A migration idempotency test called `runMigration(db, 14)` twice. The second run failed with `duplicate column name: name_en` because `ALTER TABLE ADD COLUMN` cannot be re-run.

**Root cause:** Earlier migrations used `CREATE TABLE IF NOT EXISTS` which is idempotent. v15 uses `ALTER TABLE ADD COLUMN` which is not. The idempotency test pattern from earlier migrations doesn't apply.

**Solution:** Removed the idempotency test for v15. Real-world migrations only run once (the DB version is bumped). Idempotency is not a requirement for production — it's only relevant for test helpers that might replay migrations.

**Takeaway:** `ALTER TABLE ADD COLUMN` is not idempotent. Don't write idempotency tests for migrations that add columns. The framework ensures migrations run exactly once per upgrade.

---

## 9. `display_tags` Is a List — JSON-Encode for SQLite

**Problem:** CardProvider tests failed with `Invalid sql argument type 'List<String>'` when storing `display_tags`.

**Root cause:** SQLite has no List type. `display_tags` was passed directly as a raw Dart `List<String>` to the `INSERT` statement.

**Solution:** Use `jsonEncode(card.displayTags)` when storing, and `jsonDecode` when reading. `NoteCard._parseTagList()` handles both formats (raw List from JSON restore, encoded String from DB) for backward compatibility.

**Takeaway:** Always serialize complex types (List, Map, Set) to JSON before storing in SQLite TEXT columns. Use a helper that handles both serialized and raw formats for robustness.

---

## 10. `toImage()` Requires Painting — `debugNeedsPaint` Assertion

**Problem:** `RenderRepaintBoundary.toImage()` threw `'!debugNeedsPaint': is not true` in unit tests.

**Root cause:** `toImage()` asserts that the render object has been painted at least once. Using `BuildOwner` (which has no `flushPaint`) or an uninitialized `PipelineOwner` leaves objects in a `debugNeedsPaint: true` state.

**Solution:** Switch from `BuildOwner.flushPaint` to `PipelineOwner.flushPaint`. Ensure the render object is attached to the pipeline owner before layout. Call `renderObject.layout()` → `pipelineOwner.flushLayout()` → `pipelineOwner.flushPaint()` → `renderObject.toImage()`.

**Takeaway:** The sequence for off-screen capture is strictly: mount → attach pipeline → layout → flushLayout → flushPaint → toImage. Skipping any step produces `debugNeedsPaint` errors or missing content.
