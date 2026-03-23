# Fog World Original-Style Design

**Date:** 2026-03-23

**Goal**

Add a new original-style Fog world to this Godot PvZ project that mirrors the structure and pressure curve of classic PvZ Adventure `4-1` through `4-10`, while fitting the current single-scene, vector-drawn architecture and this project's plant-food system.

**Assumptions**

- The user explicitly asked for a design without follow-up questions, so this document fixes the product direction instead of presenting open decisions.
- "Strictly reference the original" means the world progression, map type, unlock rhythm, core plant and zombie behaviors, and special-stage formats must match classic PvZ first. This project's custom layer is limited to plant-food supers, higher-fidelity animation, and compatibility with the current world-select structure.
- Sea-shroom is treated as a carried-over starter card for Fog, matching the original game where it is unlocked before Fog begins, not as a Fog-world reward.

**Current Project Fit**

- World grouping currently depends on level ID prefixes inside [`scripts/game.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/game.gd) and world card data in [`scripts/data/world_data.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/data/world_data.gd).
- Static level and unit definitions live in [`scripts/game_defs.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/game_defs.gd).
- The project already supports:
  - night-only rules with no sky sun
  - six-row pool boards
  - per-cell terrain masks for mixed maps
  - conveyor, bowling, whack, and boss branches
- That means Fog should be added as a real fourth world, not as a branch of `night` or `pool`.

**Approach Options**

**1. Add a dedicated `fog` world after `pool`**

- Pros: mirrors original Adventure progression, keeps `4-x` numbering intact, lets world-select UI show Fog as its own destination, and keeps fog rules isolated from `night` and `pool`.
- Cons: requires touching world-key routing, world card data, and level-index assumptions.

**2. Fold Fog into the existing `pool` world as `3-19+`**

- Pros: fewer world-selection changes.
- Cons: breaks the original PvZ structure, muddies unlock logic, and makes Fog-specific UI, level names, and future Roof progression harder.

**3. Fold Fog into the existing `night` world as a late branch**

- Pros: night sky and mushroom logic already exist.
- Cons: wrong board topology, wrong numbering, wrong world identity, and more conditional hacks than a new world.

**Recommendation**

Choose option 1. Add a real `fog` world with IDs `4-1` through `4-10`.

## World Structure

**World identity**

- `world_key`: `fog`
- title: `浓雾后院`
- subtitle: `Adventure 4-1 ~ 4-10`
- visual language: moonlit backyard, teal-gray fog bands, colder pool reflections, lantern-like highlights around reveal plants

**Unlock position**

- Fog unlocks after clearing `3-18`.
- If Roof is not implemented yet, `4-10` becomes the current campaign endpoint.
- If Roof is later added, `4-10` should unlock `5-1` exactly like the original chain.

**Board rules**

- Base board is the classic backyard pool board:
  - 6 rows
  - middle 2 rows are water
  - no sky sun
  - normal seed selection except special stages
- Fog covers the right side of the lawn and advances in from the fence, with density based on level.
- Sea-shroom, Plantern, Blover, and Cactus are the key anti-fog and anti-air answers and must behave like their original roles first.

**Special-stage mapping**

- `4-1` to `4-4`: standard Fog stages
- `4-5`: `Vasebreaker` style interlude on the night backyard, not a fog battle
- `4-6` to `4-9`: standard Fog stages with the full new-zombie mix
- `4-10`: `Dark Stormy Night` style conveyor level with heavy lightning, intermittent full-screen reveals, and no normal BGM

## Original-Reference Level Plan

### `4-1`

- Terrain: `fog`
- Purpose: introduce the Fog world layout and visibility restriction
- Available key plants: all previously unlocked pool cards plus Sea-shroom
- Reward: `plantern`
- Zombies: old pool carry-over only, no new Fog-exclusive zombies yet
- Fog density: light, starts around the rightmost 3 columns

### `4-2`

- Terrain: `fog`
- Reward: `cactus`
- New zombie: `balloon_zombie`
- Fog density: light-to-medium
- Design note: first hard check that anti-air cannot be optional

### `4-3`

- Terrain: `fog`
- Reward: `blover`
- No new exclusive zombie yet; pressure comes from thicker fog and mixed pool lanes
- Fog density: medium
- Design note: this is where the game teaches the difference between persistent reveal (`plantern`) and emergency purge (`blover`)

### `4-4`

- Terrain: `fog`
- Reward: none; preserve the original taco/shop-beat rhythm instead of forcing a plant unlock
- New beat: Crazy Dave taco event hook
- Fog density: medium-high
- Compatibility hook: if this project ever adds upgrade-shop progression, this is where `gloom_shroom` and `cattail` availability should be toggled

### `4-5`

- Terrain: `vasebreaker_night`
- Mode: `vasebreaker`
- Reward: `split_pea`
- Must not render fog or pool water shimmer over vases
- Jack-in-the-Box interaction should be preserved inside vase logic because it is part of the original puzzle tension

### `4-6`

- Terrain: `fog`
- Reward: `starfruit`
- New zombie: `digger_zombie`
- Fog density: medium-high
- Design note: first true backline punishment stage

### `4-7`

- Terrain: `fog`
- Reward: `pumpkin`
- Mixed pressure: Balloon plus Digger plus returning pool threats
- Fog density: high
- Design note: Pumpkin becomes the stabilizer that lets the player keep expensive supports alive in the back columns

### `4-8`

- Terrain: `fog`
- Reward: `magnet_shroom`
- New zombie: `pogo_zombie`
- Fog density: high
- Design note: this is the first explicit "metal-control matters" stage of the world

### `4-9`

- Terrain: `fog`
- Reward: none
- New zombie: `jack_in_the_box_zombie`
- Fog density: very high
- Design note: the whole stage is built around uncertainty, lane recovery, and protecting expensive shells from blast wipes

### `4-10`

- Terrain: `storm_fog`
- Mode: `conveyor`
- Reward: none
- Format reference: original `Dark Stormy Night`
- Rules:
  - no normal seed selection
  - no normal background music
  - lightning flashes periodically reveal the whole board
  - thunder cadence acts as a visibility rhythm, not pure decoration
- Conveyor composition: strongest anti-fog answers plus emergency clears

## Fog-Specific Systems

**1. Fog mask**

- Add a real fog layer independent from terrain.
- Fog is not just one rectangle. It should be rendered as:
  - a soft global haze over hidden columns
  - drifting local bands moving left-right slowly
  - denser pockets that break up the view enough to matter but do not make the game unreadable
- Hidden rules:
  - player can still place plants only on visible cells or remembered cells under the cursor
  - zombies inside full fog are hidden until close enough, revealed by Plantern, blown away by Blover, or flashed by lightning in `4-10`

**2. Reveal logic**

- Plantern creates a persistent circular reveal radius centered on its tile.
- Multiple Planterns stack by union, not by intensity.
- Blover instantly clears all fog for a short global window, then the normal fog field reforms.
- Lightning in `4-10` temporarily reveals the entire board without permanently clearing fog.

**3. Stage density curve**

- `4-1`: rightmost 3 columns hidden
- `4-2`: 3.5 columns hidden
- `4-3`: 4 columns hidden
- `4-4`: 4.5 columns hidden
- `4-6`: 5 columns hidden
- `4-7`: 5.5 columns hidden
- `4-8`: 6 columns hidden
- `4-9`: 6 columns hidden with denser drift
- `4-10`: nearly full heavy storm fog with periodic global reveal

This matches the original feel without requiring pixel-identical fog masks.

## Plant Roster Design

The user required every plant to have:

- its own visual model
- its own animation set
- its own plant-food super

The baseline behavior stays faithful to original PvZ. Plant-food supers are layered on top.

### Sea-shroom

- Original role: 0-cost, water-only, short-range mushroom shooter
- Project implementation:
  - only placeable on water
  - low damage, fast cadence, hard range clamp
  - bioluminescent spores so it remains readable under fog
- Animation:
  - cap pulse
  - short inhale before each shot
  - soft glow ripple while idle
- Plant food:
  - rapid bioluminescent burst in a short forward cone, saturating nearby water lanes

### Plantern

- Original role: stationary fog revealer
- Project implementation:
  - persistent reveal radius
  - no offensive attack
- Animation:
  - lantern-core flicker
  - leaf sway
  - soft volumetric halo
- Plant food:
  - full-board reveal for a short duration, plus a weak reveal mark on hidden and underground targets

### Cactus

- Original role: ground shooter that extends upward to hit Balloon Zombies
- Project implementation:
  - standard pea-like lane attack on ground targets
  - enters tall attack pose when targeting air
  - instantly pops balloons on hit
- Animation:
  - squat form
  - stretch-up anti-air form
  - spine recoil on fire
- Plant food:
  - multishot piercing spike barrage across the lane, auto-targeting all airborne units first

### Blover

- Original role: single-use fog purge and balloon removal
- Project implementation:
  - instant plant
  - clears current fog globally
  - removes all Balloon Zombies on screen
- Animation:
  - inflate
  - explosive petal burst
  - sweeping gust ring
- Plant food:
  - stronger hurricane that also pushes back non-heavy zombies and leaves the board fully revealed briefly

### Split Pea

- Original role: shoots forward and backward
- Project implementation:
  - front head attacks targets ahead
  - rear head attacks targets behind
  - prioritization stays directionally strict
- Animation:
  - independent head tracking
  - alternating recoil
  - back head more anxious, faster snapping
- Plant food:
  - both heads enter a short gatling state, saturating forward and backward lanes simultaneously

### Starfruit

- Original role: fires stars in five directions
- Project implementation:
  - keeps original five-line firing identity
  - stars travel in fixed star lanes, not homing curves
- Animation:
  - rotating fruit core
  - pulse before multi-shot
  - sparkling impact on hit
- Plant food:
  - dense star storm with a faster fire interval and brighter lane tracers

### Pumpkin

- Original role: protective shell that sits on top of another plant
- Project implementation:
  - overlay support plant
  - preserves original "armor shell for any occupied tile" role
  - damaged visual states must be very legible
- Animation:
  - wobble on hit
  - stitched mouth/eye idle squash
  - cracked-shell breakup stages
- Plant food:
  - instant shell heal plus a temporary thicker barrier pulse to nearby Pumpkins

### Magnet-shroom

- Original role: removes metal equipment
- Project implementation:
  - works as a periodic metal-strip utility, not direct DPS
  - must strip:
    - bucket
    - screen door
    - pogo stick
    - jack-in-the-box
    - miner pickaxe
    - any project-specific metal gear compatible with the system
- Animation:
  - charge hum
  - suction ripple
  - pulled-metal orbit arc
- Plant food:
  - full-board magnetic pulse that strips all eligible metal and briefly stuns affected zombies

## Zombie Roster Design

Fog uses original carry-over zombies plus these new introductions. Existing pool swimmers remain part of the world because the map is still the backyard pool.

### Balloon Zombie

- Reference behavior: floats over plants and ignores ground blockers until popped; weak to Cactus and Blover
- Project implementation:
  - lane-bound air path above normal collision
  - ignores ground plants while floating
  - once popped, drops to normal zombie behavior
- Animation:
  - high bobbing drift
  - string tension swing
  - pop-to-fall transition with a visible descent arc

### Digger Zombie

- Reference behavior: tunnels underground and appears on the left side of the lawn; weak to Split Pea and Magnet-shroom
- Project implementation:
  - enters from the right edge
  - underground phase ignores front defenses
  - surfaces near the backline and attacks from behind
  - if Magnet-shroom steals the pickaxe while underground, he surfaces and converts to a normal forward-walking zombie
- Animation:
  - dirt trail and tremor markers while underground
  - surfacing burst from the soil
  - confused pause when disarmed by Magnet-shroom

### Pogo Zombie

- Reference behavior: repeatedly hops over plants until blocked by Tall-nut or disarmed by Magnet-shroom
- Project implementation:
  - can vault multiple plants, not just one
  - Tall-nut is the hard stop
  - Magnet-shroom removes pogo stick and converts him into a normal medium zombie
- Animation:
  - compressed pre-hop crouch
  - tall airborne arc
  - pogo spring oscillation and landing squash

### Jack-in-the-Box Zombie

- Reference behavior: fast zombie with a 3x3 self-destructing jack-in-the-box; weak to Magnet-shroom
- Project implementation:
  - fast movement
  - looping jingle cue while armed
  - random but bounded detonation timer
  - 3x3 blast that destroys plants and self
  - Magnet-shroom removes the box cleanly and cancels the explosion behavior
- Animation:
  - manic jitter walk
  - box crank loop
  - surprise-open pre-blast pose
  - purple blast bloom on detonation

## Map And UI Direction

**World card**

- Add a fourth card to [`scripts/data/world_data.gd`](/Users/hecrereed/project/pvz/pvz-godot/scripts/data/world_data.gd):
  - `key`: `fog`
  - title: `浓雾后院`
  - subtitle: `Adventure 4-1 ~ 4-10`
  - preview plants: `sea_shroom`, `plantern`, `cactus`, `starfruit`, `magnet_shroom`
- Palette:
  - accent: desaturated cyan-teal
  - dark accent: blue-gray
  - panel: moonlit stone and mist white

**World map**

- Node chain is mostly linear left-to-right.
- `4-5` should be visually distinct like other minigame nodes.
- `4-10` should have a storm/boss-like node treatment even though it is not a boss fight.

**Battlefield look**

- Night backyard palette, but not identical to current `night`.
- Pool water is darker than `pool` world and reflects lightning in `4-10`.
- Fog should visibly sit above the lawn grid and below the HUD.
- Plantern halos must read through the fog mask immediately.

## Compatibility Hooks For This Project

These are not optional if the world is going to feel correct inside this repository.

- `_world_key_for_level()` must stop assuming only `1-`, `2-`, and `3-`.
- World-select card count, scroll behavior, and map-start routing must support `fog`.
- Selection pools must treat Fog as a standard persistent-plant world, except `4-5` and `4-10`.
- Existing pool swimmers and water lane rules must carry into Fog.
- Night-only sky-sun suppression should be generalized to "non-day worlds that disable sky sun", not just `night`.

## Verification Targets

- `fog` appears as a separate world card and unlocks after `3-18`
- `4-1` through `4-10` exist in order
- `4-5` is a Vasebreaker level with no fog battle overlay
- `4-10` is a storm conveyor level with lightning-driven reveal windows
- Sea-shroom is available at Fog entry without being a Fog reward
- Plantern reveal radius, Blover global purge, and Cactus balloon pop all match role expectations
- Digger, Pogo, Jack-in-the-Box, and Balloon zombies all preserve their original counterplay
- every new plant and zombie has unique draw logic, motion beats, and plant-food or special VFX

## Sources

- Fog world overview and level sequence: https://plantsvszombies.fandom.com/wiki/Fog
- Sea-shroom unlock timing and original role: https://plantsvszombies.fandom.com/wiki/Sea-shroom_(PvZ)
- Plantern original reveal role: https://plantsvszombies.fandom.com/wiki/Plantern_(PvZ)
- Cactus anti-balloon role: https://plantsvszombies.fandom.com/wiki/Cactus_(PvZ)
- Blover fog clear and balloon removal: https://plantsvszombies.fandom.com/wiki/Blover_(PvZ)
- Split Pea unlock timing and directionality: https://plantsvszombies.fandom.com/wiki/Split_Pea_(PvZ)
- Starfruit unlock timing and five-direction fire: https://plantsvszombies.fandom.com/wiki/Starfruit_(PvZ)
- Pumpkin shell role: https://plantsvszombies.fandom.com/wiki/Pumpkin_(PvZ)
- Magnet-shroom unlock timing and metal-strip role: https://plantsvszombies.fandom.com/wiki/Magnet-shroom_(PvZ)
- Balloon Zombie, Digger Zombie, Pogo Zombie, Jack-in-the-Box Zombie behaviors:
  - https://plantsvszombies.fandom.com/wiki/Balloon_Zombie_(PvZ)
  - https://plantsvszombies.fandom.com/wiki/Digger_Zombie_(PvZ)
  - https://plantsvszombies.fandom.com/wiki/Pogo_Zombie
  - https://plantsvszombies.fandom.com/wiki/Jack-in-the-Box_Zombie
