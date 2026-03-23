# Fog 4-17 / 4-18 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 为第四世界补上 `4-17` 无雾盐沼传送带关和 `4-18` 浓雾 Boss 传送带终章。

**Architecture:** 复用现有第四世界、传送带和 Boss 框架。`4-17` 只新增一个无雾后院地形分支；`4-18` 新增一个轻量 `fog_boss`，接入现有 Boss 生成、阶段切换、血条、图鉴和绘制链路。

**Tech Stack:** Godot 4, GDScript, headless SceneTree tests

---

### Task 1: Lock the new level contract with tests

**Files:**
- Modify: `tests/fog_world_test.gd`
- Modify: `tests/conveyor_level_rules_test.gd`
- Create: `tests/fog_boss_test.gd`

**Step 1: Write the failing test**

- Extend fog world metadata expectations from `4-16` to `4-18`
- Assert `4-17` exists as `clear_backyard + conveyor`
- Assert `4-18` exists as `fog + conveyor + boss_level`
- Assert `4-17` conveyor contains only `brine_pot`
- Assert `4-17` event roster covers every non-Boss zombie
- Assert `4-18` conveyor includes all fog-world plants except `lily_pad`
- Assert `4-18` has exactly one `fog_boss` event

**Step 2: Run test to verify it fails**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/conveyor_level_rules_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_boss_test.gd
```

Expected: failures for missing `4-17`, `4-18`, `fog_boss`, and outdated world metadata.

### Task 2: Add level definitions and world metadata

**Files:**
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/data/world_data.gd`

**Step 1: Write minimal implementation**

- Add `4-17` and `4-18` after `4-16`
- Update fog world subtitle/description to `4-18`
- `4-17`
  - `terrain = "clear_backyard"`
  - `mode = "conveyor"`
  - `available_plants = ["brine_pot"]`
  - `conveyor_plants = ["brine_pot", ...]`
  - events cover all non-Boss zombies
- `4-18`
  - `terrain = "fog"`
  - `mode = "conveyor"`
  - `boss_level = true`
  - `conveyor_plants` contains all fourth-world plants except `lily_pad`
  - final event spawns `fog_boss`

**Step 2: Run tests**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/conveyor_level_rules_test.gd
```

### Task 3: Add the new fog boss to runtime

**Files:**
- Modify: `scripts/game_defs.gd`
- Modify: `scripts/game.gd`
- Modify: `scripts/data/almanac_text.gd`

**Step 1: Write minimal implementation**

- Add `fog_boss` to zombie definitions and almanac order
- Add almanac lines/stats copy
- Add boss reinforcement pool for fog roster
- Add `fog_boss` cases in:
  - `_trigger_boss_skill`
  - `_trigger_boss_phase_shift`
  - `_update_boss_reinforcements`
  - `_draw_zombie`
- Add a simple dedicated `_draw_fog_boss`

**Step 2: Run tests**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_boss_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd
```

### Task 4: Support the new no-fog backyard terrain

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Write minimal implementation**

- Add helper for `clear_backyard`
- Make board/background rendering and pool visuals treat it as a backyard pool board
- Ensure fog overlay and fog reveal logic remain disabled on `clear_backyard`

**Step 2: Run tests**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/conveyor_level_rules_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_boss_test.gd
```

### Task 5: Regression verification

**Files:**
- Test: `tests/fog_world_test.gd`
- Test: `tests/conveyor_level_rules_test.gd`
- Test: `tests/fog_boss_test.gd`
- Test: `tests/status_behavior_test.gd`
- Test: `tests/plant_effect_alignment_test.gd`

**Step 1: Run the full targeted suite**

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_world_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/conveyor_level_rules_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/fog_boss_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/status_behavior_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/plant_effect_alignment_test.gd
```

Expected: all exit code `0`.
