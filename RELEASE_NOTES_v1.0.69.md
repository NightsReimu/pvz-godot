# 植物大战僵尸 v1.0.69 - 普通关卡循环 BGM

## 改动

- 普通主线关卡新增循环背景音乐，按世界自动播放白天、黑夜、泳池、浓雾、屋顶、城市和火山主题曲。
- 东方 Boss 分支保留各自的道中和关底专属 BGM，不会被普通关卡音乐覆盖。
- 普通 BGM 会进入资源预热队列，减少进入战斗时的首次播放等待。

## 验证

- `tests/game_boot_test.gd` 覆盖 7 首普通 BGM 的存在、MP3 循环加载和世界路由。
- `tests/boss_asset_prewarm_test.gd`、`tests/rumia_level_test.gd`、`tests/letty_branch_test.gd` 验证 Boss 资源和东方专属 BGM 路由不受影响。
