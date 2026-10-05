# 4-20 键山雏素材

角色原图与两首音乐均由用户提供。角色图是含透明通道的 1536 × 1024 PNG，六列、四行共 24 个姿态。背景 RGB 的绿色/灰色不作为可见背景导入。

原图在 `art/source_sheets/hina/hina.png` 按原始字节保存，`.gdignore` 阻止整张图重复成为运行时资源。`manifest.json` 记录每帧源图范围、足部锚点、透明连通区域归属及所有音频 SHA256。`animation_source_record.json` 提供与共用 `art/touhou_boss_animation_sources.json` 相同结构的独立登记项。

`scripts/tools/import_hina_sprite_cutouts.py` 从独立人物连通区域定位姿态，按检查过的空隙分配脱离人物的厄火与法术拖尾，将原始 RGBA 完整复制到公共 512 × 384 画布。所有帧共用 `(256, 320)` 足部锚点，不缩放、不镜像、不改色、不重绘、不旋转。每个可见源像素只属于一个运行时帧。

`art/hina/frame_00.png` 至 `frame_23.png` 按原图顺序编号。站立不透明轮廓高 233 像素，最下方不透明像素的下一行是 319；含半透明边缘的人物主体足部锚点仍为 320。使用站立统一缩放时，参数为 `IDLE_HEIGHT = 233.0`、`IDLE_BOTTOM = 319.0`。

| 素材 | 原文件名 | 导入路径 | SHA256 |
| --- | --- | --- | --- |
| 键山雏原图 | `codex-clipboard-976fde1a-1b48-4854-b784-fdc8e73dc680.png` | `art/source_sheets/hina/hina.png` | `bb03ae975a2b16390bdfadc784b883d3f5bede625337c778b08c7f970b640784` |
| 道中 BGM | `4-20道中.mp3` | `audio/bgm/touhou/4-20-stage.mp3` | `50b4c2344cd13156dea9a77fe2ffe7b14d3af6a63bfa70c458a4a3de0162c576` |
| 终末 BGM | `4-20终末.mp3` | `audio/bgm/touhou/4-20-ending.mp3` | `809eea7c6047508b1be27770121dc6533cd78ac77f925747b37259cf0cbcaf2c` |

姿态映射位于 `scripts/data/hina_sprite_defs.gd`。00–02 是站立，03–05 是转位，06–08 是挥杖/扬裙旋转，09–11 是蓄力/净化，12–13 是受击、14 是恢复，15–17 是厄火法术，18–20 是大型旋转法术，21–22 是低头/倒地，23 是恢复施法。角色始终使用原素材的直立脸部，旋转表现来自原本绘制的扬裙动作以及运行时单独绘制的厄火/丝带环绕。

两首 MP3 导入均开启 `loop=true`；关卡负责按道中/终末阶段分别切换音乐。无参数运行 importer 可以使用仓库原图、音乐重建帧。`python3 tests/hina_sprite_cutouts_test.py` 验证源图固定 SHA256、24 帧所有原始 RGBA 像素恰好保留一次、无相邻人物混入、透明边距与足部稳定以及两首音频固定 SHA256。

目视核对 contact sheet 保存在 `output/hina/source-poses.png`，不参与运行时资源。

## 山林背景

`art/backgrounds/hina_mountain_4_20.png` 使用内置 imagegen 生成，原图保留在 `/Users/hecrereed/.codex/generated_images/01a109cb-14cc-7030-8f1e-b7f3d00a17c3/exec-a4a5c67f-6339-4251-8080-7784321b85af.png`。山坡、上山石阶与树林在边缘留出中央台地；六行土石格和稀疏飘叶由游戏绘制。
