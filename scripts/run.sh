#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

DERIVED_DATA="${DERIVED_DATA:-build}"
APP_PATH="$DERIVED_DATA/Build/Products/Debug/Vimac.app"

if [[ ! -d "$APP_PATH" ]]; then
  echo "run: $APP_PATH missing — building first." >&2
  ./scripts/build.sh
fi

# `-n` forces a new instance so the dev build runs alongside any installed copy.
# Vimac will still terminate the second instance via isDuplicateAppInstance() if
# the bundle identifier matches; that's the AppDelegate's behavior, not ours.
echo "run: launching $APP_PATH"
open -n "$APP_PATH"
