# 2-31 Yakumo Netherworld Boss Level Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add and release a complete 2-31 Chen/Ran/Yukari conveyor boss level with original-inspired mechanics, three-stage BGM routing, a Netherworld cherry terrain, and 24-frame left-facing boss animation.

**Architecture:** Extend the existing night branch data and Touhou boss pipelines. Use a dedicated runtime finale state that intercepts Ran's death, plays a boundary transition, spawns Yukari independently, and blocks victory until Yukari dies. Keep visual effects programmatic and namespaced while sprite generation/post-processing remains in the existing boss asset pipeline.

**Tech Stack:** Godot 4 GDScript, PNG/MP3 assets, existing Python/Godot asset tools, headless Godot tests, GitHub Actions release workflow.

---

### Task 1: Add the RED branch contract

**Files:**
- Create: `tests/yakumo_branch_test.gd`

**Step 1:** Write tests for 2-31 unlock, terrain, route duration, Chen midboss, Ran final event, excluded enemy kinds, conveyor roster, three BGM paths, boss definitions, almanac, sequential transition helpers, independent victory blocking, and 24-frame assets.

**Step 2:** Run `godot --headless --path . -s res://tests/yakumo_branch_test.gd`.

**Expected:** FAIL because 2-31, Ran/Yukari definitions, assets, and helpers do not exist.

### Task 2: Add level, audio, definitions, and almanac data

**Files:**
- Modify: `scripts/data/level_defs_night.gd`
- Modify: `scripts/data/zombie_defs.gd`
- Modify: `scripts/data/almanac_text.gd`
- Create: `audio/yakumo_intro.mp3`
- Create: `audio/ran_boss.mp3`
- Create: `audio/yukari_boss.mp3`

**Step 1:** Add 2-31 after 2-30 with a compact event route, explicit enemy pool, conveyor roster, Chen midboss, Ran final event, and three BGM fields.

**Step 2:** Add balanced Ran and Yukari boss records with independent spell cycles and interval floors.

**Step 3:** Add almanac text grounded in shikigami and boundary mechanics.

**Step 4:** Copy the supplied MP3 files and import them with Godot.

**Step 5:** Re-run `tests/yakumo_branch_test.gd`; expect data/audio assertions to pass while runtime and art assertions remain RED.

### Task 3: Implement terrain and selection preview

**Files:**
- Modify: `scripts/game.gd`
- Modify: `tests/special_modes_test.gd`

**Step 1:** Add a failing special-mode assertion for `phantasm_sakura` preview style.

**Step 2:** Run the focused special-mode test and confirm RED.

**Step 3:** Add `_is_phantasm_sakura_level()` and integrate the new background into battle and selection preview rendering.

**Step 4:** Re-run the focused test and confirm GREEN.

### Task 4: Implement sequential finale and BGM routing

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/yakumo_branch_test.gd`

**Step 1:** Add runtime state for the Ran-to-Yukari transition and reset it on level start/exit.

**Step 2:** Route Chen to intro music, Ran to `ran_boss_bgm`, and Yukari to `yukari_boss_bgm`.

**Step 3:** Intercept Ran death on 2-31, suppress stage completion, spawn transition FX, and schedule independent Yukari spawn.

**Step 4:** Ensure only Yukari's death satisfies final boss completion.

**Step 5:** Run `tests/yakumo_branch_test.gd` and confirm sequencing/BGM assertions are GREEN.

### Task 5: Implement Ran and Yukari mechanics and effects

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/yakumo_branch_test.gd`

**Step 1:** Add frame cache/count/index/draw/prewarm/almanac order paths for both bosses.

**Step 2:** Implement `_trigger_ran_boss_skill()` and phase shift with nine spell states and `ran_*` effects.

**Step 3:** Implement `_trigger_yukari_boss_skill()` and phase shift with ten spell states, telegraphed gaps, right-side movement, and `yukari_*` effects.

**Step 4:** Integrate skill/update dispatch and reinforcement timing without copying earlier boss effect names.

**Step 5:** Run branch and boot tests until GREEN.

### Task 6: Generate and normalize 24-frame boss art

**Files:**
- Create: `art/ran/frame_00.png..frame_23.png`
- Create: `art/yukari/frame_00.png..frame_23.png`
- Modify: `scripts/tools/normalize_boss_frames.gd`
- Modify: `scripts/tools/generate_touhou_boss_animation_frames.py`
- Modify: `tests/touhou_boss_animation_frames_test.gd`
- Modify: `tests/boss_sprite_cleanup_test.gd`
- Modify: `tests/boss_asset_prewarm_test.gd`

**Step 1:** Upload each supplied reference to the logged-in ChatGPT Chrome session and request one 4x6, 24-frame chroma sheet with eight three-frame pose groups.

**Step 2:** Download generated sheets and post-process them into uniform, left-facing transparent frames while preserving internal white areas and thin details.

**Step 3:** Import all frames in Godot and extend manifest/cleanup/prewarm tests.

**Step 4:** Generate contact sheets and visually verify identity, scale, orientation, fringe, and interpolation continuity.

**Step 5:** Run animation, cleanup, prewarm, and branch tests until GREEN.

### Task 7: Regression and release

**Files:**
- Modify: `project.godot`
- Create: `RELEASE_NOTES_v1.0.89.md`

**Step 1:** Set `config/version="1.0.89"` and write release notes.

**Step 2:** Run `yakumo_branch_test.gd`, `yuyuko_branch_test.gd`, `youmu_branch_test.gd`, `chen_branch_test.gd`, `boss_asset_prewarm_test.gd`, `touhou_boss_animation_frames_test.gd`, `boss_sprite_cleanup_test.gd`, `special_modes_test.gd`, `game_boot_test.gd`, image2 manifest tests, release workflow test, and `git diff --check`.

**Step 3:** Run the full Godot/Python regression suite and fix all introduced failures.

**Step 4:** Commit with author `hecrereed <821896444@qq.com>` using `feat: add Yakumo Netherworld boss level`.

**Step 5:** Integrate into `main`, push `main`, create/push `v1.0.89`, monitor the Release workflow, and verify Android, macOS, Web, and Windows assets.
