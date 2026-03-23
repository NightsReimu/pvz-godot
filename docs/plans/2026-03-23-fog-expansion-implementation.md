# Fog Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extend the fog world from `4-10` to `4-16` with six new custom plants, five new zombies, updated world metadata, and regression-safe tests.

**Architecture:** Keep all new gameplay inside the existing single-scene GDScript architecture. Add new defs in `scripts/game_defs.gd`, extend fog world metadata and almanac copy, then wire plant/zombie state machines and vector-drawn animation into `scripts/game.gd`. Reuse the existing projectile/effect/state dictionary patterns rather than creating new scene types.

**Tech Stack:** Godot 4 GDScript, vector drawing in `scripts/game.gd`, static data in `scripts/game_defs.gd`, headless test scripts under `tests/`.

---

### Task 1: Freeze the fog expansion data model

**Files:**
- Create: `docs/plans/2026-03-23-fog-expansion-design.md`
- Create: `docs/plans/2026-03-23-fog-expansion-implementation.md`
- Modify: `scripts/data/world_data.gd`

**Step 1: Write the failing test**

- Add assertions that fog world subtitle/description now cover `4-1 ~ 4-16`.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`

Expected: FAIL because metadata still ends at `4-10`.

**Step 3: Write minimal implementation**

- Update `fog` world metadata and preview plants.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

### Task 2: Add failing tests for `4-11 ~ 4-16` structure

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/data/almanac_text.gd`

**Step 1: Write the failing test**

- Assert `4-11 ~ 4-16` exist, still route to `fog`, and unlock the six new plants in order.
- Assert six new plants and five new zombies exist in defs.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`

Expected: FAIL because new levels and defs do not exist yet.

**Step 3: Write minimal implementation**

- Extend `PLANT_ORDER`, `PLANTS`, `ZOMBIES`, `LEVELS`.
- Add almanac text entries.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

### Task 3: Add failing behavior tests before runtime work

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `tests/status_behavior_test.gd`
- Modify: `tests/plant_effect_alignment_test.gd`

**Step 1: Write the failing test**

- `mist_orchid` fires when any enemy exists ahead in lane.
- `anchor_fern` grants anti-push rooted time to nearby plants.
- `excavator_zombie` pushes a chain of plants left.
- `tornado_zombie` enters via fast relocation then slows.

**Step 2: Run test to verify it fails**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/status_behavior_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/plant_effect_alignment_test.gd`

Expected: FAIL because behavior is not implemented yet.

**Step 3: Write minimal implementation**

- Add just enough runtime code to satisfy the first batch of tests.

**Step 4: Run test to verify it passes**

Run: same commands as Step 2.

Expected: PASS.

### Task 4: Implement the six plant runtimes

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/game_defs.gd`

**Step 1: Write the failing test**

- Expand tests for each plant food mode and at least one effect/range rule.

**Step 2: Run test to verify it fails**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/plant_effect_alignment_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_attack_test.gd`

**Step 3: Write minimal implementation**

- Wire `_create_plant`, `_update_plants`, `_activate_plant_food`.
- Add new projectile/effect helpers only where needed.
- Reuse the plant action animation system for firing and support pulses.

**Step 4: Run test to verify it passes**

Run: same commands as Step 2.

Expected: PASS.

### Task 5: Implement the five zombie state machines

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/game_defs.gd`

**Step 1: Write the failing test**

- Add tests for squash jump, excavator push, tornado entry, and knight split.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/status_behavior_test.gd`

**Step 3: Write minimal implementation**

- Extend `_spawn_zombie`, `_update_zombies`, `_draw_zombie`.
- Add push-chain helpers and temporary plant motion fields.
- Extend spawn-row validation for any dual-terrain units if needed.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

### Task 6: Polish drawing, map data, and regression coverage

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/data/world_data.gd`
- Modify: `tests/progress_unlock_test.gd`

**Step 1: Write the failing test**

- Verify fog world title/description, new level unlock sequence, and replay plant pool still behave correctly.

**Step 2: Run test to verify it fails**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/progress_unlock_test.gd`

**Step 3: Write minimal implementation**

- Finish card icon/preview rendering and any lingering unlock metadata.

**Step 4: Run test to verify it passes**

Run: same commands as Step 2.

Expected: PASS.

### Task 7: Full regression and commit

**Files:**
- Modify: all changed files above

**Step 1: Run targeted suites**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/status_behavior_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/plant_effect_alignment_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/progress_unlock_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/conveyor_level_rules_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_attack_test.gd`

**Step 2: Fix regressions**

- Keep fixes limited to fog expansion fallout.

**Step 3: Commit**

```bash
git add docs/plans/2026-03-23-fog-expansion-design.md docs/plans/2026-03-23-fog-expansion-implementation.md scripts/game.gd scripts/game_defs.gd scripts/data/world_data.gd scripts/data/almanac_text.gd tests/fog_world_test.gd tests/status_behavior_test.gd tests/plant_effect_alignment_test.gd tests/progress_unlock_test.gd
git commit -m "feat(fog): extend fog world to 4-16"
git push
```
