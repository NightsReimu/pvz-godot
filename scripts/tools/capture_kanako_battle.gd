extends "res://scripts/tools/capture_battle_polish.gd"
# Native rendered snapshots of 4-24 (run without --headless):
# godot --path . -s res://scripts/tools/capture_kanako_battle.gd
const Phase = preload("res://scripts/runtime/touhou_phase_runtime.gd")
const Fusion = preload("res://scripts/data/fusion_plant_defs.gd")
const DIRECTORY := "res://output/kanako-4-24/visual"
var failures := 0

class PortraitGallery extends GameScript:
	func _ready() -> void: _build_font(); set_process(false)
	func _save_game() -> void: pass
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO,size),Color("e9dfcf"))
		draw_string(ui_font,Vector2(24,35),"守矢神社 · 八坂神奈子与御柱",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("4a2f35"))
		var scale: float=1.8 if size.y>600 else 0.75
		_draw_zombie_icon("kanako_boss",Vector2(size.x*.3,size.y*.72),scale)
		_draw_zombie_icon("kanako_onbashira",Vector2(size.x*.7,size.y*.72),scale)

func check(ok: bool,message: String) -> void:
	if not ok: failures+=1; push_error(message)

func _stage() -> Dictionary:
	for level in GameScript.Defs.LEVELS:
		if String(level.id)=="4-24": return level.duplicate(true)
	return {}

func _select(b: Dictionary,id: String) -> bool:
	var e: Dictionary=b.touhou_encounter
	for pi in range(e.phases.size()):
		for ai in range(e.phases[pi].size()):
			if String(e.phases[pi][ai][0])==id:
				e.index=pi; e.attack=ai; e.completed=ai; e.complete=false; e.depleted=false; Phase._set_bounds(b); b.health=e.ceiling
				return true
	return false

func _shot(g: Control,surface: SubViewport,label: String) -> void:
	g.banner_label.hide(); g.toast_label.hide(); g.queue_redraw()
	await process_frame; await RenderingServer.frame_post_draw
	check(surface.get_texture().get_image().save_png(DIRECTORY+"/%dx%d-%s.png" % [surface.size.x,surface.size.y,label])==OK,"Native "+label+" screenshot saves")

func _step(g: Control,seconds: float) -> void:
	for frame in range(ceili(seconds/0.05)):
		g.level_time+=0.05; g.ui_time+=0.05; g._update_zombies(0.05)
		if g.touhou_danmaku!=null: g.touhou_danmaku.update(0.05)
		g._ensure_kanako_runtime().update(0.05); g._update_effects(0.05)
		if g.ancient_expansion!=null: g.ancient_expansion.update_world(0.05)

func _card(g: Control,surface: SubViewport,b: Dictionary,id: String,label: String,times: Array) -> void:
	g._ensure_kanako_runtime().clear_owner(int(b.uid))
	if b.has("touhou_owner"): g.touhou_danmaku.clear_owner(int(b.touhou_owner))
	b.touhou_cast_remaining=0.0; b.touhou_invulnerable=false
	check(_select(b,id),"Card is reachable: "+id)
	g._trigger_boss_skill(b)
	var elapsed:=0.0
	for t in times:
		_step(g,float(t)-elapsed); elapsed=float(t)
		await _shot(g,surface,"%s-%.1fs" % [label,elapsed])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	check(not _stage().is_empty(),"Native capture requires the registered Kanako stage")
	if failures: quit(1); return
	var only := OS.get_environment("KANAKO_CAPTURE")
	for viewport in [Vector2i(1600,900),Vector2i(844,390)]:
		var surface:=SubViewport.new(); surface.size=viewport; surface.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(surface)
		var portrait:=PortraitGallery.new(); portrait.size=Vector2(viewport); surface.add_child(portrait)
		portrait._queue_boss_frame_set_prewarm("kanako_boss"); portrait._drain_asset_prewarm_queue(); portrait.queue_redraw()
		await process_frame; await RenderingServer.frame_post_draw
		check(surface.get_texture().get_image().save_png(DIRECTORY+"/%dx%d-portraits.png" % [viewport.x,viewport.y])==OK,"Native portrait snapshot saves")
		portrait.free(); await process_frame
		for tier in (["normal","lunatic"] if only.is_empty() else [only]):
			var g:=PreviewGame.new(); g.size=Vector2(viewport); g.mobile_runtime_override=1 if viewport.y<600 else 0; surface.add_child(g); g.rng.seed=424
			g._begin_level(-1,["sunflower","repeater","wallnut","healing_gourd","melon_pult","umbrella_leaf","torchwood","cherry_bomb","plantern","cactus"],g.TouhouDifficulty.build_level(_stage(),tier))
			g.battle_intro_timer=0; g.level_time=80; g.startup_loading_active=false; g.page_transition_active=false; g.selected_tool=""
			for row in range(6):
				g.grid[row][0]=g._create_plant("healing_gourd" if row%2 else "wallnut",row,0)
				g.grid[row][1]=g._create_plant(Fusion.result("repeater","wallnut") if row%2 else "repeater",row,1)
				g.grid[row][2]=g._create_plant("umbrella_leaf" if row==1 else ("torchwood" if row==4 else "melon_pult"),row,2)
				g.grid[row][3]=g._create_plant(Fusion.result("repeater","torchwood") if row==3 else "repeater",row,3)
				for col in range(4): g.grid[row][col].spawn_time=0; g.grid[row][col].sleep_timer=0
				var visitor: String=["farmer","cone_qinghua","kabuto_spear","wizard_zombie","bucket_kedama","ancient_mage"][row]
				g._spawn_zombie_at(visitor,row,g._cell_center(row,6).x,true)
				g.zombies.back().spawn_time=0
			g._drain_asset_prewarm_queue(); g._try_play_pending_bgm()
			if tier=="normal": await _shot(g,surface,"road")
			g.level_time=200; g._spawn_zombie_at("kanako_boss",2,g._boss_anchor_x("kanako_boss"),true)
			var b: Dictionary=g._find_alive_enemy_boss("kanako_boss"); g._drain_asset_prewarm_queue(); g._try_play_pending_bgm()
			_step(g,0.3); await _shot(g,surface,tier+"-arrival")
			var r:=int(g.TouhouDifficulty.profile(g.current_level).rank)
			await _card(g,surface,b,"th10-kanako-twin-nonspell",tier+"-twin-nonspell",[1.6])
			await _card(g,surface,b,"th10-%03d"%(78+r),tier+"-onbashira",[0.7,1.25,2.6])
			await _card(g,surface,b,"original-kanako-pillar-fall",tier+"-pillar-fall",[1.0,2.2,4.0])
			await _card(g,surface,b,"th10-%03d"%(82+r),tier+"-porridge",[1.4,3.0])
			await _card(g,surface,b,"original-kanako-shimenawa",tier+"-shimenawa",[1.0,2.6])
			await _card(g,surface,b,"th10-%03d"%(86+r),tier+"-misayama",[1.6,3.2])
			await _card(g,surface,b,"original-kanako-weather",tier+"-weather",[2.0,7.5])
			if r>=1: await _card(g,surface,b,"original-kanako-war-god",tier+"-war-god",[2.0])
			await _card(g,surface,b,"th10-%03d"%(90+r),tier+"-otensui",[2.5,4.0])
			if r>=2: await _card(g,surface,b,"original-kanako-serpent",tier+"-serpent",[3.0,5.0])
			if r>=3: await _card(g,surface,b,"original-kanako-faith",tier+"-faith",[2.0,4.0])
			await _card(g,surface,b,"th10-%03d"%(94+r),tier+"-last-spell",[1.5,6.0,10.0])
			for frame in range(24): check(g._try_get_boss_frame_texture("kanako_boss",frame)!=null,"Every supplied native pose loads %d" % frame)
			g._ensure_kanako_runtime().reset(); g._stop_bgm(); g.music_player.stream=null
			for player in g.sfx_players: player.stop(); player.stream=null
			g.save_dirty=false; g.free(); await process_frame
		await create_timer(0.35).timeout; surface.free(); await create_timer(0.35).timeout; await process_frame
	print("Native Kanako desktop/mobile captures: %d failure(s)" % failures)
	call_deferred("quit",1 if failures else 0)
