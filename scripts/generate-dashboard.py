#!/usr/bin/env python3
"""
Generate DASHBOARD.md from .builds/state.json, current.json, results.json.
Readable status for PM and human stakeholders. Zero JSON in output.
"""

import json, os, sys
from datetime import datetime, timezone

BUILDS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".builds")

def load(path):
    try:
        with open(os.path.join(BUILDS_DIR, path)) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None

def icon(ok): return "✅" if ok else "❌"

def emoji_status(pass_count, fail_count):
    if fail_count == 0: return "✅"
    if pass_count == 0: return "🔴"
    return "🟡"

def main():
    state = load("state.json") or {}
    current = load("current.json") or {}
    results = load("results.json") or {}

    now = datetime.now(timezone.utc).strftime("%b %d, %Y %H:%M UTC")
    commit = current.get("commit", "—")
    fixes = ", ".join(current.get("fixes", [])) or "none"
    phase = state.get("phase", "—")

    # Test stats
    total_tests = current.get("tests", "—")
    analyze = current.get("analyze", "—")
    flaky = current.get("flaky", 0)

    # Maestro stats
    total_flows = results.get("total_flows", 0)
    passed_flows = results.get("passed_flows", 0)
    failed_flows = results.get("failed_flows", 0)

    # Platform breakdown
    platforms = results.get("platforms", {})

    # Manual UAT
    manual = state.get("manual_uat", {})
    manual_done = manual.get("completed", 0)
    manual_failed = manual.get("failed", 0)
    manual_total = manual.get("total", 8)
    manual_tester = manual.get("tester", "—")
    manual_last = manual.get("last_run", "—")

    # Manual UAT defects
    manual_defects = state.get("open_defects", [])
    manual_issues = [d for d in manual_defects if d.get("source") == "manual_uat"]

    # Defects
    open_defects = state.get("open_defects", [])
    verified = state.get("verified_defects", [])

    # Gate logic
    gates = []
    gates.append(("Code Complete", commit != "—"))
    gates.append(("Analyze 0 errors", analyze == "pass"))
    gates.append((f"{total_tests} tests", isinstance(total_tests, str) or total_tests > 0))
    gates.append((f"Maestro {passed_flows}/{total_flows}", failed_flows == 0))
    gates.append((f"Manual UAT {manual_done}/{manual_total}", manual_done >= manual_total))
    all_pass = all(g[1] for g in gates)

    # Blockers
    blockers = []
    if not gates[3][1]: blockers.append("Maestro failures — automation gaps remain")
    if not gates[4][1]: blockers.append("Manual UAT + visual QA not complete")
    for d in open_defects:
        if isinstance(d, dict) and d.get("severity", "").startswith("P0"):
            blockers.append(f"P0-human defect: {d.get('id', '?')} — {d.get('title', '?')}")

    # Platform table
    platform_rows = ""
    for plat, stats in platforms.items():
        p = stats.get("passed", 0)
        f = stats.get("failed", 0)
        platform_rows += f"| {plat} | {emoji_status(p, f)} {p}/{p+f} pass |\n"

    # Defect table
    defect_rows = ""
    for d in open_defects:
        if isinstance(d, dict):
            defect_rows += f"| {d.get('id','?')} | {d.get('severity','?')} | {d.get('title','?')} | Open |\n"
    for d in verified:
        if isinstance(d, dict):
            defect_rows += f"| {d.get('id','?')} | — | {d.get('title','?')} | ✅ Verified |\n"

    # Blockers section
    blocker_text = ""
    if blockers:
        blocker_text = "\n".join(f"- {icon(False)} {b}" for b in blockers)
    else:
        blocker_text = f"- {icon(True)} No blockers"

    dashboard = f"""# Build Dashboard — {now}

## Current Build
- **Commit**: `{commit}`
- **Fixes**: {fixes}
- **Status**: {phase}
- **Analyze**: {analyze}

## Gate Status
| Gate | Status |
|------|--------|
| {gates[0][0]} | {icon(gates[0][1])} |
| {gates[1][0]} | {icon(gates[1][1])} |
| {gates[2][0]} | {icon(gates[2][1])} |
| {gates[3][0]} | {icon(gates[3][1])} |
| {gates[4][0]} | {icon(gates[4][1])} |
| **Ship Gate** | {icon(all_pass)} {'ALL CLEAR' if all_pass else 'BLOCKED'} |

## Manual UAT
- **Progress**: {manual_done}/{manual_total} completed
- **Failed**: {manual_failed}
- **Tester**: {manual_tester}
- **Last run**: {manual_last}

## Platforms
| Platform | Status |
|----------|--------|
{platform_rows or '| — | No results yet |'}

## Open Defects
| ID | Severity | Title | Status |
|----|----------|-------|--------|
{defect_rows or '| — | — | No defects | — |'}

## Blockers
{blocker_text}

## What PM Should Know
- Phase: **{phase}**. Commit `{commit}` pushed{'with fixes: ' + fixes if fixes != 'none' else ''}.
- {total_tests} automated tests, {failed_flows} Maestro failures, {manual_done}/{manual_total} manual UAT done{' (' + str(manual_failed) + ' failures)' if manual_failed else ''}.
- {'**Ready to ship.**' if all_pass else '**Not ready.** ' + ' '.join(b.replace(chr(10060), '') for b in blockers) if blockers else '**Running Maestro + manual UAT.**'}
"""
    output = os.path.join(BUILDS_DIR, "DASHBOARD.md")
    with open(output, "w") as f:
        f.write(dashboard)
    print(f"DASHBOARD.md written ({len(dashboard)} bytes)")

if __name__ == "__main__":
    main()
