# Plant fusion Implementation Plan

**Goal:** Give all 146 selectable plants reasonable fusion recipes, further evolutions, distinct SVG anatomy, combat effects and click/food ultimates, then publish v1.0.158.

**Architecture:** A symmetric finite recipe catalogue generates fusion-only definitions from reviewed native species and traits. Existing species are reused for canonical upgrades. Fusion plants retain a native behavior identity for terrain and passive interactions, plus a catalogue identity for their new model, stats and dedicated runtime. Seed-on-plant fusion uses normal costs/cooldowns; a two-click fusion tool combines two planted specimens atomically. Campaign unlocks and special puzzle rules remain authoritative.

**Tech Stack:** Godot 4.6 / GDScript, authored SVG geometry, Python asset builder, GitHub Actions four-platform exports.

## Design

- Every selectable native has a self-fusion and an additional feeding evolution. Pea + pea = existing repeater, repeater + repeater = gatling; sunflower + sunflower = twin sunflower. Further recipes have bounded ingredients and no cycles.
- Cross recipes express complementary functions: sunlight shooters, frost/fire blades, shielded cannons, magnetic artillery, healer defenses, mushroom control and sky/water supports. They receive named advanced recipes.
- Preserve coffee wake, pumpkin/holy shield and support installation when they are the intended ordinary operation. Other defined grafts take precedence over occupied-cell rejection. Bad terrain, graves, hazards, insufficient sun and cooldown reject without consuming anything.
- Combine two planted specimens with a visible fusion tool. Preview result and recipe before confirmation click; failed/cancelled selection preserves both plants. Keep damage fraction, outer armor, statuses and used resurrection/ultimate cooldown to avoid free heals or reset exploits.
- Support fusions stay support-layer plants; roof/water/lava requirements and attachments survive. Offensive fusions use the existing projectile/collision helpers and enemy filtering, including independent zombie headgear.
- New SVGs have changed silhouettes, multiple heads, barrels, flower crowns, mushroom caps, armor and ingredient ornaments. Animation uses native plant motion plus moving fusion halos, muzzle pulses and trait-specific effects.
- Almanac lists available fusion recipes separately from selectable original seeds; shows ingredients, follow-ups, abilities, costs and named ultimates. Existing save data remains readable.

## Tasks

1. Write failing canonical, catalogue coverage and real placement regression tests. Confirm intended red failures.
2. Add `scripts/data/fusion_plant_defs.gd`, compose definitions in `scripts/game_defs.gd`, and write `scripts/runtime/plant_fusion_runtime.gd`.
3. Wire atomic placement, planted-specimen merge tool, support-layer handling, preview and new battle/almanac entry points in `scripts/game.gd` and plant/food runtimes.
4. Author `scripts/tools/build_fusion_plant_art.py`, distinct imported SVGs and `scripts/ui/plant_fusion_visuals.gd` for fusion/attack/ultimate animations.
5. Verify all recipe nodes spawn and act; test resources, charm/terrain/hazards, conservation, enemy filtering, piercing armor, recursive merges, supports and ultimates.
6. Capture native SVG catalogue and desktop/mobile battles. Inspect silhouettes, firing direction, overlay/hit area, tool placement and previews.
7. Run relevant and broad regression scripts, update versions/readme/release notes, commit, tag, push, verify four release assets and Pages deployment.

## Validation

`godot --headless --path . --script tests/plant_fusion_test.gd`

`python3 tests/plant_fusion_art_test.py`

Run combat, plant food, terrain, progression, UI, save and release checks with bounded script timeouts; inspect logs for script errors even when exit code is zero. Native captures must not mutate render state or RNG.

User authorizes independent creative design, implementation and release publication. Execute locally, preserving unrelated untracked imports; no delegation or additional approval step.

## Completion notes

- Final catalogue: 146 native seeds, 362 new definitions and 364 symmetric recipes; every native has a self route and a feeding route.
- Added an atomic two-seed preparation gesture to make instant/attachment seeds reachable without a timing exploit. Sun levels charge both inputs on planting; conveyors consume two actual cards.
- Preserved native seed pools and terrain bases; added ally-safe projectile status/impact hooks and Prismriver body targeting.
- Artwork: 362 imported SVGs with botanical anatomy and source motifs, moving effects and named click/food ultimates.
