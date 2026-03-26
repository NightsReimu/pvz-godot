# Roof Boss Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the roof-world boss stage `5-17` with a unique `roof_boss`, conveyor progression, right-side reinforcements, phase skills, visuals, and regression coverage.

**Architecture:** Extend the roof data module with a final boss level and new zombie definition, then wire the boss into the shared `game.gd` boss system alongside `pool_boss` and `fog_boss`. Keep verification focused on the roof world metadata plus a dedicated boss regression test.

**Tech Stack:** Godot 4 GDScript, split `scripts/data/*` definitions, shared runtime orchestration in `scripts/game.gd`, headless Godot tests in `tests/*.gd`.

---

### Task 1: Write roof boss regression coverage

**Files:**
- Create: `tests/roof_boss_test.gd`
- Modify: `tests/roof_world_test.gd`

**Step 1: Write the failing test**

Add tests for:
- `5-17` exists and schedules exactly one `roof_boss`
- `roof_boss` cannot duplicate spawn
- summon skill uses only the roof reinforcement roster
- reinforcement timer keeps spawning from the right edge
- health bar uses five bottom segments
- roof world metadata and routing now include `5-17`

**Step 2: Run tests to verify they fail**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_boss_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_world_test.gd`

Expected: FAIL because `5-17` and `roof_boss` do not exist yet.

### Task 2: Add roof boss data

**Files:**
- Modify: `scripts/data/level_defs_roof.gd`
- Modify: `scripts/data/world_data.gd`
- Modify: `scripts/data/zombie_defs.gd`

**Step 1: Add minimal data**

Implement:
- world subtitle/description updates to `5-17`
- new `5-17` roof conveyor boss stage
- new `roof_boss` zombie definition

**Step 2: Run focused tests**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_boss_test.gd`

Expected: FAIL should move from missing data to missing behavior.

### Task 3: Implement roof boss behavior

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Add boss orchestration**

Implement:
- reinforcement pool and reinforcement timer support
- skill cycle support
- phase shift support
- stage-ending boss handling through existing boss helpers

**Step 2: Run focused tests**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_boss_test.gd`

Expected: summon and reinforcement tests should pass, leaving visuals if any.

### Task 4: Add roof boss visuals and almanac metadata

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Add drawing and metadata**

Implement:
- `_draw_roof_boss`
- `_draw_zombie` routing
- almanac ordering and boss stats text if needed

**Step 2: Run regression suite**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_boss_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/runtime_split_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/status_behavior_test.gd`

Expected: PASS, or only pre-existing unrelated warnings remain.
