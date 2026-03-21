# Pool Animation And UI Refresh Design

**Date:** 2026-03-21

**Goal**

Upgrade the current Godot PvZ prototype so it feels closer to classic PvZ moment-to-moment readability while keeping the existing single-scene, vector-drawn architecture. The work covers three areas: stronger plant/zombie animation, more coherent directional combat VFX, and cleaner pool-world spawning rules with three buoy zombie variants.

**Current State**

- The whole game is driven from [`scripts/game.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/game.gd) with most gameplay, drawing, and UI in one script.
- Static data lives in [`scripts/game_defs.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/game_defs.gd).
- Shared panel drawing helpers live in [`scripts/ui/game_theme.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/ui/game_theme.gd).
- Squash currently kills instantly and only spawns a radial hit effect.
- Fume-shroom currently damages a forward lane segment but still renders a radial pulse, so the visuals do not match the gameplay.
- Pool levels declare water rows, but generic row selection can still choose those rows for land zombies.
- Pool content only has a single `ducky_tube` unit instead of a normal / cone / bucket buoy progression.

**Design Decisions**

**1. Keep the existing vector-rendered architecture**

Do not rewrite the game into many scene files. The current project is compact, and the fastest path is to extend the existing draw/update model. This keeps risk low and lets us ship the requested gameplay and presentation upgrades in one pass.

**2. Add explicit presentation state for special attacks**

Basic action pulses through `action_timer` already exist, but Squash and Fume-shroom need richer presentation state:

- Squash gets a short attack state machine: idle, windup, launch, slam, recover.
- Fume-shroom gets directional spray metadata so rendering can draw a lane-forward plume rather than a circle.
- Effects will support both radial and directional shapes so future plants can reuse the same system.

**3. Split pool spawning into land and water families**

Pool stages should never spawn land zombies into water lanes unless a level event explicitly declares a water-capable zombie. Generic spawn logic will classify zombie kinds into:

- Land-only
- Water-capable
- Ice-lane-dependent

Row selection will then choose from eligible rows only.

**4. Replace single buoy zombie with three real variants**

The old `ducky_tube` becomes a family:

- `lifebuoy_normal`
- `lifebuoy_cone`
- `lifebuoy_bucket`

These use pool movement and buoy visuals, but scale health and presentation like normal / conehead / buckethead progression.

**Animation And VFX**

**Squash**

- Add attack detection that stores a target and attack timers before damage is applied.
- Windup compresses the body downward and leans toward the target.
- Launch stretches the body horizontally with forward travel.
- Slam resolves damage on impact, with a dust ring and lane-skid accent instead of a plain circle.
- Plant food mode reuses the same language with faster chained impacts.

**Fume-shroom**

- Replace circular effect drawing with a forward corridor plume aligned to the lane.
- Use layered translucent bands and drifting highlights to suggest continuous gas.
- Body animation will push the cap and snout forward during each shot.
- Plant food burst uses a denser and brighter version of the same directional plume.

**General Motion**

- Tune `_plant_draw_motion()` so heavy plants, mushrooms, and explosive plants no longer share almost identical rhythms.
- Give water-capable zombies a buoyant vertical bob and small wake motion.
- Keep overall readability higher than realism; the game should remain easy to parse.

**UI And Scene Polish**

- Refresh battle HUD panels, card hover states, selected states, disabled states, and wave bar sweep.
- Improve pool background layering with clearer deck/water separation, stronger highlights, and calmer repeated wave motion.
- Keep the existing hand-drawn style, but sharpen contrast and state feedback to better match classic PvZ.

**Gameplay Rules**

- Land zombies cannot be assigned to `water_rows`.
- Water-capable zombies prefer `water_rows` and only spawn there for pool-specific progression.
- Existing pool level scripts will be updated so later stages introduce cone and bucket buoy variants.
- Almanac order and text will include the new variants.

**Files To Change**

- Modify [`scripts/game.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/game.gd)
- Modify [`scripts/game_defs.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/game_defs.gd)
- Modify [`scripts/ui/game_theme.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/ui/game_theme.gd)

**Verification Plan**

- Run focused regression coverage for pool row assignment and zombie kind eligibility.
- Launch the project with Godot MCP and verify startup is clean.
- Run the game and inspect Squash attack timing, Fume-shroom directional VFX, pool-wave enemy composition, and updated HUD responsiveness.
