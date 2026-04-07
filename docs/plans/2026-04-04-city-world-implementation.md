# 城市世界 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 接入第六世界“城市世界”，实现 `6-1` 到 `6-10`、8 个新植物、5 个新僵尸，以及瓷砖/铁轨/雪地城市地格机制。

**Architecture:** 复用现有世界定义、关卡定义与 runtime 分层，把“城市地格”和“轨道/下水道”作为 `cell_terrain_mask` 的扩展状态处理。植物与僵尸的数值放在 defs，行为分别写入 `plant_runtime.gd`、`projectile_runtime.gd`、`plant_food_runtime.gd`，主脚本只承担接线、绘制和关卡流转。

**Tech Stack:** Godot 4 GDScript、纯绘制 UI/战斗场景、现有 `game.gd` + split runtime modules、headless test scripts。

---

### Task 1: 为第六世界写世界/关卡接入测试

**Files:**
- Create: `tests/city_world_test.gd`
- Modify: `tests/progress_unlock_test.gd`

**Step 1: 写失败测试**
- 断言 `6-1` 到 `6-10` 存在
- 断言 `6-*` 归属 `city` 世界
- 断言 `city` 世界起点在通关 `5-17` 前锁定，通关后解锁
- 断言 `6-10` 为传送带关，且包含 `flower_pot`

**Step 2: 运行测试确认失败**

Run:
```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/city_world_test.gd
```

**Step 3: 实现最小世界骨架**
- 新增 `scripts/data/level_defs_city.gd`
- 修改 `scripts/data/level_defs.gd`
- 修改 `scripts/data/world_data.gd`
- 修改 `scripts/game.gd` 中 `_world_key_for_level`、`_map_mode_title_for_world`

**Step 4: 重跑测试**

**Step 5: 继续下一任务**

### Task 2: 接入城市地格与花盆判定

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/city_world_test.gd`

**Step 1: 写失败测试**
- 断言 `city_tile` / `rail` 需要花盆
- 断言 `land` 可直接种植
- 断言 `snowfield` 也要求花盆后种普通植物

**Step 2: 运行测试确认失败**

**Step 3: 最小实现**
- 扩展 `_setup_cell_terrain_mask`
- 扩展 `_placement_error`
- 新增城市格判定 helper
- 为 `6-10` 提供固定随机种子生成的草地/瓷砖图

**Step 4: 重跑测试**

### Task 3: 新增植物 defs 和图鉴文本

**Files:**
- Modify: `scripts/data/plant_defs.gd`
- Modify: `scripts/data/almanac_text.gd`
- Test: `tests/runtime_split_test.gd`

**Step 1: 写失败测试**
- 断言 8 个新植物存在于 `PLANTS` / `ORDER`
- 断言都有 ultimate 字段

**Step 2: 运行测试确认失败**

**Step 3: 最小实现**
- 新增：
  - `heather_shooter`
  - `leyline`
  - `holo_nut`
  - `healing_gourd`
  - `mango_bowling`
  - `snow_bloom`
  - `cluster_boomerang`
  - `glitch_walnut`

**Step 4: 重跑测试**

### Task 4: 新增僵尸 defs 和图鉴文本

**Files:**
- Modify: `scripts/data/zombie_defs.gd`
- Modify: `scripts/data/almanac_text.gd`
- Modify: `scripts/game.gd`
- Test: `tests/city_world_test.gd`

**Step 1: 写失败测试**
- 断言 5 个新僵尸存在且可在图鉴顺序中显示

**Step 2: 运行测试确认失败**

**Step 3: 最小实现**
- 新增：
  - `wenjie_zombie`
  - `janitor_zombie`
  - `subway_zombie`
  - `enderman_zombie`
  - `router_zombie`

**Step 4: 重跑测试**

### Task 5: 实现基础植物行为

**Files:**
- Modify: `scripts/runtime/plant_runtime.gd`
- Modify: `scripts/game.gd`
- Test: `tests/city_world_test.gd`

**Step 1: 写失败测试**
- 石楠花射手会附带腐蚀与眩晕
- 地脉能整行攻击
- 全息坚果能回血
- 治愈葫芦能治疗周围植物

**Step 2: 跑失败测试**

**Step 3: 最小实现**
- 为 4 个植物加 update 方法
- 复用现有 effect / status timer 体系

**Step 4: 重跑测试**

### Task 6: 实现投射物与特殊植物行为

**Files:**
- Modify: `scripts/runtime/projectile_runtime.gd`
- Modify: `scripts/runtime/plant_runtime.gd`
- Modify: `scripts/game.gd`
- Test: `tests/city_world_test.gd`

**Step 1: 写失败测试**
- 芒果保龄球能滚动并弹向相邻行
- 聚集回旋镖能维持最多 10 个
- 失真核桃到时触发全体随机效果
- 雪中花能生成临时雪地

**Step 2: 跑失败测试**

**Step 3: 最小实现**
- 扩展 roller / boomerang / timed support 行为
- 新增 snowfield 生命周期

**Step 4: 重跑测试**

### Task 7: 实现 8 个植物的大招

**Files:**
- Modify: `scripts/runtime/plant_food_runtime.gd`
- Modify: `scripts/runtime/plant_runtime.gd`
- Modify: `scripts/runtime/projectile_runtime.gd`
- Test: `tests/runtime_split_test.gd`

**Step 1: 写失败测试**
- 断言新增 8 植物都能触发 plant food

**Step 2: 跑失败测试**

**Step 3: 最小实现**
- 为每个植物补一套明确的 plant food 行为

**Step 4: 重跑测试**

### Task 8: 实现 5 个新僵尸行为

**Files:**
- Modify: `scripts/game.gd`
- Modify: `scripts/runtime/projectile_runtime.gd`
- Test: `tests/city_world_test.gd`

**Step 1: 写失败测试**
- 问界僵尸会随机换行
- 清洁工僵尸能正面格挡并铲植物
- 地铁僵尸沿轨冲刺
- 末影人僵尸瞬移后阻挡弹道但不进家
- 路由器僵尸在场时给全体僵尸增益

**Step 2: 跑失败测试**

**Step 3: 最小实现**
- 给各类僵尸增加状态字段、AI 更新和视觉特效

**Step 4: 重跑测试**

### Task 9: 接入城市世界绘制与模型

**Files:**
- Modify: `scripts/game.gd`
- Test: `tests/game_boot_test.gd`

**Step 1: 写失败测试**
- 至少断言新 draw helper / terrain helper 可加载

**Step 2: 跑失败测试**

**Step 3: 最小实现**
- 城市世界背景
- 草地/瓷砖/铁轨/雪地/下水道井盖绘制
- 8 植物与 5 僵尸的独立 draw helper

**Step 4: 重跑测试**

### Task 10: 完成 `6-1` 到 `6-10` 配表与平衡

**Files:**
- Modify: `scripts/data/level_defs_city.gd`
- Test: `tests/city_world_test.gd`

**Step 1: 写失败测试**
- 断言每关奖励植物、模式、传送带和关键僵尸组合符合设计

**Step 2: 跑失败测试**

**Step 3: 最小实现**
- 完成 10 关事件、种子池、地格 mask、轨道、下水道刷怪点

**Step 4: 重跑测试**

### Task 11: 运行整体验证

**Files:**
- Test: `tests/city_world_test.gd`
- Test: `tests/progress_unlock_test.gd`
- Test: `tests/runtime_split_test.gd`
- Test: `tests/special_modes_test.gd`
- Test: `tests/game_boot_test.gd`

**Step 1: 运行**

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot --quit
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/city_world_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/progress_unlock_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/runtime_split_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/special_modes_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/game_boot_test.gd
```

**Step 2: 处理失败项直到通过**

**Step 3: 继续主线实现或提交**
