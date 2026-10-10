extends RefCounted
# Which emitter module owns a reworked TH06-08 card. Difficulty originals
# ("pressure_*") and finale moves ("finale_*") keep their shared emitters.

const EosdDanmaku = preload("res://scripts/runtime/eosd_danmaku.gd")
const PcbDanmaku = preload("res://scripts/runtime/pcb_danmaku.gd")
const NightDanmaku = preload("res://scripts/runtime/imperishable_road_danmaku.gd")
const MoonDanmaku = preload("res://scripts/runtime/imperishable_finale_danmaku.gd")
const MODULES := [EosdDanmaku, PcbDanmaku, NightDanmaku, MoonDanmaku]

static func module_for(kind: String, pattern: String):
	if pattern.begins_with("pressure_") or pattern.begins_with("finale_"):
		return null
	for module in MODULES:
		if kind in module.KINDS and module.owns(pattern):
			return module
	return null

static func owns(kind: String, pattern: String) -> bool:
	return module_for(kind, pattern) != null
