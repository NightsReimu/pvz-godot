#!/usr/bin/env python3

from __future__ import annotations

import base64
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
    assert_true(len(records) == len(generator.BOSSES), "Touhou boss animation metadata should cover every boss")
    assert_true(
        {record.get("source") for record in records} == {"gpt-image-2_sheet"},
        "Touhou boss animation metadata should prove all frames came from gpt-image-2",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
