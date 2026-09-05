# Battle Readability and Boss Continuity

**Goal:** Make attacks, boss transitions, and battle UI easier to read without changing character rosters or damage tables.

**Architecture:** Keep boss scheduling and health feedback in the existing zombie runtime. Keep drawing in `scripts/game.gd`, using the existing character textures, theme helpers, and effect layer.

**Tech Stack:** Godot 4.6, GDScript, existing headless tests and native viewport captures.

## Implementation

1. Add behavioral regressions in `tests/boss_combat_flow_test.gd` for recovery, a visible windup, expired poses, defeated bosses, and successor state. Run the test before and after implementation.
2. Move the shared boss scheduling block into `scripts/runtime/zombie_runtime.gd`. Introduce a short windup within normal cooldowns; defer attacks and autonomous movement during recovery. Keep existing spell implementations and phase thresholds.
3. Add delayed health loss, phase markers, spell status, and a cast progress track to the existing five-segment boss HUD. Keep names and status inside bounded text regions.
4. Freeze combat particles and shake during pause, reset them on restart, and bound decorative particle counts. Isolate battle shake from HUD and remove shake from ordinary projectile impacts.
5. Refine plant skill readiness and remaining-duration indicators. Draw a restrained casting cue around bosses using their existing palette.
6. Verify boss branches, ultimates, pause, effects, and responsive layout. Capture real Godot renderings at desktop and mobile landscape sizes. Inspect changes and run the repository tests.
7. Commit and push to `NightsReimu/pvz-godot` with the verified author and committer `NightsReimu <nightsreimu@gmail.com>`.

## Acceptance

- A boss cannot cast while defeated, mid-shift, or recovering; a fresh windup is visible before each scheduled spell.
- Timed spell poses return to idle and are not overwritten by autonomous movement.
- Successor and revival transitions cannot execute an inherited pending cast.
- Damage feedback settles; healing and boss replacement do not inherit stale health trails.
- HUD text and bars stay within the viewport and outside the board at supported landscape layouts.
- Pausing preserves combat presentation; restarting removes old particles and shake.
- Existing damage, unlocks, boss assets, and branch progression tests continue passing.

## Verification Results

- All 66 GDScript test entry points exit successfully without assertion or script errors. Ten existing test fixtures still report resource cleanup warnings at exit; the same warnings were reproduced against the original commit.
- All eight standalone Python repository checks pass.
- Native Godot captures cover 1600x900, 1365x768 with six rows, and 2000x900 with mobile layout enabled, each during windup and spell release. Run `godot --path . -s res://scripts/tools/capture_battle_polish.gd` to regenerate the images in `output/battle-polish/` without loading or writing player saves.
- Additional fixes from verification: ten-card seed bank fit, mobile resource text anchoring, non-overlapping resource controls and challenge objective strip, complete three-frame pose playback, and board-local sunlight placement for three ultimates.
