#!/bin/bash
# Production build script for Blinking App — both platforms, single command.
# Usage: PRO_API_KEY=<key> TRIAL_API_KEY=<key> bash scripts/build-release.sh
# Keys are read from scripts/keys.sh (gitignored) or environment.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

# ── Keys ──────────────────────────────────────────────────────────
RC_IOS_KEY="${RC_IOS_KEY:-appl_vgTGaiNtCARgmdgOzpJcZyITNAT}"
RC_ANDROID_KEY="${RC_ANDROID_KEY:-goog_ITjNhBQowFMaFwdyZYvaCGqqioi}"
TRIAL_API_KEY="${TRIAL_API_KEY:-}"
PRO_API_KEY="${PRO_API_KEY:-}"

# ── Validate ──────────────────────────────────────────────────────
if [ -z "$TRIAL_API_KEY" ] || [ -z "$PRO_API_KEY" ]; then
  echo "ERROR: TRIAL_API_KEY and PRO_API_KEY must be set."
  echo "  export TRIAL_API_KEY=sk-or-v1-..."
  echo "  export PRO_API_KEY=sk-or-v1-..."
  exit 1
fi

echo "Building Blinking App — Release"
echo "  iOS key:     ${RC_IOS_KEY:0:10}..."
echo "  Android key: ${RC_ANDROID_KEY:0:10}..."
echo "  TRIAL key:   ${TRIAL_API_KEY:0:10}..."
echo "  PRO key:     ${PRO_API_KEY:0:10}..."

# ── Gate checks ───────────────────────────────────────────────────
cd "$ROOT"
flutter analyze --no-pub
flutter test

# ── Build (clean once, iOS first, Android second) ─────────────────
flutter clean
flutter pub get

echo ""
echo "=== Building iOS IPA ==="
flutter build ipa --release \
  --dart-define=RC_API_KEY="$RC_IOS_KEY" \
  --dart-define=TRIAL_API_KEY="$TRIAL_API_KEY" \
  --dart-define=PRO_API_KEY="$PRO_API_KEY"

echo ""
echo "=== Building Android AAB ==="
flutter build appbundle --release \
  --dart-define=RC_API_KEY="$RC_ANDROID_KEY" \
  --dart-define=TRIAL_API_KEY="$TRIAL_API_KEY" \
  --dart-define=PRO_API_KEY="$PRO_API_KEY"

# ── Verify ────────────────────────────────────────────────────────
IPA=$(ls build/ios/ipa/*.ipa 2>/dev/null | head -1)
AAB=$(ls build/app/outputs/bundle/release/*.aab 2>/dev/null | head -1)

if [ ! -f "$IPA" ]; then
  echo "ERROR: IPA not found"
  exit 1
fi
if [ ! -f "$AAB" ]; then
  echo "ERROR: AAB not found"
  exit 1
fi

# Check Android merged manifest for leaked media permissions
MEDIA_COUNT=$(unzip -p "$AAB" base/manifest/AndroidManifest.xml 2>/dev/null | strings | grep -c "READ_MEDIA\|READ_EXTERNAL_STORAGE\|CAMERA" || true)
if [ "$MEDIA_COUNT" -gt 0 ]; then
  echo "ERROR: $MEDIA_COUNT media permission(s) found in merged manifest. Build blocked."
  exit 1
fi

echo ""
echo "===================================="
echo "  Build complete"
echo "  IPA: $(ls -lh "$IPA" | awk '{print $5}')  $(basename "$IPA")"
echo "  AAB: $(ls -lh "$AAB" | awk '{print $5}')  $(basename "$AAB")"
echo "  Media permissions: 0 (verified)"
echo "===================================="
