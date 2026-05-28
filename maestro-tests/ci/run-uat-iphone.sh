#!/bin/bash
# iPhone UAT — Keepsake Flows (10 flows)
# Usage: ./run-uat-iphone.sh --device <UUID>
set -euo pipefail

DEVICE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --device) DEVICE="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

if [ -z "$DEVICE" ]; then
  DEVICE="E755BD80-D6A2-4D4B-9FFA-0BEA131AE1EA"
fi

FLOW_DIR="$(dirname "$0")/../apps/blink-notes/flows/uat"

echo "=== iPhone UAT — Keepsake Flows ==="
echo "Device: $DEVICE"
echo "Flows:  k1-core-create  k2-template-cycle  k3-toggle-elements  k4-ai-rewrite"
echo "        k5-empty-content  k6-badge-preview  k7-photo-keepsake"
echo "        k8-locale-zh  k9-edit-keepsake  k10-three-entry-points"

PASS=0
FAIL=0

FIRST=1
for flow in k1-core-create k2-template-cycle k3-toggle-elements k4-ai-rewrite k5-empty-content k6-badge-preview k7-photo-keepsake k8-locale-zh k9-edit-keepsake k10-three-entry-points; do
  echo ""
  # Kill the Maestro XCTest runner before each flow so Maestro always starts
  # with a fresh driver. iOS 26.4 beta's XCTest accessibility layer becomes
  # unstable after ~45s of use; explicit kill + 25s wait guarantees a clean slate.
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
