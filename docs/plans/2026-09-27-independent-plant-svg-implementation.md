# 独立植物 SVG 美术实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 重绘全部 144 个植物物种及状态变体，让每个 SVG 根据植物特点拥有独立的轮廓和材质识别，并发布新的 GitHub release。

**Architecture:** 保留现有 SVG 生成器和 `VectorUnitArt` 加载接口；把共享完整主体收敛为低层几何工具，再为每个物种增加专属形态分支和签名器官。生成器继续一次性写出基础 SVG、状态 SVG 与 manifest，运行时不需要改资源路径。

**Tech Stack:** Python 3 SVG 生成器、Godot 4 headless/display tests、Git/GitHub CLI。

---

### Task 1: 建立全量 SVG 身份回归

**Files:**
- Modify: `tests/vector_art_assets_test.gd`
- Modify: `tests/unit_identity_visual_test.gd`

**Steps:**
1. 记录 manifest 中 144 个物种、所有生成 SVG、状态变体的完整性与可加载性。
2. 增加按植物分组的轮廓比较和 SVG 结构签名检查，避免物种只因颜色不同而通过。
3. 运行测试确认当前实现暴露出共享底模风险，保存失败输出作为重绘前基线。

### Task 2: 重构生成器的物种形态层

**Files:**
- Modify: `scripts/tools/build_vector_unit_art.py`

**Steps:**
1. 保留 `path`、`ell`、`leaf`、`petal`、`crystal` 等低层工具。
2. 给每个 recipe 增加基于玩法的独立轮廓锚点，包括炮口、花心/花瓣、菌盖边缘、壳体纹理、投掷架、果皮分瓣、根系和特殊装备。
3. 将完整共享底膜改成带物种参数的主体构建，确保同类植物仍有系列关系但拥有不同姿态、比例和材质。
4. 保持全部状态文件名与 manifest 生成行为不变。
5. 重建 SVG 并检查文件数、画布留白和所有 `Defs.PLANTS` 对应关系。

### Task 3: 运行资源与视觉回归

**Files:**
- Modify: `docs/releases/v1.0.141.md`
- Modify: `README.md` only if new preview is needed

**Steps:**
1. 运行 `godot --headless --path . -s res://tests/vector_art_assets_test.gd`。
2. 运行 `godot --headless --path . -s res://tests/unit_identity_visual_test.gd`，有显示渲染器时再运行一次非 headless 像素检查。
3. 运行 `godot --headless --path . -s res://tests/game_boot_test.gd`、`ui_surface_polish_test.gd` 和 `plant_effect_alignment_test.gd`。
4. 运行生成器静态检查与 manifest/植物定义审计，确认没有资源路径、状态文件或裁切回归。
5. 写入 release 说明，记录实际资源数、测试命令和已知限制。

### Task 4: 提交并发布

**Files:**
- Stage only files changed by Tasks 1-3.

**Steps:**
1. 查看 `git diff`，确保不纳入工作区中既有的 Boss、关卡和 UI 修改。
2. 使用 `NightsReimu <nightsreimu@gmail.com>` 提交本轮文件。
3. 按仓库版本规则更新版本元数据，创建对应 tag。
4. 推送当前分支和 tag，使用 GitHub CLI 创建 release，发布说明使用 `docs/releases/v1.0.141.md`。
5. 读取远端 release 信息并报告提交、tag、release URL 与验证结果。
