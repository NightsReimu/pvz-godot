# 2-31 Yakumo Netherworld Boss Level Design

## Goal

Add a polished Touhou Perfect Cherry Blossom Extra/Phantasm-inspired branch level after 2-30. The route uses Chen as the midboss, Ran Yakumo as the first final boss, and Yukari Yakumo as a separate second final boss that appears only after Ran is defeated.

## Level Flow

- Level id: `2-31`
- World: `night`
- Terrain: `phantasm_sakura`
- Mode: conveyor
- Unlock requirement and branch source: `2-30`
- Route target: roughly 120 seconds, shorter than a long stage-four route
- Route and Chen use `res://audio/yakumo_intro.mp3`
- Ran uses `res://audio/ran_boss.mp3`
- Yukari uses `res://audio/yukari_boss.mp3`

The level uses an explicit finale state instead of scheduling Ran and Yukari as ordinary overlapping events. Ran is the scheduled final event. Her death is intercepted before victory, a visible boundary transition plays, and Yukari is spawned as an independent boss. Stage completion remains blocked until Yukari is defeated.

## Enemy And Conveyor Rules

The ordinary route may use the game's existing non-boss zombies, including elite and supernatural units. Only `flywheel_zombie` and `programmer_zombie` are excluded. The conveyor roster emphasizes magic, prism, mushroom, frost, control, defense, healing, and limited explosive plants. It does not include support plants required by water, roof, or cloud terrain.

## Boss Design

Ran is a fast shikigami boss focused on calculated formations, fox/tanuki lasers, twelve-general patterns, Chen summons, and Iizuna-Gongen pressure. She stays mainly on the right side and moves only as part of specific spell actions. Her effects use only `ran_*` shapes.

Yukari is a boundary youkai. Her cycle uses dream/reality, motion/stillness, light/dark mesh, spiriting away, black death butterflies, Ran shikigami, life/death boundaries, and a final danmaku barrier. Gaps telegraph movement and attacks before damage. Her effects use only `yukari_*` shapes. She remains mainly on the right side and does not constantly wander.

Both bosses preserve reaction windows and use visual telegraphs before high-damage attacks. Neither enters the home lane, triggers mowers, or causes an immediate loss by position alone.

## Terrain And Visuals

`phantasm_sakura` is a fully plantable land terrain beneath a giant Netherworld cherry tree. The background combines moonlit stone paths, pale blossoms, ghost lanterns, drifting petals, and boundary gaps. Selection preview and battle rendering share the same terrain identity. Boss transition effects stay inside the battlefield and text/UI are drawn above them.

## Art Pipeline

Ran and Yukari each use 24 prebaked left-facing frames. The supplied 8-pose references remain the authority for identity and costume. ChatGPT image generation in the user's logged-in Chrome session produces two intermediate frames per pose group on a flat chroma background. Post-processing removes only exterior connected background/fringe while preserving internal white hair, clothes, umbrella details, tails, and spell effects.

Outputs:

- `res://art/ran/frame_00.png..frame_23.png`
- `res://art/yukari/frame_00.png..frame_23.png`

## Persistence And Compatibility

No save schema changes are needed. Existing level completion and unlock logic handles 2-31. Boss-finale state is runtime-only and resets whenever the level begins or the player leaves battle.

## Testing

Tests cover unlock flow, route length, enemy exclusions, conveyor constraints, BGM transitions, independent Ran/Yukari sequencing, victory blocking, boss definitions, almanac copy, spell effect families, right-side movement bounds, terrain preview, 24-frame assets, alpha cleanup, prewarm paths, release version, and regression behavior for 2-30.
