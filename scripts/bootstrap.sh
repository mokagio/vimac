#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v bundle >/dev/null; then
  echo "bootstrap: Bundler is required (gem install bundler)." >&2
  exit 1
fi

bundle install

bundle exec pod install

# Test for the xcframework itself: a checkout that predates --use-xcframeworks
# leaves a Carthage/Build/Mac/ tree that satisfies a directory check while the
# build still fails for want of Carthage/Build/LaunchAtLogin.xcframework.
if [[ ! -d Carthage/Build/LaunchAtLogin.xcframework ]]; then
  carthage build --use-xcframeworks --platform macOS
else
  echo "bootstrap: LaunchAtLogin.xcframework present, skipping carthage build (delete to force)."
fi
