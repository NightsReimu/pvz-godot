# 4-24 八坂神奈子素材

24 姿态 PNG 与道中、终末音乐均由用户提供。附件原名 `Purple-Haired Shrine Maiden Sprite Sheet.png`，原图按原始字节保存在 `art/source_sheets/kanako/kanako.png`，实际尺寸 **1536 × 1024 RGBA**，六列四行，alpha 范围 **0–254**。原图不去背、不重绘、不改色、不旋转、不镜像、不缩放。源目录的 `.gdignore` 阻止整张原图进入运行包；24 张独立帧是正常的运行资源。

| 素材 | 原文件名 | SHA256 |
| --- | --- | --- |
| 神奈子 PNG | `Purple-Haired Shrine Maiden Sprite Sheet.png` | `c44ba7f90de7c8ffd80bf03aa2bf39660c58e61544d56644f77da2df0e2b667b` |
| 道中 BGM | `4-24道中.mp3` | `cbb36dc946549decf88b244b22be882f06bae532f8983249de5fa9d2297db303` |
| 终末 BGM | `4-24终末.mp3` | `47f4098e29b6bf5eb9860d1a2464580883a11f59853b8948d87f255870887595` |

音乐保存为 `audio/bgm/touhou/4-24-stage.mp3`（2,123,695 字节）与 `audio/bgm/touhou/4-24-ending.mp3`（4,912,736 字节），与 Downloads 中的原文件字节一致，`loop=true`、`loop_offset=0`。本关没有道中 Boss：进入关卡即播放道中曲，神奈子登场时切到终末曲。

## 切分

`scripts/tools/import_kanako_sprite_cutouts.py` 复用此前 Sanae/Tengu 的归属提取：

- alpha > 32 的连通主体作为每个姿态的归属种子，24 个主体与 24 个位置一一对应；
- 第 1 行的红色箭矢、镜环弧光和第 4 行的赤色晶体越过 256px 网格。列分界取相邻主体包围盒的中点（逐行审核），脱离主体的小块特效按所在行、列归属；
- 另以 alpha > 240 的不透明身体单独校准足部锚点，地面以下的淡光不会移动 pivot；
- 最后恢复全部原图 RGBA，未删除任何淡像素。

全部 **991,829 个正 alpha 源像素**恰好归属一个帧。每帧只做整数平移，放到 **512 × 384** 公共画布，pivot **(256,320)**。站立帧（alpha ≥ 128）校准为 **IDLE_HEIGHT = 239，IDLE_BOTTOM = 320**。24 个 `.import` 使用无损 `compress/mode=0`，关闭 `fix_alpha_border`、预乘 alpha 与 mipmap。

| 源槽位 | 复核后的动作 | 运行时用途 |
| --- | --- | --- |
| 00–02 | 手持镜子站立 | idle |
| 03–05 | 站姿摆动 | walk / arrival / shift |
| 06–08 | 指出红色箭矢 | shot / arrow |
| 09–11 | 掌前展开镜环 | mirror / seal |
| 12–13 | 举镜、红色微光 | channel / prayer |
| 14–17 | 红色风之气旋环绕 | wind / storm / phase |
| 18 | 跪倒 | defeat（战损 22 → 跪倒 18） |
| 19 | 闭眼后仰 | hit（唯一受击帧） |
| 20–21 | 召出赤色晶体 | crystal / pillar |
| 22–23 | 战损的神威形态，镜光大盛 | final（最后符卡） |

`scripts/data/kanako_sprite_defs.gd` 的 `ACTIONS` 中，19 只用于 hit，18 只用于 defeat；施法循环不会取到跪倒或后仰帧，受击帧也不会混入 defeat。

## 复现与校验

```bash
cd scripts/tools
python3 import_kanako_sprite_cutouts.py \
  --sheet "~/Downloads/Purple-Haired Shrine Maiden Sprite Sheet.png" \
  --stage-bgm ~/Downloads/4-24道中.mp3 --ending-bgm ~/Downloads/4-24终末.mp3
python3 tests/kanako_sprite_cutouts_test.py
```

无参数运行会用仓库内保存的原图与 MP3 重建。测试校验源 SHA、24 帧 RGBA 唯一归属、主体与足部锚点、越过网格的箭矢/弧光/晶体归属、可复现重建、动作分组和两首音乐的 SHA。`manifest.json` 记录原图尺寸、布局、每帧来源范围、锚点、帧 SHA 与导入配置；`animation_source_record.json` 与共用的 `art/touhou_boss_animation_sources.json` 中的 Kanako 条目一致，既有 29 条记录未改动。

contact sheet 输出在 `output/kanako-4-24/assets/kanako-source-poses.png`（开发产物，不进入发行包）。
