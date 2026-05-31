#!/bin/bash
# iPad UAT — Keepsake Flows (10 flows)
# Usage: ./run-uat-ipad.sh --device <UUID>
set -euo pipefail

DEVICE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --device) DEVICE="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

if [ -z "$DEVICE" ]; then
  DEVICE="39B46CD1-C3B5-43C1-B527-A5BCFECEA773"
fi

FLOW_DIR="$(dirname "$0")/../apps/blink-notes/flows/uat"

echo "=== iPad UAT — Keepsake + Purchase Flows ==="
echo "Device: $DEVICE"

PASS=0
FAIL=0
FIRST=1

for flow in k1-core-create k2-template-cycle k3-toggle-elements k4-ai-rewrite k5-empty-content k6-badge-preview k7-photo-keepsake k8-locale-zh k9-edit-keepsake k10-three-entry-points p1-paywall-ready; do
  echo ""
  if [ "$FIRST" -eq 0 ]; then
    xcrun simctl spawn "$DEVICE" pkill -f "maestro-driver-iosUITests-Runner" 2>/dev/null || true
    sleep 25
  fi
  FIRST=0
  echo "--- $flow ---"
  if maestro test --device "$DEVICE" "$FLOW_DIR/$flow.yaml"; then
    echo "✅ $flow PASSED"
    PASS=$((PASS + 1))
  else
    echo "❌ $flow FAILED"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
