# Unit Identity Restoration

## Design

The user rejected commit `7d8b920`: substring-based bodies and hash-derived colors
made distinct units look interchangeable and bypassed the Touhou image pipeline.
Keep each existing vector illustration's silhouette, equipment, face, palette,
and gameplay-dependent state. Adapt its individual solid shapes to the volcano
units' ink outlines and layered shading. Do not replace Touhou images or edit
their animations, resources, abilities, or dedicated drawing functions.

Card icons, almanac portraits, enhancement portraits, planting previews, and
battle units must select the same species-specific drawing routine. Retain the
recent mobile layout fixes and scale health/armor displays with their units.
Remove the universal decorative rings that obscure distinguishing details.

## Implementation Plan

**Goal:** Restore recognizable unit identities while combining the original art
with the volcano expansion's geometric rendering finish.

**Architecture:** Reuse the dedicated plant and zombie renderers. Consolidate
plant state argument handling into one entry point. Apply bounded ink and light
primitives to ordinary vector art; Touhou renderers remain an untouched path.

**Tech Stack:** Godot 4, GDScript, CanvasItem drawing, existing PNG animation frames.

1. Capture plant/zombie contact sheets before changes, without loading or saving
   player progress (`scripts/tools/capture_unit_identity.gd`).
2. Remove the generic early returns and hash-based bodies in `scripts/game.gd`.
   Restore per-species rendering, stateful bodies, support plants, pumpkin armor,
   and Touhou frame loading. Reuse the plant body entry point in every portrait.
3. Add geometric ink/shading helpers to the individual ordinary unit shapes.
   Preserve accessories and native colors; use effect-specific visual feedback.
4. Add `tests/unit_identity_test.gd` to verify renderer coverage, state routing,
   alpha/scale propagation, and all Touhou bosses using their own images.
5. Inspect contact sheets, animated states, battle and compact UI captures.
   Run relevant existing tests, Godot import, and `git diff --check`.
6. Verify no art assets changed, commit with the existing NightsReimu identity,
   and push to `NightsReimu/pvz-godot`.

## Verification

- All 145 plants and 107 zombies rendered through their actual portrait paths.
- All 18 Touhou bosses reached their own existing image frames. Their dedicated
  draw functions match the parent of `7d8b920`; no art or gameplay files changed.
- Display-rendered tests distinguish 12 pairs by silhouette, 7 gameplay states by
  pixels, and 3 active attack poses.
- Seventeen focused regression scripts passed without engine or script errors.
- Contact sheets cover the complete roster. UI captures cover five viewport
  sizes; mixed battles cover four sizes, including five/six-row boards.
- Visual checks also exposed and fixed portrait accessory defaults, the tall-nut
  cap, mobile planting-preview scale, boss footer overlap, and a narrow-screen
  self-intersection in the daytime hill polygon.
