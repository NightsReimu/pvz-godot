# Touhou self-midboss implementation plan

**Goal:** Continue the interrupted boss work with defeat-only road encounters for
Rumia, Meiling, Sakuya, Chen, Alice, Youmu, Wriggle, Mystia, Keine, Reimu and Marisa.

**Architecture:** Pass encounter identity into spawning before phase and music
initialization. Reuse character-specific nonspells and the existing midboss gate;
keep the finale's complete spell route and the existing health buffs.

**Tech stack:** Godot 4, GDScript, existing headless and rendered capture fixtures.

## Accepted behavior

- No 16-second withdrawal or forced completion after a fixed number of attacks.
- Self-midbosses have one health bar at 12% of finale HP, retaining difficulty scaling.
  This is a tower-defense balance value, not an original-game HP ratio.
- They repeat only the character's basic nonspell, with supporting monsters
  continuing to spawn through the existing reinforcement timer. Wave events,
  queued units and the progress bar stay frozen until the boss is defeated.
  Defeat can interrupt the attack immediately; surviving monsters remain.
- Road music continues through midboss entry, fighting and defeat. Only the
  actual finale changes the track.
- The final event stays pending until the road boss is defeated. Road defeat
  neither consumes the remaining events nor wins the level.
- Independent midboss routes and their existing spell sequences remain intact.
- `mid_boss_final_preview` remains the level flag for compatibility; it no longer
  implies a timed appearance. Runtime identity must exist before spawn callbacks.

## Steps

1. Add `tests/touhou_self_midboss_test.gd`: all 11 level mappings, all four
   difficulties, live nonspells, undamaged survival, immediate damage defeat,
   music requests, queued/unbatched finale gates and owner cleanup.
2. Run `godot --headless --path . --script tests/touhou_self_midboss_test.gd`.
   Confirm failures in timed departure, route coverage, music and attack scope.
3. Update `scripts/data/level_defs_{day,night,pool}.gd`,
   `scripts/runtime/touhou_phase_runtime.gd` and `scripts/game.gd`.
   Remove the departure timer, set identity before spawning and isolate the
   single-nonspell route from the mandatory finale phase gate.
4. Update prior assertions that required no self-midboss or timed departure in
   difficulty, Wriggle, Reimu and Marisa tests. Keep finale route assertions.
5. Run the focused test, existing boss/phase/difficulty/flow tests, and headless
   project checks. Render representative road and finale captures and inspect
   the HUD, sprites and resumed stage state.
6. Update `docs/touhou-spells.md` and the current README behavior notes. Preserve
   unrelated worktree changes and generated import files.
