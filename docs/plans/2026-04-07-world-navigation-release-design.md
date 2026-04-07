# 世界切换与移动端选关优化设计

## 目标

优化世界选择页和世界地图页的动画与滑动体验，让切换更顺、更像原生触屏界面；同时统一发布版本号，确保 GitHub Release 的 APK 与桌面端版本信息一致。

## 现状

- 世界选择页目前主要依赖 `InputEventPanGesture`，在手机触屏环境下缺少 `InputEventScreenTouch` / `InputEventScreenDrag` 的拖拽逻辑。
- 世界切换、地图滚动和页面切换都采用简单的 `lerpf`，速度固定，缺少拖拽中的跟手反馈、松手后的惯性和回弹。
- Release workflow 只给 `project.godot` 写版本号，`export_presets.cfg` 里的 Windows/macOS/Android 版本字段仍会停在旧值，导致 APK 版本信息不同步。

## 方案

### 1. 世界页触摸拖拽

在世界选择页加入触摸会话状态：

- 按下时记录触点起点、初始滚动值、最近速度采样。
- 拖动时直接驱动 `world_select_scroll`，而不是只改 `world_select_index`，让卡片跟手移动。
- 松手后根据速度和当前位置自动吸附到最近世界卡片，并带一段短惯性。

这样桌面滚轮、触控板与手机触屏会共用同一套“目标滚动 + 平滑收敛”模型。

### 2. 地图页横向拖拽与惯性

在世界地图页加入横向拖拽：

- 手机上可直接左右拖动地图。
- 松手后保留有限惯性并在边界处夹紧，避免一下子停死。
- 仍保留左右箭头和触控板手势，作为补充输入。

### 3. 页面切换动画优化

保留现有页面切换结构，但把进度推进和绘制偏移改成更平滑的缓动曲线：

- 切换页采用 ease-out / smoothstep 样式，而不是匀速推进。
- 世界卡片缩放和位置继续使用 `world_select_scroll`，但增加拖拽时的弹性感和更柔和的收尾。
- 地图滚动改成“带阻尼的速度衰减”而非简单固定比例 lerp。

### 4. 发布版本统一

Release workflow 在构建前统一推导：

- 显示版本号，例如 `1.0.1`
- Android `versionCode`

并同步写入：

- `project.godot`
- `export_presets.cfg` 中的 Windows/macOS 版本字段
- `export_presets.cfg` 中的 Android `version/name` 与 `version/code`

`versionCode` 采用数值化方案，确保每次 release 单调递增，避免安装更新时被系统拒绝。

## 验证

- 新增 UI/输入测试，覆盖世界页拖拽、地图页拖拽和吸附行为。
- 新增 release workflow 版本戳测试，覆盖 `project.godot` 与 `export_presets.cfg` 同步更新。
- 运行现有启动与更新 UI 测试，确认没有引入回归。
