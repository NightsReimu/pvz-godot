#!/usr/bin/env python3

from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/tools/generate_touhou_boss_animation_frames.py"


def load_pipeline_module():
    spec = importlib.util.spec_from_file_location("touhou_boss_animation_pipeline", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError("failed to load Touhou boss animation pipeline")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def make_white_6x4_sheet(irregular_centers: bool = False) -> Image.Image:
    cell_w = 180
    cell_h = 190
    sheet = Image.new("RGB", (cell_w * 6, cell_h * 4), (255, 255, 255))
    draw = ImageDraw.Draw(sheet)
    for index in range(24):
        col = index % 6
        row = index // 6
        x_shift = [-28, 22, -16, 30, -24, 18][col] if irregular_centers else 0
        left = col * cell_w + 48 + x_shift
        top = row * cell_h + 32
        right = left + 84
        bottom = top + 124
        body_color = (24 + index * 6, 52, 178 - index * 3)
        draw.rounded_rectangle((left, top, right, bottom), radius=16, fill=body_color, outline=(32, 20, 62), width=5)
        draw.rectangle((left + 28, top + 34, right - 28, bottom - 34), fill=(250, 250, 250))
    return sheet


def max_nonwhite_opaque_red(frame: Image.Image) -> int:
    reds = [
        red
        for red, green, blue, alpha in frame.convert("RGBA").get_flattened_data()
        if alpha > 200 and max(red, green, blue) - min(red, green, blue) > 20
    ]
    if not reds:
        raise AssertionError("frame did not contain a colored sprite pixel")
    return max(reds)


def main() -> int:
    pipeline = load_pipeline_module()
    sheet = make_white_6x4_sheet()
    frames = pipeline.split_image2_sheet_by_grid(sheet, pipeline.GREEN_KEY)

    assert frames is not None, "6x4 white-background sheets should split successfully"
    assert len(frames) == 24, "the horizontal browser sheet should produce exactly 24 frames"
    assert max_nonwhite_opaque_red(frames[0]) < max_nonwhite_opaque_red(frames[-1]), "frames should stay in row-major 6x4 order"

    for index, frame in enumerate(frames):
        assert frame.getpixel((0, 0))[3] == 0, f"frame {index} should have transparent corners"
        assert frame.width <= 150 and frame.height <= 180, f"frame {index} should contain one trimmed sprite, not a cross-cell crop"
        opaque_pixels = sum(1 for *_rgb, alpha in frame.convert("RGBA").get_flattened_data() if alpha > 220)
        assert opaque_pixels < frame.width * frame.height * 0.72, f"frame {index} should not retain its opaque white cell background"
        internal_white = sum(
            1
            for red, green, blue, alpha in frame.convert("RGBA").get_flattened_data()
            if alpha > 220 and min(red, green, blue) >= 245
        )
        assert internal_white >= 300, f"frame {index} should preserve internal white details"
        assert internal_white <= 5000, f"frame {index} should clear exterior white without counting it as sprite detail"

    component_frames = pipeline.split_white_sheet_by_components(make_white_6x4_sheet(irregular_centers=True))
    assert component_frames is not None and len(component_frames) == 24, "white sheets should use sprite centers instead of rigid cell boundaries"
    assert all(frame.getpixel((0, 0))[3] == 0 for frame in component_frames), "component-split frames should have transparent corners"
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
