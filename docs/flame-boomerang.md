# 烈焰回旋镖

v1.0.106 将火炬树桩的点燃范围扩展到回旋镖类投射物。`boomerang_shooter` 与 `cluster_boomerang` 产生的投射物仍使用 `boomerang` 运动类型，因此出回、命中去重、回程标记和反射处理保持一致；经过同一行的火炬树桩时额外写入 `flame_boomerang` 标记。

点燃后的回旋镖获得 1.8 倍直接伤害、3.2 秒灼烧、按伤害比例计算的灼烧 DPS，以及 12 像素的可读碰撞半径。首次命中会在主目标周围产生火焰溅射，邻近僵尸也会获得较弱的灼烧；回程命中只使用回程伤害，不会二次点燃或重复放大。

绘制层保留原来的旋转弧线，并增加热核、分层拖尾和浮动火星。点燃瞬间会产生短促橙红脉冲并复用火焰音效。

验证入口：

- `godot --headless --path . --script tests/flame_boomerang_test.gd`
- `godot --headless --path . --script tests/torchwood_amber_test.gd`
- `godot --path . --script scripts/tools/capture_flame_boomerang.gd`
