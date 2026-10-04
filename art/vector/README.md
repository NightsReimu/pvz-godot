# 植物矢量造型

`plants/` 内为 149 种植物 SVG，以及破损、幼年、躲藏、咀嚼、布雷、倾倒、睁眼与出拳等状态。图形由可编辑路径、曲线和填色构成，不依赖位图描摹或外部字体。

运行 `python3 scripts/tools/build_vector_unit_art.py` 可从各植物的造型配置重建 SVG 和 `scripts/data/vector_plant_manifest.gd`。修改后用 Godot 导入，并运行 `tests/vector_art_assets_test.gd` 检查空图和裁切。

`VectorUnitArt` 共用缓存，战场、卡片、预览和图鉴使用同一资源；动画变换、透明度、受击闪白和状态切换仍由运行时驱动。火炬树桩保留原生实时火焰，坚果保龄球使用新坚果造型加标记。

## 融合造型

`fusions/` 内为全部固定融合形态。融合植物与基础植物使用同一套描边、渐变与五官：

1. `python3 scripts/tools/build_fusion_parts.py` 从基础植物生成部件库 `scripts/data/fusion_art_parts.gd`：每种材料的完整本体、按眼睛定位的头部锚点，以及它的标志嫁接部件（豌豆炮口、花瓣光环、菌盖、坚果护甲、投石臂、莲座等）。
2. `godot --headless --path . -s res://scripts/tools/build_universal_fusion_art.gd` 用 `scripts/ui/fusion_plant_morphology.gd` 组合出全部固定 SVG，并删除已不存在配方的旧模型；递归共生在运行时调用同一个组合器。
3. 重新导入后运行 `python3 tests/plant_fusion_art_test.py`、`tests/universal_fusion_art_test.gd` 与 `tests/fusion_model_identity_test.gd`，检查朝向、几何唯一性、可渲染性与轮廓差异。
