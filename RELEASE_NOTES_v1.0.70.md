# 植物大战僵尸 v1.0.70 - 妖梦旋转楼梯 Boss 关

## 改动

- 第二章节新增东方妖妖梦五面支线 `2-29`，完成 `2-28` 后解锁。
- 新增旋转楼梯场景 `spiral_staircase`，表现月夜白玉楼石阶、幽灵灯、樱花和剑气光影。
- 新增魂魄妖梦 Boss：高速瞬移、第一列剑光斩击、半灵环绕、怨灵魅惑和多段终幕剑气。
- 妖梦专属移动不会触发小推车或进家失败，威胁来自符卡、剑气和怨灵机制。
- 接入 `2-29` 道中与终末 BGM，妖梦登场时才切换终末曲。
- 拆分并清理妖梦 8 帧 Boss 素材，接入图鉴、预热、绘制和 image2 排除链路。

## 验证

- 新增 `tests/youmu_branch_test.gd` 覆盖关卡配置、解锁、BGM、素材、图鉴、技能、第一列瞬移和怨灵魅惑。
- 扩展 `tests/boss_asset_prewarm_test.gd`、`tests/special_modes_test.gd`、`tests/image2_asset_pipeline_test.gd`、`tests/boss_sprite_cleanup_test.gd` 和 `tests/image2_asset_manifest_test.py` 覆盖妖梦资源与旋转楼梯预览。
