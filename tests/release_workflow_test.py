#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path


WORKFLOW_PATH = Path(".github/workflows/release.yml")


def assert_contains(text: str, needle: str, message: str) -> None:
    if needle not in text:
        raise AssertionError(message)


def main() -> int:
    text = WORKFLOW_PATH.read_text(encoding="utf-8")

    pages_deploy_condition = """if: |
      startsWith(github.ref, 'refs/tags/v') ||
      github.event.inputs.release_tag != '' ||
      (github.event_name == 'push' && github.ref == 'refs/heads/main')"""

    assert_contains(text, "workflow_dispatch:", "release workflow should still support manual dispatch")
    assert_contains(text, "build_ref:", "manual dispatch should accept an explicit build ref")
    assert_contains(text, "release_tag:", "manual dispatch should accept an explicit release tag")
    assert_contains(text, "pages: write", "release workflow should request Pages write permission for GitHub Pages deployments")
    assert_contains(text, "id-token: write", "release workflow should request id-token permission for GitHub Pages deployments")
    assert_contains(text, "branches:", "release workflow should declare push branches")
    assert_contains(text, "- main", "release workflow should build on pushes to main")
    assert_contains(text, "tags:", "release workflow should still declare tag triggers")
    assert_contains(text, '- "v*"', "release workflow should publish on semantic tags")
    assert_contains(text, "ref: ${{ github.event.inputs.build_ref || github.ref }}", "checkout should support building a different ref during manual dispatch")
    assert_contains(text, "if: startsWith(github.ref, 'refs/tags/v')", "publish job should only run for version tags")
    assert_contains(
        text,
        pages_deploy_condition,
        "deploy_pages should run for version tags, manual release dispatches, and pushes to main so GitHub Pages stays current",
    )
    assert_contains(text, "actions/upload-pages-artifact@v4", "release workflow should upload a dedicated GitHub Pages artifact")
    assert_contains(text, "actions/deploy-pages@v4", "release workflow should deploy the Pages artifact with deploy-pages")
    assert_contains(text, "environment:\n      name: github-pages", "release workflow should deploy Pages through the github-pages environment")
    assert_contains(text, 'touch build/releases/pages/.nojekyll', "release workflow should add a .nojekyll marker to the Pages payload")
    assert_contains(text, 'test -f build/releases/pages/index.html', "release workflow should verify that the Pages payload contains index.html before upload")
    assert_contains(text, "pvz-godot-windows.zip", "workflow should package the Windows artifact")
    assert_contains(text, "pvz-godot-macos.zip", "workflow should package the macOS artifact")
    assert_contains(text, "pvz-godot-web.zip", "workflow should package the Web artifact")
    assert_contains(text, "pvz-godot-android.apk", "workflow should package the Android artifact")
    assert_contains(text, 'Path("export_presets.cfg")', "release workflow should stamp export preset metadata alongside project.godot")
    assert_contains(text, '"version/code"', "release workflow should update Android versionCode for release APKs")
    assert_contains(text, '"version/name"', "release workflow should update the Android version name in export presets")
    assert_contains(text, '"application/file_version"', "release workflow should sync the Windows file version")
    assert_contains(text, '"application/product_version"', "release workflow should sync the Windows product version")
    assert_contains(text, '"application/short_version"', "release workflow should sync the macOS short version")
    assert_contains(text, '"application/version"', "release workflow should sync the macOS bundle version")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
