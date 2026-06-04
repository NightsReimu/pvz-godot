#!/usr/bin/env python3
"""Trim and resize a transparent image2 sprite for the Godot polish assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def _parse_size(value: str) -> tuple[int, int]:
    try:
        width_raw, height_raw = value.lower().split("x", 1)
        width = int(width_raw)
        height = int(height_raw)
    except Exception as exc:
        raise argparse.ArgumentTypeError("size must be WIDTHxHEIGHT, for example 128x128") from exc
    if width <= 0 or height <= 0:
        raise argparse.ArgumentTypeError("size dimensions must be positive")
    return width, height


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    return bbox


def prepare_asset(source: Path, out: Path, size: tuple[int, int], padding: int) -> None:
    image = Image.open(source).convert("RGBA")
    left, top, right, bottom = _alpha_bbox(image)
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(image.width, right + padding)
    bottom = min(image.height, bottom + padding)
    cropped = image.crop((left, top, right, bottom))

    target_w, target_h = size
    scale = min(target_w / cropped.width, target_h / cropped.height)
    resized_size = (
        max(1, int(round(cropped.width * scale))),
        max(1, int(round(cropped.height * scale))),
    )
    resized = cropped.resize(resized_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    offset = ((target_w - resized.width) // 2, (target_h - resized.height) // 2)
    canvas.alpha_composite(resized, offset)
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out)
    print(f"Wrote {out}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--size", required=True, type=_parse_size)
    parser.add_argument("--padding", default=24, type=int)
    args = parser.parse_args()
    prepare_asset(args.input, args.out, args.size, args.padding)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
