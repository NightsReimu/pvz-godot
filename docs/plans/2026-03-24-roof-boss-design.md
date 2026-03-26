# Roof Boss Design

**Topic:** `5-17` 屋顶世界 Boss 关

**Goal:** 在屋顶世界 `5-16` 之后新增一个完整可玩的 `5-17` Boss 关，沿用现有 `3-18` / `4-18` 的终章结构，加入独立屋顶 Boss、持续右侧增援、底部五段血条、夸张技能特效和屋顶主题压力。

## Chosen Approach

采用新的 `roof_boss` 数据定义和现有 Boss 终章机制扩展，而不是复用旧 Boss 皮肤或单纯堆怪。

原因：
- 和 `pool_boss`、`fog_boss` 的架构一致，接入点明确，风险最低。
- 现有测试、血条、Boss 阶段和右侧增援逻辑都能复用。
- 用户一直要求“直接做”和“特效夸张”，这个方案改动集中，能最快给出完整结果。

## Boss Theme

Boss 名称暂定为 `穹顶尸王`。

主题定位：
- 屋顶工程化尸王
- 擅长空袭、瓦片压制、工程封锁
- 会召来屋顶时代僵尸和扩展屋顶僵尸持续混编进场

## Level Structure

`5-17` 设计为屋顶传送带 Boss 关。

关键规则：
- `terrain: "roof"`
- `mode: "conveyor"`
- `boss_level: true`
- 使用屋顶世界已解锁植物和扩展植物作为传送带池
- 保留屋顶花盆支撑规则
- 右侧在 Boss 存活期间持续刷怪
- 终局必须击败 `roof_boss` 才能过关

## Boss Mechanics

`roof_boss` 固定压在右侧，不走正常前进路线，阶段和技能逻辑按当前 Boss 框架实现。

技能循环：
1. **混编空投**
   - 召唤屋顶时代和扩展屋顶僵尸
   - 允许池：`bungee_zombie`、`ladder_zombie`、`catapult_zombie`、`kite_zombie`、`hive_zombie`、`turret_zombie`、`programmer_zombie`
2. **瓦顶轰炸**
   - 对多行前排植物造成高额伤害
   - 叠加大范围 `lane_spray` / 爆点特效
3. **工程封锁**
   - 对若干格位施加压制
   - 配合 `turret_zombie`、`bungee_zombie` 或 `ladder_zombie` 形成后续压力

阶段强化：
- 血量进入新阶段时触发大范围屏幕特效
- 阶段越高，增援间隔越短、技能覆盖越广

## Visual Direction

Boss 表现独立绘制，不复用 `pool_boss` / `fog_boss` 外形。

视觉元素：
- 红砖与铜件主体
- 天线/投石臂/屋瓦轮廓
- 夸张橙红色高亮和建筑阴影
- 与屋顶世界暖色背景保持一致

## Testing

测试覆盖：
- `5-17` 存在且仅安排 1 次 `roof_boss`
- `roof_boss` 无法重复生成
- `roof_boss` 召唤技能只会产出允许的屋顶增援
- `roof_boss` 存活时右侧持续刷怪
- `roof_boss` 使用底部五段血条
- 屋顶世界文案与路线覆盖到 `5-17`
