# Touhou Encounter Phases Implementation Plan

**Goal:** Make later Touhou encounters play their longer spell sequences instead
of sharing four health tiers and cycling a partially seen spell catalogue.

**Architecture:** Keep the existing TH06/TH07 route catalogues and all image
resources. Group each canonical spell into a combat phase with an unnamed,
character-specific nonspell opening. Keep Youmu's original wraith card inside
her sword sequence and Yuyuko's timed Rebirth as the final sixth phase. A small
runtime owns phase progress and health boundaries; existing danmaku owns actual
attacks and existing boss timing owns windup and recovery. Legacy `boss_phase`
remains the bounded 0-3 pressure tier so Extra stages cannot multiply movement,
summons, damage or sprite scale without limit.

**Tech Stack:** Godot 4, GDScript, native rendering, existing regression scripts.

## Design Decisions

- Normal spell phases: Rumia 2, Cirno 3, Meiling/Patchouli/Sakuya 4, Remilia 5;
  Letty 2, Chen/Alice/Prismriver 4, Youmu 5, Yuyuko 5 plus Rebirth.
- Extra/Phantasm: Flandre 10, Ran 10, Yukari 11. Midboss routes retain their own
  shorter tables. Unnamed midbosses remain nonspell encounters.
- Stage counts are this project's spell-phase grouping, not a claim that original
  nonspell health bars, difficulty branches, or route variations are identical.
- Split existing total HP across phases. Damage cannot skip a phase, healing
  cannot restore a cleared phase, and each phase's required attacks must execute.
- Use a short nonspell opening and full spell emission, with visible transitions.
  Retain the existing invulnerable survival attacks and cancel only the outgoing
  boss's bullets/emitters/time stop when transitioning.
- HUD shows actual phase progress and current phase HP. No art changes.

## Tasks

1. Extend `scripts/data/touhou_spell_defs.gd` with phase grouping, nonspell metadata,
   and phase-aware selection. Add a focused encounter regression script.
2. Add `scripts/runtime/touhou_phase_runtime.gd`; connect spawn, damage, cleanup,
   healing, boss timing, survival completion and Ran/Yukari handoff.
3. Extend `scripts/runtime/touhou_danmaku_runtime.gd` with character-specific
   nonspells using existing bullets, beams and actor primitives.
4. Update HUD and `docs/touhou-spells.md`; capture desktop/mobile stage labels and
   representative late attacks using the existing native capture framework.
5. Run encounter, spell-contract, boss-flow, balance, HUD, status and ordinary-boss
   regressions; verify no Boss art changed. Commit and push using NightsReimu.

## Validation

Exercise every full encounter with burst damage and confirm all required cards
appear in order, nonspells produce distinct live projectiles, healing stays within
the active segment, time stop/transition cleanup is scoped, survival stages expire,
Youmu's original charm remains reachable, and successor state is independent.
Run `godot --headless --path . -s res://tests/touhou_encounter_test.gd` and the
relevant existing tests. Inspect native screenshots at desktop/mobile sizes.

## Completed Verification

- Full 18-boss and five-midboss encounter sequences passed, including canonical
  card order, burst damage, phase-local healing, scaled HP, repeated attacks,
  time stop, pause, survival without damage, and independent successor state.
- Fourteen focused regression scripts passed: encounter, spell contracts, boss
  flow, Touhou balance, battle HUD, almanac, statuses, special attacks, pool/fog/
  roof/city bosses, unit identity, and UI layout.
- Native captures at 1600x900, 1000x450 and 844x390 rendered the original Boss
  images with phase counts, current-segment health and Rebirth's survival timer.
- Godot editor import and `git diff --check` passed. `art/` and `audio/` have no
  changes. Verification does not cover Android device builds or frame-accurate
  original-game bullet trajectories.
