# 抽卡植物、强化与罗德岛优化 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve gacha plant identity, add resonance milestones to enhancement, and make Rhodes Island rooms upgradeable with clear synergy feedback.

**Architecture:** Extend the existing renderer dispatch and enhancement/base helpers in `scripts/game.gd`. New state is optional and initialized by existing default/merge functions so old saves remain valid. UI uses existing rectangle helpers and terminal assets; no Touhou Boss resource path is changed.

**Tech Stack:** Godot 4 GDScript, procedural CanvasItem drawing, existing headless SceneTree tests.

---

### Task 1: Add visual identity helpers and regression coverage

**Files:**
- Modify: `scripts/game.gd:26532-26620, 32100-33120`
- Test: `tests/unit_identity_visual_test.gd`

**Step 1: Write the failing test**

Add assertions for a gacha identity helper, a stable identity key per gacha plant, and scale-safe bounds metadata.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/unit_identity_visual_test.gd`
Expected: FAIL because the identity helper is not defined.

**Step 3: Implement the minimal code**

Add `_gacha_identity_profile(kind)` and `_draw_gacha_identity_layer(kind, center, size_scale, flash, alpha)`. Dispatch it only for `gacha_only` plants after the existing per-plant renderer. Give each current gacha kind a distinct silhouette component and keep all coordinates derived from `size_scale`.

**Step 4: Run test to verify it passes**

Run the same command. Expected: PASS, with existing Boss and ordinary plant branches unchanged.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/unit_identity_visual_test.gd
git commit -m "feat: restore distinct gacha plant silhouettes"
```

### Task 2: Add enhancement resonance and preview data

**Files:**
- Modify: `scripts/game.gd:650-735, 6376-6465, 6540-6685`
- Test: `tests/enhance_system_test.gd`

**Step 1: Write the failing test**

Cover resonance at levels 5, 10, and 15; next-level preview values; and failure protection at level 10 or higher.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/enhance_system_test.gd`
Expected: FAIL because resonance and preview methods do not exist.

**Step 3: Implement the minimal code**

Add resonance definitions and helpers. Apply resonance multipliers in the existing enhanced stats/runtime multiplier path. Update `_try_enhance_plant` so failures at level 10+ keep the current level. Extend the enhancement detail panel with current/next resonance and delta values while keeping existing action rectangles unchanged.

**Step 4: Run test to verify it passes**

Run the enhancement test and verify old save merge tests still pass.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/enhance_system_test.gd
git commit -m "feat: add enhancement resonance milestones"
```

### Task 3: Add Rhodes Island room upgrades and synergy readout

**Files:**
- Modify: `scripts/game.gd:810-840, 4610-4895, 5050-5075, 5393-5445, 19558-19630, 33640-33735`
- Test: `tests/base_system_test.gd`

**Step 1: Write the failing test**

Cover upgrade costs, level cap, efficiency/capacity changes, save merge defaults, and non-overlapping upgrade controls.

**Step 2: Run test to verify it fails**

Run: `godot --headless --path . --script tests/base_system_test.gd`
Expected: FAIL because room upgrade helpers and upgrade rect are not defined.

**Step 3: Implement the minimal code**

Add per-room upgrade metadata and `_base_room_upgrade_cost`, `_base_can_upgrade_room`, `_base_upgrade_room`, plus `_base_upgrade_rect`. Initialize and merge optional room fields. Handle the new click target before roster/material hit testing. Add level/cost/synergy text to the detail panel and use existing room pulse FX on success.

**Step 4: Run test to verify it passes**

Run the base test and confirm all existing layout, FX, and offline production checks pass.

**Step 5: Commit**

```bash
git add scripts/game.gd tests/base_system_test.gd
git commit -m "feat: add upgradeable Rhodes Island rooms"
```

### Task 4: Full verification and release

**Files:**
- Modify: `docs/plans/2026-09-06-gacha-enhance-base-implementation.md` only if test commands change

**Step 1: Run focused tests**

Run the following commands:

```bash
godot --headless --path . --script tests/enhance_system_test.gd
godot --headless --path . --script tests/base_system_test.gd
godot --headless --path . --script tests/gacha_ui_test.gd
godot --headless --path . --script tests/gacha_passive_test.gd
godot --headless --path . --script tests/unit_identity_visual_test.gd
git diff --check
```

Expected: all commands exit 0 and no whitespace errors are reported.

**Step 2: Inspect release scope**

Run `git status --short`, `git diff origin/main...HEAD --stat`, and verify `tmp/` remains untracked and no Boss assets changed.

**Step 3: Publish**

Set git identity to `NightsReimu <nightsreimu@gmail.com>` for the release commit if needed, push `main`, create annotated tag `v1.0.96`, push the tag, and create the GitHub release for `NightsReimu/pvz-godot`.
