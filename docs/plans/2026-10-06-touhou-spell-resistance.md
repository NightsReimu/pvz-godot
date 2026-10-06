# Touhou damage and spell resistance implementation plan

**Goal:** Double every Touhou Boss attack's actual plant damage relative to v1.0.177 and grant 75% damage reduction while any formal spell card is active.

**Architecture:** Apply a source-scoped 2.0 outgoing multiplier through the existing attack damage pipeline and explicitly attributed bespoke attacks. Add a pure active-card resistance predicate in TouhouPhaseRuntime and apply it once in Game's incoming damage entry. Route legacy direct body damage and execution abilities against Touhou Bosses through the same entry while preserving ordinary-unit behavior. Read that predicate for a visible HUD status.

**Tech stack:** Godot 4.6, GDScript, real cast/collision/HP-and-armor probes, native phase and campaign flow tests, four-platform Release workflow.

## 1. Capture v177 and prove missing behavior

- Preserve current Nitori stage/characters/assets and unrelated untracked files.
- Record true HP+armor removal for bullets, beams and explicit direct attacks, with ordinary zombie/environment controls.
- Add tests/touhou_attack_strength_test.gd and tests/touhou_spell_resistance_test.gd, run valid assertion RED before production edits.

## 2. Attribute and double Boss attacks

- Edit scripts/data/touhou_difficulty_defs.gd with source-only outgoing multipliers; cover the complete 34-character catalogue, including Tewi.
- Update bespoke runtimes and game.gd explicit charm, summon, drain, bite and Patchouli active hazard sources. Preserve warning lengths, per-pattern geometry, support ordinary enemies, terrain damage and old difficulty composition; apply the new source multiplier exactly once.

## 3. Formal spell resistance and incoming routing

- Add TouhouPhaseRuntime.spell_damage_factor(boss): active real formal card ->0.25; nonspell, absent/expired card, ordinary enemy and completed/dead states ->1.0. Keep existing survival invulnerability.
- Apply before body/equipment damage in Game._apply_zombie_damage, including armor bypass flags, reflected attacks and fusion ultimates.
- Audit legacy direct HP and execution writes in game.gd and plant_food_runtime.gd. Preserve exact ordinary enemy behavior; Bosses must honor formal-card resistance, invulnerability and mandatory phase gates.
- Show 75% reduction in active formal-card HUD state; survive/idle/nonspell labels retain their proper meaning.

## 4. Verify and publish v1.0.178

- Green the new paired attack/incoming source tests, actual card catalogue and role/difficulty matrix, existing phase/survival/cleanup/custom Boss/ash/fusion/mower regressions, native desktop/mobile UI captures and independent review.
- Use legal actual strong fusion formations for sustained route probes; retain genuine strategy failures and diagnose them without reducing the user-requested 2.0 multiplier or manufacturing resources.
- Update version, README and release notes, verify the staged scope, commit/tag/push. Verify four error-free version-stamped builds, public Release assets/notes/latest tag and the deployed PCK's actual new version and changed modules.

## Verified evidence

- v177 baseline: 54 actual attack HP/armor paths, 864 source-factor checks, plus 42 untuned direct-hit cases and actual enemy-owned contact. Every eligible source gains exactly ×2; ordinary units, ally attacks and environment controls retain their values.
- New incoming regression: 306 role/tier bodies, 1763 declared formal cards, 964 real nonspells and 20 paired native incoming sources. Independent inventory: 102 level variants, 206 role instances, 34 characters, 1592 attacks; card metadata/order/HP remain exactly v177.
- All 50 affected regression entries pass. Legacy expected damage contracts now include the explicit global ×2; old immutable firing snapshots retain their original count/cadence metadata.
- Desktop/mobile native screenshots show the active 75% status, with unchanged nonspell labels. Final editor, README, Android preset and whitespace checks pass.
- Three unchanged-policy Easy routes complete with native resources, campaign fusions and earned ultimates: 4-19 643.75s (0 lost plants / 0 mowers), 4-20 726.10s (0 / 0), 4-21 766.50s (9 / 0). Highest-tier strategy probes retain genuine failures rather than weaken production or manufacture resources.
