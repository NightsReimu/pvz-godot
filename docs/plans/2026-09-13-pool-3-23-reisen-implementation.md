# 泳池世界 3-23 铃仙与因幡帝 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the six-row 3-23 Imperishable Night Stage 5 level with a distinct Tewi road encounter, Reisen finale, supplied audio and 24-frame art, original difficulty scaling, and Plants vs. Zombies-compatible corridor mechanics.

**Architecture:** Reuse the existing level definition, Touhou phase, boss runtime, frozen road-gate, danmaku, and terrain-rendering systems. Add a small Reisen-specific runtime for madness-eye, eclipse, portals, and corridor return state; keep combat coordinates stable while rendering only the background rotation. Keep all temporary state owner-scoped and clear it through existing phase, death, retry, and pause paths.

**Tech Stack:** Godot 4.6 GDScript, headless SceneTree tests, existing PNG frame loader, AudioStream resources, procedural CanvasItem drawing, Git.

---

### Task 1: Add failing 3-23 contract tests

**Files:**
- Create: `tests/reisen_level_test.gd`
- Create: `tests/reisen_battle_flow_test.gd`

**Step 1: Write the failing test**

Cover the 3-23 ID, six grass rows, no water rows, required healing gourd, supplied BGM paths, Tewi road kind, Reisen finale event, four difficulty options, and a four-difficulty phase growth contract. Add battle-flow assertions for road minions, frozen waves, road defeat, finale BGM switch, and no premature finale spawn.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/reisen_level_test.gd`
Expected: FAIL because 3-23 and Reisen/Tewi are not registered.

**Step 3: Commit**

```bash
git add tests/reisen_level_test.gd tests/reisen_battle_flow_test.gd
git commit -m "test: define 3-23 reisen stage contracts"
```

### Task 2: Register Reisen and Tewi data

**Files:**
- Modify: `scripts/data/zombie_defs.gd`
- Modify: `scripts/data/touhou_spell_defs.gd`
- Modify: `scripts/data/level_defs_pool.gd`

**Step 1: Add the failing data assertions**

Extend the tests with required `tewi_boss` and `reisen_boss` definitions, canonical spell IDs, and the stage event order.

**Step 2: Run tests to verify they fail**

Run: `godot --headless --path . --script tests/reisen_level_test.gd`
Expected: FAIL on missing definitions and spell routes.

**Step 3: Implement minimal data**

Add boss metadata, frame folders, low-damage opening nonspell, Reisen canonical cards, and the 3-23 configuration. Make the final event `reisen_boss`; configure `mid_boss_kind` as `tewi_boss`, `mid_boss_nonspell_only` true (a distinct character, not `mid_boss_final_preview`), `row_count` 6, `water_rows` empty, `healing_gourd` in `available_plants` and `conveyor_plants`, and new stage/finale BGM paths.

**Step 4: Run tests to verify they pass**

Run: `godot --headless --path . --script tests/reisen_level_test.gd`
Expected: PASS for data and difficulty contracts.

**Step 5: Commit**

```bash
git add scripts/data/zombie_defs.gd scripts/data/touhou_spell_defs.gd scripts/data/level_defs_pool.gd tests/reisen_level_test.gd
git commit -m "feat: register 3-23 reisen and tewi routes"
```

### Task 3: Prepare supplied art and audio assets

**Files:**
- Create: `art/tewi/frame_00.png` through `art/tewi/frame_23.png`
- Create: `art/reisen/frame_00.png` through `art/reisen/frame_23.png`
- Create: `audio/th08_tewi_stage.mp3`
- Create: `audio/th08_reisen_boss.mp3`
- Create: `art/tewi/source.json`
- Create: `art/reisen/source.json`

**Step 1: Write asset contract checks**

Assert all 48 frames exist, load as textures, have nonzero dimensions, and match the existing 24-frame boss conventions. Assert copied audio files exist and import.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/reisen_level_test.gd`
Expected: FAIL on missing assets.

**Step 3: Generate/copy assets**

Use exact 256×256 RGBA crops from the two supplied 1536×1024 atlases. Inspection confirmed existing transparent backgrounds, so preserve alpha without another color key. Write source metadata and copy the supplied MP3 files into the project paths.

**Step 4: Run asset tests**

Run: `godot --headless --path . --script tests/reisen_level_test.gd`
Expected: PASS with all 24 Tewi and 24 Reisen textures loadable.

**Step 5: Commit**

```bash
git add art/tewi art/reisen audio/th08_tewi_stage.mp3 audio/th08_reisen_boss.mp3 tests/reisen_level_test.gd
git commit -m "feat: add 3-23 tewi and reisen assets"
```

### Task 4: Add Reisen runtime state and mechanics tests

**Files:**
- Create: `scripts/runtime/reisen_boss_runtime.gd`
- Modify: `scripts/game.gd`
- Create: `tests/reisen_mechanics_test.gd`

**Step 1: Write the failing mechanics tests**

Test madness-eye marks and clears plants, eclipse progresses and restores, portals spawn/destroy correctly, corridor return state is bounded, and all owner-scoped state clears on phase change, defeat, and retry.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/reisen_mechanics_test.gd`
Expected: FAIL because the runtime and state hooks do not exist.

**Step 3: Implement minimal runtime**

Add owner-scoped arrays for eye fields, eclipse state, portals, and return bullets. Implement update/cast/reset/clear_owner methods. Wire `_spawn_zombie`, `_trigger_boss_skill`, `_update_zombies`, `_cleanup_dead_zombies`, `_begin_level`, and drawing hooks. Use low-impact damage and existing difficulty multipliers.

**Step 4: Run mechanics tests**

Run: `godot --headless --path . --script tests/reisen_mechanics_test.gd`
Expected: PASS with deterministic state transitions and cleanup.

**Step 5: Commit**

```bash
git add scripts/runtime/reisen_boss_runtime.gd scripts/game.gd tests/reisen_mechanics_test.gd
git commit -m "feat: add reisen madness eclipse and portal runtime"
```

### Task 5: Add infinite corridor visuals

**Files:**
- Modify: `scripts/game.gd`
- Modify: `tests/reisen_battle_flow_test.gd`

**Step 1: Add visual-state assertions**

Assert the `infinite_moon_corridor` terrain renders six grass lanes, rotates only the background angle, and keeps board cell coordinates unchanged.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/reisen_battle_flow_test.gd`
Expected: FAIL because the terrain branch is absent.

**Step 3: Implement the terrain branch**

Add the dark corridor gradient, moon disc, concentric corridor arches, perspective lines, rotating particles, and a restrained eclipse overlay. Keep visual alpha readable on desktop and narrow landscape layouts.

**Step 4: Run the battle-flow test**

Run: `godot --headless --path . --script tests/reisen_battle_flow_test.gd`
Expected: PASS for stable grid coordinates and visible corridor state.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/reisen_battle_flow_test.gd
git commit -m "feat: render infinite moon corridor for 3-23"
```

### Task 6: Verify full battle flow and screenshots

**Files:**
- Modify: `tests/reisen_battle_flow_test.gd`
- Create: `tests/reisen_capture_test.gd`
- Modify: `docs/touhou-spells.md`
- Modify: `README.md`

**Step 1: Add end-to-end assertions**

Cover road BGM retention, continuing minions, frozen wave count/progress, defeat-only gate release, final BGM switch, difficulty phase growth, pause, retry, and desktop/mobile screenshot capture.

**Step 2: Run focused tests**

Run:
- `godot --headless --path . --script tests/reisen_level_test.gd`
- `godot --headless --path . --script tests/reisen_mechanics_test.gd`
- `godot --headless --path . --script tests/reisen_battle_flow_test.gd`
- `godot --headless --path . --script tests/reisen_capture_test.gd`

Expected: PASS with no new parser/runtime errors.

**Step 3: Inspect captures**

Run: `godot --path . --script tests/reisen_capture_test.gd -- --capture`
Inspect the saved desktop and narrow landscape PNGs for the corridor, Boss frames, eye rings, portals, and non-overlapping HUD.

**Step 4: Run broader regression**

Run the existing Touhou, game boot, level, and UI tests, including `tests/touhou_self_midboss_test.gd`, `tests/touhou_encounter_test.gd`, `tests/touhou_difficulty_flow_test.gd`, `tests/game_boot_test.gd`, and `tests/battle_hud_layout_test.gd`.

**Step 5: Update docs and commit**

Document 3-23 mechanics, canonical/original spell split, asset provenance, and test commands.

```bash
git add tests/reisen_battle_flow_test.gd tests/reisen_capture_test.gd docs/touhou-spells.md README.md
git commit -m "test: verify 3-23 reisen battle flow and visuals"
```

### Task 7: Publish with the NightsReimu identity

**Files:**
- No source changes.

**Step 1: Verify identity and scope**

Run: `git config user.name && git config user.email && git status --short`
Expected: `NightsReimu` and `nightsreimu@gmail.com`; generated `.import` and `tmp/` files remain untracked.

**Step 2: Verify final diff and tests**

Run: `git diff --check` and the focused plus broader tests from Task 6.

**Step 3: Push**

Push the current `main` branch to `origin/main` using the configured `NightsReimu/pvz-godot` remote.

**Step 4: Create release metadata if repository workflow requires it**

Use the project’s existing release workflow conventions and report the resulting commit and release tag.
