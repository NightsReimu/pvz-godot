#!/usr/bin/env python3
"""Expand Touhou boss sprites from 8 key poses to 24 animation frames.

The deterministic local expansion is intentionally alpha-preserving so white
details inside the sprite, especially Youmu's hair, clothes, and half-phantom,
are never treated as background. The optional gpt-image-2 pass can generate a
24-frame 4x6 sheet per boss; generated sheets are accepted only when every
split cell validates as a transparent sprite. Invalid generated sheets fall
back to the local expansion instead of blocking a release.
"""

from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path
import subprocess
import sys
from typing import Iterable

from PIL import Image, ImageChops, ImageStat


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = Path("/Users/hecrereed/xianyu/蜂蜜/image2画图配置")
DEFAULT_IMAGE_GEN = Path.home() / ".codex/skills/.system/imagegen/scripts/image_gen.py"
OUTPUT_ROOT = ROOT / "output/imagegen/touhou-boss-animation"
TMP_ROOT = ROOT / "tmp/imagegen/touhou-boss-animation"
CONTACT_ROOT = ROOT / "output/touhou-boss-animation-contact-sheets"

BOSSES = [
    ("rumia_boss", "rumia", "Rumia"),
    ("daiyousei_boss", "daiyousei", "Daiyousei"),
    ("cirno_boss", "cirno", "Cirno"),
    ("meiling_boss", "meiling", "Hong Meiling"),
    ("koakuma_boss", "koakuma", "Koakuma"),
    ("patchouli_boss", "patchouli", "Patchouli Knowledge"),
    ("sakuya_boss", "sakuya", "Sakuya Izayoi"),
    ("remilia_boss", "remilia", "Remilia Scarlet"),
    ("flandre_boss", "flandre", "Flandre Scarlet"),
    ("letty_boss", "letty", "Letty Whiterock"),
    ("chen_boss", "chen", "Chen"),
    ("alice_boss", "alice", "Alice Margatroid"),
    ("lily_white_boss", "lily_white", "Lily White"),
    ("prismriver_boss", "prismriver", "Prismriver Sisters"),
    ("youmu_boss", "youmu", "Youmu Konpaku"),
]

GREEN_KEY = (0, 255, 0)
MAGENTA_KEY = (255, 0, 255)
MAGENTA_KEY_BOSSES = {"daiyousei", "meiling"}
HALO_ALPHA_THRESHOLD = 13
HALO_SOLID_ALPHA_THRESHOLD = 180
HALO_BRIGHTNESS_THRESHOLD = 232
HALO_CHROMA_THRESHOLD = 22


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bosses", default="", help="Comma-separated folder names to process")
    parser.add_argument("--use-image2", action="store_true", help="Try gpt-image-2 sheets before local fallback")
    parser.add_argument("--force-image2", action="store_true", help="Regenerate existing gpt-image-2 sheets")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--image-gen", type=Path, default=DEFAULT_IMAGE_GEN)
    parser.add_argument("--quality", default="medium", choices=["low", "medium", "high", "auto"])
    parser.add_argument("--size", default="1536x2304")
    parser.add_argument("--no-contact-sheets", action="store_true")
    return parser.parse_args()


def selected_bosses(raw: str) -> list[tuple[str, str, str]]:
    if not raw:
        return BOSSES
    wanted = {item.strip() for item in raw.split(",") if item.strip()}
    return [boss for boss in BOSSES if boss[1] in wanted or boss[0] in wanted]


def load_keyframes(folder: Path) -> list[Image.Image]:
    frame_paths = sorted(folder.glob("frame_*.png"))
    if len(frame_paths) >= 24 and (folder / "frame_21.png").exists():
        source_indices = [pose * 3 for pose in range(8)]
    else:
        source_indices = list(range(8))
    frames: list[Image.Image] = []
    for index in source_indices:
        path = folder / f"frame_{index:02d}.png"
        if not path.exists():
            raise FileNotFoundError(path)
        frames.append(Image.open(path).convert("RGBA"))
    return frames


def image_bbox(image: Image.Image, threshold: int = 8) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value > threshold else 0)
    return mask.getbbox()


def transform_sprite(base: Image.Image, pose_index: int, subframe: int) -> Image.Image:
    if subframe == 0:
        return base.copy()
    bbox = image_bbox(base)
    if bbox is None:
        return base.copy()
    pad = 10
    x0, y0, x1, y1 = bbox
    crop_box = (
        max(0, x0 - pad),
        max(0, y0 - pad),
        min(base.width, x1 + pad),
        min(base.height, y1 + pad),
    )
    sprite = base.crop(crop_box)
    sign = 1 if subframe == 1 else -1
    phase = pose_index * 1.37 + subframe * 0.91
    scale = 1.0 + sign * (0.008 + (pose_index % 3) * 0.002)
    angle = sign * (0.45 + (pose_index % 4) * 0.12)
    dx = int(round(math.sin(phase) * 1.7))
    dy = int(round(math.cos(phase * 0.8) * 1.3))
    scaled_size = (
        max(1, int(round(sprite.width * scale))),
        max(1, int(round(sprite.height * scale))),
    )
    transformed = sprite.resize(scaled_size, Image.Resampling.BICUBIC)
    transformed = transformed.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)
    out = Image.new("RGBA", base.size, (255, 255, 255, 0))
    center_x = (crop_box[0] + crop_box[2]) // 2 + dx
    center_y = (crop_box[1] + crop_box[3]) // 2 + dy
    paste_pos = (center_x - transformed.width // 2, center_y - transformed.height // 2)
    out.alpha_composite(transformed, paste_pos)
    return out


def is_external_white_halo_pixel(image: Image.Image, x: int, y: int) -> bool:
    pixels = image.load()
    r, g, b, a = pixels[x, y]
    if a <= HALO_ALPHA_THRESHOLD:
        return False
    max_channel = max(r, g, b)
    min_channel = min(r, g, b)
    if max_channel < HALO_BRIGHTNESS_THRESHOLD or max_channel - min_channel > HALO_CHROMA_THRESHOLD:
        return False
    touches_transparency = False
    has_darker_solid_neighbor = False
    for oy in (-1, 0, 1):
        for ox in (-1, 0, 1):
            if ox == 0 and oy == 0:
                continue
            nx = x + ox
            ny = y + oy
            if nx < 0 or nx >= image.width or ny < 0 or ny >= image.height:
                continue
            nr, ng, nb, na = pixels[nx, ny]
            if na <= HALO_ALPHA_THRESHOLD:
                touches_transparency = True
            if na >= HALO_SOLID_ALPHA_THRESHOLD and max(nr, ng, nb) <= 220:
                has_darker_solid_neighbor = True
            if touches_transparency and has_darker_solid_neighbor:
                return True
    return False


def remove_external_white_halo(image: Image.Image) -> Image.Image:
    """Strip only near-transparent contour whites, preserving internal whites."""
    cleaned = image.copy().convert("RGBA")
    for _pass in range(2):
        pixels = cleaned.load()
        clear_positions: list[tuple[int, int]] = []
        for y in range(cleaned.height):
            for x in range(cleaned.width):
                if is_external_white_halo_pixel(cleaned, x, y):
                    clear_positions.append((x, y))
        if not clear_positions:
            break
        for x, y in clear_positions:
            r, g, b, _a = pixels[x, y]
            pixels[x, y] = (r, g, b, 0)
    return cleaned


def local_expand(keyframes: list[Image.Image]) -> list[Image.Image]:
    frames: list[Image.Image] = []
    for pose_index, keyframe in enumerate(keyframes):
        for subframe in range(3):
            frames.append(remove_external_white_halo(transform_sprite(keyframe, pose_index, subframe)))
    return frames


def key_color_for_folder(folder_name: str) -> tuple[int, int, int]:
    return MAGENTA_KEY if folder_name in MAGENTA_KEY_BOSSES else GREEN_KEY


def make_reference_sheet(folder_name: str, display_name: str, keyframes: list[Image.Image]) -> Path:
    TMP_ROOT.mkdir(parents=True, exist_ok=True)
    key = key_color_for_folder(folder_name)
    cell_w = max(frame.width for frame in keyframes) + 56
    cell_h = max(frame.height for frame in keyframes) + 56
    sheet = Image.new("RGBA", (cell_w * 4, cell_h * 2), (*key, 255))
    for index, frame in enumerate(keyframes):
        x = (index % 4) * cell_w + (cell_w - frame.width) // 2
        y = (index // 4) * cell_h + (cell_h - frame.height) // 2
        sheet.alpha_composite(frame, (x, y))
    path = TMP_ROOT / f"{folder_name}-8pose-reference.png"
    sheet.convert("RGB").save(path)
    prompt_path = TMP_ROOT / f"{folder_name}-prompt.txt"
    prompt_path.write_text(image2_prompt(display_name, key), encoding="utf-8")
    return path


def image2_prompt(display_name: str, key: tuple[int, int, int]) -> str:
    key_hex = "#%02x%02x%02x" % key
    return (
        f"Create a polished 4 columns by 6 rows sprite sheet for {display_name}, "
        "24 animation frames total, using the attached 8-pose sprite sheet as the exact character reference. "
        "Keep the same character identity, outfit, silhouette, palette, anime game sprite style, and LEFT-facing orientation. "
        "Expand each original pose into three smooth adjacent motion frames: pose, subtle in-between, subtle follow-through. "
        f"Every cell must have a perfectly flat solid {key_hex} chroma-key background in all empty space. "
        "No transparency, no shadows on the background, no grid lines, no borders, no text, no watermark, no labels. "
        "Keep one complete full-body character centered in each cell with generous padding. "
        "Do not erase internal white clothing, white hair, pale skin, instruments, wings, weapons, or phantom effects."
    )


def run_image2_sheet(
    folder_name: str,
    display_name: str,
    reference_path: Path,
    args: argparse.Namespace,
) -> Path | None:
    if not args.config.exists() or not args.image_gen.exists():
        print(f"Skipping image2 for {folder_name}: config or CLI missing", file=sys.stderr)
        return None
    out_path = OUTPUT_ROOT / f"{folder_name}-24frame-sheet.png"
    if out_path.exists() and not args.force_image2:
        return out_path
    config_lines = args.config.read_text(encoding="utf-8").splitlines()
    if len(config_lines) < 2:
        print(f"Skipping image2 for {folder_name}: config should contain base URL and key", file=sys.stderr)
        return None
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["OPENAI_BASE_URL"] = config_lines[0].strip()
    env["OPENAI_API_KEY"] = config_lines[1].strip()
    prompt = image2_prompt(display_name, key_color_for_folder(folder_name))
    command = [
        sys.executable,
        str(args.image_gen),
        "edit",
        "--model",
        "gpt-image-2",
        "--image",
        str(reference_path),
        "--prompt",
        prompt,
        "--size",
        args.size,
        "--quality",
        args.quality,
        "--output-format",
        "png",
        "--out",
        str(out_path),
        "--force",
    ]
    print(f"Calling gpt-image-2 for {folder_name}...")
    result = subprocess.run(command, cwd=ROOT, env=env, text=True)
    if result.returncode != 0:
        print(f"gpt-image-2 failed for {folder_name}; local expansion will be used", file=sys.stderr)
        return None
    return out_path if out_path.exists() else None


def remove_chroma(image: Image.Image, key: tuple[int, int, int]) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    kr, kg, kb = key
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            distance = abs(r - kr) + abs(g - kg) + abs(b - kb)
            if distance <= 54:
                pixels[x, y] = (r, g, b, 0)
            elif distance <= 130:
                alpha = int(a * (distance - 54) / 76)
                pixels[x, y] = (r, g, b, alpha)
    return rgba


def trim_with_padding(image: Image.Image, padding: int = 12) -> Image.Image | None:
    bbox = image_bbox(image)
    if bbox is None:
        return None
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(image.width, x1 + padding)
    y1 = min(image.height, y1 + padding)
    return image.crop((x0, y0, x1, y1))


def split_image2_sheet(path: Path, folder_name: str) -> list[Image.Image] | None:
    try:
        sheet = Image.open(path).convert("RGBA")
    except Exception as exc:
        print(f"Failed to load image2 sheet {path}: {exc}", file=sys.stderr)
        return None
    key = key_color_for_folder(folder_name)
    cell_w = sheet.width // 4
    cell_h = sheet.height // 6
    frames: list[Image.Image] = []
    for row in range(6):
        for col in range(4):
            cell = sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
            cleaned = remove_chroma(cell, key)
            trimmed = trim_with_padding(cleaned)
            if trimmed is None:
                return None
            if trimmed.width < 80 or trimmed.height < 80:
                return None
            frames.append(trimmed)
    return frames if len(frames) == 24 else None


def alpha_similarity(a: Image.Image, b: Image.Image) -> float:
    size = (128, 128)
    aa = a.getchannel("A").resize(size, Image.Resampling.BILINEAR)
    bb = b.getchannel("A").resize(size, Image.Resampling.BILINEAR)
    diff = ImageChops.difference(aa, bb)
    stat = ImageStat.Stat(diff)
    return 1.0 - float(stat.mean[0]) / 255.0


def generated_sheet_is_usable(generated: list[Image.Image], keyframes: list[Image.Image]) -> bool:
    if len(generated) != 24:
        return False
    for pose_index, keyframe in enumerate(keyframes):
        candidate = generated[pose_index * 3]
        if alpha_similarity(candidate, keyframe) < 0.2:
            return False
    return True


def save_frames(frames: Iterable[Image.Image], folder: Path) -> None:
    for index, frame in enumerate(frames):
        remove_external_white_halo(frame).save(folder / f"frame_{index:02d}.png")
    for stale in folder.glob("frame_*.webp"):
        stale.unlink()


def make_contact_sheet(folder_name: str, frames: list[Image.Image]) -> Path:
    CONTACT_ROOT.mkdir(parents=True, exist_ok=True)
    cell_w = max(frame.width for frame in frames) + 28
    cell_h = max(frame.height for frame in frames) + 28
    sheet = Image.new("RGBA", (cell_w * 8, cell_h * 3), (24, 26, 34, 255))
    for index, frame in enumerate(frames):
        x = (index % 8) * cell_w + (cell_w - frame.width) // 2
        y = (index // 8) * cell_h + (cell_h - frame.height) // 2
        sheet.alpha_composite(frame, (x, y))
    path = CONTACT_ROOT / f"{folder_name}-24frame-contact.png"
    sheet.save(path)
    return path


def write_metadata(records: list[dict]) -> None:
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT_ROOT / "touhou-boss-animation-sources.json"
    path.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    records: list[dict] = []
    for kind, folder_name, display_name in selected_bosses(args.bosses):
        folder = ROOT / "art" / folder_name
        keyframes = load_keyframes(folder)
        reference = make_reference_sheet(folder_name, display_name, keyframes)
        source = "local_alpha_preserving_expansion"
        frames: list[Image.Image] | None = None
        image2_sheet: Path | None = None
        if args.use_image2:
            image2_sheet = run_image2_sheet(folder_name, display_name, reference, args)
            if image2_sheet is not None:
                generated = split_image2_sheet(image2_sheet, folder_name)
                if generated_sheet_is_usable(generated or [], keyframes):
                    frames = generated
                    source = "gpt-image-2_sheet"
        if frames is None:
            frames = local_expand(keyframes)
        save_frames(frames, folder)
        contact_path = None if args.no_contact_sheets else make_contact_sheet(folder_name, frames)
        records.append(
            {
                "kind": kind,
                "folder": f"art/{folder_name}",
                "frame_count": len(frames),
                "source": source,
                "reference_sheet": str(reference.relative_to(ROOT)),
                "image2_sheet": str(image2_sheet.relative_to(ROOT)) if image2_sheet else "",
                "contact_sheet": str(contact_path.relative_to(ROOT)) if contact_path else "",
            }
        )
        print(f"{folder_name}: wrote {len(frames)} frames via {source}")
    write_metadata(records)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
