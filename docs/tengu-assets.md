# 4-22 天狗素材

犬走椛、射命丸文的 24 姿态源图和道中、终末音乐均由用户提供。原始 PNG 在 `art/source_sheets/momiji/momiji.png` 和 `art/source_sheets/aya/aya.png` 按原始字节保存，不做去背、重绘、改色或缩放。两目录的 `.gdignore` 及现有导出策略阻止整张源图重复进入运行包；生成的 48 张独立帧仍是正常动态资源。

实际椛源图为 **1448 × 1086 RGBA**，文源图为 **1536 × 1024 RGBA**。两张图都有透明通道。文图看似棕色的背景位于 alpha 为零的像素中，不能按不透明背景处理。此次没有 alpha 阈值削除或 dematte，所有正 alpha 像素，包括最淡的剑光、白狼尾巴、团扇、枫叶和法术光晕，均保持原始 RGBA 并恰好归属一个输出帧。

`scripts/tools/import_tengu_sprite_cutouts.py` 沿用已检查的连通区域 ownership 提取：以各人物完整主体作为种子，按实际空隙分配脱离人物的法术碎片，并恢复原来的软透明边缘。列分界用于零散特效归属，不用固定格子切断人物、剑或扇子的完整连通轮廓。每帧只平移到公共 **512 × 384** 画布，足部锚点为 **(256, 320)**；不旋转、不镜像、不插值、不生成中间帧。source slot 00–23 与 runtime frame 00–23 一一对应。

48 张新 PNG 均采用 Godot 无损导入，不生成 mipmap、不预乘透明度、不限制尺寸。只对这批素材关闭默认的 `process/fix_alpha_border`：原生逐像素检查发现默认开关会重新着色 alpha 1–19 的软边，关闭后所有正 alpha 像素的原 RGBA 在原生纹理中也逐字节相同。importer 同时生成/维护这些 `.import` 设置，避免重建或重新导入改变原画边缘；现有角色的导入参数不受影响。

| 素材 | 原文件名 | SHA256 |
| --- | --- | --- |
| 椛 PNG | `codex-clipboard-0b40f1f8-3598-40e8-957f-b9ae4b369ec1.png` | `a80ccccf4fe9d52531157c64331d2e2bb38e8019a5a7e123046f96732a6fa1be` |
| 文 PNG | `codex-clipboard-611e1517-1764-4557-b34a-fc7a0c914d3a.png` | `5c0c78ad9b4c8500e838cf5202c2d5bc4cd1d630cfd17e6ba89cbc045e5ad913` |
| 道中 BGM | `4-22道中.mp3` | `a481deebfa6332d9dee5f35140c204d63aeabfcae60709e4f13684027d06f3f8` |
| 终末 BGM | `4-22终末.mp3` | `aaa28605e5e9c713a7f356a6024e86509774d5d79f93845902bf999ab27eb732` |

音频导入位置分别为 `audio/bgm/touhou/4-22-stage.mp3` 和 `audio/bgm/touhou/4-22-ending.mp3`，字节与用户文件一致，`.import` 保持 `loop=true` 和 `loop_offset=0`。具体播放时机由关卡控制：道中和椛期间播放 stage，文真实出场后才切换 ending。

`manifest.json` 记录源图尺寸、源 SHA、完整 layout、24 个源范围与足部锚点、每张输出帧的 SHA 及两首音乐 SHA。独立 `animation_source_record.json` 与共用来源登记结构兼容，供主代理接入。运行时只使用帧和 sprite defs，不读取被排除的源图 manifest。

| 角色 | `IDLE_HEIGHT` | `IDLE_BOTTOM` | 反应与施法分界 |
| --- | ---: | ---: | --- |
| 椛 | 245 | 320 | 12–14 作短暂防御/受击反应；21 仍是直立的持盾红枫光晕姿态；22–23 才是蹲伏，败退使用 22–23 |
| 文 | 236 | 319 | 12–13 受击、14 恢复；21 低头、22 伏地、23 恢复直立，败退使用 21–22 |

高度按站立帧 alpha ≥ 128 的原始不透明轮廓校准，所有姿态使用同一个站立比例。两套 `scripts/data/{momiji,aya}_sprite_defs.gd` 提供 `KIND`、`FRAME_FOLDER`、`FRAME_COUNT`、`CANVAS`、`PIVOT`、两个高度、`ACTIONS` 和 `frame_index(boss, time)`，可登记到共用 `SCARLET_ANIMATIONS`。`frame_index` 优先读取 `tengu_pose`，其次 `rumia_state`，死亡/短暂受击覆盖普通动作。

椛：idle 00–02，arrival/walk/guard 03–05，shot/sweep/patrol 06–08，sword/cross 09–11，farsight/channel/protect 15–17，final 18–21。文：idle 00–02，walk/dash/flight 03–05，shot/branch/cross 06–08，channel/camera/photo 09–11，wind/veil/cyclone/blockade 15–17，final/survival 18–20 和直立恢复 23。相机闪光、风隐身、冲刺残影及风场由独立运行时表现，不重绘素材或机械旋转整个人物。

无参数运行 importer 会从仓库保存的原图和 MP3 重建帧。`python3 tests/tengu_sprite_cutouts_test.py` 校验两份固定源 SHA、48 帧原 RGBA 的唯一归属、完整剑/尾/扇/枫叶、没有相邻人物混入、透明边距、足部锚点、实际动作范围和两首原音频 SHA。独立 contact sheets 位于 `output/tengu-4-22/assets/{momiji,aya}-source-poses.png`，仅作为检查证据。

原生检查记录位于同目录的 `native-assets.log`，确认 48 张无损纹理的每个正 alpha 像素、所有 action 取帧及死亡姿态，且两首 MP3 在只打包 `.import`/`.mp3str`、不含原 MP3 的 PCK 中实际播放并保持原字节。`native-author-poses.png` 提供棋盘格透明背景上的原生渲染核对；`native-import-red.log` 记录默认 alpha 边缘处理的有效 48 项失败，关闭这批素材边缘改色后全部通过。
