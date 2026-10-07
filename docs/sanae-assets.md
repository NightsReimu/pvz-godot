# 4-23 东风谷早苗素材

24 姿态 PNG 与道中、终末音乐均由用户提供。附件原名 `codex-clipboard-54323c73-a85d-4ab9-bff3-2c6a08098cba.png`，原图按原始字节保存在 `art/source_sheets/sanae/sanae.png`，实际尺寸 **1536 × 1024 RGBA**，六列四行，alpha 范围为 **0–254**。原图不去背、不重绘、不改色、不旋转、不镜像、不缩放。源目录的 `.gdignore` 阻止整张原图重复进入运行包；24 张独立帧仍是正常动态资源。

| 素材 | 保存路径或原文件名 | SHA256 |
| --- | --- | --- |
| 早苗 PNG | `codex-clipboard-54323c73-a85d-4ab9-bff3-2c6a08098cba.png` | `a0955b390603c05b7fa4d7198c7328d15e4c7539699d0bb73692f29fdde2167b` |
| 道中 BGM | `4-23道中.mp3` | `27c69211c67603193016c4dae73f062098e10a0127af694c43709cb013295ffa` |
| 终末 BGM | `4-23终末.mp3` | `503044ad980a47f05801eb14259f275a87da35fb5200f732364cb84636f92e97` |

音频分别保存为 `audio/bgm/touhou/4-23-stage.mp3`（5,966,411 字节）与 `audio/bgm/touhou/4-23-ending.mp3`（5,633,716 字节），与 Downloads 中用户原文件的 SHA 完全一致，保持 `loop=true`、`loop_offset=0`。此素材导入不决定道中与终末切歌时机，播放切换由关卡控制。

`scripts/tools/import_sanae_sprite_cutouts.py` 使用经过复核的区域归属提取。源图中的淡透明桥接、跨行法术边缘与最后一行 19/20 的重叠蓝弧，使单一 alpha 阈值无法同时获得正确的特效归属和足部锚点。此次以 alpha > 32 的丰富主体/特效作归属种子，另以 alpha > 240 的主要身体轮廓校准足部。三个很小的分割矩形只作用于种子掩码，最后恢复全部原图 RGBA；没有以阈值删除淡像素。

最后一行 19 的绿色头发与 20 的蓝白前景弧在原图中实际相交。复核区域 `[460,850,503,910]` 中绿色头发仍归 19，较短上部区域 `[460,850,503,888]` 的蓝白弧归 20。颜色只用于判断归属，不改变像素；较低的蓝色卷曲仍保留在 19。该分配同时修正 15 的绿色风效误落到上一行 09 足下、19 的蓝弧误落到 13 足下的问题。

全部 **918,901 个正 alpha 源像素**均按原始 RGBA 恰好归属一个帧，包括御币、绿色头饰、长发、最淡的蓝绿光晕。24 个完整身体各自独立，不串入相邻人物。每帧仅整数平移到 **512 × 384** 公共画布，pivot 为 **(256,320)**；不插值、不生成中间帧。source slot 00–23 与 runtime frame 00–23 一一对应。站立帧以 alpha ≥ 128 的轮廓校准：**IDLE_HEIGHT = 231，IDLE_BOTTOM = 321**；所有姿态以同一站立比例绘制，主要身体足部统一落在 y=320。

24 帧 `.import` 使用无损压缩 `compress/mode=0`，关闭 `fix_alpha_border`、预乘 alpha 与 mipmap，不限制尺寸。Godot 的默认边缘修补会改变淡透明像素的 RGB，因此保持关闭，保证运行时纹理也保存原 RGBA。

| 源槽位 | 复核后的动作 |
| --- | --- |
| 00–02 | 直立待机，02 闭眼 |
| 03–05 | 持御币行走、转移与入场 |
| 06–08 | 举御币、蓝色挥击 |
| 09–11 | 竖起御币、聚集蓝色光点与光球 |
| 12–14 | 短暂受击、低头反应与恢复 |
| 15–17 | 完整绿色风效，适合风/青蛙/阶段施法 |
| 18–20 | 举御币与完整蓝色大弧，终末施法 |
| 21–22 | 低头、跪坐败退 |
| 23 | 恢复直立，不能混作倒地 |

`scripts/data/sanae_sprite_defs.gd` 的 `ACTIONS` 将 idle、walk/arrival/shift、shot/sweep、stars/prayer、frog/wind、phase、final、hit、defeat 分开；`frame_index` 在死亡时只取 21–22，施法不会取短暂受击或倒地帧。人物保持直立，法术拓扑和额外效果由独立运行时表现。

`manifest.json` 保存原图尺寸、源 SHA、布局、24 个源范围、足部锚点、每帧 SHA、导入配置、重叠归属复核与音乐 SHA。独立 `animation_source_record.json` 与共用 `art/touhou_boss_animation_sources.json` 的 Sanae 条目一致。此次未改变既有 28 个角色来源记录，仅追加 Sanae 条目。

无参数运行 importer 会用仓库保存的原图与 MP3 重建全部帧。`python3 tests/sanae_sprite_cutouts_test.py` 校验固定源 SHA、24 帧 RGBA 唯一归属、主体/足锚/透明边界、跨行风效与重叠头发归属、可复现重建、动作分组与两个原音频 SHA。最初归属问题的有效失败日志为 `output/sanae-4-23/assets/source-contract-red.log`，修正后的通过日志为 `source-contract-green.log`；最终 contact sheet 为 `sanae-source-poses.png`。

原生验证使用独立 `native_asset_probe.gd`，比较 24 张 Godot 导入纹理的完整 RGBA8 字节，遍历每组实际取帧并检查死亡姿态，实际播放两首原 MP3 与循环参数。`native-import-before.log` 记录重新导入前 17 张旧缓存纹理的有效失败，重新导入后结果记录于 `native-assets.log` 和 `native-asset-report.json`，原生 contact sheet 为 `native-sanae-poses.png`。上述验证产物均位于 `output/sanae-4-23/assets`，仅作为开发证据，不属于运行资源。
