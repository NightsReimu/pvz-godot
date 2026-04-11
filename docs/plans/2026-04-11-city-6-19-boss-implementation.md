# City 6-19 Boss Finale Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a manual seed-selection city finale level `6-19` with a new `city_boss`, 10 total waves, and a full non-boss zombie roster.

**Architecture:** Reuse the existing end-world boss pipeline instead of adding a bespoke mode. The level data is generated in `level_defs_city.gd`, the boss is added as a normal zombie definition plus runtime hooks in `game.gd`, and tests lock the contract around waves, roster coverage, spawn behavior, and health-bar layout.

**Tech Stack:** Godot 4 GDScript, data-driven level definitions, existing Boss runtime helpers, headless Godot tests.

---

### Task 1: Lock The Level Contract

**Files:**
- Modify: `tests/city_world_test.gd`
- Create: `tests/city_boss_test.gd`

**Step 1: Write the failing test**

Add assertions that:
- city world subtitle extends to `6-19`
- `6-19` exists, is `boss_level`, is not conveyor, has 10 waves, uses `city_boss`
- `6-19` event roster covers every non-boss zombie
- `city_boss` cannot duplicate, summons reinforcements, and uses the five-segment bottom health bar

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s tests/city_world_test.gd`
Expected: FAIL because `6-19` does not exist yet

Run: `godot --headless --path . -s tests/city_boss_test.gd`
Expected: FAIL because `city_boss` does not exist yet

**Step 3: Write minimal implementation**

Do not touch production code yet.

**Step 4: Run test to verify it passes**

Not applicable until Task 2 and Task 3 are done.

**Step 5: Commit**

```bash
git add tests/city_world_test.gd tests/city_boss_test.gd
git commit -m "test: lock city 6-19 finale contract"
```

### Task 2: Add The Level And Boss Data

**Files:**
- Modify: `scripts/data/level_defs_city.gd`
- Modify: `scripts/data/world_data.gd`
- Modify: `scripts/data/zombie_defs.gd`
- Modify: `scripts/data/almanac_text.gd`

**Step 1: Write the failing test**

Reuse the new test coverage from Task 1.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s tests/city_world_test.gd`
Expected: FAIL on missing `6-19` or wrong metadata

**Step 3: Write minimal implementation**

- Add `city_boss` zombie data
- Extend city world subtitle/description to `6-19`
- Add a programmatic `6-19` event builder that includes every non-boss zombie and ends on `city_boss`
- Mark the level as a normal manual-selection boss stage with `boss_level: true`

**Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s tests/city_world_test.gd`
Expected: PASS

**Step 5: Commit**

```bash
git add scripts/data/level_defs_city.gd scripts/data/world_data.gd scripts/data/zombie_defs.gd scripts/data/almanac_text.gd
git commit -m "feat: add city 6-19 finale data"
```

### Task 3: Wire Runtime Boss Behavior

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/city_boss_test.gd`

**Step 1: Write the failing test**

Reuse `tests/city_boss_test.gd`.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . -s tests/city_boss_test.gd`
Expected: FAIL on missing spawn hooks or boss skills

**Step 3: Write minimal implementation**

- Register `city_boss` in boss ordering
- Add spawn setup, reinforcement timer support, skill cycle, phase-shift behavior, extra-support routing, almanac stat text, and draw routine

**Step 4: Run test to verify it passes**

Run: `godot --headless --path . -s tests/city_boss_test.gd`
Expected: PASS

**Step 5: Commit**

```bash
git add scripts/game.gd tests/city_boss_test.gd
git commit -m "feat: implement city boss runtime"
```

### Task 4: Regression Verification

**Files:**
- Test: `tests/progress_unlock_test.gd`
- Test: `tests/city_world_test.gd`
- Test: `tests/city_boss_test.gd`

**Step 1: Write the failing test**

No new tests.

**Step 2: Run test to verify current state**

Run:

```bash
godot --headless --path . -s tests/city_world_test.gd
godot --headless --path . -s tests/city_boss_test.gd
godot --headless --path . -s tests/progress_unlock_test.gd
```

Expected: all PASS

**Step 3: Write minimal implementation**

Only fix real regressions if any command fails.

**Step 4: Run test to verify it passes**

Repeat the same three commands until all return exit code `0`.

**Step 5: Commit**

```bash
git add scripts/game.gd scripts/data/level_defs_city.gd scripts/data/world_data.gd scripts/data/zombie_defs.gd scripts/data/almanac_text.gd tests/city_world_test.gd tests/city_boss_test.gd docs/plans/2026-04-11-city-6-19-boss-design.md docs/plans/2026-04-11-city-6-19-boss-implementation.md
git commit -m "feat: add city world 6-19 boss finale"
```
