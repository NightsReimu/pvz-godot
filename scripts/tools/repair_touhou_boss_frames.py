#!/usr/bin/env python3
"""Recover Touhou boss keyframes and rebuild clean 24-frame animations.

The image2 pass used by older releases baked chroma-key green into several
sprites.  This repair intentionally starts from the last checked-in pose
frames, removes only their connected white sheet background, scales them to
the current boss size, and lets the alpha-preserving local animator rebuild
the in-between frames.
"""

from __future__ import annotations

import argparse
import io
import subprocess
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
PIPELINE_PATH = ROOT / "scripts/tools/generate_touhou_boss_animation_frames.py"
RECOVERABLE_BOSSES = (
    "rumia", "daiyousei", "cirno", "meiling", "koakuma", "patchouli",
    "sakuya", "remilia", "flandre", "letty", "chen", "alice",
    "lily_white", "prismriver", "youmu",
)


def load_pipeline():
    import importlib.util

    spec = importlib.util.spec_from_file_location("touhou_pipeline", PIPELINE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"failed to load {PIPELINE_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def git_frame(commit: str, boss: str, index: int) -> Image.Image:
    path = f"art/{boss}/frame_{index:02d}.png"
    data = subprocess.check_output(["git", "show", f"{commit}:{path}"], cwd=ROOT)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def alpha_bounds(pipeline, frames: list[Image.Image]) -> tuple[int, int]:
    bounds = [pipeline.image_bbox(frame) for frame in frames]
    visible = [box for box in bounds if box is not None]
    if not visible:
        raise RuntimeError("keyframe set contains no visible pixels")
    return (
        max(box[2] - box[0] for box in visible),
        max(box[3] - box[1] for box in visible),
    )


def repair_boss(pipeline, boss: str, source_commit: str, dry_run: bool) -> tuple[int, int]:
    folder = ROOT / "art" / boss
    current = [Image.open(path).convert("RGBA") for path in sorted(folder.glob("frame_*.png"))]
    if len(current) != 24:
        raise RuntimeError(f"{folder} should contain 24 current frames")
    keyframes = []
    for index in range(0, 24, 3):
        frame = git_frame(source_commit, boss, index)
        if pipeline.has_near_white_background(frame):
            frame = pipeline.remove_exterior_white_background(frame)
        keyframes.append(frame)

    target_w, target_h = alpha_bounds(pipeline, current)
    source_w, source_h = alpha_bounds(pipeline, keyframes)
    scale = min(target_w / source_w, target_h / source_h)
    # Youmu's white half-phantom and costume are fine detail; retain the
    # slightly denser source sampling required by the existing detail check.
    if boss == "youmu":
        scale *= 1.03
    scaled = [
        frame.resize(
            (max(1, round(frame.width * scale)), max(1, round(frame.height * scale))),
            Image.Resampling.LANCZOS,
        )
        for frame in keyframes
    ]
    frames = pipeline.postprocess_frames_for_boss(boss, pipeline.local_expand(scaled))
    if not dry_run:
        pipeline.save_frames(frames, folder)
        pipeline.make_contact_sheet(boss, frames)
    return (source_w, source_h)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-commit", default="3716e44")
    parser.add_argument("--bosses", default=",".join(RECOVERABLE_BOSSES))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    pipeline = load_pipeline()
    wanted = {name.strip() for name in args.bosses.split(",") if name.strip()}
    for boss in RECOVERABLE_BOSSES:
        if boss not in wanted:
            continue
        source_w, source_h = repair_boss(pipeline, boss, args.source_commit, args.dry_run)
        action = "would rebuild" if args.dry_run else "rebuilt"
        print(f"{boss}: {action} 24 frames from {args.source_commit} ({source_w}x{source_h} source bounds)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
