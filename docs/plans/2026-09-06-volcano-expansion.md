# Volcano Expansion Implementation Plan

Goal: extend the campaign through 7-20, reward a plant on every volcano clear,
add ten plants and seven enemies, and heal the caster on successful ultimates.

Architecture: keep existing level IDs and indexes. Append ten stages to the
volcano catalogue. A dedicated VolcanoExpansionRuntime owns geothermal charges,
cooling, enemy abilities and delayed attacks; terrain and support grids remain
owned by Game. Reuse the projectile runtime for visible arcing shots.

Tech stack: Godot 4.6, GDScript, existing procedural CanvasItem artwork.

## Design

The player authorized independent creative choices. The expansion uses heat as
a resource, with clearly marked vent warnings and temporary cooling. It avoids
permanent terrain replacement and introduces no new support layer.

Stages 11-20 award thermal sunflower, obsidian artichoke, steam clover, pumice
wall, sulfur pod, resonance beet, pressure bamboo, fumarole melon, magnet orchid,
and caldera lotus respectively. Stage 10 awards the existing gator cannon.
New selection stages include accumulated rewards from earlier stages. Stage 20
is a conventional conveyor boss encounter with the existing volcano boss;
its conveyor excludes sun producers. The final reward joins the persistent
collection for replays and other modes.

Seven enemies: basalt guard (periodic brace), cinder runner (heat sprint), kiln
mason (limited ally armor), ash bell (telegraphed suppression), sulfur carrier
(interruptible pressure blast), geode zombie (armor-break shards), vent tunneler
(one telegraphed vent traversal). Cooling and control interrupt their abilities.

## Implementation

1. Add unit definitions/order/almanac and append stages 11-20. Preserve stage IDs,
   old saves and completed flags; include the final plant in the reward flow.
2. Restore living casters to max_health at the two successful ultimate paths.
   Failed casts and consumed instant plants must not heal or resurrect.
3. Implement scoped plant/enemy/world behavior in volcano_expansion_runtime.gd.
   Use bounded charge/armor, stable UIDs, explicit warning timers and cleanup.
4. Add distinct procedural plant and enemy artwork plus warning/impact rendering.
5. Add progression, ability, support, allegiance, cooldown, pause and reward
   regressions. Run all Godot and Python test entrypoints with isolated saves.
6. Capture native desktop/mobile volcano battles and inspect the results.
7. Review diff, commit and push using NightsReimu's existing Git identity.

## Verification

- Godot 4.6 editor parse completed without script errors.
- All 68 Godot test entrypoints passed their assertions and returned zero after
  correcting the conveyor catalog and the legacy all-enemy encounter rosters.
  Ten existing test entrypoints still report unfreed fixture resources at exit.
- All eight Python script entrypoints passed (these scripts use main(), not
  unittest or pytest discovery).
- Fifteen expansion scenarios cover real projectile damage, ultimates, charge
  limits, armor expiration, control interruptions, allegiance, lava cooling,
  frozen attack cadence, save migration, final rewards and battle resets.
- Native captures at 1600x900 and mobile landscape 2000x900 show all ten plants,
  seven zombies, meteors and vent warnings. Live vents render above the terrain;
  their preplaced support remains stored and becomes visible after sealing.
- The full regression run backed up the real progress file and restored it
  byte-for-byte afterward.

Reproduce behavior checks with:

```sh
godot --headless --path . -s res://tests/volcano_expansion_test.gd
godot --headless --path . -s res://tests/volcano_world_test.gd
```

Capture deterministic previews without touching saves:

```sh
godot --path . --audio-driver Dummy -s res://scripts/tools/capture_volcano_expansion.gd
```

Images are written to the ignored output/battle-polish directory.
