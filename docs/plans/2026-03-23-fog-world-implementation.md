# Fog World Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a new original-style `fog` world with levels `4-1` through `4-10`, classic fog mechanics, eight original Fog-era plants, and four original Fog-era zombies.

**Architecture:** Extend the current single-scene GDScript architecture instead of splitting the game into new scenes. Add a dedicated `fog` world key, a reusable fog-visibility layer, level data for `4-x`, and plant/zombie behavior modules inside the existing update/draw systems. Keep classic PvZ behavior first and layer plant-food supers on top.

**Tech Stack:** Godot 4 GDScript, vector-drawn units in `scripts/game.gd`, static data in `scripts/game_defs.gd`, headless Godot test scripts, world metadata in `scripts/data/world_data.gd`.

---

### Task 1: Add failing tests for Fog world routing and world-select metadata

**Files:**
- Create: `tests/fog_world_test.gd`
- Modify: `scripts/data/world_data.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that a `fog` world exists in `WorldData`.
- Assert that `4-1` through `4-10` are routed to `fog` by `_world_key_for_level()`.
- Assert that Fog unlocks after `3-18`.
- Assert that `4-5` and `4-10` remain inside the Fog world even though they use special stage formats.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`

Expected: FAIL because `fog` world data and `4-x` routing do not exist yet.

**Step 3: Write minimal implementation**
- Add Fog world metadata in `scripts/data/world_data.gd`.
- Update `_world_key_for_level()` and any hard-coded world-card assumptions in `scripts/game.gd`.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add tests/fog_world_test.gd scripts/data/world_data.gd scripts/game.gd
git commit -m "test(world): scaffold fog world routing"
```

### Task 2: Add failing tests for Fog level data and original unlock rhythm

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `scripts/game_defs.gd`

**Step 1: Write the failing test**
- Assert that `4-1` to `4-10` exist in order.
- Assert that:
  - `4-1` unlocks `plantern`
  - `4-2` unlocks `cactus`
  - `4-3` unlocks `blover`
  - `4-4` unlocks nothing
  - `4-5` unlocks `split_pea`
  - `4-6` unlocks `starfruit`
  - `4-7` unlocks `pumpkin`
  - `4-8` unlocks `magnet_shroom`
- Assert that `4-5` is `vasebreaker_night` and `4-10` is `storm_fog` + `conveyor`.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`

Expected: FAIL because the level data does not exist yet.

**Step 3: Write minimal implementation**
- Add all Fog level entries to `scripts/game_defs.gd`.
- Set node positions, available plants, unlock plants, special modes, and event rosters.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add tests/fog_world_test.gd scripts/game_defs.gd
git commit -m "feat(fog): add 4-1 to 4-10 level data"
```

### Task 3: Add failing tests for the fog mask, Plantern reveal, Blover purge, and lightning reveal

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that Fog levels mark the right-side columns as hidden.
- Assert that Plantern reveals a persistent radius.
- Assert that Blover clears all fog for a temporary global window.
- Assert that `4-10` lightning reveals the full board temporarily without permanently disabling fog.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`

Expected: FAIL because Fog visibility state does not exist.

**Step 3: Write minimal implementation**
- Add fog-state helpers and a draw/update layer in `scripts/game.gd`.
- Add Plantern reveal coverage and Blover purge logic.
- Add `storm_fog` lightning pulses.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add tests/fog_world_test.gd scripts/game.gd
git commit -m "feat(fog): add visibility and reveal systems"
```

### Task 4: Add failing tests for Fog plants and implement their base behaviors

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `tests/plant_effect_alignment_test.gd`
- Modify: `tests/special_attack_test.gd`
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that all eight Fog-era plants exist in `Defs.PLANTS`.
- Assert original-role behavior:
  - Sea-shroom is water-only and short-range
  - Plantern reveals fog
  - Cactus pops Balloon Zombies
  - Blover removes Balloon Zombies and clears fog
  - Split Pea attacks both directions
  - Starfruit fires in five fixed directions
  - Pumpkin acts as a shell support layer
  - Magnet-shroom strips metal
- Assert each plant has a plant-food super entry and effect trigger.

**Step 2: Run test to verify it fails**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/plant_effect_alignment_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_attack_test.gd`

Expected: FAIL because the new plants do not exist yet.

**Step 3: Write minimal implementation**
- Add plant definitions to `scripts/game_defs.gd`.
- Add creation, placement, attack, support, and plant-food logic in `scripts/game.gd`.
- Add bespoke draw functions for each plant.

**Step 4: Run test to verify it passes**

Run: same commands as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add tests/fog_world_test.gd tests/plant_effect_alignment_test.gd tests/special_attack_test.gd scripts/game_defs.gd scripts/game.gd
git commit -m "feat(fog): add fog-world plants and supers"
```

### Task 5: Add failing tests for Fog zombies and implement their original counterplay

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `tests/status_behavior_test.gd`
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that `balloon_zombie`, `digger_zombie`, `pogo_zombie`, and `jack_in_the_box_zombie` exist.
- Assert original-role behavior:
  - Balloon ignores plants until popped, then converts to normal walking
  - Digger tunnels to the back and can be disarmed by Magnet-shroom
  - Pogo jumps multiple plants and is stopped by Tall-nut or Magnet-shroom
  - Jack-in-the-Box explodes in a 3x3 and loses the box to Magnet-shroom

**Step 2: Run test to verify it fails**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/status_behavior_test.gd`

Expected: FAIL because the zombie kinds do not exist yet.

**Step 3: Write minimal implementation**
- Add zombie defs in `scripts/game_defs.gd`.
- Add spawn routing, movement phases, state transitions, interactions, and draw functions in `scripts/game.gd`.
- Keep the naming aligned with the rest of this repository.

**Step 4: Run test to verify it passes**

Run: same commands as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add tests/fog_world_test.gd tests/status_behavior_test.gd scripts/game_defs.gd scripts/game.gd
git commit -m "feat(fog): add fog-world zombies"
```

### Task 6: Add failing tests for `4-5` Vasebreaker and `4-10` Dark Stormy Night

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that `4-5` uses Vasebreaker-style content generation on the night backyard.
- Assert that Jack-in-the-Box immediately threatens nearby vases in that mode.
- Assert that `4-10` is conveyor-based, uses lightning reveal pulses, and does not use normal fog BGM logic.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`

Expected: FAIL because the special-stage rules are missing.

**Step 3: Write minimal implementation**
- Add a Fog-world vasebreaker ruleset.
- Add `storm_fog` timing, thunder flashes, and conveyor-card composition.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add tests/fog_world_test.gd scripts/game_defs.gd scripts/game.gd
git commit -m "feat(fog): add special stages 4-5 and 4-10"
```

### Task 7: Verify persistence, plant collection, and world navigation

**Files:**
- Modify: `tests/progress_unlock_test.gd`
- Modify: `tests/fog_world_test.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that clearing `3-18` unlocks Fog.
- Assert that replaying older levels after entering Fog includes Fog-unlocked plants where appropriate.
- Assert that `4-4` does not incorrectly mark a missing plant unlock.
- Assert that map return stays on `fog` after winning Fog levels.

**Step 2: Run test to verify it fails**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/progress_unlock_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`

Expected: FAIL because Fog is not integrated into progression yet.

**Step 3: Write minimal implementation**
- Update progression, persistent plant collection, and world return routing in `scripts/game.gd`.

**Step 4: Run test to verify it passes**

Run: same commands as Step 2.

Expected: PASS.

**Step 5: Commit**

```bash
git add tests/progress_unlock_test.gd tests/fog_world_test.gd scripts/game.gd
git commit -m "fix(progress): integrate fog world unlock flow"
```

### Task 8: Full verification

**Files:**
- Test: `tests/*.gd`

**Step 1: Run focused Fog coverage**

Run:
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/plant_effect_alignment_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_attack_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/status_behavior_test.gd`
- `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/progress_unlock_test.gd`

Expected: PASS.

**Step 2: Run the full suite**

Run:

```bash
python3 - <<'PY'
import subprocess, pathlib, sys
root = pathlib.Path('/Users/hecrereed/project/pvz/pvz-godot')
failed = []
for path in sorted((root / 'tests').glob('*.gd')):
    cmd = ['godot', '--headless', '--path', str(root), '-s', f'res://tests/{path.name}']
    proc = subprocess.run(cmd, capture_output=True, text=True)
    print(f'=== {path.name} :: exit {proc.returncode} ===')
    print((proc.stdout + proc.stderr).strip())
    if proc.returncode != 0:
        failed.append(path.name)
if failed:
    print('FAILURES:', ', '.join(failed))
    sys.exit(1)
print('ALL_TESTS_PASSED')
PY
```

Expected: `ALL_TESTS_PASSED`.

**Step 3: Final commit**

```bash
git add .
git commit -m "feat(fog): add original-style fog world"
```
