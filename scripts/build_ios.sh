#!/bin/bash
# Build Blinking App IPA for App Store submission.
# For simulator testing, run WITHOUT RC_API_KEY (uses RevenueCat Test Store):
#   flutter build ios --debug --simulator --dart-define=TRIAL_API_KEY=... --dart-define=PRO_API_KEY=...
#
# For App Store submission, ALL 3 keys required:
# Usage: ./scripts/build_ios.sh
set -e

# ── Secrets (set via environment or CI) ──
RC_API_KEY="${RC_API_KEY:-}"
TRIAL_API_KEY="${TRIAL_API_KEY:-}"
PRO_API_KEY="${PRO_API_KEY:-}"

# ── Validate required keys ──
if [ -z "$RC_API_KEY" ]; then
  echo "ERROR: RC_API_KEY is required (RevenueCat Apple API key: appl_...)"
  echo "  For simulator testing, do NOT use this script — run flutter build without RC_API_KEY."
  exit 1
fi
if [ -z "$TRIAL_API_KEY" ]; then
  echo "ERROR: TRIAL_API_KEY is required."
  exit 1
fi
if [ -z "$PRO_API_KEY" ]; then
  echo "ERROR: PRO_API_KEY is required."
  exit 1
fi

echo "Building Blinking App for iOS (Release)..."
echo "  RC_API_KEY: ${RC_API_KEY:0:10}..."
echo "  TRIAL_API_KEY: ${TRIAL_API_KEY:0:10}..."
echo "  PRO_API_KEY: ${PRO_API_KEY:0:10}..."

flutter clean
flutter pub get

flutter build ipa --release \
  --dart-define=RC_API_KEY="$RC_API_KEY" \
  --dart-define=TRIAL_API_KEY="$TRIAL_API_KEY" \
  --dart-define=PRO_API_KEY="$PRO_API_KEY"

echo "✓ Build complete. IPA at: build/ios/ipa/"
