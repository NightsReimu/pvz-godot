extends "res://scripts/tools/capture_battle_polish.gd"
const Phase = preload("res://scripts/runtime/touhou_phase_runtime.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const DIRECTORY := "res://output/tengu-4-22/tests/visual"
var failures := 0

class PortraitGallery extends GameScript:
	func _ready() -> void: _build_font(); set_process(false)
	func _save_game() -> void: pass
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("ddd8bd"))
		draw_string(ui_font,Vector2(24,35),"九天瀑布 · 白狼哨戒与疾风天狗",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("3b5146"))
		var scale: float=1.8 if size.y>600 else 0.75
		_draw_zombie_icon("momiji_boss",Vector2(size.x*.28,size.y*.72),scale)
		_draw_zombie_icon("aya_boss",Vector2(size.x*.72,size.y*.72),scale)
		draw_string(ui_font,Vector2(size.x*.24,size.y*.90),"犬走椛",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("3b5146"))
		draw_string(ui_font,Vector2(size.x*.67,size.y*.90),"射命丸文",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("3b5146"))

func check(ok: bool,message: String) -> void:
	if not ok: failures+=1; push_error(message)

func _stage() -> Dictionary:
	for level in GameScript.Defs.LEVELS:
		if String(level.id)=="4-22": return level.duplicate(true)
	return {}

func _select(g: Control,b: Dictionary,id: String) -> bool:
	var e: Dictionary=b.touhou_encounter
	for pi in range(e.phases.size()):
		for ai in range(e.phases[pi].size()):
			if String(e.phases[pi][ai][0])==id:
				e.index=pi; e.attack=ai; e.completed=ai; e.complete=false; e.depleted=false; Phase._set_bounds(b); b.health=e.ceiling
				return true
	return false

func _shot(g: Control,surface: SubViewport,label: String) -> void:
	g.banner_label.hide(); g.toast_label.hide(); g.queue_redraw()
	var before: int=g.rng.state
	await process_frame; await RenderingServer.frame_post_draw
	check(before==g.rng.state,"Drawing a native Tengu snapshot cannot consume combat RNG")
	check(surface.get_texture().get_image().save_png(DIRECTORY+"/%dx%d-%s.png" % [surface.size.x,surface.size.y,label])==OK,"Native "+label+" screenshot saves")

func _step(g: Control,seconds: float) -> void:
	for frame in range(ceili(seconds/0.05)):
		g.level_time+=0.05; g._update_zombies(0.05)
		if g.touhou_danmaku!=null: g.touhou_danmaku.update(0.05)
		g._ensure_tengu_runtime().update(0.05); g._update_effects(0.05)

func _new_flight_and_cyclone(g: Control,surface: SubViewport,aya: Dictionary) -> void:
	var rt=g._ensure_tengu_runtime(); rt.clear_owner(int(aya.uid)); g.touhou_danmaku.clear_owner(int(aya.touhou_owner))
	aya.touhou_cast_remaining=0.0; aya.touhou_survival_timer=0.0; aya.touhou_invulnerable=false
	aya.touhou_encounter.casting=false
	aya.boss_cast_pending=false; aya.boss_skill_timer=1000.0; aya.boss_pause_timer=0.0; aya.rumia_state="idle"; aya.rumia_state_timer=0.0
	var left:=false; var right:=false
	for frame in range(600):
		_step(g,0.05)
		check(float(aya.touhou_cast_remaining)==0.0 and not bool(aya.touhou_invulnerable),"Native idle-flight capture cannot silently restart a survival attack")
		var uv: Vector2=rt._body_uv(aya)
		if not left and uv.x<=1.6:
			await _shot(g,surface,"aya-left-board-flight"); left=true
		if left and not right and uv.x>=8.4:
			await _shot(g,surface,"aya-right-board-flight"); right=true
		if left and right: break
	check(left and right,"Actual native between-cast Aya flight reaches both col 1 and col 8 in the rendered board")
	rt.clear_owner(int(aya.uid)); g.projectiles.clear()
	g.grid[3][3]=g._create_plant(Fusion.result("peashooter","wallnut"),3,3)
	rt.queue_field(int(aya.uid),Vector2i(3,4),"cyclone",1.2)
	_step(g,0.65); await _shot(g,surface,"cyclone-capture-warning")
	var observed: Array=[]; var captured:=false
	for frame in range(160):
		_step(g,0.05); g._update_plants(0.05)
		for shot in g.projectiles:
			if shot.has("fusion_source") and not observed.any(func(p): return is_same(p,shot)): observed.append(shot)
		g._update_projectiles(0.05)
		if observed.any(func(shot): return bool(shot.get("tengu_captured",false))):
			captured=true; break
	check(captured and rt.fields.any(func(field): return String(field.mode)=="cyclone" and not field.get("orbit_tokens",[]).is_empty()),"A real fused native shot is swallowed before impact and creates visible orbit debris")
	await _shot(g,surface,"cyclone-captured-native-fusion-shot")
	print(JSON.stringify({"viewport":surface.size,"rendered_aya_left":left,"rendered_aya_right":right,"captured_native_fusion":captured,"orbit_tokens":rt.fields.reduce(func(total,field): return total+field.get("orbit_tokens",[]).size(),0)}))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	check(not _stage().is_empty(),"Native capture requires the real registered Tengu stage")
	if failures: quit(1); return
	for viewport in [Vector2i(1600,900),Vector2i(844,390)]:
		var surface:=SubViewport.new(); surface.size=viewport; surface.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(surface)
		var portrait:=PortraitGallery.new(); portrait.size=Vector2(viewport); surface.add_child(portrait)
		portrait._queue_boss_frame_set_prewarm("momiji_boss"); portrait._queue_boss_frame_set_prewarm("aya_boss"); portrait._drain_asset_prewarm_queue(); portrait.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		check(surface.get_texture().get_image().save_png(DIRECTORY+"/%dx%d-portraits.png" % [viewport.x,viewport.y])==OK,"Native portrait snapshot saves")
		portrait.free(); await process_frame
		var g:=PreviewGame.new(); g.size=Vector2(viewport); g.mobile_runtime_override=1 if viewport.y<600 else 0; surface.add_child(g); g.rng.seed=422
		g._begin_level(-1,["repeater","wallnut","lily_pad","sea_shroom","plantern","umbrella_leaf","healing_gourd","mirror_reed"],g.TouhouDifficulty.build_level(_stage(),"normal"))
		g.battle_intro_timer=0; g.level_time=80; g.startup_loading_active=false; g.page_transition_active=false; g.selected_tool=""
		for row in range(6):
			g.grid[row][1]=g._create_plant(Fusion.result("repeater","wallnut") if row%2 else "repeater",row,1)
			g.grid[row][2]=g._create_plant("umbrella_leaf" if row==1 else ("plantern" if row==4 else "healing_gourd"),row,2)
			for col in [1,2]: g.grid[row][col].spawn_time=0; g.grid[row][col].sleep_timer=0
			g._spawn_zombie_at("bucket_snorkel" if row%2 else "cone_star_fairy",row,g._cell_center(row,7).x,true)
			g.zombies.back().spawn_time=0
		g._drain_asset_prewarm_queue(); g._try_play_pending_bgm()
		await _shot(g,surface,"water-road")
		g.level_time=120; g._update_frozen_branch_flow()
		var momiji: Dictionary=g._find_alive_enemy_boss("momiji_boss")
		check(not momiji.is_empty(),"Real forty-percent flow spawns visible Momiji")
		check(_select(g,momiji,"original-momiji-sentinel"),"Momiji supplied guard pose is reachable")
		g._trigger_boss_skill(momiji); _step(g,0.65); await _shot(g,surface,"momiji-warning")
		_step(g,1.0); await _shot(g,surface,"momiji-guard")
		g._ensure_tengu_runtime().clear_owner(int(momiji.uid)); g.touhou_danmaku.clear_owner(int(momiji.touhou_owner)); momiji.touhou_encounter.complete=true; momiji.health=0; g._cleanup_dead_zombies(); g._update_frozen_branch_flow()
		g.level_time=300; g._spawn_zombie_at("aya_boss",2,g._boss_anchor_x("aya_boss"),true)
		var aya: Dictionary=g._find_alive_enemy_boss("aya_boss"); g._drain_asset_prewarm_queue(); g._try_play_pending_bgm()
		check(g.water_rows.is_empty() and g.current_level.terrain=="tengu_mountainside","Native Aya arrival turns every road row into land")
		await _shot(g,surface,"land-arrival")
		_step(g,2.65); await _shot(g,surface,"settled-mountainside")
		check(_select(g,aya,"th10-044"),"Normal branch card is reachable")
		g._trigger_boss_skill(aya); _step(g,1.36); await _shot(g,surface,"aya-live-dash")
		g._ensure_tengu_runtime().clear_owner(int(aya.uid)); g.touhou_danmaku.clear_owner(int(aya.touhou_owner))
		check(_select(g,aya,"original-aya-report"),"The PvZ photo card is reachable")
		g._trigger_boss_skill(aya); _step(g,0.6); await _shot(g,surface,"photo-warning")
		_step(g,0.95); await _shot(g,surface,"photo-followup")
		g._ensure_tengu_runtime().clear_owner(int(aya.uid)); g.touhou_danmaku.clear_owner(int(aya.touhou_owner))
		check(_select(g,aya,"th10-051"),"Normal canonical timed survival is reachable")
		g._trigger_boss_skill(aya); _step(g,3.0); await _shot(g,surface,"fantasy-storm-survival")
		g._ensure_tengu_runtime().clear_owner(int(aya.uid)); g.touhou_danmaku.clear_owner(int(aya.touhou_owner))
		g._ensure_tengu_runtime().queue_dash(int(aya.uid),Vector2i(0,5),1.2,0.36)
		_step(g,1.6); await _shot(g,surface,"top-row-dash-and-trail")
		await _new_flight_and_cyclone(g,surface,aya)
		for kind in ["momiji_boss","aya_boss"]:
			for frame in range(24): check(g._try_get_boss_frame_texture(kind,frame)!=null,"Every supplied native pose loads "+kind+" "+str(frame))
		g._stop_bgm(); g.music_player.stream=null
		for player in g.sfx_players: player.stop(); player.stream=null
		g.save_dirty=false; await create_timer(0.35).timeout; surface.free(); await create_timer(0.35).timeout; await process_frame
	print("Native Tengu desktop/mobile road, patrol, terrain, warning, dash and survival captures: %d failure(s)" % failures)
	call_deferred("quit",1 if failures else 0)
