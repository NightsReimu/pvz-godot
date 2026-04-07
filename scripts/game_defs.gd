extends RefCounted
class_name GameDefs

const PlantDefs = preload("res://scripts/data/plant_defs.gd")
const ZombieDefs = preload("res://scripts/data/zombie_defs.gd")
const DayLevelDefs = preload("res://scripts/data/level_defs_day.gd")
const NightLevelDefs = preload("res://scripts/data/level_defs_night.gd")
const PoolLevelDefs = preload("res://scripts/data/level_defs_pool.gd")
const FogLevelDefs = preload("res://scripts/data/level_defs_fog.gd")
const RoofLevelDefs = preload("res://scripts/data/level_defs_roof.gd")
const CityLevelDefs = preload("res://scripts/data/level_defs_city.gd")

const PLANT_ORDER = PlantDefs.ORDER
const PLANTS = PlantDefs.PLANTS
const ZOMBIES = ZombieDefs.ZOMBIES
static var LEVELS = DayLevelDefs.LEVELS + NightLevelDefs.LEVELS + PoolLevelDefs.LEVELS + FogLevelDefs.LEVELS + RoofLevelDefs.LEVELS + CityLevelDefs.LEVELS
