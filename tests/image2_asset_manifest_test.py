#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/tools/generate_image2_asset_manifest.py"
TMP_OUT = ROOT / "output/test-image2-manifest.jsonl"

TOUHOU_BOSSES = {
    "rumia_boss",
    "daiyousei_boss",
    "cirno_boss",
    "meiling_boss",
    "koakuma_boss",
    "patchouli_boss",
    "sakuya_boss",
    "remilia_boss",
    "letty_boss",
    "chen_boss",
    "flandre_boss",
}


def run_manifest(*args: str) -> list[dict]:
    TMP_OUT.parent.mkdir(parents=True, exist_ok=True)
    if TMP_OUT.exists():
        TMP_OUT.unlink()
    subprocess.run(
        ["python3", str(SCRIPT), "--out", str(TMP_OUT), *args],
        cwd=ROOT,
        check=True,
    )
    return [json.loads(line) for line in TMP_OUT.read_text(encoding="utf-8").splitlines() if line.strip()]


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> int:
    all_jobs = run_manifest()
    ids = {job["asset_id"] for job in all_jobs}

    assert_true("plants/peashooter" in ids, "manifest should include peashooter")
    assert_true("plants/chaos_shroom" in ids, "manifest should include late-list plants from PlantDefs.ORDER")
    assert_true("zombies/normal" in ids, "manifest should include normal zombies")
    assert_true("zombies/day_boss" in ids, "manifest should include non-Touhou bosses")
    for boss in TOUHOU_BOSSES:
        assert_true(f"zombies/{boss}" not in ids, f"manifest should not generate image2 art for existing Touhou boss {boss}")
    assert_true("projectiles/pea" in ids, "manifest should include pea projectile")
    assert_true("projectiles/boomerang" in ids, "manifest should include explicit projectile kinds")
    assert_true("effects/projectile_impact" in ids, "manifest should include shared impact effect")
    assert_true("effects/lane_spray" in ids, "manifest should include explicit effect shapes")

    sample = all_jobs[0]
    assert_true(sample["model"] == "gpt-image-2", "manifest jobs should pin gpt-image-2")
    assert_true(sample["output_format"] == "png", "manifest jobs should produce PNG source images")
    assert_true(sample["out"].endswith("-source.png"), "manifest source outputs should use the -source.png suffix")
    assert_true("#ff00ff" in sample["prompt"], "manifest prompts should use a removable chroma-key background")
    assert_true("no text" in sample["constraints"].lower(), "manifest prompts should forbid in-image text")
    assert_true("facing right" in sample["prompt"].lower(), "plant prompts should explicitly require right-facing sprites")
    assert_true("facing right" in sample["composition"].lower(), "plant composition should explicitly require right-facing sprites")

    plant_jobs = run_manifest("--category", "plants", "--limit", "2", "--offset", "1")
    assert_true(len(plant_jobs) == 2, "category/limit/offset should select a small deterministic batch")
    assert_true(all(job["category"] == "plants" for job in plant_jobs), "category filter should return only plants")
    assert_true(all("facing right" in job["prompt"].lower() for job in plant_jobs), "all generated plant prompts should face right")

    zombie_jobs = run_manifest("--category", "zombies", "--limit", "2")
    assert_true(len(zombie_jobs) == 2, "zombie category filter should select a small deterministic batch")
    assert_true(all(job["category"] == "zombies" for job in zombie_jobs), "zombie category filter should return only zombies")
    assert_true(all("facing left" in job["prompt"].lower() for job in zombie_jobs), "all generated zombie prompts should face left")
    assert_true(all("facing left" in job["composition"].lower() for job in zombie_jobs), "zombie composition should explicitly require left-facing sprites")

    selected_jobs = run_manifest("--category", "projectiles", "--kinds", "pea,boomerang")
    assert_true({job["kind"] for job in selected_jobs} == {"pea", "boomerang"}, "kinds filter should select exact asset kinds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
