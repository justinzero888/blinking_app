# Dev Cycle Playbook — Role Instructions

> **Purpose:** Each role knows exactly what to do, what to read, what to write, and where.  
> **Protocol:** File-based in `.builds/`. No chat relay. No APIs. Files ARE the notification.

---

## Cycle Overview

```
┌──────────┐    current.json    ┌──────────┐    results.json    ┌──────────┐
│ DEV      │ ────────────────── │ TEST     │ ────────────────── │ DEV      │
│ (agent)  │                    │ (agent)  │                    │ (agent)  │
└──────────┘                    └──────────┘                    └──────────┘
      │                               │                               │
      │  publish-build.sh             │  publish-results.sh           │
      │                               │                               │
      └───────────────┬───────────────┴───────────────┬───────────────┘
                      │                               │
               state.json                  DASHBOARD.md (auto)
                      │                               │
              ┌───────┴───────┐               ┌───────┴───────┐
              │ HUMAN TESTER  │               │      PM       │
              │ (manual UAT)  │               │  (dashboard)  │
              └───────────────┘               └───────────────┘
```

**Cycle length:** Dev pushes → test runs (< 5 min) → dev fixes → test verifies.  
**Poll interval:** Agents poll `state.json` every 60 seconds for timestamp changes.

---

## File Reference

| File | Written by | Read by | Format | Purpose |
|------|-----------|---------|--------|---------|
| `current.json` | Dev agent | Test agent, PM | JSON | What was built |
| `results.json` | Test agent | Dev agent, PM | JSON | Maestro test results |
| `state.json` | Both agents, human tester | Everyone | JSON | Shared phase + defect tracker |
| `DASHBOARD.md` | Auto-generated | PM, human | Markdown | Human-readable status |
| `uat/manual-checklist.md` | Dev agent (once) | Human tester | Markdown | Test cases to execute |
| `uat/results.json` | Human tester | Dev agent | JSON | Manual UAT results |
| `dumps/*.txt` | Test agent | Dev agent | Text | Hierarchy dumps for failures |

---

## 1. Dev Agent

### Your Job
Write code, push fixes, publish builds. Monitor test results. Fix defects.

### What You Monitor
- `.builds/results.json` — when `last_results` timestamp changes, new test results available
- `.builds/state.json` — when `open_defects` changes or `manual_uat.failed > 0`, new issues exist

### Before Every Build

```bash
# 1. Verify code health
flutter analyze --no-pub              # Must be 0 errors
flutter test                           # Must match or exceed previous pass count

# 2. Build all simulators
flutter build ios --simulator --debug
xcrun simctl install <iphone-uuid> build/ios/iphonesimulator/Runner.app
xcrun simctl install <ipad-uuid> build/ios/iphonesimulator/Runner.app
flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Publish
bash scripts/publish-build.sh "<fixes>" "<files>"
```

### publish-build.sh interaction

The script asks three questions. Answer honestly:

```
Sim status (y/n)?
iPhone 17 Pro: y    ← type y if app installed and opens
iPad Air M4:   y
Android:       y
```

If you couldn't install (Android storage, etc.), answer `n`. The dashboard will show which sims are ready.

### What publish-build.sh does

1. Reads commit hash, timestamp, test counts from flutter
2. Writes `.builds/current.json`
3. Regenerates `.builds/DASHBOARD.md`
4. Prints the build notification message (copy this to any chat channel if humans need it)

### When You See New Test Results

```bash
# Check if results exist for current build
cat .builds/results.json | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['summary'])"

# Check for failures
cat .builds/results.json | python3 -c "
import sys,json
r=json.load(sys.stdin)
for f in r['failures']:
    print(f'{f[\"flow\"]} ({f[\"platform\"]}): {f[\"error\"]}')
"
```

### When There Are Failures

1. Read `results.json` → identify failing flows and platforms
2. Read the hierarchy dump for each failure: `cat .builds/dumps/<flow>-<platform>.txt`
3. Classify severity using the dump + error message:

| What You See | Classification | Action |
|-------------|:---:|--------|
| `assertion` or `Null check` in Dart stack | P0-human | Fix immediately |
| `Node not found` or `identifier` issue in hierarchy dump | P2-automation | Batch at EOD |
| `tap` on interactive widget fails | Check dump for `hasAction` | If missing `onTap` → P2-automation. If button genuinely broken → P0-human |

4. Fix code
5. Update `state.json`:

```python
import json
with open('.builds/state.json') as f: s = json.load(f)
# Move verified defects from open_defects to verified_defects
# Add new defect IDs as needed
s['open_defects'] = [d for d in s['open_defects'] if d['id'] not in verified_ids]
s['verified_defects'].extend(verified)
with open('.builds/state.json','w') as f: json.dump(s, f, indent=2)
```

6. Go back to "Before Every Build"

### When You See Manual UAT Results

Check `state.json` → `manual_uat.failed > 0`. Read `uat/results.json` for details. Fix defects. Update state when fixed.

### What You NEVER Do
- Wait for a human to tell you there's a problem. Read the files.
- Guess the hierarchy dump content. Open the file.
- Iterate a fix without root cause analysis. Post root cause before next attempt.

---

## 2. Test Agent

### Your Job
Watch for new builds. Run Maestro flows. Publish results. Attach dumps for failures.

### What You Monitor
- `.builds/current.json` — when `commit` changes, new build available
- Check every 60 seconds: compare current commit hash with last tested

### Poll Loop

```bash
LAST_COMMIT=""
while true; do
  CURRENT=$(cat .builds/current.json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('commit',''))" 2>/dev/null)
  if [ "$CURRENT" != "$LAST_COMMIT" ] && [ -n "$CURRENT" ]; then
    echo "New build: $CURRENT"
    # Run test suite
    bash scripts/run-maestro.sh "$CURRENT"
    LAST_COMMIT="$CURRENT"
  fi
  sleep 60
done
```

### Running Tests — What to Execute

Read `current.json` → `files_changed` to determine which flows:

| Files Changed | Run |
|--------------|-----|
| `card_builder_sheet.dart` | k1-k10 (all keepsake flows) |
| `settings_screen.dart` | v1-voice-settings |
| `*.dart` (multiple files) | Full regression suite |
| No match | Full regression suite |

### When a Flow Fails

1. Save the hierarchy dump:

```bash
maestro test flows/uat/v1-voice-settings.yaml --format hierarchy > .builds/dumps/v1-voice-settings-iphone.txt
```

2. Classify severity:

| Symptom | Severity |
|---------|----------|
| App crash, blank screen, data loss | P0-human |
| Feature broken for all input methods | P1-human |
| Works with finger tap, fails with accessibility tap | P2-automation |
| Visual misalignment only | P3-cosmetic |

3. Build the failures array in `.builds/defects.json`:

```json
[
  {
    "flow": "v1-voice-settings",
    "platform": "iphone",
    "step": "toggle_voice_reminders",
    "error": "XCUITest tap had no effect — node has no action",
    "severity": "P2-automation",
    "defect_id": "DEF-V-001",
    "title": "Voice toggle accessibility node has no tap action",
    "hierarchy_dump": ".builds/dumps/v1-voice-settings-iphone.txt"
  }
]
```

4. Run the results publisher:

```bash
bash scripts/publish-results.sh <passed_count> <failed_count>
```

This updates `results.json`, `state.json`, and regenerates `DASHBOARD.md`.

### What publish-results.sh does

1. Reads `current.json` for commit hash
2. Reads `.builds/defects.json` for failure details
3. Writes `.builds/results.json` with pass/fail/platform breakdown
4. Updates `.builds/state.json`: sets `phase = 'testing'` (if failures) or `'verified'` (if all pass), records `last_results`
5. Regenerates `.builds/DASHBOARD.md`

### When All Flows Pass

```bash
# No defects file needed — just counts
IPHONE_PASS=22 IPHONE_FAIL=0 IPAD_PASS=20 IPAD_FAIL=0 ANDROID_PASS=22 ANDROID_FAIL=0 \
  bash scripts/publish-results.sh 22 0
```

The `state.json` updates to `phase: "verified"`. The Ship Gate on the dashboard turns green.

### What You NEVER Do
- Report a failure without a hierarchy dump. Dev needs it.
- Classify a failure as P0-human without confirming it affects a real user.
- Skip the severity classification. It determines dev's response priority.

---

## 3. Human Tester

### Your Job
Execute the manual UAT checklist on real devices. Report results. You are the ONLY role that uses real hardware.

### Before You Start

1. Ask the dev agent which build to test. Check `.builds/current.json` for the commit hash.
2. Get real devices: iPhone (physical, not simulator) and iPad (physical, not simulator).
3. The app should already be installed. If not, ask dev agent to install it.

### Executing the Checklist

1. Open `.builds/uat/manual-checklist.md`
2. Work through each case (MV-1 through MV-8)
3. Check the box `[x]` when a case passes
4. If a case fails, write a note: what you saw vs what you expected
5. For visual cases (MV-1, MV-2), take screenshots if something looks wrong

### After Completion

1. Edit `.builds/uat/results.json`:

```json
{
  "commit": "9b871ef",
  "timestamp": "2026-05-23T17:00:00Z",
  "tester": "Alice",
  "device": "iPhone 14 Pro (real)",
  "total_cases": 8,
  "passed": 6,
  "failed": 2,
  "defects": [
    {
      "case": "MV-3",
      "description": "Font color override — red selected but card shows black text",
      "severity": "P1-human",
      "screenshot": null
    },
    {
      "case": "MV-8",
      "description": "AI Rewrite button shows spinner forever, never completes",
      "severity": "P0-human",
      "screenshot": null
    }
  ]
}
```

2. Run the publisher:

```bash
bash scripts/publish-manual-uat.sh 6 2 "Alice"
```

This updates `state.json` with completion counts and any P0/P1 defects. The dev agent will pick it up.

### Classification Rules for Human Testers

| If... | Classify as |
|-------|-------------|
| App crashes, data lost, save doesn't work | P0-human |
| Feature works but output is wrong (wrong color, wrong text) | P1-human |
| Visual nitpick (alignment off by 1px) | P3-cosmetic |

When in doubt, ask: "Would a paying user complain about this?" If yes → P1. If they'd uninstall → P0.

### What You NEVER Do
- Test on a simulator. Simulators are not real devices. Use physical hardware.
- Report a defect without specifying the exact case number (MV-X).
- Forget to run `publish-manual-uat.sh` — until you do, the dev agent doesn't know you found anything.

---

## 4. Product Manager (PM)

### Your Job
Monitor the dashboard. Make product decisions. Escalate blockers. You do NOT relay messages.

### What You Open

One file: `.builds/DASHBOARD.md`

It auto-regenerates every time any agent publishes. You never need to run anything.

### How to Read the Dashboard

Look at three things, in order:

**1. Ship Gate — top of the dashboard**
```
| **Ship Gate** | ✅ ALL CLEAR |
```
Green = ready to ship. Red = BLOCKED — read the Blockers section.

**2. Blockers section**
```
- ❌ Maestro failures — automation gaps remain
- ❌ Manual UAT + visual QA not complete
```
Each blocker tells you what's preventing the release.

**3. Defects table**
```
| ID | Severity | Title | Status |
|----|----------|-------|--------|
| DEF-V-003 | P2-automation | Toggle hierarchy | Open |
| MUAT-MV-3 | P1-human | Font color wrong | Open |
```
P0-human = urgent. P1-human = must fix before release. P2-automation = can ship with. P3-cosmetic = defer.

### Decision Points

| Dashboard Signal | Your Action |
|-----------------|-------------|
| Ship Gate = ALL CLEAR | Approve release |
| Ship Gate = BLOCKED + P0-human defects | Ask dev for ETA. Consider delaying release. |
| Ship Gate = BLOCKED + only P2-automation | Approve release — automation gaps don't block human users |
| Manual UAT section shows failures | Read the defects. Decide if P1 issues are ship-blocking |
| Deferred scope table shows new items | Product decision: defer or re-prioritize? |

### What You NEVER Do
- Relay messages between dev and test. They read each other's files directly.
- Ask "what's the status?" — it's in the dashboard.
- Open a JSON file. The dashboard IS your interface.

---

## 5. State Machine Reference

The `state.json` `phase` field controls the cycle:

```
        ┌─────────────────────────────────┐
        │                                 │
        ▼                                 │
   ┌─────────┐    dev pushes    ┌─────────┐    all pass   ┌──────────┐
   │ testing │ ──────────────── │ testing │ ───────────── │ verified │
   │ (idle)  │                  │(running)│               │          │
   └─────────┘                  └─────────┘               └──────────┘
        ▲                            │                         │
        │                            │ failures                │ manual done
        │                            ▼                         ▼
        │                       ┌─────────┐              ┌───────────┐
        └─────────────────────── │ fixing  │◄─────────────│ deploying │
          dev fixes + publishes  │         │  ship blocked │           │
                                 └─────────┘              └───────────┘
```

**Phase transitions:**

| From | To | Trigger |
|------|----|---------|
| testing | testing | Dev pushes new build (`current.json` updated) |
| testing | verified | Test agent publishes all-pass results |
| testing | fixing | Test agent or human tester reports failures |
| fixing | testing | Dev pushes fix |
| verified | deploying | PM approves release |
| deploying | testing | New feature work begins |

The dev and test agents should update `phase` in `state.json` when they push results. The dashboard reflects the current phase.

---

## Quick Reference Card

### Dev Agent

```
Poll: state.json (60s)
Read: results.json, dumps/*.txt, uat/results.json
Run: bash scripts/publish-build.sh "<fixes>" "<files>"
Write: current.json, state.json (defects)
Key rule: P0-human → fix now. P2-automation → batch EOD.
```

### Test Agent

```
Poll: current.json (60s)
Read: current.json (files_changed → which flows)
Run: bash scripts/publish-results.sh <passed> <failed>
Write: results.json, defects.json, dumps/*.txt, state.json
Key rule: EVERY failure gets a hierarchy dump. No dump = not actionable.
```

### Human Tester

```
Read: uat/manual-checklist.md
Run: bash scripts/publish-manual-uat.sh <passed> <failed> <name>
Write: uat/results.json
Key rule: Real devices only. Run publish script when done.
```

### PM

```
Read: DASHBOARD.md (only)
Act on: Ship Gate BLOCKED, P0-human defects, deferred scope changes
Key rule: You never relay. Dashboard IS the status.
```
