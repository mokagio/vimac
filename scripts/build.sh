#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-build}"

# Suffix the bundle id so AppDelegate.isDuplicateAppInstance() doesn't terminate
# this build when the user's installed Vimac is running. Pass an empty string to
# build under the shipping id. The base lives in Config/Project.xcconfig.
BUNDLE_ID_SUFFIX="${BUNDLE_ID_SUFFIX--dev}"

formatter=(cat)
command -v xcbeautify >/dev/null && formatter=(xcbeautify)

xcodebuild \
  -workspace Vimac.xcworkspace \
  -scheme "Vimac (Vimac Workspace)" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  BUNDLE_ID_SUFFIX="$BUNDLE_ID_SUFFIX" \
  build | "${formatter[@]}"
