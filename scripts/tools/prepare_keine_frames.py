"""Separate the supplied textured sprites from their smooth lavender backdrop."""

import argparse
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import binary_fill_holes


def extract(tile, index):
    rgb = np.array(tile.convert("RGB"))
    # The backdrop is smooth; sprite outlines, fabric and spell strokes are not.
    edges = np.maximum.reduce([
        cv2.Canny(rgb[:, :, channel], 20, 48) for channel in range(3)
    ])
    edges = cv2.morphologyEx(edges, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    mask = binary_fill_holes(edges > 0).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask, 8)
    keep = np.zeros_like(mask)
    for label in range(1, count):
        if stats[label, cv2.CC_STAT_AREA] >= 14:
            keep[labels == label] = 1
    # One subpixel fringe preserves antialiasing without keeping the ambient haze.
    inner = cv2.erode(keep, np.ones((2, 2), np.uint8))
    alpha = cv2.GaussianBlur(keep.astype(np.float32), (3, 3), 0.45)
    alpha[inner > 0] = 1.0
    red, green, blue = rgb.astype(np.float32).transpose(2, 0, 1)
    lavender = ((red > green * 1.18) & (blue > green * 1.18)
                & (red > blue * 0.85) & (red < blue * 1.35))
    detail = np.max(np.abs(rgb.astype(np.float32)
                           - cv2.GaussianBlur(rgb.astype(np.float32), (5, 5), 1.0)), axis=2)
    spell_alpha = np.clip(np.maximum((detail - 2.0) / 14.0,
                                     (np.minimum(red, blue) - 165.0) / 70.0), 0, 1)
    alpha[lavender] *= spell_alpha[lavender]
    # Remove fragments belonging to neighbouring cells in the generated sheet.
    if index in (8, 20):
        alpha[:, :8] = 0
    if index == 13:
        alpha[246:, :] = 0
    if index == 21:
        fade = np.clip((np.arange(alpha.shape[1]) - 85) / 75, 0, 1)
        alpha *= 0.58 + 0.42 * (fade * fade * (3 - 2 * fade))
    alpha[alpha < 0.08] = 0.0
    return Image.fromarray(np.dstack([rgb, np.uint8(alpha * 255)]))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, default=Path("art/keine"))
    parser.add_argument("--preview", type=Path, default=Path("tmp/keine-contact.png"))
    args = parser.parse_args()
    sheet = Image.open(args.source)
    args.output.mkdir(parents=True, exist_ok=True)
    args.preview.parent.mkdir(parents=True, exist_ok=True)
    contact = Image.new("RGB", (1536, 1120), "#14231f")
    draw = ImageDraw.Draw(contact)
    for index in range(24):
        x, y = index % 6, index // 6
        tile = sheet.crop((x * sheet.width // 6, y * sheet.height // 4,
                           (x + 1) * sheet.width // 6, (y + 1) * sheet.height // 4))
        frame = extract(tile, index)
        # All cells share one fixed canvas and baseline; no per-pose resizing.
        canvas = Image.new("RGBA", (272, 272))
        canvas.alpha_composite(frame, ((272 - frame.width) // 2, (272 - frame.height) // 2))
        canvas.save(args.output / f"frame_{index:02d}.png", optimize=True)
        preview = canvas.resize((256, 256), Image.Resampling.LANCZOS)
        contact.paste(preview, (x * 256, y * 280), preview)
        draw.text((x * 256 + 12, y * 280 + 258), f"{index:02d}", fill="#ffffff")
    contact.save(args.preview)
    print(f"Prepared 24 frames from {sheet.size}; contact sheet: {args.preview}")


if __name__ == "__main__":
    main()
