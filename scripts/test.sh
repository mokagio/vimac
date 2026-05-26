#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

DERIVED_DATA="${DERIVED_DATA:-build}"

# See scripts/build.sh for why BUILD_ENV=CI is set.
export BUILD_ENV=CI

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
  FRAMEWORK_SEARCH_PATHS='$(inherited) $(PROJECT_DIR)/Carthage/Build/Mac' \
  PRODUCT_BUNDLE_IDENTIFIER='dexterleng.vimac.test' \
  test
