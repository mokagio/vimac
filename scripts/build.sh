#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-build}"

# Suffix the bundle id so AppDelegate.isDuplicateAppInstance() doesn't terminate
# this build when the user's installed Vimac is running. Pass an empty string to
# build under the shipping id. The base lives in Config/Project.xcconfig.
BUNDLE_ID_SUFFIX="${BUNDLE_ID_SUFFIX--dev}"

# Derived rather than passed separately, so overriding the id suffix alone
# cannot leave a build called "Vimac Dev" carrying the shipping identifier.
BUNDLE_NAME_SUFFIX=""
if [[ -n "$BUNDLE_ID_SUFFIX" ]]; then
  bare="${BUNDLE_ID_SUFFIX#-}"
  BUNDLE_NAME_SUFFIX=" $(printf '%s' "${bare:0:1}" | tr '[:lower:]' '[:upper:]')${bare:1}"
fi

formatter=(cat)
command -v xcbeautify >/dev/null && formatter=(xcbeautify)

xcodebuild \
  -project Vimac.xcodeproj \
  -scheme Vimac \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  BUNDLE_ID_SUFFIX="$BUNDLE_ID_SUFFIX" \
  BUNDLE_NAME_SUFFIX="$BUNDLE_NAME_SUFFIX" \
  build | "${formatter[@]}"
