# Combat Polish Design

**Date:** 2026-06-04

**Goal**

Make the battle loop feel smoother and punchier without rewriting the current single-scene Godot architecture. The first pass focuses on projectile impact feedback, lightweight SFX playback, richer impact particles, and a small set of polished PNG assets for the most common plants/projectiles.

**Current State**

- `scripts/game.gd` owns the scene, drawing, BGM, screen shake, and particle arrays.
- `scripts/runtime/projectile_runtime.gd` owns projectile movement and hit resolution.
- Effects are dictionaries in `effects`; short-lived particles are dictionaries in `vfx_particles`.
- BGM uses one `AudioStreamPlayer`; there is no reusable hit SFX pool.
- Most plants and projectiles are hand-drawn in code. Existing PNG loading is limited to boss frames.

**Design**

Add a small feedback layer instead of splitting the whole project into many scenes:

- `Game._emit_projectile_impact_feedback(position, projectile, zombie)` creates a generic impact effect, a few particles, light screen shake, and an SFX request.
- `ProjectileRuntime.update_projectiles()` calls that feedback layer at normal projectile hit points while keeping existing special-case effects such as amber splashes and fire splash behavior.
- `Game` owns an SFX pool of `AudioStreamPlayer` nodes so repeated hits do not allocate new players or block the main battle loop.
- Image assets are generated through the image2 config at `/Users/hecrereed/xianyu/蜂蜜/image2画图配置` with `gpt-image-2`. Source and alpha-processing artifacts live under `output/imagegen/image2-polish/`; final transparent PNGs live under `art/polish/`.
- Short generated hit sounds live under `audio/sfx/`. The image2 PNGs and WAV files are optional enhancements, so the existing draw code remains the fallback if an asset is missing.
- `Game._try_draw_polished_plant()` and `_try_draw_polished_projectile()` draw selected PNG assets for common plants/projectiles. Existing procedural art stays in place for every other kind.

**Scope**

This pass upgrades the feel of common combat first:

- Peashooter, sunflower, wallnut, and basic pea art.
- Generic projectile hit effects and hit sound.
- No level design changes, no broad data reshaping, no full plant catalog repaint.

**Verification**

- Add focused Godot tests for SFX pool creation, generic impact feedback, and polish asset loading.
- Run the new test and relevant existing projectile/effect tests.
- Run `game_boot_test.gd` to catch parse/load regressions.
