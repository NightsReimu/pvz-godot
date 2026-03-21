# Day 1-18 Frozen Branch Design

**Goal:** Add a new white-day branch level `1-18` after `1-17`, featuring a frozen-lake battlefield, Daiyousei as a mid-boss, and Cirno as the final boss.

**Approved Scope**
- `1-18` is placed immediately after `1-17` in the day world and requires both `1-17` and `3-4` to be cleared.
- The map must remain horizontally scrollable so the new node appears to the right of `1-17`.
- The battlefield uses five active rows and nine columns.
- Columns `0-4` are water before Cirno appears.
- Columns `5-8` are normal land for the entire level.
- Conveyor mode is used throughout the level.
- Daiyousei appears once at 50% progress as a true mid-boss and freezes wave progression until defeated.
- Cirno appears as the final boss after the mid-boss segment.
- While either boss is alive, zombies continue to spawn from the right.
- When Cirno appears, columns `0-4` convert from water to frozen ice across all active rows.
- Frozen columns no longer require lily pads, but plants placed there attack more slowly.
- Cirno and Daiyousei use imported sprite sheets, trimmed frames, left-facing orientation, and looped intro/boss BGM similar to `1-17`.

**Boss Interpretation**
- Daiyousei is implemented as an EoSD stage 2 mid-boss style encounter without named spell cards.
- Cirno uses EoSD stage 2 inspired ice patterns built around `Icicle Fall`, `Perfect Freeze`, and `Diamond Blizzard`.
- Boss animations stay mostly stable in idle and only switch state frames during movement, casting, hurt, and defeat states.

**Technical Direction**
- Add per-cell terrain support instead of relying only on `water_rows`.
- Keep existing row-based pool spawn partitioning intact for pool world stages.
- Introduce a special frozen-lake rule set used only by `1-18` so the rest of the campaign is unaffected.
- Reuse the existing boss health bar and BGM infrastructure from `1-17`.
- Reuse the existing effect system for ice lances, freezing bursts, snowflake swirls, and transition effects.
