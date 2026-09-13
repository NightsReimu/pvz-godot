extends RefCounted

const ThemeLib = preload("res://scripts/ui/game_theme.gd")
const Menus = preload("res://scripts/ui/garden_menus.gd")
const Data = preload("res://scripts/data/minigame_defs.gd")

static func footer_rect(game: Control) -> Rect2:
	var safe: Rect2 = game._viewport_safe_rect()
	return Rect2(safe.position.x+16,safe.end.y-50,safe.size.x-32,44)

static func help_rect(game: Control) -> Rect2:
	var footer := footer_rect(game)
	return Rect2(footer.end-Vector2(72,44),Vector2(72,44))

static func action_rect(game: Control) -> Rect2:
	var footer := footer_rect(game)
	return Rect2(footer.end-Vector2(178,44),Vector2(98,44))

static func help_panel_rect(game: Control) -> Rect2:
	var safe: Rect2 = game._viewport_safe_rect().grow(-18)
	var dimensions := Vector2(minf(640,safe.size.x),minf(340,safe.size.y))
	return Rect2(safe.get_center()-dimensions*0.5,dimensions)

static func help_close_rect(game: Control) -> Rect2:
	var panel := help_panel_rect(game)
	return Rect2(panel.end-Vector2(166,66),Vector2(140,44))

static func star(game: Control, center: Vector2, radius: float, color: Color, fill: bool = false) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		points.append(center+Vector2.from_angle(-PI/2+i*PI/5)*radius*(1.0 if i%2==0 else 0.43))
	if fill: game.draw_colored_polygon(points,color)
	else:
		points.append(points[0])
		game.draw_polyline(points,color,2,true)

static func portal(game: Control, center: Vector2, radius: float, color: Color, time: float) -> void:
	game.draw_circle(center,radius,Color(color,0.08))
	for ring in range(3):
		var points := PackedVector2Array()
		for n in range(40):
			var angle := time*(1 if ring%2==0 else -1)+n*TAU/48
			points.append(center+Vector2(cos(angle)*0.62,sin(angle))*radius*(1.0-ring*0.18))
		game.draw_polyline(points,Color(color,0.85-ring*0.16),maxf(1.5,radius*0.06),true)

static func draw_core(game: Control, center: Vector2, scale: float, alpha: float) -> void:
	portal(game,center-Vector2(0,16)*scale,46*scale,Color(0.4,0.95,1,alpha),float(game.level_time))
	game.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-44)*scale,center+Vector2(16,-15)*scale,center+Vector2(0,10)*scale,center+Vector2(-16,-15)*scale]),Color(0.62,0.98,1,alpha))
	game.draw_line(center+Vector2(-29,32)*scale,center+Vector2(29,32)*scale,Color(0.35,0.67,0.72,alpha),8*scale,true)

static func draw_ground(game: Control, rt: RefCounted) -> void:
	if rt.id == "bare":
		for row in range(game.board_rows):
			for col in range(game.COLS):
				var rect: Rect2 = game._cell_rect(row,col).grow(-1)
				game.draw_rect(rect,Color("a4a8a4") if (row+col)%2==0 else Color("979d9b"))
				game.draw_rect(rect.grow(-4),Color(0.84,0.85,0.81,0.4),false,1)
				if (row*3+col)%4==0:
					game.draw_line(rect.position+rect.size*Vector2(0.3,0),rect.position+rect.size*Vector2(0.6,0.45),Color(0.25,0.28,0.27,0.3),1.5,true)
	if rt.id == "stars":
		for cell in Data.STAR_CELLS:
			var rect: Rect2 = game._cell_rect(cell.x,cell.y).grow(-3)
			var plant = game.grid[cell.x][cell.y]
			var filled: bool = plant != null and plant.kind == "starfruit" and float(plant.health)>0
			game.draw_rect(rect,Color(0.98,0.78,0.19,0.24 if filled else 0.1))
			game.draw_rect(rect,Color(1,0.86,0.36,0.85),false,2)
			star(game,rect.get_center(),minf(rect.size.x,rect.size.y)*0.35,Color(1,0.9,0.46,0.8),filled)
	if rt.puzzle != null:
		for row in range(5):
			for col in range(8):
				var cell := Vector2i(row,col)
				var rect: Rect2 = game._cell_rect(row,col).grow(-3)
				game.draw_rect(rect,Color(0.19,0.33,0.24,0.16))
				if cell == rt.puzzle.selected or rt.puzzle.hint.has(cell):
					game.draw_rect(rect,Color(0.91,0.95,0.57,0.22))
					game.draw_rect(rect,Color(1,0.92,0.47),false,3)
				for group in rt.puzzle.pending:
					if group.has(cell): game.draw_rect(rect,Color(1,0.94,0.72,0.56))
	if rt.id == "portals":
		for i in range(2):
			var a: Vector2 = game._cell_center(rt.portal_rows[i],7)
			var b: Vector2 = game._cell_center(rt.cores[i].row,4)
			var tint := Color("d8a0f4") if i == 0 else Color("f1abc6")
			game.draw_dashed_line(a,b,Color(tint,0.32),2,8,true)
			portal(game,a,game.CELL_SIZE.y*0.43,tint,float(game.level_time))
			portal(game,b,game.CELL_SIZE.y*0.3,tint,-float(game.level_time))
			if rt.portal_time >= 21:
				var next_rows: Array = [[0,4],[2,0],[4,2]][(int(rt.portal_phase)+1)%3]
				var next: Rect2 = game._cell_rect(next_rows[i],7).grow(-2)
				game.draw_rect(next,Color(tint,0.18+0.15*sin(float(game.level_time)*8)))
				game.draw_rect(next,tint,false,2)

static func draw_column_hover(game: Control, rt: RefCounted) -> bool:
	if rt.id != "columns" or game.selected_tool == "" or not game.active_cards.has(game.selected_tool): return false
	var cell: Vector2i = game._mouse_to_cell(game._pointer_local_position())
	if cell.x < 0: return false
	for row in range(game.board_rows):
		var rect: Rect2 = game._cell_rect(row,cell.y).grow(-3)
		var valid: bool = game._placement_error(game.selected_tool,row,cell.y) == ""
		game.draw_rect(rect,Color(0.9,0.96,0.43,0.24) if valid else Color(0.85,0.32,0.22,0.17))
		game.draw_rect(rect,Color(0.96,0.97,0.62,0.6),false,2)
		if valid: game._draw_plant_preview(game.selected_tool,game._cell_center(row,cell.y))
	return true

static func footprint(game: Control, zombie: Dictionary) -> void:
	var scale: float = game._battle_unit_scale()
	var center := Vector2(float(zombie.x),game._row_center_y(int(zombie.row))+18*scale)
	for i in range(4):
		var point := center+Vector2((i-2)*13,6 if i%2==0 else -2)*scale
		var alpha := 0.14+0.16*(0.5+0.5*sin(float(game.level_time)*4-i))
		game.draw_set_transform(point,-0.18,Vector2(1,0.5))
		game.draw_circle(Vector2.ZERO,6*scale,Color(0.17,0.23,0.19,alpha))
	game._set_combat_transform()

static func draw_overlay(game: Control, rt: RefCounted) -> void:
	if rt.id != "rain": return
	var board := Rect2(game.BOARD_ORIGIN,game.board_size)
	var age: float = game.level_time
	game.draw_rect(board,Color(0.07,0.14,0.22,0.17))
	for n in range(72):
		var u := fposmod(float(n)*0.618-age*0.02,1)
		var v := fposmod(float(n)*0.367+age*0.62,1)
		var pos := board.position+board.size*Vector2(u,v)
		game.draw_line(pos,pos+Vector2(-5,13),Color(0.75,0.9,1,0.27),1,true)
	if fmod(age,19) < 0.14: game.draw_rect(board,Color(0.8,0.9,1,0.12))
	for packet in rt.packets:
		var rect: Rect2 = rt.packet_rect(packet)
		var expiring: bool = float(packet.life)<4
		ThemeLib.draw_rounded_panel(game,rect,Color("f4e8c9"),Color("ec9864") if expiring else Color("82bdb0"),7,0.12)
		Menus.plant(game,packet.kind,Rect2(rect.position+Vector2(4,2),rect.size-Vector2(8,12)))
		ThemeLib.draw_progress_bar(game,Rect2(rect.position+Vector2(4,rect.size.y-8),Vector2(rect.size.x-8,4)),float(packet.life)/15,Color("e9925a") if expiring else Color("5b9b88"),Color("bfc6b0"),Color.TRANSPARENT)

static func draw_hud(game: Control, rt: RefCounted) -> void:
	var footer := footer_rect(game)
	ThemeLib.draw_rounded_panel(game,footer,Color("243d36"),Color("708a75"),10,0.06)
	var has_action: bool = rt.planning or rt.puzzle != null
	var text_rect := Rect2(footer.position+Vector2(12,0),Vector2(footer.size.x-(190 if has_action else 100),44))
	game._draw_text_block(rt.status(),text_rect,16 if game.size.y<500 else 21,Color("f4eed3"),0,1)
	game._draw_fancy_button(help_rect(game),"玩法",Color("e9e9d7"),Color("708a75"),18)
	if has_action: game._draw_fancy_button(action_rect(game),"出击 →" if rt.planning else "提示",Color("a8d182"),Color("537857"),18)
	if not rt.help_open: return
	game.draw_rect(Rect2(Vector2.ZERO,game.size),Color(0.02,0.08,0.06,0.72))
	var panel := help_panel_rect(game)
	ThemeLib.draw_rounded_panel(game,panel,Color("f8f5e9"),Color("829474"),18,0.1)
	var info := Data.entry(rt.id)
	Menus.label(game,Rect2(panel.position+Vector2(26,18),Vector2(panel.size.x-52,46)),info.title,30)
	game._draw_text_block(info.description,Rect2(panel.position+Vector2(26,80),Vector2(panel.size.x-52,120)),23,Menus.INK,10,4)
	Menus.label(game,Rect2(panel.position+Vector2(26,205),Vector2(panel.size.x-52,30)),info.goal+" · 首通奖励 200 金币",19,Menus.GREEN)
	game._draw_fancy_button(help_close_rect(game),"继续游戏",Color("a8d182"),Color("537857"),21)
