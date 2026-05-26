#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

DERIVED_DATA="${DERIVED_DATA:-build}"
APP_PATH="$(pwd)/$DERIVED_DATA/Build/Products/Debug/Vimac.app"
OUTPUT_DIR="${OUTPUT_DIR:-tmp/screenshots}"
WINDOW_NAME="${WINDOW_NAME:-General}"  # Preferences pane titles: General/Bindings/...

if [[ ! -d "$APP_PATH" ]]; then
  echo "screenshot: $APP_PATH missing — building first." >&2
  ./scripts/build.sh
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Contents/Info.plist")"
mkdir -p "$OUTPUT_DIR"

# Launch the dev build via `open -nb` so we get the PID of *this* instance,
# independent of any installed Vimac the user might already have running.
open -nb "$bundle_id" -a "$APP_PATH"

# Wait for the process to appear (up to ~5s) and capture its PID.
pid=""
for _ in $(seq 1 25); do
  pid="$(pgrep -f "$APP_PATH/Contents/MacOS/Vimac" | head -n1 || true)"
  [[ -n "$pid" ]] && break
  sleep 0.2
done

if [[ -z "$pid" ]]; then
  echo "screenshot: dev Vimac never appeared in pgrep — aborting" >&2
  exit 1
fi

# Target the dev build by its unique bundle id, not by display name (which
# collides with the installed Vimac). `applicationShouldHandleReopen` triggers
# `openPreferences()` in AppDelegate.
osascript -e "tell application id \"$bundle_id\" to activate" >/dev/null 2>&1 || true
osascript <<APPLESCRIPT >/dev/null 2>&1 || true
tell application "System Events"
    set frontmost of (first process whose unix id is $pid) to true
    -- Cmd+,
    keystroke "," using {command down}
end tell
APPLESCRIPT

# Let the Preferences window finish opening before we look for it.
sleep 1.5

timestamp="$(date +%Y%m%d-%H%M%S)"
output="$OUTPUT_DIR/preferences-$timestamp.png"

window_id="$(swift scripts/_find_window_id.swift "$pid" "$WINDOW_NAME" 2>/dev/null || true)"

if [[ -n "$window_id" ]]; then
  echo "screenshot: capturing window $window_id → $output"
  screencapture -l "$window_id" -o -x "$output"
else
  echo "screenshot: no window from PID $pid matching '$WINDOW_NAME' — falling back to full display" >&2
  screencapture -x "$output"
fi

if [[ ! -s "$output" ]]; then
  echo "screenshot: capture produced empty file at $output" >&2
  exit 1
fi

ls -lh "$output"
