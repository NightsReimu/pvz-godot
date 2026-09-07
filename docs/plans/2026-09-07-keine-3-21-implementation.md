# Keine 3-21 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add the approved 3-21 moonlit forest encounter with Keine, supplied animation/music, canonical spell references and explicitly original tower-defense abilities.

**Architecture:** Reuse the level registry, shared Touhou phase/danmaku system and preprocessed boss frame loader. Put the new scenery and whip/piano/bamboo mechanics in a dedicated runtime; hostile bamboo uses targetable enemy entities and never overwrites the player's grid.

**Tech Stack:** Godot 4.6, GDScript, Pillow/OpenCV asset preparation, native viewport capture, GitHub Actions releases.

### 1. Source and assets
- Verify TH08 stage-three spell names and distinguish original additions.
- Process the supplied 6-by-4 sheet into `art/keine/frame_00.png` through `frame_23.png`, inspect a contact sheet on dark backgrounds and preserve magenta spell details.
- Copy the two supplied MP3s to `audio/th08_keine_stage.mp3` and `audio/th08_keine_boss.mp3`.

### 2. Encounter data
- Add `keine_boss` to `scripts/data/zombie_defs.gd` and `scripts/data/touhou_spell_defs.gd`.
- Add 3-21 after 3-20 in `scripts/data/level_defs_pool.gd`: six grass rows, no midboss, conveyor, proper unlock/music.
- Add focused contract tests in `tests/keine_level_test.gd`.
- Run `godot --headless --path . --script tests/keine_level_test.gd`.

### 3. Runtime and presentation
- Implement distinct spell trajectories in `scripts/runtime/touhou_danmaku_runtime.gd`.
- Create `scripts/runtime/keine_boss_runtime.gd`: telegraphed whip/piano hits, capped destructible bamboo summons, cleanup, moonlit forest rendering and supplied sprite animation.
- Wire asset loading, spawn music, frame selection, gameplay ticking and drawing through `scripts/game.gd`.
- Test effects on real plant health/cooldowns, summon limits and cleanup in `tests/keine_mechanics_test.gd`.

### 4. Verification and delivery
- Capture desktop and mobile landscape gameplay with `scripts/tools/capture_keine_battle.gd`; open screenshots and inspect art, HUD, telegraphs and scene.
- Run existing Touhou phase, boss-flow, UI and adjacent-stage regressions; examine logs for errors regardless of process exit status.
- Update version and spell documentation for 1.0.100, commit explicit task files with NightsReimu identity, push and tag `v1.0.100`.
- Verify release workflow and downloadable artifacts before reporting completion.

### Implementation status
- Source research, supplied 24-frame processing, music, encounter data and runtime are implemented.
- Native screenshots inspected at 1600x900 and 844x390; whip lines are clipped to the board and the compact HUD leaves room for all six rows.
- Keine level, complete five-phase/twelve-attack encounter, live planting/music/pause/restart/victory, general Touhou spell/encounter, UI layout and adjacent Mystia/Wriggle regressions pass.
- Release build and artifact verification remain the delivery gate for v1.0.100.
