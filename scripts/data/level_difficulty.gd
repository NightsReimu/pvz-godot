extends RefCounted
class_name LevelDifficulty

const ZombieDefs = preload("res://scripts/data/zombie_defs.gd")

static func build_hard_level(base: Dictionary) -> Dictionary:
	var level := base.duplicate(true)
	var profile := _hard_profile(base)
	level["regular_difficulty"] = "hard"
	level["hard_mode"] = true
	level["title"] = "%s · 困难" % String(base.get("title", base.get("id", "关卡")))
	level["description"] = "困难：%s；僵尸数量与波数至少提升至普通的两倍。" % String(profile.get("label", "强化敌群"))
	level["hard_profile"] = profile.duplicate(true)
	var source_events: Array = Array(base.get("events", [])).duplicate(true)
	var regular_events: Array = []
	var boss_events: Array = []
	for event_variant in source_events:
		var event := Dictionary(event_variant).duplicate(true)
		var kind := String(event.get("kind", event.get("zombie", "")))
		if bool(ZombieDefs.ZOMBIES.get(kind, {}).get("boss", false)):
			boss_events.append(event)
		else:
			regular_events.append(event)

	var first_end := _last_event_time(regular_events)
	var shift := maxf(first_end + 8.0, 18.0)
	var hard_events: Array = []
	for event in regular_events:
		hard_events.append(event.duplicate(true))
	for event in regular_events:
		var copy: Dictionary = event.duplicate(true)
		copy["time"] = float(copy.get("time", 0.0)) + shift
		hard_events.append(copy)

	# Add a small rotating set of tougher ordinary enemies without touching any
	# boss or stage-specific special event.
	var extras: Array = Array(profile.get("extra_kinds", []))
	var extra_index := 0
	var extra_stride := maxi(3, int(profile.get("extra_stride", 7)))
	for i in range(hard_events.size()):
		var candidate := Dictionary(hard_events[i])
		if not _is_spawn_event(candidate) or i % extra_stride != int(profile.get("extra_offset", 4)) or extras.is_empty():
			continue
		var extra := candidate.duplicate(true)
		extra["kind"] = extras[extra_index % extras.size()]
		extra["time"] = float(candidate.get("time", 0.0)) + 0.45
		hard_events.append(extra)
		extra_index += 1

	var target_waves := maxi(2, _wave_count(source_events) * 2 + int(profile.get("wave_bonus", 0)))
	var missing_waves := maxi(0, target_waves - _wave_count(hard_events))
	# Very short tutorial stages have no explicit flags; hard mode still gets
	# two visible pressure breaks. Boss-wave flags are also counted here so the
	# displayed wave total is genuinely at least double the ordinary stage.
	for wave_index in range(missing_waves):
		hard_events.append({"time": shift * (0.42 + float(wave_index + 1) / float(missing_waves + 1)), "kind": "flag", "wave": true})

	hard_events.sort_custom(func(a, b): return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	var final_time := _last_event_time(hard_events) + 8.0
	for event in boss_events:
		var boss: Dictionary = event.duplicate(true)
		boss["time"] = final_time
		hard_events.append(boss)
		final_time += 4.0
	hard_events.sort_custom(func(a, b): return float(a.get("time", 0.0)) < float(b.get("time", 0.0)))
	level["events"] = hard_events
	level["hard_wave_multiplier"] = 2.0
	level["hard_zombie_multiplier"] = 2.0
	return level

static func _last_event_time(events: Array) -> float:
	var result := 0.0
	for event_variant in events:
		result = maxf(result, float(Dictionary(event_variant).get("time", 0.0)))
	return result

static func _wave_count(events: Array) -> int:
	var result := 0
	for event_variant in events:
		var event := Dictionary(event_variant)
		if bool(event.get("wave", false)) or String(event.get("kind", "")) == "flag":
			result += 1
	return result

static func _is_spawn_event(event: Dictionary) -> bool:
	var kind := String(event.get("kind", event.get("zombie", "")))
	return kind != "" and kind != "flag" and not bool(event.get("wave", false)) and ZombieDefs.ZOMBIES.has(kind)

static func _hard_profile(base: Dictionary) -> Dictionary:
	var level_id := String(base.get("id", "1-1"))
	var parts := level_id.split("-")
	var world := int(parts[0]) if not parts.is_empty() and String(parts[0]).is_valid_int() else 1
	var stage_token := String(parts[1]) if parts.size() > 1 else "1"
	# Branch stages such as 1-S4 receive their own slots after the numbered
	# stages instead of silently reusing the 1-1 design.
	var stage := int(stage_token) if stage_token.is_valid_int() else (20 + int(stage_token.trim_prefix("S")) if stage_token.trim_prefix("S").is_valid_int() else 1)
	var profiles: Dictionary = {
		1: [
			{"label": "路障先锋与撑杆跳突袭", "extra_kinds": ["conehead", "pole_vault"], "extra_stride": 6},
			{"label": "铁桶护卫压阵", "extra_kinds": ["buckethead", "conehead"], "extra_stride": 7},
			{"label": "报纸狂奔与路障夹击", "extra_kinds": ["newspaper", "conehead", "pole_vault"], "extra_stride": 5},
			{"label": "铁门盾墙推进", "extra_kinds": ["screen_door", "buckethead"], "extra_stride": 6},
			{"label": "橄榄球重装冲线", "extra_kinds": ["football", "conehead"], "extra_stride": 5},
		],
		2: [
			{"label": "报纸与舞王夜袭", "extra_kinds": ["newspaper", "dancing"], "extra_stride": 6},
			{"label": "矿工掘进与撑杆跳", "extra_kinds": ["digger_zombie", "pole_vault"], "extra_stride": 5},
			{"label": "篮球投掷与铁门护行", "extra_kinds": ["basketball", "screen_door"], "extra_stride": 6},
			{"label": "魅惑盒与橄榄球压境", "extra_kinds": ["jack_in_the_box_zombie", "football"], "extra_stride": 5},
			{"label": "黑暗橄榄球混编", "extra_kinds": ["dark_football", "ninja", "newspaper"], "extra_stride": 4},
		],
		3: [
			{"label": "鸭泳圈与海豚骑士夹岸", "extra_kinds": ["ducky_tube", "dolphin_rider"], "extra_stride": 6},
			{"label": "浮圈铁桶抢滩", "extra_kinds": ["lifebuoy_bucket", "lifebuoy_cone"], "extra_stride": 5},
			{"label": "潜水与气球交错进攻", "extra_kinds": ["snorkel", "balloon_zombie"], "extra_stride": 6},
			{"label": "雪橇冰道与海豚突击", "extra_kinds": ["bobsled_team", "dolphin_rider"], "extra_stride": 5},
			{"label": "水陆双线滚筒推进", "extra_kinds": ["zomboni", "snorkel", "lifebuoy_normal"], "extra_stride": 4},
		],
		4: [
			{"label": "气球遮蔽与矿工渗透", "extra_kinds": ["balloon_zombie", "digger_zombie"], "extra_stride": 6},
			{"label": "忍者冲刺与龙卷扰流", "extra_kinds": ["ninja", "tornado_zombie"], "extra_stride": 5},
			{"label": "骆驼骑队与铁门护航", "extra_kinds": ["camel_zombie", "screen_door"], "extra_stride": 6},
			{"label": "末影瞬移和挖掘夹击", "extra_kinds": ["enderman_zombie", "digger_zombie"], "extra_stride": 5},
			{"label": "巫师催眠与暗影推进", "extra_kinds": ["wizard_zombie", "shade_zombie", "ninja"], "extra_stride": 4},
		],
		5: [
			{"label": "梯子架桥与蹦极空降", "extra_kinds": ["ladder_zombie", "bungee_zombie"], "extra_stride": 6},
			{"label": "投石车远射与撑杆跳", "extra_kinds": ["catapult_zombie", "pole_vault"], "extra_stride": 5},
			{"label": "矿工梯队和气球遮顶", "extra_kinds": ["digger_zombie", "balloon_zombie", "ladder_zombie"], "extra_stride": 5},
			{"label": "巨人带小鬼破阵", "extra_kinds": ["gargantuar", "imp"], "extra_stride": 7},
			{"label": "雪橇与滚筒压屋顶", "extra_kinds": ["bobsled_team", "zomboni", "catapult_zombie"], "extra_stride": 4},
		],
		6: [
			{"label": "程序员投影与路由干扰", "extra_kinds": ["programmer_zombie", "router_zombie"], "extra_stride": 6},
			{"label": "盾卫推进与医疗支援", "extra_kinds": ["shieldbearer_zombie", "medic_zombie"], "extra_stride": 5},
			{"label": "破坏者与裂隙突袭", "extra_kinds": ["saboteur_zombie", "rift_zombie"], "extra_stride": 6},
			{"label": "飞艇龙舟和投弹混编", "extra_kinds": ["dragon_boat", "bomber_zombie"], "extra_stride": 5},
			{"label": "凋零重装护卫群", "extra_kinds": ["wither_zombie", "shieldbearer_zombie", "medic_zombie"], "extra_stride": 4},
		],
		7: [
			{"label": "余烬奔行与玄武岩护卫", "extra_kinds": ["cinder_runner", "basalt_guard"], "extra_stride": 6},
			{"label": "窑工筑墙和硫磺搬运", "extra_kinds": ["kiln_mason", "sulfur_carrier"], "extra_stride": 5},
			{"label": "灰烬钟鸣与晶簇护甲", "extra_kinds": ["ash_bell", "geode_zombie"], "extra_stride": 6},
			{"label": "喷口穿行与余烬夹击", "extra_kinds": ["vent_tunneler", "cinder_runner"], "extra_stride": 5},
			{"label": "火山全谱混编", "extra_kinds": ["basalt_guard", "kiln_mason", "geode_zombie", "sulfur_carrier"], "extra_stride": 4},
		],
	}
	var list: Array = profiles.get(world, profiles[1])
	var selected: Dictionary = Dictionary(list[posmod(stage - 1, list.size())]).duplicate(true)
	var valid: Array = []
	for kind_variant in Array(selected.get("extra_kinds", [])):
		var kind := String(kind_variant)
		if ZombieDefs.ZOMBIES.has(kind) and not bool(ZombieDefs.ZOMBIES[kind].get("boss", false)):
			valid.append(kind)
	selected["extra_kinds"] = valid
	var variant_pools: Dictionary = {
		1: ["normal", "conehead", "pole_vault", "buckethead", "newspaper", "screen_door", "football", "dancing", "ninja", "basketball"],
		2: ["newspaper", "dancing", "digger_zombie", "basketball", "jack_in_the_box_zombie", "dark_football", "pogo_zombie", "ninja", "squash_zombie", "football"],
		3: ["ducky_tube", "lifebuoy_cone", "lifebuoy_bucket", "snorkel", "dolphin_rider", "balloon_zombie", "bobsled_team", "zomboni", "lifebuoy_normal", "digger_zombie"],
		4: ["balloon_zombie", "digger_zombie", "ninja", "tornado_zombie", "camel_zombie", "enderman_zombie", "wizard_zombie", "shade_zombie", "screen_door", "pogo_zombie"],
		5: ["ladder_zombie", "bungee_zombie", "catapult_zombie", "pole_vault", "digger_zombie", "balloon_zombie", "gargantuar", "bobsled_team", "zomboni", "football"],
		6: ["programmer_zombie", "router_zombie", "shieldbearer_zombie", "medic_zombie", "saboteur_zombie", "rift_zombie", "dragon_boat", "bomber_zombie", "wither_zombie", "enderman_zombie"],
		7: ["cinder_runner", "basalt_guard", "kiln_mason", "sulfur_carrier", "ash_bell", "geode_zombie", "vent_tunneler", "cinder_runner", "basalt_guard", "geode_zombie"],
	}
	var variant_pool: Array = variant_pools.get(world, variant_pools[1])
	var variant_kind := String(variant_pool[posmod(stage - 1, variant_pool.size())])
	if variant_kind != "normal" and ZombieDefs.ZOMBIES.has(variant_kind) and not bool(ZombieDefs.ZOMBIES[variant_kind].get("boss", false)) and not valid.has(variant_kind):
		valid.append(variant_kind)
	selected["extra_kinds"] = valid
	selected["level_id"] = level_id
	selected["design_index"] = stage
	selected["label"] = "%s（%s）" % [String(selected.get("label", "强化敌群")), level_id]
	selected["extra_offset"] = posmod(stage + world, int(selected.get("extra_stride", 6)))
	selected["wave_bonus"] = 1 if stage >= 10 else 0
	return selected
