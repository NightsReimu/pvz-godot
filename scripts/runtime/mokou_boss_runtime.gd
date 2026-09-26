extends RefCounted

const Visuals = preload("res://scripts/runtime/mokou_visuals.gd")
var game: Control
var marks: Array[Dictionary] = []
var rallies: Array[Dictionary] = []
var serial := 0

func _init(owner: Control) -> void:
	game = owner

func reset() -> void:
	marks.clear()
	rallies.clear()
	serial = 0

func clear_owner(owner: int) -> void:
	marks = marks.filter(func(m): return int(m.owner) != owner)
	rallies = rallies.filter(func(r): return int(r.owner) != owner)

func extinguish_all() -> void:
	marks = marks.filter(func(m): return m.kind == "archive")
	rallies.clear()

func plant_stilled(row: int, col: int) -> bool:
	return marks.any(func(m): return m.kind == "archive" and m.cell == Vector2i(row,col) and float(m.age)>=float(m.delay) and float(m.age)<float(m.delay)+3.0)

func mark(boss: Dictionary, cell: Vector2i, kind: String, delay: float = 1.8) -> void:
	if marks.size() >= 24: return
	var damage = 30.0 * game.TouhouDifficulty.attack_damage(String(boss.kind),game.current_level,int(boss.boss_phase))
	marks.append({"owner":int(boss.uid),"cell":cell,"kind":kind,"age":0.0,"delay":delay,"tick":0.0,"damage":damage})

func rally(boss: Dictionary, row: int, side: int = 0) -> void:
	if rallies.size() >= 2: return
	if side == 0: side = -1 if game.rng.randf()<0.5 else 1
	var a: Vector2 = game._cell_center(row,0) + Vector2(0,-12)
	a.x = game.BOARD_ORIGIN.x + (12 if side<0 else game.board_size.x-12)
	var b = Vector2(game.BOARD_ORIGIN.x + (game.board_size.x-12 if side<0 else 12),a.y)
	rallies.append({"owner":int(boss.uid),"position":a,"from":a,"to":b,"age":0.0,"warning":1.6,"leg":0,"hits":[],"trail":[],"speed":game.board_size.x/2.4,"damage":68.0*game.TouhouDifficulty.attack_damage("mokou_boss",game.current_level,int(boss.boss_phase)),"side":side})

func cast(boss: Dictionary, pattern: String) -> void:
	clear_owner(int(boss.uid))
	serial += 1
	var rank = int(game.TouhouDifficulty.profile(game.current_level).rank)
	match pattern:
		"mokou_pingpong", "mokou_double_rally":
			var row = int(game.active_rows[game.rng.randi_range(0,game.active_rows.size()-1)])
			rally(boss,row)
			if pattern == "mokou_double_rally":
				rally(boss,int(game.active_rows[(row+3)%game.active_rows.size()]),-int(rallies[0].side))
			game._show_banner("烈焰乒乓 · 红线预告球路，冰弹熄火，镜芦苇反击",2.8)
		"mokou_embers", "hakutaku_archive", "mokou_fujiyama", "mokou_rebirth":
			var targets: Array[Vector2i] = []
			for row in game.active_rows:
				for col in range(game.COLS):
					if game._targetable_plant_at(row,col) != null: targets.append(Vector2i(row,col))
			if targets.is_empty(): targets.append(Vector2i(2,3))
			if pattern == "mokou_rebirth":
				var center: Vector2i = targets[posmod(serial,targets.size())]
				for row in range(maxi(0,center.x-1),mini(game.board_rows,center.x+2)):
					for col in range(maxi(0,center.y-1),mini(game.COLS,center.y+2)):
						if Vector2i(row,col) != center: mark(boss,Vector2i(row,col),"rebirth",2.2)
				game._show_banner("涅槃火圈 · 外圈将燃烧，中心格安全；冰系可扑灭",2.5)
			else:
				for n in range(mini(3+rank/2,targets.size())):
					var index = posmod(serial*5,targets.size())
					mark(boss,targets[index],"archive" if pattern == "hakutaku_archive" else "ember",2.0)
					targets.remove_at(index)
				if pattern == "hakutaku_archive": game._show_banner("编年封印 · 两秒后标记格停长三秒",2.4)
				else: game._show_banner("余烬将落 · 冰系攻击或寒冰菇可扑灭灼烧格",2.4)

func _ice_on_segment(a: Vector2, b: Vector2, radius: float, delta: float) -> bool:
	for p in game.projectiles:
		if float(p.get("slow_duration",0))<=0 or p.get("fire",false) or p.get("reflected",false): continue
		var start = Vector2(p.position)
		var direction = -1 if p.get("outbound",true) == false else 1
		var end = start + Vector2(float(p.get("speed",0))*direction,float(p.get("velocity_y",0)))*delta
		var point = Geometry2D.get_closest_point_to_segment(start,a,b)
		if point.distance_to(start)<=radius or Geometry2D.segment_intersects_segment(start,end,a,b)!=null or Geometry2D.get_closest_point_to_segment(b,start,end).distance_to(b)<=radius:
			return true
	return false

func update(delta: float) -> void:
	if game.boss_time_stop_timer>0 or game.battle_paused: return
	var owners = {}
	for boss in game.zombies:
		if String(boss.kind) in ["hakutaku_boss","mokou_boss"] and float(boss.health)>0: owners[int(boss.uid)] = boss
	for index in range(marks.size()-1,-1,-1):
		var m = marks[index]
		m.age += delta
		var center: Vector2 = game._cell_center(m.cell.x,m.cell.y)
		if not owners.has(int(m.owner)) or float(m.age)>float(m.delay)+(3 if m.kind=="archive" else 6) or (m.kind!="archive" and _ice_on_segment(center-Vector2(game.CELL_SIZE.x*0.38,0),center+Vector2(game.CELL_SIZE.x*0.38,0),game.CELL_SIZE.y*0.5,delta)):
			marks.remove_at(index)
			continue
		if m.kind=="archive" or float(m.age)<float(m.delay): continue
		m.tick -= delta
		if float(m.tick)<=0:
			m.tick = 0.9
			game._damage_plant_cell(m.cell.x,m.cell.y,float(m.damage),0.0)
	for index in range(rallies.size()-1,-1,-1):
		var r = rallies[index]
		r.age += delta
		if not owners.has(int(r.owner)) or float(r.age)>12 or int(r.leg)>=4:
			rallies.remove_at(index)
			continue
		var dt = delta
		if float(r.warning)>0:
			var wait_time = minf(dt,float(r.warning))
			r.warning -= wait_time
			dt -= wait_time
			if dt<=0: continue
		var before = Vector2(r.position)
		r.position = before.move_toward(Vector2(r.to),float(r.speed)*dt)
		if _ice_on_segment(before,Vector2(r.position),game.CELL_SIZE.y*0.20,delta):
			rallies.remove_at(index)
			continue
		var mirror: Vector2i = game._mirror_reed_on_segment(before,Vector2(r.position),game.CELL_SIZE.y*0.10)
		if mirror.y>=0:
			# Reuse reflection cooldown and shield rules, then send a real reflected ball.
			var b = {"owner":int(owners[int(r.owner)].get("touhou_owner",0)),"kind":"mokou_boss","position":Vector2(r.position),"velocity":(Vector2(r.to)-Vector2(r.from)).normalized()*float(r.speed),"damage":float(r.damage),"radius":8.0*game._battle_unit_scale(),"color":Color("ffb564"),"shape":"orb","age":0.0,"life":6.0}
			if game._bounce_boss_danmaku(b,mirror):
				game._ensure_touhou_danmaku().bullets.append(b)
				rallies.remove_at(index)
				continue
		game._ensure_touhou_danmaku()._hit_plant_segment(before,Vector2(r.position),game.CELL_SIZE.y*0.10,float(r.damage),r.hits,false)
		r.trail.append(before)
		if r.trail.size()>10: r.trail.pop_front()
		if Vector2(r.position).distance_to(Vector2(r.to))<0.1:
			r.leg += 1
			r.from = Vector2(r.to)
			r.to = Vector2(game.BOARD_ORIGIN.x+(12 if float(r.from.x)>game.BOARD_ORIGIN.x+game.board_size.x/2 else game.board_size.x-12),game._cell_center(int(game.active_rows[game.rng.randi_range(0,game.active_rows.size()-1)]),0).y-12)
			r.warning = 0.95
			r.hits = []
			r.trail.clear()

func frame_index(boss: Dictionary) -> int:
	var pose = String(boss.get("rumia_state","idle"))
	var age = float(boss.get("animation_time",game.level_time))
	if float(boss.get("health",1))<=0: return 21
	if float(boss.get("flash",0))>0.12 and float(boss.get("touhou_cast_remaining",0))<=0: return [12,13,14][posmod(int(age*6),3)]
	var frames: Array = {"idle":[0,1,2,1],"shift":[3,4,5,4],"shot":[6,7,8,7],"special":[9,10,11,10],"phase":[15,16,17,16],"final":[18,19,20,23,20,19]}.get(pose,[0,1,2,1])
	return frames[posmod(int(age*6),frames.size())]

func draw_boss(center: Vector2,boss: Dictionary) -> void:
	var kind = String(boss.kind)
	var texture: Texture2D = game._try_get_boss_frame_texture(kind,frame_index(boss))
	if texture == null: return
	var scale: float = game._touhou_boss_draw_scale(kind)
	var extent: Vector2 = texture.get_size()*scale
	var anchor = 162.0 if kind=="hakutaku_boss" else 124.5
	game.draw_texture_rect(texture,Rect2(center+Vector2(-anchor*scale,game.TouhouSpriteDefs.top_offset(kind)),extent),false)

func draw_ground() -> void:
	Visuals.ground(self)

func draw_overlay() -> void:
	Visuals.overlay(self)
