#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v bundle >/dev/null; then
  echo "bootstrap: Bundler is required (gem install bundler)." >&2
  exit 1
fi

bundle install
