#!/usr/bin/env python3
"""Fail if a @Test function body has neither #expect nor #require."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEST_ROOT = ROOT / "twenty-restTests"

FUNC_RE = re.compile(
    r"@Test(?:\([^)]*\))?\s*\n\s*func\s+(\w+)\s*\([^)]*\)\s*"
    r"(?:async\s+)?(?:throws\s+)?\{",
    re.MULTILINE,
)


def function_body(source: str, body_start: int) -> str:
    depth = 1
    i = body_start
    while i < len(source) and depth:
        ch = source[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        i += 1
    return source[body_start : i - 1]


def main() -> int:
    if not TEST_ROOT.is_dir():
        print(f"missing test root: {TEST_ROOT}", file=sys.stderr)
        return 1

    failures: list[str] = []
    for path in sorted(TEST_ROOT.rglob("*.swift")):
        source = path.read_text(encoding="utf-8")
        for match in FUNC_RE.finditer(source):
            name = match.group(1)
            body = function_body(source, match.end())
            if "#expect" not in body and "#require" not in body:
                rel = path.relative_to(ROOT)
                failures.append(f"{rel}: {name}()")

    if failures:
        print("Tests missing #expect/#require:", file=sys.stderr)
        for item in failures:
            print(f"  {item}", file=sys.stderr)
        return 1

    print("All @Test functions include #expect or #require.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
