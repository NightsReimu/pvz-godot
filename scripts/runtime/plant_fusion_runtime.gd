extends RefCounted
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const Defs = preload("res://scripts/game_defs.gd")
var game: Control
var source_cell := Vector2i(-1,-1)
var source_seed := ""
var prepared_seeds: Array = []
var prepared_result := ""

func _init(owner: Control): game = owner

func kind(plant: Dictionary) -> String:
	return String(plant.get("fusion_kind",plant.get("kind","")))

func enabled() -> bool:
	return not game._is_minigame() and not String(game.current_level.get("mode","")) in ["bowling","whack","vasebreaker"]

func reset() -> void:
	source_cell = Vector2i(-1,-1); source_seed = ""
	prepared_seeds.clear(); prepared_result = ""

func select_seed(seed: String) -> void:
	if not enabled() or not seed in game.active_cards: return
	if not game._is_conveyor_level() and float(game.card_cooldowns.get(seed,0)) > 0.01:
		game._show_toast("这张种子还在冷却"); return
	if source_seed.is_empty():
		source_cell = Vector2i(-1,-1); source_seed = seed
		game._show_toast("已选"+String(Defs.PLANTS[seed].name)+"；再点一张配方种子")
		return
	var id: String = Fusion.result(source_seed,seed)
	if id.is_empty(): game._show_toast("这两张种子没有配方，可改选第二张"); return
	prepared_seeds = [source_seed,seed]; prepared_result = id
	var error: String = resource_error()
	if not error.is_empty():
		prepared_seeds.clear(); prepared_result = ""; game._show_toast(error); return
	game.selected_tool = id; source_seed = ""
	game._show_toast("融合种子："+String(Defs.PLANTS[id].name)+"；选择地格种植")
	game.queue_redraw()

func prepared_cost() -> int:
	var total := 0
	for seed in prepared_seeds: total += game._endless_cost_for_kind(seed)
	return total

func resource_error() -> String:
	var needed: Dictionary = {}
	for seed in prepared_seeds: needed[seed] = int(needed.get(seed,0))+1
	for seed in needed:
		if not seed in game.active_cards: return "配方种子已经不在卡槽中"
		if game._is_conveyor_level():
			if game.active_cards.count(seed) < int(needed[seed]): return "传送带需要两张实际种子"
		elif float(game.card_cooldowns.get(seed,0)) > 0.01: return "配方种子还在冷却"
	if not game._is_conveyor_level() and game.sun_points < prepared_cost(): return "阳光不足：融合种子消耗两份种子费用"
	return ""

func prepared_error(row: int, col: int) -> String:
	var recipe: Dictionary = candidate(prepared_result,row,col)
	if not recipe.is_empty(): return placement_error(prepared_result,row,col,recipe)
	var d: Dictionary = Defs.PLANTS[prepared_result]
	var base: String = String(d.get("fusion_base",prepared_result))
	var support = game._support_plant_at(row,col)
	if game._top_plant_at(row,col) != null or (base in Fusion.SUPPORTS and support != null): return "这个格子已经被占用了"
	if game._vase_index_at(row,col) != -1 or game._grave_index_at(row,col) != -1: return "先清理花瓶或坟墓"
	if game._has_porcelain_shard(row,col) or game._has_wither_patch(row,col) or game._has_ice_tile(row,col): return "这块地皮暂时不能种植"
	var terrain: String = game._cell_terrain_kind(row,col)
	if not game._is_row_active(row) or terrain == "void": return "这里不能种植"
	if base in ["lily_pad","sea_shroom","tangle_kelp"] and terrain != "water": return "这个融合结果需要水路"
	if base == "flower_pot" and terrain not in ["land","roof","city_tile","rail","snowfield","volcano_tile"]: return "花盆融合需要实心地格"
	if base == "spikeweed" and terrain == "water": return "地刺融合不能种在水里"
	if base == "cotton_candy" and terrain not in ["cloud","sky_gap"]: return "这个融合结果需要云格"
	if terrain == "lava" and base != "cork_plug": return "岩浆需要先封堵"
	if terrain == "sky_gap" and base != "cotton_candy": return "这里没有云朵"
	if terrain == "water" and base not in ["lily_pad","sea_shroom","tangle_kelp"] and support == null: return "水路需要睡莲底座"
	if terrain in ["roof","city_tile","rail","snowfield","volcano_tile"] and base not in Fusion.SUPPORTS and support == null: return "这里需要先放底座"
	return ""

func plant_prepared(row: int, col: int) -> bool:
	var error: String = prepared_error(row,col)
	if error.is_empty(): error = resource_error()
	if not error.is_empty(): game._show_toast(error); return false
	var recipe: Dictionary = candidate(prepared_result,row,col)
	if not recipe.is_empty(): apply_seed(prepared_result,row,col,recipe)
	else:
		var p: Dictionary = game._create_plant(prepared_result,row,col)
		if String(p.kind) in Fusion.SUPPORTS: game.support_grid[row][col] = p
		else: game.grid[row][col] = p
		if String(p.kind) == "cork_plug" and game._cell_terrain_kind(row,col) == "lava": game._set_cell_terrain_kind(row,col,"volcano_tile")
		_emit(p,row,col,"fusion_bloom",62,0.8)
	if game._is_conveyor_level():
		for seed in prepared_seeds: game._consume_conveyor_card(seed)
	else:
		game.sun_points -= prepared_cost()
		for seed in prepared_seeds: game.card_cooldowns[seed] = game._endless_cooldown_for_kind(seed)
	reset(); game.selected_tool = ""; game.hover_preview_initialized = false
	game.queue_redraw()
	return true

func candidate(seed: String, row: int, col: int) -> Dictionary:
	if not enabled() or not Defs.PLANTS.has(seed): return {}
	var top = game._top_plant_at(row,col)
	var support = game._support_plant_at(row,col)
	# Waking, charging and ordinary armor attachment retain their original gestures.
	if seed == "coffee_bean" and top != null and float(top.get("sleep_timer",0)) > 0: return {}
	if seed in ["pumpkin","holy_flower","ice_cream"] and top != null and String(top.kind) != seed: return {}
	var layer: String = "support" if seed in Fusion.SUPPORTS else "grid"
	var host = support if layer == "support" else top
	if host == null and support != null and top == null:
		host = support; layer = "support"
	if host == null: return {}
	var id: String = Fusion.result(kind(host),seed)
	if id.is_empty(): return {}
	return {"id":id,"host":host,"layer":layer}

func placement_error(seed: String, row: int, col: int, recipe: Dictionary) -> String:
	var host: Dictionary = recipe.host
	if float(host.get("health",0)) <= 0: return "这株植物已经倒下"
	if game._vase_index_at(row,col) != -1: return "先打碎这个花瓶"
	if game._grave_index_at(row,col) != -1 and String(host.kind) != "grave_buster": return "这里有坟墓，先清理"
	if game._has_porcelain_shard(row,col) or game._has_wither_patch(row,col) or game._has_ice_tile(row,col): return "这块地皮暂时不能融合"
	if game._plant_charm_blocks_actions(host) or float(host.get("rooted_timer",0)) > 0 or bool(host.get("ultimate_active",false)): return "植物被控制或正在施放大招"
	if game.mokou_runtime != null and game.mokou_runtime.plant_stilled(row,col): return "符卡封印期间不能融合"
	if game.kaguya_runtime != null and game.kaguya_runtime.plant_stilled(row,col): return "符卡封印期间不能融合"
	var data: Dictionary = Defs.PLANTS[recipe.id]
	var base: String = String(data.get("fusion_base",recipe.id))
	var terrain: String = game._cell_terrain_kind(row,col)
	if not game._is_row_active(row) or terrain == "void": return "这里不能融合"
	if base in ["lily_pad","sea_shroom","tangle_kelp"] and terrain != "water": return "这个融合结果需要水路"
	if base == "flower_pot" and terrain not in ["land","roof","city_tile","rail","snowfield","volcano_tile"]: return "花盆融合需要实心地格"
	if base == "spikeweed" and terrain == "water": return "地刺融合不能种在水里"
	if base == "cotton_candy" and not terrain in ["cloud","sky_gap"]: return "这个融合结果需要云格"
	if terrain == "lava" and base != "cork_plug": return "岩浆需要先封堵"
	if terrain == "sky_gap" and base != "cotton_candy": return "没有云朵不能融合"
	if terrain == "water" and base not in ["lily_pad","sea_shroom","tangle_kelp"] and game._support_plant_at(row,col) == null: return "水路需要睡莲底座"
	if terrain in ["roof","city_tile","rail","snowfield","volcano_tile"] and base not in Fusion.SUPPORTS and game._support_plant_at(row,col) == null: return "这里需要先放底座"
	return ""

func create(id: String, row: int, col: int) -> Dictionary:
	var d: Dictionary = Defs.PLANTS[id]
	var base: String = d.fusion_base
	var p: Dictionary = game._create_plant(base,row,col)
	var health_scale: float = float(p.max_health) / float(Defs.PLANTS[base].health)
	p.fusion_kind = id; p.stats = d.duplicate(true)
	p.health = float(d.health)*health_scale; p.max_health = p.health
	p.fusion_attack_timer = 0.55; p.fusion_support_timer = 0.8; p.fusion_summon_timer = 18.0
	p.fusion_hypno_timer = 0.0; p.fusion_grave_timer = 0.0
	p.support_lifetime = 0.0 # A living graft replaces the temporary cork with a permanent root seal.
	if "awake" in d.fusion_traits: p.sleep_timer = 0.0
	p.sun_timer = minf(float(p.get("sun_timer",8)),8.0)
	if base == "pumpkin":
		p.armor_health = float(d.health); p.max_armor_health = float(d.health)
	return p

func combined(id: String, host: Dictionary, donor: Dictionary = {}) -> Dictionary:
	var p: Dictionary = create(id,int(host.row),int(host.col)) if bool(Defs.PLANTS[id].get("fusion_only",false)) else game._create_plant(id,int(host.row),int(host.col))
	var ratio: float = clampf(float(host.health)/maxf(float(host.max_health),1),0,1)
	if not donor.is_empty():
		ratio = (float(host.health)+float(donor.health))/maxf(float(host.max_health)+float(donor.max_health),1)
	p.health = maxf(1.0,float(p.max_health)*ratio)
	for field in ["sleep_timer","rooted_timer","ultimate_cooldown","special_timer","mystia_charm_timer","frozen_timer","fusion_hypno_timer","fusion_summon_timer","save_cooldown"]:
		p[field] = maxf(float(host.get(field,0)),float(donor.get(field,0)))
	p.ultimate_charge = minf(float(host.get("ultimate_charge",0)),float(donor.get("ultimate_charge",0))) if not donor.is_empty() else float(host.get("ultimate_charge",0))
	p.armor_health = float(host.get("armor_health",0))+float(donor.get("armor_health",0))
	p.max_armor_health = float(host.get("max_armor_health",0))+float(donor.get("max_armor_health",0))
	p.shell_kind = String(host.get("shell_kind",donor.get("shell_kind","")))
	for field in ["mystia_charmed","mystia_being_cooked","phoenix_revive_used"]:
		p[field] = bool(host.get(field,false)) or bool(donor.get(field,false))
	p.revives_used = maxi(int(host.get("revives_used",0)),int(donor.get("revives_used",0)))
	if "awake" in Defs.PLANTS[id].get("fusion_traits",[]): p.sleep_timer = 0.0
	# Do not refill production, attacks, resurrection or a charged ultimate by grafting.
	p.sun_timer = maxf(float(host.get("sun_timer",0)),float(donor.get("sun_timer",0)))
	p.fusion_attack_timer = maxf(0.55,maxf(float(host.get("fusion_attack_timer",host.get("shot_cooldown",0))),float(donor.get("fusion_attack_timer",donor.get("shot_cooldown",0)))))
	p.spawn_time = game.level_time
	return p

func apply_seed(seed: String, row: int, col: int, recipe: Dictionary) -> void:
	var p: Dictionary = combined(recipe.id,recipe.host)
	if recipe.layer == "support": game.support_grid[row][col] = p
	else: game.grid[row][col] = p
	_emit(p,row,col,"fusion_bloom",62,0.8)
	game._show_toast("融合成功："+String(Defs.PLANTS[recipe.id].name))

func merge_cells(from: Vector2i, to: Vector2i) -> bool:
	if not enabled() or from == to: return false
	if from.x < 0 or to.x < 0 or from.x >= game.ROWS or to.x >= game.ROWS or from.y < 0 or to.y < 0 or from.y >= game.COLS or to.y >= game.COLS: return false
	var a = game._targetable_plant_at(from.x,from.y); var b = game._targetable_plant_at(to.x,to.y)
	if a == null or b == null: return false
	var id: String = Fusion.result(kind(a),kind(b))
	if id.is_empty(): game._show_toast("这两株没有融合配方"); return false
	var layer: String = "grid" if game._top_plant_at(to.x,to.y) != null else "support"
	var recipe := {"id":id,"host":b,"layer":layer}
	var error: String = placement_error(kind(a),to.x,to.y,recipe)
	if error.is_empty(): error = placement_error(kind(b),from.x,from.y,{"id":kind(a),"host":a,"layer":"grid"}) if a.has("fusion_kind") else ""
	if not error.is_empty(): game._show_toast(error); return false
	if game._plant_charm_blocks_actions(a) or float(a.get("rooted_timer",0)) > 0 or bool(a.get("ultimate_active",false)): return false
	if game.mokou_runtime != null and game.mokou_runtime.plant_stilled(from.x,from.y): return false
	if game.kaguya_runtime != null and game.kaguya_runtime.plant_stilled(from.x,from.y): return false
	if float(a.health) <= 0: return false
	# A hybrid rooted in a pad/pot stays in the support layer in either input order.
	if String(Defs.PLANTS[id].get("fusion_base",id)) in Fusion.SUPPORTS:
		if layer == "grid" and game._support_plant_at(to.x,to.y) != null:
			game._show_toast("底座已有植物，请把融合对象种在空底座上"); return false
		layer = "support"
	var p: Dictionary = combined(id,b,a)
	if game._top_plant_at(from.x,from.y) != null: game.grid[from.x][from.y] = null
	else: game.support_grid[from.x][from.y] = null
	if layer == "support":
		if game._top_plant_at(to.x,to.y) == b: game.grid[to.x][to.y] = null
		game.support_grid[to.x][to.y] = p
	else: game.grid[to.x][to.y] = p
	_emit(p,to.x,to.y,"fusion_bloom",72,0.8)
	game._show_toast("融合成功："+String(Defs.PLANTS[id].name))
	return true

func click(cell: Vector2i) -> void:
	if source_cell.x < 0:
		var p = game._targetable_plant_at(cell.x,cell.y)
		if p == null: game._show_toast("先点选一株植物，再点融合对象"); return
		source_cell = cell; game._show_toast("选择融合对象；再次点击原植物取消")
	elif source_cell == cell: source_cell = Vector2i(-1,-1)
	elif merge_cells(source_cell,cell):
		source_cell = Vector2i(-1,-1); game.selected_tool = ""
	game.queue_redraw()

func _emit(p: Dictionary, row: int, col: int, shape: String, radius: float, duration: float, target: Vector2 = Vector2.INF) -> void:
	var d: Dictionary = Defs.PLANTS[kind(p)]
	game.effects.append({"shape":shape,"position":game._cell_center(row,col)+Vector2(0,-14),"target":target,"radius":radius,"time":duration,"duration":duration,"color":Color(0.7,0.94,0.6,0.75),"traits":d.get("fusion_traits",["shot"]),"tier":d.get("fusion_tier",1)})

func update(p: Dictionary, delta: float, row: int, col: int) -> void:
	var d: Dictionary = Defs.PLANTS[kind(p)]
	var t: Array = d.fusion_traits
	var cadence: float = game._plant_cadence_delta(delta,row,col)
	p.fusion_attack_timer = maxf(0,float(p.get("fusion_attack_timer",0))-cadence)
	p.fusion_support_timer = maxf(0,float(p.get("fusion_support_timer",0))-cadence)
	p.fusion_summon_timer = maxf(0,float(p.get("fusion_summon_timer",0))-delta)
	p.fusion_hypno_timer = maxf(0,float(p.get("fusion_hypno_timer",0))-delta)
	if "sun" in t:
		p.sun_timer = float(p.get("sun_timer",0))-delta
		if p.sun_timer <= 0:
			game._spawn_sun(game._cell_center(row,col)+Vector2(-12,-26),game._cell_center(row,col).y,"plant",maxi(25,int(d.sun_amount)))
			p.sun_timer = float(d.sun_interval)
			_emit(p,row,col,"fusion_sun",42,0.4)
	if p.fusion_support_timer <= 0:
		_support(p,row,col,false)
		p.fusion_support_timer = 3.0 if "heal" in t else 5.0
	if "torch" in t: game._ensure_plant_runtime().update_torchwood(p,delta,row,col)
	if p.fusion_attack_timer <= 0:
		if _attack(p,row,col,false):
			p.fusion_attack_timer = float(d.shoot_interval)
			game._trigger_plant_action(p,0.3)

func _support(p: Dictionary, row: int, col: int, ultimate: bool) -> void:
	var d: Dictionary = Defs.PLANTS[kind(p)]; var t: Array = d.fusion_traits
	var center: Vector2 = game._cell_center(row,col)
	var radius: float = game.CELL_SIZE.x * (3.0 if ultimate else 1.55)
	var tier: float = float(d.fusion_tier)
	if "reveal" in t:
		for i in range(game.zombies.size()):
			var z: Dictionary = game.zombies[i]
			if game._is_enemy_zombie(z) and center.distance_to(game._zombie_target_point(z,center)) <= radius:
				z.revealed_timer = maxf(float(z.get("revealed_timer",0)),6.0)
		if ultimate: game._trigger_blover_fog_clear(10.0)
	if "wind" in t and ultimate: game._trigger_blover_fog_clear(8.0)
	if "awake" in t: game._wake_plants_in_radius(center,radius)
	if "heal" in t or "shield" in t:
		for r in range(game.ROWS):
			for c in range(game.COLS):
				if center.distance_to(game._cell_center(r,c)) > radius: continue
				var ally = game._targetable_plant_at(r,c)
				if ally == null: continue
				if "heal" in t: game._heal_targetable_plant_cell(r,c,float(d.get("fusion_heal",90 if ultimate else 14))*(2.5 if ultimate else 1.0))
				if "shield" in t:
					var limit: float = minf(900,float(ally.max_health)*0.4)
					ally.armor_health = minf(limit,float(ally.get("armor_health",0))+(180 if ultimate else 20)*(1+tier*0.3)) if float(ally.get("armor_health",0)) < limit else float(ally.armor_health)
					ally.max_armor_health = maxf(float(ally.get("max_armor_health",0)),float(ally.armor_health))
					game._set_targetable_plant(r,c,ally)
		_emit(p,row,col,"fusion_guard",radius,0.45)
	if "grave" in t:
		for i in range(game.graves.size()-1,-1,-1):
			var grave: Dictionary = game.graves[i]
			if center.distance_to(game._cell_center(int(grave.row),int(grave.col))) < radius:
				game.graves.remove_at(i)
	if "cooling" in t and game.has_method("_ensure_volcano_expansion"):
		# Cooling uses the same safe lava API as steam clover, without changing terrain.
		game._ensure_volcano_expansion().cool(Vector2i(row,col),2 if ultimate else 1,12.0 if ultimate else 6.0)
	if "summon" in t and float(p.fusion_summon_timer) <= 0:
		var friends := 0
		for z in game.zombies:
			if bool(z.get("fusion_spirit",false)) and not game._is_enemy_zombie(z): friends += 1
		if friends < 3:
			game._spawn_zombie_at("normal",row,center.x+36)
			if not game.zombies.is_empty():
				var index: int = game.zombies.size()-1
				game.zombies[index] = game._hypnotize_zombie(game.zombies[index]); game.zombies[index].fusion_spirit = true
		p.fusion_summon_timer = 22.0
	if "magnet" in t:
		var count := 0
		for i in range(game.zombies.size()):
			var z: Dictionary = game.zombies[i]
			if not game._is_enemy_zombie(z) or center.distance_to(game._zombie_target_point(z,center)) > radius: continue
			if game._ensure_plant_runtime().can_magnet_strip(z):
				game.zombies[i] = game._ensure_plant_runtime().strip_metal_from_zombie(z)
				count += 1
				if count >= (5 if ultimate else 1): break
		if count > 0: _emit(p,row,col,"fusion_magnet",radius,0.45)

func _status(z: Dictionary, p: Dictionary, row: int, col: int, ultimate: bool) -> Dictionary:
	var t: Array = Defs.PLANTS[kind(p)].fusion_traits
	if "frost" in t: z = game._apply_zombie_slow(z,0.35,5.0 if ultimate else 2.8)
	if "stun" in t or "shock" in t: z.frozen_timer = maxf(float(z.get("frozen_timer",0)),1.0 if ultimate else 0.25)
	if "root" in t: z.rooted_timer = maxf(float(z.get("rooted_timer",0)),4.0 if ultimate else 1.2)
	if "fire" in t or "poison" in t:
		z.corrode_timer = maxf(float(z.get("corrode_timer",0)),4.0)
		z.corrode_dps = maxf(float(z.get("corrode_dps",0)),16.0 if ultimate else 7.0)
	if "reveal" in t: z.revealed_timer = maxf(float(z.get("revealed_timer",0)),6.0)
	if "wind" in t and not game._is_boss_zombie(z): z.x = minf(float(z.x)+(90 if ultimate else 20),game.BOARD_ORIGIN.x+game.board_size.x+30)
	if "redirect" in t and not game._is_boss_zombie(z):
		var next: int = clampi(row+(1 if row < game.ROWS-1 else -1),0,game.ROWS-1)
		if game._is_row_active(next) and game._cell_terrain_kind(next,col) == game._cell_terrain_kind(int(z.row),col): z.row = next
	if "hypno" in t and not game._is_boss_zombie(z) and float(p.fusion_hypno_timer) <= 0:
		z.fusion_dream_stacks = int(z.get("fusion_dream_stacks",0))+ (4 if ultimate else 1)
		if int(z.fusion_dream_stacks) >= 4 and float(z.health) > 0:
			z = game._hypnotize_zombie(z); p.fusion_hypno_timer = 18.0
	return z

func _attack(p: Dictionary, row: int, col: int, ultimate: bool) -> bool:
	var d: Dictionary = Defs.PLANTS[kind(p)]; var t: Array = d.fusion_traits
	var center: Vector2 = game._cell_center(row,col)
	var style: String = d.fusion_attack
	var damage: float = float(d.damage)*game._projectile_damage_multiplier_for_spawn(row,center,String(p.kind))*(3.0 if ultimate else 1.0)
	var range_limit: float = game.board_size.x if style in ["shooter","sun","blade","beam","spread","lobber","roller"] else game.CELL_SIZE.x*(4.0 if ultimate else 1.6)
	var lanes: int = 2 if ultimate else (1 if "lanes" in t or style in ["spread","bomb"] else 0)
	var targets: Array = []
	var target_rows: Dictionary = {}
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not game._is_enemy_zombie(z) or float(z.health) <= 0 or not game._is_row_active(int(z.row)): continue
		var attack_lane := -1
		var lane_choices: Array = [row]
		for offset in range(1,lanes+1): lane_choices.append_array([row-offset,row+offset])
		for lane in lane_choices:
			if lane < 0 or lane >= game.ROWS or not game._is_row_active(lane) or not game._zombie_has_row(z,lane): continue
			var x: float = game._zombie_lane_x(z,lane)
			if absf(x-center.x) > range_limit or (x < center.x-16 and not style in ["guard","control","support","bomb","melee"]): continue
			if style in ["shooter","sun","blade","beam","spread"] and game._is_roof_direct_fire_blocked(center.x,x,lane): continue
			attack_lane = lane; break
		if attack_lane < 0: continue
		if "ground" in t and (bool(z.get("balloon_flying",false)) or bool(z.get("jumping",false))): continue
		if game._is_hidden_from_lane_attacks(z): continue
		targets.append(i); target_rows[i] = attack_lane
	if style in ["support","sun"] and not "shot" in t:
		if ultimate and "sun" in t: game._spawn_sun(center+Vector2(0,-30),center.y,"plant_food",maxi(100,int(d.sun_amount)*3))
		if ultimate:
			for index in targets: game.zombies[index] = _status(game.zombies[index],p,row,col,true)
		return false
	if targets.is_empty(): return false
	if style == "roller":
		game._ensure_projectile_runtime().spawn_mango_roller(row,col,ultimate)
		var roller: Dictionary = game.rollers.back()
		roller.damage = damage; roller.splash_ratio = 0.5
		roller.fusion_traits = t; roller.fusion_source = kind(p)
	elif style == "lobber":
		var z: Dictionary = game.zombies[int(targets[0])]
		game._ensure_plant_runtime().spawn_roof_lobbed_projectile("fusion_seed",int(target_rows[targets[0]]),center+Vector2(8,-25),game._zombie_lane_point(z,int(target_rows[targets[0]])),float(d.damage)*(3.0 if ultimate else 1.0),Color(0.86,0.74,0.34),90,12,80 if "splash" in t else 0,2 if "stun" in t else 0,String(p.kind))
		_decorate_projectile(game.projectiles.back(),p)
		game.projectiles.back().fusion_ultimate = ultimate
	elif style in ["shooter","sun","spread","blade"]:
		var count: int = int(d.fusion_shots)*(3 if ultimate else 1)
		var fired_rows: Array = []
		for index in targets:
			var lane: int = int(target_rows[index])
			if fired_rows.has(lane): continue
			fired_rows.append(lane)
			for s in range(count):
				var origin: Vector2 = Vector2(center.x+26+(s/2)*3,game._row_center_y(lane)-16+(s%4)*6)
				game._spawn_projectile(lane,origin,Color(0.5,0.89,0.44),float(d.damage)*(3.0 if ultimate else 1.0),3.5 if "frost" in t else 0,480,7,String(p.kind))
				var shot: Dictionary = game.projectiles.back(); _decorate_projectile(shot,p)
				shot.fusion_ultimate = ultimate
				if style == "blade":
					shot.kind = "boomerang"; shot.pierce_left = 3; shot.hit_uids = []; shot.max_hits = 3; shot.anchor_x = center.x; shot.outbound = true; shot.return_hits = []; shot.return_markers = []; shot.return_damage = float(shot.damage)*0.7
	else:
		var hits := 0
		for index in targets:
			var z: Dictionary = game.zombies[index]
			z = game._apply_zombie_damage(z,damage,0.16,3 if "frost" in t else 0,false,style == "beam" or "pierce" in t,center.x)
			z = _status(z,p,row,col,ultimate)
			game.zombies[index] = z
			hits += 1
			if style == "control" and hits >= (8 if ultimate else 4): break
		_emit(p,row,col,"fusion_beam" if style == "beam" else "fusion_wave",range_limit,0.4,game._zombie_target_point(game.zombies[int(targets[0])],center))
	_emit(p,row,col,"fusion_muzzle",30,0.22)
	return true

func _decorate_projectile(shot: Dictionary, p: Dictionary) -> void:
	var d: Dictionary = Defs.PLANTS[kind(p)]; var t: Array = d.fusion_traits
	shot.fusion_traits = t; shot.fusion_source = kind(p)
	shot.color = Color(0.97,0.56,0.25) if "fire" in t else (Color(0.5,0.88,1.0) if "frost" in t else Color(0.64,0.89,0.46))
	if "fire" in t: shot.fire = true
	if "pierce" in t: shot.pierce_left = 2; shot.pierce_handheld = true; shot.hit_uids = []
	if "splash" in t: shot.splash_radius = 65.0

func projectile_hit(z: Dictionary, shot: Dictionary) -> Dictionary:
	if not shot.has("fusion_source") or not game._is_enemy_zombie(z): return z
	var p := {"kind":"peashooter","fusion_kind":shot.fusion_source,"fusion_hypno_timer":0.0}
	# Projectile dream spores cannot bypass a boss's immunity or the four-hit threshold.
	return _status(z,p,int(z.row),0,bool(shot.get("fusion_ultimate",false)))

func impact(shot: Dictionary, center: Vector2, skip_index: int = -1, splash: bool = false) -> void:
	var radius: float = maxf(42,float(shot.get("splash_radius",0)))
	var hits := 0
	for i in range(game.zombies.size()):
		if i == skip_index: continue
		var z: Dictionary = game.zombies[i]
		if not game._is_enemy_zombie(z) or game._is_hidden_from_lane_attacks(z): continue
		if bool(z.get("balloon_flying",false)) or bool(z.get("jumping",false)): continue
		if game._zombie_target_point(z,center).distance_to(center) > radius: continue
		var damage: float = float(shot.damage)*(0.5 if splash else 1.0)
		z = game._apply_zombie_damage(z,damage,0.14,0,false,bool(shot.get("pierce_handheld",false)),center.x)
		game.zombies[i] = projectile_hit(z,shot)
		hits += 1
		if not splash and float(shot.get("splash_radius",0)) <= 0 and hits >= 1: break
	game._damage_obstacles_in_circle(center,radius,float(shot.damage)*0.5)
	game.effects.append({"shape":"fusion_wave","position":center,"radius":radius,"time":0.35,"duration":0.35,"traits":shot.fusion_traits,"tier":2,"color":shot.get("color",Color.WHITE)})

func ultimate(p: Dictionary, row: int, col: int) -> void:
	_support(p,row,col,true)
	_attack(p,row,col,true)
	_emit(p,row,col,"fusion_ultimate",170,1.2)
	p.ultimate_active = true; p.ultimate_timer = 1.2; p.ultimate_charge = 0.0
	p.ultimate_cooldown = 90.0
