# 4-21 河城荷取素材

角色原图与两首音乐均由用户提供。角色图是含透明通道的 1536 × 1024 像素风 PNG，六列、四行共 24 个姿态。

原图在 `art/source_sheets/nitori/nitori.png` 按原始字节保存，`.gdignore` 阻止整张图重复成为运行时资源。原图整张带有一层 alpha 1–9 的近乎不可见的底雾（235,499 个像素）；导入时只把 alpha < 10 的像素清零，派生的归属图写在被忽略的 `output/nitori/nitori-haze-cleared.png`，不提交。其余像素的 RGBA 原样复制。`manifest.json` 记录每帧源图范围、足部锚点、连通区域归属、清除阈值与所有音频 SHA256；`animation_source_record.json` 提供独立登记项。

`scripts/tools/import_nitori_sprite_cutouts.py` 从独立人物连通区域定位姿态，在检查过的空白竖条处划分归属。08 号水弹和 20 号大水炮越过原图网格线，仍归属各自施法帧。所有帧共用 512 × 384 画布和 `(256, 320)` 足部锚点，不缩放、不镜像、不改色、不重绘、不旋转；每个可见源像素只属于一个运行时帧。

`art/nitori/frame_00.png` 至 `frame_23.png` 按原图顺序编号。站立不透明轮廓高 233 像素，最下方不透明像素的下一行是 319，即 `IDLE_HEIGHT = 233.0`、`IDLE_BOTTOM = 319.0`。

| 素材 | 原文件名 | 导入路径 | SHA256 |
| --- | --- | --- | --- |
| 河城荷取原图 | `Pixel-Art Water Mage Sprite Sheet.png` | `art/source_sheets/nitori/nitori.png` | `02722d6496da48c2963d6415548a3c41420e3869dd86bfe5e6a70f61901220a4` |
| 道中 BGM | `4-21道中.mp3` | `audio/bgm/touhou/4-21-stage.mp3` | `d053d5aaccde2d6621181027df9e6e635d1eb74103d08bd3951c1f9bb63ce181` |
| 终末 BGM | `4-21终末.mp3` | `audio/bgm/touhou/4-21-ending.mp3` | `57c63b137853fa7f25c1c3cf2bb39e3bdd9ffa29f84b61513b8850d975b50985` |

姿态映射位于 `scripts/data/nitori_sprite_defs.gd`：00–02 站立与眨眼，03–05 迈步，06–08 水枪蓄力与水弹，09–11 出拳/投掷（黄瓜、延展手臂），12–14 双手引水，15–17 受击与恢复，18–20 大型水术（20 为整束水炮），21–22 跪倒，23 恢复后的水环架势。光学迷彩、雨与水环是运行时单独绘制的图层，不改动人物像素。

两首 MP3 导入均开启 `loop=true`；道中曲覆盖弱化荷取，只有终末荷取登场才切换终末曲。无参数运行 importer 会用仓库内原图与音乐重建帧。`python3 tests/nitori_sprite_cutouts_test.py` 验证原图固定 SHA256、底雾只按阈值清除、24 帧原始像素恰好保留一次、两束水炮不离开施法帧、透明边距与足部稳定，以及两首音频哈希。

## 玄武之泽背景

`art/backgrounds/nitori_waterfall_4_21.png` 由 `scripts/tools/build_nitori_waterfall_background.py` 确定性程序绘制（固定随机种子，无外部素材）。「玄武」取自玄武岩：六角柱状节理的玄武岩崖围出湿石板岸台，主瀑布落在 Boss 所在的右侧峡谷，左岸有河童水车和开黄花的黄瓜藤，底部是溪流。只在瀑潭附近有轻微水雾，没有遮挡视野的浓雾；动态雨丝、雨点涟漪和瀑布水纹由 `scripts/ui/nitori_waterfall_scene.gd` 在游戏中绘制。
