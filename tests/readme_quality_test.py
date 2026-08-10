#!/usr/bin/env python3

from __future__ import annotations

import re
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"
CODE_LICENSE = ROOT / "LICENSE"
ASSETS_LICENSE = ROOT / "ASSETS_LICENSE.md"
ACCENT = ROOT / "docs/readme/readme-accent.svg"


def check(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def read_or_empty(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def main() -> int:
    failures: list[str] = []
    required_files = (README, CODE_LICENSE, ASSETS_LICENSE, ACCENT)
    for path in required_files:
        check(path.exists(), f"missing required file: {path.relative_to(ROOT)}", failures)

    release_notes = sorted(ROOT.glob("RELEASE_NOTES_v*.md"))
    check(not release_notes, "root release-note files should be replaced by GitHub Releases", failures)

    readme = read_or_empty(README)
    code_license = read_or_empty(CODE_LICENSE)
    assets_license = read_or_empty(ASSETS_LICENSE)

    required_readme_text = {
        "中文项目简介": "## 项目简介",
        "English summary": "## English Summary",
        "feature overview": "## 游戏内容",
        "Touhou content": "## 东方 Boss 支线",
        "controls": "## 操作方式",
        "installation": "## 下载与运行",
        "development": "## 本地开发",
        "architecture": "## 项目结构",
        "tests": "## 测试",
        "contributing": "## 参与贡献",
        "roadmap": "## 路线图",
        "license": "## 许可与素材声明",
    }
    for description, marker in required_readme_text.items():
        check(marker in readme, f"README is missing {description}: {marker}", failures)

    expected_links = (
        "https://github.com/NightsReimu/pvz-godot/releases/latest",
        "https://github.com/NightsReimu/pvz-godot/releases",
        "https://nightsreimu.github.io/pvz-godot/",
    )
    for link in expected_links:
        check(link in readme, f"README is missing canonical project link: {link}", failures)

    local_images = re.findall(r"!\[[^\]]*\]\(([^)]+)\)", readme)
    check(bool(local_images), "README should include at least one local visual", failures)
    for raw_target in local_images:
        target = raw_target.strip().split(" ", 1)[0].strip("<>")
        if target.startswith(("http://", "https://", "data:")):
            continue
        asset_path = ROOT / unquote(target).split("#", 1)[0]
        check(asset_path.is_file(), f"README image does not exist: {target}", failures)

    identity_scope = "\n".join((readme, code_license, assets_license))
    old_repo_pattern = re.compile(r"(?:github\.com/HecreReed|hecrereed\.github\.io)", re.IGNORECASE)
    check(not old_repo_pattern.search(identity_scope), "documentation must not link to the old repository owner", failures)

    check("MIT License" in code_license, "LICENSE should contain the MIT License", failures)
    check("source code only" in code_license.lower(), "LICENSE should limit MIT coverage to original source code", failures)
    check("media assets are excluded" in code_license.lower(), "LICENSE should exclude bundled media assets", failures)

    asset_markers = (
        "not covered by the MIT License",
        "Touhou Project",
        "derivative-work guidelines",
        "original Touhou music",
        "no verified redistribution license",
        "replace the music",
    )
    for marker in asset_markers:
        check(marker.lower() in assets_license.lower(), f"ASSETS_LICENSE.md is missing licensing boundary: {marker}", failures)

    readme_license_markers = (
        "源码采用 MIT License",
        "媒体素材不属于 MIT 授权范围",
        "东方原曲",
        "取得授权或替换",
    )
    for marker in readme_license_markers:
        check(marker in readme, f"README is missing prominent media license warning: {marker}", failures)

    if failures:
        print("README quality checks failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("README quality checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
