extends RefCounted
class_name CombatVectorArt

## Runtime cache for the hand-authored combat SVG set.
## The loader is deliberately independent of gameplay state: a missing or
## malformed asset simply returns null so the established procedural renderer
## remains the safe fallback.

const PROJECTILE_ROOT := "res://art/vector/combat_projectiles/"
const EFFECT_ROOT := "res://art/vector/combat_effects/"

static var _projectiles: Dictionary = {}
static var _effects: Dictionary = {}

static func projectile_texture(kind: String) -> Texture2D:
	return _texture(_projectiles, PROJECTILE_ROOT, kind)

static func effect_texture(shape: String) -> Texture2D:
	return _texture(_effects, EFFECT_ROOT, shape)

static func _texture(cache: Dictionary, root: String, key: String) -> Texture2D:
	if key.is_empty():
		return null
	if cache.has(key):
		return cache[key] as Texture2D
	var path := root + key + ".svg"
	if not ResourceLoader.exists(path):
		cache[key] = null
		return null
	var texture := load(path) as Texture2D
	cache[key] = texture
	return texture

static func clear_cache() -> void:
	_projectiles.clear()
	_effects.clear()
