#!/usr/bin/env python3
"""Generate JSONL prompts for the full gpt-image-2 game asset pass."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PLANT_DEFS = ROOT / "scripts/data/plant_defs.gd"
ZOMBIE_DEFS = ROOT / "scripts/data/zombie_defs.gd"
SOURCE_FILES = [
    ROOT / "scripts/game.gd",
    ROOT / "scripts/runtime/projectile_runtime.gd",
    ROOT / "scripts/runtime/plant_runtime.gd",
    ROOT / "scripts/runtime/plant_food_runtime.gd",
]

TOUHOU_BOSSES = {
    "rumia_boss",
    "daiyousei_boss",
    "cirno_boss",
    "meiling_boss",
    "koakuma_boss",
    "patchouli_boss",
    "sakuya_boss",
    "remilia_boss",
    "flandre_boss",
}

EXTRA_PROJECTILES = {
    "pea",
    "amber_pea",
    "amber_ultimate_shard",
    "boomerang",
    "butter",
    "cabbage",
    "kernel",
    "melon",
    "chimney_fire",
    "origami_plane",
    "heather_thorn",
    "sakura_petal",
    "angel_spear",
    "mist_bloom",
    "glow_seed",
    "moon_meteor",
    "lotus_orbit_shot",
    "lotus_converge_shot",
    "mango",
    "prism_pea",
    "prism_fragment",
    "shadow_pea",
    "star",
    "meteor_flower",
    "prism_burst",
    "thorn_spike",
}

EXTRA_EFFECTS = {
    "projectile_impact",
    "lane_spray",
    "glow_burst",
    "storm_arc",
    "push_wave",
    "anchor_ring",
    "amber_splash",
    "amber_prism_burst",
    "nut_blast",
    "mist_cloud",
    "moon_blast",
    "squash_slam",
    "rainbow_beam",
    "pulse_bulb_wave",
    "wind_gust_lane",
}

PROJECTILE_CONTEXT_WORDS = (
    "projectile",
    "projectiles",
    "spawn_roof_lobbed_projectile",
    "spawn_boomerang_projectile",
    "spawn_sakura_projectile",
    "spawn_mist_projectile",
    "spawn_glowvine_projectile",
    "spawn_moonforge_projectile",
    "spawn_shadow_pea_projectile",
    "spawn_prism_pea_projectile",
)


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _literal_list_after_marker(text: str, marker: str) -> list[str]:
    marker_index = text.index(marker)
    start = text.index("[", marker_index)
    end = text.index("]", start)
    return re.findall(r'"([^"]+)"', text[start:end])


def plant_kinds() -> list[str]:
    return _literal_list_after_marker(_read(PLANT_DEFS), "const ORDER")


def _dictionary_names(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    current = ""
    for line in text.splitlines():
        key_match = re.match(r'\s*"([^"]+)":\s*\{', line)
        if key_match:
            current = key_match.group(1)
            result.setdefault(current, current)
            continue
        if current:
            name_match = re.match(r'\s*"name":\s*"([^"]+)"', line)
            if name_match:
                result[current] = name_match.group(1)
            if re.match(r"\s*\},?\s*$", line):
                current = ""
    return result


def plant_names() -> dict[str, str]:
    return _dictionary_names(_read(PLANT_DEFS))


def zombie_names() -> dict[str, str]:
    return _dictionary_names(_read(ZOMBIE_DEFS))


def zombie_kinds() -> list[str]:
    names = zombie_names()
    return [kind for kind in names.keys() if kind not in TOUHOU_BOSSES]


def _source_text() -> str:
    return "\n".join(_read(path) for path in SOURCE_FILES)


def projectile_kinds() -> list[str]:
    found = set(EXTRA_PROJECTILES)
    for path in SOURCE_FILES:
        text = _read(path)
        for match in re.finditer(r'"kind"\s*:\s*"([^"]+)"', text):
            context = text[max(0, match.start() - 280) : match.end() + 120]
            if any(word in context for word in PROJECTILE_CONTEXT_WORDS):
                found.add(match.group(1))
        for match in re.finditer(r'projectile_kind\s*==\s*"([^"]+)"', text):
            found.add(match.group(1))
        for match in re.finditer(r'spawn_roof_lobbed_projectile\("([^"]+)"', text):
            found.add(match.group(1))
    return sorted(found)


def effect_kinds() -> list[str]:
    text = _source_text()
    found = set(EXTRA_EFFECTS)
    found.update(re.findall(r'"shape"\s*:\s*"([^"]+)"', text))
    found.update(re.findall(r"'shape'\s*:\s*'([^']+)'", text))
    found.update(re.findall(r'_add_effect\([^,\n]+,\s*"([^"]+)"', text))
    return sorted(found)


def _title_from_kind(kind: str) -> str:
    return kind.replace("_", " ")


def _subject(category: str, kind: str, display_name: str) -> str:
    title = _title_from_kind(kind)
    if category == "plants":
        return f"{display_name} plant, {title}, cute botanical tower defense unit, facing right toward the zombies"
    if category == "zombies":
        if kind.endswith("_boss"):
            return f"{display_name} boss zombie, {title}, large enemy unit, facing left toward the plants"
        return f"{display_name} zombie, {title}, readable enemy unit, facing left toward the plants"
    if category == "projectiles":
        return f"{title} projectile, single attack sprite moving to the right"
    return f"{title} combat visual effect burst, single reusable VFX sprite"


def _composition(category: str) -> str:
    if category == "projectiles":
        return "single centered projectile with generous padding, right-facing motion, no impact target"
    if category == "effects":
        return "single centered VFX element with generous padding, usable as a transparent overlay"
    if category == "zombies":
        return "single centered full-body enemy sprite with generous padding, facing left toward the plants"
    return "single centered full-body plant sprite with generous padding, facing right toward the zombies, readable at small size"


def _prompt(category: str, kind: str, display_name: str) -> str:
    return (
        "Create a polished 2D mobile game sprite for a Plants-vs-Zombies-style tower defense game. "
        f"Subject: {_subject(category, kind, display_name)}. "
        "Use a clean colorful painterly sprite style with crisp silhouette, soft highlights, and strong readability at small size. "
        "Create the subject on a perfectly flat solid #ff00ff chroma-key background for background removal. "
        "The background must be one uniform color with no shadows, gradients, texture, reflections, floor plane, or lighting variation. "
        "Do not use #ff00ff anywhere in the subject. No cast shadow, no contact shadow, no text, no watermark."
    )


def _job(category: str, kind: str, display_name: str) -> dict[str, str]:
    return {
        "asset_id": f"{category}/{kind}",
        "category": category,
        "kind": kind,
        "model": "gpt-image-2",
        "out": f"{category}-{kind}-source.png",
        "prompt": _prompt(category, kind, display_name),
        "use_case": "stylized-concept",
        "style": "clean colorful mobile game sprite, soft painterly highlights, crisp cutout silhouette",
        "composition": _composition(category),
        "constraints": "transparent-cutout friendly, no extra characters, no UI, no background details, no text, no watermark",
        "negative": "text, logo, watermark, background scene, cast shadow, contact shadow, extra characters",
        "size": "1024x1024",
        "quality": "medium",
        "output_format": "png",
    }


def build_jobs() -> list[dict[str, str]]:
    pnames = plant_names()
    znames = zombie_names()
    jobs: list[dict[str, str]] = []
    for kind in plant_kinds():
        jobs.append(_job("plants", kind, pnames.get(kind, kind)))
    for kind in zombie_kinds():
        jobs.append(_job("zombies", kind, znames.get(kind, kind)))
    for kind in projectile_kinds():
        jobs.append(_job("projectiles", kind, kind))
    for kind in effect_kinds():
        jobs.append(_job("effects", kind, kind))
    return jobs


def filter_jobs(jobs: list[dict[str, str]], category: str, kinds: str, offset: int, limit: int) -> list[dict[str, str]]:
    if category != "all":
        jobs = [job for job in jobs if job["category"] == category]
    if kinds:
        requested = {kind.strip() for kind in kinds.split(",") if kind.strip()}
        jobs = [job for job in jobs if job["kind"] in requested or job["asset_id"] in requested]
    if offset > 0:
        jobs = jobs[offset:]
    if limit >= 0:
        jobs = jobs[:limit]
    return jobs


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=ROOT / "output/imagegen/image2-full-manifest.jsonl")
    parser.add_argument("--category", choices=["all", "plants", "zombies", "projectiles", "effects"], default="all")
    parser.add_argument("--kinds", default="")
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int, default=-1)
    args = parser.parse_args()

    jobs = filter_jobs(build_jobs(), args.category, args.kinds, args.offset, args.limit)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as handle:
        for job in jobs:
            handle.write(json.dumps(job, ensure_ascii=False, separators=(",", ":")) + "\n")
    print(f"Wrote {len(jobs)} image2 asset jobs to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
