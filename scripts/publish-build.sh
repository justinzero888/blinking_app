#!/bin/bash
# publish-build.sh — write .builds/current.json after successful build.
# Run from repo root: bash scripts/publish-build.sh "fix: DEF-V-001" "card_builder.dart,settings.dart"
set -e

COMMIT=$(git rev-parse --short HEAD)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FIXES="$1"
FILES="$2"
TESTS=$(flutter test 2>&1 | tail -1 | grep -oE '[0-9]+ pass' || echo "N/A")
ANALYZE=$(flutter analyze --no-pub 2>&1 | grep -c "error" || echo "0")
FLAKY=$(flutter test 2>&1 | tail -1 | grep -oE '\-[0-9]+ flaky' | grep -oE '[0-9]+' || echo "0")

echo "Commit: $COMMIT"

# Ask for sim status
echo "Sim status (y/n)?"
echo -n "iPhone 17 Pro: "; read IPHONE
echo -n "iPad Air M4:   "; read IPAD
echo -n "Android:       "; read ANDROID

iphone_status="not installed"
ipad_status="not installed"
android_status="not installed"
[[ "$IPHONE" == "y" ]] && iphone_status="installed"
[[ "$IPAD" == "y" ]] && ipad_status="installed"
[[ "$ANDROID" == "y" ]] && android_status="installed"

# Write current.json
cat > .builds/current.json << EOF
{
  "commit": "$COMMIT",
  "timestamp": "$TIMESTAMP",
  "fixes": "$FIXES",
  "files_changed": "$FILES",
  "sim_status": {
    "iphone": "$iphone_status",
    "ipad": "$ipad_status",
    "android": "$android_status"
  },
  "analyze": "$([ "$ANALYZE" == "0" ] && echo 'pass' || echo 'fail')",
  "tests": "$TESTS",
  "flaky": $FLAKY
}
EOF

# Generate dashboard
python3 scripts/generate-dashboard.py

echo ""
echo "✅ .builds/current.json written"
echo "📊 .builds/DASHBOARD.md updated"
echo ""
echo "── Build Notification ──"
echo "🔨 Build ready — commit $COMMIT"
echo "   Fixes: $FIXES"
echo "   Files: $FILES"
echo "   Sims: iPhone $( [[ "$iphone_status" == "installed" ]] && echo '✅' || echo '⬜' ) | iPad $( [[ "$ipad_status" == "installed" ]] && echo '✅' || echo '⬜' ) | Android $( [[ "$android_status" == "installed" ]] && echo '✅' || echo '⬜' )"
