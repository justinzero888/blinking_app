#!/usr/bin/env bash
# run-uat-android.sh — v1.2.0+56 UAT: full coverage (k+p+r+s+v+a+e — 34 flows)
# Usage: ./ci/run-uat-android.sh [--device <id>]
#
# Fuluo 001: r/s/v/a/e flows added. Android TTS broken on emulator (v1–v4 may fail).

set -euo pipefail
export PATH="$PATH:$HOME/.maestro/bin"

DEVICE_FLAG=""
ANDROID_SERIAL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device) ANDROID_SERIAL="$2"; DEVICE_FLAG="--device $2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Default to first connected emulator/device
if [[ -z "$ANDROID_SERIAL" ]]; then
  ANDROID_SERIAL=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {print $1; exit}' || true)
fi

# Pre-clear voice_notifications_enabled so v1 always starts with voice OFF
if [[ -n "$ANDROID_SERIAL" ]]; then
  adb -s "$ANDROID_SERIAL" shell run-as com.blinking.blinking \
    sh -c "rm -f /data/data/com.blinking.blinking/shared_prefs/FlutterSharedPreferences.xml" 2>/dev/null || true
fi

FLOWS_DIR="apps/blink-notes/flows/uat"

ANDROID_FLOWS=(
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
  "${FLOWS_DIR}/s1-s2-entry-share.yaml"
  "${FLOWS_DIR}/s3-s4-backup-export.yaml"
  "${FLOWS_DIR}/s5-s6-habit-export.yaml"
  "${FLOWS_DIR}/s9-habit-import.yaml"
  "${FLOWS_DIR}/v1-voice-settings.yaml"
  "${FLOWS_DIR}/v2-voice-per-routine.yaml"
  "${FLOWS_DIR}/v3-voice-persist.yaml"
  "${FLOWS_DIR}/v4-voice-dynamic.yaml"
  "${FLOWS_DIR}/a1-android-entry-share.yaml"
  "${FLOWS_DIR}/a2-android-backup-export.yaml"
  "${FLOWS_DIR}/e1-preview-mode.yaml"
  "${FLOWS_DIR}/e2-debug-restricted.yaml"
  "${FLOWS_DIR}/e3-debug-preview.yaml"
)

echo "=== Blink Notes — Android UAT (34 flows: k+p+r+s+v+a+e) ==="
echo ""

maestro $DEVICE_FLAG test "${ANDROID_FLOWS[@]}"
