#!/usr/bin/env bash
# run-uat-ipad.sh — v1.2.0+56 UAT: full coverage minus iPad share-sheet exclusions
# Usage: ./ci/run-uat-ipad.sh [--device <udid>]
#
# Fuluo 001: r/v/e flows added. Excludes s1-s2 (share-sheet not reliable on iPad)
# and Android-only a1/a2.

set -euo pipefail
export PATH="$PATH:$HOME/.maestro/bin"

FLOWS_DIR="apps/blink-notes/flows/uat"
DEVICE_FLAG=""
DEVICE_UDID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) DEVICE_UDID="$2"; DEVICE_FLAG="--device $2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Auto-detect booted iPad when no --device given
if [[ -z "$DEVICE_UDID" ]]; then
  DEVICE_UDID=$(xcrun simctl list devices booted 2>/dev/null | grep -E "iPad" | head -1 | grep -oE '[A-F0-9-]{36}' || true)
fi

# Pre-clear voice_notifications_enabled so v1 always starts with voice OFF
if [[ -n "$DEVICE_UDID" ]]; then
  xcrun simctl spawn "$DEVICE_UDID" defaults delete "com.blinking.blinking" "flutter.voice_notifications_enabled" 2>/dev/null || true
fi

IPAD_FLOWS=(
  "${FLOWS_DIR}/k1-core-create.yaml"
  "${FLOWS_DIR}/k2-ipad-create.yaml"
  "${FLOWS_DIR}/k3-android-create.yaml"
  "${FLOWS_DIR}/k4-template-browse.yaml"
  "${FLOWS_DIR}/k5-toggle-overlays.yaml"
  "${FLOWS_DIR}/k6-edit-keepsake.yaml"
  "${FLOWS_DIR}/k7-locale.yaml"
  "${FLOWS_DIR}/k8-reflection-entry.yaml"
  "${FLOWS_DIR}/k9-photo-integration.yaml"
  "${FLOWS_DIR}/k10-badge-mapping.yaml"
  "${FLOWS_DIR}/p1-paywall-ready.yaml"
  "${FLOWS_DIR}/p1-persona-switch.yaml"
  "${FLOWS_DIR}/p2-custom-persona.yaml"
  "${FLOWS_DIR}/p2-paywall-cta-smoke.yaml"
  "${FLOWS_DIR}/r1-entry-crud.yaml"
  "${FLOWS_DIR}/r2-checklist-entry.yaml"
  "${FLOWS_DIR}/r3-routine-crud.yaml"
  "${FLOWS_DIR}/r4-ai-chat.yaml"
  "${FLOWS_DIR}/r5-insights.yaml"
  "${FLOWS_DIR}/r6-calendar.yaml"
  "${FLOWS_DIR}/r7-language-toggle.yaml"
  "${FLOWS_DIR}/s3-s4-backup-export.yaml"
  "${FLOWS_DIR}/s5-s6-habit-export.yaml"
  "${FLOWS_DIR}/s9-habit-import.yaml"
  "${FLOWS_DIR}/v1-voice-settings.yaml"
  "${FLOWS_DIR}/v2-voice-per-routine.yaml"
  "${FLOWS_DIR}/v3-voice-persist.yaml"
  "${FLOWS_DIR}/v4-voice-dynamic.yaml"
  "${FLOWS_DIR}/e1-preview-mode.yaml"
  "${FLOWS_DIR}/e2-debug-restricted.yaml"
  "${FLOWS_DIR}/e3-debug-preview.yaml"
)

echo "=== Blink Notes — iPad UAT (30 flows: k+p+r+s+v+e, excl s1-s2 share-sheet) ==="
echo ""

maestro $DEVICE_FLAG test "${IPAD_FLOWS[@]}"
