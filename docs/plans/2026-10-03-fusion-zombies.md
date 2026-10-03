# Fusion zombies and independent equipment Implementation Plan

**Goal:** Add the reasonable equipment combinations across ordinary zombie roles, preserve their abilities, and make headgear resist attacks that only pierce handheld shields.

**Architecture:** Generate a reviewed catalogue of equipment recipes from existing zombie definitions. A spawned fusion retains its base `kind` for behavior and stores `fusion_kind` for its catalogue identity; added headgear and handheld gear have independent health. Existing native `shield_health` remains compatible with existing behavior and tests. One equipment helper supplies damage order, HUD colors, metal removal and draw anchors.

**Tech Stack:** Godot 4.6, GDScript, existing vector combat art.

## Design

- Headgear-compatible humanoids receive cone and bucket variants; selected mobile roles also receive football and dark football helmets. Free-hand roles receive a screen door, including headgear-plus-door combinations. Do not stack two helmets or two handheld objects, attach handheld doors to two-handed jumpers, or add gear to bosses, vehicles, floating spirits or non-humanoid enemies.
- Normal front attacks damage handheld gear, then headgear, then the body, carrying leftover damage through layers. Smoke, boomerangs, piercing beams and rear attacks skip handheld gear only. Crush, drowning and explicit execution retain their existing full bypass.
- Headgear bars are amber, handheld bars blue, body bars red. Both independent gear bars remain visible when equipped; damaged and removed equipment updates visually without removing the base zombie identity.
- Add catalogue entries and a bounded number of fusion replacements to later endless waves, gated by equipment strength. Authored campaign enemies, terrain restrictions and special stage whitelists remain authoritative.

## Tasks

1. Reproduce the fume-shroom native headgear bypass using a real attack fixture before changing damage behavior.
2. Create `scripts/data/fusion_zombie_defs.gd` and `scripts/runtime/zombie_equipment.gd`; extend `scripts/game_defs.gd` and spawn/catalogue handling in `scripts/game.gd`.
3. Route damage through independent gear, classify native gear, preserve break reactions and update smoke/piercing attack flags in plant/projectile runtime.
4. Compose gear using existing combat drawing, add separate colored health bars and readable almanac descriptions, integrate magnetic removal and health scaling.
5. Add comprehensive `tests/fusion_zombie_test.gd`: all recipes spawn correctly, role abilities still work, normal/piercing/rear hits route correctly, overflow/metal removal/scaling are independent, early/late endless gates are respected.
6. Run relevant combat, projectile, role, endless, pool and UI regressions and capture actual native renderings of whole/intact/broken combinations in desktop and mobile sizes.

## Validation commands

`godot --headless --path . --script tests/fusion_zombie_test.gd`

Run related repository GDScript tests individually with timeouts and scan logs for script errors as well as exit codes. Inspect native screenshot contact sheets for overlays, damaged gear, facing direction and equipment bars.

This task follows the user's request to implement the broader catalogue directly. Work is executed in the current checkout, preserving existing untracked files; no delegation or release publication is requested in this turn.

## Completed implementation and verification

- Added 163 recipes across 50 native definition IDs. The headgear table covers 47 roles; native cone, bucket and football variants supply the canonical helmet-plus-door combinations. Examples include armored ninjas, dancers, pole vaulters, snorkelers, wizards, mounted knights and volcano enemies.
- Fusion equipment has independent current/maximum health, reward, catalogue text, damage/metal-removal order and worn/removed visuals. Native role behavior remains keyed to the base kind. Ordinary authored rosters retain their existing entries.
- Endless replaces up to an 18% roll of eligible base spawns. Added cones start at wave 6, buckets at 9, doors at 10, football helmets at 12, double gear at 14 and dark helmets at 16; dark football-plus-door starts at 18. Both equipment layers scale with endless health.
- Corrected actual smoke, boomerang, piercing projectile, lotus barrage and beam paths, including click/plant-food mirror, laser, solar, plasma, dragon breath and echo attacks. Headgear consumes piercing damage before the body. Rear direction respects hypnosis; the final hit of a piercing projectile retains its attack property. Armor bonuses conserve overflow damage.
- All 115 headless GDScript scripts, 7 native-rendering GDScript scripts and 13 Python validation scripts passed; affected combat tests were rerun after the final changes. Existing assertions that required a beam to bypass a helmet now verify helmet consumption instead.
- `tests/fusion_zombie_test.gd` exercises every recipe, actual normal/piercing attacks and ultimates, front/rear hits, break reactions, magnetic removal, ninja/vault/dancer behavior, endless gates and forbidden-stage spawns. Logs are in `output/fusion-regression/`.
- Native capture produced 21 catalogue pages for intact/worn/removed gear and 2 battle screenshots at 1600×900 and 844×390, with zero render-state mutation failures. Inspected all intact pages plus worn/removed samples and desktop/mobile battles. Previews are in `output/fusion-zombies/`.
- `git diff --check` passed. Changes remain local for the current task.
