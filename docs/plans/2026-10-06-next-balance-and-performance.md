# Next balance, fusion and performance implementation plan

**Goal:** Relative to v1.0.178, increase all Touhou Boss damage by 150% (×2.5), halve damage received during formal cards (87.5% total resistance), label additional cards simply as spells, improve fusion/twin abilities and reduce package/memory/dense-bullet costs. Commit and push the feature branch without a tag or Release.

**Architecture:** Keep the established explicit Boss source pipeline and card identity; change the source multiplier 2→5 relative to immutable v177 probes and formal incoming factor .25→.125. Retain internal original IDs/origin while changing only user-visible wording. Profile export contents/cache and dense collision/render work before optimizing. Repair shooter signature ultimates and same-plant fusion using actual native damage/output and visuals.

**Tech stack:** Godot4.6/GDScript, paired native mechanics tests, deterministic performance probes, local export/PCK inventory and native captures.

## Tasks

1. Update baseline-relative damage/resistance/display contracts; observe valid RED, then source/UI/data changes, GREEN actual HP+armor/card-scope/HUD tests.
2. Audit all user-facing original spell labels in definitions, declarations, HUD, selection and catalogue; use neutral spell labels without altering origin, IDs, canonical titles or phase order.
3. Measure package contents, dynamic resource dependencies and texture/audio/cache memory; safely remove unnecessary export payload and cache retention, checking local exported dynamic assets and playback.
4. Measure worst-case dense projectile/swept-collision cost and allocations; optimize hotspots with identical collision order, warning, reflection, beam, viewport and simulation semantics.
5. Reproduce weak/empty shooter-fusion ultimates and indistinct same-plant twins; fix actual initial action/sustained weapon/infusion and role-appropriate output/defense/support/visuals with representative native comparisons and catalogue-wide checks.
6. Run affected meaningful regressions, inspect native visuals and quantitative before/after results, update unreleased documentation, review final diff. Commit/push codex/touhou-boss-next-balance. Keep released main/tag/Pages untouched; no Release or version tag.

## Implemented behavior

- All 34 Touhou damage sources: v178 ×2.5, immutable v177 ×5. Active formal incoming damage factor .125, including fusion weapons and ash; native endurance invulnerability remains separate. Display wording changes preserve internal card IDs and origin metadata.
- Fusion clicks activate real native weapons immediately and retain source-specific states and partner ammunition. Mono-material cadence, durability, support and planting fuses use scoped metadata; resource-only plants retain their existing multiplied sun value without also multiplying cadence. Regenerated 296 same-material SVG models show repeated organs. Original collectible plants expose twin benefits through the existing catalogue followups.
- Projectile queries synchronize scalar target signatures on every query, retaining live movement, spawns, concealment, flight and multi-body bosses. Both ordinary and special lotus queries exclude fresh corpses while retaining timed survival exceptions. Danmaku collision candidates preserve native order, swept distance, reflection, warning and fixed-step simulation.
- Export filters exclude output/tmp/docs/tests/tools/source sheets. Source sheets already had no payload in the baseline PCK; no savings are attributed to them. Startup prewarms its logo; battle pins current encounter frames/music, while map and catalogue pin visible previews. Unpinned working sets are bounded and both shared/instance references are cleared together.

## Measured evidence

Measurements use Godot 4.6 on the same local machine. Raw logs, before/after JSON, native desktop/short-screen captures and export inventories are saved locally under ignored `output/touhou-next-balance/`.

| Measurement | Before | After |
| --- | ---: | ---: |
| Local Windows PCK | 676.69 MiB | 595.02 MiB |
| Native startup texture memory | 935.96 MB | 76.53 MB |
| Four battles → catalogue → home texture memory | 958.52 MB | 245.89 MB |
| Same scenario RSS peak | 1.989 GB | 1.226 GB |
| 480 cross-board Touhou bullets, desktop CPU mean | 40.85 ms | 5.84 ms |
| 480 real plant contacts, desktop CPU mean | 68.80 ms | 30.53 ms |

The local PCK reduction is 81.67 MiB / 12.07%, including the new twin art. Local tmp files may not exist in GitHub CI exports, so that percentage is not a future Release guarantee. Fixed CPU probes retain 480 bullets/contacts, literal damage 1, identical high-HP enemies and visual counts; they are not total rendered FPS. A separate real 20-fusion-ultimate workload reaches 917 native projectiles with natural enemy deaths retained and projectile-update mean/p95 17.66/22.44 ms; it is not a paired benchmark.

Representative native twin output over 24 seconds: cactus 320→720, starfruit 260→546, melon 640→1397, electric bonk 2959→5380. Cactus clicked native ultimate over 3 seconds rises from the old twin's 550 to 4038; single cactus is 1200. Wallnut twin HP becomes 7400 vs single 4000. Native sunflower remains 50→100 sun over the measured period. Costs, material cooldowns and actual ultimate charge remain enforced.

## Verification

- Valid failing contracts observed before implementation for attack strength, formal resistance, visible spell labels, fusion output, same-material roles, cache bounds, visible-map pins and same-frame lotus corpse exclusion. Selectable collected-seed catalogue entries also verify the visible twin benefit.
- Exact semantics probes compare 10,094 live native projectile queries and 9,000 swept collision cases plus mixed shapes and beams. Native fusion/Boss paired damage still obeys .125 formal incoming damage.
- Final integration covers 68 affected Godot suites, two additional dense-projectile performance/semantics gates and five Python repository checks. The strengthened Nitori jet fixture has enough HP to test cleansing independently of lethal damage; explicit player-stop/settle cleanup avoids MP3 mixer handles outliving tests.
- Independent-directory PCK runtime checks load 12,764 dynamic textures, compare 1,855 decoded image hashes/dimensions/formats, exercise 816 Boss poses and actually play 60 original MP3 streams with exact compressed-byte equality. Native desktop 1600×900 and short landscape 844×390 fusion visuals inspected.
- Release versions remain 1.0.178. Only the feature branch is pushed; the existing main/tag workflow is not triggered.
