#!/usr/bin/env python3
"""Audit generated gpt-image-2 assets before a release."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "scripts/tools"
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"

if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from generate_image2_asset_manifest import build_jobs, filter_jobs  # noqa: E402


def _load_jobs(path: Path | None) -> list[dict[str, str]]:
    if path is None:
        return build_jobs()
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _asset_path(asset_root: Path, job: dict[str, str]) -> Path:
    return asset_root / str(job["category"]) / f"{job['kind']}.png"


def _png_problem(path: Path) -> str:
    if not path.exists():
        return "missing"
    if path.stat().st_size <= len(PNG_SIGNATURE):
        return "empty"
    with path.open("rb") as handle:
        signature = handle.read(len(PNG_SIGNATURE))
    if signature != PNG_SIGNATURE:
        return "not-png"
    return ""


def audit_assets(
    jobs: list[dict[str, str]],
    asset_root: Path,
) -> tuple[list[dict[str, str]], dict[str, int]]:
    bad_jobs: list[dict[str, str]] = []
    counts: dict[str, int] = {}
    for job in jobs:
        category = str(job["category"])
        counts[category] = counts.get(category, 0) + 1
        problem = _png_problem(_asset_path(asset_root, job))
        if problem:
            bad_job = dict(job)
            bad_job["problem"] = problem
            bad_jobs.append(bad_job)
    return bad_jobs, counts


def _write_manifest(path: Path, jobs: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for job in jobs:
            clean_job = {key: value for key, value in job.items() if key != "problem"}
            handle.write(json.dumps(clean_job, ensure_ascii=False, separators=(",", ":")) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--asset-root", default=ROOT / "art/image2", type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--category", choices=["all", "plants", "zombies", "projectiles", "effects"], default="all")
    parser.add_argument("--kinds", default="")
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--limit", type=int, default=-1)
    parser.add_argument("--write-missing-manifest", type=Path)
    parser.add_argument("--list-limit", type=int, default=50)
    args = parser.parse_args()

    jobs = filter_jobs(_load_jobs(args.manifest), args.category, args.kinds, args.offset, args.limit)
    bad_jobs, counts = audit_assets(jobs, args.asset_root)
    print(f"Audited {len(jobs)} image2 assets in {args.asset_root}")
    print("Category counts: " + ", ".join(f"{key}={counts[key]}" for key in sorted(counts)))
    if not bad_jobs:
        print("All image2 assets are present PNG files.")
        if args.write_missing_manifest:
            _write_manifest(args.write_missing_manifest, [])
        return 0

    problem_counts: dict[str, int] = {}
    for job in bad_jobs:
        problem = str(job["problem"])
        problem_counts[problem] = problem_counts.get(problem, 0) + 1
    print("Problems: " + ", ".join(f"{key}={problem_counts[key]}" for key in sorted(problem_counts)))
    for job in bad_jobs[: max(args.list_limit, 0)]:
        print(f"{job['problem']}: {job['category']}/{job['kind']}")
    if len(bad_jobs) > args.list_limit:
        print(f"... and {len(bad_jobs) - args.list_limit} more")
    if args.write_missing_manifest:
        _write_manifest(args.write_missing_manifest, bad_jobs)
        print(f"Wrote missing manifest to {args.write_missing_manifest}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
