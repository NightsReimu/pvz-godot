#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


DEFAULT_TARGETS = (
    "art/cirno",
    "art/daiyousei",
    "art/rumia",
    "art/meiling",
    "art/koakuma",
    "art/patchouli",
    "art/sakuya",
    "art/remilia",
)

ALPHA_EMPTY_THRESHOLD = 8
NEIGHBOR_COLOR_ALPHA_THRESHOLD = 140
OPAQUE_NEIGHBOR_ALPHA_THRESHOLD = 180
HALO_BRIGHTNESS_THRESHOLD = 232
HALO_CHROMA_THRESHOLD = 22
COLOR_SAMPLE_BRIGHTNESS_THRESHOLD = 220
COLOR_SAMPLE_CHROMA_THRESHOLD = 18


def is_halo_candidate(pixel: tuple[int, int, int, int]) -> bool:
    r, g, b, a = pixel
    if a <= ALPHA_EMPTY_THRESHOLD:
        return False
    max_channel = max(r, g, b)
    min_channel = min(r, g, b)
    return (
        max_channel >= HALO_BRIGHTNESS_THRESHOLD
        and max_channel - min_channel <= HALO_CHROMA_THRESHOLD
    )


def is_strict_halo_pixel(
    pixels,
    width: int,
    height: int,
    x: int,
    y: int,
) -> bool:
    if not is_halo_candidate(pixels[x, y]):
        return False
    touches_transparency = False
    has_dark_neighbor = False
    for next_y in range(max(0, y - 1), min(height, y + 2)):
        for next_x in range(max(0, x - 1), min(width, x + 2)):
            if next_x == x and next_y == y:
                continue
            nr, ng, nb, na = pixels[next_x, next_y]
            if na <= ALPHA_EMPTY_THRESHOLD:
                touches_transparency = True
            if (
                na >= OPAQUE_NEIGHBOR_ALPHA_THRESHOLD
                and max(nr, ng, nb) <= COLOR_SAMPLE_BRIGHTNESS_THRESHOLD
            ):
                has_dark_neighbor = True
        if touches_transparency and has_dark_neighbor:
            return True
    return False


def collect_replacement_color(
    pixels,
    width: int,
    height: int,
    x: int,
    y: int,
) -> tuple[int, int, int] | None:
    has_transparent_neighbor = False
    samples: list[tuple[int, int, int, float]] = []
    for next_y in range(max(0, y - 1), min(height, y + 2)):
        for next_x in range(max(0, x - 1), min(width, x + 2)):
            if next_x == x and next_y == y:
                continue
            nr, ng, nb, na = pixels[next_x, next_y]
            if na <= ALPHA_EMPTY_THRESHOLD:
                has_transparent_neighbor = True
                continue
            neighbor_brightness = max(nr, ng, nb)
            neighbor_chroma = neighbor_brightness - min(nr, ng, nb)
            if na < NEIGHBOR_COLOR_ALPHA_THRESHOLD:
                continue
            if (
                neighbor_brightness <= COLOR_SAMPLE_BRIGHTNESS_THRESHOLD
                or neighbor_chroma >= COLOR_SAMPLE_CHROMA_THRESHOLD
            ):
                weight = 1.0 + na / 255.0
                samples.append((nr, ng, nb, weight))
    if not has_transparent_neighbor or len(samples) < 2:
        return None
    sum_r = 0.0
    sum_g = 0.0
    sum_b = 0.0
    sum_weight = 0.0
    for nr, ng, nb, weight in samples:
        sum_r += nr * weight
        sum_g += ng * weight
        sum_b += nb * weight
        sum_weight += weight
    if sum_weight <= 0.0:
        return None
    return (
        round(sum_r / sum_weight),
        round(sum_g / sum_weight),
        round(sum_b / sum_weight),
    )


def cleanup_once(image: Image.Image) -> tuple[Image.Image, int]:
    width, height = image.size
    source = image.load()
    output = image.copy()
    destination = output.load()
    changed = 0
    for y in range(height):
        for x in range(width):
            pixel = source[x, y]
            if not is_halo_candidate(pixel):
                continue
            replacement = collect_replacement_color(source, width, height, x, y)
            if replacement is not None:
                current_max = max(pixel[0], pixel[1], pixel[2])
                current_min = min(pixel[0], pixel[1], pixel[2])
                replacement_max = max(replacement)
                replacement_min = min(replacement)
                if replacement_max < current_max or replacement_min < current_min:
                    destination[x, y] = (*replacement, pixel[3])
                    changed += 1
                    continue
            if is_strict_halo_pixel(source, width, height, x, y):
                destination[x, y] = (pixel[0], pixel[1], pixel[2], 0)
                changed += 1
    return output, changed


def cleanup_image(image: Image.Image, passes: int) -> tuple[Image.Image, int]:
    current = image.convert("RGBA")
    changed_total = 0
    for _ in range(max(1, passes)):
        current, changed = cleanup_once(current)
        changed_total += changed
        if changed == 0:
            break
    return current, changed_total


def count_halo_pixels(image: Image.Image) -> int:
    width, height = image.size
    pixels = image.load()
    halo_pixels = 0
    for y in range(height):
        for x in range(width):
            if is_strict_halo_pixel(pixels, width, height, x, y):
                halo_pixels += 1
    return halo_pixels


def frame_paths(target: Path) -> list[Path]:
    return sorted(path for path in target.glob("frame_*.png") if path.is_file())


def process_target(target: Path, passes: int, dry_run: bool) -> tuple[int, int, int]:
    total_before = 0
    total_after = 0
    total_changed = 0
    for frame_path in frame_paths(target):
        image = Image.open(frame_path).convert("RGBA")
        before = count_halo_pixels(image)
        cleaned, changed = cleanup_image(image, passes)
        after = count_halo_pixels(cleaned)
        total_before += before
        total_after += after
        total_changed += changed
        if not dry_run and changed > 0:
            cleaned.save(frame_path)
    return total_before, total_after, total_changed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Offline cleanup for boss sprite white contour halos.")
    parser.add_argument(
        "targets",
        nargs="*",
        default=DEFAULT_TARGETS,
        help="Boss frame folders to process.",
    )
    parser.add_argument(
        "--passes",
        type=int,
        default=2,
        help="How many cleanup passes to run per image.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print stats without rewriting files.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    exit_code = 0
    for target_arg in args.targets:
        target = Path(target_arg)
        if not target.exists():
            print(f"[skip] {target} does not exist")
            continue
        before, after, changed = process_target(target, args.passes, args.dry_run)
        print(
            f"{target}: before={before} after={after} changed={changed}"
            + (" dry-run" if args.dry_run else "")
        )
        if after > before:
            exit_code = 1
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
