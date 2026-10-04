extends RefCounted
const NativeRuntime = preload("res://scripts/runtime/fusion_native_runtime.gd")
var native_runtime = null
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
	if seed in Fusion.EXCLUDED:
		game._show_toast("花盆和睡莲只作底座，不参与融合"); return
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
	p.fusion_channel_timers = {}
	for channel in d.fusion_channels: p.fusion_channel_timers[channel.source] = float(channel.initial_delay)
	p.fusion_attack_timer = 0.55; p.fusion_support_timer = 0.8; p.fusion_summon_timer = 18.0
	p.fusion_hypno_timer = 0.0; p.fusion_grave_timer = 0.0
	p.support_lifetime = 0.0 # A living graft replaces the temporary cork with a permanent root seal.
	if "awake" in d.fusion_traits or _has_daytime_component(d): p.sleep_timer = 0.0
	p.fusion_skill_echoes = 0; p.fusion_echo_timer = 0.0
	p.fusion_passive_timers = {}; p.fusion_native_states = {}; p.pressure_ammo = 0; p.fusion_copy_damage = 0.0
	p.fusion_haste_timer = 0.0; p.fusion_renewal_timer = 0.0
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
	if "awake" in Defs.PLANTS[id].get("fusion_traits",[]) or _has_daytime_component(Defs.PLANTS[id]): p.sleep_timer = 0.0
	if String(p.kind) == "pumpkin":
		p.armor_health = maxf(float(p.armor_health),float(p.max_health)*ratio*0.35)
		p.max_armor_health = maxf(float(p.max_armor_health),float(p.max_health)*0.35)
	# Do not refill production, attacks, resurrection or a charged ultimate by grafting.
	p.sun_timer = maxf(float(host.get("sun_timer",0)),float(donor.get("sun_timer",0)))
	p.fusion_attack_timer = maxf(0.55,maxf(float(host.get("fusion_attack_timer",host.get("shot_cooldown",0))),float(donor.get("fusion_attack_timer",donor.get("shot_cooldown",0)))))
	if p.has("fusion_kind"):
		for channel in Defs.PLANTS[id].fusion_channels:
			var source: String = channel.source
			var inherited_cooldown: float = maxf(float(host.get("fusion_channel_timers",{}).get(source,0)),float(donor.get("fusion_channel_timers",{}).get(source,0)))
			# A donor heavy weapon also carries its native loading/arming time.
			for input in [host,donor]:
				if String(input.get("kind","")) == source:
					inherited_cooldown = maxf(inherited_cooldown,float(input.get("shot_cooldown",input.get("attack_timer",0))))
			var carried := false
			for input in [host,donor]:
				if input.get("fusion_channel_timers",{}).has(source): carried = true
			p.fusion_channel_timers[source] = inherited_cooldown if carried else maxf(inherited_cooldown,float(channel.initial_delay))
	if p.has("fusion_kind"):
		for input in [host,donor]:
			if input.is_empty(): continue
			var states: Dictionary = input.get("fusion_native_states",{}).duplicate(true)
			if not input.has("fusion_kind"):
				var source: String = "peashooter" if input.kind == "repeater" else String(input.kind)
				states[source] = input.duplicate(true); states[source].kind = source
			for source in states:
				if not Defs.PLANTS[id].fusion_weights.has(source): continue
				if not p.fusion_native_states.has(source): p.fusion_native_states[source] = states[source]
				else:
					for clock in NativeRuntime.CLOCKS+["action_timer","sun_timer","charge_timer","grow_timer","save_cooldown"]:
						p.fusion_native_states[source][clock] = maxf(float(p.fusion_native_states[source].get(clock,0)),float(states[source].get(clock,0)))
				if source == "corn_cannon": p.corn_reload = p.fusion_native_states[source].get("action_timer",0)

	p.reflect_cooldown_until = maxf(float(host.get("reflect_cooldown_until",0)),float(donor.get("reflect_cooldown_until",0)))
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
	# Support grafts keep their layer and never consume the underlying terrain base.
	if String(Defs.PLANTS[id].get("fusion_base",id)) in Fusion.SUPPORTS:
		if layer != "grid" or game._support_plant_at(to.x,to.y) == null: layer = "support"
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
	if int(p.get("fusion_skill_echoes",0)) > 0:
		p.fusion_echo_timer = float(p.get("fusion_echo_timer",0))-delta
		if p.fusion_echo_timer <= 0:
			_ultimate_strike(p,row,col)
			p.fusion_skill_echoes -= 1; p.fusion_echo_timer += 0.45
	p.fusion_attack_timer = maxf(0,float(p.get("fusion_attack_timer",0))-cadence)
	p.fusion_support_timer = maxf(0,float(p.get("fusion_support_timer",0))-cadence)
	p.fusion_summon_timer = maxf(0,float(p.get("fusion_summon_timer",0))-delta)
	p.fusion_hypno_timer = maxf(0,float(p.get("fusion_hypno_timer",0))-delta)
	if native_runtime == null: native_runtime = NativeRuntime.new(game)
	native_runtime.update(p,delta,row,col)
	for channel in d.fusion_channels:
		if channel.style != "burst": continue
		var source: String = channel.source
		p.fusion_channel_timers[source] = maxf(0,float(p.fusion_channel_timers.get(source,channel.initial_delay))-delta)
		if p.fusion_channel_timers[source] <= 0 and _burst(p,row,col,channel,false):
			p.fusion_channel_timers[source] = float(channel.interval)
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
		_summon_spirits(row,col,1)
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

func _summon_spirits(row: int, col: int, requested: int) -> void:
	var friends := 0
	for z in game.zombies:
		if bool(z.get("fusion_spirit",false)) and float(z.health) > 0 and not game._is_enemy_zombie(z): friends += 1
	for n in range(mini(requested,maxi(0,3-friends))):
		var lane: int = clampi(row+(n%3)-1,0,game.ROWS-1) if requested > 1 else row
		if not game._is_row_active(lane): lane = row
		game._spawn_zombie_at("normal",lane,game._cell_center(row,col).x+36)
		var index: int = game.zombies.size()-1
		game.zombies[index] = game._hypnotize_zombie(game.zombies[index])
		game.zombies[index].fusion_spirit = true

func _status(z: Dictionary, p: Dictionary, row: int, col: int, ultimate: bool) -> Dictionary:
	var t: Array = p.get("fusion_hit_traits",Defs.PLANTS[kind(p)].fusion_traits)
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

func _channel_definition(p: Dictionary, channel: Dictionary) -> Dictionary:
	var d: Dictionary = Defs.PLANTS[kind(p)].duplicate(false)
	if not channel.is_empty():
		d.damage = channel.damage; d.fusion_attack = channel.style; d.shoot_interval = channel.interval
		d.fusion_shots = channel.shots; d.fusion_traits = channel.traits
	return d

func _decorate_projectile(shot: Dictionary, p: Dictionary, channel: Dictionary = {}) -> void:
	var d: Dictionary = _channel_definition(p,channel); var t: Array = d.fusion_traits
	shot.fusion_channel_source = channel.get("source","")
	shot.fusion_mechanics = channel.get("mechanics",{})
	shot.anti_air = "anti_air" in t
	var source: String = channel.get("source","")
	if source == "amber_shooter": shot.kind = "amber_pea"; shot.armor_bonus_mult = 2.0
	if source == "prism_pea":
		shot.kind = "prism_pea"; shot.split_at_x = float(Vector2(shot.position).x)+160; shot.split_count = 3; shot.fragment_damage = float(shot.damage)*0.65
	if source in ["sakura_shooter","glowvine"]:
		shot.kind = "sakura_petal" if source == "sakura_shooter" else "glow_seed"
	if source == "brine_pot" or source == "fumarole_melon": shot.splash_radius = 78.0
	shot.fusion_traits = t; shot.fusion_source = kind(p)
	shot.color = Color(0.97,0.56,0.25) if "fire" in t else (Color(0.5,0.88,1.0) if "frost" in t else Color(0.64,0.89,0.46))
	if "fire" in t: shot.fire = true
	if "pierce" in t: shot.pierce_left = 2; shot.pierce_handheld = true; shot.hit_uids = []
	if "splash" in t: shot.splash_radius = float(channel.get("radius",65.0))

func projectile_hit(z: Dictionary, shot: Dictionary) -> Dictionary:
	if not shot.has("fusion_source") or not game._is_enemy_zombie(z): return z
	if bool(shot.get("fusion_native",false)): return NativeRuntime.Ammo.apply_status(z,shot)
	var p := {"kind":"peashooter","fusion_kind":shot.fusion_source,"fusion_hypno_timer":0.0,"fusion_hit_traits":shot.get("fusion_traits",[])}
	# Projectile dream spores cannot bypass a boss's immunity or the four-hit threshold.
	z = _status(z,p,int(z.row),0,bool(shot.get("fusion_ultimate",false)))
	return _native_ammo_status(z,shot.get("fusion_channel_source",""),shot.get("fusion_mechanics",{}),bool(shot.get("fusion_ultimate",false)))

func impact(shot: Dictionary, center: Vector2, skip_index: int = -1, splash: bool = false) -> void:
	if shot.has("fusion_blast"):
		_burst_impact(shot,center)
		return
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
	_native_impact(shot,center)
	game.effects.append({"shape":"fusion_wave","position":center,"radius":radius,"time":0.35,"duration":0.35,"traits":shot.fusion_traits,"tier":2,"color":shot.get("color",Color.WHITE)})

func _has_daytime_component(d: Dictionary) -> bool:
	for component in d.get("fusion_components",[]):
		if not game._is_sleepy_mushroom_kind(component): return true
	return false

func tick_buffs(p: Dictionary, delta: float) -> void:
	p.fusion_haste_timer = maxf(0,float(p.get("fusion_haste_timer",0))-delta)
	p.fusion_renewal_timer = maxf(0,float(p.get("fusion_renewal_timer",0))-delta)
	if float(p.fusion_renewal_timer) > 0: game._restore_plant_health(p,18.0*delta,false)

func _skill_effect(p: Dictionary, row: int, col: int, skill: String, target: Vector2 = Vector2.INF) -> void:
	if game.effects.size() >= 600: return
	var d: Dictionary = Defs.PLANTS[kind(p)]
	game.effects.append({"shape":"fusion_skill","skill":skill,"position":game._cell_center(row,col)+Vector2(0,-14),"target":target,"radius":160.0,"time":1.4,"duration":1.4,"color":Color.WHITE,"traits":d.fusion_traits,"tier":d.fusion_tier})

func _garden(p: Dictionary, row: int, col: int, fortified: bool = false) -> void:
	var center: Vector2 = game._cell_center(row,col)
	for r in range(game.ROWS):
		for c in range(game.COLS):
			if center.distance_to(game._cell_center(r,c)) > game.CELL_SIZE.x*3.2: continue
			for layer in ["grid","support"]:
				var ally = game.grid[r][c] if layer == "grid" else game.support_grid[r][c]
				if ally == null or float(ally.health) <= 0 or game._plant_charm_blocks_actions(ally): continue
				game._restore_plant_health(ally,float(ally.max_health)*0.3,false)
				ally.fusion_haste_timer = maxf(float(ally.get("fusion_haste_timer",0)),10.0)
				ally.armor_health = maxf(float(ally.get("armor_health",0)),minf(1500,float(ally.max_health)*0.5+160))
				ally.max_armor_health = maxf(float(ally.get("max_armor_health",0)),float(ally.armor_health))
				if fortified: ally.holy_invincible_timer = maxf(float(ally.get("holy_invincible_timer",0)),2.0)

func _skill_damage(p: Dictionary, row: int, col: int, skill: String) -> void:
	var d: Dictionary = Defs.PLANTS[kind(p)]
	var center: Vector2 = game._cell_center(row,col)
	var damage: float = float(d.fusion_utility_damage)*game._projectile_damage_multiplier_for_spawn(row,center,String(p.kind))
	var visible_hits := 0
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not game._is_enemy_zombie(z) or float(z.health) <= 0: continue
		if skill == "beacon": z.revealed_timer = maxf(float(z.get("revealed_timer",0)),10.0)
		if skill in ["tornado","vortex"] and bool(z.get("balloon_flying",false)):
			z.balloon_flying = false; z.flying = false
			game.zombies[i] = z
		if game._is_hidden_from_lane_attacks(z):
			game.zombies[i] = z
			continue
		var point: Vector2 = game._zombie_target_point(z,center)
		if skill == "roots" and point.distance_to(center) > game.CELL_SIZE.x*3.2:
			z.rooted_timer = maxf(float(z.get("rooted_timer",0)),4.0)
			game.zombies[i] = z
			if visible_hits < 4: _skill_effect(p,row,col,skill,point); visible_hits += 1
			continue
		if skill in ["minefield","devour"] and point.distance_to(center) > game.CELL_SIZE.x*3.2: continue
		if skill == "devour" and (bool(z.get("balloon_flying",false)) or bool(z.get("jumping",false))): continue
		if skill in ["minefield","purge"] and bool(z.get("balloon_flying",false)): continue
		if skill in ["laser","rail_storm","sun_lance","beacon"] and game._is_roof_direct_fire_blocked(center.x,point.x,game._zombie_target_row(z,point)): continue
		var hit: float = minf(damage,float(z.health)*0.1) if skill == "dream" else damage
		z = game._apply_zombie_damage(z,hit,0.18,0,false,skill in ["laser","rail_storm","sun_lance","beacon","needles"],center.x)
		z = _status(z,p,int(z.row),col,true)
		match skill:
			"blizzard": z = game._apply_zombie_slow(z,0.35,5.0); z.frozen_timer = maxf(float(z.get("frozen_timer",0)),1.0)
			"roots": z.rooted_timer = maxf(float(z.get("rooted_timer",0)),4.0)
			"lightning","rail_storm": z.frozen_timer = maxf(float(z.get("frozen_timer",0)),0.65)
			"inferno","miasma","steam": z.corrode_timer = maxf(float(z.get("corrode_timer",0)),8.0); z.corrode_dps = maxf(float(z.get("corrode_dps",0)),24.0)
			"domain": z.rooted_timer = maxf(float(z.get("rooted_timer",0)),2.0); z = game._apply_zombie_slow(z,0.35,4.0)
			"dream":
				if not game._is_boss_zombie(z) and float(z.health) > 0: z = game._hypnotize_zombie(z)
				else: z.rooted_timer = maxf(float(z.get("rooted_timer",0)),2.0)
			"tornado","vortex":
				if not game._is_boss_zombie(z):
					z.x = minf(float(z.x)+100,game.BOARD_ORIGIN.x+game.board_size.x+30)
					if bool(z.get("balloon_flying",false)): z.balloon_flying = false; z.flying = false
		game.zombies[i] = z
		if visible_hits < 4: _skill_effect(p,row,col,skill,point); visible_hits += 1
	if skill == "devour": game._restore_plant_health(p,float(p.max_health)*0.25,false)

func _ultimate_strike(p: Dictionary, row: int, col: int, opening: bool = false) -> void:
	var d: Dictionary = Defs.PLANTS[kind(p)]
	if native_runtime == null: native_runtime = NativeRuntime.new(game)
	native_runtime.update(p,0.01,row,col,true,opening)
	for skill in d.fusion_skills:
		if skill in ["steam","miasma"]: _skill_damage(p,row,col,skill)
	_skill_effect(p,row,col,d.fusion_skills[0])

func ultimate(p: Dictionary, row: int, col: int) -> void:
	var d: Dictionary = Defs.PLANTS[kind(p)]; var center: Vector2 = game._cell_center(row,col)
	_support(p,row,col,true)
	for skill in d.fusion_skills:
		match skill:
			"minefield":
				for channel in d.fusion_channels:
					if channel.style == "burst":
						_burst(p,row,col,channel,true)
						p.fusion_channel_timers[channel.source] = float(channel.interval)
			"reflection":
				if game.touhou_danmaku != null:
					for bullet in game.touhou_danmaku.bullets:
						if not bool(bullet.get("reflected",false)): game._bounce_boss_danmaku(bullet,Vector2i(row,col),true,false)
				for r in range(maxi(0,row-1),mini(game.ROWS,row+2)):
					for c in range(maxi(0,col-1),mini(game.COLS,col+2)):
						var ally = game._targetable_plant_at(r,c)
						if ally != null: ally.fusion_mirror_until = game.level_time+3.0
				_garden(p,row,col)
			"solar":
				for n in range(3): game._spawn_sun(center+Vector2((n-1)*30,-35),center.y,"plant_food",maxi(50,int(d.sun_amount)*2))
			"garden","awakening": _garden(p,row,col); game._wake_plants_in_radius(center,game.CELL_SIZE.x*3.2)
			"bastion","spring": _garden(p,row,col,true)
			"renewal":
				_garden(p,row,col)
				for r in range(game.ROWS):
					for c in range(game.COLS):
						var ally = game._targetable_plant_at(r,c)
						if ally != null and center.distance_to(game._cell_center(r,c)) < game.CELL_SIZE.x*3.2: ally.fusion_renewal_timer = 8.0
			"spirits": _summon_spirits(row,col,3); p.fusion_summon_timer = 22.0
			"tornado","vortex": game._trigger_blover_fog_clear(8.0); _skill_damage(p,row,col,skill)
			"magnetic": _support(p,row,col,true); _skill_damage(p,row,col,"rail_storm")
			"beacon": game._trigger_blover_fog_clear(10.0); _skill_damage(p,row,col,skill)
			"purge","dream","roots","lightning","blizzard","inferno","needles","rail_storm","sun_lance": _skill_damage(p,row,col,skill)
		_skill_effect(p,row,col,skill)
	_ultimate_strike(p,row,col,true)
	p.fusion_skill_echoes = 2 if d.fusion_weapon_skills.any(func(skill): return skill in ["barrage","blades","constellation","bowling","meteor"]) or "steam" in d.fusion_skills or "miasma" in d.fusion_skills else 0
	p.fusion_echo_timer = 0.45
	p.ultimate_active = true; p.ultimate_timer = 2.4; p.ultimate_charge = 0.0
	p.ultimate_cooldown = 90.0

func _channel_status(z: Dictionary, p: Dictionary, channel: Dictionary, row: int, col: int, ultimate: bool) -> Dictionary:
	p.fusion_hit_traits = channel.get("traits",Defs.PLANTS[kind(p)].fusion_traits)
	z = _status(z,p,row,col,ultimate)
	p.erase("fusion_hit_traits")
	return _native_ammo_status(z,channel.get("source",""),channel.get("mechanics",{}),ultimate)

func _native_ammo_status(z: Dictionary, source: String, data: Dictionary, ultimate: bool) -> Dictionary:
	if not game._is_enemy_zombie(z): return z
	if source == "kernel_pult" and (ultimate or game.rng.randf() < float(data.get("butter_chance",0.25))):
		z.frozen_timer = maxf(float(z.get("frozen_timer",0)),float(data.get("butter_duration",3.2)))
	if source == "sulfur_pod": z.sulfur_brittle_until = maxf(float(z.get("sulfur_brittle_until",0)),game.level_time+4.0)
	if source == "obsidian_artichoke" and float(z.get("shield_health",0)) > 0: z = game._apply_zombie_damage(z,80,0.1)
	if data.has("slow_duration"): z = game._apply_zombie_slow(z,float(data.get("slow_ratio",0.35)),float(data.slow_duration))
	if data.has("root_duration") or data.has("rooted_duration"):
		z.rooted_timer = maxf(float(z.get("rooted_timer",0)),float(data.get("root_duration",data.get("rooted_duration",2.8))))
	if data.has("burn_damage") or data.has("dot_damage"):
		z.corrode_timer = maxf(float(z.get("corrode_timer",0)),float(data.get("burn_duration",data.get("dot_duration",4.0))))
		z.corrode_dps = maxf(float(z.get("corrode_dps",0)),float(data.get("burn_damage",data.get("dot_damage",0))))
	return z

func _burst(p: Dictionary, row: int, col: int, channel: Dictionary, ultimate: bool) -> bool:
	var center: Vector2 = game._cell_center(row,col)
	var delivery: bool = bool(channel.deliver) and Defs.PLANTS[kind(p)].fusion_channels.any(func(c): return c.style in ["shooter","spread","beam","lobber","blade","roller"])
	var candidates: Array = []
	var reach: float = game.board_size.x if delivery or channel.blast_shape in ["row","freeze"] else float(channel.get("range",channel.radius))*(2.5 if ultimate else 1)
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not game._is_enemy_zombie(z) or float(z.health) <= 0: continue
		if channel.blast_shape != "freeze" and game._is_hidden_from_lane_attacks(z): continue
		if delivery and not game._zombie_has_row(z,row): continue
		var point: Vector2 = game._zombie_target_point(z,center)
		if delivery and point.x < center.x-16: continue
		if not delivery and channel.blast_shape == "row" and not game._zombie_has_row(z,row): continue
		if point.distance_to(center) > reach: continue
		if channel.source in ["potato_mine","squash","tangle_kelp","chomper"] and (bool(z.get("balloon_flying",false)) or bool(z.get("jumping",false))): continue
		candidates.append({"index":i,"point":point,"distance":point.distance_squared_to(center)})
	candidates.sort_custom(func(a,b): return a.distance < b.distance)
	if candidates.is_empty() and not ultimate: return false
	var impact: Vector2 = candidates[0].point if delivery and not candidates.is_empty() else center
	if channel.blast_shape == "single" and not candidates.is_empty(): impact = candidates[0].point
	var burst: Dictionary = channel.duplicate(true)
	burst.damage = float(channel.damage)*(1.3 if ultimate else 1.0)
	if ultimate and channel.blast_shape == "circle": burst.radius = float(channel.radius)*1.3
	if delivery:
		game._ensure_plant_runtime().spawn_roof_lobbed_projectile("fusion_burst",row,center+Vector2(8,-25),impact,float(burst.damage),Color("f8b57b"),110,13,float(burst.radius),0,String(p.kind))
		var shot: Dictionary = game.projectiles.back()
		_decorate_projectile(shot,p,channel)
		shot.splash_radius = float(burst.radius); shot.fusion_blast = burst; shot.fusion_ultimate = ultimate
	else:
		var shot := {"damage":float(burst.damage)*game._projectile_damage_multiplier_for_spawn(row,center,String(p.kind)),"row":row,"fusion_source":kind(p),"fusion_channel_source":channel.source,"fusion_traits":channel.traits,"fusion_blast":burst,"fusion_ultimate":ultimate}
		_burst_impact(shot,impact)
	_skill_effect(p,row,col,"minefield",impact)
	if channel.source == "chomper" and ultimate: game._restore_plant_health(p,float(p.max_health)*0.25,false)
	return true

func _burst_impact(shot: Dictionary, center: Vector2) -> void:
	var b: Dictionary = shot.fusion_blast
	var row: int = int(shot.row)
	var radius: float = float(b.radius)
	var shape: String = b.blast_shape
	var struck := 0
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not game._is_enemy_zombie(z) or float(z.health) <= 0: continue
		if shape != "freeze" and game._is_hidden_from_lane_attacks(z): continue
		if shape == "row":
			if not game._zombie_has_row(z,row): continue
		elif game._zombie_target_point(z,center).distance_to(center) > radius: continue
		if b.source in ["potato_mine","squash","tangle_kelp","chomper"] and (bool(z.get("balloon_flying",false)) or bool(z.get("jumping",false))): continue
		if shape == "single" and struck > 0: break
		z = game._apply_zombie_damage(z,float(shot.damage),0.2)
		if shape == "freeze":
			z.frozen_timer = maxf(float(z.get("frozen_timer",0)),float(b.mechanics.get("freeze_duration",2.5)))
			z = game._apply_zombie_slow(z,0.35,float(b.mechanics.get("slow_duration",5.0)))
		if shape == "sleep" and not game._is_boss_zombie(z): z.sleep_timer = maxf(float(z.get("sleep_timer",0)),6.0)
		if shape == "snare": z.rooted_timer = maxf(float(z.get("rooted_timer",0)),6.0)
		if shape == "pull" and not game._is_boss_zombie(z): z.x = lerpf(float(z.x),center.x,0.55)
		if shape == "magma": z.corrode_timer = maxf(float(z.get("corrode_timer",0)),11.0); z.corrode_dps = maxf(float(z.get("corrode_dps",0)),28.0)
		game.zombies[i] = projectile_hit(z,shot)
		struck += 1
	if shape == "row": game._damage_obstacles_in_radius(row,center.x,game.board_size.x,float(shot.damage))
	elif shape in ["circle","single"]: game._damage_obstacles_in_circle(center,radius,float(shot.damage))
	game.effects.append({"shape":"fusion_blast","position":center,"radius":minf(240,radius),"blast_shape":shape,"row":row,"from":Vector2(game.BOARD_ORIGIN.x,game._row_center_y(row)),"to":Vector2(game.BOARD_ORIGIN.x+game.board_size.x,game._row_center_y(row)),"time":0.8,"duration":0.8,"traits":b.traits,"tier":2,"color":Color.WHITE})

func _native_impact(shot: Dictionary, center: Vector2) -> void:
	if bool(shot.get("fusion_fragment",false)): return
	var source: String = shot.get("fusion_channel_source","")
	if source == "fumarole_melon":
		game.effects.append({"shape":"volcano_steam","position":center,"radius":95.0,"dps":float(shot.damage)*0.3,"time":3.0,"duration":3.0,"color":Color("97d8dd")})
	if source == "brine_pot": game._ensure_plant_runtime().spawn_bog_pool(center,92.0,5.0)
	var data: Dictionary = shot.get("fusion_mechanics",{})
	if source in ["dragon_bubble_pult","toxic_gum_pult","blast_pomegranate"]:
		var count: int = mini(6,int(data.get("split_count",data.get("cluster_count",2))))
		for n in range(count):
			var landing: Vector2 = center+Vector2.from_angle(n*TAU/count)*float(data.get("cluster_radius",45))
			game._ensure_plant_runtime().spawn_roof_lobbed_projectile("fusion_fragment",int(shot.row),center,landing,float(shot.damage)*0.4,Color("d2a8d9"),34,6,35,0,"")
			var fragment: Dictionary = game.projectiles.back()
			fragment.fusion_source = shot.fusion_source; fragment.fusion_channel_source = source; fragment.fusion_traits = shot.fusion_traits; fragment.fusion_mechanics = data; fragment.fusion_fragment = true
