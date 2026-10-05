extends RefCounted
# Expressions, barrel modifications and elemental auras of a hybrid.
const INK := "#283e35"

# Strongest expression wins when several partners lend one.
const MOOD_ORDER := ["hypno","fierce","angry","frosty","spark","manic","cool","sleepy","stern","happy","worried","calm"]
const ELEMENT_ORDER := ["fire","frost","shock","poison","dream","shadow","blast","sun","water","wind","light","holy","heal","metal","time","tea","milk","sweet","bloom","butter","bite","smoke","earth"]
# Leaves of a hybrid turn with its strongest element.
const LEAF_TINTS := {
	"fire":["#c9c062","#7c6a2e"], "frost":["#a6dccb","#3f7c7c"], "shadow":["#9aa88a","#4c4f6d"], "sun":["#bfd666","#5a8a3a"],
	"poison":["#b1d955","#4f7a2c"], "dream":["#a9bf95","#5c5f7e"], "shock":["#a4d48a","#3c7a63"], "water":["#94cfa8","#2f7a6a"],
}

static func _f(v: float) -> String:
	return "%.1f" % v


static func mood(eyes: Array, frontal: bool, kind: String, skin: String) -> String:
	if eyes.is_empty() or kind in ["calm",""]: return ""
	var cx := 0.0
	for e in eyes: cx += float(e[0])
	cx /= eyes.size()
	var out := ""
	for e in eyes:
		var x: float = float(e[0]); var y: float = float(e[1]); var rx: float = maxf(1.6,float(e[2])); var ry: float = maxf(2.4,float(e[3]))
		var side: float = -1.0 if (frontal and x < cx-0.5) else 1.0
		if not frontal: side = -1.0
		var outer := Vector2(x+side*rx*1.9,y-ry*1.35)
		var inner := Vector2(x-side*rx*1.1,y-ry*1.0)
		match kind:
			"angry","fierce":
				out += '<path d="M%s %s L%s %s L%s %s Z" fill="%s" stroke="%s" stroke-width="0.6"/>' % [_f(outer.x),_f(outer.y-1.4),_f(inner.x),_f(inner.y+0.6),_f(inner.x+side*0.6),_f(inner.y-1.4),INK,INK]
				if kind == "fierce": out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="#ff5a4a" stroke-width="0.8" opacity=".85"/>' % [_f(x),_f(y),_f(rx*1.25),_f(ry*1.15)]
			"stern":
				out += '<path d="M%s %s L%s %s" fill="none" stroke="%s" stroke-width="1.8"/>' % [_f(outer.x),_f(outer.y+0.4),_f(inner.x),_f(inner.y-0.2),INK]
			"worried":
				out += '<path d="M%s %s L%s %s" fill="none" stroke="%s" stroke-width="1.3"/>' % [_f(outer.x),_f(inner.y),_f(inner.x),_f(outer.y-0.4),INK]
			"frosty":
				out += '<path d="M%s %s L%s %s L%s %s Z" fill="#e8fbff" stroke="%s" stroke-width="0.7"/>' % [_f(outer.x),_f(outer.y-1.2),_f(inner.x),_f(inner.y+0.4),_f(inner.x),_f(inner.y-1.4),INK]
				out += '<path d="M%s %s l0.8 2.6 l0.8 -2.6Z" fill="#c9f2ff" stroke="%s" stroke-width="0.4"/>' % [_f((outer.x+inner.x)*0.5-0.8),_f((outer.y+inner.y)*0.5+0.2),INK]
			"happy":
				out += '<path d="M%s %s Q%s %s %s %s" fill="none" stroke="%s" stroke-width="1.1"/>' % [_f(x-rx*1.3),_f(y-ry*1.2),_f(x),_f(y-ry*1.8),_f(x+rx*1.3),_f(y-ry*1.2),INK]
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#f29a9a" opacity=".55"/>' % [_f(x+side*rx*0.6),_f(y+ry*1.35),_f(rx*1.1),_f(ry*0.35)]
			"sleepy":
				out += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %sZ" fill="%s" stroke="%s" stroke-width="0.9"/>' % [_f(x-rx*1.3),_f(y),_f(x-rx*1.2),_f(y-ry*1.35),_f(x),_f(y-ry*1.3),_f(x+rx*1.2),_f(y-ry*1.35),_f(x+rx*1.3),_f(y),skin,INK]
			"hypno":
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#fff4fb" stroke="%s" stroke-width="0.8"/>' % [_f(x),_f(y),_f(rx*1.25),_f(ry*1.05),INK]
				var d := "M%s %s" % [_f(x),_f(y)]
				for k in range(1,14):
					var a: float = k*0.75
					d += " L%s %s" % [_f(x+cos(a)*rx*k/12.0),_f(y+sin(a)*ry*0.85*k/12.0)]
				out += '<path d="%s" fill="none" stroke="#a64fc2" stroke-width="1.0"/>' % d
			"spark":
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="#7fe8ff" stroke-width="0.9" opacity=".9"/>' % [_f(x),_f(y),_f(rx*1.4),_f(ry*1.25)]
				out += '<path d="M%s %s l0.7 1.6 1.6 0.7 -1.6 0.7 -0.7 1.6 -0.7 -1.6 -1.6 -0.7 1.6 -0.7Z" fill="#fff59a"/>' % [_f(x+rx*0.4),_f(y-ry*0.9)]
			"manic":
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#ffffff" stroke="%s" stroke-width="0.8"/>' % [_f(x),_f(y),_f(rx*1.45),_f(ry*1.2),INK]
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % [_f(x+side*0.2),_f(y+0.4),_f(rx*0.6),_f(ry*0.55),INK]
			"cool":
				out += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %sZ" fill="#2d3445" stroke="%s" stroke-width="0.7"/>' % [_f(x-rx*1.7),_f(y-ry*0.6),_f(x),_f(y-ry*0.9),_f(x+rx*1.7),_f(y-ry*0.6),_f(x),_f(y+ry*1.3),_f(x-rx*1.7),_f(y-ry*0.6),INK]
				out += '<path d="M%s %s l%s %s" fill="none" stroke="#bfe8ff" stroke-width="0.8"/>' % [_f(x-rx*0.8),_f(y-ry*0.3),_f(rx*0.9),_f(ry*0.5)]
	if kind == "cool" and frontal and eyes.size() >= 2:
		var a: Array = eyes[0]; var b: Array = eyes[1]
		out += '<path d="M%s %s L%s %s" fill="none" stroke="#2d3445" stroke-width="1.2"/>' % [_f(float(a[0])+float(a[2])*1.5),_f(float(a[1])-float(a[3])*0.5),_f(float(b[0])-float(b[2])*1.5),_f(float(b[1])-float(b[3])*0.5)]
	return out


# An armed host does not grow a second gun: its barrel takes the partner's form.
static func muzzle(kind: String, muzzles: Array, light: Color, dark: Color) -> String:
	var out := ""
	var lc := "#"+light.to_html(false)
	var dc := "#"+dark.to_html(false)
	for m in muzzles:
		var x: float = float(m[0]); var y: float = float(m[1]); var r: float = clampf(float(m[2]),3.0,7.0)
		match kind:
			"barrel":
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="%s" stroke-width="3.2"/>' % [_f(x-1.5),_f(y),_f(r*0.72),_f(r*1.32),INK]
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="%s" stroke-width="1.8"/>' % [_f(x-1.5),_f(y),_f(r*0.72),_f(r*1.32),lc]
			"nozzle":
				out += '<path d="M%s %s L%s %s L%s %s L%s %sZ" fill="%s" stroke="%s" stroke-width="1.2"/>' % [_f(x+r*0.4),_f(y-r*0.8),_f(x+r*1.7),_f(y-r*1.5),_f(x+r*1.7),_f(y+r*1.5),_f(x+r*0.4),_f(y+r*0.8),lc,INK]
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % [_f(x+r*1.75),_f(y),_f(r*0.3),_f(r*1.15),dc]
			"teeth":
				for k in range(4):
					var a: float = -PI*0.42+k*PI*0.28
					var p := Vector2(x,y)+Vector2(cos(a)*r*0.75,sin(a)*r*1.2)
					out += '<path d="M%s %s l%s %s l%s %sZ" fill="#fff0d7" stroke="%s" stroke-width="0.6"/>' % [_f(p.x-1.2),_f(p.y),_f(2.6),_f(-0.8 if p.y < y else 0.8),_f(-1.6),_f(1.8 if p.y < y else -1.8),INK]
			"cannon":
				out += '<path d="M%s %s h%s v%s h%sZ" fill="#c9d3d8" stroke="%s" stroke-width="1"/>' % [_f(x-r*1.6),_f(y-r*1.25),_f(r*0.7),_f(r*2.5),_f(-r*0.7),INK]
			"lens":
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#eaffff" stroke="%s" stroke-width="1" opacity=".9"/>' % [_f(x+r*0.9),_f(y),_f(r*0.5),_f(r*1.1),INK]
				out += '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % [_f(x+r*0.95),_f(y),_f(r*0.22),_f(r*0.55),lc]
			"flame":
				out += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %sZ" fill="url(#flame)" stroke="%s" stroke-width="0.8"/>' % [_f(x+r*0.6),_f(y-r*0.7),_f(x+r*2.2),_f(y-r*1.2),_f(x+r*3.2),_f(y),_f(x+r*2.2),_f(y+r*1.2),_f(x+r*0.6),_f(y+r*0.7),INK]
	return out


static func _flame(x: float, y: float, s: float) -> String:
	return '<g transform="translate(%s %s) scale(%.2f)"><path d="M0 8 Q-12 2 -7 -9 Q-3 -5 0 -21 Q12 -9 7 0 Q6 8 0 8Z" fill="url(#flame)" stroke="%s" stroke-width="1.2"/><path d="M0 6 Q-6 0 1 -8 Q6 2 0 6Z" fill="#fff1b0"/></g>' % [_f(x),_f(y),s,INK]

static func _spark(x: float, y: float, r: float, color: String) -> String:
	var d := ""
	for i in range(8):
		var radius: float = r if i%2 == 0 else r*0.38
		var a: float = -PI*0.5+i*PI/4.0
		d += ("M" if i == 0 else " L")+"%s %s" % [_f(x+cos(a)*radius),_f(y+sin(a)*radius)]
	return '<path d="%sZ" fill="%s" stroke="%s" stroke-width="0.6"/>' % [d,color,INK]


# A small emblem of an element at one point around the hybrid.
static func aura(element: String, x: float, y: float, s: float, seed: int) -> String:
	match element:
		"fire":
			return _flame(x,y,0.42*s)+'<circle cx="%s" cy="%s" r="1.2" fill="#ffb347"/>' % [_f(x-6*s),_f(y-9*s)]+'<circle cx="%s" cy="%s" r="0.9" fill="#ffe08a"/>' % [_f(x+5*s),_f(y-13*s)]
		"frost":
			var d := ""
			for k in range(3):
				var a: float = k*PI/3.0
				d += "M%s %s L%s %s " % [_f(x-cos(a)*5*s),_f(y-sin(a)*5*s),_f(x+cos(a)*5*s),_f(y+sin(a)*5*s)]
			return '<path d="%s" fill="none" stroke="%s" stroke-width="2.6"/><path d="%s" fill="none" stroke="#e8fbff" stroke-width="1.3"/>' % [d,INK,d]+'<circle cx="%s" cy="%s" r="1" fill="#ffffff"/>' % [_f(x+7*s),_f(y+6*s)]
		"shock":
			return '<path d="M%s %s l-4 7 h3 l-2 7 l7 -9 h-3 l3 -5Z" fill="#ffe36a" stroke="%s" stroke-width="0.8" transform="scale(1)"/>' % [_f(x+1),_f(y-8*s),INK]+_spark(x+7*s,y+4*s,2.2*s,"#9fe8ff")
		"poison":
			return '<circle cx="%s" cy="%s" r="%s" fill="#b6e36a" stroke="%s" stroke-width="0.7"/><circle cx="%s" cy="%s" r="%s" fill="#d6f59a" stroke="%s" stroke-width="0.6"/><circle cx="%s" cy="%s" r="1.1" fill="#9fd04a"/>' % [_f(x),_f(y),_f(3*s),INK,_f(x+5*s),_f(y-6*s),_f(2*s),INK,_f(x-4*s),_f(y-8*s)]
		"dream":
			var w := '<g transform="translate(%s %s) scale(%.2f)"><path d="M0 0 Q-7 -8 -9 -2 Q-8 3 0 1Z M0 0 Q7 -8 9 -2 Q8 3 0 1Z" fill="#e39bff" stroke="%s" stroke-width="0.8"/><path d="M0 1 Q-5 6 -4 8 Q-1 7 0 2Z M0 1 Q5 6 4 8 Q1 7 0 2Z" fill="#f6c8ff" stroke="%s" stroke-width="0.6"/></g>' % [_f(x),_f(y),0.75*s,INK,INK]
			return w+'<path d="M%s %s h3 l-3 3 h3" fill="none" stroke="#b58ad8" stroke-width="0.9"/>' % [_f(x+7*s),_f(y-9*s)]
		"shadow":
			return '<path d="M%s %s q-6 -4 -2 -10 q5 -3 4 3 q-1 4 -4 2" fill="none" stroke="#8e7bc4" stroke-width="1.6"/>' % [_f(x),_f(y)]+'<path d="M%s %s a4 4 0 1 0 4 5 a3 3 0 1 1 -4 -5Z" fill="#d9ccff" stroke="%s" stroke-width="0.6"/>' % [_f(x+6*s),_f(y-10*s),INK]
		"blast":
			return _spark(x,y,4.4*s,"#ffd76a")+'<circle cx="%s" cy="%s" r="1.6" fill="#fff6d0"/>' % [_f(x),_f(y)]+'<circle cx="%s" cy="%s" r="%s" fill="#c9c3b4" opacity=".7"/>' % [_f(x-6*s),_f(y+3*s),_f(2.2*s)]
		"sun":
			var rays := ""
			for k in range(8):
				var a: float = k*PI/4.0
				rays += "M%s %s L%s %s " % [_f(x+cos(a)*4*s),_f(y+sin(a)*4*s),_f(x+cos(a)*6.6*s),_f(y+sin(a)*6.6*s)]
			return '<path d="%s" fill="none" stroke="#f5b83d" stroke-width="1.3"/><circle cx="%s" cy="%s" r="%s" fill="#ffe27a" stroke="%s" stroke-width="0.8"/>' % [rays,_f(x),_f(y),_f(3.4*s),INK]
		"water":
			return '<path d="M%s %s q-4 5 0 7 q4 -2 0 -7Z" fill="#9fdcf2" stroke="%s" stroke-width="0.7"/><circle cx="%s" cy="%s" r="%s" fill="none" stroke="#7cc4dc" stroke-width="0.9"/>' % [_f(x),_f(y-6*s),INK,_f(x+6*s),_f(y+2*s),_f(2*s)]
		"wind":
			return '<path d="M%s %s q6 -5 10 -1 q2 4 -3 4 M%s %s q5 -3 8 0" fill="none" stroke="#9fd8c8" stroke-width="1.5"/>' % [_f(x-6*s),_f(y),_f(x-4*s),_f(y+5*s)]
		"light", "holy":
			if element == "holy": return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="#e8c870" stroke-width="2"/><ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="none" stroke="#fff4c8" stroke-width="0.8"/>' % [_f(x),_f(y),_f(9*s),_f(2.6*s),_f(x),_f(y),_f(9*s),_f(2.6*s)]
			return _spark(x,y,4.0*s,"#fff6c8")+_spark(x+6*s,y+6*s,2.0*s,"#e8fdff")
		"heal":
			return '<path d="M%s %s h2.4 v2.4 h2.4 v2.4 h-2.4 v2.4 h-2.4 v-2.4 h-2.4 v-2.4 h2.4Z" fill="#8fe39a" stroke="%s" stroke-width="0.7"/>' % [_f(x-1.2),_f(y-3.6),INK]
		"metal":
			return '<path d="M%s %s a5 5 0 0 1 10 0" fill="none" stroke="#d86761" stroke-width="2.4"/><path d="M%s %s a3 3 0 0 1 6 0" fill="none" stroke="#c9d3d8" stroke-width="1.2"/>' % [_f(x-5*s),_f(y),_f(x-3*s),_f(y-4*s)]
		"time":
			return '<circle cx="%s" cy="%s" r="%s" fill="#faf0ca" stroke="%s" stroke-width="0.9"/><path d="M%s %s v-2.6 M%s %s l2 1" fill="none" stroke="#604a44" stroke-width="0.9"/>' % [_f(x),_f(y),_f(4*s),INK,_f(x),_f(y),_f(x),_f(y)]
		"tea":
			return '<path d="M%s %s q-3 -4 0 -7 q3 -3 0 -6 M%s %s q-3 -3 0 -6" fill="none" stroke="#e7dccf" stroke-width="1.4"/>' % [_f(x),_f(y),_f(x+4*s),_f(y-1)]
		"milk":
			return '<path d="M%s %s q-4 5 0 7 q4 -2 0 -7Z" fill="#fffdf5" stroke="%s" stroke-width="0.7"/>' % [_f(x),_f(y-5*s),INK]+'<circle cx="%s" cy="%s" r="1.3" fill="#fffdf5" stroke="%s" stroke-width="0.4"/>' % [_f(x+5*s),_f(y+3*s),INK]
		"sweet":
			return _spark(x,y,3.4*s,"#ffc7e0")+'<circle cx="%s" cy="%s" r="1.2" fill="#c8f0ff"/>' % [_f(x+5*s),_f(y+4*s)]
		"bloom":
			return '<path d="M%s %s q-2.6 -3.4 0 -6 q2.6 2.6 0 6Z" fill="#ffd9e6" stroke="%s" stroke-width="0.6" transform="rotate(30 %s %s)"/>' % [_f(x),_f(y),INK,_f(x),_f(y)]
		"butter":
			return '<path d="M%s %s h6 l2 3 h-6Z" fill="#ffe88a" stroke="%s" stroke-width="0.7"/>' % [_f(x-4),_f(y-2),INK]
		"bite":
			return '<path d="M%s %s l2.2 4 2.2 -4 2.2 4 2.2 -4" fill="none" stroke="#fff0d7" stroke-width="1.4"/>' % [_f(x-4.4*s),_f(y)]
		"smoke":
			return '<circle cx="%s" cy="%s" r="%s" fill="#c9c3b4" opacity=".75"/><circle cx="%s" cy="%s" r="%s" fill="#dcd6c8" opacity=".75"/>' % [_f(x),_f(y),_f(2.6*s),_f(x+3*s),_f(y-4*s),_f(2*s)]
		"earth":
			return '<path d="M%s %s l3 -3 3 1 1 3 -4 1Z" fill="#b3a68a" stroke="%s" stroke-width="0.7"/>' % [_f(x-3),_f(y+2),INK]
	return ""
