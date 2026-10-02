extends RefCounted

# Illustration layers read the existing combat clocks; they own no attacks or timers.
const ASSETS := {
	"crimson_seal": "res://art/touhou_spell_fx/crimson_seal.png",
	"golden_starfield": "res://art/touhou_spell_fx/golden_starfield.png",
	"frost_crystal": "res://art/touhou_spell_fx/frost_crystal.png",
	"sakura_spirit": "res://art/touhou_spell_fx/sakura_spirit.png",
	"phoenix_fire": "res://art/touhou_spell_fx/phoenix_fire.png",
	"boundary_gap": "res://art/touhou_spell_fx/boundary_gap.png",
}
const KIND_ART := {
	"reimu_boss": "crimson_seal", "chen_boss": "crimson_seal",
	"marisa_boss": "golden_starfield", "flandre_boss": "golden_starfield",
	"cirno_boss": "frost_crystal", "letty_boss": "frost_crystal",
	"youmu_boss": "sakura_spirit", "yuyuko_boss": "sakura_spirit",
	"mokou_boss": "phoenix_fire", "yukari_boss": "boundary_gap",
}
const MAX_ACCENTS := 12
static var textures: Dictionary = {}


static func texture(asset: String) -> Texture2D:
	if not ASSETS.has(asset):
		return null
	if not textures.has(asset):
		var path := String(ASSETS[asset])
		textures[asset] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return textures[asset] as Texture2D


static func state(cast: Dictionary) -> Dictionary:
	var card: Dictionary = cast.get("card", {})
	var kind := String(cast.get("kind", ""))
	var age := float(cast.get("age", -1.0))
	var duration := float(cast.get("duration", 0.0))
	if not KIND_ART.has(kind) or card.is_empty() or String(card.get("origin", "")) == "nonspell" or age < 0 or duration <= 0 or age >= duration:
		return {}
	var asset := String(KIND_ART[kind])
	var enter := clampf(age / 0.28, 0.0, 1.0)
	var leave := clampf((duration - age) / 0.65, 0.0, 1.0)
	var pulse := sin(age * 3.6) * 0.025
	var extent := 238.0
	var angle := age * 0.16
	if asset == "phoenix_fire":
		extent = 306.0
		angle = sin(age * 1.4) * 0.035
	elif asset == "boundary_gap":
		extent = 306.0
		angle = 0.0
	elif asset == "frost_crystal":
		extent = 222.0
		angle = -age * 0.13
	return {"asset": asset, "alpha": enter * leave * (0.34 + pulse), "extent": extent * (0.76 + 0.24 * (1.0 - pow(1.0 - enter, 3.0)) + pulse), "angle": angle}


static func _stamp(game: Control, asset: String, center: Vector2, extent: float, alpha: float, angle: float = 0.0, squash: float = 1.0) -> void:
	if alpha <= 0.0:
		return
	var image := texture(asset)
	if image == null:
		return
	game._set_combat_transform(center, angle, Vector2(1.0, squash))
	game.draw_texture_rect(image, Rect2(Vector2.ONE * -extent * 0.5, Vector2.ONE * extent), false, Color(1, 1, 1, clampf(alpha, 0.0, 0.42)))
	game._set_combat_transform()


static func _boss_center(game: Control, boss: Dictionary, unit_scale: float) -> Vector2:
	var center := Vector2(float(boss.x), game._row_center_y(int(boss.row)) + float(boss.get("jump_offset", 0.0)))
	center = Vector2(game._zombie_draw_motion(boss, center).center)
	if String(boss.kind) == "mokou_boss":
		center.y = maxf(center.y, game.BOARD_ORIGIN.y + 160 * unit_scale)
	return center + Vector2(0, -70.0 * unit_scale)


static func draw(game: Control) -> void:
	var scale: float = game._battle_unit_scale()
	var owners := {}
	for boss in game.zombies:
		var kind := String(boss.kind)
		var surviving := bool(boss.get("touhou_invulnerable", false)) and float(boss.get("touhou_survival_timer", 0.0)) > 0.0
		if not KIND_ART.has(kind) or (float(boss.health) <= 0.0 and not surviving):
			continue
		owners[int(boss.get("touhou_owner", -1))] = boss
		if bool(boss.get("boss_cast_pending", false)):
			var card: Dictionary = game.TouhouSpellDefs.card_for(boss, game.current_level)
			if String(card.get("origin", "")) == "nonspell":
				continue
			var progress := clampf(1.0 - float(boss.get("boss_skill_timer", 0.0)) / game.ZombieRuntime.BOSS_WINDUP, 0.0, 1.0)
			_stamp(game, String(KIND_ART[kind]), _boss_center(game, boss, scale), lerpf(140.0, 226.0, progress) * scale, progress * 0.24, progress * 0.22 if kind != "yukari_boss" else 0.0)
	if game.touhou_danmaku != null:
		for cast in game.touhou_danmaku.casts:
			var visual := state(cast)
			if visual.is_empty() or not owners.has(int(cast.owner)):
				continue
			_stamp(game, visual.asset, _boss_center(game, owners[int(cast.owner)], scale), float(visual.extent) * scale, visual.alpha, visual.angle)
		var beam_count := 0
		for beam in game.touhou_danmaku.beams:
			if String(beam.kind) != "marisa_boss" or beam_count >= MAX_ACCENTS:
				continue
			var age := float(beam.age)
			var delay := maxf(float(beam.delay), 0.01)
			var fade := clampf((delay + float(beam.duration) - age) / 0.2, 0.0, 1.0)
			var charge := clampf(age / delay, 0.0, 1.0)
			_stamp(game, "golden_starfield", Vector2(beam.from), lerpf(64.0, 112.0, charge) * scale, (0.12 + charge * 0.24) * fade, age * 0.8)
			beam_count += 1
	_draw_tiles(game)
	var accent_count := 0
	for effect in game.effects:
		if accent_count >= MAX_ACCENTS:
			break
		var shape := String(effect.get("shape", ""))
		if shape not in ["yukari_boundary_arrival", "yukari_boundary_expansion", "yukari_evil_eye_screen", "yuyuko_full_bloom", "yuyuko_resurrection", "youmu_half_ghost"]:
			continue
		var duration := maxf(float(effect.get("duration", 0.0)), 0.01)
		var remaining := clampf(float(effect.get("time", 0.0)) / duration, 0.0, 1.0)
		var fade := minf(remaining * 3.0, (1.0 - remaining) * 6.0)
		var gap := shape.begins_with("yukari_")
		var asset := "boundary_gap" if gap else "sakura_spirit"
		var extent := clampf(float(effect.get("radius", 70.0)) * 2.2, 90.0 * scale, 260.0 * scale)
		_stamp(game, asset, Vector2(effect.position), extent, fade * 0.32, 0.0 if gap else (1.0 - remaining) * 0.3)
		if gap and effect.has("target"):
			_stamp(game, asset, Vector2(effect.target), extent, fade * 0.28)
		accent_count += 1


static func _draw_tiles(game: Control) -> void:
	# These illustrations follow the actual timed seal/glare/burning cells.
	# Tile outlines, attack telegraphs, units and bullets are drawn above this pass.
	var count := 0
	for runtime in [game.reimu_runtime, game.marisa_runtime, game.mokou_runtime]:
		if runtime == null:
			continue
		var entries: Array = runtime.marks if runtime == game.mokou_runtime else runtime.tiles
		for tile in entries:
			var kind := String(tile.kind)
			if count >= MAX_ACCENTS:
				return
			if kind not in ["seal", "glare", "prism", "ember", "rebirth"]:
				continue
			var asset := "crimson_seal" if kind == "seal" else ("phoenix_fire" if kind in ["ember", "rebirth"] else "golden_starfield")
			var age := float(tile.age)
			var delay := maxf(float(tile.delay), 0.01)
			var remaining := delay + float(tile.get("duration", 6.0)) - age
			var fade := clampf(age / 0.25, 0.0, 1.0) * clampf(remaining / 0.4, 0.0, 1.0)
			var active := age >= delay
			var extent := minf(game.CELL_SIZE.x, game.CELL_SIZE.y) * (0.84 if active else 0.65)
			_stamp(game, asset, game._cell_center(int(tile.cell.x), int(tile.cell.y)), extent, fade * (0.30 if active else 0.16), age * 0.22, 0.8)
			count += 1
