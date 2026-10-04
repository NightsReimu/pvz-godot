extends RefCounted
class_name GameDefs

const PlantDefs = preload("res://scripts/data/plant_defs.gd")
const FusionPlantDefs = preload("res://scripts/data/fusion_plant_defs.gd")
const ZombieDefs = preload("res://scripts/data/zombie_defs.gd")
const FusionZombieDefs = preload("res://scripts/data/fusion_zombie_defs.gd")
const DayLevelDefs = preload("res://scripts/data/level_defs_day.gd")
const NightLevelDefs = preload("res://scripts/data/level_defs_night.gd")
const PoolLevelDefs = preload("res://scripts/data/level_defs_pool.gd")
const FogLevelDefs = preload("res://scripts/data/level_defs_fog.gd")
const RoofLevelDefs = preload("res://scripts/data/level_defs_roof.gd")
const CityLevelDefs = preload("res://scripts/data/level_defs_city.gd")
const VolcanoLevelDefs = preload("res://scripts/data/level_defs_volcano.gd")
const AncientLevelDefs = preload("res://scripts/data/level_defs_ancient.gd")

const PLANT_ORDER = PlantDefs.ORDER
static var PLANTS: Dictionary = FusionPlantDefs.with_fusions(PlantDefs.PLANTS, PlantDefs.ORDER)
static var ZOMBIES: Dictionary = FusionZombieDefs.with_fusions(ZombieDefs.ZOMBIES)
static var LEVELS = DayLevelDefs.LEVELS + NightLevelDefs.LEVELS + PoolLevelDefs.LEVELS + FogLevelDefs.LEVELS + RoofLevelDefs.LEVELS + CityLevelDefs.LEVELS + VolcanoLevelDefs.LEVELS + AncientLevelDefs.LEVELS
