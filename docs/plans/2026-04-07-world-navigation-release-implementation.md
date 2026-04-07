# 世界切换与移动端选关优化 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 让世界选择与世界地图在桌面和手机上都具备顺滑拖拽、惯性和吸附体验，并让 release 构建统一更新项目与 APK 版本号。

**Architecture:** 在 `scripts/game.gd` 中引入统一的横向拖拽状态与速度衰减模型，分别驱动世界卡片滚动和地图滚动；在 release workflow 中抽取版本戳逻辑，同步更新 `project.godot` 和 `export_presets.cfg`。测试先行，覆盖输入行为与版本同步。

**Tech Stack:** Godot 4 GDScript, headless SceneTree tests, GitHub Actions, Python stamping helper embedded in workflow

---

### Task 1: 世界页与地图页输入测试

**Files:**
- Create: `tests/world_navigation_test.gd`
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**

- 断言世界页支持 `InputEventScreenTouch` / `InputEventScreenDrag` 拖拽后改变滚动值。
- 断言松手后会吸附到有效世界索引。
- 断言地图页拖拽会修改目标滚动值，并在后续 `_update_map_scroll` 中继续前进。

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/world_navigation_test.gd`

Expected: FAIL，因为当前没有手机触摸拖拽状态。

**Step 3: Write minimal implementation**

- 给 `scripts/game.gd` 增加触摸拖拽状态、速度采样与松手吸附逻辑。
- 世界页直接更新 `world_select_scroll`，再通过收尾逻辑写回 `world_select_index`。
- 地图页维护独立的滚动速度，支持惯性衰减。

**Step 4: Run test to verify it passes**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/world_navigation_test.gd`

Expected: PASS

**Step 5: Commit**

```bash
git add tests/world_navigation_test.gd scripts/game.gd docs/plans/2026-04-07-world-navigation-release-design.md docs/plans/2026-04-07-world-navigation-release-implementation.md
git commit -m "feat: improve world navigation interactions"
```

### Task 2: 页面切换与滚动缓动优化

**Files:**
- Modify: `scripts/game.gd`

**Step 1: Write the failing test**

- 补充同一测试文件，断言页面切换进度推进后会在完成前保持激活，到阈值后才结束。
- 断言地图滚动在有速度时会持续衰减而不是一步跳停。

**Step 2: Run test to verify it fails**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/world_navigation_test.gd`

Expected: FAIL，因为当前只有简单线性/lerp 行为。

**Step 3: Write minimal implementation**

- 抽出缓动辅助函数。
- 页面切换使用 smoothstep 风格推进。
- 地图滚动引入速度衰减和边界夹紧。

**Step 4: Run test to verify it passes**

Run: `godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/world_navigation_test.gd`

Expected: PASS

**Step 5: Commit**

```bash
git add scripts/game.gd tests/world_navigation_test.gd
git commit -m "feat: smooth world transitions and map scrolling"
```

### Task 3: Release 版本号同步

**Files:**
- Modify: `.github/workflows/release.yml`
- Modify: `export_presets.cfg`
- Test: `tests/release_workflow_test.py`

**Step 1: Write the failing test**

- 让 workflow 测试验证版本戳逻辑会同步更新：
  - `project.godot` 的 `config/version`
  - Windows/macOS 字段
  - Android `version/name`
  - Android `version/code`

**Step 2: Run test to verify it fails**

Run: `python3 tests/release_workflow_test.py`

Expected: FAIL，因为当前 workflow 不会更新 `export_presets.cfg`。

**Step 3: Write minimal implementation**

- 扩展 workflow 里的 stamping 脚本。
- 用统一算法从 release tag 生成 Android `versionCode`。
- 把仓库里的 `export_presets.cfg` 默认值也抬到新的 release 版本，避免本地导出继续展示旧号。

**Step 4: Run test to verify it passes**

Run: `python3 tests/release_workflow_test.py`

Expected: PASS

**Step 5: Commit**

```bash
git add .github/workflows/release.yml export_presets.cfg tests/release_workflow_test.py
git commit -m "build: sync export preset versions for releases"
```

### Task 4: 回归验证与发版

**Files:**
- Modify: `project.godot`

**Step 1: Run focused regression tests**

Run:

```bash
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/world_navigation_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/update_ui_test.gd
godot --headless --path /Users/hecrereed/project/pvz/pvz-godot -s res://tests/game_boot_test.gd
python3 tests/release_workflow_test.py
```

Expected: all PASS

**Step 2: Bump release version**

- 更新 `project.godot` 和 `export_presets.cfg` 的默认版本到下一版。
- 生成对应 git commit 与 tag。

**Step 3: Push and publish**

Run:

```bash
git push origin main
git tag v1.0.1
git push origin v1.0.1
gh release view v1.0.1 || true
```

Expected: main 和 tag 推送成功，GitHub Actions 自动打包 release。

**Step 4: Verify release artifacts**

Run:

```bash
gh run view --workflow Release --limit 1
gh release view v1.0.1 --json assets,url,name,tagName
```

Expected: Windows/macOS/Web/APK 产物全部挂载
