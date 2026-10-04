extends RefCounted
# Payload composition never replaces the native kind: orbit, return, split, arc and
# armor rules continue to run in the same projectile handlers used by the parent.
const BASES = ["pea","snow_pea","fire_pea","amber_pea","boomerang","sakura_petal","mist_bloom","glow_seed","heather_thorn","origami_plane","star_shot","moonforge_shot","prism_pea","shadow_pea","spiral_bamboo","cluster_boomerang","frost_boomerang","amber_ultimate_shard","mango","phoenix_flame","cabbage","kernel","butter","melon","chimney_fire","meteor_flower","dragon_bubble","toxic_gum","gator_orb","angel_spear","lotus_orbit_shot","lotus_converge_shot","prism_fragment","sakura_shard","obsidian_artichoke","sulfur_pod","pressure_bamboo","fumarole_melon","caldera_lotus","resonance_beet"]
const ELEMENTS = ["flame","frost","venom","storm","dream","root"]
static func catalogue() -> Array:
	var result: Array = BASES.duplicate()
	for base in BASES:
		for element in ELEMENTS: result.append(element+":"+base)
	for mask in range(1,1 << ELEMENTS.size()):
		var tags: Array = []
		for index in range(ELEMENTS.size()):
			if mask & (1 << index): tags.append(ELEMENTS[index])
		if tags.size() < 2: continue
		for base in BASES: result.append("+".join(tags)+":"+base)
	return result
static func compose(shot: Dictionary, weights: Dictionary, source: String = "") -> void:
	var elements: Array = shot.get("ammo_elements",[]).duplicate()
	var families := {
		"flame":["torchwood","jalapeno","phoenix_tree","dragon_fruit","chimney_pepper","caldera_lotus"],
		"frost":["snow_pea","ice_shroom","snow_bloom","frost_boomerang","ice_queen","frost_fan","frost_cypress"],
		"venom":["heather_shooter","toxic_gum_pult","sulfur_pod"],
		"storm":["storm_reed","thunder_pine","thunder_god","tesla_tulip","plasma_shooter"],
		"dream":["hypno_shroom","chaos_shroom"],"root":["root_snare","anchor_fern","vine_emperor","glow_ivy"]}
	for element in families:
		for component in families[element]:
			if weights.has(component) and component != source and not element in elements: elements.append(element)
	shot.ammo_elements = elements
	shot.ammo_identity = "+".join(elements)+":"+String(shot.get("volcano_seed",shot.get("kind","pea")))
	if "flame" in elements:
		shot.fire = true
		shot.burn_damage = maxf(float(shot.get("burn_damage",0)),8.0)
		shot.burn_duration = maxf(float(shot.get("burn_duration",0)),3.2)
		if shot.get("kind","") == "boomerang": shot.flame_boomerang = true
	if "frost" in elements: shot.slow_duration = maxf(float(shot.get("slow_duration",0)),3.5)
	if "venom" in elements: shot.dot_damage = maxf(float(shot.get("dot_damage",0)),7.0); shot.dot_duration = maxf(float(shot.get("dot_duration",0)),4.0)
static func apply_status(z: Dictionary, shot: Dictionary) -> Dictionary:
	var elements: Array = shot.get("ammo_elements",[])
	if "flame" in elements or "venom" in elements:
		z.corrode_timer = maxf(float(z.get("corrode_timer",0)),4.0)
		z.corrode_dps = maxf(float(z.get("corrode_dps",0)),float(shot.get("burn_damage",0))+float(shot.get("dot_damage",0)))
	if "frost" in elements:
		z.slow_timer = maxf(float(z.get("slow_timer",0)),3.5); z.slow_ratio = minf(float(z.get("slow_ratio",1)),0.5)
	if "storm" in elements: z.special_pause_timer = maxf(float(z.get("special_pause_timer",0)),0.25)
	if "root" in elements: z.rooted_timer = maxf(float(z.get("rooted_timer",0)),1.2)
	return z
