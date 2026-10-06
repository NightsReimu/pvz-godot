# Conveyor pacing and Touhou finale balance implementation plan

**Goal:** Reduce the overly generous conveyor supply and make Touhou finales offer more distinct spell encounters against fusion formations.

**Architecture:** Keep delivery cadence in the authored level data. A full seed bank pauses its delivery clock instead of replacing it with a short polling interval. Finale-only spell extensions and health tuning use the shared Touhou phase system; road incarnations retain their weak role and original identities.

**Tech stack:** Godot 4.6 / GDScript, native headless combat simulations, four-platform GitHub release workflow.

## 1. Reproduce and adjust belt supply

- `tests/conveyor_pacing_test.gd` measures actual deliveries for 4-19/4-20 E/N/H and full-bank behavior for conveyor/bowling. Run before the fix and confirm excessive delivery rates and full-bank clock loss.
- In `scripts/data/level_defs_autumn.gd` and `scripts/data/level_defs_hina.gd`, change the authored delivery range to 2.8–4.0 seconds. Keep the three opening cards and initial delivery.
- In `scripts/game.gd::_update_conveyor`, animate/synchronize the belt, then return while full before consuming delivery time. Ordinary levels keep their 4.6–6.8 second cadence.

## 2. Extend and strengthen finales

- Inventory every Touhou stage/tier before choosing targets. Add clearly labeled character-themed originals with genuinely different attack patterns, retaining canonical card order and final-card treatment.
- Tune finale health for fusion formations while leaving road health multipliers intact. Check role scaling happens once and declared phases cannot be skipped by burst damage.
- Final decision: finale multiplier 1.45 → 1.95; add two distinct originals to every complete role and a third for the shortest lists. Keep original finishing/rebirth segments last. Roads retain their previous HP and authored cards.
- Verify original patterns execute and draw through actual runtime; check telegraphs, cleanup and valid character poses.

## 2a. Sustain the new finale enemy waves

- `tests/touhou_finale_reinforcement_test.gd` exercises actual road/finale spawns in 4-19, 4-20 and 8-6 for all four difficulties, verifies road support stays unchanged, checks multi-lane batch creation and verifies the cap cannot be overshot.
- In `scripts/game.gd`, pass the actual boss instance to the support dispatcher. Only complete Hina, Minoriko and Suika receive the new policy: first arrivals after 1.8 seconds; 2 enemies per batch on E/N, 3 on H/L; a 6.4–4.4 second phase-dependent interval multiplied by the existing difficulty cadence. Reserve queued wave arrivals in the 42-unit cap.
- Include both kedama and fairy families in every Hina batch; late batches also use their armored fusions. Aki/Suika have richer regular/fusion rosters. Road forms continue single-unit arrivals on their old interval.

## 3. Integrated balance and publication

- Run native empty-board 4-19/4-20/8-6 routes with campaign fusion enemies and legal delivered/paid planting. Check all twelve full difficulty routes with stronger finales, including Suika’s five active rows and real tea/milk grafting. Fix the old Suika prepared diagnostic to consume its actual belt and use legal starting ingredients rather than treating its unavailable sunflowers as a valid belt formation.
- Run affected phase, role, danmaku, conveyor and custom-boss regressions; review the combined diff independently.
- Stamp v1.0.175, commit and push its annotated tag. Await Windows/macOS/Android/Web builds and Pages deployment, publish exact notes, inspect export logs and verify the deployed PCK version and new runtime resources.
