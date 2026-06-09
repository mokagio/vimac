#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-build}"

# BUILD_ENV=CI tells the Vimac target's LaunchAtLogin helper-signing phase to
# ad-hoc sign (codesign --sign -) rather than reach for a Developer ID identity
# a CLI/CI build doesn't have.
export BUILD_ENV=CI

# Use a distinct bundle id for dev builds so AppDelegate.isDuplicateAppInstance()
# doesn't terminate this build when the user's installed Vimac is running.
PRODUCT_BUNDLE_ID="${PRODUCT_BUNDLE_ID:-dexterleng.vimac.dev}"

xcodebuild \
  -workspace Vimac.xcworkspace \
  -scheme "Vimac (Vimac Workspace)" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  PRODUCT_BUNDLE_IDENTIFIER="$PRODUCT_BUNDLE_ID" \
  build
