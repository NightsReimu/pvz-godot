#!/usr/bin/env python3
"""Install generated gpt-image-2 source PNGs into art/image2."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CHROMA = Path.home() / ".codex/skills/.system/imagegen/scripts/remove_chroma_key.py"
DEFAULT_PREPARE = ROOT / "scripts/tools/prepare_image2_polish_asset.py"

SIZES = {
    "plants": "128x128",
    "zombies": "192x192",
    "projectiles": "64x64",
    "effects": "192x192",
}

PADDING = {
    "plants": "32",
    "zombies": "38",
    "projectiles": "24",
    "effects": "20",
}


def _load_manifest(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _run(command: list[str], dry_run: bool) -> None:
    if dry_run:
        print(" ".join(command))
        return
    subprocess.run(command, cwd=ROOT, check=True)


def _target_path(asset_root: Path, job: dict) -> Path:
    return asset_root / str(job["category"]) / f"{job['kind']}.png"


def postprocess(
    manifest: Path,
    source_dir: Path,
    asset_root: Path,
    chroma_script: Path,
    prepare_script: Path,
    force: bool,
    dry_run: bool,
    skip_missing: bool,
) -> int:
    jobs = _load_manifest(manifest)
    tmp_dir = source_dir / "_alpha"
    installed = 0
    for job in jobs:
        category = str(job["category"])
        source = source_dir / str(job["out"])
        target = _target_path(asset_root, job)
        alpha = tmp_dir / f"{category}-{job['kind']}-alpha.png"
        if target.exists() and not force:
            print(f"Skip existing {target}")
            continue
        if not source.exists():
            message = f"Generated source missing: {source}"
            if skip_missing:
                print(f"Skip missing {source}")
                continue
            raise FileNotFoundError(message)
        target.parent.mkdir(parents=True, exist_ok=True)
        alpha.parent.mkdir(parents=True, exist_ok=True)
        chroma_command = [
            "python3",
            str(chroma_script),
            "--input",
            str(source),
            "--out",
            str(alpha),
            "--auto-key",
            "border",
            "--soft-matte",
            "--transparent-threshold",
            "12",
            "--opaque-threshold",
            "220",
            "--despill",
            "--force",
        ]
        prepare_command = [
            "python3",
            str(prepare_script),
            "--input",
            str(alpha),
            "--out",
            str(target),
            "--size",
            SIZES.get(category, "128x128"),
            "--padding",
            PADDING.get(category, "24"),
        ]
        _run(chroma_command, dry_run)
        _run(prepare_command, dry_run)
        installed += 1
    print(f"Installed {installed} image2 assets into {asset_root}")
    return installed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--source-dir", required=True, type=Path)
    parser.add_argument("--asset-root", default=ROOT / "art/image2", type=Path)
    parser.add_argument("--chroma-script", default=DEFAULT_CHROMA, type=Path)
    parser.add_argument("--prepare-script", default=DEFAULT_PREPARE, type=Path)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-missing", action="store_true")
    args = parser.parse_args()
    postprocess(
        args.manifest,
        args.source_dir,
        args.asset_root,
        args.chroma_script,
        args.prepare_script,
        args.force,
        args.dry_run,
        args.skip_missing,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
