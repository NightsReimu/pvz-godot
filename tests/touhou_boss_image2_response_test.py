#!/usr/bin/env python3

from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_DIR = ROOT / "scripts/tools"
import sys

sys.path.insert(0, str(SCRIPT_DIR))

import generate_touhou_boss_animation_frames as generator  # noqa: E402


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def tiny_png_b64() -> str:
    image = Image.new("RGB", (2, 2), (255, 0, 255))
    out = ROOT / "output/test-touhou-image2-response.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out)
    return base64.b64encode(out.read_bytes()).decode("ascii")


def main() -> int:
    payload = {"created": 1, "data": [{"b64_json": tiny_png_b64(), "url": "https://example.invalid/image.png"}]}
    decoded = generator.extract_image2_b64_json(json.dumps(payload))
    assert_true(decoded.startswith("iVBOR"), "string JSON proxy responses should expose data[0].b64_json")

    direct = generator.extract_image2_b64_json(payload)
    assert_true(direct == decoded, "dict proxy responses should expose the same b64 image")

    wrapped = generator.extract_image2_b64_json({"output": json.dumps(payload)})
    assert_true(wrapped == decoded, "wrapped string responses should expose nested b64 image")

    metadata_path = ROOT / "art/touhou_boss_animation_sources.json"
    assert_true(metadata_path.exists(), "committed Touhou boss animation metadata should exist")
    records = json.loads(metadata_path.read_text(encoding="utf-8"))
    assert_true(len(records) == len(generator.BOSSES) + 8, "metadata must retain the earlier sets, Imperishable refresh, repaired Mokou, supplied Suika, both Aki sets and Hina")
    assert_true(
        {record.get("source") for record in records} <= {
            "gpt-image-2_sheet", "user_sheet_imagegen_background_extraction",
            "user_transparent_sheet_individual_crops"
        },
        "Touhou boss animation metadata should identify its actual sheet source",
    )
    supplied = [r for r in records if r.get("source") == "user_sheet_imagegen_background_extraction"]
    assert_true(len(supplied) == 9, "Scarlet refresh should cover all nine supplied bosses")
    for record in supplied:
        assert_true((ROOT / record["source_sheet"]).exists(), "supplied cutout sheets must be preserved")
        assert_true(len(record["runtime_source_slots"]) == 24, "runtime frames must map to individual supplied poses")
    native_alpha = [r for r in records if r.get("source") == "user_transparent_sheet_individual_crops"]
    assert_true({r['kind'] for r in native_alpha} == {
        'wriggle_boss', 'mystia_boss', 'keine_boss', 'mokou_boss',
        'letty_boss', 'chen_boss', 'alice_boss', 'lily_white_boss',
        'youmu_boss', 'yuyuko_boss', 'ran_boss', 'yukari_boss', 'prismriver_boss', 'suika_boss', 'shizuha_boss', 'minoriko_boss', 'hina_boss',
    }, "the Imperishable, Cherry, Aki and Hina transparent supplied sheets must be attributed to their actual source")
    for record in native_alpha:
        assert_true(record['source_sha256'] == record['original_sha256'], "the supplied alpha sheets must not be regenerated")
        assert_true((ROOT / record['source_sheet']).exists(), "original alpha sheet must be saved")
        assert_true(hashlib.sha256((ROOT / record['source_sheet']).read_bytes()).hexdigest() == record['original_sha256'], "the archived sheet must match its actual original hash")
        assert_true(len(record['runtime_source_slots']) == 24, "runtime contract remains 24 frames")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
