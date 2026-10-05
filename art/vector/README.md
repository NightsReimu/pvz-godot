# 植物矢量造型

`plants/` 内为 149 种植物 SVG，以及破损、幼年、躲藏、咀嚼、布雷、倾倒、睁眼与出拳等状态。图形由可编辑路径、曲线和填色构成，不依赖位图描摹或外部字体。

运行 `python3 scripts/tools/build_vector_unit_art.py` 可从各植物的造型配置重建 SVG 和 `scripts/data/vector_plant_manifest.gd`。修改后用 Godot 导入，并运行 `tests/vector_art_assets_test.gd` 检查空图和裁切。

`VectorUnitArt` 共用缓存，战场、卡片、预览和图鉴使用同一资源；动画变换、透明度、受击闪白和状态切换仍由运行时驱动。火炬树桩保留原生实时火焰，坚果保龄球使用新坚果造型加标记。

## 融合造型

`fusions/` 内为全部固定融合形态。每个融合都画成一株新植物：一种材料提供体型，颜色最鲜明的搭档为它换皮并铺上纹理，其余材料长出相连的饰物或武器，再加上搭档的表情和元素徽记。

1. `python3 scripts/tools/build_fusion_parts.py` 测量基础植物，生成 `scripts/data/fusion_art_parts.gd`：
   - `fusion_anatomy.py`：可换色皮肤（模板色 `{sN}` 与遮罩）、眼睛、嘴、炮口和纹理范围；底座与叶片标为 `data-part="base"`，不会被换色。
   - `fusion_traits.py`：每种材料的体型、材质强度、纹理、表情和元素。
   - `fusion_accessories.py`：饰物（头冠、光环、头盔、尾巴、底座等）与嘴部武器，以及已有炮口时的改装方式。
2. `godot --headless --path . -s res://scripts/tools/build_universal_fusion_art.gd` 用 `scripts/ui/fusion_plant_morphology.gd` 组合全部固定 SVG，并删除已不存在配方的旧模型；纹理由 `fusion_patterns.gd` 绘制，表情、炮口改装和元素徽记由 `fusion_flair.gd` 绘制。递归共生在运行时调用同一个组合器。
3. 重新导入后运行 `python3 tests/plant_fusion_art_test.py`、`tests/universal_fusion_art_test.gd`、`tests/fusion_model_identity_test.gd` 与 `tests/fusion_anatomy_test.gd`，检查朝向、几何唯一性、可渲染性、轮廓差异和解剖规则。
