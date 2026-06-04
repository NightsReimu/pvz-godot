# Combat Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add impact sound, hit effects, lightweight particles, and a first batch of polished battle assets.

**Architecture:** Keep the current `Control`-drawn game. Add a thin feedback API on `Game`, call it from `ProjectileRuntime`, and add optional texture-backed drawing for selected plants/projectiles with procedural fallback.

**Tech Stack:** Godot 4.6 GDScript, `AudioStreamPlayer`, `AudioStreamWAV`, PNG assets, existing headless SceneTree tests.

---

### Task 1: Focused Tests

**Files:**
- Create: `tests/combat_polish_test.gd`

**Steps:**

1. Write tests for SFX pool creation, generic projectile impact feedback, and polish asset loading.
2. Run `godot --headless --path . --script tests/combat_polish_test.gd`.
3. Expected red state: missing methods/assets or missing impact feedback.

### Task 2: Generated Assets

**Files:**
- Create: `scripts/tools/image2_polish_prompts.jsonl`
- Create: `scripts/tools/run_image2_polish_assets.sh`
- Create: `scripts/tools/prepare_image2_polish_asset.py`
- Create: `scripts/tools/generate_combat_polish_assets.gd`
- Create: `art/polish/peashooter-polished.png`
- Create: `art/polish/sunflower-polished.png`
- Create: `art/polish/wallnut-polished.png`
- Create: `art/polish/pea-polished.png`
- Create: `output/imagegen/image2-polish/`
- Create: `audio/sfx/hit-soft.wav`
- Create: `audio/sfx/hit-bright.wav`

**Steps:**

1. Add image2 prompt jobs for peashooter, sunflower, wallnut, and pea projectile sprites.
2. Add a runner that reads `/Users/hecrereed/xianyu/蜂蜜/image2画图配置`, exports the configured base URL and API key, and calls the bundled image generation CLI with `gpt-image-2`.
3. Remove the chroma-key background locally, trim each source, and write final transparent PNGs into `art/polish/`.
4. Keep the Godot tool script for short WAV hit sounds only, so rerunning it cannot overwrite image2-generated PNGs.
5. Confirm final PNG and WAV files exist and load in Godot.

### Task 3: SFX Pool

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/combat_polish_test.gd`

**Steps:**

1. Add `sfx_players`, `sfx_stream_cache`, and constants for hit SFX paths.
2. Add `_build_sfx_players()`, `_load_sfx_stream()`, `_play_sfx()`.
3. Ensure `_build_audio_player()` also prepares the SFX pool.
4. Run the focused test and keep only the expected remaining failures.

### Task 4: Impact Feedback

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/runtime/projectile_runtime.gd`
- Test: `tests/combat_polish_test.gd`, `tests/plant_effect_alignment_test.gd`

**Steps:**

1. Add `_emit_projectile_impact_feedback()` to create `projectile_impact`, particles, shake, and SFX.
2. Add drawing support for `projectile_impact` in `_draw_effects()`.
3. Call the feedback helper from normal projectile hit paths.
4. Run focused tests and existing projectile/effect tests.

### Task 5: Optional PNG Drawing

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/combat_polish_test.gd`, `tests/game_boot_test.gd`

**Steps:**

1. Add cached polish texture loading.
2. Add `_try_draw_polished_plant()` for peashooter, sunflower, and wallnut.
3. Add `_try_draw_polished_projectile()` for basic pea projectiles.
4. Keep all existing procedural drawing as fallback.
5. Run focused tests and boot test.
