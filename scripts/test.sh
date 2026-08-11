#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

DERIVED_DATA="${DERIVED_DATA:-build}"

# Tests keep ad-hoc signing: nothing here is installed or needs a stable TCC
# grant, and `BUILD_ENV=CI` is what tells the LaunchAtLogin helper-signing phase
# to use `codesign --sign -`.
export BUILD_ENV=CI

formatter=(cat)
command -v xcbeautify >/dev/null && formatter=(xcbeautify)

# VimacTests is the unit-test bundle. The UI-test target is skipped because it
# needs Accessibility permission granted to the test runner — run it manually
# with `xcodebuild test -only-testing:VimacUITests` when that prerequisite is met.
xcodebuild \
  -workspace Vimac.xcworkspace \
  -scheme "Vimac (Vimac Workspace)" \
  -configuration Debug \
  -derivedDataPath "$DERIVED_DATA" \
  -only-testing:VimacTests \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  BUNDLE_ID_SUFFIX='-test' \
  test | "${formatter[@]}"
