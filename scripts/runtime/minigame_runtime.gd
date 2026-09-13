extends RefCounted

const Data = preload("res://scripts/data/minigame_defs.gd")
const Defs = preload("res://scripts/game_defs.gd")
const Match3 = preload("res://scripts/runtime/minigame_match3.gd")
const Visuals = preload("res://scripts/ui/minigame_visuals.gd")
var game: Control
var id := ""
var puzzle: RefCounted
var planning := false
var help_open := false
var wave := 1
var spawn_timer := 24.0
var spawn_index := 0
var completed_waves := 0
var packets: Array = []
var packet_timer := 0.0
var packet_index := 0
var cores: Array = []
var portal_time := 0.0
var portal_phase := 0
var portal_rows := [0,4]

func _init(owner_game: Control) -> void:
	game = owner_game

func setup() -> void:
	id = String(game.current_level.get("minigame", ""))
	puzzle = null
	planning = id == "bare"
	help_open = false
	wave = 1
	completed_waves = 0
	spawn_timer = 30.0 if id in ["stars","rain","portals"] else 22.0
	spawn_index = 0
	packets.clear()
	packet_timer = 0
	packet_index = 0
	cores.clear()
	portal_time = 0
	portal_phase = 0
	portal_rows = [0,4]
	if id == "": return
	game.expected_spawn_units = game.current_level.events.size()
	if id == "gems": puzzle = Match3.new(game)
	if id == "rain": game.active_cards = []
	if id == "invisible": game.active_cards = ["peashooter", "snow_pea", "plantern", "wallnut", "", ""]
	if id == "columns":
		game.active_cards = ["flower_pot", "cabbage_pult", "kernel_pult", "", "", ""]
		# The challenge starts with two potted columns, so early cards always work.
		for row in range(game.board_rows):
			for col in range(game.COLS):
				game.support_grid[row][col] = game._create_plant("flower_pot",row,col) if col < 2 else null
	if id == "bare":
		for row in range(game.board_rows):
			for col in range(game.COLS):
				game._set_cell_terrain_kind(row,col,"roof")
				game.support_grid[row][col] = null
	if id == "portals":
		for row in [1,3]:
			var core: Dictionary = game._create_plant("wallnut",row,2)
			core.minigame_core = true
			core.health = 3600.0
			core.max_health = 3600.0
			game.grid[row][2] = core
			cores.append(core)

func blocks_simulation() -> bool:
	return id != "" and (planning or help_open)

func update(delta: float) -> void:
	if id == "": return
	if puzzle != null: puzzle.update(delta)
	if id == "rain": update_rain(delta)
	if id == "portals": update_portals(delta)
	update_spawns(delta)

func update_spawns(delta: float) -> void:
	if planning: return
	var events: Array = game.current_level.events
	var all_spawned := spawn_index >= events.size()
	var between_waves := not all_spawned and int(events[spawn_index].mini_wave) > wave
	if all_spawned or between_waves:
		if game._enemy_zombie_count() > 0: return
		completed_waves = wave
		if all_spawned:
			# Puzzle and star objectives retain pressure until their actual goal is met.
			if id in ["gems","stars"]:
				spawn_timer -= delta
				if spawn_timer <= 0:
					for row in range(game.board_rows): game._spawn_zombie("conehead",row,true)
					spawn_timer = 15
			return
		wave += 1
		spawn_timer = 8.0
		if id == "bare":
			planning = true
			game.sun_points += 250
			game._show_toast("补给 +250 阳光；布防后点击出击")
		else:
			game._show_banner("第 %d / 6 波" % wave,1.8)
		return
	if game._enemy_zombie_count() >= (20 if id == "columns" else 14): return
	spawn_timer -= delta
	if spawn_timer > 0: return
	var event: Dictionary = events[spawn_index]
	game._spawn_zombie(String(event.kind),int(event.row))
	spawn_index += 1
	game.next_event_index = spawn_index
	game.base_events_spawned = spawn_index
	spawn_timer = maxf(1.2, (2.6 if id == "columns" else 4.8) - wave * 0.3)

func update_rain(delta: float) -> void:
	for packet in packets:
		packet.life -= delta
		packet.v = minf(float(packet.target),float(packet.v) + delta * 0.15)
	packets = packets.filter(func(packet): return float(packet.life) > 0)
	packet_timer -= delta
	if packet_timer > 0: return
	packet_timer = 2.8
	if packets.size() >= 10: return
	var opening := ["peashooter", "peashooter", "lily_pad", "lily_pad", "repeater", "repeater", "peashooter", "snow_pea", "lily_pad", "wallnut", "starfruit", "cherry_bomb"]
	var cards: Array = game.current_level.minigame_cards
	var kind: String = opening[packet_index] if packet_index < opening.size() else cards[game.rng.randi_range(0,cards.size()-1)]
	# A reliable pad cycle prevents a random streak from closing both water lanes.
	if packet_index >= opening.size() and packet_index % 6 == 0: kind = "lily_pad"
	packets.append({"kind":kind, "u":0.05 + float(packet_index % 10)*0.1, "v":0.0, "target":game.rng.randf_range(0.35,0.8), "life":15.0})
	packet_index += 1

func packet_rect(packet: Dictionary) -> Rect2:
	var dimensions := Vector2(54,64) if game.size.y >= 500 else Vector2(40,44)
	var center: Vector2 = game.BOARD_ORIGIN + game.board_size * Vector2(float(packet.u),float(packet.v))
	center.y = maxf(center.y, float(game.BOARD_ORIGIN.y) + dimensions.y*0.5)
	return Rect2(center-dimensions*0.5,dimensions)

func update_portals(delta: float) -> void:
	portal_time += delta
	if portal_time >= 24:
		portal_time = fmod(portal_time,24)
		portal_phase = (portal_phase+1)%3
		portal_rows = [[0,4],[2,0],[4,2]][portal_phase].duplicate()
		game._show_toast("传送入口已换路")
	for zombie in game.zombies:
		if not game._is_enemy_zombie(zombie) or bool(zombie.get("mini_portal_used",false)): continue
		var pair := portal_rows.find(int(zombie.row))
		if pair < 0 or float(zombie.x) > game._cell_center(0,7).x: continue
		if float(zombie.x) < game._cell_center(0,6).x: continue
		zombie.mini_portal_used = true
		zombie.row = int(cores[pair].row)
		zombie.x = game._cell_center(zombie.row,4).x
		zombie.flash = 0.45
		zombie.spawn_time = game.level_time

func zombie_visible(zombie: Dictionary) -> bool:
	if id != "invisible" or not game._is_enemy_zombie(zombie): return true
	if float(zombie.get("flash",0)) > 0 or float(zombie.get("slow_timer",0)) > 0 or float(zombie.get("special_pause_timer",0)) > 0: return true
	var col := int(floor((float(zombie.x)-float(game.BOARD_ORIGIN.x))/float(game.CELL_SIZE.x)))
	for row in range(maxi(0,int(zombie.row)-1),mini(game.board_rows,int(zombie.row)+2)):
		for c in range(maxi(0,col-1),mini(game.COLS,col+2)):
			var plant = game.grid[row][c]
			if plant != null and plant.kind == "plantern" and float(plant.health)>0: return true
	return false

func star_count() -> int:
	var count := 0
	for cell in Data.STAR_CELLS:
		var plant = game.grid[cell.x][cell.y]
		if plant != null and plant.kind == "starfruit" and float(plant.health)>0: count += 1
	return count

func fail_reason() -> String:
	if id == "portals":
		for core in cores:
			if float(core.health) <= 0 or game.grid[core.row][core.col] != core: return "传送门核心被摧毁了"
	return ""

func won() -> bool:
	if id == "gems": return puzzle != null and int(puzzle.score)>=Match3.TARGET
	if id == "stars": return star_count() == Data.STAR_CELLS.size()
	return not planning and spawn_index >= game.current_level.events.size() and game._enemy_zombie_count() == 0

func board_click(cell: Vector2i) -> bool:
	if help_open: return true
	if puzzle != null:
		puzzle.click(cell)
		return true
	var plant = game.grid[cell.x][cell.y]
	if plant != null and bool(plant.get("minigame_core",false)):
		game._show_toast("守护核心不可铲除、覆盖或使用大招；可用葫芦治疗")
		return true
	if id == "bare" and planning and game.selected_tool == "shovel":
		var target = game._targetable_plant_at(cell.x,cell.y)
		if target != null:
			var fraction := clampf(float(target.health)/maxf(1,float(target.max_health)),0,1)
			game.sun_points += int(game._endless_cost_for_kind(String(target.kind))*fraction)
		return false
	if id != "columns" or not game.active_cards.has(game.selected_tool) or game.selected_tool == "": return false
	var kind: String = game.selected_tool
	var valid_rows: Array = []
	for row in range(game.board_rows):
		if game._placement_error(kind,row,cell.y) == "": valid_rows.append(row)
	if valid_rows.is_empty():
		game._show_toast("本列没有可种植空位；先补花盆")
		return true
	for row in valid_rows:
		var fresh: Dictionary = game._create_plant(kind,row,cell.y)
		if kind == "flower_pot": game.support_grid[row][cell.y] = fresh
		else: game.grid[row][cell.y] = fresh
	game._consume_conveyor_card(kind)
	game.selected_tool = ""
	game._show_toast("整列种下 %d 株" % valid_rows.size())
	return true

func click(pos: Vector2) -> bool:
	if help_open:
		if Visuals.help_close_rect(game).has_point(pos): help_open = false
		return true
	if Visuals.help_rect(game).has_point(pos):
		help_open = true
		return true
	if Visuals.action_rect(game).has_point(pos):
		if planning:
			if not has_attacker():
				game._show_toast("先在花盆上种下攻击植物")
				return true
			planning = false
			spawn_timer = 2.0
			game._show_banner("第 %d / 5 轮出击" % wave,1.8)
		elif puzzle != null:
			puzzle.hint = puzzle.find_move()
			puzzle.idle = 6
		return true
	if id == "rain":
		# Rain has no seed bank: clicking a falling seed puts it straight into hand.
		for i in range(packets.size()-1,-1,-1):
			if packet_rect(packets[i]).has_point(pos):
				var kind := String(packets[i].kind)
				packets.remove_at(i)
				game.selected_tool = kind
				var data: Dictionary = Defs.PLANTS.get(kind, {})
				game._show_toast("%s 已握在手上，点击格子种下" % String(data.get("name", kind)))
				return true
	return false

func has_attacker() -> bool:
	for row in game.grid:
		for plant in row:
			if plant != null and plant.kind in ["cabbage_pult","kernel_pult","melon_pult","snow_pea"]: return true
	return false

func status() -> String:
	match id:
		"gems": return "消除 %d / 50 组   ·   连锁 %d" % [mini(puzzle.score,50),puzzle.combo]
		"stars": return "星位 %d / 14   ·   所有标记同时放满星星果" % star_count()
		"bare": return "第 %d / 5 轮 · %s" % [wave,"布防中（铲除按剩余血量退款）" if planning else "防守中 · 无天降阳光"]
		"rain": return "第 %d / 6 波 · 点落种握在手上，再点格子免费种下" % wave
		"invisible": return "第 %d / 6 波 · 脚印追踪 / 路灯照明 / 冰冻现形" % wave
		"portals":
			var health := "%d%% / %d%%" % [maxi(0,int(cores[0].health/36)),maxi(0,int(cores[1].health/36))]
			return "核心 %s · %s" % [health,"入口即将换路！" if portal_time>=21 else "第 %d / 6 波" % wave]
		"columns": return "第 %d / 6 波 · 一张种一列，先放花盆" % wave
	return ""
