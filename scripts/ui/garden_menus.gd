extends RefCounted

const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const Worlds = preload("res://scripts/data/world_data.gd")
const PAPER := Color("fff3d6")
const INK := Color("263f36")
const MUTED := Color("786e50")
const GREEN := Color("326753")
const BORDER := Color("ac9b68")
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
	game.storybook_ui.background(game)


static func label(game: Control, rect: Rect2, text: String, font_size: int = 22, color: Color = INK, center: bool = false) -> void:
	ThemeLib.draw_label(game, game.ui_font, rect, text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT)


static func plant(game: Control, kind: String, rect: Rect2) -> void:
	# Unified procedural/SVG plant art everywhere; image2 plant icons are retired so the
	# hub, challenge menus and rain seeds all match the in-battle look.
	game._draw_card_icon(kind, rect.get_center(), clampf(rect.size.y / 52.0, 0.3, 3.0))


static func draw_home_entry(game: Control, rect: Rect2, title: String, subtitle: String, accent: Color, entry_id: String, large: bool = false, disabled: bool = false) -> void:
	var order := ["mainline", "daily", "entertainment", "base", "enhance", "gacha", "almanac", "events"]
	var surface: Rect2 = game.storybook_ui.surface(game, rect, "home:" + entry_id, disabled, order.find(entry_id) * 0.035)
	var motion: Dictionary = game.storybook_ui.state(game, rect, "home:" + entry_id, disabled)
	game.storybook_ui.panel(game, surface, PAPER, accent, 0.24)
	if disabled:
		label(game, surface.grow(-24), "活动关卡  ·  敬请期待", 18, MUTED)
		return
	var heading := Rect2(surface.position + Vector2(32, 36 if large else 30), Vector2(366 if large else surface.size.x - 128, 54 if large else 42))
	label(game, heading, title, 40 if large else 28)
	var subtitle_rect := Rect2(heading.position + Vector2(0, 66 if large else 54), Vector2(364 if large else minf(460, heading.size.x), 82 if large else 50))
	if not large and surface.size.x < 500:
		subtitle_rect.size = Vector2(190, 40)
	game._draw_text_block(subtitle, subtitle_rect, 21 if large else (16 if surface.size.x < 500 else 18), MUTED, 4, 2)
	var kind := "peashooter" if large else String(game.HOME_ENTRY_ICON_KINDS.get(entry_id, "peashooter"))
	var bob := sin(game.ui_time * 2.0 + order.find(entry_id)) * (2.5 + float(motion.hover) * 2.0)
	var icon_rect := Rect2(surface.end - Vector2(105, surface.size.y * 0.5 + 42 - bob), Vector2(78, 84))
	if large:
		var art_rect := Rect2(surface.position + Vector2(420, 32), Vector2(258, 205))
		game.storybook_ui.panel(game, art_rect.grow(7), Color("e6ddb8"), GREEN, 0.08)
		var artwork: Texture2D = game._world_ui_texture("scene_atlas")
		if artwork != null:
			game.draw_texture_rect_region(artwork, art_rect, scene_region(artwork.get_size(), game.WorldDataLib.index_of(game.current_world_key), art_rect.size.x / art_rect.size.y))
		icon_rect = Rect2(surface.position + Vector2(502, 60 + bob), Vector2(160, 154))
		game.storybook_ui.ambient(game, art_rect.grow(-10), game.current_world_key, 6)
		game.storybook_ui.nine_slice(game, "wood_plaque", Rect2(surface.position + Vector2(32, 201), Vector2(304, 40)))
		label(game, Rect2(surface.position + Vector2(48, 208), Vector2(272, 26)), "开启冒险  →", 20, PAPER, true)
	elif surface.size.x > 500:
		label(game, Rect2(surface.position + Vector2(32, 152), Vector2(270, 28)), "接受挑战  →", 19, GREEN)
	else:
		label(game, Rect2(surface.position + Vector2(32, 124), Vector2(176, 22)), "打开  →", 15, GREEN)
	game.draw_arc(icon_rect.get_center(), icon_rect.size.x * 0.46, game.ui_time * 0.25, game.ui_time * 0.25 + 4.8, 36, Color(accent, 0.28), 1.5, true)
	plant(game, kind, icon_rect)


static func draw_home(game: Control) -> void:
	background(game)
	game.storybook_ui.nine_slice(game, "wood_plaque", Rect2(72, 34, 712, 104))
	var logo: Texture2D = game.storybook_ui.texture("title_logo")
	if logo != null:
		game.draw_texture_rect_region(logo, Rect2(176, 33, 504, 104), Rect2(18, 142, 2140, 448))
	else:
		label(game, Rect2(108, 45, 638, 75), "植物大战僵尸", 49, PAPER, true)
	game.storybook_ui.panel(game, Rect2(132, 146, 592, 38), PAPER, BORDER, 0.10)
	label(game, Rect2(148, 151, 560, 27), "幻想庭院  ·  今天，也要守住这片花园", 18, GREEN, true)
	var resource: Rect2 = game._home_resource_rect()
	game.storybook_ui.panel(game, resource, PAPER, BORDER, 0.14)
	game._draw_coin_icon(resource.position + Vector2(42, 37), 0.82)
	label(game, game._home_resource_coin_text_rect(), "金币 %d" % game.coins_total, 20, Color("89641d"))
	label(game, game._home_resource_drone_text_rect(), "无人机 %.0f" % game.base_drones, 19, GREEN)
	label(game, game._home_resource_status_rect(), game._home_update_status_line(), 13, MUTED)
	game.storybook_ui.lantern(game, Vector2(866, -15), 172)
	var rects: Dictionary = game._home_action_rects()
	draw_home_entry(game, rects.mainline, "主线冒险", "七个世界，一片属于你的庭院。\n选择植物，迎战新的首领。", Color("92b56a"), "mainline", true)
	var chips: Array = game._home_mainline_chip_rects()
	for i in range(chips.size()):
		var world: Dictionary = Worlds.all()[i]
		var chip := Rect2(chips[i])
		var unlocked: bool = game._is_world_unlocked(String(world.key))
		var active: bool = String(world.key) == game.current_world_key
		var stamp := chip.grow(-3)
		game.storybook_ui.panel(game, chip, Color("dfe9c6") if active else PAPER, BORDER, 0.04)
		var atlas: Texture2D = game._world_ui_texture("scene_atlas")
		if atlas != null:
			game.draw_texture_rect_region(atlas, stamp, scene_region(atlas.get_size(), i), Color.WHITE if unlocked else Color(0.55, 0.57, 0.51))
		game.draw_circle(chip.position + Vector2(14, 14), 11, GREEN)
		label(game, Rect2(chip.position + Vector2(3, 3), Vector2(22, 22)), str(i + 1), 13, PAPER, true)
		if active:
			game.draw_rect(chip.grow(2), Color("d4ac4b"), false, 2.5, true)
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
	var event_rect: Rect2 = game.storybook_ui.surface(game, rects.events, "home:events", false, 0.2)
	game.storybook_ui.panel(game, event_rect, PAPER, BORDER, 0.12)
	label(game, Rect2(event_rect.position + Vector2(24, 12), Vector2(480, 40)), "庭院小游戏  ·  七种奇妙挑战", 24, GREEN)
	label(game, Rect2(event_rect.position + Vector2(526, 16), Vector2(676, 32)), "雨中落种 / 活体三消 / 隐形尸潮 / 更多玩法", 21, MUTED)
	label(game, Rect2(event_rect.end - Vector2(170, 52), Vector2(144, 40)), "开始游玩  →", 22, GREEN, true)


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
	game.storybook_ui.panel(game, game._world_select_title_panel_rect(), PAPER, BORDER, 0.18)
	label(game, game._world_select_title_text_rect(), "幻想乡旅行手册", 39)
	label(game, game._world_select_title_subtitle_rect(), "翻开下一页，挑选你的下一站。", 20, MUTED)
	game._draw_fancy_button(game.WORLD_SELECT_ARROW_LEFT_RECT, "‹", PAPER, BORDER, 36)
	game._draw_fancy_button(game.WORLD_SELECT_ARROW_RIGHT_RECT, "›", PAPER, BORDER, 36)
	var selected: Dictionary = game._selected_world_data()
	var key := String(selected.key)
	var unlocked: bool = game._is_world_unlocked(key)
	var atlas: Texture2D = game._world_ui_texture("scene_atlas")
	for i in range(Worlds.all().size()):
		var world: Dictionary = Worlds.all()[i]
		var row: Rect2 = game._world_card_rect(i)
		var active: bool = i == game.world_select_index
		var available: bool = game._is_world_unlocked(String(world.key))
		var surface: Rect2 = game.storybook_ui.surface(game, row, "world:" + str(i), false, i * 0.025)
		game.storybook_ui.panel(game, surface, Color("dbe8bc") if active else PAPER, GREEN if active else BORDER, 0.16)
		var stamp := Rect2(surface.position + Vector2(10, 9), Vector2(66, 50))
		if atlas != null:
			game.draw_texture_rect_region(atlas, stamp, scene_region(atlas.get_size(), i, stamp.size.x / stamp.size.y), Color.WHITE if available else Color(0.58, 0.6, 0.56))
		game.draw_circle(stamp.position + Vector2(10, 10), 9, GREEN)
		label(game, Rect2(stamp.position, Vector2(20, 20)), str(i + 1), 12, PAPER, true)
		var text_rect: Rect2 = game._world_select_card_text_rect(i)
		text_rect.position += surface.position - row.position
		label(game, text_rect, String(world.title), 22)
		var progress := world_progress(game, String(world.key))
		label(game, Rect2(surface.position + Vector2(92, 38), Vector2(194, 22)), "%d / %d  已通关" % [progress.x, progress.y] if available else "通关前一世界解锁", 13, MUTED)
		if active:
			game.draw_line(surface.position + Vector2(3, 14), Vector2(surface.position.x + 3, surface.end.y - 14), Color("c49a36"), 4, true)
	var hero := Rect2(416, 170, 1100, 530)
	game.storybook_ui.panel(game, hero, PAPER, BORDER, 0.26)
	# Bound pages, binding and stitching make the scene a travel journal.
	for i in range(4):
		game.draw_line(Vector2(1005 + i * 2, 191), Vector2(1005 + i * 2, 676), Color(0.38, 0.3, 0.16, 0.09 - i * 0.015), 1.0, true)
	var artwork_rect := Rect2(440, 194, 546, 482)
	game.storybook_ui.world_art(game, artwork_rect, game.world_select_index, Color.WHITE if unlocked else Color(0.7, 0.75, 0.72))
	game.draw_rect(artwork_rect, Color("746a43"), false, 2, true)
	var badge := Rect2(456, 210, 178, 38)
	game.storybook_ui.nine_slice(game, "wood_plaque", badge)
	label(game, badge.grow_individual(-12, -4, -12, -4), "WORLD  %02d" % (game.world_select_index + 1), 16, PAPER, true)
	game.storybook_ui.panel(game, Rect2(462, 602, 498, 52), Color(0.98, 0.95, 0.83, 0.94), BORDER, 0.08)
	label(game, Rect2(480, 610, 462, 36), String(WORLD_COPY[key][2]), 16, GREEN, true)
	var copy: Array = WORLD_COPY[key]
	label(game, Rect2(1030, 198, 456, 30), String(copy[0]), 18, GREEN)
	label(game, Rect2(1030, 243, 456, 62), String(selected.title), 42)
	game._draw_text_block(String(copy[1]), Rect2(1032, 320, 440, 104), 21, MUTED, 8, 3)
	label(game, Rect2(1032, 428, 448, 28), "本页的植物伙伴", 18, GREEN)
	var plants: Array = selected.plants
	var grid: Rect2 = game._world_select_card_preview_grid_rect(game.world_select_index)
	var step := grid.size.x / maxi(plants.size(), 1)
	for i in range(plants.size()):
		var slot := Rect2(grid.position + Vector2(i * step, 0), Vector2(step - 6, 108))
		game.storybook_ui.panel(game, slot, Color("e8eccd"), BORDER, 0.05)
		plant(game, String(plants[i]), Rect2(slot.position + Vector2(8, 8 + sin(game.ui_time * 1.7 + i) * 2), Vector2(slot.size.x - 16, 66)))
		label(game, Rect2(slot.position + Vector2(4, 78), Vector2(slot.size.x - 8, 24)), String(game.Defs.PLANTS[plants[i]].name), 13, INK, true)
	var progress := world_progress(game, key)
	label(game, Rect2(1032, 603, 446, 32), "已通关 %d / %d 关" % [progress.x, progress.y] if unlocked else "通关前一世界后，开启旅程", 20, GREEN)
	ThemeLib.draw_progress_bar(game, Rect2(1032, 650, 444, 10), float(progress.x) / maxi(1, progress.y), GREEN, Color("dee3cd"), Color.TRANSPARENT)
	game.storybook_ui.panel(game, game._world_select_command_dock_rect(), PAPER, BORDER, 0.18)
	game._draw_fancy_button(actions.update, game._update_action_text(), Color("e6ead9"), BORDER, 18)
	label(game, actions.update_info, game._update_status_line(), 17, MUTED)
	if game.update_state == "downloading":
		ThemeLib.draw_progress_bar(game, Rect2(272, 820, 364, 4), game.update_download_progress, GREEN, BORDER, Color.TRANSPARENT)
	game._draw_coin_icon(Vector2(1000, 794), 0.8)
	label(game, Rect2(1024, 776, 144, 36), str(game.coins_total), 20, Color("89641d"))
	game._draw_fancy_button(actions.enter, "进入地图  →" if unlocked else "尚未解锁", GREEN if unlocked else Color("87917f"), GREEN, 26)
	label(game, Rect2(438, 705, 1040, 26), "左侧挑选目的地  ·  左右键 / 滑动切换  ·  点击进入地图开始冒险", 15, PAPER, true)


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
