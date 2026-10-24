#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

xcodebuild \
  -scheme twenty-rest \
  -destination 'platform=macOS' \
  -quiet \
  test
