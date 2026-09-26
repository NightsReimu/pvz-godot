# 植物矢量造型

`plants/` 内为 v1.0.138 重新设计的 144 种植物 SVG，以及破损、幼年、躲藏、咀嚼与布雷状态。图形由可编辑路径、曲线和填色构成，不依赖位图描摹或外部字体。

运行 `python3 scripts/tools/build_vector_unit_art.py` 可从各植物的造型配置重建 SVG 和 `scripts/data/vector_plant_manifest.gd`。修改后用 Godot 导入，并运行 `tests/vector_art_assets_test.gd` 检查空图和裁切。

`VectorUnitArt` 共用缓存，战场、卡片、预览和图鉴使用同一资源；动画变换、透明度、受击闪白和状态切换仍由运行时驱动。火炬树桩保留原生实时火焰，坚果保龄球使用新坚果造型加标记。
