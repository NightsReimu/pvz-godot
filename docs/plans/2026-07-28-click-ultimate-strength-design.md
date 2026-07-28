# Click Ultimate Strength Restoration Design

## Context

Versions 1.0.87 and 1.0.88 changed most campaign plants from their established
plant-food powers to newly added generic or per-plant click-ultimate branches.
Those branches preserved variety, but changed the strength baseline the player
expects from a fully charged click ultimate.

## Decision

Restore the 1.0.84 routing rule for plants supported by `PlantFoodRuntime`.
Existing dedicated click ultimates declared before that rule, including amber
shooter, lotus lancer, Tesla tulip, flower pot, and similar special cases, keep
their dedicated behavior. Plants with explicit ultimate data and plants without
a plant-food implementation keep using the current explicit/generic fallback.

This restores the stronger, mature energy-bean effects without reverting the
click charge UI, input handling, cooldown state, newer plant definitions, or
unrelated combat work.

## Alternatives Considered

- Apply a global damage multiplier to current click ultimates. Rejected because
  healing, armor, control, summons, and production ultimates would remain weak.
- Revert versions 1.0.87 and 1.0.88 wholesale. Rejected because it would also
  remove useful coverage and dedicated implementations.
- Restore `PlantFoodRuntime` routing at the original priority. Chosen because it
  matches the requested old behavior and has a known working implementation.

## Verification

- A normal campaign plant such as peashooter must expose the
  `plant_food_ultimate` profile and enter its `pea_storm` state when clicked.
- A dedicated click-ultimate plant such as amber shooter must retain its custom
  profile and projectile barrage.
- Plant food, click-ultimate coverage, boot, and formatting tests must pass.
