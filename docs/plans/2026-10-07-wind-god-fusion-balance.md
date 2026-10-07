# Wind God Fusion Balance Implementation Plan

**Goal:** Reduce the six Wind God Bosses’ additional outgoing damage from2.5× to1.5× and assess their actual encounters with native fusion armies. Carry the preceding authorized release workflow forward to a patch version after verification.

**Architecture:** Change only the independent Wind God source coefficient first. Keep global source5, all formal protection, density, warnings, canonical cards and role health. Use a reusable native four-stage/four-tier fusion combat runner with balanced, ash-heavy and support/defensive formations. Additional gameplay tuning is conditional on reproducible outcomes and meaningful counterplay, not on the survival of inflated single plants.

**Tech Stack:** Godot4.6, GDScript native combat/phase/input simulation, Python paired results, GitHub CLI release.

## Tasks

1. Inspect existing four Wind God stage data, damage propagation and balance tests. Preserve the original eight unrelated untracked files. Branch `codex/wind-god-fusion-balance`.
2. Update expected Wind God native source factor in `tests/touhou_attack_strength_test.gd` to7.5 while archived v177 evidence stays immutable; observe the valid damage regression RED on2.5 production. Other Bosses retain5 and ordinary sources1.
3. Create `tests/wind_god_fusion_balance_test.gd` and its reusable native runner. Prepared main/support crops must be actual `Fusion.result` units from legal stage card pools, with original health, armor, damage, cadence and charge. Water-only lily foundations are terrain, not defensive balance targets. Prefer12–24 hybrids reachable at plausible material cost; do not fill54 cells with gratuitous endgame hybrids. Define at least balanced, ash-heavy and defensive/support cohorts.
4. First save2.5 runs with loaded coefficient and production hashes. Use real complete Boss phase gates, real support spawning/mowers, real earned ultimate activation, native player/enemy attacks. No forced Boss damage, phase changes, regeneration, inflated plant HP, blocked loss or disabled enemy spawning. Record deaths, plants/lane/mower losses, clear time, card progression, bullet/plant/ordinary reinforcement damage, paid/belt repairs and seed. A prepared-army result is not an empty-board full campaign proof.
5. Change `WIND_GOD_DAMAGE` to1.5 only, then repeat identical scenarios with exact same seed/formation/policy. Run Easy/Normal/Hard/Lunatic across4-19–4-22; root can run individual stage/tier/style CLI cases. Material corrections fix misleading test formations first. Actual gameplay changes require causal evidence, e.g. unavoidable simultaneous fields/reinforcements or missing practical counterplay.
6. Inspect variation between offensive/ash/support armies and formal cards. Preserve weaknesses between lineup types; do not make every strategy win every tier or impose arbitrary universal victory assertions. Add focused regressions for any real production adjustments.
7. Run affected source/protection/phase/fusion/projectile/field tests and native visual smoke. Keep explanatory output and actual logs, no claims of optimal play, full defensive playthrough or universal60FPS. Update current README/version/release notes with verified findings, leaving v179 historical notes intact.
8. Commit intended files, fast-forward/push main and new unused patch tag; wait for successful Windows/macOS/Web/Android artifacts and publish metadata before reporting release complete.

## Verified implementation and balance evidence

The only gameplay change is `WIND_GOD_DAMAGE: 2.5 -> 1.5`. Combined with the existing global factor5, Wind God Boss and owned-source damage is7.5 instead of12.5; other Touhou sources remain5 and ordinary sources1. Formal protection remains0.125 received damage. Density, cadence, roles/HP, movement, spells and reinforcement behavior are unchanged.

The previous balance fixtures mostly used single plants. The new diagnostic uses18 real hybrids (20 with forward wall/plantern reveal in4-21/22), native catalog stats and initial zero charge. All combat/support bodies are fusion units; water lilies are terrain foundations. The prepared finale snapshot explicitly skips the road and records its36/40-material ledger. It is not evidence that the random conveyor typically delivers that exact formation by300s. Actual repairs use native fusion input, real held ingredients or price/cooldown. The fixed ten-slot belt is counted by occupied entries, and successful fusion consumption must remove exactly two materials.

Four stages × four difficulties × three styles (balanced/ash/defensive), seed180906,450 simulated seconds per case, identical controller bytes:

| Extra source factor | Wins | Losses | Still playing at450s |
| --- | ---: | ---: | ---: |
| 2.5 | 0 | 44 | 4 |
| 1.5 | 2 | 32 | 14 |

Both48-case runs exited0 with zero runtime diagnostics and zero native-stat/resource violations. After1.5,4-20 Easy balanced/ash cleared at399.7/438.7s. Extending4-19 Easy balanced explicitly to900s produced a real win at510.6s (all5 phases,44 naturally earned ultimates). A timeout is not a loss. Earlier v1 samples with an incorrect ten-slot replacement policy are excluded from these comparisons.

An additional20-body fortified4-22 formation uses native wall/healing, melon/wall, repeater/wall and forward wall/plantern hybrids. At450s on Normal,2.5 reached phase4/8 with24 fusion losses, while1.5 reached6/8 with one fusion loss. Hard still lost:161.75s at1/9 before,218.9s at3/9 after. These results show improved survivability without requiring every lineup or tier to win.

The separate full-route controller starts from the actual level opening, available cards, mowers and terrain, with no prepared combat army, forced phase damage, injected charge, sun or HP. It grows an adaptive fusion army using native two-material inputs and naturally earned pad blooms. Same controller, same seeds,1200s cap:

| 4-22 full route | Extra2.5 | Extra1.5 |
| --- | --- | --- |
| Easy seed905 | Still playing at1200s | Won786.25s |
| Easy seed1777 | Won1021.75s | Won913.95s |
| Normal seed905 | Still playing at1200s | Won1125.50s |
| Normal seed1777 | Won1050.05s | Won990.25s |

All eight paired routes have zero material-input violations. The original before probe reported two teardown resource warnings; its paired combat results are retained, not described as warning-free. The permanent controller fixes observation/teardown and reproduces the after Easy1777 placement, damage, ultimate and material counters exactly. Further1.5 routes atseed1777 won4-19 E/N at597.15/721.60s,4-20 E/N at482.20/867.75s and4-21 E at969.30s.4-21 N lost at1092.15s in its final7/7 phase when a ninja breached, with1449.77 BossHP left; another seed905 genuinely won at906.05s, complete=true/HP0. These permanent eight samples had seven wins and one loss, zero input violations and zero runtime diagnostics. They show strategy/seed variation, not evidence of an impossible encounter or a reason to weaken every boss.

No new collision fix is justified: Aya's fast row/column movement creates deliberate evasion windows, but stationary warning windows remain hittable and full native fusion routes clear. No further production nerf was added.

## Reproduce and verification scope

Use Godot4.6 and the following development-only entry points:

```sh
godot --headless --path . --script res://tests/wind_god_fusion_balance_test.gd
godot --headless --path . --script res://tests/wind_god_fusion_route_test.gd
godot --headless --path . --script res://tests/wind_god_fusion_balance_test.gd -- --run --variant after --stage all --tier all --style all --seed 180906 --cap 450 --wall-seconds 90
godot --headless --path . --script res://tests/wind_god_fusion_route_test.gd -- --run --stage 4-22 --tier normal --seed 1777 --cap 1200
```

Historical comparisons must run a separate v179 production checkout with the same controller, rather than change a multiplier at runtime; the requested before/after variant verifies the genuinely preloaded coefficient. Detailed per-case JSON is written under ignored `output/`.

The paired48-case controller hashes were tool `99b1cc5c374365ebdea212c891de51b23c8f600b45b25c9dd4326792f52e3afd`, test `7b897ae6c3bd371a0a874a65ae8fa3a44c70bae20d0c20edf8e63406182cc0b0`. Final optional fortified support has tool `775883535d76e0fedd4c1107624cdc9023f236399a64e829cc638f136db519be`, test `b10f7505ad233a829c5335c206ee24b21c3dcbdf63dcaefaf0837b155f1eed1a`; default three cohorts retain the same policy. Full-route paired controller `45290ef91f5277957ae99d6e6532ac27c231eb7c1b7b0d26721ea780049b2207`; permanent generic-stage observer/controller before final audit hardening `50031874e1a01f84616e30b8c3090ac6aa3c5b00b214cc4a8c76aed11ec3ec48`. The11 production combat-source hashes in every manifest differ only in Difficulty: before `14df1c7d1ab02faf2a9487791e2cfaff200cb1fa096d659aa106597bc82377a6`, after `b65e2137550ccada9045460455c27fa6abc5f805971327b29db34887a127b7c3`.

The source-strength expected7.5 regression first failed on unchanged2.5 production with159 actual damage failures, then passed after the constant change. Twelve affected existing native regressions passed: source strength, formal protection, Tengu level/mechanics/flow, Aki/Hina/Nitori flow, fusion activation/twins/native inheritance and projectile/dense semantics. Both new default tests pass, including true two-card consumption, no hidden stat buffs, earned pad blooms, actual Lunatic bank costs and cooldowns. README, export-resource policy, release workflow and Android preset checks also pass. Mathematical isolated damage targets are unit checks, not single-plant balance evidence. These samples do not prove optimal human play, universal victory or performance at arbitrary bullet counts.

Final read-only review found no production blocker. It identified a development guard gap: the full-route run loop only checked fusion identity, while catalogue audits were called by its default test. The final controller now records catalogue and native offensive-enhancement audits during each placement cycle and at exit, with deliberate one-point/multiplier mutations rejected by the default test. This does not alter the adaptive play policy. Final full-route tool SHA256 `c84e192719a7e67e5e1808b9329b647ce07c25e2c74f4228f6b622e20139c13a`, test `6c3b9c3194389a710c76e88962ec1b7ee7794149e4bb57e6340faff03153d390`.

After this guard hardening, the default native test passed with zero diagnostics. A fresh full4-22 Easy seed1777 route won at913.95s with zero live audit violations and reproduced every recorded victory, phase, material, placement, damage and ultimate counter from the frozen prior sample.
