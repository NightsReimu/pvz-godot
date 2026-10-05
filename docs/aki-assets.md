# 4-19 秋姐妹素材

原始图片和音乐均由用户提供。静叶与穰子各有 24 个姿态，按六列、四行依次编号为 00–23。原图已含透明通道；静叶图的透明像素虽然存有棕色 RGB，但不会作为可见背景导入。

源图保存在 `art/source_sheets/aki/`，由 `.gdignore` 排除运行时导入。该目录的 `manifest.json` 记录源文件 SHA256、逐帧原图范围、足部锚点、透明连通区域归属与音乐 SHA256。完整源图按原始字节保留。

运行时帧位于 `art/shizuha/` 与 `art/minoriko/`。导入脚本 `scripts/tools/import_aki_sprite_cutouts.py` 使用人物连通区域区分姿态，并按目视检查的间隔分配脱离人物的枫叶/法术颗粒。每个源图可见像素只属于一帧，保留原始 RGBA，不缩放、不镜像、不改色、不生成中间帧。所有帧使用已有东方角色的 512 × 384 画布与 `(256, 320)` 足部锚点。

静叶站立轮廓高 241 像素，穰子高 242 像素。`TouhouSpriteDefs` 在绘制时将两人的站立身高统一为 180 单位。技能姿态沿用同一缩放比例，保留大幅动作及法术拖尾。

| 素材 | 原文件名 | 导入路径 | SHA256 |
| --- | --- | --- | --- |
| 秋静叶 | `codex-clipboard-5d48d410-95cd-45ae-8aae-abb10500581b.png` | `art/source_sheets/aki/shizuha.png` | `950585dc85cf2dc19776448528a2131ad3b10ce1187c62feceaef5339c507709` |
| 秋穰子 | `codex-clipboard-2cbb7b13-1f4e-4562-a5e9-f905e009161b.png` | `art/source_sheets/aki/minoriko.png` | `ef3057727ba3ff42ce04e186a422a0b7001b25b599e9cb3864b82e8351ae3e5d` |
| 道中音乐 | `4-19道中.mp3` | `audio/bgm/touhou/4-19-stage.mp3` | `92460101bb56c2c7a89cb21be1af7779b56af53cad3a08fc2f3537ed56cdb113` |
| 终末音乐 | `4-19终末.mp3` | `audio/bgm/touhou/4-19-ending.mp3` | `ae995b9b0040685bea64e21466216c46ba881a17b511f44382ea877513247833` |

00–02 是站立，03–05 是移动/转位，06–08 是射击/扬叶，09–11 是蓄力，15–17 是展开法术，18–20 是强力法术，21–22 是败北动作，23 是恢复。静叶 12–13 为受击、14 为恢复；穰子 12–13 为欢欣动作，不能混入受击序列。穰子受击使用 21–22 的低头/跌坐动作，持续技能循环不会混入这两帧。

`python3 tests/aki_sprite_cutouts_test.py` 验证两组素材逐像素、逐 alpha 对应原图，48 帧只包含一个人物主体、每个源像素没有遗漏或重复、足部对齐、透明边距及音乐校验一致。`output/aki/*-source-poses.png` 为目视检查使用的 contact sheet，不进入运行时资源。

## Red maple battlefield

- Background: `art/backgrounds/autumn_maple_4_19.png`, generated with the built-in `image_gen.imagegen` tool (new image, opaque background), then copied without pixel editing.
- Generation prompt: a wide painted Japanese red maple forest clearing, scarlet/golden canopy on the outer edges, a clear warm sky, low wooden fence and distant mountains, a quiet flat dry ochre center for a 9×6 board, no fog, mist, water, characters, grid, text or UI.
- Dry planting squares, sparse cosmetic falling leaves, attack leaves and grain glyphs are drawn independently by the Godot scene/runtime.
- The supplied sprite sheets and BGM were not generated or redrawn.
