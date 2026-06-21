# Daily Stage World Variety Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make daily stages use varied, stage-specific worlds so previews and battles are not all day-like.

**Architecture:** Daily series remain the reward/zombie/modifier container. Individual generated stages can override the series world with a `world` field, and `_enter_daily_challenge()` builds the custom level from that stage world so selection preview and runtime board rules share the same source.

**Tech Stack:** Godot 4.6 GDScript, existing headless SceneTree tests, GitHub Actions release workflow.

---

### Task 1: Add Red Test For Daily Stage World Variety

**Files:**
- Modify: `tests/special_modes_test.gd`

**Steps:**
1. Add a test that iterates `_daily_series_defs()` and `_daily_stage_defs_for_series()`.
2. Assert at least one series has multiple stage worlds.
3. Assert daily stages cover non-day worlds such as `night`, `pool`, `fog`, `roof`, `city`, or `volcano`.
4. Run `godot --headless --log-file /private/tmp/pvz-daily-variety-red.log --path . -s res://tests/special_modes_test.gd` and confirm it fails before implementation.

### Task 2: Implement Stage-Level World Selection

**Files:**
- Modify: `scripts/game.gd`

**Steps:**
1. Add `stage_worlds` arrays to daily series definitions.
2. Add a helper to resolve the world for a series/stage index.
3. Add `world` to each generated daily stage.
4. Use `stage["world"]` in `_enter_daily_challenge()` when building `current_level`.

### Task 3: Verify And Release

**Files:**
- Modify: `project.godot`

**Steps:**
1. Run focused Godot regression tests and `git diff --check`.
2. Bump `config/version` to `1.0.56`.
3. Run `python3 tests/release_workflow_test.py`.
4. Commit with `fix: vary daily stage backgrounds`.
5. Push `main` and tag `v1.0.56`.
6. Confirm the GitHub release workflow creates the expected release assets.
