extends RefCounted
# Each ingredient owns its native state machine. No attack-pattern/targeting approximation.
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const Ammo = preload("res://scripts/data/plant_ammo.gd")
const CLOCKS = ["shot_cooldown","attack_timer","support_timer","pulse_timer","gust_timer","rear_shot_cooldown","geothermal_timer","copy_timer","honey_timer"]
const NATIVE_ULTIMATES = ["scaredy_shroom","spikeweed","laser_lily","plasma_shroom","corn_cannon","moonforge","lotus_lancer","kernel_pult","cabbage_pult","melon_pult","boomerang_shooter","sakura_shooter","origami_blossom","dandelion","electric_bonk_choy"]
const SHARED = ["health","max_health","armor_health","max_armor_health","holy_invincible_timer","save_cooldown","revives_used","geothermal_charge","fusion_mirror_until"]
var game: Control
func _init(owner: Control): game = owner

func state_for(p: Dictionary, source: String, row: int, col: int) -> Dictionary:
	if not p.fusion_native_states.has(source):
		var state: Dictionary = game._create_plant(source,row,col)
		state.sleep_timer = 0
		if source == "holy_flower": state.attached = true
		# Newly grafted chambers charge normally; native high-damage reloads remain intact.
		if p.fusion_channel_timers.has(source):
			var wait: float = p.fusion_channel_timers[source]
			if state.has("shot_cooldown"): state.shot_cooldown = wait if wait <= 0 else maxf(float(state.shot_cooldown),wait)
		p.fusion_native_states[source] = state
	return p.fusion_native_states[source]

func update(p: Dictionary, delta: float, row: int, col: int, ultimate: bool = false, opening: bool = false) -> void:
	var data: Dictionary = Defs.PLANTS[p.fusion_kind]
	for source in data.fusion_weights:
		if Fusion.Combat.BURSTS.has(source): continue
		var state := state_for(p,source,row,col)
		var count: int = data.fusion_weights[source]
		var step: float = delta * (1.0 + minf(0.6,(sqrt(float(count))-1.0)*0.5))
		if source == "peashooter": step = delta # multi-head volleys instead of accelerating peas
		var before: Dictionary = {}
		for field in SHARED:
			if p.has(field): state[field] = p[field]; before[field] = p[field]
		state.row = row; state.col = col
		state.flash = maxf(0,float(state.get("flash",0))-delta)
		# Honor restored chamber cooldowns (including a save/merge) without resetting native phases.
		if p.fusion_channel_timers.has(source) and float(p.fusion_channel_timers[source]) <= 0 and float(state.get("fusion_last_clock",0)) > 0:
			for clock in CLOCKS: state[clock] = 0.0
		if not bool(Defs.PLANTS[source].get("gacha_only",false)):
			state.support_timer = maxf(0,float(state.support_timer)-step)
		state.action_timer = maxf(0,float(state.get("action_timer",0))-delta)
		state.plant_food_timer = maxf(0,float(state.plant_food_timer)-step)
		if state.plant_food_timer <= 0: state.plant_food_mode = ""
		var start: int = game.projectiles.size()
		var roller_start: int = game.rollers.size()
		var sun_start: int = game.suns.size()
		var effect_start: int = game.effects.size()
		if opening and source in NATIVE_ULTIMATES:
			game._execute_ultimate(state,source,row,col,game._ultimate_profile_for_kind(source) if source == "spikeweed" else {"style":"explicit"})
			# Native ultimates may write their state back; retain the real grafted body.
			game._set_targetable_plant(row,col,p)
		elif source == "wallnut_bowling":
			state.attack_timer -= step
			if ultimate or state.attack_timer <= 0:
				game._ensure_projectile_runtime().spawn_bowling_roller(row,col,ultimate)
				state.attack_timer = 12.0
		elif source == "ice_cream":
			p.ultimate_charge = minf(1.0,float(p.get("ultimate_charge",0))+delta/float(data.ultimate_charge_time))
		elif source == "coffee_bean":
			if state.support_timer <= 0:
				game._wake_plants_in_radius(game._cell_center(row,col),game.CELL_SIZE.x*1.6); state.support_timer = 4.0
		elif source == "cork_plug":
			game._ensure_volcano_expansion().cool(Vector2i(row,col),0,3.0)
		elif source == "grave_buster":
			if state.support_timer <= 0:
				for i in range(game.graves.size()-1,-1,-1):
					if game._cell_center(int(game.graves[i].row),int(game.graves[i].col)).distance_to(game._cell_center(row,col)) <= game.CELL_SIZE.x*1.5: game.graves.remove_at(i)
				state.support_timer = 6.0
		elif source == "blover":
			if state.support_timer <= 0:
				game._ensure_plant_runtime().update_blover(state,step,row,col); state.support_timer = 18.0
		else:
			if ultimate:
				for clock in CLOCKS: state[clock] = 0.0
			game._ensure_plant_runtime().update_native(state,step,row,col)
		# Growth changes payload strength, while source patterns and timers remain native.
		var power: float = (1.0+0.22*(sqrt(float(count))-1.0))/sqrt(maxf(1.0,float(data.fusion_weights.size())/3.0))
		if ultimate and not (opening and source in NATIVE_ULTIMATES): power *= 1.8
		for index in range(start,game.projectiles.size()):
			var shot: Dictionary = game.projectiles[index]
			shot.damage = float(shot.get("damage",0))*power
			for field in ["fragment_damage","split_damage","return_damage"]:
				if shot.has(field): shot[field] = float(shot[field])*power
			shot.fusion_native = true; shot.fusion_source = p.fusion_kind; shot.fusion_channel_source = source
			shot.fusion_traits = data.fusion_traits; shot.fusion_mechanics = Fusion.NATIVE[source]
			Ammo.compose(shot,data.fusion_weights,source)
			if ultimate:
				shot.fusion_ultimate = true
				if source == "starfruit": shot.pierce_handheld = true; shot.pierce_left = 3; shot.hit_uids = []
		if source == "peashooter" and count > 1 and game.projectiles.size() > start:
			var original: Array = game.projectiles.slice(start)
			for n in range(1,mini(6,count)):
				for shot in original:
					var extra: Dictionary = shot.duplicate(true)
					extra.position += Vector2((n/2)*4,(n%2)*8-4)
					extra.damage = float(extra.damage)/power*(1.8 if ultimate else 1.0)
					game.projectiles.append(extra)
			for shot in original: shot.damage = float(shot.damage)/power*(1.8 if ultimate else 1.0)
		for index in range(roller_start,game.rollers.size()):
			var roller: Dictionary = game.rollers[index]
			roller.damage = float(roller.damage)*power
			roller.fusion_native = true; roller.fusion_source = p.fusion_kind; roller.fusion_channel_source = source; roller.fusion_traits = data.fusion_traits
			Ammo.compose(roller,data.fusion_weights,source)
		for index in range(sun_start,game.suns.size()):
			if count > 1: game.suns[index].value = int(game.suns[index].get("value",25))*count
		for field in SHARED:
			if not before.has(field): continue
			# Health/armor changes inside a native support routine apply to the shared body.
			if field in ["health","armor_health"]: p[field] = clampf(float(p[field])+float(state[field])-float(before[field]),0,float(p.max_health) if field == "health" else maxf(float(state.max_armor_health),float(p.get("max_armor_health",0))))
			elif state[field] != before[field]: p[field] = state[field]
		p.flash = maxf(float(p.flash),float(state.flash))
		p.action_timer = maxf(float(p.action_timer),float(state.get("action_timer",0)))
		if source == "pressure_bamboo": p.pressure_ammo = state.get("pressure_ammo",0)
		if source == "mirror_shroom": p.fusion_copy_damage = state.get("mirror_damage",0)
		if source == "corn_cannon": p.corn_reload = state.action_timer
		var clock: float = maxf(float(state.shot_cooldown),float(state.attack_timer))
		if state.has("geothermal_timer"): clock = float(state.geothermal_timer)
		if source == "corn_cannon": clock = state.action_timer
		state.fusion_last_clock = clock; p.fusion_channel_timers[source] = clock
		# Persistent fields keep a reference to the real living plant, never a detached proxy.
		for index in range(effect_start,game.effects.size()):
			if game.effects[index].has("source_plant"): game.effects[index].source_plant = p
