#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/tools/postprocess_image2_asset_batch.py"
WORK = ROOT / "output/test-image2-postprocess"


def assert_contains(text: str, needle: str, message: str) -> None:
    if needle not in text:
        raise AssertionError(message)


def main() -> int:
    source_dir = WORK / "sources"
    asset_root = WORK / "art-image2"
    manifest = WORK / "manifest.jsonl"
    source_dir.mkdir(parents=True, exist_ok=True)
    manifest.parent.mkdir(parents=True, exist_ok=True)
    (source_dir / "plants-peashooter-source.png").write_bytes(b"not-used-in-dry-run")
    manifest.write_text(
        json.dumps(
            {
                "asset_id": "plants/peashooter",
                "category": "plants",
                "kind": "peashooter",
                "out": "plants-peashooter-source.png",
            },
            separators=(",", ":"),
        )
        + "\n",
        encoding="utf-8",
    )
    result = subprocess.run(
        [
            "python3",
            str(SCRIPT),
            "--manifest",
            str(manifest),
            "--source-dir",
            str(source_dir),
            "--asset-root",
            str(asset_root),
            "--dry-run",
        ],
        cwd=ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    assert_contains(result.stdout, "remove_chroma_key.py", "postprocess should chroma-key remove generated source images")
    assert_contains(result.stdout, "prepare_image2_polish_asset.py", "postprocess should trim/resize alpha assets")
    assert_contains(result.stdout, str(asset_root / "plants/peashooter.png"), "postprocess should install to category/kind PNG path")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
