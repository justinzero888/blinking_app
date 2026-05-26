#!/bin/bash
# publish-manual-uat.sh — human tester runs after completing manual UAT.
# Updates state.json with completed count and any defects found.
# Run from repo root: bash scripts/publish-manual-uat.sh <passed> <failed>

set -e

PASSED="${1:-0}"
FAILED="${2:-0}"
COMMIT=$(cat .builds/current.json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('commit','unknown'))" 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TESTER="${3:-unknown}"

# Update state.json with manual UAT progress
python3 -c "
import json, sys

with open('.builds/state.json') as f:
    state = json.load(f)

state['manual_uat']['completed'] = $PASSED
state['manual_uat']['failed'] = $FAILED
state['manual_uat']['last_run'] = '$TIMESTAMP'
state['manual_uat']['tester'] = '$TESTER'

# Read manual defects from uat/results.json
try:
    with open('.builds/uat/results.json') as f:
        results = json.load(f)
    for d in results.get('defects', []):
        if d.get('severity', '').startswith('P0') or d.get('severity', '').startswith('P1'):
            defect = {
                'id': f\"MUAT-{d.get('case','?')}\",
                'severity': d.get('severity', 'P2-automation'),
                'title': d.get('description', 'Manual UAT failure'),
                'source': 'manual_uat'
            }
            if defect not in state.get('open_defects', []):
                state.setdefault('open_defects', []).append(defect)
except: pass

with open('.builds/state.json','w') as f:
    json.dump(state, f, indent=2)

print(f'state.json updated: {state[\"manual_uat\"][\"completed\"]} passed, {FAILED} failed')
"

# Generate dashboard
python3 scripts/generate-dashboard.py

echo ""
echo "✅ Manual UAT results published"
echo "📊 .builds/DASHBOARD.md updated"
echo ""
echo "── Manual UAT Summary ──"
echo "$PASSED/$((PASSED + FAILED)) passed, $FAILED failed"
echo "Tester: $TESTER"
echo "Dev agent will detect state.json change and investigate."
