extends RefCounted

const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const Worlds = preload("res://scripts/data/world_data.gd")
const PAPER := Color("f8f5e9")
const INK := Color("263f36")
const MUTED := Color("71806a")
const GREEN := Color("326753")
const BORDER := Color("cbd1bd")
const BACKGROUND_TOP := Color("e8eddb")
const BACKGROUND_BOTTOM := Color("d3ddbd")
const WORLD_COPY := {
	"day": ["阳光下的第一道防线", "收集阳光，布置庭院。循着主线前进，或挑战隐藏在庭院深处的东方首领。", "阳光供给 / 庭院防守 / 东方支线"],
	"night": ["月光照亮蘑菇的舞台", "夜晚没有天降阳光。让蘑菇与夜生植物接管防线，穿过墓碑和不断逼近的尸潮。", "夜间作战 / 蘑菇阵容 / 墓碑"],
	"pool": ["水陆之间，另辟新路", "中央水路打开新的战线。搭建水陆阵容，迎接游泳僵尸，并探索深夜竹林的首领支线。", "六行战场 / 水陆协同 / 竹林支线"],
	"fog": ["看不见的地方，更要守住", "雾气掩盖了后院。用路灯探明前线，让三叶草与防空植物为队伍争取视野。", "浓雾视野 / 驱雾防空 / 后院泳池"],
	"roof": ["把防线延伸到天空", "在倾斜的红瓦屋顶安放花盆。投掷植物、伞叶与风向装置一起抵御空中的威胁。", "斜坡屋顶 / 花盆种植 / 投掷阵容"],
	"city": ["霓虹尽头，寒潮将至", "沿着街区和地铁轨道推进。用城市植物守住路口，再迎战席卷全城的暴风雪。", "霓虹街区 / 轨道地形 / 暴风雪"],
	"volcano": ["向熔岩深处进发", "在火山坡面建立防线。运用地热与蒸汽冷却，穿越岩浆火口，迎战熔岩尸王。", "地热蓄能 / 蒸汽冷却 / 熔岩终章"],
}


static func background(game: Control) -> void:
	ThemeLib.draw_gradient_rect_v(game, Rect2(0, 0, 1600, 900), BACKGROUND_TOP, BACKGROUND_BOTTOM)
	var texture: Texture2D = game._world_ui_texture("scene_atlas")
	if texture != null:
		game.draw_texture_rect_region(texture, Rect2(0, 0, 1600, 900), scene_region(texture.get_size(), 7, 1600.0 / 900.0), Color(1, 1, 1, 0.10))
	game.draw_line(Vector2(72, 156), Vector2(1516, 156), Color(GREEN, 0.13), 1, true)


static func label(game: Control, rect: Rect2, text: String, font_size: int = 22, color: Color = INK, center: bool = false) -> void:
	ThemeLib.draw_label(game, game.ui_font, rect, text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT)


static func plant(game: Control, kind: String, rect: Rect2) -> void:
	var texture: Texture2D = game._image2_texture("plants", kind)
	if texture != null:
		var dimensions := texture.get_size()
		dimensions *= minf(rect.size.x / dimensions.x, rect.size.y / dimensions.y)
		game.draw_texture_rect(texture, Rect2(rect.get_center() - dimensions * 0.5, dimensions), false)
	else:
		game._draw_card_icon(kind, rect.get_center())


static func draw_home_entry(game: Control, rect: Rect2, title: String, subtitle: String, accent: Color, entry_id: String, large: bool = false, disabled: bool = false) -> void:
	var hovered := rect.has_point(game._pointer_local_position()) and not disabled
	var surface := Rect2(rect.position - Vector2(0, 3 if hovered else 0), rect.size)
	if disabled:
		label(game, surface.grow_individual(-20, 0, -20, 0), "活动关卡    ·    敬请期待", 18, MUTED)
		return
	ThemeLib.draw_rounded_panel(game, surface, Color("e1ead1") if large else PAPER, GREEN if hovered else BORDER, 20, 0.16 if hovered else 0.1)
	var text_rect: Rect2 = game._home_entry_text_rect(entry_id)
	text_rect.position += surface.position - rect.position
	label(game, Rect2(text_rect.position, Vector2(text_rect.size.x, 48 if large else 38)), title, 40 if large else 28)
	game._draw_text_block(subtitle, Rect2(text_rect.position + Vector2(0, 62 if large else 48), Vector2(text_rect.size.x, text_rect.size.y - 48)), 21 if large else 18, MUTED, 6, 3)
	var kind := "peashooter" if large else String(game.HOME_ENTRY_ICON_KINDS.get(entry_id, "peashooter"))
	var icon_rect := Rect2(surface.end - Vector2(94, surface.size.y * 0.5 + 42), Vector2(76, 84))
	if large:
		icon_rect = Rect2(surface.position + Vector2(454, 62), Vector2(218, 232))
		game.draw_circle(icon_rect.get_center() + Vector2(0, 10), 104, Color("d0dfb9"))
		game.draw_arc(icon_rect.get_center(), 117, -0.9, 2.6, 48, Color(GREEN, 0.14), 1.5, true)
		plant(game, "sunflower", Rect2(surface.position + Vector2(416, 199), Vector2(86, 98)))
	else:
		game.draw_circle(icon_rect.get_center(), 40, Color(accent, 0.12))
	plant(game, kind, icon_rect)
	if large:
		label(game, Rect2(surface.position + Vector2(32, 209), Vector2(364, 30)), "开启冒险   →", 22, GREEN)
	elif surface.size.x > 500:
		label(game, Rect2(surface.position + Vector2(28, 151), Vector2(260, 28)), "进入挑战   →", 18, GREEN)


static func draw_home(game: Control) -> void:
	background(game)
	label(game, Rect2(72, 40, 720, 78), "植物大战僵尸", 54)
	label(game, Rect2(76, 119, 700, 28), "庭院冒险    /    今天，也要守住这片花园", 21, MUTED)
	var resource: Rect2 = game._home_resource_rect()
	ThemeLib.draw_rounded_panel(game, resource, PAPER, BORDER, 16, 0.06)
	game._draw_coin_icon(resource.position + Vector2(42, 37), 0.82)
	label(game, game._home_resource_coin_text_rect(), "金币 %d" % game.coins_total, 20, Color("89641d"))
	label(game, game._home_resource_drone_text_rect(), "无人机 %.0f" % game.base_drones, 19, GREEN)
	label(game, game._home_resource_status_rect(), game._home_update_status_line(), 13, MUTED)
	var rects: Dictionary = game._home_action_rects()
	draw_home_entry(game, rects.mainline, "主线冒险", "七个世界，一片属于你的庭院。\n选择植物，迎战新的首领。", Color("92b56a"), "mainline", true)
	var chips: Array = game._home_mainline_chip_rects()
	for i in range(chips.size()):
		var world: Dictionary = Worlds.all()[i]
		var chip := Rect2(chips[i])
		var unlocked: bool = game._is_world_unlocked(String(world.key))
		var active: bool = String(world.key) == game.current_world_key
		ThemeLib.draw_rounded_panel(game, chip, GREEN if active else Color(PAPER, 0.7), BORDER, 14, 0.0)
		label(game, chip, "%02d" % (i + 1), 24, PAPER if active else (GREEN if unlocked else MUTED), true)
	var progress: Rect2 = game._home_mainline_progress_rect()
	var done: int = game._completed_level_count()
	var total: int = maxi(game.Defs.LEVELS.size(), 1)
	label(game, Rect2(progress.position - Vector2(0, 36), Vector2(progress.size.x, 28)), "冒险进度     %d / %d 关" % [done, total], 18, GREEN)
	ThemeLib.draw_progress_bar(game, progress, float(done) / total, GREEN, Color("c6d4b4"), Color.TRANSPARENT)
	draw_home_entry(game, rects.daily, "每日关卡", "挑战今日作战，收集金币与强化材料。", Color("65a6b0"), "daily")
	draw_home_entry(game, rects.entertainment, "无尽挑战", "搭建长线阵容，迎接越来越强的尸潮。", Color("d68862"), "entertainment")
	var entries := [
		["base", "温室基建", "生产物资，安排植物驻守", Color("5b9f92")],
		["enhance", "植物强化", "培养阵容，提升植物属性", Color("c2a15d")],
		["gacha", "幻想召唤", "召唤植物，收集稀有伙伴", Color("a789bd")],
		["almanac", "庭院图鉴", "查阅植物、僵尸与首领", Color("8aa567")],
	]
	for entry in entries:
		draw_home_entry(game, rects[entry[0]], entry[1], entry[2], entry[3], entry[0])
	draw_home_entry(game, rects.events, "", "", GREEN, "events", false, true)


static func world_progress(game: Control, key: String) -> Vector2i:
	var indices: Array = game._visible_level_indices(key)
	var completed := 0
	for index in indices:
		if int(index) < game.completed_levels.size() and bool(game.completed_levels[int(index)]):
			completed += 1
	return Vector2i(completed, indices.size())


static func draw_world_select(game: Control) -> void:
	background(game)
	var actions: Dictionary = game._world_select_action_rects()
	game._draw_fancy_button(actions.home, "‹  主页", PAPER, BORDER, 22)
	label(game, game._world_select_title_text_rect(), "选择你的下一站", 40)
	label(game, game._world_select_title_subtitle_rect(), "探索七个世界，沿着自己的路线前进。", 20, MUTED)
	game._draw_fancy_button(game.WORLD_SELECT_ARROW_LEFT_RECT, "‹", PAPER, BORDER, 36)
	game._draw_fancy_button(game.WORLD_SELECT_ARROW_RIGHT_RECT, "›", PAPER, BORDER, 36)
	var selected: Dictionary = game._selected_world_data()
	var key := String(selected.key)
	var unlocked: bool = game._is_world_unlocked(key)
	for i in range(Worlds.all().size()):
		var world: Dictionary = Worlds.all()[i]
		var row: Rect2 = game._world_card_rect(i)
		var active: bool = i == game.world_select_index
		var available: bool = game._is_world_unlocked(String(world.key))
		var hovered := row.has_point(game._pointer_local_position())
		ThemeLib.draw_rounded_panel(game, row, GREEN if active else Color(PAPER, 0.94 if hovered else 0.65), GREEN if active else Color.TRANSPARENT, 14, 0.08 if active else 0.0)
		label(game, Rect2(row.position + Vector2(14, 16), Vector2(36, 34)), "%02d" % (i + 1), 21, Color("dfc991") if active else MUTED, true)
		label(game, game._world_select_card_text_rect(i), String(world.title), 23, PAPER if active else INK)
		var progress := world_progress(game, String(world.key))
		label(game, Rect2(row.position + Vector2(62, 39), Vector2(214, 20)), "已通关 %d / %d" % [progress.x, progress.y] if available else "通关前一世界解锁", 14, Color("c3d4b9") if active else MUTED)
		if active:
			label(game, Rect2(row.end - Vector2(36, 49), Vector2(24, 32)), "›", 28, PAPER, true)
	var hero := Rect2(416, 170, 1100, 530)
	ThemeLib.draw_rounded_panel(game, hero, PAPER, BORDER, 22, 0.12)
	var artwork: Texture2D = game._world_ui_texture("scene_atlas")
	var artwork_rect := Rect2(432, 186, 474, 498)
	if artwork != null:
		var region := scene_region(artwork.get_size(), game.world_select_index, artwork_rect.size.x / artwork_rect.size.y)
		game.draw_texture_rect_region(artwork, artwork_rect, region, Color.WHITE if unlocked else Color(0.7, 0.75, 0.72))
	else:
		ThemeLib.draw_rounded_panel(game, artwork_rect, selected.panel, selected.accent, 16)
	var badge := Rect2(450, 204, 150, 38)
	ThemeLib.draw_rounded_panel(game, badge, Color("203e34"), Color.TRANSPARENT, 10, 0.0)
	label(game, badge, "WORLD   %02d" % (game.world_select_index + 1), 16, PAPER, true)
	var copy: Array = WORLD_COPY[key]
	label(game, Rect2(948, 198, 530, 26), String(copy[0]), 19, GREEN)
	label(game, Rect2(948, 238, 532, 64), String(selected.title), 46)
	game._draw_text_block(String(copy[1]), Rect2(952, 321, 516, 104), 22, MUTED, 8, 3)
	label(game, Rect2(952, 426, 528, 30), "在这里遇见", 18, GREEN)
	var plants: Array = selected.plants
	var grid: Rect2 = game._world_select_card_preview_grid_rect(game.world_select_index)
	for i in range(plants.size()):
		var slot := Rect2(grid.position + Vector2(i * 106, 0), Vector2(94, 108))
		ThemeLib.draw_rounded_panel(game, slot, Color("edf0df"), Color.TRANSPARENT, 12, 0.0)
		plant(game, String(plants[i]), Rect2(slot.position + Vector2(12, 8), Vector2(70, 68)))
		label(game, Rect2(slot.position + Vector2(4, 78), Vector2(86, 24)), String(game.Defs.PLANTS[plants[i]].name), 14, INK, true)
	var progress := world_progress(game, key)
	label(game, Rect2(952, 601, 524, 32), "已通关 %d / %d 关" % [progress.x, progress.y] if unlocked else "通关前一世界后，即可开启旅程", 20, GREEN)
	ThemeLib.draw_progress_bar(game, Rect2(952, 648, 526, 10), float(progress.x) / maxi(1, progress.y), GREEN, Color("dee3cd"), Color.TRANSPARENT)
	ThemeLib.draw_rounded_panel(game, game._world_select_command_dock_rect(), Color(PAPER, 0.88), BORDER, 18, 0.06)
	game._draw_fancy_button(actions.update, game._update_action_text(), Color("e6ead9"), BORDER, 18)
	label(game, actions.update_info, game._update_status_line(), 17, MUTED)
	if game.update_state == "downloading":
		ThemeLib.draw_progress_bar(game, Rect2(272, 820, 364, 4), game.update_download_progress, GREEN, BORDER, Color.TRANSPARENT)
	game._draw_coin_icon(Vector2(1000, 794), 0.8)
	label(game, Rect2(1024, 776, 144, 36), str(game.coins_total), 20, Color("89641d"))
	game._draw_fancy_button(actions.enter, "进入地图   →" if unlocked else "尚未解锁", GREEN if unlocked else Color("87917f"), GREEN, 26)
	label(game, Rect2(430, 704, 1070, 28), String(copy[2]), 15, MUTED)


# The source is one 4 x 2 atlas; inset samples keep neighbouring scenes out of
# filtered edges. Crop in the renderer, preserving the original generated file.
static func scene_region(texture_size: Vector2, index: int, aspect: float = 1.0) -> Rect2:
	var tile := texture_size / Vector2(4, 2)
	var safe_index := clampi(index, 0, 7)
	var region := Rect2(Vector2(safe_index % 4, floori(safe_index / 4.0)) * tile, tile).grow(-1)
	var cropped := region.size
	if cropped.x / cropped.y > aspect:
		cropped.x = cropped.y * aspect
	else:
		cropped.y = cropped.x / aspect
	return Rect2(region.get_center() - cropped * 0.5, cropped)
