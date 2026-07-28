# Click Ultimate Strength Restoration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restore strong plant-food behavior for ordinary charged click ultimates while preserving dedicated click skills.

**Architecture:** Reintroduce the original `PlantFoodRuntime.supported_kinds()` routing guard in `_ultimate_profile_for_kind()` after dedicated click profiles and before generic/explicit fallbacks. Update behavior tests to lock both sides of that priority rule.

**Tech Stack:** Godot 4, GDScript, headless SceneTree tests.

---

### Task 1: Add the regression tests

**Files:**
- Modify: `tests/click_ultimate_behavior_test.gd`

**Step 1: Write the failing test**

Change the peashooter assertion to require `plant_food_ultimate` routing and the
runtime `pea_storm` state. Keep the amber shooter assertion to prove dedicated
profiles still take priority.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s res://tests/click_ultimate_behavior_test.gd`

Expected: FAIL because peashooter currently returns an explicit profile and
spawns an immediate custom volley.

### Task 2: Restore the old profile priority

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Write minimal implementation**

Add the `PlantFoodRuntime.supported_kinds().has(kind)` return immediately after
the dedicated click-profile checks and before the later explicit/generic cases.

**Step 2: Run focused tests**

Run:

```bash
godot --headless --path . -s res://tests/click_ultimate_behavior_test.gd
godot --headless --path . -s res://tests/runtime_split_test.gd
godot --headless --path . -s res://tests/gacha_plant_food_test.gd
```

Expected: PASS.

### Task 3: Run regression verification

**Files:**
- Verify: `scripts/game.gd`
- Verify: `tests/click_ultimate_behavior_test.gd`

**Step 1: Run combat and boot tests**

Run:

```bash
godot --headless --path . -s res://tests/special_attack_test.gd
godot --headless --path . -s res://tests/plant_balance_test.gd
godot --headless --path . -s res://tests/game_boot_test.gd
git diff --check
```

Expected: PASS with no formatting errors.
