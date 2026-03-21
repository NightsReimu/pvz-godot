# Pool Animation And UI Refresh Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade animation, combat VFX, UI polish, and pool spawning so Squash and Fume-shroom read correctly, the HUD feels smoother, and pool lanes only receive valid zombie types including three buoy variants.

**Architecture:** Keep the current single-scene vector-rendered structure. Extend data definitions in `scripts/game_defs.gd`, add richer state and directional effects in `scripts/game.gd`, and tune shared panel styling in `scripts/ui/game_theme.gd`. Use small regression tests where feasible and verify the final result by running the Godot project through MCP.

**Tech Stack:** Godot 4.6, GDScript, custom vector drawing, Godot MCP

---

### Task 1: Add Pool Spawn Regression Coverage

**Files:**
- Create: `tests/pool_spawn_logic_test.gd`
- Modify: `project.godot`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**

Create a small script-driven regression test that asserts:

- land zombie kinds never select `water_rows`
- water-capable zombie kinds only select `water_rows` in pool levels
- new buoy variants are treated as water-capable

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/pool_spawn_logic_test.gd`

Expected: FAIL because helper functions and/or classifications do not exist yet.

**Step 3: Write minimal implementation**

Add classification helpers in `scripts/game.gd` for:

- land zombie eligibility
- water zombie eligibility
- pool row candidate selection

Expose only the minimum internal helpers needed by the test.

**Step 4: Run test to verify it passes**

Run the same headless command.

Expected: PASS

**Step 5: Commit**

```bash
git add project.godot tests/pool_spawn_logic_test.gd scripts/game.gd
git commit -m "test: cover pool row spawn rules"
```

### Task 2: Implement Pool Spawn Routing And Buoy Variants

**Files:**
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**

Extend `tests/pool_spawn_logic_test.gd` to assert:

- `lifebuoy_normal`, `lifebuoy_cone`, and `lifebuoy_bucket` exist
- their health progression matches normal / cone / bucket expectations
- pool world level events include buoy progression rather than only a single `ducky_tube`

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/pool_spawn_logic_test.gd`

Expected: FAIL because the new definitions and event data do not exist yet.

**Step 3: Write minimal implementation**

- Add the three buoy zombie definitions to `scripts/game_defs.gd`
- Update pool world events to use the new variants
- Update zombie drawing, almanac ordering, and water-capable checks in `scripts/game.gd`

**Step 4: Run test to verify it passes**

Run the same headless command.

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/game_defs.gd scripts/game.gd tests/pool_spawn_logic_test.gd
git commit -m "feat: add buoy zombie variants"
```

### Task 3: Rebuild Squash Attack Timing And Animation

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**

Add a focused regression path in `tests/pool_spawn_logic_test.gd` or a new `tests/special_attack_test.gd` that asserts:

- Squash does not deal damage immediately on acquisition
- damage resolves only during slam timing
- Squash clears itself after attack resolution

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_attack_test.gd`

Expected: FAIL because current Squash resolves damage instantly.

**Step 3: Write minimal implementation**

- Add Squash attack timers and target tracking
- Update motion and draw logic for windup / launch / slam / recover
- Replace plain radial hit feedback with a stronger impact effect

**Step 4: Run test to verify it passes**

Run the same headless command.

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/game.gd tests/special_attack_test.gd
git commit -m "feat: animate squash attack timing"
```

### Task 4: Replace Fume-Shroom Radial Burst With Directional Spray

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**

Add a regression test that asserts Fume-shroom effect metadata encodes forward directional geometry instead of only a radial circle when a shot is fired.

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_attack_test.gd`

Expected: FAIL because the current effect remains radial.

**Step 3: Write minimal implementation**

- Add directional effect metadata for Fume-shroom normal fire and plant-food burst
- Update `_draw_effects()` to render directional plume geometry
- Tune `_plant_draw_motion()` and `_draw_fume_shroom()` to match the new attack direction

**Step 4: Run test to verify it passes**

Run the same headless command.

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/game.gd tests/special_attack_test.gd
git commit -m "feat: add directional fume spray effects"
```

### Task 5: Refresh HUD, Pool Background, And Interactive UI States

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/ui/game_theme.gd`

**Step 1: Write the failing test**

Create a lightweight UI regression script that verifies the shared draw helpers accept the new panel treatment inputs and that battle rendering paths still execute without runtime errors.

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/ui_render_smoke_test.gd`

Expected: FAIL after the new helper expectations are introduced but before implementation.

**Step 3: Write minimal implementation**

- Refine panel shell treatment and highlight rhythm in `scripts/ui/game_theme.gd`
- Update seed bank, cards, wave bar, and pool background drawing in `scripts/game.gd`
- Preserve readability and avoid introducing heavy animation noise

**Step 4: Run test to verify it passes**

Run the same headless command.

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/game.gd scripts/ui/game_theme.gd tests/ui_render_smoke_test.gd
git commit -m "feat: polish battle hud and pool visuals"
```

### Task 6: Full Verification Through Godot MCP

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/ui/game_theme.gd`

**Step 1: Run all headless regression scripts**

Run:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/pool_spawn_logic_test.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_attack_test.gd
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/ui_render_smoke_test.gd
```

Expected: PASS

**Step 2: Launch and run with Godot MCP**

Use Godot MCP:

- `get_project_info`
- `run_project`
- `get_debug_output`
- `stop_project`

Expected: No startup errors.

**Step 3: Manual gameplay verification checklist**

- Squash visibly winds up, jumps, slams, and clears itself
- Fume-shroom shows a forward lane plume instead of a sphere
- Pool stages no longer spawn land zombies into water rows
- Buoy normal / cone / bucket variants appear in pool waves
- HUD panels, hover states, and wave bar feel smoother and clearer

**Step 4: Commit**

```bash
git add scripts/game.gd scripts/game_defs.gd scripts/ui/game_theme.gd tests
git commit -m "feat: refresh pool combat presentation"
```
