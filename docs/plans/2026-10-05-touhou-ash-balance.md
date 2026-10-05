# Touhou encounter and ash ammunition implementation plan

**Goal:** Make every road boss an incomplete encounter, strengthen finales, and replace repetitive ash bombs with partner-specific ammunition before publishing v1.0.170.

**Architecture:** Configure encounter health once at spawn, before spell boundaries are initialized. Keep native firing, reload, targeting, armor and ultimate state machines; attach bounded ash payloads to ballistic ammunition and remove their separate explosive channel. Non-ballistic ash combinations keep reduced, independently charged blasts.

**Tech stack:** Godot 4.6, GDScript, native drawing, GitHub Actions.

1. Add `tests/touhou_role_balance_test.gd`: enumerate every authored Touhou level and available tier, spawn actual road and final bosses, compare old definitions and HP bounds, validate fresh finale and spell partition. Observe failure before implementation.
2. Modify `scripts/runtime/touhou_phase_runtime.gd` and `scripts/game.gd`: self road 9% of old scaled HP; different road 18% capped by 10% of old finale HP; full finale 145% of old scaled HP. Apply before phase bounds, retaining distinct road spells/nonspell identity, finale music and reinforcements.
3. Add `tests/ash_ammunition_test.gd`: actual fired bullets, small blast radius, ally/hidden/armor rules, no extra bomb after charge or ultimate, lob impacts, repeated pea volley budget, native one-shot unchanged. Observe existing behavior fail.
4. Modify `scripts/data/fusion_combat_profiles.gd`, `scripts/runtime/fusion_native_runtime.gd`, `scripts/data/plant_ammo.gd`, `scripts/runtime/projectile_runtime.gd`, and `scripts/ui/plant_fusion_visuals.gd`: cherry ballistic payload 48px small blast; doom 64px dark blast; jalapeno burning ammunition. Ash bonus is bounded per native volley, shared among bullets, with diminishing repeated materials. Preserve native projectile types and source patterns; prevent extra bomb channels. Reduce retained cherry/doom/jalapeno/core/glitch burst damage and charged ultimate multiplier. Describe actual payloads in catalogue.
5. Update existing `tests/fusion_trait_combat_test.gd` expectations for the new requested behavior; keep long cooldown/recursive inheritance contracts on actual bomb combinations.
6. Run red/green fixtures, relevant Touhou encounters/difficulty/self-midboss/character and fusion/projectile/ultimate tests, prepared defense battle, boot, all Python repository checks, import and `git diff --check`. Inspect desktop/mobile ammunition screenshots.
7. Update version/export config/README and `docs/releases/v1.0.170.md`; commit, tag, push atomically. Await four platform exports, public release and Pages deployment. Verify release assets and logs, then report release and playable links.

The user explicitly authorizes these balance changes and publishing the release. Preserve unrelated untracked files. Continue within this scope without another approval round.
