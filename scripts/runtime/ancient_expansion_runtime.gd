extends RefCounted
class_name AncientExpansionRuntime

# 古代世界: weather, the five ancient plants and the three ancient zombies.
# Game owns grids, terrain and the generic combat loops; this runtime receives
# the same fixed hooks as the volcano expansion and keeps its own short-lived
# state (corroded lawn, milk waves, hexes, a revival log, weather overrides).
const Defs = preload("res://scripts/game_defs.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const Visuals = preload("res://scripts/ui/ancient_visuals.gd")
const PLANTS := ["dandelion", "jasmine_tea", "golden_milk", "samsara_eye", "electric_bonk_choy"]
const ZOMBIES := ["ancient_samurai", "ancient_mage", "ancient_strategist"]
const WEATHER := {
	"clear": {"name": "晴天", "summary": "风和日丽，没有天气修正", "color": Color("#9fd27a")},
	"sunny": {"name": "烈日", "summary": "阳光+25%  火焰+20%  铁甲迟缓", "color": Color("#ffc54d")},
	"rain": {"name": "细雨", "summary": "火焰-40%  雷电+25%  茶渍扩散", "color": Color("#7fb8e8")},
	"storm": {"name": "雷暴", "summary": "落雷劈向铁甲  电系出手+30%", "color": Color("#b3a3ff")},
	"wind": {"name": "东风", "summary": "僵尸顺风+20%  蒲公英多一枚", "color": Color("#9fe0c8")},
	"fog": {"name": "大雾", "summary": "直射只锁定4格  轮回窗口延长", "color": Color("#c9d3d6")},
	"snow": {"name": "飘雪", "summary": "僵尸-25%  冰系+25%  火焰-15%", "color": Color("#bae7f4")},
	"hail": {"name": "冰雹", "summary": "冰雹击甲28伤害  僵尸-15%", "color": Color("#95c6ed")},
	"sandstorm": {"name": "沙尘", "summary": "直射视野3.5格  僵尸-10%", "color": Color("#e6bc7c")},
	"rainbow": {"name": "虹光", "summary": "产阳+15%  出手与大招充能+15%", "color": Color("#e9b6e8")},
}
const SHOCK_KINDS := ["electric_bonk_choy", "tesla_tulip", "thunder_pine", "thunder_god", "storm_reed", "plasma_shooter", "plasma_shroom", "chain_lotus", "pulse_bulb"]
const FIRE_KINDS := ["torchwood", "jalapeno", "pepper_mortar", "chimney_pepper", "magma_stream", "meteor_flower", "core_blossom", "phoenix_tree", "dragon_fruit", "dragon_bubble_pult", "caldera_lotus", "thermal_sunflower"]
const FROST_KINDS := ["snow_pea", "ice_shroom", "snow_bloom", "frost_boomerang", "ice_queen", "frost_fan", "frost_cypress", "ice_cream"]
const DEATH_MEMORY := 16.0

var game: Control
var weather = "clear"
var previous_weather = "clear"
var weather_blend = 1.0
var schedule_index = 0
var schedule_timer = 0.0
var override_weather = ""
var override_until = 0.0
var override_owner = -1
var lightning_timer = 6.0
var hail_timer = 4.5
var corroded: Dictionary = {}
var deaths: Array = []
var pending_revivals: Array = []


func _init(owner: Control) -> void:
	game = owner


func reset() -> void:
	weather = "clear"
	previous_weather = "clear"
	weather_blend = 1.0
	schedule_index = 0
	schedule_timer = 0.0
	override_weather = ""
	override_until = 0.0
	override_owner = -1
	lightning_timer = 6.0
	hail_timer = 4.5
	corroded.clear()
	deaths.clear()
	pending_revivals.clear()
	var schedule: Array = game.current_level.get("weather_schedule", [])
	if not schedule.is_empty():
		weather = _valid_weather(String(schedule[0].get("weather", "clear")))
		previous_weather = weather


func active() -> bool:
	return game._is_ancient_level() or not game.current_level.get("weather_schedule", []).is_empty()


func _valid_weather(value: String) -> String:
	return value if WEATHER.has(value) else "clear"


func current() -> String:
	return weather if active() else "clear"


func is_weather(kinds: Array) -> bool:
	return active() and weather in kinds


func weather_info(kind: String = "") -> Dictionary:
	return WEATHER.get(kind if not kind.is_empty() else weather, WEATHER.clear)


func schedule_remaining() -> float:
	var schedule: Array = game.current_level.get("weather_schedule", [])
	if not override_weather.is_empty():
		return maxf(0.0, override_until - game.level_time)
	if schedule.is_empty():
		return 0.0
	return maxf(0.0, float(schedule[schedule_index % schedule.size()].get("duration", 30.0)) - schedule_timer)


# ---------------------------------------------------------------- weather

func _set_weather(next: String, banner: String = "") -> void:
	next = _valid_weather(next)
	if next == weather:
		return
	previous_weather = weather
	weather = next
	weather_blend = 0.0
	if active():
		game._show_banner(banner if not banner.is_empty() else "天气转为 · %s" % String(weather_info(next).name), 1.6)
		game._play_sfx(game.SFX_SHOOT_ENERGY_PATH, -18.0, 0.62 if next in ["rain", "storm", "fog"] else 1.1)


func set_override(next: String, owner_uid: int, duration: float) -> void:
	if not WEATHER.has(next): return
	override_weather = next
	override_owner = owner_uid
	override_until = game.level_time + duration
	_set_weather(next, "军师挥扇 · %s" % {"wind": "借来东风", "fog": "唤起大雾", "rain": "召来细雨", "storm": "引动雷暴"}.get(next, String(weather_info(next).name)))


func _owner_alive(uid: int) -> bool:
	for z in game.zombies:
		if int(z.get("uid", -2)) == uid and float(z.get("health", 0.0)) > 0.0 and game._is_enemy_zombie(z):
			return true
	return false


func update_world(delta: float) -> void:
	if game.boss_time_stop_timer > 0.0:
		return
	_prune_memory()
	_run_pending_revivals()
	_update_sheep()
	if not active():
		return
	weather_blend = minf(1.0, weather_blend + delta / 1.6)
	var schedule: Array = game.current_level.get("weather_schedule", [])
	var scheduled = "clear"
	if not schedule.is_empty():
		schedule_timer += delta
		var cycle := 0.0
		for entry in schedule: cycle += maxf(0.1, float(entry.get("duration", 30.0)))
		schedule_timer = fmod(schedule_timer, cycle)
		var span = maxf(0.1, float(schedule[schedule_index % schedule.size()].get("duration", 30.0)))
		while schedule_timer >= span:
			schedule_timer -= span
			schedule_index = (schedule_index + 1) % schedule.size()
			span = maxf(0.1, float(schedule[schedule_index].get("duration", 30.0)))
		scheduled = _valid_weather(String(schedule[schedule_index % schedule.size()].get("weather", "clear")))
	if not override_weather.is_empty():
		if game.level_time >= override_until or not _owner_alive(override_owner):
			var fallen = not _owner_alive(override_owner)
			override_weather = ""
			override_owner = -1
			_set_weather(scheduled, "天象复归 · %s" % String(weather_info(scheduled).name) if fallen else "")
		elif weather != override_weather:
			_set_weather(override_weather)
	elif scheduled != weather:
		_set_weather(scheduled)
	_update_corrosion()
	if weather == "storm":
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			lightning_timer = 6.5 + game.rng.randf_range(0.0, 2.0)
			_call_lightning()
	if weather == "hail":
		hail_timer -= delta
		if hail_timer <= 0.0:
			hail_timer = 6.0
			_call_hail()


func sky_sun_factor() -> float:
	if not active():
		return 1.0
	match weather:
		"sunny": return 0.68
		"rain", "storm": return 1.6
		"fog": return 1.2
		"snow", "hail", "sandstorm": return 1.35
		"rainbow": return 0.85
	return 1.0


func plant_sun_factor() -> float:
	return 1.25 if is_weather(["sunny"]) else (1.15 if is_weather(["rainbow"]) else 1.0)


func element_factor(kind: String, fire: bool) -> float:
	if not active():
		return 1.0
	var factor = 1.0
	if fire or kind in FIRE_KINDS:
		if weather == "sunny": factor *= 1.2
		elif weather in ["rain", "storm"]: factor *= 0.6
		elif weather in ["snow", "hail"]: factor *= 0.85
	if kind in SHOCK_KINDS and weather in ["rain", "storm"]:
		factor *= 1.25
	if kind in FROST_KINDS and weather in ["snow", "hail"]:
		factor *= 1.25
	return factor


func projectile_factor(projectile: Dictionary) -> float:
	if not active():
		return 1.0
	var kind = String(projectile.get("fusion_channel_source", projectile.get("source_kind", "")))
	if kind.is_empty(): kind = String(projectile.get("volcano_seed", projectile.get("kind", "")))
	var fire = bool(projectile.get("fire", false)) or String(projectile.get("kind", "")).find("fire") != -1 or "flame" in projectile.get("ammo_elements", [])
	var factor = element_factor(kind, fire)
	var tags: Array = projectile.get("ammo_elements", [])
	if "storm" in tags and kind not in SHOCK_KINDS and is_weather(["rain", "storm"]): factor *= 1.25
	if ("frost" in tags or float(projectile.get("slow_duration",0)) > 0) and kind not in FROST_KINDS and is_weather(["snow", "hail"]): factor *= 1.25
	return factor


func cadence_factor(plant) -> float:
	if plant == null or not active():
		return 1.0
	if weather == "rainbow": return 1.15
	if weather != "storm": return 1.0
	var kind = String(plant.get("kind", ""))
	if kind in SHOCK_KINDS: return 1.3
	for source in SHOCK_KINDS:
		if game._plant_has_component(plant, source): return 1.3
	return 1.0


func charge_factor() -> float:
	return 1.15 if is_weather(["rainbow"]) else 1.0


func range_limit(range_value: float) -> float:
	if is_weather(["fog"]):
		return minf(range_value, game.CELL_SIZE.x * 4.5)
	if is_weather(["sandstorm"]):
		return minf(range_value, game.CELL_SIZE.x * 3.5)
	return range_value


func speed_factor(z: Dictionary) -> float:
	var factor = 1.0
	var enemy: bool = game._is_enemy_zombie(z)
	if float(z.get("ancient_command_until", 0.0)) > game.level_time:
		factor *= 1.25
	if enemy and String(z.get("kind", "")) == "ancient_strategist" and _strategist_holds(z):
		return 0.0
	if active():
		match weather:
			"wind":
				if enemy: factor *= 1.2
			"rain", "storm":
				factor *= 0.9
			"snow": factor *= 0.75
			"hail": factor *= 0.85
			"sandstorm": factor *= 0.9
			"sunny":
				if String(z.get("kind", "")) == "ancient_samurai" or game.ZombieEquipment.metal_field(z) != "": factor *= 0.85
	return factor


func attack_factor(z: Dictionary) -> float:
	return 1.15 if float(z.get("ancient_command_until", 0.0)) > game.level_time else 1.0


func damage_factor(z: Dictionary) -> float:
	if float(z.get("ancient_weak_until", 0.0)) > game.level_time:
		return 1.0 + float(Defs.PLANTS.jasmine_tea.weaken_ratio)
	return 1.0


# ---------------------------------------------------------------- shared helpers

func fx(shape: String, center: Vector2, radius: float, duration: float, extra: Dictionary = {}) -> void:
	if game.effects.size() >= 640:
		return
	var effect = {"shape": shape, "position": center, "radius": radius, "time": duration, "duration": duration, "color": Color.WHITE}
	effect.merge(extra, true)
	game.effects.append(effect)


func _enemy_alive(z: Dictionary) -> bool:
	return game._is_enemy_zombie(z) and float(z.get("health", 0.0)) > 0.0


func _zombie_point(z: Dictionary) -> Vector2:
	return Vector2(float(z.x), game._row_center_y(int(z.row)) - 10.0)


func _index_of_uid(uid: int) -> int:
	for i in range(game.zombies.size()):
		if int(game.zombies[i].get("uid", -2)) == uid:
			return i
	return -1


# Spores fall from the sky, so balloons are fair targets; buried or submerged ones are not.
func _sky_visible(z: Dictionary) -> bool:
	return bool(z.get("balloon_flying", false)) or not game._is_hidden_from_lane_attacks(z)


func _row_targets(row: int, from_x: float, limit: int = 8, air: bool = true) -> Array:
	var found: Array = []
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not _enemy_alive(z) or not _sky_visible(z) or not game._zombie_has_row(z, row):
			continue
		if not air and (bool(z.get("balloon_flying", false)) or bool(z.get("jumping", false))):
			continue
		var x: float = game._zombie_lane_x(z, row)
		if x < from_x - 8.0 or x > game.BOARD_ORIGIN.x + game.board_size.x + 60.0:
			continue
		found.append(i)
	found.sort_custom(func(a, b): return float(game.zombies[a].x) < float(game.zombies[b].x))
	return found.slice(0, limit)


func _hit(index: int, damage: float, flash: float = 0.16, pierce: bool = false, from_x: float = INF) -> void:
	if index < 0 or index >= game.zombies.size():
		return
	var z: Dictionary = game.zombies[index]
	if bool(z.get("balloon_flying", false)) and pierce:
		z["balloon_flying"] = false
		z["flying"] = false
		z["special_pause_timer"] = maxf(float(z.get("special_pause_timer", 0.0)), 0.2)
	game.zombies[index] = game._apply_zombie_damage(z, damage, flash, 0.0, false, pierce, from_x)


func _power(plant: Dictionary, row: int, col: int) -> float:
	return game._plant_enhance_multiplier_at_cell(row, col) * float(plant.get("ancient_power", 1.0))


# ---------------------------------------------------------------- plants

func update_plant(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	var kind = String(plant.kind)
	match kind:
		"dandelion": _update_dandelion(plant, delta, row, col)
		"jasmine_tea": _update_jasmine(plant, delta, row, col)
		"golden_milk": return _update_milk(plant, delta, row, col)
		"samsara_eye": return _update_samsara(plant, delta, row, col)
		"electric_bonk_choy": _update_bonk_choy(plant, delta, row, col)
	return false


func _update_dandelion(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["shot_cooldown"] = float(plant.get("shot_cooldown", 0.6)) - game._plant_cadence_delta(delta, row, col)
	if float(plant.shot_cooldown) > 0.0:
		return
	var center: Vector2 = game._cell_center(row, col)
	var targets = _row_targets(row, center.x)
	if targets.is_empty():
		plant["shot_cooldown"] = 0.15
		return
	var count = 2 if is_weather(["wind"]) else 1
	for n in range(count):
		var target: int = targets[mini(n, targets.size() - 1)]
		launch_spore(row, center + Vector2(-2.0 + n * 6.0, -42.0), int(game.zombies[target].uid), float(Defs.PLANTS.dandelion.damage) * _power(plant, row, col), n * 0.18)
	plant["shot_cooldown"] = float(Defs.PLANTS.dandelion.shoot_interval)
	game._trigger_plant_action(plant, 0.42)
	game._play_sfx(game.SFX_SHOOT_SPORE_PATH, -16.0, 1.25)


func launch_spore(row: int, origin: Vector2, target_uid: int, damage: float, delay: float = 0.0, empowered: bool = false) -> void:
	var data: Dictionary = Defs.PLANTS.dandelion
	var target_index = _index_of_uid(target_uid)
	var aim = origin + Vector2(game.CELL_SIZE.x * 2.0, 0.0)
	if target_index >= 0:
		aim = _zombie_point(game.zombies[target_index])
	var lift = 128.0 + game.rng.randf_range(-14.0, 18.0)
	if is_weather(["rain", "storm"]):
		damage *= 1.2
	game.projectiles.append({
		"kind": "ancient_spore", "row": row, "position": origin, "spore_origin": origin,
		"spore_apex": Vector2(lerpf(origin.x, aim.x, 0.62) + game.rng.randf_range(-12.0, 12.0), minf(origin.y, aim.y) - lift),
		"spore_phase": 0.0, "spore_delay": delay, "spore_dive": 0.0, "spore_seed": game.rng.randf_range(0.0, TAU),
		"spore_float_time": float(data.spore_float_time), "spore_dive_time": float(data.spore_dive_time),
		"target_uid": target_uid, "damage": damage, "radius": 9.0 if empowered else 7.0, "empowered": empowered,
		"anti_air": true, "pierce_handheld": true, "speed": 0.0, "slow_duration": 0.0, "color": Color("#fff7dc"),
		"reflected": false, "fire": false, "source_kind": "dandelion",
	})


# Returns true when the spore has landed (the caller removes it).
func update_spore(shot: Dictionary, delta: float) -> bool:
	if float(shot.get("spore_delay", 0.0)) > 0.0:
		shot["spore_delay"] = float(shot.spore_delay) - delta
		return false
	var origin: Vector2 = shot.spore_origin
	var apex: Vector2 = shot.spore_apex
	var sway = sin(game.level_time * 5.0 + float(shot.spore_seed)) * 6.0
	if float(shot.spore_phase) < 1.0:
		shot["spore_phase"] = minf(1.0, float(shot.spore_phase) + delta / float(shot.spore_float_time))
		var t = float(shot.spore_phase)
		var eased = 1.0 - pow(1.0 - t, 2.2)
		shot["position"] = Vector2(lerpf(origin.x, apex.x, eased) + sway * t, lerpf(origin.y, apex.y, sin(t * PI * 0.5)))
		return false
	var index = _index_of_uid(int(shot.get("target_uid", -1)))
	if index < 0 or not _enemy_alive(game.zombies[index]) or not _sky_visible(game.zombies[index]):
		var fallback = _row_targets(int(shot.row), apex.x - game.CELL_SIZE.x * 3.0, 1)
		if fallback.is_empty():
			fallback = _row_targets(int(shot.row), game.BOARD_ORIGIN.x, 1)
		if not fallback.is_empty():
			index = fallback[0]
			shot["target_uid"] = int(game.zombies[index].uid)
	var landing = Vector2(apex.x, game._row_center_y(int(shot.row)) + 6.0)
	if index >= 0:
		landing = _zombie_point(game.zombies[index]) + Vector2(0.0, -14.0)
	shot["spore_dive"] = minf(1.0, float(shot.spore_dive) + delta / float(shot.spore_dive_time))
	var d = float(shot.spore_dive)
	shot["position"] = apex.lerp(landing, d * d) + Vector2(sway * (1.0 - d), 0.0)
	if d < 1.0:
		return false
	var damage = float(shot.damage) * projectile_factor(shot)
	if index >= 0:
		_hit(index, damage, 0.18, true, landing.x)
		# Grafted spores carry their partners' elemental payloads.
		game.zombies[index] = game._ensure_projectile_runtime().apply_ammo_status(game.zombies[index], shot)
	var splash = float(Defs.PLANTS.dandelion.spore_splash_radius) * (1.5 if bool(shot.get("empowered", false)) else 1.0)
	for i in range(game.zombies.size()):
		if i == index or not _enemy_alive(game.zombies[i]) or game._is_hidden_from_lane_attacks(game.zombies[i]):
			continue
		if _zombie_point(game.zombies[i]).distance_to(landing) <= splash:
			_hit(i, damage * 0.3, 0.1)
			game.zombies[i] = game._ensure_projectile_runtime().apply_ammo_status(game.zombies[i], shot)
	fx("ancient_spore_burst", landing, splash, 0.5, {"empowered": bool(shot.get("empowered", false))})
	return true


# The 3x3 block ahead of the cup; zombies already at the cup's face are splashed too.
func _jasmine_cells(row: int, col: int, columns: int, rows: int = 1) -> Array:
	var cells: Array = []
	for r in range(row - rows, row + rows + 1):
		if r < 0 or r >= game.ROWS or not game._is_row_active(r):
			continue
		for c in range(col, mini(game.COLS, col + 1 + columns)):
			cells.append(Vector2i(r, c))
	return cells


func _zombies_in_cells(cells: Array, front_of: float = -INF) -> Array:
	var found: Array = []
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not _enemy_alive(z) or game._is_hidden_from_lane_attacks(z):
			continue
		if float(z.x) < front_of:
			continue
		var cell = Vector2i(int(z.row), game._zombie_cell_col(float(z.x)))
		if cell in cells:
			found.append(i)
	return found


func corrode(cells: Array, duration: float) -> void:
	for cell in cells:
		corroded[cell] = maxf(float(corroded.get(cell, 0.0)), game.level_time + duration)


func is_corroded(cell: Vector2i) -> bool:
	return float(corroded.get(cell, 0.0)) > game.level_time


func _update_jasmine(plant: Dictionary, delta: float, row: int, col: int) -> void:
	plant["shot_cooldown"] = float(plant.get("shot_cooldown", 0.5)) - game._plant_cadence_delta(delta, row, col)
	if float(plant.shot_cooldown) > 0.0:
		return
	var columns = 4 if is_weather(["rain", "storm"]) else 3
	var cells = _jasmine_cells(row, col, columns)
	var victims = _zombies_in_cells(cells, game._cell_center(row, col).x - 10.0)
	if victims.is_empty():
		plant["shot_cooldown"] = 0.2
		return
	pour_tea(plant, row, col, cells, float(Defs.PLANTS.jasmine_tea.damage) * _power(plant, row, col))
	plant["shot_cooldown"] = float(Defs.PLANTS.jasmine_tea.shoot_interval)


func pour_tea(plant: Dictionary, row: int, col: int, cells: Array, damage: float, duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = float(Defs.PLANTS.jasmine_tea.corrode_duration)
		if is_weather(["rain", "storm"]):
			duration = 9.0
		elif is_weather(["sunny"]):
			duration = 4.0
			damage *= 1.3
	for index in _zombies_in_cells(cells, game._cell_center(row, col).x - 10.0):
		game.zombies[index] = game._apply_zombie_damage(game.zombies[index], damage, 0.12)
		game.zombies[index]["ancient_weak_until"] = maxf(float(game.zombies[index].get("ancient_weak_until", 0.0)), game.level_time + 1.2)
	var lawn: Array = []
	for cell in cells:
		if int(cell.y) != col:
			lawn.append(cell)
	corrode(lawn, duration)
	fx("ancient_tea_pour", game._cell_center(row, col), game.CELL_SIZE.x, 0.7, {"cells": cells, "row": row, "col": col})
	if not plant.is_empty():
		game._trigger_plant_action(plant, 0.5)
	game._play_sfx(game.SFX_HIT_SOFT_PATH, -15.0, 0.78)


func _update_corrosion() -> void:
	for cell in corroded.keys():
		if not is_corroded(cell):
			corroded.erase(cell)
	if corroded.is_empty():
		return
	for z in game.zombies:
		if not _enemy_alive(z):
			continue
		var cell = Vector2i(int(z.row), game._zombie_cell_col(float(z.x)))
		if is_corroded(cell):
			z["ancient_weak_until"] = maxf(float(z.get("ancient_weak_until", 0.0)), game.level_time + 0.6)


func _update_milk(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	if not plant.has("ancient_fuse"):
		plant["ancient_fuse"] = float(Defs.PLANTS.golden_milk.fuse)
		plant["ancient_fuse_total"] = plant.ancient_fuse
	plant["ancient_fuse"] = float(plant.ancient_fuse) - delta
	plant["action_timer"] = maxf(float(plant.get("action_timer", 0.0)), 0.05)
	if float(plant.ancient_fuse) > 0.0:
		return false
	spawn_milk_wave(row, game._cell_center(row, col).x, float(Defs.PLANTS.golden_milk.damage) * game._plant_enhance_multiplier_at_cell(row, col))
	return true


func spawn_milk_wave(row: int, start_x: float, damage: float, empowered: bool = false) -> void:
	var knock = float(Defs.PLANTS.golden_milk.knockback) * (1.5 if is_weather(["rain", "storm"]) else 1.0) * (1.25 if empowered else 1.0)
	# The first gush lands right at the bottle's mouth; an empowered pour surges further.
	var wave := {"shape": "ancient_milk_wave", "position": Vector2(start_x, game._row_center_y(row)), "radius": 60.0, "row": row, "start_x": start_x, "front_x": start_x + (200.0 if empowered else 60.0), "damage": damage, "knock": knock, "hit": [], "empowered": empowered, "time": 1.6, "duration": 1.6, "color": Color.WHITE}
	game.effects.append(wave)
	_advance_wave(wave, 0.0)
	game._play_sfx(game.SFX_HIT_SOFT_PATH, -9.0, 0.6)
	game._trigger_screen_shake(3.0)


func _advance_wave(wave: Dictionary, delta: float) -> void:
	var limit: float = game.BOARD_ORIGIN.x + game.board_size.x + 90.0
	if float(wave.front_x) >= limit and delta > 0.0:
		return
	wave["front_x"] = minf(limit, float(wave.front_x) + 980.0 * delta)
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not _enemy_alive(z) or not game._zombie_has_row(z, int(wave.row)) or int(z.uid) in wave.hit:
			continue
		var x: float = game._zombie_lane_x(z, int(wave.row))
		if x < float(wave.start_x) - 30.0 or x > float(wave.front_x) + 18.0:
			continue
		wave.hit.append(int(z.uid))
		z = game._apply_zombie_damage(z, float(wave.damage), 0.24, 2.0, false, true, float(wave.start_x))
		if not game._is_boss_zombie(z):
			z["x"] = minf(float(z.x) + float(wave.knock), game.BOARD_ORIGIN.x + game.board_size.x + 40.0)
			z["special_pause_timer"] = maxf(float(z.get("special_pause_timer", 0.0)), 0.45)
			z["impact_timer"] = 0.3
		game.zombies[i] = z
	game._damage_obstacles_in_radius(int(wave.row), (float(wave.start_x) + float(wave.front_x)) * 0.5, (float(wave.front_x) - float(wave.start_x)) * 0.5, float(wave.damage) * 0.25)


func tick_effect(effect: Dictionary, delta: float) -> void:
	match String(effect.shape):
		"ancient_milk_wave":
			_advance_wave(effect, delta)
		"ancient_strike":
			var index = _index_of_uid(int(effect.uid))
			if index >= 0:
				effect["position"] = _zombie_point(game.zombies[index])


func resolve_effect(effect: Dictionary) -> void:
	match String(effect.shape):
		"ancient_hex": _resolve_hex(effect)
		"ancient_strike": _resolve_strike(effect)


func _update_samsara(plant: Dictionary, delta: float, row: int, col: int) -> bool:
	if not plant.has("ancient_fuse"):
		plant["ancient_fuse"] = float(Defs.PLANTS.samsara_eye.fuse)
		plant["ancient_fuse_total"] = plant.ancient_fuse
		fx("ancient_samsara", game._cell_center(row, col) + Vector2(0, -20), 120.0, 1.6)
	plant["ancient_fuse"] = float(plant.ancient_fuse) - delta
	plant["action_timer"] = maxf(float(plant.get("action_timer", 0.0)), 0.05)
	if float(plant.ancient_fuse) > 0.0:
		return false
	# The flower closes first, so its own cell can host the plant that fell there.
	var window = float(Defs.PLANTS.samsara_eye.revive_window) * (1.5 if is_weather(["fog"]) else 1.0)
	pending_revivals.append({"window": window, "origin": Vector2i(row, col), "radius": INF, "toast": true})
	fx("ancient_samsara", game._cell_center(row, col) + Vector2(0, -20), 220.0, 1.2, {"burst": true})
	return true


func _update_bonk_choy(plant: Dictionary, delta: float, row: int, col: int) -> void:
	var data: Dictionary = Defs.PLANTS.electric_bonk_choy
	var center: Vector2 = game._cell_center(row, col)
	var rush = float(plant.get("ancient_rush", 0.0))
	plant["ancient_punch_anim"] = maxf(0.0, float(plant.get("ancient_punch_anim", 0.0)) - delta)
	if rush > 0.0:
		plant["ancient_rush"] = rush - delta
		plant["attack_timer"] = float(plant.get("attack_timer", 0.0)) - delta
		if float(plant.attack_timer) <= 0.0:
			plant["attack_timer"] = 0.125
			_rush_punch(plant, row, col)
		return
	plant["attack_timer"] = float(plant.get("attack_timer", 0.3)) - game._plant_cadence_delta(delta, row, col)
	if float(plant.attack_timer) > 0.0:
		return
	var front = -1
	var back = -1
	var front_x = INF
	var back_x = -INF
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not _enemy_alive(z) or game._is_hidden_from_lane_attacks(z) or not game._zombie_has_row(z, row):
			continue
		if bool(z.get("balloon_flying", false)):
			continue
		var x: float = game._zombie_lane_x(z, row)
		if x >= center.x - 12.0 and x <= center.x + float(data.range) and x < front_x:
			front = i
			front_x = x
		elif x < center.x - 12.0 and x >= center.x - float(data.rear_range) and x > back_x:
			back = i
			back_x = x
	if front < 0 and back < 0:
		plant["attack_timer"] = 0.1
		return
	var side = 1
	if front < 0 or (back >= 0 and int(plant.get("ancient_last_side", 1)) == 1):
		side = -1
	if side == -1 and back < 0:
		side = 1
	var target = front if side == 1 else back
	plant["ancient_last_side"] = side
	plant["ancient_punch_side"] = side
	plant["ancient_punch_anim"] = 0.22
	plant["ancient_punches"] = int(plant.get("ancient_punches", 0)) + 1
	var power = _power(plant, row, col)
	var point = _zombie_point(game.zombies[target])
	_hit(target, float(data.damage) * power * element_factor("electric_bonk_choy",false), 0.14)
	fx("ancient_punch", point + Vector2(0, -8), 26.0, 0.22, {"side": side})
	game._play_sfx(game.SFX_HIT_HEAVY_PATH, -17.0, 1.25 + game.rng.randf_range(-0.08, 0.08))
	if int(plant.ancient_punches) % int(data.lightning_every) == 0:
		chain_lightning(target, float(data.lightning_damage) * power, int(data.lightning_chain), center + Vector2(side * 18.0, -34.0))
	plant["attack_timer"] = float(data.attack_interval)
	game._trigger_plant_action(plant, 0.16)


func _rush_punch(plant: Dictionary, row: int, col: int) -> void:
	var center: Vector2 = game._cell_center(row, col)
	var side = 1 if int(plant.get("ancient_last_side", 1)) == -1 else -1
	plant["ancient_last_side"] = side
	plant["ancient_punch_side"] = side
	plant["ancient_punch_anim"] = 0.12
	var power = _power(plant, row, col)
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not _enemy_alive(z) or game._is_hidden_from_lane_attacks(z):
			continue
		if absi(int(z.row) - row) > 1 or absf(float(z.x) - center.x) > game.CELL_SIZE.x * 1.45:
			continue
		_hit(i, 40.0 * power * element_factor("electric_bonk_choy",false), 0.12)
		if game.rng.randf() < 0.35:
			fx("ancient_punch", _zombie_point(game.zombies[i]) + Vector2(0, -6), 22.0, 0.18, {"side": side})


func chain_lightning(first_index: int, damage: float, jumps: int, origin: Vector2) -> void:
	if is_weather(["rain"]):
		jumps += 1
		damage *= 1.25
	elif is_weather(["storm"]):
		jumps += 2
		damage *= 1.25
	var visited: Array = []
	var current = first_index
	var from = origin
	var points = PackedVector2Array([origin])
	for n in range(jumps + 1):
		if current < 0:
			break
		var z: Dictionary = game.zombies[current]
		visited.append(int(z.uid))
		var point = _zombie_point(z) + Vector2(0, -10)
		points.append(point)
		var hit: Dictionary = game._apply_zombie_damage(z, damage, 0.2)
		hit["frozen_timer"] = maxf(float(hit.get("frozen_timer", 0.0)), 0.3)
		game.zombies[current] = hit
		from = point
		var best = -1
		var best_distance = game.CELL_SIZE.x * 2.6
		for i in range(game.zombies.size()):
			var other: Dictionary = game.zombies[i]
			if not _enemy_alive(other) or int(other.uid) in visited or game._is_hidden_from_lane_attacks(other):
				continue
			var distance = _zombie_point(other).distance_to(from)
			if distance < best_distance:
				best_distance = distance
				best = i
		current = best
	fx("ancient_chain", origin, 40.0, 0.42, {"points": points})
	game._play_sfx(game.SFX_HIT_ELECTRIC_PATH, -13.0, 1.1)


func ultimate(plant: Dictionary, row: int, col: int) -> void:
	var kind = String(plant.kind)
	var center: Vector2 = game._cell_center(row, col)
	match kind:
		"dandelion":
			var spore_index = 0
			for lane in game.active_rows:
				var targets = _row_targets(int(lane), game.BOARD_ORIGIN.x)
				for n in range(3):
					var uid = -1 if targets.is_empty() else int(game.zombies[targets[n % targets.size()]].uid)
					var origin = center + Vector2(game.rng.randf_range(-12.0, 12.0), -46.0)
					if uid < 0:
						continue
					launch_spore(int(lane), origin, uid, 90.0 * game._plant_enhance_multiplier_at_cell(row, col), spore_index * 0.06, true)
					spore_index += 1
			fx("ancient_dandelion_gust", center + Vector2(0, -40), 180.0, 1.2)
		"jasmine_tea":
			var cells = _jasmine_cells(row, col, 6)
			pour_tea(plant, row, col, cells, 90.0 * game._plant_enhance_multiplier_at_cell(row, col), 12.0)
			fx("ancient_tea_bloom", center, game.CELL_SIZE.x * 3.0, 1.2, {"cells": cells})
		"electric_bonk_choy":
			plant["ancient_rush"] = float(Defs.PLANTS.electric_bonk_choy.ultimate_duration)
			plant["attack_timer"] = 0.0
			var candidates: Array = []
			for i in range(game.zombies.size()):
				var z: Dictionary = game.zombies[i]
				if _enemy_alive(z) and absi(int(z.row) - row) <= 1 and absf(float(z.x) - center.x) < game.CELL_SIZE.x * 4.0:
					candidates.append(i)
			candidates.shuffle()
			for n in range(mini(8, candidates.size())):
				var target: int = candidates[n]
				strike_zombie(target, 90.0 * game._plant_enhance_multiplier_at_cell(row, col), n * 0.18, false)
			fx("ancient_thunder_fists", center + Vector2(0, -24), 150.0, 2.0)


# ---------------------------------------------------------------- lightning & storm

func _call_hail() -> void:
	var hits := 0
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not _enemy_alive(z) or game._is_hidden_from_lane_attacks(z): continue
		var point = _zombie_point(z)
		_hit(i, 28.0, 0.14)
		fx("ancient_hail_hit", point, 26.0, 0.55)
		hits += 1
		if hits >= 12: break

func _call_lightning() -> void:
	var best = -1
	var best_score = -1.0
	for i in range(game.zombies.size()):
		var z: Dictionary = game.zombies[i]
		if not _enemy_alive(z) or game._is_hidden_from_lane_attacks(z) or game._is_boss_zombie(z):
			continue
		var score = game.rng.randf_range(0.0, 1.0)
		if String(z.kind) == "ancient_samurai" and float(z.get("shield_health", 0.0)) > 0.0:
			score += 3.0
		elif game.ZombieEquipment.metal_field(z) != "":
			score += 2.0
		if String(z.kind) == "ancient_mage" and float(z.get("ancient_cast", 0.0)) > 0.0:
			score += 1.5
		if score > best_score:
			best_score = score
			best = i
	if best >= 0:
		strike_zombie(best, 180.0, 0.0, true)


func strike_zombie(index: int, damage: float, delay: float, natural: bool) -> void:
	var z: Dictionary = game.zombies[index]
	game.effects.append({"shape": "ancient_strike", "uid": int(z.uid), "damage": damage, "natural": natural, "position": _zombie_point(z), "radius": 34.0, "time": delay + 0.55, "duration": delay + 0.55, "color": Color.WHITE})


func _resolve_strike(strike: Dictionary) -> void:
	var index = _index_of_uid(int(strike.uid))
	var point: Vector2 = strike.position
	if index >= 0 and _enemy_alive(game.zombies[index]):
		var z: Dictionary = game.zombies[index]
		point = _zombie_point(z)
		var damage = float(strike.damage)
		if String(z.kind) == "ancient_samurai" and float(z.get("shield_health", 0.0)) > 0.0:
			damage *= 1.5
		z = game._apply_zombie_damage(z, damage, 0.3, 0.0, false, true)
		z["frozen_timer"] = maxf(float(z.get("frozen_timer", 0.0)), 0.6)
		if String(z.kind) == "ancient_mage" and float(z.get("ancient_cast", 0.0)) > 0.0:
			z["ancient_cast"] = 0.0
			z["ancient_mage_timer"] = 3.5
			_cancel_hexes(int(z.uid))
		game.zombies[index] = z
	for i in range(game.zombies.size()):
		if i != index and _enemy_alive(game.zombies[i]) and _zombie_point(game.zombies[i]).distance_to(point) < 46.0:
			_hit(i, float(strike.damage) * 0.35, 0.16)
	fx("ancient_lightning", point, 56.0, 0.5, {"natural": bool(strike.natural)})
	game._play_sfx(game.SFX_HIT_ELECTRIC_PATH, -8.0 if bool(strike.natural) else -12.0, 0.82)
	game._trigger_screen_shake(4.0 if bool(strike.natural) else 2.0)


# ---------------------------------------------------------------- revival

func record_death(plant: Dictionary, row: int, col: int, layer: String) -> void:
	var kind = String(plant.get("kind", ""))
	if kind.is_empty() or kind in ["golden_milk", "samsara_eye"] or bool(plant.get("minigame_core", false)):
		return
	if bool(Defs.PLANTS.get(kind, {}).get("one_shot", false)) and not plant.has("fusion_kind"):
		return
	deaths.append({"plant": plant.duplicate(true), "row": row, "col": col, "layer": layer, "time": game.level_time})


func _prune_memory() -> void:
	for d in range(deaths.size() - 1, -1, -1):
		if game.level_time - float(deaths[d].time) > DEATH_MEMORY:
			deaths.remove_at(d)


func _restored(record: Dictionary, row: int, col: int) -> Dictionary:
	var p: Dictionary = record.plant.duplicate(true)
	p["row"] = row
	p["col"] = col
	p["health"] = float(p.get("max_health", p.get("health", 1.0)))
	for field in ["sleep_timer", "rooted_timer", "frozen_timer", "ancient_sheep_until", "ultimate_active", "laddered"]:
		if p.has(field):
			p[field] = false if field in ["ultimate_active", "laddered"] else 0.0
	p["flash"] = 0.6
	p["spawn_time"] = game.level_time
	p["mystia_charmed"] = false
	p["mystia_being_cooked"] = false
	if is_weather(["storm"]):
		p["holy_invincible_timer"] = maxf(float(p.get("holy_invincible_timer", 0.0)), 3.0)
	return p


# Revive plants that fell within the window, latest fall per cell. A plant whose cell is
# taken grafts onto the occupant when a recipe exists, otherwise it moves to the
# closest free legal cell in its row. Returns the number of plants restored.
func _revival_candidates(window: float, origin: Vector2i, radius: float) -> Array:
	var cutoff: float = game.level_time - window
	var candidates: Array = []
	var seen = {}
	for d in range(deaths.size() - 1, -1, -1):
		var record: Dictionary = deaths[d]
		if float(record.time) < cutoff:
			continue
		var key = "%d,%d,%s" % [int(record.row), int(record.col), String(record.layer)]
		if seen.has(key):
			continue
		var cell = Vector2i(int(record.row), int(record.col))
		if radius < INF and game._cell_center(cell.x, cell.y).distance_to(game._cell_center(origin.x, origin.y)) > radius:
			continue
		seen[key] = true
		candidates.append(d)
	return candidates


func revive_recent(window: float, origin: Vector2i, radius: float) -> int:
	var candidates = _revival_candidates(window, origin, radius)
	var restored = 0
	for d in candidates:
		var record: Dictionary = deaths[d]
		if _revive(record):
			restored += 1
			record["used"] = true
	for d in range(deaths.size() - 1, -1, -1):
		if bool(deaths[d].get("used", false)):
			deaths.remove_at(d)
	return restored


func _revive(record: Dictionary) -> bool:
	var row = int(record.row)
	var col = int(record.col)
	if not game._is_row_active(row):
		return false
	var p = _restored(record, row, col)
	if String(record.layer) == "support":
		if game.support_grid[row][col] != null:
			return false
		game.support_grid[row][col] = p
		fx("ancient_revive", game._cell_center(row, col), 60.0, 1.0)
		return true
	var existing = game.grid[row][col]
	if existing == null and game._placement_error(String(p.kind), row, col) == "":
		game.grid[row][col] = p
		fx("ancient_revive", game._cell_center(row, col), 60.0, 1.0)
		return true
	if existing != null and float(existing.get("health", 0.0)) > 0.0:
		var fusion = game._ensure_plant_fusion()
		var id: String = Fusion.result(fusion.kind(existing), fusion.kind(p))
		if not id.is_empty() and fusion.placement_error(fusion.kind(p), row, col, {"id": id, "host": existing, "layer": "grid"}).is_empty():
			var merged: Dictionary = fusion.combined(id, existing, p)
			merged.health = merged.max_health
			game.grid[row][col] = merged
			fx("ancient_revive", game._cell_center(row, col), 70.0, 1.0, {"fused": true})
			fusion._emit(merged, row, col, "fusion_bloom", 72, 0.8)
			return true
	for offset in [1, -1, 2, -2, 3, -3, 4, -4]:
		var c: int = col + int(offset)
		if c < 0 or c >= game.COLS or game.grid[row][c] != null:
			continue
		if game._placement_error(String(p.kind), row, c) != "":
			continue
		p["col"] = c
		game.grid[row][c] = p
		fx("ancient_revive", game._cell_center(row, c), 60.0, 1.0)
		return true
	return false


# Samsara as a fused chamber: revive nearby plants on its own charge cycle.
# Revivals land after the plant pass finishes, so a plant updating in the
# same cell can never overwrite the one that just returned.
func fusion_revive(row: int, col: int, ultimate: bool) -> bool:
	var window = 15.0 if ultimate else 10.0
	var radius = INF if ultimate else game.CELL_SIZE.x * 2.6
	var ready = not _revival_candidates(window, Vector2i(row, col), radius).is_empty()
	if ready:
		pending_revivals.append({"window": window, "origin": Vector2i(row, col), "radius": radius, "toast": false})
	if ready or ultimate:
		fx("ancient_samsara", game._cell_center(row, col) + Vector2(0, -20), 200.0 if ultimate else 130.0, 1.2, {"burst": true})
	return ready


func _run_pending_revivals() -> void:
	while not pending_revivals.is_empty():
		var request: Dictionary = pending_revivals.pop_front()
		var count = revive_recent(float(request.window), request.origin, float(request.radius))
		if bool(request.toast):
			game._show_toast("轮回之眼：%d 株植物归来" % count if count > 0 else "轮回之眼：近处没有可复活的植物")


# ---------------------------------------------------------------- zombies

func update_zombie(z: Dictionary, delta: float) -> void:
	var kind = String(z.get("kind", ""))
	if not kind in ZOMBIES or float(z.get("health", 0.0)) <= 0.0:
		return
	z["ancient_anim"] = maxf(0.0, float(z.get("ancient_anim", 0.0)) - delta)
	if not game._is_enemy_zombie(z):
		return
	var stunned = float(z.get("frozen_timer", 0.0)) > 0.0 or float(z.get("sleep_timer", 0.0)) > 0.0
	match kind:
		"ancient_samurai": _update_samurai(z)
		"ancient_mage":
			if not stunned:
				_update_mage(z, delta)
		"ancient_strategist":
			if not stunned:
				_update_strategist(z, delta)


func _update_samurai(z: Dictionary) -> void:
	var target: Vector2i = game._find_bite_target(int(z.row), float(z.x))
	if target.y == -1 or bool(z.get("flying", false)):
		return
	var plant = game._targetable_plant_at(target.x, target.y)
	if plant == null:
		return
	# Identify the victim by cell, species and planting time, never by a stored reference.
	var key = "%d,%d,%s,%.3f" % [target.x, target.y, String(plant.get("fusion_kind", plant.kind)), float(plant.get("spawn_time", 0.0))]
	if String(z.get("ancient_iaido_key", "")) == key:
		return
	z["ancient_iaido_key"] = key
	z["ancient_anim"] = 0.55
	game._damage_plant_cell(target.x, target.y, float(Defs.ZOMBIES.ancient_samurai.iaido_damage))
	fx("ancient_iaido", game._cell_center(target.x, target.y) + Vector2(4, -12), 46.0, 0.42)
	game._play_sfx(game.SFX_HIT_HEAVY_PATH, -9.0, 0.72)


func _hex_targets(z: Dictionary) -> Array:
	var reach_cells = 4 if is_weather(["fog"]) else 6
	var options: Array = []
	for r in range(int(z.row) - 1, int(z.row) + 2):
		if r < 0 or r >= game.ROWS or not game._is_row_active(r):
			continue
		for c in range(game.COLS):
			var plant = game.grid[r][c]
			if plant == null or float(plant.get("health", 0.0)) <= 0.0 or is_sheep(plant):
				continue
			if float(plant.get("holy_invincible_timer", 0.0)) > 0.0 or String(plant.kind) in ["golden_milk", "samsara_eye"]:
				continue
			var x: float = game._cell_center(r, c).x
			if x >= float(z.x) - 10.0 or float(z.x) - x > game.CELL_SIZE.x * reach_cells:
				continue
			options.append(Vector2i(r, c))
	options.shuffle()
	return options.slice(0, 2)


func _update_mage(z: Dictionary, delta: float) -> void:
	var data: Dictionary = Defs.ZOMBIES.ancient_mage
	if float(z.get("ancient_cast", 0.0)) > 0.0:
		z["ancient_cast"] = float(z.ancient_cast) - delta
		z["special_pause_timer"] = maxf(float(z.get("special_pause_timer", 0.0)), 0.1)
		return
	if float(z.x) > game.BOARD_ORIGIN.x + game.board_size.x - 10.0:
		return
	z["ancient_mage_timer"] = float(z.get("ancient_mage_timer", 4.0)) - delta
	if float(z.ancient_mage_timer) > 0.0:
		return
	var cells = _hex_targets(z)
	if cells.is_empty():
		z["ancient_mage_timer"] = 1.0
		return
	z["ancient_mage_timer"] = float(data.cast_interval)
	z["ancient_cast"] = 1.0
	z["ancient_anim"] = 1.0
	z["special_pause_timer"] = maxf(float(z.get("special_pause_timer", 0.0)), 1.1)
	var staff = Vector2(float(z.x) - 30.0, game._row_center_y(int(z.row)) - 58.0)
	for cell in cells:
		game.effects.append({"shape": "ancient_hex", "owner": int(z.uid), "cell": cell, "plant": game.grid[cell.x][cell.y], "from": staff, "position": game._cell_center(cell.x, cell.y), "radius": 40.0, "time": 1.0, "duration": 1.0, "color": Color.WHITE})
	game._play_sfx(game.SFX_SHOOT_ENERGY_PATH, -12.0, 0.7)


func _cancel_hexes(owner_uid: int) -> void:
	for h in range(game.effects.size() - 1, -1, -1):
		var effect: Dictionary = game.effects[h]
		if String(effect.get("shape", "")) == "ancient_hex" and int(effect.owner) == owner_uid:
			game.effects.remove_at(h)


func _resolve_hex(hex: Dictionary) -> void:
	if not _owner_alive(int(hex.owner)):
		return
	var cell: Vector2i = hex.cell
	var plant = game.grid[cell.x][cell.y]
	if plant == null or not is_same(plant, hex.plant) or float(plant.get("health", 0.0)) <= 0.0:
		return
	if float(plant.get("holy_invincible_timer", 0.0)) > 0.0:
		fx("ancient_hex_fizzle", game._cell_center(cell.x, cell.y), 40.0, 0.5)
		return
	plant["ancient_sheep_until"] = game.level_time + float(Defs.ZOMBIES.ancient_mage.sheep_duration)
	plant["ancient_sheep_owner"] = int(hex.owner)
	plant["flash"] = 0.4
	fx("ancient_poof", game._cell_center(cell.x, cell.y) + Vector2(0, -10), 52.0, 0.6, {"color": Color("#c9a8ff")})
	game._play_sfx(game.SFX_HIT_SOFT_PATH, -10.0, 1.6)


func is_sheep(plant) -> bool:
	return plant != null and float(plant.get("ancient_sheep_until", 0.0)) > game.level_time


func _update_sheep() -> void:
	for r in range(game.ROWS):
		for c in range(game.COLS):
			var plant = game.grid[r][c]
			if plant == null or not plant.has("ancient_sheep_until"):
				continue
			var expired = float(plant.ancient_sheep_until) <= game.level_time
			if not expired and _owner_alive(int(plant.get("ancient_sheep_owner", -1))):
				continue
			plant.erase("ancient_sheep_until")
			plant.erase("ancient_sheep_owner")
			plant["flash"] = 0.35
			fx("ancient_poof", game._cell_center(r, c) + Vector2(0, -10), 46.0, 0.55, {"color": Color("#fff4cf")})


func _strategist_holds(z: Dictionary) -> bool:
	var hold_x: float = game.BOARD_ORIGIN.x + game.CELL_SIZE.x * 6.4
	if float(z.x) > hold_x:
		return false
	for other in game.zombies:
		if is_same(other, z) or not _enemy_alive(other) or String(other.kind) == "ancient_strategist":
			continue
		return true
	return false


func _pick_weather() -> String:
	var fire = 0
	var shooters = 0
	for r in range(game.ROWS):
		for c in range(game.COLS):
			var plant = game.grid[r][c]
			if plant == null:
				continue
			var kind = String(plant.get("fusion_kind", plant.kind))
			if kind in FIRE_KINDS or game._plant_has_component(plant, "torchwood"):
				fire += 1
			if Defs.PLANTS.get(kind, {}).has("shoot_interval") or Defs.PLANTS.get(kind, {}).get("fusion_attack", "") in ["shooter", "spread", "beam"]:
				shooters += 1
	if fire >= 2 and weather != "rain":
		return "rain"
	if shooters >= 6 and weather != "fog":
		return "fog"
	return "wind" if weather != "wind" else ("fog" if game.rng.randf() < 0.5 else "rain")


func _update_strategist(z: Dictionary, delta: float) -> void:
	var data: Dictionary = Defs.ZOMBIES.ancient_strategist
	if float(z.x) > game.BOARD_ORIGIN.x + game.board_size.x:
		return
	z["ancient_weather_timer"] = float(z.get("ancient_weather_timer", 6.0)) - delta
	z["ancient_command_timer"] = float(z.get("ancient_command_timer", 4.0)) - delta
	if float(z.ancient_weather_timer) <= 0.0 and active():
		z["ancient_weather_timer"] = float(data.weather_interval)
		z["ancient_anim"] = 1.2
		z["special_pause_timer"] = maxf(float(z.get("special_pause_timer", 0.0)), 1.2)
		set_override(_pick_weather(), int(z.uid), float(data.weather_duration))
		fx("ancient_fan_gust", _zombie_point(z) + Vector2(-20, -30), 160.0, 1.2)
	if float(z.ancient_command_timer) <= 0.0:
		z["ancient_command_timer"] = float(data.command_interval)
		_command(z)


func _row_defense(row: int, before_x: float) -> float:
	var total = 0.0
	for c in range(game.COLS):
		if game._cell_center(row, c).x > before_x:
			continue
		var plant = game._targetable_plant_at(row, c)
		if plant != null and float(plant.get("health", 0.0)) > 0.0:
			total += 1.0 + float(plant.health) / 400.0 + float(plant.get("armor_health", 0.0)) / 400.0
	return total


func _command(z: Dictionary) -> void:
	var issued = 0
	var center = _zombie_point(z)
	for i in range(game.zombies.size()):
		if issued >= 3:
			break
		var ally: Dictionary = game.zombies[i]
		if is_same(ally, z) or not _enemy_alive(ally) or game._is_boss_zombie(ally) or String(ally.kind) == "ancient_strategist":
			continue
		if bool(ally.get("jumping", false)) or bool(ally.get("flying", false)) or bool(ally.get("balloon_flying", false)):
			continue
		if absi(int(ally.row) - int(z.row)) > 2 or absf(float(ally.x) - float(z.x)) > game.CELL_SIZE.x * 3.5:
			continue
		var row = int(ally.row)
		var here = _row_defense(row, float(ally.x))
		var best_row = row
		var best = here
		for next in [row - 1, row + 1]:
			if next < 0 or next >= game.ROWS or not game._is_row_active(next):
				continue
			if not game._is_row_valid_for_spawn_kind(String(ally.kind), next):
				continue
			var value = _row_defense(next, float(ally.x))
			if value + 0.8 < best:
				best = value
				best_row = next
		ally["ancient_command_until"] = game.level_time + 4.0
		if best_row != row:
			ally["jumping"] = true
			ally["jump_t"] = 0.0
			ally["jump_from_x"] = float(ally.x)
			ally["jump_to_x"] = float(ally.x) - 12.0
			ally["jump_duration"] = 0.42
			ally["jump_row_to"] = best_row
			ally["jump_row_switched"] = false
		game.zombies[i] = ally
		fx("ancient_command", center + Vector2(-26, -40), 30.0, 0.8, {"target": _zombie_point(ally) + Vector2(0, -50)})
		issued += 1
	if issued > 0:
		z["ancient_anim"] = maxf(float(z.get("ancient_anim", 0.0)), 0.6)


# ---------------------------------------------------------------- drawing delegates

func draw_plant(kind: String, center: Vector2, scale: float = 1.0, flash: float = 0.0, alpha: float = 1.0, plant: Dictionary = {}) -> void:
	Visuals.draw_plant(game, kind, center, scale, flash, alpha, plant)


func draw_zombie(center: Vector2, z: Dictionary) -> void:
	Visuals.draw_zombie(game, center, z)


func draw_spore(shot: Dictionary) -> void:
	Visuals.draw_spore(game, shot)


func draw_ground() -> void:
	if game._is_ancient_level():
		Visuals.draw_ground(game, self)
	Visuals.draw_corrosion(game, self)


func draw_background() -> void:
	Visuals.draw_background(game, self)


func draw_overlay() -> void:
	if active():
		Visuals.draw_weather(game, self)


func draw_hud() -> void:
	if active():
		Visuals.draw_weather_chip(game, self)


func draw_effect(effect: Dictionary) -> bool:
	return Visuals.draw_effect(game, effect)


func lane_color(row: int) -> Color:
	return Visuals.lane_color(game, self, row)
