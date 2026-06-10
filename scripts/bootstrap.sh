#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v bundle >/dev/null; then
  echo "bootstrap: Bundler is required (gem install bundler)." >&2
  exit 1
fi

bundle install

bundle exec pod install

if [[ ! -d Carthage/Build ]]; then
  carthage build --use-xcframeworks --platform macOS
else
  echo "bootstrap: Carthage/Build present, skipping carthage build (delete to force)."
fi
