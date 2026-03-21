# Day 1-18 Frozen Branch Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the day-world `1-18` frozen branch with mixed per-cell terrain, a Daiyousei mid-boss, and a Cirno final boss.

**Architecture:** Extend the current `1-17` boss framework rather than adding a separate battle mode. Add a per-cell terrain helper layer for `1-18`, then plug boss-specific flow control, conveyor pool swaps, and imported sprite/BGM assets into the existing game scene.

**Tech Stack:** Godot 4 GDScript, headless Godot test scripts, Pillow for sprite sheet slicing, local MP3 assets.

---

### Task 1: Add failing tests for 1-18 campaign data and unlock rules

**Files:**
- Modify: `tests/rumia_level_test.gd`
- Modify: `scripts/game_defs.gd`

**Step 1: Write the failing test**
- Assert that `1-18` exists.
- Assert that it appears immediately after `1-17`.
- Assert that it requires both `1-17` and `3-4`.
- Assert that it is a conveyor boss level in the day world.

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/rumia_level_test.gd`

Expected: FAIL because `1-18` data does not exist yet.

**Step 3: Write minimal implementation**
- Add the level definition and unlock requirements in `scripts/game_defs.gd`.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS for the new unlock/data assertions.

### Task 2: Add failing tests for mixed terrain and Cirno ice conversion

**Files:**
- Create or modify: `tests/frozen_branch_test.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that `1-18` reports columns `0-4` as water before Cirno.
- Assert that columns `5-8` report as land.
- Trigger Cirno spawn and assert columns `0-4` become frozen support tiles that no longer require lily pads.
- Assert that plants on frozen cells receive an attack-speed slowdown multiplier.

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/frozen_branch_test.gd`

Expected: FAIL because per-cell terrain support is missing.

**Step 3: Write minimal implementation**
- Add `cell_terrain_mask` helpers and Cirno freeze conversion logic.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

### Task 3: Add failing tests for Daiyousei mid-boss progression gating

**Files:**
- Modify: `tests/frozen_branch_test.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**
- Assert that `1-18` locks wave progress when the mid-boss appears at 50%.
- Assert that Daiyousei must be defeated before progress resumes.
- Assert that right-side zombie pressure continues while the mid-boss is active.

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/frozen_branch_test.gd`

Expected: FAIL because mid-boss gating does not exist yet.

**Step 3: Write minimal implementation**
- Add a dedicated frozen-branch boss flow controller inside `scripts/game.gd`.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

### Task 4: Import and wire Cirno and Daiyousei assets

**Files:**
- Create: `art/cirno/frame_00.png` through `art/cirno/frame_07.png`
- Create: `art/daiyousei/frame_00.png` through `art/daiyousei/frame_07.png`
- Create: `audio/cirno_intro.mp3`
- Create: `audio/cirno_boss.mp3`
- Modify: `scripts/game.gd`
- Modify: `tests/frozen_branch_test.gd`

**Step 1: Write the failing test**
- Assert that all required Cirno and Daiyousei frames exist.
- Assert that both MP3 files load and loop.

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/frozen_branch_test.gd`

Expected: FAIL because assets are missing.

**Step 3: Write minimal implementation**
- Slice, trim, and mirror the sprite sheets into frame files.
- Copy the MP3 files into `audio/`.
- Add texture loading and draw helpers for both bosses.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

### Task 5: Implement boss skills, draw states, and conveyor transitions

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/data/almanac_text.gd`

**Step 1: Write the failing test**
- Assert that Daiyousei creates visual spell effects and damages plants.
- Assert that Cirno creates `Icicle Fall`, `Perfect Freeze`, and `Diamond Blizzard` style animated effects.
- Assert that the conveyor plant pool swaps after Cirno appears so sleep-lily dependency disappears.

**Step 2: Run test to verify it fails**

Run: `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/frozen_branch_test.gd`

Expected: FAIL because the new boss flow and attack patterns are missing.

**Step 3: Write minimal implementation**
- Add Daiyousei and Cirno zombie definitions, state machines, effects, and support spawn pools.
- Add frozen conveyor-card swap and status banners.

**Step 4: Run test to verify it passes**

Run: same command as Step 2.

Expected: PASS.

### Task 6: Verify the full project

**Files:**
- Test: `tests/*.gd`

**Step 1: Run targeted test files**

Run:
- `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/rumia_level_test.gd`
- `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/frozen_branch_test.gd`

Expected: PASS.

**Step 2: Run full suite**

Run:

```bash
python3 - <<'PY'
import subprocess, pathlib, sys
root = pathlib.Path('/Users/hecrereed/project/pvz/pvz-godot')
godot = '/Applications/Godot.app/Contents/MacOS/Godot'
failed = []
for path in sorted((root / 'tests').glob('*.gd')):
    cmd = [godot, '--headless', '--path', str(root), '-s', f'res://tests/{path.name}']
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
