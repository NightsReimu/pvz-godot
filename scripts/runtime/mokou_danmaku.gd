extends RefCounted

const RED = Color("fa6173")
const BLUE = Color("80d8ff")
const GOLD = Color("ffc56c")
const GREEN = Color("b3eb8d")

# EX's geometric signatures are rotated onto the horizontal six-lane board.
static func emit(dm: RefCounted, c: Dictionary) -> void:
	var g: Control = dm.game
	var s = minf(g.CELL_SIZE.x / 100.0, g.CELL_SIZE.y / 110.0)
	var o = Vector2(c.center)
	var w = int(c.wave)
	var aim: float = (dm._target(o) - o).angle()
	var e = {"damage": 28.0, "radius": 5*s, "arming_time": 0.7, "life": 6.0}
	match String(c.pattern):
		"hakutaku_old", "hakutaku_next":
			var next = c.pattern == "hakutaku_next"
			for side in [-1, 1]:
				var point: Vector2 = dm._point(0.87, 0.5 + side*0.34)
				dm._fan(c, point, 11 if next else 9, PI + side*(0.38 + sin(w*0.5)*0.24), 1.3, (150 if next else 125)*s, RED if side < 0 else GREEN, "rice", e)
			dm._fan(c, o, 3, aim + (0.18*sin(w) if next else 0), 0.24, 185*s, BLUE, "ofuda", e)
		"hakutaku_bridge":
			for side in [-1, 1]:
				for arm in range(4):
					var point: Vector2 = dm._point(0.65, 0.5 + side*0.32)
					dm._fan(c, point, 3, arm*TAU/4 + side*w*0.25, 0.14, 132*s, RED if side<0 else BLUE, "rice", e)
			if w % 2 == 0:
				dm._fan(c, dm._point(0.94, 0.92), 5, PI+0.3, 0.6, 160*s, GREEN, "ofuda", e)
		"hakutaku_archive":
			dm._fan(c, o, 9, aim, 1.5, 130*s, GREEN, "ofuda", e)
		"nonspell_mokou":
			dm._fan(c, o, 9, aim + sin(w*0.5)*0.25, 1.7, 170*s, RED, "rice", e)
		"mokou_iwakasa":
			dm._ring(c, o, 16, w*0.23, 115*s, GREEN, "rice", e)
			var redirect = e.duplicate()
			redirect.merge({"redirect_at": 0.95, "aim_point": dm._target(o), "mokou_turn": true})
			for arm in range(4):
				dm._fan(c, o, 3, arm*TAU/4-w*0.3, 0.12, 175*s, BLUE, "knife", redirect)
		"mokou_firebird":
			# Symmetric chevrons form a bird; the third volley opens seven wings.
			for wing in [-1, 1]:
				for feather in range(7 if w%3 == 2 else 5):
					var point = o + Vector2(-feather*16, wing*feather*13)*s
					dm._fan(c, point, 3, aim + wing*feather*0.08, 0.12, (205-feather*14)*s, GOLD if feather%2 else RED, "rice", e)
		"mokou_temple":
			var bounce = e.duplicate()
			bounce.merge({"bounces": 1, "temple_bounce": true})
			for side in [-1, 1]:
				var point: Vector2 = dm._point(0.72 + sin(w*0.65)*0.15, 0.5+side*0.3)
				dm._fan(c, point, 9, PI+side*0.95, 0.6, 200*s, BLUE, "ofuda", bounce)
		"mokou_xufu":
			# Two opposed rectangular spirals; every fourth segment is an opening.
			for side in [-1, 1]:
				for n in range(12):
					if (n+w)%4 == 0: continue
					var angle = n*TAU/12 + side*w*0.18
					var v = Vector2.from_angle(angle)
					var point = dm._point(0.63, 0.5) + v/maxf(absf(v.x),absf(v.y))*60*s
					dm._bullet(c, point, angle, 110*s, RED if side<0 else BLUE, "rice", {"damage": 25, "radius": 5*s, "angular_speed": side*0.48, "life": 3.1, "arming_time": 0.8})
			dm._fan(c, o, 3, aim, 0.3, 200*s, GOLD, "rice", e)
		"mokou_honest":
			for n in range(4):
				var point: Vector2 = dm._point(0.8, 0.14+n*0.24)
				dm._fan(c, point, 3, PI+sin(w*0.7+n)*0.5, 0.2, 140*s, BLUE, "rice", e)
			if w%3 == 0:
				var side = 1 if w%2 else -1
				dm._beam(c, dm._point(0.97,0.5+side*0.42), dm._point(0.04,0.5-side*0.15), RED, 1.7, 11*s, {"damage": 95, "duration": 0.48})
			dm._fan(c,o,3,aim,0.22,195*s,RED,"rice",e)
		"mokou_wu":
			var point: Vector2 = dm._point(0.5+cos(w*1.1)*0.32,0.5+sin(w*1.1)*0.36)
			var delayed = e.duplicate()
			delayed.merge({"freeze_at": 0.0, "thaw_at": 0.75, "arming_time": 0.9, "mokou_accelerate": true})
			dm._ring(c,point,13,w*2.399,75*s,Color("bc9ced"),"rice",delayed)
		"mokou_tail":
			for n in range(10):
				var point: Vector2 = dm._point(0.78,0.06+n*0.095)
				dm._fan(c,point,3,PI+sin(w*0.32+n*0.38)*0.4,0.32,120*s,RED if n%2 else GOLD,"rice",e)
			if w%2 == 0: dm._fan(c,o,3,aim,0.5,195*s,GOLD,"orb",e)
		"mokou_fujiyama":
			dm._ring(c,o,24,w*0.15,130*s,RED,"rice",e)
			dm._fan(c,o,3,aim,0.35,255*s,GOLD,"orb",e)
		"mokou_possessed":
			var act = mini(3,int(float(c.age)/4))
			if act in [0,3]: dm._ring(c,dm._point(0.72,0.5),20,w*0.37,130*s,Color("c5a4f1"),"rice",e)
			if act in [1,3]: dm._fan(c,o,5,aim,0.6,255*s,BLUE,"rice",e)
			if act in [2,3] and w%2 == 0:
				var target: Vector2 = dm._target(o)
				dm._ring(c,target,18,w*0.2,100*s,GOLD,"rice",{"arming_time":1.4,"freeze_at":0.0,"thaw_at":1.3,"damage":26,"radius":5*s})
		"mokou_hourai":
			for side in [-1,1]:
				var point: Vector2 = dm._point(0.65,0.5)+Vector2.from_angle(side*w*0.35)*maxf(22,125-w*5)*s
				dm._ring(c,point,12,side*w*0.2,108*s,RED if side<0 else BLUE,"rice",{"angular_speed":side*0.65,"damage":25,"radius":5*s,"arming_time":0.8,"life":4.5})
			if w>7: dm._fan(c,o,7,aim,1.5,190*s,GOLD,"orb",e)
		"mokou_imperishable":
			var act = mini(8,int(float(c.age)/2))
			var point: Vector2 = dm._point(0.7,0.5)
			if act%3 == 2: point = dm._point(0.65,0.22 if w%2 else 0.78)
			dm._ring(c,point,20+act*2,w*0.27,155*s,[RED,BLUE,GOLD][act%3],"rice",{"imperishable":true,"damage":27,"radius":5*s,"arming_time":1.35,"life":6.0})
		"mokou_pingpong", "mokou_double_rally", "mokou_embers", "mokou_rebirth":
			if w%2 == 0: dm._fan(c,o,5,aim,1.5,115*s,GOLD,"rice",e)

static func advance_bullet(b: Dictionary, delta: float) -> void:
	if bool(b.get("reflected",false)): return
	if b.get("mokou_turn",false) and b.get("redirected",false): b.color = RED
	if b.get("temple_bounce",false) and int(b.get("bounces",1)) == 0: b.color = Color("cb8feb")
	if b.get("mokou_accelerate",false) and float(b.age)>0.75:
		b.velocity *= 1.0+delta*0.6
	if b.get("imperishable",false):
		if float(b.age)>=0.55 and not b.get("contracted",false):
			b.velocity *= -0.72
			b.contracted = true
		if float(b.age)>=1.25 and not b.get("released",false):
			b.velocity = Vector2(b.velocity).rotated(0.27)*-2.0
			b.released = true
