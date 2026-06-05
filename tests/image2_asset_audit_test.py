#!/usr/bin/env python3

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/tools/audit_image2_assets.py"
WORK = ROOT / "output/test-image2-audit"
PNG_BYTES = b"\x89PNG\r\n\x1a\nnot-a-real-png-but-enough-for-audit"


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def _write_manifest(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    jobs = [
        {
            "asset_id": "plants/peashooter",
            "category": "plants",
            "kind": "peashooter",
            "out": "plants-peashooter-source.png",
            "prompt": "test",
        },
        {
            "asset_id": "zombies/normal",
            "category": "zombies",
            "kind": "normal",
            "out": "zombies-normal-source.png",
            "prompt": "test",
        },
    ]
    path.write_text(
        "".join(json.dumps(job, separators=(",", ":")) + "\n" for job in jobs),
        encoding="utf-8",
    )


def main() -> int:
    shutil.rmtree(WORK, ignore_errors=True)
    asset_root = WORK / "art-image2"
    manifest = WORK / "manifest.jsonl"
    missing_manifest = WORK / "missing.jsonl"
    _write_manifest(manifest)
    (asset_root / "plants").mkdir(parents=True, exist_ok=True)
    (asset_root / "plants/peashooter.png").write_bytes(PNG_BYTES)

    missing = subprocess.run(
        [
            "python3",
            str(SCRIPT),
            "--manifest",
            str(manifest),
            "--asset-root",
            str(asset_root),
            "--write-missing-manifest",
            str(missing_manifest),
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert_true(missing.returncode == 1, "audit should fail when expected assets are missing")
    assert_true("missing: zombies/normal" in missing.stdout, "audit should list missing category/kind assets")
    missing_jobs = [json.loads(line) for line in missing_manifest.read_text(encoding="utf-8").splitlines() if line.strip()]
    assert_true(len(missing_jobs) == 1 and missing_jobs[0]["asset_id"] == "zombies/normal", "missing manifest should contain only absent assets")

    (asset_root / "zombies").mkdir(parents=True, exist_ok=True)
    (asset_root / "zombies/normal.png").write_bytes(PNG_BYTES)
    complete = subprocess.run(
        [
            "python3",
            str(SCRIPT),
            "--manifest",
            str(manifest),
            "--asset-root",
            str(asset_root),
            "--write-missing-manifest",
            str(missing_manifest),
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert_true(complete.returncode == 0, "audit should pass once every expected asset exists")
    assert_true("All image2 assets are present PNG files." in complete.stdout, "audit should confirm complete assets")
    assert_true(missing_manifest.read_text(encoding="utf-8") == "", "complete audit should write an empty missing manifest")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
