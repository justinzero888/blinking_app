#!/bin/bash
# publish-results.sh — write .builds/results.json after Maestro test run.
# Run from repo root: bash scripts/publish-results.sh <passed> <failed>

set -e

PASSED="${1:-0}"
FAILED="${2:-0}"
TOTAL=$((PASSED + FAILED))
COMMIT=$(cat .builds/current.json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('commit','unknown'))" 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Platform stats — override with real values
IPHONE_PASS=${IPHONE_PASS:-$PASSED}
IPHONE_FAIL=${IPHONE_FAIL:-$FAILED}
IPAD_PASS=${IPAD_PASS:-$PASSED}
IPAD_FAIL=${IPAD_FAIL:-$FAILED}
ANDROID_PASS=${ANDROID_PASS:-$PASSED}
ANDROID_FAIL=${ANDROID_FAIL:-$FAILED}

# Build failures array from defects file
FAILURES_JSON="[]"
if [ -f ".builds/defects.json" ]; then
  FAILURES_JSON=$(cat .builds/defects.json)
fi

cat > .builds/results.json << EOF
{
  "commit": "$COMMIT",
  "timestamp": "$TIMESTAMP",
  "summary": "$PASSED/$TOTAL passed, $FAILED failed",
  "total_flows": $TOTAL,
  "passed_flows": $PASSED,
  "failed_flows": $FAILED,
  "platforms": {
    "iphone": { "passed": $IPHONE_PASS, "failed": $IPHONE_FAIL },
    "ipad":   { "passed": $IPAD_PASS, "failed": $IPAD_FAIL },
    "android":{ "passed": $ANDROID_PASS, "failed": $ANDROID_FAIL }
  },
  "failures": $FAILURES_JSON
}
EOF

# Update state
if [ "$FAILED" -gt 0 ]; then
  python3 -c "
import json
with open('.builds/state.json') as f: s=json.load(f)
s['last_results']='$COMMIT'
s['phase']='testing'
with open('.builds/state.json','w') as f: json.dump(s,f,indent=2)
"
else
  python3 -c "
import json
with open('.builds/state.json') as f: s=json.load(f)
s['last_results']='$COMMIT'
s['phase']='verified'
with open('.builds/state.json','w') as f: json.dump(s,f,indent=2)
"
fi

# Generate dashboard
python3 scripts/generate-dashboard.py

echo ""
echo "✅ .builds/results.json written"
echo "📊 .builds/DASHBOARD.md updated"
echo ""
echo "── Test Results ──"
echo "$PASSED/$TOTAL passed, $FAILED failed"
