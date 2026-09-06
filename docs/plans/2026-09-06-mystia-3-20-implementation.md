# Mystia 3-20 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add pool-world level 3-20 as a six-row grassland Touhou Imperishable Night stage with Mystia Lorelei as the final boss, Cirno as the midboss, and two distinct Mystia mechanics.

**Architecture:** Reuse the existing level definition, Touhou spell, phase runtime, boss BGM, and midboss gate systems. Add Mystia-specific state transitions in `game.gd` for permanent song charm and temporary restaurant food buffs, while keeping all existing Touhou boss assets unchanged. Add a dedicated terrain style for the night sparrow restaurant and load a 24-frame Mystia animation set generated from the supplied reference image.

**Tech Stack:** Godot 4 GDScript, existing `TouhouSpellDefs`, `TouhouPhaseRuntime`, procedural CanvasItem drawing, Python/Pillow asset preparation, Godot headless tests.

---

### Task 1: Add the 3-20 level contract and audio assets

**Files:**
- Modify: `scripts/data/level_defs_pool.gd`
- Modify: `project.godot` if audio import metadata requires it
- Create: `audio/th08_mystia_stage.mp3`
- Create: `audio/th08_mystia_boss.mp3`
- Test: `tests/mystia_level_test.gd`

**Step 1: Write the failing test**

Assert that level `3-20` exists, is a six-row non-pool boss stage, references both supplied BGM paths, has the Cirno midboss gate, and queues Mystia as the final boss only after the gate.

**Step 2: Run the test to verify it fails**

Run: `godot --headless --path . --script tests/mystia_level_test.gd`
Expected: FAIL because `3-20` and its audio paths are absent.

**Step 3: Write minimal implementation**

Copy the supplied MP3 files into `audio/` under stable project names and add a level definition after `3-19` with `terrain = "mystia_night_food_stand"`, no `water_rows`, `row_count = 6`, `mid_boss_kind = "cirno_boss"`, and a timed event list containing normal night-spawn pressure, Cirno midboss timing, and a gated `mystia_boss` finale. Ensure `boss_intro_bgm` points to the stage track and `boss_bgm` points to the finale track.

**Step 4: Run test to verify it passes**

Run: `godot --headless --path . --script tests/mystia_level_test.gd`
Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/data/level_defs_pool.gd audio/th08_mystia_stage.mp3 audio/th08_mystia_boss.mp3 tests/mystia_level_test.gd
git commit -m "feat: add pool level 3-20 mystia stage"
```

### Task 2: Add Mystia data, spells, frames, and rendering

**Files:**
- Modify: `scripts/data/zombie_defs.gd`
- Modify: `scripts/data/touhou_spell_defs.gd`
- Modify: `scripts/data/almanac_text.gd`
- Modify: `scripts/game.gd`
- Modify: `scripts/tools/normalize_boss_frames.gd`
- Modify: `scripts/tools/generate_touhou_boss_animation_frames.py`
- Create: `art/mystia/frame_00.png` through `art/mystia/frame_23.png`
- Create: `tests/mystia_boss_asset_test.gd`

**Step 1: Write the failing test**

Check that `mystia_boss` has 24 frames, a six-stage card sequence based on Imperishable Night stage 2, a boss definition, a draw dispatch, and an almanac entry.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/mystia_boss_asset_test.gd`
Expected: FAIL because the kind and frame pipeline are absent.

**Step 3: Generate and prepare assets**

Use the browser ChatGPT image tool with the supplied Mystia sheet as the reference, requesting a transparent 4x6 action sheet that preserves the pink hair, bat wings, dark-red maid outfit, hat, and silhouette. Save the generated sheet outside the repository, validate it, then split and clean it into `art/mystia/frame_00.png` through `frame_23.png` with stable anchor and transparent background. Do not edit existing Boss folders.

**Step 4: Write minimal implementation**

Add Mystia's original card names and patterns to `TouhouSpellDefs`, add the boss stats and custom parameters to `zombie_defs.gd`, register the 24-frame folder/count/cache in `game.gd`, and add the asset target to the normalization and animation scripts. Implement a sprite-based draw function that uses the same scale and anchor conventions as the existing Touhou bosses.

**Step 5: Run test to verify it passes**

Run: `godot --headless --path . --script tests/mystia_boss_asset_test.gd` and `python3 tests/touhou_boss_animation_pipeline_test.py`.
Expected: PASS, with all 24 frame files present and non-empty.

**Step 6: Commit**

```bash
git add scripts/data/zombie_defs.gd scripts/data/touhou_spell_defs.gd scripts/data/almanac_text.gd scripts/game.gd scripts/tools/normalize_boss_frames.gd scripts/tools/generate_touhou_boss_animation_frames.py art/mystia tests/mystia_boss_asset_test.gd
git commit -m "feat: add mystia touhou boss animation and spell data"
```

### Task 3: Implement song charm, restaurant cooking, and scene presentation

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/runtime/touhou_danmaku_runtime.gd` only if a new Mystia pattern needs a reusable projectile pattern
- Create: `tests/mystia_mechanics_test.gd`

**Step 1: Write the failing test**

Cover permanent charm application on a song hit, charm persistence across timer ticks, cooking a plant into a restaurant order, zombie buff application, and cleanup after the buff duration.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/mystia_mechanics_test.gd`
Expected: FAIL because Mystia state fields and handlers are absent.

**Step 3: Write minimal implementation**

Add explicit plant fields for `mystia_charmed` and restaurant order metadata. Song-hit resolution marks the plant permanently charmed and renders a clear status effect; it must not rely on the existing timed Youmu charm. Restaurant cooking selects occupied plant cells, locks/removes the plant according to the encounter rule, spawns a cooking effect, and records a timed buff payload on spawned zombies. Apply buff multipliers at runtime without changing base `zombie_defs` values, and expire them deterministically. Add Mystia battlefield skill and phase-shift handlers that use the existing spell runtime while increasing song coverage, cooking throughput, reinforcements, and visual telegraphs by phase.

Add `mystia_night_food_stand` to terrain preview and battlefield drawing: six standard grass rows, dark forest depth, warm lanterns, wooden stall, tables, stools, and decorations that never block planting. Add food, lantern, and firefly effects to the existing effect renderer.

**Step 4: Run test to verify it passes**

Run: `godot --headless --path . --script tests/mystia_mechanics_test.gd`, `godot --headless --path . --script tests/midboss_final_gate_test.gd`, and `godot --headless --path . --script tests/boss_combat_flow_test.gd`.
Expected: PASS, including no Mystia spawn while Cirno is alive and BGM transition on Mystia spawn.

**Step 5: Commit**

```bash
git add scripts/game.gd scripts/runtime/touhou_danmaku_runtime.gd tests/mystia_mechanics_test.gd
git commit -m "feat: add mystia song charm and restaurant buffs"
```

### Task 4: Release validation and publish

**Files:**
- Modify: `README.md` and `project.godot` version metadata
- Modify: `art/touhou_boss_animation_sources.json` if generated asset provenance is recorded

**Step 1: Run focused validation**

Run the Mystia tests, existing pool and Touhou tests, and a Godot parse check. Confirm no existing `art/<boss>` files changed.

**Step 2: Run the game smoke test**

Start the Godot project, open pool world 3-20, verify the six-row grass board, restaurant background, Cirno gate, Mystia BGM swap, active small-zombie waves during the finale, permanent charm state, cooking buffs, and animation frame cycling.

**Step 3: Bump version and commit**

Increment the current `1.0.98` release to `1.0.99`, then commit the release metadata and validated implementation.

**Step 4: Push and create release**

Verify Git identity is `NightsReimu <nightsreimu@gmail.com>`, push `main` to `origin`, and create GitHub release `v1.0.99` with a concise changelog for 3-20.
