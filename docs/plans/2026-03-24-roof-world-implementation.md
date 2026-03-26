# Roof World Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the original-style roof world `5-1` through `5-9` with roof board rules, roof plants, roof zombies, special stage flow, and regression coverage.

**Architecture:** Extend the split data layer with a dedicated roof level definition module, then wire roof-specific board rules and unit behavior through the existing `game.gd` orchestration plus the split runtime modules. Keep new attack logic inside `scripts/runtime/*` where possible and reserve `scripts/game.gd` for shared state, placement rules, zombie state machines, and drawing.

**Tech Stack:** Godot 4 GDScript, split data/runtime modules under `scripts/data` and `scripts/runtime`, headless Godot tests in `tests/*.gd`.

---

### Task 1: Align roof regression tests with the intended spec

**Files:**
- Modify: `tests/roof_world_test.gd`

**Step 1: Write the failing test**

Update or extend the roof test to cover the intended roof unlock rhythm, roof routing, flower pot support, roof direct-fire slope blocking, pult attacks, bungee theft, umbrella protection, garlic redirect, and gargantuar imp throw.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_world_test.gd`

Expected: FAIL because roof world data and runtime behavior are missing.

### Task 2: Add roof world data and definitions

**Files:**
- Create: `scripts/data/level_defs_roof.gd`
- Modify: `scripts/data/level_defs.gd`
- Modify: `scripts/data/world_data.gd`
- Modify: `scripts/data/plant_defs.gd`
- Modify: `scripts/data/zombie_defs.gd`

**Step 1: Write the minimal data implementation**

Add:
- world metadata for `roof`
- level definitions for `5-1` through `5-9`
- roof plants: `cabbage_pult`, `flower_pot`, `kernel_pult`, `coffee_bean`, `garlic`, `umbrella_leaf`, `marigold`, `melon_pult`
- roof zombies: `bungee_zombie`, `ladder_zombie`, `catapult_zombie`, `gargantuar`, `imp`

**Step 2: Run roof test again**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_world_test.gd`

Expected: still FAIL, but missing-data failures should be reduced to runtime behavior failures.

### Task 3: Implement roof placement and board rules

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Add minimal roof board logic**

Implement:
- `roof` world routing and map title
- roof unlock after `4-18`
- roof terrain helper
- flower pot support requirements
- coffee bean activation on sleeping mushrooms
- roof straight-shot visibility cutoff for low roof columns

**Step 2: Run roof test again**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_world_test.gd`

Expected: remaining failures should mainly be projectile and zombie behavior.

### Task 4: Implement roof plant runtime

**Files:**
- Modify: `scripts/runtime/plant_runtime.gd`
- Modify: `scripts/runtime/projectile_runtime.gd`
- Modify: `scripts/runtime/plant_food_runtime.gd`

**Step 1: Add minimal runtime**

Implement:
- cabbage, kernel, butter, melon lobbed shots
- melon splash
- garlic passive redirect support
- umbrella leaf protection helper usage
- marigold coin/sun behavior
- plant food support for new roof plants

**Step 2: Run roof test again**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_world_test.gd`

Expected: remaining failures should mainly be roof zombie state machines and drawing-related issues.

### Task 5: Implement roof zombie behavior and visuals

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Add minimal zombie state support**

Implement:
- bungee targeting and theft
- ladder placement and laddered barrier bypass
- catapult lobbing and umbrella interception
- gargantuar smash and imp throw
- imp spawn behavior
- roof board background, grid styling, and roof cleaner presentation

**Step 2: Run focused and regression tests**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/roof_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/runtime_split_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/plant_effect_alignment_test.gd`

Expected: PASS, or only unrelated pre-existing failures remain.
