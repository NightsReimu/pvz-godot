# Battle Visual Style Unification Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Unify all plant, zombie, projectile, and effect rendering with the volcano expansion visual language while preserving existing character silhouettes and Touhou spell art.

**Architecture:** Add small shared rendering helpers in `scripts/game.gd` for ground shadows, outline/highlight overlays, status rings, and projectile cores. Call them from the existing plant/zombie/image2/procedural paths so gameplay logic and assets remain unchanged. Keep world-specific colors in a compact theme helper and reuse the same rules in the volcano runtime.

**Tech Stack:** Godot 4 GDScript, CanvasItem `_draw`, existing image2 textures, repository Godot and Python tests.

---

### Task 1: Add shared visual primitives

**Files:**
- Modify: `scripts/game.gd` near existing draw helpers and `_draw_health_bar`
- Test: existing Godot parse/test commands

**Step 1:** Add helpers for theme tint selection, ground shadow, outline/highlight rings, and status overlays. Keep all dimensions bounded by the supplied unit size.

**Step 2:** Run the Godot parser/tests to catch type or CanvasItem API errors.

**Step 3:** Commit the helper-only change.

### Task 2: Apply the shell to plants and zombies

**Files:**
- Modify: `scripts/game.gd::_draw_plants`, `_try_draw_image2_plant`, `_draw_zombies`, `_try_draw_image2_zombie`, `_draw_zombie`

**Step 1:** Draw a shared shadow before every visible plant/zombie and add a restrained outline/highlight after the existing body draw.

**Step 2:** Add status overlays for flash, slow, hypnotized, shield, plant food, and boss cast state without changing gameplay fields.

**Step 3:** Use the same helpers for card and almanac icons, with a smaller scale multiplier.

**Step 4:** Run focused battle and almanac tests and inspect desktop/mobile screenshots.

### Task 3: Unify projectiles and effects

**Files:**
- Modify: `scripts/game.gd::_draw_projectiles`, `_try_draw_image2_projectile`, `_draw_effects`
- Modify: `scripts/runtime/volcano_expansion_runtime.gd::draw_effect`

**Step 1:** Add the shared projectile core, trail, highlight, and impact pulse to procedural and image2 projectiles.

**Step 2:** Add a common outer ring and state-colored pulse to generic effects while leaving Touhou-specific shapes intact.

**Step 3:** Verify that effect alpha follows lifetime and that overlays do not cover health bars.

### Task 4: Add visual regression coverage

**Files:**
- Modify or add: focused tests/scripts under `tests/` following existing repository conventions

**Step 1:** Add checks for stable draw sizes, status color selection, and image2 fallback behavior.

**Step 2:** Run all Godot tests and Python tests.

**Step 3:** Capture desktop `1600x900` and mobile landscape screenshots and inspect representative ordinary, volcano, and Boss scenes.

### Task 5: Publish

**Files:** all implementation files and plan docs

**Step 1:** Review the diff and verify the working tree contains no unrelated changes.

**Step 2:** Commit with Git identity `NightsReimu <nightsreimu@gmail.com>`.

**Step 3:** Push the branch to `https://github.com/NightsReimu/pvz-godot.git`.
