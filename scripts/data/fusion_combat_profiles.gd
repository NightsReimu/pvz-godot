extends RefCounted

# Native weapons retain their own damage. Ash uses a bounded payload, never disposable blast damage.
const LOBBERS := ["cabbage_pult","kernel_pult","melon_pult","corn_cannon","moonforge","meteor_gourd","meteor_flower","pepper_mortar","chimney_pepper","skylight_melon","obsidian_artichoke","sulfur_pod","pressure_bamboo","fumarole_melon","caldera_lotus","blast_pomegranate","dandelion"]
# Ash blasts reach balloons and other fliers, like the native cherry, jalapeno and doom.
const ASH := ["cherry_bomb","jalapeno","doom_shroom","ice_shroom","core_blossom","glitch_walnut","snow_bloom"]

const BURSTS := {
 "cherry_bomb":{"damage":620.0,"interval":32.0,"radius":155.0,"blast_shape":"circle","deliver":true},
 "doom_shroom":{"damage":780.0,"interval":48.0,"radius":220.0,"blast_shape":"circle","deliver":true},
 "jalapeno":{"damage":560.0,"interval":36.0,"radius":10000.0,"blast_shape":"row","deliver":true},
 "potato_mine":{"damage":880.0,"interval":30.0,"radius":70.0,"blast_shape":"circle","deliver":false},
 "squash":{"damage":880.0,"interval":32.0,"radius":55.0,"blast_shape":"single","deliver":false,"range":120.0},
 "tangle_kelp":{"damage":990.0,"interval":36.0,"radius":44.0,"blast_shape":"single","deliver":false,"range":44.0},
 "chomper":{"damage":990.0,"interval":42.0,"radius":44.0,"blast_shape":"single","deliver":false,"range":92.0},
 "ice_shroom":{"damage":0.0,"interval":40.0,"radius":10000.0,"blast_shape":"freeze","deliver":false},
 "snow_bloom":{"damage":0.0,"interval":32.0,"radius":220.0,"blast_shape":"freeze","deliver":false},
 "dream_disc":{"damage":26.0,"interval":24.0,"radius":150.0,"blast_shape":"sleep","deliver":false},
 "sand_lotus":{"damage":40.0,"interval":28.0,"radius":150.0,"blast_shape":"snare","deliver":false},
 "cyclone_grass":{"damage":120.0,"interval":24.0,"radius":150.0,"blast_shape":"pull","deliver":false},
 "magma_stream":{"damage":56.0,"interval":32.0,"radius":170.0,"blast_shape":"magma","deliver":false},
 "core_blossom":{"damage":280.0,"interval":14.0,"radius":200.0,"blast_shape":"circle","deliver":true},
 "glitch_walnut":{"damage":340.0,"interval":32.0,"radius":220.0,"blast_shape":"circle","deliver":false},
 "golden_milk":{"damage":1000.0,"interval":34.0,"radius":10000.0,"blast_shape":"milk","deliver":false},
 "samsara_eye":{"damage":0.0,"interval":46.0,"radius":260.0,"blast_shape":"revive","deliver":false},
}

static func channels(native: Dictionary, weights: Dictionary, global_tags: Array, attack_for: Callable, traits_for: Callable) -> Array:
 var result: Array = []
 var sources: Array = weights.keys(); sources.sort()
 # More distinct weapons share the rootstock's energy; repeated materials have diminishing returns.
 var active_count := 0
 for source in sources:
  var stats: Dictionary = native[source]
  if BURSTS.has(source) or float(stats.get("damage",stats.get("contact_damage",stats.get("zone_damage",0)))) > 0 and source != "mirror_reed": active_count += 1
 var energy: float = 1.0 / sqrt(maxf(1.0,float(active_count)/3.0))
 var ballistic := sources.any(func(source): return not BURSTS.has(source) and attack_for.call(source) in ["shooter","spread","lobber","blade"] and float(native[source].get("damage",0)) > 0)
 for source in sources:
  var stats: Dictionary = native[source]
  var style: String = attack_for.call(source)
  var tags: Array = traits_for.call(source,stats)
  for tag in ["fire","frost","poison","hypno","reveal"]:
   if tag in global_tags and not tag in tags: tags.append(tag)
  var count: int = int(weights[source]); var growth: float = sqrt(float(count))
  if ballistic and source in ["cherry_bomb","doom_shroom","jalapeno"]:
   result.append({"source":source,"style":"payload","damage":0.0,"interval":0.0,"initial_delay":0.0,"radius":48.0 if source == "cherry_bomb" else (64.0 if source == "doom_shroom" else 0.0),"shots":1,"weight":count,"traits":tags,"mechanics":stats})
   continue
  if BURSTS.has(source):
   var burst: Dictionary = BURSTS[source].duplicate(true)
   burst.merge({"source":source,"style":"burst","traits":tags,"shots":1,"weight":count,"mechanics":stats},true)
   burst.damage = float(burst.damage)*energy*(1.0+0.22*(growth-1))
   burst.interval = float(burst.interval)*(1.0+0.18*(growth-1))
   # Long cooldowns use real time, so haste cannot turn explosions into rapid fire.
   burst.initial_delay = float(burst.interval)
   if weights.size() == 1 and count >= 2:
    # Pure twin chambers keep a native planting fuse, then recharge as living
    # chambers. This never applies to ash-infused shooter payloads above.
    burst.damage *= minf(4.0,float(count))*0.9
    burst.interval /= minf(2.0,1.0+0.5*float(count-1))
    burst.initial_delay = float(stats.get("arm_time",stats.get("fuse",0.6)))
    if source in ["cherry_bomb","jalapeno","doom_shroom"]:
     burst.opening_damage = float(stats.get("damage",burst.damage))*minf(4.0,float(count))*0.9
   result.append(burst); continue
  if source == "mirror_reed": continue # Reactive shield, not an imaginary pea cannon.
  var damage: float = float(stats.get("damage",stats.get("contact_damage",stats.get("zone_damage",0))))
  if damage <= 0: continue
  var interval: float = float(stats.get("fire_interval",stats.get("shoot_interval",stats.get("attack_interval",stats.get("contact_interval",stats.get("pulse_interval",stats.get("support_interval",3.0)))))))
  var shots: int = mini(4,count) if style in ["shooter","spread","blade"] else 1
  damage *= 0.9*growth*energy/float(shots)
  if source == "peashooter":
   shots = mini(6,count); damage = 20.0*energy*float(count)/float(shots) if count <= 6 else 20.0*energy*sqrt(float(count)/6.0)
  # High-damage native weapons retain their actual loading/charging time.
  interval = maxf(interval,float(stats.get("charge_time",0))+float(stats.get("recharge_time",0)))
  interval *= 1.0+0.12*(growth-1)
  if damage > 120: interval = maxf(interval,damage/45.0)
  if style == "sun": style = "shooter"
  if style in ["support","guard"]: style = "control"
  var reach: float = float(stats.get("range",stats.get("melee_range",stats.get("cone_range",stats.get("radius",10000.0)))))
  if source == "spikeweed": reach = 60.0
  if style in ["melee","control"]: reach = minf(reach,260.0)
  result.append({"source":source,"style":style,"damage":damage,"interval":maxf(0.8,interval),"initial_delay":interval if interval >= 10 else 0.55,"radius":float(stats.get("splash_radius",0)),"range":reach,"shots":shots,"weight":count,"traits":tags,"mechanics":stats})
 return result

static func describe(channel: Dictionary, native: Dictionary) -> String:
 if channel.style == "payload":
  return {"cherry_bomb":"樱桃弹头：原生弹型命中产生 48 像素小爆炸，整轮齐射共享伤害预算", "doom_shroom":"暗爆弹头：原生弹型命中产生 64 像素暗爆，整轮齐射共享伤害预算", "jalapeno":"灼烧弹头：保留原生弹型并附加持续灼烧，不另投整行炸弹"}[channel.source]
 var names := {"shooter":"直射","spread":"跨行射击","beam":"贯穿","lobber":"抛射","blade":"往返回旋","roller":"滚动","control":"范围脉冲","melee":"近战","burst":"蓄力"}
 var footprint := {"milk":"整行奶浪击退","revive":"复活附近倒下的植物","circle":"圆形范围爆炸","row":"整行火焰","single":"近身单体重击","freeze":"范围冻结","sleep":"范围催眠","snare":"范围缠根","pull":"范围聚拢","magma":"持续灼烧"}
 var action: String = footprint.get(channel.get("blast_shape",""),names.get(channel.style,channel.style))
 return "%s：%s，每 %.1f 秒 %d × %d 伤害%s" % [native[channel.source].name,action,float(channel.interval),int(channel.damage),int(channel.shots),"（独立充能）" if channel.style == "burst" else ""]
