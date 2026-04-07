extends RefCounted
class_name LevelDefs

const DayLevelDefs = preload("res://scripts/data/level_defs_day.gd")
const NightLevelDefs = preload("res://scripts/data/level_defs_night.gd")
const PoolLevelDefs = preload("res://scripts/data/level_defs_pool.gd")
const FogLevelDefs = preload("res://scripts/data/level_defs_fog.gd")
const RoofLevelDefs = preload("res://scripts/data/level_defs_roof.gd")
const CityLevelDefs = preload("res://scripts/data/level_defs_city.gd")

static var LEVELS = DayLevelDefs.LEVELS + NightLevelDefs.LEVELS + PoolLevelDefs.LEVELS + FogLevelDefs.LEVELS + RoofLevelDefs.LEVELS + CityLevelDefs.LEVELS
