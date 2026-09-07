# Touhou Difficulty Implementation Plan

**Goal:** Offer Easy/Normal/Hard/Lunatic after clicking a regular Touhou stage, and EX/EX+ for the existing Extra finales. Preserve today's encounters as the lowest setting. Highest settings require seed selection.

**Architecture:** Build isolated level overrides from immutable stage definitions. Keep difficulty profiles and additional attack routes in a dedicated data module; reuse native seed selection, phase progression, danmaku, reinforcement and save systems. A modal owns difficulty input before map controls can receive it.

**Tech Stack:** Godot 4.6, GDScript, existing no-save battle harness and native desktop/mobile viewport capture.

## Rules
- Easy and EX preserve existing gameplay. Upper tiers increase boss health, attack pressure, required phases and road waves. New extension attacks are explicitly tower-defense additions; verified higher-difficulty spell variants retain their original references.
- Regular tiers add one/two/three phases; EX+ adds two. Keep canonical finales and existing resurrection/successor handling last.
- Lunatic and EX+ use the player's available collection, with terrain support and basic sun production available. Restore normal card costs/cooldowns and starting/sky sun for these previously conveyor-only stages.
- Difficulty is chosen after entering an unlocked map node. Escape/back cancels; seed-selection back returns to the selector. Restart retains difficulty and selected seeds. Clear records are per difficulty, while map unlocks continue using the original stage index.
- No independent midboss is added to stages that do not have one. Existing midboss gates, music and successor fights remain intact.

## Implementation
1. Add `scripts/data/touhou_difficulty_defs.gd`: classification, profiles, immutable level overrides, extra phases, canonical variants and capped extra wave schedules. Validate monotonic difficulty and baseline equivalence in `tests/touhou_difficulty_test.gd`.
2. Integrate profiles into spawn stats, danmaku density/speed/damage, skill/reinforcement intervals and phase route construction. Add real collision patterns for extension attacks and preserve original finishers.
3. Add `scripts/runtime/touhou_difficulty_menu.gd`, map input interception, selected-level override propagation, seed economy, retry and save compatibility. Cover full map-to-selection-to-battle, retry, clears and unaffected non-Touhou stages.
4. Capture desktop and small landscape selector/selection/battle views, inspect text and hitboxes, run Touhou encounter/spell, UI, seed-selection and progression regressions. Verify no errors in Godot logs.
5. Update documentation/version, commit and push using NightsReimu, publish the next release and verify all build artifacts.

## Status
- Implementation and local verification complete: all 17 stage selectors, all 21 character routes, collision-bearing added attacks, native seed selection, touch input, retries and per-difficulty saves.
- Existing encounter, spell-contract, UI-layout, conveyor, progression and midboss/finale gate regressions passed. Desktop and 844x390 / 568x320 captures were inspected.
- Release target: v1.0.101. Publication and Windows/macOS/Web/Android build verification follow the commit; the GitHub Actions run is the source of release status.

## Validation Commands
`godot --headless --path . --script tests/touhou_difficulty_test.gd`

`godot --headless --path . --script tests/touhou_difficulty_flow_test.gd`

`godot --headless --path . --script tests/touhou_encounter_test.gd`

`godot --headless --path . --script tests/touhou_spell_contract_test.gd`

`godot --headless --path . --script tests/ui_layout_regression_test.gd`
