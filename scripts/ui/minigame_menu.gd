extends RefCounted

const Data = preload("res://scripts/data/minigame_defs.gd")
const Menus = preload("res://scripts/ui/garden_menus.gd")
const ThemeLib = preload("res://scripts/ui/game_theme.gd")

static func card_rect(index: int) -> Rect2:
	return Rect2(72 + (index % 4)*366,194 + (index / 4)*326,346,302)

static func back_rect() -> Rect2:
	return Rect2(1332,63,184,56)

static func click(game: Control, pos: Vector2) -> void:
	if back_rect().has_point(pos):
		game._enter_home_mode()
		return
	for i in range(Data.ENTRIES.size()):
		if card_rect(i).has_point(pos):
			game._start_minigame(String(Data.ENTRIES[i].id))
			return

static func draw(game: Control) -> void:
	Menus.background(game)
	Menus.label(game,Rect2(72,42,900,72),"庭院小游戏",48)
	Menus.label(game,Rect2(76,119,1130,28),"七种规则，七次新冒险    ·    植物卡片由关卡提供    ·    首通每项奖励 200 金币",21,Menus.MUTED)
	game._draw_fancy_button(back_rect(),"‹  返回主页",Menus.PAPER,Menus.BORDER,22)
	for i in range(Data.ENTRIES.size()):
		var entry: Dictionary = Data.ENTRIES[i]
		var rect := card_rect(i)
		var accent := Color(entry.color)
		var hovered := rect.has_point(game._pointer_local_position())
		ThemeLib.draw_rounded_panel(game,rect,Menus.PAPER,accent if hovered else Menus.BORDER,18,0.12 if hovered else 0.04)
		ThemeLib.draw_rounded_panel(game,Rect2(rect.position+Vector2(12,12),Vector2(322,82)),Color(accent,0.15),Color.TRANSPARENT,14,0)
		Menus.plant(game,entry.icon,Rect2(rect.position+Vector2(236,11),Vector2(82,84)))
		Menus.label(game,Rect2(rect.position+Vector2(24,22),Vector2(208,38)),entry.title,29)
		Menus.label(game,Rect2(rect.position+Vector2(24,61),Vector2(230,24)),entry.tag,17,Menus.GREEN)
		game._draw_text_block(entry.description,Rect2(rect.position+Vector2(24,110),Vector2(298,104)),21,Menus.INK,6,4)
		Menus.label(game,Rect2(rect.position+Vector2(24,220),Vector2(300,28)),entry.goal,19,Menus.GREEN)
		var cleared: bool = bool(game.minigame_clears.get(entry.id,false))
		Menus.label(game,Rect2(rect.position+Vector2(24,264),Vector2(180,26)),"✓ 已通关" if cleared else "首通 +200 金币",18,Menus.MUTED if cleared else Color("9b762a"))
		Menus.label(game,Rect2(rect.position+Vector2(204,258),Vector2(120,36)),"开始  →",23,Menus.GREEN,true)
	var last := card_rect(7)
	ThemeLib.draw_rounded_panel(game,last,Color("dce7cc"),Menus.BORDER,18,0)
	Menus.plant(game,"sunflower",Rect2(last.position+Vector2(116,22),Vector2(112,106)))
	Menus.label(game,Rect2(last.position+Vector2(20,134),Vector2(306,40)),"随时换一种玩法",26,Menus.GREEN,true)
	game._draw_text_block("暂停可重开或返回。\n底部「玩法」可查看规则，\n查看期间战斗暂停。",Rect2(last.position+Vector2(28,191),Vector2(290,92)),21,Menus.MUTED,8,3)
