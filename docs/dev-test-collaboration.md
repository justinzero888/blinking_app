# Dev–Test Collaboration Process

> **Goal:** Dev and test teams work directly without middleman relay.  
> **Trigger:** Dev pushes code → test team validates → bugs filed → dev fixes → cycle repeats.

---

## 1. Build Notification

### Dev team: After every push, post a build notification

Drop a message in the shared channel with this format:

```
🔨 Build ready — commit abc1234
   Files: card_builder_sheet.dart, settings_screen.dart
   What: DEF-V-001 v7 — added onTap to Semantics on Switch
   Sims: iPhone 17 Pro ✅ | iPad Air M4 ✅ | Android ✅
```

**Rule:** Never push code without a build notification. The test team doesn't monitor git — they monitor the channel.

### Dev team check before posting

| Check | Command |
|-------|---------|
| Analyze clean | `flutter analyze --no-pub` → 0 errors |
| Tests pass | `flutter test` → same flaky count as before |
| Sims installed | Verify app opens on all 3 devices |

---

## 2. Test Execution

### Test team: When a build notification arrives

1. Pull the latest `.yaml` flows from the repo
2. Run the full Maestro regression suite on all 3 simulators
3. Run any new keepsake flows for the changed files

### Test team: When a flow fails

**Do NOT relay through the middleman.** Open an issue directly in the bug tracker with:

```
Title: DEF-V-001 — Voice toggle OFF not persisting

Platform: iPhone 17 Pro, iPad Air M4, Android
Flow: v1-voice-settings
Commit tested: abc1234

Steps:
1. Toggle voice ON → ✅
2. Tap Test Voice → ✅
3. Toggle voice OFF → tap registers
4. Navigate to My Day → back to Settings
5. Toggle shows ON ❌ (expected OFF)

Evidence:
- Screenshot: [attached]
- Maestro hierarchy dump: [attached]
- Video: [attached if available]

Suspect: settings_screen.dart _buildVoiceToggle()
```

**Required attachments for every bug report:**
- [ ] Screenshot at failure point
- [ ] Maestro hierarchy dump showing the failing node
- [ ] Maestro flow name + step number that failed

### Test team: Severity classification

| Label | Meaning | Dev SLA |
|-------|---------|---------|
| `P0-human` | Affects real user (crash, data loss, feature broken) | Drop everything |
| `P1-human` | Degraded UX for real user | Fix same day |
| `P2-automation` | Maestro/VoiceOver only — human touch works | Fix in batch, end of day |
| `P3-cosmetic` | Visual only, no functional impact | Fix in next release |

---

## 3. Dev Investigation

### Dev team: When a bug is filed

**Before writing any code:**

1. Read the hierarchy dump — understand what the semantics tree looks like
2. Reproduce locally if possible (simulators are pre-installed)
3. Ask the test team for clarification directly (not through middleman)
4. Propose root cause + fix approach in the issue thread

### Dev team: Required fix format

```
Root cause: [1-2 sentences explaining WHY]
Fix: [1-2 sentences explaining WHAT changed]
Commit: abc1234
Verification: flutter analyze 0 errors, flutter test 558/556 pass
```

**Rule:** Never mark a bug as "fixed" without analyzer + test verification.

### Dev team: Direct questions to test team

Don't ask the middleman. Ask the test team directly:

- "Can you share the hierarchy dump for this node?"
- "Does this fail on iPhone only or all platforms?"
- "Can you re-run just flow v1-voice-settings with --verbose?"

---

## 4. Verification Loop

### After dev pushes a fix:

1. Dev posts build notification with `Fixes: DEF-V-001`  
2. Test team runs ONLY the affected flows (not full suite)
3. If pass: test team closes the issue
4. If fail: test team reopens with new evidence

### Shared definitions of "done"

| State | Meaning |
|-------|---------|
| **Open** | Bug reported, awaiting dev investigation |
| **In Progress** | Dev has proposed root cause + fix |
| **Fixed** | Dev pushed fix, awaiting test verification |
| **Verified** | Test team confirmed fix on all 3 platforms |
| **Closed** | Fix merged, no regressions |

---

## 5. Communication Rules

### For both teams

| Rule | Rationale |
|------|-----------|
| **No relay** | Test team files bugs directly. Dev team asks questions directly. Middleman only escalates. |
| **One bug, one issue** | Don't bundle multiple defects in one report |
| **Evidence required** | No screenshot + hierarchy dump = not actionable |
| **Reply in thread** | Keep all discussion on the issue, not in chat |
| **State updates** | Move the issue state, don't just say "fixed" in chat |

### Dev team specifically

- Tag test team on every build notification
- Respond to `P0-human` within 1 hour
- If you need more evidence, ask directly — don't guess
- If a fix fails verification, post a new root cause analysis before next attempt

### Test team specifically

- Classify severity on every bug report
- Include hierarchy dump for every accessibility/semantics failure
- Re-run only affected flows for verification (not full suite)
- If a fix passes on 2/3 platforms, log it as a separate issue for the failing platform

---

## 6. Shared Environment

| Resource | Location | Purpose |
|----------|----------|---------|
| Maestro flows | `maestro-tests/apps/blink-notes/flows/uat/` | Both teams have read/write |
| Bug tracker | GitHub Issues | Single source of truth for defects |
| Build artifacts | CI artifact store (future) | Test team downloads APK/IPA directly |
| Simulator UDIDs | Shared doc | Consistent device IDs across teams |
| Hierarchy dumps | Attached to issues | Required evidence for semantics bugs |

---

## Quick Reference

### Dev team cheat sheet

```
When pushing a fix:
1. flutter analyze → 0 errors
2. flutter test → same pass count
3. Post: "🔨 abc1234 — Fixes DEF-V-001 — all 3 sims ready"

When receiving a bug:
1. Read hierarchy dump first
2. Ask test team for missing evidence
3. Classify: P0/P1 human → fix now. P2 automation → batch at EOD.

When fix fails verification:
1. Post new root cause analysis
2. Don't iterate blindly — understand WHY the previous fix failed
```

### Test team cheat sheet

```
When receiving a build:
1. Run affected flows only
2. If pass → close related issues
3. If fail → file new issue with: screenshot + hierarchy dump + steps

When filing a bug:
1. Label severity: P0-human / P1-human / P2-automation / P3-cosmetic
2. Attach hierarchy dump for EVERY semantics/accessibility failure
3. Include commit hash you tested against
```
