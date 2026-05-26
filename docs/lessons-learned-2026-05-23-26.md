# Lessons Learned — May 23–26, 2026

> **Session:** Phase 3 Keepsake cards (full lifecycle: design → implementation → defect fixing → process)  
> **Duration:** Multi-day session | **Topics:** 12 lessons across 4 categories

---

## Category 1: Defect Fixing Anti-Patterns

### Lesson 1: Automation Failures ≠ Customer Bugs

The entirety of DEF-V-001 (7 versions) was an automation-only defect. The physical toggle worked for human users through all 7 iterations. The fix was 1 line: `Semantics(onTap:)`. We treated every Maestro report as P0 urgency, burning a full day on something that had zero customer impact.

**Rule:** After every failure report, ask: "Does this affect a real human user?" If finger taps work but Maestro fails → **P2-automation, batch fix at end of day.** Only drop everything for P0-human (crash, data loss, feature broken).

### Lesson 2: Request the Hierarchy Dump Before Writing Code

DEF-V-001 would have been a 1-commit fix if we had asked for the hierarchy dump on version 1. The dump clearly showed `text: ""` (no action) on the identified node. Instead, we guessed for 6 versions — changing SharedPreferences loading, widget structure, MergeSemantics wrappers, ListTile vs Row — none of which addressed the actual problem.

**Rule:** Every semantics/accessibility defect report MUST include a hierarchy dump. If it doesn't, request it before investigating. The dump answers "does this node have an action?" in 5 seconds. Guessing takes hours.

### Lesson 3: Double-Nested MergeSemantics Creates Silent Barriers

`SwitchListTile` has its own internal `MergeSemantics`. Wrapping it with an outer `MergeSemantics(child: Semantics(...))` creates a double-nested semantics barrier — the outer node absorbs the identifier but the inner node's actions are isolated behind it. Neither Maestro nor VoiceOver can reach the toggle handler.

**Rule:** Never wrap `SwitchListTile` with `MergeSemantics`. Use `Semantics(identifier:, onTap:, child: Switch(...))` directly, or use `ListTile` + `Switch` inside a plain `Semantics`.

### Lesson 4: Stack Trace ≠ Root Cause — Read the Hierarchy Dump

When Maestro reports "tap had no effect," the stack trace shows WHERE the tap failed, not WHY. The WHY is in the semantics tree: does the node have a tap action? Is it inside a MergeSemantics barrier? Is the identifier on a container node or an action node? The hierarchy dump answers all three. The stack trace answers none.

**Rule:** For any Maestro accessibility/tap failure, the hierarchy dump IS the root cause analysis tool. The Dart stack trace is supplementary.

---

## Category 2: Architecture & Implementation

### Lesson 5: Off-Screen Rendering Requires PipelineOwner, Not BuildOwner

`RenderRepaintBoundary.toImage()` failed with `'!debugNeedsPaint': is not true` because we called `buildOwner.flushPaint()`. `BuildOwner` manages the widget tree, not the render tree. Layout and paint require a `PipelineOwner` that's properly attached to the root render object before `element.mount()`.

**Rule:** The off-screen capture sequence is strict: attach `PipelineOwner` → `element.mount()` → `renderObject.layout()` → `pipelineOwner.flushLayout()` → `pipelineOwner.flushPaint()` → `renderObject.toImage()`. Never call `buildScope()` after `mount()` — it's redundant and causes `_debugStateLocked` assertions.

### Lesson 6: Model Field Addition Is a 7-Layer Write Chain

Adding one field (`voiceEnabled` to Routine) required changes in 7 places: model, `_onCreate` schema, `_onUpgrade` migration, `addRoutine()` INSERT map, `getRoutines()` SELECT map, repository pass-through, provider pass-through. Missing any layer = data works in memory but is lost on restart.

**Rule:** Use the model field checklist: `[ ] Model [ ] DB create [ ] DB migrate [ ] Storage insert [ ] Storage select [ ] Repository [ ] Provider [ ] Version test`.

### Lesson 7: `ALTER TABLE ADD COLUMN` Is Not Idempotent

Migrations using `ALTER TABLE ADD COLUMN` fail on second run with `duplicate column name`. `CREATE TABLE IF NOT EXISTS` IS idempotent — don't mix the patterns. Don't write idempotency tests for column additions.

**Rule:** The framework ensures migrations run exactly once per upgrade. Idempotency tests are a test artifact, not a production requirement.

### Lesson 8: `json.fuse(utf8).decode()` Halves Peak RAM

`json.decode(utf8.decode(bytes))` creates two copies (raw bytes → string → parsed). `json.fuse(utf8).decode(bytes)` fuses decode + parse into one step, avoiding the intermediate string allocation. For restore streaming, this saved ~62% peak RAM.

**Rule:** Anywhere you do `json.decode(utf8.decode(bytes))`, replace with `json.fuse(utf8).decode(bytes)`.

---

## Category 3: Process & Design

### Lesson 9: Use-Case Separation Prevents Scope Creep

Keepsake cards and XHS Export were originally one feature. They had conflicting requirements: single-page (keepsake) vs multi-page (XHS), photo-centric vs template-centric. Separating into two use cases reduced Phase 3 from 17 days to 11 and eliminated mixed UX.

**Rule:** Write each user goal as a single sentence. If you have two sentences, you have two features. Ship one. Defer the other.

### Lesson 10: "Store the Recipe, Not the Cake" for Backups

Keepsake cards rendered to ~2MB PNGs each. Storing all PNGs in backup would add 100MB for 50 cards. The backup stores metadata only (~2KB/card) and re-renders on demand. Deterministic rendering ensures identical output.

**Rule:** Never back up rendered output that can be regenerated. Back up inputs (content, template, config), regenerate outputs (PNGs) lazily.

### Lesson 11: Middleman Relay Creates Latency and Misinterpretation

All defect reports and build notifications flowed through a human middleman. This added latency, introduced interpretation errors, and made it impossible for dev to ask test for hierarchy dumps directly. The file-based protocol eliminates the middleman.

**Rule:** Structured files (`current.json`, `results.json`, `state.json`) are more reliable than chat messages. Each agent reads and writes directly. The PM reads an auto-generated dashboard. No one relays.

### Lesson 12: Classify Before Fixing — Severity Determines Urgency

Without a severity classification system, every defect was treated as equally urgent. DEF-V-001 (P2-automation) consumed as much attention as the multi-photo crash (P0-human). Adding a 4-tier severity system (P0/P1/P2/P3) and a "batch EOD for P2" rule would have saved a full day.

**Rule:** After receiving any defect report, classify severity before writing code. `P0-human` → fix now. `P1-human` → fix today. `P2-automation` → batch at end of day. `P3-cosmetic` → next release.
