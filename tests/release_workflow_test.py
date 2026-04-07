#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path


WORKFLOW_PATH = Path(".github/workflows/release.yml")


def assert_contains(text: str, needle: str, message: str) -> None:
    if needle not in text:
        raise AssertionError(message)


def main() -> int:
    text = WORKFLOW_PATH.read_text(encoding="utf-8")

    assert_contains(text, "workflow_dispatch:", "release workflow should still support manual dispatch")
    assert_contains(text, "branches:", "release workflow should declare push branches")
    assert_contains(text, "- main", "release workflow should build on pushes to main")
    assert_contains(text, "tags:", "release workflow should still declare tag triggers")
    assert_contains(text, '- "v*"', "release workflow should publish on semantic tags")
    assert_contains(text, "if: startsWith(github.ref, 'refs/tags/v')", "publish job should only run for version tags")
    assert_contains(text, "pvz-godot-windows.zip", "workflow should package the Windows artifact")
    assert_contains(text, "pvz-godot-macos.zip", "workflow should package the macOS artifact")
    assert_contains(text, "pvz-godot-web.zip", "workflow should package the Web artifact")
    assert_contains(text, "pvz-godot-android.apk", "workflow should package the Android artifact")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
