extends RefCounted

const MomijiSprites = preload("res://scripts/data/momiji_sprite_defs.gd")
const AyaSprites = preload("res://scripts/data/aya_sprite_defs.gd")
const STEP := 1.0 / 60.0
const WARNING := 1.2
const WIND_FACTOR := 0.8
const MAX_FIELDS := 12
const MAX_DASHES := 12
const MAX_AFTERIMAGES := 12
const MAX_ORBIT_TOKENS := 12
const ORBIT_LIFETIME := .9
const ROAM_ROWS := [2, 5, 1, 4, 0, 3]
const ROAM_COLUMNS := [7, 2, 8, 3, 6, 1, 5, 4]
const WHITE := Color("f1eee1")
const RED := Color("ce554b")
const WIND := Color("aacdc0")
const GOLD := Color("eecb83")
const VEIL_PATTERNS := ["aya_leaf_veiling", "aya_tengu_fall", "aya_storm_day"]

var game: Control
var fields: Array[Dictionary] = []
var dashes: Array[Dictionary] = []
var afterimages: Array[Dictionary] = []
var serial := 0
var land_arrived := false
var transition_time := 0.0

func _init(owner: Control) -> void:
	game = owner

func _alive(boss: Dictionary) -> bool:
	return float(boss.get("health", 0.0)) > 0.0 or (bool(boss.get("touhou_invulnerable", false)) and float(boss.get("touhou_survival_timer", 0.0)) > 0.0)

func boss_for(owner: int) -> Dictionary:
	for boss in game.zombies:
		if int(boss.get("uid", -1)) == owner and String(boss.get("kind", "")) in ["momiji_boss", "aya_boss"] and _alive(boss): return boss
	return {}

func reset() -> void:
	for field in fields: _clear_orbit(field)
	fields.clear(); dashes.clear(); afterimages.clear()
	serial = 0; land_arrived = false; transition_time = 0.0
	for boss in game.zombies:
		if String(boss.get("kind", "")) not in ["momiji_boss", "aya_boss"]: continue
		for key in ["tengu_body_uv", "tengu_clock", "tengu_pose", "tengu_pattern", "tengu_shield_age", "tengu_veil_age", "tengu_dash_active", "tengu_image_timer", "tengu_roam_step", "tengu_relay_step"]: boss.erase(key)

func clear_owner(owner: int) -> void:
	for field in fields:
		if int(field.owner) == owner: _clear_orbit(field)
	fields = fields.filter(func(p): return int(p.owner) != owner)
	dashes = dashes.filter(func(p): return int(p.owner) != owner)
	afterimages = afterimages.filter(func(p): return int(p.owner) != owner)
	for boss in game.zombies:
		if int(boss.get("uid", -1)) != owner: continue
		# Retain the current position when a phase ends; no unannounced teleport.
		for key in ["tengu_pose", "tengu_pattern", "tengu_shield_age", "tengu_veil_age", "tengu_dash_active"]: boss.erase(key)

func _rank() -> int:
	return clampi(int(game.TouhouDifficulty.profile(game.current_level).rank), 0, 3)

func _body_uv(boss: Dictionary) -> Vector2:
	return Vector2(boss.get("tengu_body_uv", Vector2((float(boss.get("x", game.BOARD_ORIGIN.x + game.board_size.x)) - game.BOARD_ORIGIN.x) / maxf(.01, game.CELL_SIZE.x), float(boss.get("row", 2)))))

func _world(uv: Vector2) -> Vector2:
	return Vector2(game.BOARD_ORIGIN.x + uv.x * game.CELL_SIZE.x, game._row_center_y(0) + uv.y * game.CELL_SIZE.y)

func body_point(boss: Dictionary) -> Vector2:
	# Store a grid coordinate, not a stale pixel position: resizing during flight
	# keeps rendering, the native hit point and the emitter in the same place.
	return _world(_body_uv(boss))

func _closest_row(y: float) -> int:
	var closest := 0; var distance := INF
	for row in game.active_rows:
		var d: float = absf(y - game._row_center_y(int(row)))
		if d < distance: distance = d; closest = int(row)
	return closest

func on_finale_arrival(boss: Dictionary) -> void:
	if land_arrived or String(boss.get("kind", "")) != "aya_boss" or bool(boss.get("touhou_final_preview", false)) or bool(boss.get("portrait", false)) or boss_for(int(boss.get("uid", -1))).is_empty(): return
	land_arrived = true; transition_time = 0.0
	# The parent owns one atomic terrain/belt/mower update. This runtime changes
	# only its eased visual state and leaves all placed plant dictionaries intact.
	if game.has_method("_tengu_begin_mountainside"): game.call("_tengu_begin_mountainside")
	for other in game.zombies:
		if String(other.get("kind", "")) == "momiji_boss": clear_owner(int(other.get("uid", -1)))

func transition_progress() -> float:
	if not land_arrived: return 0.0
	var t := clampf(transition_time / 2.6, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _plant(row: int, col: int) -> Variant:
	if row < 0 or row >= game.grid.size() or col < 0 or col >= game.COLS or col >= game.grid[row].size(): return null
	return game._targetable_plant_at(row, col)

func sheltered(row: int, col: int) -> bool:
	var plant = _plant(row, col)
	if plant == null or float(plant.get("health", 0.0)) <= 0.0: return false
	return game._is_cell_protected_by_umbrella(row, col) or game._plant_has_component(plant, "anchor_fern") or float(plant.get("rooted_timer", 0.0)) > 0.0 or float(plant.get("holy_invincible_timer", 0.0)) > 0.0 or bool(plant.get("ultimate_active", false))

func boss_revealed(boss: Dictionary) -> bool:
	if float(boss.get("revealed_timer", 0.0)) > 0.0: return true
	return game._plantern_reveals_position(body_point(boss))

func is_hidden(boss: Dictionary) -> bool:
	if String(boss.get("kind", "")) != "aya_boss" or not _alive(boss) or boss_revealed(boss): return false
	var age := float(boss.get("tengu_veil_age", -1.0))
	return age >= WARNING and age < 4.8

func damage_factor(boss: Dictionary, from_x: float = -INF) -> float:
	if String(boss.get("kind", "")) != "momiji_boss" or not _alive(boss): return 1.0
	var age := float(boss.get("tengu_shield_age", -1.0))
	return .68 if age >= WARNING and age < 4.2 and from_x <= body_point(boss).x else 1.0

func _busy_cells(count: int) -> Array[Vector2i]:
	var choices: Array = []
	for row in game.active_rows:
		for col in range(game.COLS):
			var p = _plant(int(row), col)
			if p == null or float(p.get("health", 0.0)) <= 0.0: continue
			var score := 10.0 + col * .15
			if p.has("fusion_kind"): score += 12.0 + float(p.get("stats", {}).get("fusion_tier", 1)) * 2.0
			var data: Dictionary = game.Defs.PLANTS.get(String(p.get("fusion_kind", p.get("kind", ""))), {})
			if float(data.get("damage", 0.0)) > 0.0 or data.has("fusion_channels"): score += 6.0
			choices.append({"cell":Vector2i(int(row), col), "score":score, "tie":posmod(int(row) * game.COLS + col + serial * 7, game.COLS * maxi(1, game.active_rows.size()))})
	choices.sort_custom(func(a,b): return a.score > b.score or (a.score == b.score and a.tie < b.tie))
	var result: Array[Vector2i] = []
	for entry in choices:
		if result.size() >= count: break
		result.append(Vector2i(entry.cell))
	for i in range(count - result.size()):
		if game.active_rows.is_empty(): break
		result.append(Vector2i(int(game.active_rows[posmod(serial + i * 2, game.active_rows.size())]), 3 + posmod(serial + i, maxi(1, game.COLS - 4))))
	return result

func queue_field(owner: int, cell: Vector2i, mode: String, delay: float = WARNING, duration: float = 6.0) -> void:
	if fields.size() >= MAX_FIELDS or boss_for(owner).is_empty() or not game._is_row_active(cell.x) or cell.y < 0 or cell.y >= game.COLS: return
	if mode not in ["wind", "report", "cyclone", "fence", "sword"] or fields.any(func(p): return int(p.owner) == owner and p.cell == cell and String(p.mode) == mode): return
	var raw: float = {"wind":0.0,"report":16.0 + 3 * _rank(),"cyclone":5.0 + _rank(),"fence":4.0 + _rank(),"sword":8.0 + 2 * _rank()}[mode]
	fields.append({"owner":owner,"cell":cell,"mode":mode,"age":0.0,"delay":maxf(1.4 if mode == "report" else WARNING,delay),"duration":clampf(duration,.3,8.0),"damage":raw,"hits":[],"hit_counts":{},"pulse_timer":0.0,"pulse":0.0,"orbit_tokens":[]})

func queue_dash(owner: int, target_cell: Vector2i, delay: float = WARNING, duration: float = .36) -> void:
	var boss := boss_for(owner)
	if boss.is_empty() or String(boss.kind) != "aya_boss" or dashes.size() >= MAX_DASHES or not game._is_row_active(target_cell.x): return
	var start := _body_uv(boss)
	for previous in dashes:
		if int(previous.owner) == owner: start = Vector2(previous.to_uv)
	dashes.append({"owner":owner,"from_uv":start,"to_uv":Vector2(clampf(target_cell.y + .5,1.5,game.COLS-.5),target_cell.x),"age":0.0,"delay":maxf(WARNING,delay),"duration":clampf(duration,.24,.6),"motion_time":0.0,"hits":[]})

func _queue_roam(boss: Dictionary, delay: float = WARNING, duration: float = .36) -> void:
	var step := int(boss.get("tengu_roam_step",0))
	boss.tengu_roam_step = step + 1
	var row := int(ROAM_ROWS[posmod(step,ROAM_ROWS.size())])
	if not game._is_row_active(row): row = int(game.active_rows[posmod(step,game.active_rows.size())])
	queue_dash(int(boss.uid),Vector2i(row,int(ROAM_COLUMNS[posmod(step,ROAM_COLUMNS.size())])),delay,duration)

func _damage_cell(owner: int, cell: Vector2i, raw: float) -> bool:
	var boss := boss_for(owner)
	if boss.is_empty() or sheltered(cell.x, cell.y): return false
	var p = _plant(cell.x, cell.y)
	if p == null or float(p.get("health", 0.0)) <= 0.0: return false
	return game._damage_plant_cell(cell.x,cell.y,raw * game.TouhouDifficulty.direct_attack_damage(String(boss.kind),game.current_level),0.0,true)

func _dash_hits(dash: Dictionary, before: Vector2, after: Vector2) -> void:
	var reach: float = minf(game.CELL_SIZE.x,game.CELL_SIZE.y) * .30
	for row in game.active_rows:
		for col in range(game.COLS):
			var cell := Vector2i(int(row),col)
			if dash.hits.has(cell): continue
			var point: Vector2 = game._cell_center(cell.x,cell.y)
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,before,after)) > reach: continue
			dash.hits.append(cell)
			_damage_cell(int(dash.owner),cell,8.0 + _rank() * 2)

func update_boss(boss: Dictionary, delta: float) -> Dictionary:
	if game.boss_time_stop_timer > 0.0 or not _alive(boss): return boss
	if not boss.has("tengu_body_uv"): boss.tengu_body_uv = _body_uv(boss)
	var remaining := maxf(0.0,delta)
	while remaining > .00001:
		var dt := minf(STEP,remaining); remaining -= dt
		boss = game.ZombieRuntime.tick_hover_pose(boss,dt)
		boss.tengu_clock = float(boss.get("tengu_clock",0.0)) + dt
		for clock in ["tengu_shield_age","tengu_veil_age"]:
			if boss.has(clock): boss[clock] = float(boss[clock]) + dt
		boss.tengu_dash_active = false
		# Each new route starts with its own warning. Keep the living body moving
		# through every card and recovery window, not just the survival sequence.
		if String(boss.kind) == "aya_boss" and not dashes.any(func(p): return int(p.owner)==int(boss.uid)) and not game.active_rows.is_empty():
			var quick := String(boss.get("tengu_pattern","")) in ["aya_fantasy_storm","aya_peerless_wind","aya_relay"]
			_queue_roam(boss,WARNING,.28 if quick else .36)
		var next_dash := -1
		for i in range(dashes.size()):
			var dash: Dictionary = dashes[i]
			if int(dash.owner) != int(boss.uid): continue
			dash.age += dt
			if next_dash < 0: next_dash = i
		# A root/freeze can delay a route beyond a later route's deadline. Keep
		# the queue sequential instead of applying multiple bodies in one tick.
		if next_dash >= 0:
			var dash: Dictionary = dashes[next_dash]
			if float(dash.age) < float(dash.delay):
				var stationary := body_point(boss)
				boss.x = stationary.x; boss.row = _closest_row(stationary.y)
				continue
			if float(boss.get("frozen_timer",0.0)) > 0.0 or float(boss.get("rooted_timer",0.0)) > 0.0: continue
			var before := body_point(boss)
			var travel: float = dt * (.55 if float(boss.get("slow_timer",0.0)) > 0.0 else 1.0)
			dash.motion_time = minf(float(dash.duration),float(dash.motion_time)+travel)
			var progress := clampf(float(dash.motion_time)/float(dash.duration),0,1)
			var eased := progress*progress*(3.0-2.0*progress)
			boss.tengu_body_uv = Vector2(dash.from_uv).lerp(Vector2(dash.to_uv),eased)
			boss.tengu_dash_active = true
			boss.tengu_image_timer = float(boss.get("tengu_image_timer",0.0))-dt
			if float(boss.tengu_image_timer) <= 0.0:
				boss.tengu_image_timer=.05
				if afterimages.size() >= MAX_AFTERIMAGES: afterimages.remove_at(0)
				afterimages.append({"owner":int(boss.uid),"uv":_body_uv(boss),"age":0.0,"frame":[3,4,5][posmod(int(float(boss.tengu_clock)*10),3)]})
			_dash_hits(dash,before,body_point(boss))
			if progress >= 1.0: dashes.remove_at(next_dash)
		var point := body_point(boss)
		boss.x = point.x; boss.row = _closest_row(point.y)
	return boss

func _field_cells(field: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if String(field.mode) != "cyclone": return [Vector2i(field.cell)]
	var progress := clampf((float(field.age)-float(field.delay))/float(field.duration),0,1)
	var center := Vector2(lerpf(float(field.cell.y)+.5,1.5,progress),float(field.cell.x) + sin(progress*TAU)*.65)
	for row in game.active_rows:
		for col in range(game.COLS):
			if Vector2(col+.5,float(row)).distance_to(center) <= .9: result.append(Vector2i(int(row),col))
	return result

func _active(field: Dictionary) -> bool:
	return float(field.age) >= float(field.delay) and float(field.age) < float(field.delay)+float(field.duration) and not boss_for(int(field.owner)).is_empty()

func action_factor(row: int, col: int) -> float:
	if sheltered(row,col): return 1.0
	for field in fields:
		if String(field.mode) not in ["wind","cyclone","fence"] or not _active(field): continue
		if _field_cells(field).has(Vector2i(row,col)): return WIND_FACTOR
	return 1.0

func modify_projectile(projectile: Dictionary, delta: float) -> Dictionary:
	if game.boss_time_stop_timer > 0.0 or delta <= 0.0 or not projectile.has("position") or projectile.has("arc_target") or projectile.has("target_uid"): return projectile
	for flag in ["ultimate","plant_food","fusion_ultimate","reflected","fusion_fragment","source_special","special"]:
		if bool(projectile.get(flag,false)): return projectile
	var kind := String(projectile.get("kind","pea"))
	if kind in ["boomerang","frost_boomerang","lotus_orbit_shot","lotus_converge_shot","moon_meteor","ancient_spore"] or kind.contains("ultimate") or kind.contains("meteor"): return projectile
	var point := Vector2(projectile.position)
	for field in fields:
		if String(field.mode) != "wind" or not _active(field): continue
		var cell := Vector2i(field.cell)
		if not game._cell_rect(cell.x,cell.y).has_point(point) or sheltered(cell.x,cell.y): continue
		# Accumulate a bounded sideways velocity, not repeated damage scaling.
		# Free-aim lets the native collision follow the visibly displaced projectile.
		var direction := 1.0 if posmod(cell.x + cell.y + serial,2) == 0 else -1.0
		var limit: float = game.CELL_SIZE.y*.42
		projectile.velocity_y = clampf(float(projectile.get("velocity_y",0.0)) + direction*game.CELL_SIZE.y*.8*delta,-limit,limit)
		projectile.free_aim = true; projectile.tengu_deflected = true
		return projectile
	return projectile

func cyclone_point(field: Dictionary) -> Vector2:
	var progress := clampf((float(field.age)-float(field.delay))/float(field.duration),0,1)
	return _world(Vector2(lerpf(float(field.cell.y)+.5,1.5,progress),float(field.cell.x)+sin(progress*TAU)*.65))

func _clear_orbit(field: Dictionary) -> void:
	if field.has("orbit_tokens"): field.orbit_tokens.clear()

func capture_projectile(projectile: Dictionary, from: Vector2, to: Vector2) -> bool:
	if bool(projectile.get("tengu_captured",false)): return true
	if game.boss_time_stop_timer > 0.0: return false
	for flag in ["ultimate","plant_food","fusion_ultimate","reflected","hina_exempt"]:
		if bool(projectile.get(flag,false)): return false
	var kind := String(projectile.get("kind","pea"))
	if kind.contains("ultimate") or kind in ["ancient_spore"]: return false
	for field in fields:
		if String(field.mode) != "cyclone" or not _active(field): continue
		var center := cyclone_point(field)
		var reach: float = minf(game.CELL_SIZE.x,game.CELL_SIZE.y)*.56 + maxf(0.0,float(projectile.get("radius",6.0)))
		if Geometry2D.get_closest_point_to_segment(center,from,to).distance_squared_to(center) > reach*reach: continue
		projectile.tengu_captured = true
		var tokens: Array = field.orbit_tokens
		if tokens.size() >= MAX_ORBIT_TOKENS: tokens.remove_at(0)
		# Only drawing scalars survive interception; no projectile/source/target
		# dictionaries or object references remain alive inside the cyclone.
		tokens.append({"color":Color(projectile.get("color",GOLD)),"radius":clampf(float(projectile.get("radius",4.0)),1.5,12.0),"age":0.0,"phase":float(tokens.size())*2.4+float(field.age)})
		return true
	return false

func cleanse_row(row: int) -> void:
	for field in fields:
		if Vector2i(field.cell).x == row or _field_cells(field).any(func(cell): return cell.x == row): _clear_orbit(field)
	fields = fields.filter(func(p): return Vector2i(p.cell).x != row and not _field_cells(p).any(func(cell): return cell.x == row))
	dashes = dashes.filter(func(p): return roundi(Vector2(p.to_uv).y) != row)

func cast(boss: Dictionary, pattern: String) -> void:
	clear_owner(int(boss.uid)); serial += 1
	boss.tengu_pattern = pattern
	if game.active_rows.is_empty(): return
	var rank := _rank(); var owner := int(boss.uid)
	var cells := _busy_cells(2 + mini(2,rank))
	if String(boss.kind) == "momiji_boss":
		boss.tengu_pose = "sword" if pattern == "nonspell_momiji_cross" else "patrol"
		if pattern in ["momiji_sentinel","momiji_maple_guard"]:
			boss.tengu_shield_age = 0.0; boss.tengu_pose = "farsight"
			for cell in cells.slice(0,1+mini(1,rank/2)): queue_field(owner,cell,"sword",1.4,.5)
		return
	boss.tengu_pose = "branch"
	if pattern in VEIL_PATTERNS:
		boss.tengu_veil_age = 0.0; boss.tengu_pose = "veil"
		for cell in cells: queue_field(owner,cell,"wind",1.4,5.0)
	match pattern:
		"aya_headwind":
			boss.tengu_pose="wind"
			for cell in cells:
				for offset in [-1,0,1]: queue_field(owner,Vector2i(cell.x,clampi(cell.y+offset,0,game.COLS-1)),"wind",1.3,6.0)
		"aya_report", "aya_extra_edition":
			boss.tengu_pose="camera"
			for i in range(cells.size()): queue_field(owner,cells[i],"report",1.4+i*.18,.5)
			if pattern == "aya_extra_edition" and game.has_method("_spawn_new_touhou_finale_support"):
				game.call("_spawn_new_touhou_finale_support","aya_boss",int(boss.get("boss_phase",0)))
		"aya_cyclone":
			boss.tengu_pose="cyclone"
			for i in range(2): queue_field(owner,Vector2i(int(game.active_rows[posmod(serial+i*3,game.active_rows.size())]),game.COLS-2),"cyclone",1.4+i*.4,6.0)
		"aya_wind_fence", "aya_procession", "aya_divine_advent", "aya_terukuni":
			boss.tengu_pose="blockade"
			for i in range(2+rank/2): queue_field(owner,Vector2i(int(game.active_rows[posmod(serial+i*2,game.active_rows.size())]),3+posmod(serial+i,4)),"fence",1.4+i*.15,5.0)
	var survival := pattern in ["aya_fantasy_storm","aya_peerless_wind","aya_relay"]
	var count := 6+rank if survival else 2
	for i in range(count): _queue_roam(boss,WARNING+i*(.72 if survival else 2.0),.28 if survival else .36)

func update(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0: return
	var remaining := maxf(delta,0.0)
	while remaining > .00001:
		var dt := minf(STEP,remaining); remaining -= dt
		if land_arrived: transition_time = minf(2.6,transition_time+dt)
		for i in range(afterimages.size()-1,-1,-1):
			afterimages[i].age += dt
			if float(afterimages[i].age) >= .32 or boss_for(int(afterimages[i].owner)).is_empty(): afterimages.remove_at(i)
		for i in range(dashes.size()-1,-1,-1):
			if boss_for(int(dashes[i].owner)).is_empty(): dashes.remove_at(i)
		for i in range(fields.size()-1,-1,-1):
			var field: Dictionary = fields[i]
			if boss_for(int(field.owner)).is_empty(): _clear_orbit(field); fields.remove_at(i); continue
			field.age += dt; field.pulse = maxf(0.0,float(field.pulse)-dt)
			for ti in range(field.orbit_tokens.size()-1,-1,-1):
				field.orbit_tokens[ti].age += dt
				if float(field.orbit_tokens[ti].age) >= ORBIT_LIFETIME: field.orbit_tokens.remove_at(ti)
			if float(field.age) >= float(field.delay)+float(field.duration): _clear_orbit(field); fields.remove_at(i); continue
			if not _active(field) or String(field.mode) == "wind": continue
			field.pulse_timer -= dt
			if float(field.pulse_timer) > 0.0: continue
			field.pulse_timer += .9
			var maximum := 3 if String(field.mode) == "fence" else (2 if String(field.mode) == "cyclone" else 1)
			for cell in _field_cells(field):
				if int(field.hit_counts.get(cell,0)) >= maximum: continue
				field.hit_counts[cell] = int(field.hit_counts.get(cell,0))+1
				if not field.hits.has(cell): field.hits.append(cell)
				if _damage_cell(int(field.owner),cell,float(field.damage)): field.pulse=.35

func frame_index(boss: Dictionary) -> int:
	var state: Dictionary = boss.duplicate(false)
	if bool(boss.get("tengu_dash_active",false)): state.tengu_pose="dash"
	var time := float(boss.get("tengu_clock",boss.get("animation_time",game.level_time)))
	return MomijiSprites.frame_index(state,time) if String(boss.get("kind","")) == "momiji_boss" else AyaSprites.frame_index(state,time)

func draw_ground() -> void:
	var unit: float = minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for field in fields:
		var cell := Vector2i(field.cell); var active := _active(field)
		var tint := GOLD if String(field.mode) == "report" else (RED if String(field.mode) == "sword" else WIND)
		var rect: Rect2 = game._cell_rect(cell.x,cell.y).grow(-unit*.06)
		if String(field.mode) == "cyclone" and active:
			for target in _field_cells(field): game.draw_rect(game._cell_rect(target.x,target.y).grow(-unit*.08),Color(WIND,.10))
		else:
			game.draw_rect(rect,Color(tint,.09 if active else .035))
			game.draw_rect(rect,Color(tint,.72),false,maxf(1,unit*.024),true)
		if not active:
			var progress := clampf(float(field.age)/float(field.delay),0,1)
			game.draw_arc(rect.get_center(),unit*.29,-PI/2,-PI/2+TAU*progress,24,Color(tint,.75),maxf(1,unit*.025),true)
		elif String(field.mode) == "report":
			game.draw_line(rect.position,rect.end,Color(GOLD,.25),maxf(1,unit*.018),true)
	for dash in dashes:
		if float(dash.age) >= float(dash.delay): continue
		var a := _world(Vector2(dash.from_uv)); var b := _world(Vector2(dash.to_uv))
		var progress := clampf(float(dash.age)/float(dash.delay),0,1)
		game.draw_line(a,a.lerp(b,progress),Color(WHITE,.16+progress*.26),maxf(1,unit*.02),true)
		game.draw_arc(b,unit*.22,0,TAU,20,Color(RED,.36+progress*.35),maxf(1,unit*.018),true)

func draw_overlay() -> void:
	var unit: float = minf(game.CELL_SIZE.x,game.CELL_SIZE.y)
	for field in fields:
		if not _active(field): continue
		if String(field.mode) == "cyclone":
			var point := cyclone_point(field)
			for i in range(3): game.draw_arc(point+Vector2(0,-unit*i*.12),unit*(.22+i*.09),float(field.age)*4+i,float(field.age)*4+i+PI*1.45,24,Color(WIND,.35),maxf(1,unit*.024),true)
			for token in field.orbit_tokens:
				var angle: float = float(token.phase)+float(token.age)*8.0
				var radius: float = unit*(.18+.16*float(token.age)/ORBIT_LIFETIME)
				var orbit := point+Vector2(cos(angle)*radius,sin(angle)*radius*.55-unit*.12)
				var tint := Color(token.color); tint.a *= 1.0-float(token.age)/ORBIT_LIFETIME
				game.draw_circle(orbit,maxf(1.2,float(token.radius)*minf(1.0,unit/100.0)),tint)
		elif String(field.mode) == "fence":
			var rect: Rect2 = game._cell_rect(field.cell.x,field.cell.y)
			for i in range(3): game.draw_line(rect.position+Vector2(rect.size.x*(.25+i*.25),0),rect.position+Vector2(rect.size.x*(.25+i*.25),rect.size.y),Color(WIND,.38),maxf(1,unit*.03),true)
		if float(field.pulse) > 0:
			var rect: Rect2 = game._cell_rect(field.cell.x,field.cell.y)
			game.draw_rect(rect.grow(-unit*.1),Color(WHITE,float(field.pulse)*.7),false,maxf(1,unit*.035),true)
