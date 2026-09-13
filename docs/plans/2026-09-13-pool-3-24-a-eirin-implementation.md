# 3-24-a Eirin Implementation Plan

**Goal:** Add the approved TH08 6A Eirin encounter, terrain changes and Touhou enemies using the supplied assets.

**Architecture:** Keep the board and input coordinates stable. Dedicated Eirin spell data, danmaku, battlefield and enemy modules connect to existing phase, spawn, healing and rendering paths. Temporary state belongs to its owner and must reset on retry and defeat.

**Tech Stack:** Godot 4.6 GDScript, Python/Pillow/OpenCV asset preparation, GitHub Actions exports.

## Tasks

1. Add `tests/eirin_level_test.gd`; observe missing-stage failure. Add `scripts/data/eirin_level_defs.gd`, `eirin_spell_defs.gd`, the pool entry and boss/enemy definitions. Verify ID, world, four difficulties, canonical cards, road route, conveyor and audio.
2. Crop the provided 6×4 sheet with `scripts/tools/prepare_eirin_frames.py`; verify 24 transparent, consistently scaled frames and inspect a contact sheet on dark/light backgrounds. Copy supplied music. Register frame loading, scale and source metadata.
3. Add `tests/eirin_mechanics_test.gd`; fail first on missing runtime. Implement corridor exit gate, world transitions, telegraphs, temporary tiles, healing suppression and reversible rage in `scripts/runtime/eirin_boss_runtime.gd` and necessary game hooks.
4. Implement `scripts/runtime/eirin_danmaku.gd` with distinct canonical families and original pressure casts. Verify actual damage to ordinary-health plants, no damage before warnings, all phases completable and bounded projectile counts.
5. Add `scripts/runtime/touhou_enemy_runtime.gd`: fairy shots, one-generation kedama split and rabbit airship movement/drop behavior. Test every crossing under fine and coarse delta, return boundary, ground projectile damage, pause and death.
6. Add `tests/eirin_battle_flow_test.gd`: run actual processing and capture corridor, transition, moon and terrain states at 1600×900 and 844×390. Check road music, frozen events, exit-before-finale, boss music, pause, retry, unlock and selection.
7. Run related Touhou phase/difficulty, healing, conveyor and collision regressions. Inspect screenshots and fix any discovered issues. Update docs/version, merge into main, commit/push with NightsReimu identity and publish a verified four-platform Release.

Use `godot --headless --path . --script tests/<test>.gd` for logic, and native `godot --path . --script tests/eirin_battle_flow_test.gd -- --capture` for rendering. Review each meaningful implementation against its failing test; stop expanding validation once the appropriate tests pass without unresolved concerns.

## Implementation record

- Implemented data, six canonical spell groups plus three difficulty extensions, corridor exit gate, moon/world backgrounds, temporary terrain, medicine and common healing hooks.
- Cropped all 24 supplied Eirin poses, removed gray/rose background and neighboring-cell spill. Inspected dark and cream contact sheets; retained shared silhouette calibration.
- Implemented fairy, single-generation kedama and ground-targetable rabbit airship. Road/final mixed roster includes water, mechanical and stationary combat units such as dragon boats.
- Red-to-green checks: missing stage, missing runtime, all-world roster excluding zero-speed dragon boat, and missing conventional frame-selector entry. Fixed each implementation issue. A ground-pea fixture uses actual small frame steps because its existing collision code tests discrete positions.
- Passed stage/asset, actual mechanics, complete four-difficulty phase, BGM/road/final/pause/retry and 1600×900/844×390 native rendering tests. Captures use fixed-size SubViewports to avoid macOS backing-scale differences.
- Related healing gourd, click ultimate, conveyor, Reisen, Touhou difficulty/phase/collision, volcano, gacha passive and world-navigation regressions pass. All temporary outputs remain in ignored `output/eirin`.
- Version 1.0.110 and release notes prepared; publish with NightsReimu author/committer identity, then verify four platform assets and Pages deployment.
