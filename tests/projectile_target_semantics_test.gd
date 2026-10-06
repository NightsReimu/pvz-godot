extends "res://tests/projectile_target_performance_test.gd"

var comparisons := 0
func make_game(dimensions: Vector2, legacy: bool = false) -> Control:
	return super.make_game(dimensions, legacy or OS.get_cmdline_user_args().has("--legacy"))
func agree(g: Control, p: Dictionary, label: String) -> void:
	comparisons += 1
	var expected: int = g.legacy_find_projectile_target(p)
	check(g._find_projectile_target(p) == expected, label + " agrees with the frozen live-target brute force")

func shot_at(g: Control, row: int, x: float) -> Dictionary:
	return {"row":row,"position":Vector2(x,g._row_center_y(row)),"speed":460.0,"radius":8.0}

func alive_parity() -> void:
	var random := RandomNumberGenerator.new(); random.seed = 179
	for dimensions in [Vector2(135,110), Vector2(76,33), Vector2(52,20), Vector2(37,.75)]:
		var g := make_game(dimensions)
		g.zombies.clear()
		for i in range(60):
			var kind: String = ["normal","digger_zombie","balloon_zombie","snorkel","shouyue"][i % 5]
			g._spawn_zombie_at(kind, random.randi_range(0,5), random.randf_range(10,1100), true)
			var z: Dictionary = g.zombies.back()
			z.health=100000000.0; z.balloon_flying=i%7==0; z.digger_tunneling=i%11==0
			z.submerged=i%13==0; z.hypnotized=i%17==0; z.revealed_timer=1.0 if i%3 else 0.0
		for i in range(2250):
			var n := random.randi_range(0,g.zombies.size()-1)
			g.zombies[n].x=random.randf_range(-100,1300)
			g.zombies[n].row=random.randi_range(0,5)
			var p := shot_at(g,random.randi_range(-1,6),random.randf_range(-100,1300))
			p.position.y += random.randf_range(-26,26)
			p.speed=-460.0 if i%2 else 460.0
			p.radius=random.randf_range(0,45)
			p.free_aim=i%3==0; p.anti_air=i%4==0; p.ignore_lane_hide=i%5==0
			p.hit_uids=[int(g.zombies[n].uid)] if i%7==0 else []
			agree(g,p,"Random geometry/hidden/air/ignore UID " + str(dimensions))
		g.free()

func same_frame_mutations() -> void:
	var g := make_game(Vector2(76,33))
	g.zombies.clear()
	for i in range(2): g._spawn_zombie_at("normal",2,400.0,true)
	var p := shot_at(g,2,400)
	agree(g,p,"Equal-distance array-index tie")
	check(g._find_projectile_target(p)==0,"Array order resolves equal distances")
	g.zombies.reverse(); agree(g,p,"Same-frame reversed equal-position identities")
	p.hit_uids=[int(g.zombies[0].uid)]; agree(g,p,"Piercing skips already hit UID")
	g.zombies[1].x=800.0; agree(g,p,"Same-frame milk knockback exits candidate bin")
	g.zombies[1].x=397.0; agree(g,p,"Same-frame teleport back enters candidate bin")
	g.zombies[1].row=4; agree(g,p,"Same-frame lane change")
	g.zombies[1].row=2; g.zombies[1].hypnotized=true; agree(g,p,"Live hypnosis allegiance")
	g.zombies[1].hypnotized=false; g.zombies[1].digger_tunneling=true; agree(g,p,"Live tunnel hiding")
	g.zombies[1].digger_tunneling=false; g.zombies[1].balloon_flying=true; agree(g,p,"Live anti-air restriction")
	p.anti_air=true; agree(g,p,"Anti-air hits an airborne target")
	g.zombies[1].balloon_flying=false
	g._spawn_zombie_at("normal",2,395.0,true); agree(g,p,"Same-frame new target closer than cached candidates")
	g.zombies.remove_at(0); agree(g,p,"Same-frame list erase remaps indices")
	g.zombies[0].kind="prismriver_boss"; agree(g,p,"Same-frame ordinary target becomes multi-body boss")
	g.zombies[0].kind="normal"; agree(g,p,"Same-frame multi-body boss becomes single-body target")
	g.BOARD_ORIGIN=Vector2(59,200); g.CELL_SIZE=Vector2(52,20)
	p.position=Vector2(395,g._row_center_y(2)); agree(g,p,"Same-frame layout resize")
	g.zombies.clear(); agree(g,p,"Clear/restart has no stale target")
	g._spawn_zombie_at("normal",2,395.0,true); agree(g,p,"New world with rebuilt index")
	g.free()

func corpses_and_survival() -> void:
	var g := make_game(Vector2(76,33)); g.zombies.clear()
	g._spawn_zombie_at("normal",2,395.0,true)
	g._spawn_zombie_at("normal",2,400.0,true)
	var p := shot_at(g,2,400)
	g._find_projectile_target(p)
	g.zombies[0].health=0.0
	check(g.legacy_find_projectile_target(p)==0,"Frozen baseline reproduces corpse consuming shots before cleanup")
	check(g._find_projectile_target(p)==1,"A corpse killed earlier in the same projectile update cannot consume the next shot")
	g.zombies[0].health=1.0; agree(g,p,"Resurrection is visible immediately")
	g.zombies[0].kind="flandre_boss"; g.zombies[0].health=0.0
	g.zombies[0].touhou_invulnerable=true; g.zombies[0].touhou_survival_timer=3.0
	agree(g,p,"Zero-HP visible endurance boss remains targetable")
	check(g._find_projectile_target(p)==0,"Endurance boss matches cleanup's preserved life semantics")
	g.zombies[0].touhou_survival_timer=0.0
	check(g._find_projectile_target(p)==1,"Expired zero-HP endurance boss is a corpse")
	g.zombies.clear(); g._spawn_zombie_at("normal",2,400.0,true)
	g.zombies[0].health=1.0
	var first := shot_at(g,2,393); first.merge({"kind":"pea","damage":1.0,"slow_duration":0.0,"color":Color.WHITE,"velocity_y":0.0})
	g.projectiles=[first.duplicate(true),first.duplicate(true)]
	g._update_projectiles(1.0/60.0)
	check(g.projectiles.size()==1,"Real native two-shot update retains the shot that would hit a freshly killed corpse")
	g.free()

func dynamic_bosses() -> void:
	var g := make_game(Vector2(135,110)); g.zombies.clear()
	var kinds: Array = g.TouhouDifficulty.boss_kinds()
	if not kinds.has("tewi_boss"): kinds.append("tewi_boss")
	for kind in kinds:
		g.zombies.clear(); var z: Dictionary = g.add_boss(String(kind))
		z.health=100000000.0
		for tick in range(4):
			z.x=500.0+float(tick)*61.0; z.row=tick%6; z.prismriver_time=float(tick)*1.7
			for point in g._zombie_hit_positions(z):
				var p := shot_at(g,z.row,point.x+2.0); p.free_aim=true; p.position.y=point.y
				agree(g,p,String(kind)+" live body positions")
				p.free_aim=false
				for row in range(6): p.row=row; agree(g,p,String(kind)+" strict lane/body parity")
		g.active_rows=[0,2,5]
		for point in g._zombie_hit_positions(z):
			var p := shot_at(g,z.row,point.x); p.free_aim=true; p.position.y=point.y
			agree(g,p,String(kind)+" active-lane bounds changes")
		g.active_rows=[0,1,2,3,4,5]
	g.free()

func boundary_and_extent() -> void:
	var g := make_game(Vector2(52,20)); g.zombies.clear()
	g._spawn_zombie_at("normal",2,400.0,true)
	for speed in [-460.0,460.0]:
		for offset in [-28.00003,-28.0,-27.99997,-20.00003,-20.0,-19.99997,19.99997,20.0,20.00003,27.99997,28.0,28.00003]:
			var p := shot_at(g,2,400.0+offset); p.speed=speed
			agree(g,p,"Strict endpoint boundary " + str(offset))
	var wide := shot_at(g,2,400.0); wide.radius=100000.0
	agree(g,wide,"Huge custom radius uses bounded fallback")
	g.zombies[0].x=400.000019
	var rounded := shot_at(g,2,380.0)
	agree(g,rounded,"Native Vector2 rounding at bin/boundary")
	g.free()

func live_camouflage() -> void:
	var g := make_game(Vector2(76,33)); g.zombies.clear()
	for row in g.grid:
		for col in range(row.size()): row[col]=null
	g._ensure_nitori_runtime()
	g._spawn_zombie_at("normal",2,650.0,true)
	var z: Dictionary = g.zombies[0]; z.nitori_camo=true
	var p := shot_at(g,2,650)
	agree(g,p,"Live Nitori camouflage")
	check(g._find_projectile_target(p)==-1,"Unrevealed camouflage preserves native target restriction")
	p.ignore_lane_hide=true; agree(g,p,"Special fog-ignoring projectile versus camouflage")
	p.ignore_lane_hide=false; z.revealed_timer=1.0
	agree(g,p,"Same-frame reveal timer")
	z.revealed_timer=0.0; g.grid[2][7]=g._create_plant("plantern",2,7)
	agree(g,p,"Same-frame revealing plant placement")
	check(g._find_projectile_target(p)==0,"Nearby live lantern makes cached geometry targetable")
	g.grid[2][7]=null; agree(g,p,"Same-frame revealer removal")
	g.free()

func native_updates() -> void:
	for dimensions in [Vector2(135,110),Vector2(76,33)]:
		var old := make_game(dimensions,true); var now := make_game(dimensions)
		for g in [old,now]:
			g.zombies[3].kind="kungfu"; g.zombies[3].reflect_timer=2.0
			g.zombies[4].kind="balloon_zombie"; g.zombies[4].balloon_flying=true
			g.zombies[5].digger_tunneling=true
			g.zombies[10].hypnotized=true
			var body: Dictionary = g.add_boss("prismriver_boss",3,6)
			body.health=100000000.0; body.prismriver_time=.7
		var template := shots(old).slice(0,120)
		for i in range(template.size()):
			var p: Dictionary = template[i]
			p.kind=["pea","heather_thorn","amber_pea","frost_boomerang","mist_bloom","pea"][i%6]
			p.ammo_elements=["milk","ice"] if i%2 else ["fire","dream"]
			p.anti_air=i%3==0; p.free_aim=i%5==0; p.ignore_lane_hide=i%7==0
			p.dot_damage=2.0; p.dot_duration=3.0; p.stun_duration=.2
			p.reveal_duration=2.0; p.pierce_left=2; p.hit_uids=[]
			p.anchor_x=old.BOARD_ORIGIN.x; p.outbound=true
			p.lane_center_y=p.position.y
			if i%4==0: p.speed=-460.0; p.position.x+=32.0
			if i%9==0: p.ash_radius=70.0; p.ash_damage=.1
		old.projectiles=template.duplicate(true); now.projectiles=template.duplicate(true)
		for delta in [1.0/60.0,.05,.1,.4,.8]:
			old._update_projectiles(delta); now._update_projectiles(delta)
			check(old.projectiles==now.projectiles,"Native tracks retain identical positions, mirror returns and piercing exclusions")
			check(old.zombies==now.zombies,"Native hit/armor/DOT/milk/dream/bodies are identical after each update")
			check(old.effects==now.effects and old.vfx_particles==now.vfx_particles,"Native hits retain exact visual output")
		old.free(); now.free()

func _run() -> void:
	alive_parity(); same_frame_mutations(); corpses_and_survival(); dynamic_bosses(); boundary_and_extent(); live_camouflage(); native_updates()
	print("Plant target exact semantics: ",comparisons," brute-force comparisons; ",failures," failure(s)")
	quit(1 if failures else 0)
