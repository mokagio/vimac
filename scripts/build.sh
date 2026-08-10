#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-build}"

# BUILD_ENV=CI tells the Vimac target's LaunchAtLogin helper-signing phase to
# ad-hoc sign (codesign --sign -) rather than reach for a Developer ID identity
# a CLI/CI build doesn't have.
export BUILD_ENV=CI

# Suffix the bundle id so AppDelegate.isDuplicateAppInstance() doesn't terminate
# this build when the user's installed Vimac is running. Pass an empty string to
# build under the shipping id. The base lives in Config/Project.xcconfig.
BUNDLE_ID_SUFFIX="${BUNDLE_ID_SUFFIX--dev}"

xcodebuild \
  -workspace Vimac.xcworkspace \
  -scheme "Vimac (Vimac Workspace)" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  BUNDLE_ID_SUFFIX="$BUNDLE_ID_SUFFIX" \
  build
