#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

"$ROOT/scripts/check-tests-have-expects.py"

xcodebuild \
  -scheme twenty-rest \
  -destination 'platform=macOS' \
  -quiet \
  test
