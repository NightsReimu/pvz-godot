# Day 1-23 Flandre Branch Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add day-world level `1-23` as a conveyor Scarlet branch finale with a Patchouli midboss gate, a new `flandre_boss`, a blood-moon toy-roof battlefield, and prebaked Flandre boss art/audio assets.

**Architecture:** Reuse the existing Touhou hover-boss pipeline instead of inventing a new scene type. Level data lives in `level_defs_day.gd`, asset preprocessing goes through `scripts/tools/normalize_boss_frames.gd`, boss stats and almanac data live in the data definitions, and `scripts/game.gd` handles terrain, midboss gating, boss skill cycles, FX, and draw logic.

**Tech Stack:** Godot 4 GDScript, data-driven level definitions, offline sprite normalization script, headless Godot tests, bundled MP3 boss BGM.

---

### Task 1: Lock The 1-23 Contract

**Files:**
- Modify: `tests/remilia_branch_test.gd`
- Create: `tests/flandre_branch_test.gd`
- Create: `tests/flandre_fx_test.gd`

**Step 1: Write the failing test**

Add tests that assert:
- `1-23` exists and unlocks only after `1-22`
- `1-23` sits to the right of `1-22`
- `1-23` is a conveyor boss level with `patchouli_boss` as `mid_boss_kind`
- `1-23` conveyor includes `flower_pot`
- `1-23` exposes a mixed “pot-required roof” terrain contract
- `flandre_boss` assets, intro/boss BGM, and prebaked left-facing frames exist
- `flandre_boss` has a five-segment bottom health bar
- Flandre exposes at least 11 skill-cycle branches and dedicated effect shapes

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
godot --headless --path . -s tests/flandre_fx_test.gd
```

Expected: FAIL because `1-23` and `flandre_boss` do not exist yet.

**Step 3: Write minimal implementation**

Do not change production code yet.

**Step 4: Run test to verify it passes**

Not applicable until later tasks finish.

**Step 5: Commit**

```bash
git add tests/flandre_branch_test.gd tests/flandre_fx_test.gd tests/remilia_branch_test.gd
git commit -m "test: lock day 1-23 flandre branch contract"
```

### Task 2: Add Flandre Asset Inputs And Offline Normalization

**Files:**
- Modify: `scripts/tools/normalize_boss_frames.gd`
- Create/Update generated assets: `art/flandre/frame_00.png` through `art/flandre/frame_07.png`
- Create: `audio/flandre_intro.mp3`
- Create: `audio/flandre_boss.mp3`

**Step 1: Write the failing test**

Reuse `tests/flandre_branch_test.gd`.

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
```

Expected: FAIL on missing Flandre assets/audio.

**Step 3: Write minimal implementation**

- Add a `flandre_boss` entry to `normalize_boss_frames.gd` pointing at `/Users/hecrereed/Downloads/芙兰朵露.png`
- Run the normalizer for `flandre_boss`
- Copy `1-23道中.mp3` and `1-23终末.mp3` into project audio paths used by the level

**Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
```

Expected: asset-existence assertions pass, level/Boss config assertions still fail.

**Step 5: Commit**

```bash
git add scripts/tools/normalize_boss_frames.gd art/flandre audio/flandre_intro.mp3 audio/flandre_boss.mp3 tests/flandre_branch_test.gd
git commit -m "feat: add flandre boss assets"
```

### Task 3: Add Level Data, World Metadata, And Terrain Contract

**Files:**
- Modify: `scripts/data/level_defs_day.gd`
- Modify: `scripts/data/world_data.gd`
- Modify: `scripts/data/almanac_text.gd`

**Step 1: Write the failing test**

Reuse `tests/flandre_branch_test.gd`.

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
```

Expected: FAIL on missing `1-23` or wrong metadata.

**Step 3: Write minimal implementation**

- Add `1-23` after `1-22`
- Set unlock requirement to `1-22`
- Add node position further right on the day map
- Mark it `boss_level: true`, `mode: "conveyor"`, `mid_boss_kind: "patchouli_boss"`
- Add conveyor roster including `flower_pot`
- Add new terrain tag and mixed pot-required floor metadata
- Extend white-day world subtitle/description to `1-23`

**Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
```

Expected: level placement and unlock assertions pass; runtime/boss behavior still fails.

**Step 5: Commit**

```bash
git add scripts/data/level_defs_day.gd scripts/data/world_data.gd scripts/data/almanac_text.gd tests/flandre_branch_test.gd docs/plans/2026-04-19-day-1-23-flandre-design.md
git commit -m "feat: add day 1-23 level data"
```

### Task 4: Add Flandre Boss Data

**Files:**
- Modify: `scripts/data/zombie_defs.gd`
- Modify: `scripts/data/almanac_text.gd`

**Step 1: Write the failing test**

Reuse `tests/flandre_branch_test.gd`.

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
```

Expected: FAIL on missing `flandre_boss` definition or bad stats.

**Step 3: Write minimal implementation**

- Add `flandre_boss` stats with hover cadence, damage buckets, reward, and boss flag
- Add almanac text entry and ordering hooks if needed

**Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
```

Expected: Boss data assertions pass; runtime behavior and FX still fail.

**Step 5: Commit**

```bash
git add scripts/data/zombie_defs.gd scripts/data/almanac_text.gd tests/flandre_branch_test.gd
git commit -m "feat: add flandre boss data"
```

### Task 5: Implement Terrain, Midboss Gate, And Flandre Runtime

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/flandre_branch_test.gd`
- Test: `tests/flandre_fx_test.gd`
- Test: `tests/scarlet_fx_test.gd`

**Step 1: Write the failing test**

Reuse the new Flandre tests and existing scarlet FX regression tests.

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path . -s tests/flandre_fx_test.gd
godot --headless --path . -s tests/scarlet_fx_test.gd
```

Expected: FAIL on missing terrain helpers, skill branches, or dedicated effect shapes.

**Step 3: Write minimal implementation**

- Add blood-moon toy-roof terrain drawing and mixed pot-required cell checks
- Ensure Patchouli can be reused as a `1-23` midboss gate without regressing `1-20`
- Register `flandre_boss` in boss ordering, caches, prewarm, spawn routing, draw scale, anchor, and health bar
- Implement at least 11 Flandre skill branches plus phase shift behavior
- Add dedicated effect shapes for her lance, toy ring, split clones, rainbow burst, doll storm, and forbidden break attacks
- Keep right-side pressure spawning during both midboss and final boss windows

**Step 4: Run test to verify it passes**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
godot --headless --path . -s tests/flandre_fx_test.gd
godot --headless --path . -s tests/scarlet_fx_test.gd
```

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/game.gd tests/flandre_branch_test.gd tests/flandre_fx_test.gd tests/scarlet_fx_test.gd
git commit -m "feat: implement flandre scarlet boss finale"
```

### Task 6: Final Regression Verification

**Files:**
- Test: `tests/rumia_level_test.gd`
- Test: `tests/remilia_branch_test.gd`
- Test: `tests/boss_asset_prewarm_test.gd`
- Test: `tests/flandre_branch_test.gd`
- Test: `tests/flandre_fx_test.gd`

**Step 1: Write the failing test**

No new tests.

**Step 2: Run test to verify current state**

Run:

```bash
godot --headless --path . -s tests/flandre_branch_test.gd
godot --headless --path . -s tests/flandre_fx_test.gd
godot --headless --path . -s tests/remilia_branch_test.gd
godot --headless --path . -s tests/rumia_level_test.gd
godot --headless --path . -s tests/boss_asset_prewarm_test.gd
```

Expected: all PASS

**Step 3: Write minimal implementation**

Only fix genuine regressions if any verification command fails.

**Step 4: Run test to verify it passes**

Repeat the same commands until all return exit code `0`.

**Step 5: Commit**

```bash
git add scripts/game.gd scripts/data/level_defs_day.gd scripts/data/world_data.gd scripts/data/zombie_defs.gd scripts/data/almanac_text.gd scripts/tools/normalize_boss_frames.gd art/flandre audio/flandre_intro.mp3 audio/flandre_boss.mp3 tests/flandre_branch_test.gd tests/flandre_fx_test.gd tests/remilia_branch_test.gd docs/plans/2026-04-19-day-1-23-flandre-design.md docs/plans/2026-04-19-day-1-23-flandre-implementation.md
git commit -m "feat: add day world 1-23 flandre finale"
```
