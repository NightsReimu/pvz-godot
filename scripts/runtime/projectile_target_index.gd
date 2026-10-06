extends RefCounted

# Only broad-phase membership is cached. Native visibility, allegiance, life,
# multi-body geometry and the exact endpoint test are evaluated for every shot.
# Scalar signatures are synchronized on EVERY query: impacts can push, spawn,
# remove or morph targets during the same projectile update.
var game: Control
var _width := 32.0
var _xs := PackedFloat64Array()
var _rows := PackedInt32Array()
var _uids := PackedInt64Array()
var _kinds := PackedStringArray()
var _bins: Dictionary = {}
var _bosses: Array[int] = []

func _init(owner: Control) -> void:
	game = owner

func _insert(index: int, row: int, x: float, kind: String) -> void:
	# All bosses stay in the conservative bucket. Their native body geometry
	# may depend on time, active lanes or encounter state without changing x/row.
	if game._is_boss_kind(kind) or kind == "prismriver_boss":
		_bosses.append(index)
		return
	var bucket := floori(x / _width)
	if not _bins.has(row): _bins[row] = {}
	if not _bins[row].has(bucket): _bins[row][bucket] = []
	_bins[row][bucket].append(index)

func _remove(index: int, row: int, x: float, kind: String) -> void:
	if game._is_boss_kind(kind) or kind == "prismriver_boss":
		_bosses.erase(index)
		return
	var bucket := floori(x / _width)
	var bins: Dictionary = _bins[row]
	bins[bucket].erase(index)
	if bins[bucket].is_empty(): bins.erase(bucket)
	if bins.is_empty(): _bins.erase(row)

func _rebuild(width: float) -> void:
	_width = width
	_bins.clear(); _bosses.clear()
	var count: int = game.zombies.size()
	_xs.resize(count); _rows.resize(count); _uids.resize(count); _kinds.resize(count)
	for index in range(count):
		var z: Dictionary = game.zombies[index]
		_xs[index] = float(z.x); _rows[index] = int(z.row)
		_uids[index] = int(z.get("uid", -1)); _kinds[index] = String(z.kind)
		_insert(index, _rows[index], _xs[index], _kinds[index])

func _synchronize() -> void:
	var width: float = maxf(game.CELL_SIZE.x * .5, 32.0)
	if game.zombies.size() != _xs.size() or width != _width:
		_rebuild(width)
		return
	for index in range(game.zombies.size()):
		var z: Dictionary = game.zombies[index]
		if int(z.get("uid", -1)) != _uids[index]:
			_rebuild(width)
			return
		var x := float(z.x); var row := int(z.row); var kind := String(z.kind)
		if x == _xs[index] and row == _rows[index] and kind == _kinds[index]: continue
		_remove(index, _rows[index], _xs[index], _kinds[index])
		_xs[index] = x; _rows[index] = row; _kinds[index] = kind
		_insert(index, row, x, kind)

func find(projectile: Dictionary) -> int:
	_synchronize()
	var position := Vector2(projectile.position)
	var radius := float(projectile.get("radius", 8.0))
	var free_aim := bool(projectile.get("free_aim", false))
	var moving_left := float(projectile.get("speed", 0.0)) < 0.0
	var target_y: float = position.y if free_aim else game._row_center_y(int(projectile.row))
	var y_radius := 24.0 if free_aim else 1.0
	# Cached x is a float64; native hit points are Vector2/float32. Widen the
	# broad phase for that rounding only, retaining the native strict final test.
	var epsilon := maxf(.0001, maxf(absf(position.x), absf(position.y)) * .000001)
	var first := floori((position.x - (20.0 + radius if moving_left else 20.0) - epsilon) / _width)
	var last := floori((position.x + (20.0 if moving_left else 20.0 + radius) + epsilon) / _width)
	var candidates: Array = []
	if last - first > maxi(32, game.zombies.size()):
		# Very large custom projectiles should cost O(enemies), not O(empty bins).
		candidates = range(game.zombies.size())
	else:
		candidates.append_array(_bosses)
		for row in _bins:
			if absf(game._row_center_y(int(row)) - target_y) > y_radius + epsilon: continue
			var bins: Dictionary = _bins[row]
			for bucket in range(first, last + 1):
				if bins.has(bucket): candidates.append_array(bins[bucket])
	var best_index := -1
	var best_distance := 999999.0
	var anti_air := bool(projectile.get("anti_air", false))
	var ignore_lane_hide := bool(projectile.get("ignore_lane_hide", false))
	var ignored_uids: Array = projectile.get("hit_uids", [])
	for index in candidates:
		var zombie: Dictionary = game.zombies[index]
		# Endurance cards are deliberately kept alive by native cleanup even if
		# an impact briefly leaves zero HP before that cleanup executes.
		if float(zombie.get("health", 0.0)) <= 0.0 and not (bool(zombie.get("touhou_invulnerable", false)) and float(zombie.get("touhou_survival_timer", 0.0)) > 0.0): continue
		var hidden: bool = game._is_hidden_from_lane_attacks(zombie)
		var can_ignore_hidden: bool = ignore_lane_hide and not game._is_hidden_for_direct_fire_ignoring_fog(zombie)
		if (hidden and not can_ignore_hidden and not (anti_air and bool(zombie.get("balloon_flying", false)))) or not game._is_enemy_zombie(zombie): continue
		if bool(zombie.get("balloon_flying", false)) and not anti_air: continue
		if ignored_uids.has(int(zombie.get("uid", -1))): continue
		for point in game._zombie_hit_positions(zombie):
			if absf(point.y - target_y) > y_radius: continue
			var distance: float = position.x - point.x if moving_left else point.x - position.x
			if distance < -20.0 or distance > 20.0 + radius: continue
			if distance < best_distance or (best_index >= 0 and distance == best_distance and int(index) < best_index):
				best_distance = distance; best_index = int(index)
	return best_index
