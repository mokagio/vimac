#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

INSTALL_DIR="${INSTALL_DIR:-/Applications}"
DERIVED_DATA="${DERIVED_DATA:-build}"
BUILT_APP="$DERIVED_DATA/Build/Products/Release/Vimac.app"
INSTALLED_APP="$INSTALL_DIR/Vimac.app"

# The shipping id, with no `-dev`/`-test` suffix — see Config/Project.xcconfig.
BUNDLE_ID="$(sed -n 's/^BASE_BUNDLE_ID[[:space:]]*=[[:space:]]*//p' Config/Project.xcconfig)"
if [[ -z "$BUNDLE_ID" ]]; then
  echo "install: could not read BASE_BUNDLE_ID from Config/Project.xcconfig" >&2
  exit 1
fi

quit_running_instances() {
  local pids
  # Any Vimac.app, wherever it runs from: a dev build left running will fight
  # the installed one over the Accessibility API even under a different id.
  pids="$(pgrep -f "Vimac.app/Contents/MacOS/Vimac" || true)"
  [[ -z "$pids" ]] && return 0

  echo "install: quitting running Vimac ($(echo "$pids" | tr '\n' ' '))"
  # shellcheck disable=SC2086
  kill $pids 2>/dev/null || true

  for _ in $(seq 1 25); do
    pgrep -f "Vimac.app/Contents/MacOS/Vimac" >/dev/null || return 0
    sleep 0.2
  done

  echo "install: still running after 5s, forcing" >&2
  # shellcheck disable=SC2086
  kill -9 $pids 2>/dev/null || true
}

quit_running_instances

BUNDLE_ID_SUFFIX="" CONFIGURATION=Release DERIVED_DATA="$DERIVED_DATA" ./scripts/build.sh

if [[ ! -d "$BUILT_APP" ]]; then
  echo "install: expected a build at $BUILT_APP" >&2
  exit 1
fi

built_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$BUILT_APP/Contents/Info.plist")"
if [[ "$built_id" != "$BUNDLE_ID" ]]; then
  echo "install: built $built_id, expected $BUNDLE_ID — refusing to install" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
if [[ -e "$INSTALLED_APP" ]]; then
  rm -rf "$INSTALLED_APP"
fi

# `ditto` over `cp -R`: it preserves the bundle's metadata and code signature.
ditto "$BUILT_APP" "$INSTALLED_APP"
echo "install: installed $INSTALLED_APP ($built_id)"

open "$INSTALLED_APP"
