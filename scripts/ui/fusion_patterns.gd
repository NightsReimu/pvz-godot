extends RefCounted
# Surface patterns a partner lends a hybrid's skin. Each pattern fills the skin's
# bounding box in body units; the composer masks it to living tissue, away from
# eyes, mouth and muzzles.

static func _c(color: Color) -> String:
	return "#"+color.to_html(false)

static func _f(v: float) -> String:
	return "%.1f" % v

static func _line(d: String, color: String, width: float, opacity: float = 1.0) -> String:
	return '<path d="%s" fill="none" stroke="%s" stroke-width="%.1f" opacity="%.2f"/>' % [d,color,width,opacity]

static func _dot(x: float, y: float, rx: float, ry: float, fill: String, opacity: float = 1.0, stroke: String = "none", width: float = 0.0) -> String:
	return '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="%s" stroke="%s" stroke-width="%.1f" opacity="%.2f"/>' % [x,y,rx,ry,fill,stroke,width,opacity]

static func _rand(seed: int, n: int) -> float:
	return fposmod(sin(float(seed*12.9898+n*78.233))*43758.5453,1.0)


static func draw(pattern: String, box: Array, light: Color, dark: Color, seed: int, strength: float = 1.0) -> String:
	var x0: float = float(box[0]); var y0: float = float(box[1]); var x1: float = float(box[2]); var y1: float = float(box[3])
	var w: float = maxf(8.0,x1-x0); var h: float = maxf(8.0,y1-y0)
	var cx: float = (x0+x1)*0.5; var cy: float = (y0+y1)*0.5
	var lt: String = _c(Color.from_hsv(light.h,light.s*0.45,minf(1.0,light.v*1.12)))
	var dk: String = _c(Color.from_hsv(dark.h,minf(1.0,dark.s*1.15),dark.v*0.6))
	var o: float = strength
	var out := ""
	match pattern:
		"gloss":
			out += _line("M%s %s Q%s %s %s %s" % [_f(x0+w*0.2),_f(y0+h*0.48),_f(x0+w*0.2),_f(y0+h*0.16),_f(x0+w*0.48),_f(y0+h*0.12)],"#ffffff",maxf(1.8,w*0.06),0.6*o)
			out += _dot(x0+w*0.3,y0+h*0.3,maxf(1.2,w*0.035),maxf(1.6,h*0.05),"#ffffff",0.8*o)
			out += _line("M%s %s Q%s %s %s %s" % [_f(x1-w*0.16),_f(y0+h*0.6),_f(x1-w*0.12),_f(y1-h*0.2),_f(x1-w*0.34),_f(y1-h*0.1)],lt,1.4,0.45*o)
		"stripes", "ribs":
			var n: int = 5 if pattern == "stripes" else 4
			for i in range(n):
				var x: float = x0+w*(i+0.5)/n
				var bend: float = (x-cx)*0.35
				out += _line("M%s %s Q%s %s %s %s" % [_f(x-bend*0.3),_f(y0+1),_f(x+bend),_f(cy),_f(x-bend*0.3),_f(y1-1)],dk,maxf(1.2,w*(0.07 if pattern == "stripes" else 0.03)),(0.5 if pattern == "stripes" else 0.55)*o)
			if pattern == "stripes":
				for i in range(n-1):
					var x: float = x0+w*(i+1.0)/n
					out += _line("M%s %s Q%s %s %s %s" % [_f(x),_f(y0+h*0.15),_f(x+(x-cx)*0.3),_f(cy),_f(x),_f(y1-h*0.15)],lt,0.9,0.5*o)
		"cracks", "bark":
			var lines: int = 3 if pattern == "cracks" else 5
			for i in range(lines):
				var x: float = x0+w*(0.2+0.6*_rand(seed,i))
				var y: float = y0+h*(0.15+0.65*_rand(seed,i+7))
				if pattern == "bark":
					out += _line("M%s %s q%s %s 0 %s q%s %s 0 %s" % [_f(x),_f(y0+h*0.1),_f(-2),_f(h*0.2),_f(h*0.4),_f(2),_f(h*0.2),_f(h*0.4)],dk,1.0,0.5*o)
				else:
					out += _line("M%s %s q%s %s %s %s" % [_f(x),_f(y),_f(-3+_rand(seed,i+3)*6),_f(3),_f(1),_f(7)],dk,1.0,0.7*o)
			if pattern == "cracks":
				out += _line("M%s %s l3 4 -3 3 4 5" % [_f(x0+w*0.62),_f(y0+h*0.08)],dk,1.3,0.75*o)
		"kernels", "seeds":
			var step: float = clampf(minf(w,h)/6.0,4.2,7.0)
			var row := 0
			var y: float = y0+step*0.6
			while y < y1 and row < 10:
				var x: float = x0+step*(0.6+0.5*(row%2))
				var col := 0
				while x < x1 and col < 10:
					if pattern == "kernels": out += _dot(x,y,step*0.36,step*0.3,lt,0.85*o,dk,0.5)
					else: out += '<path d="M%s %s q%s %s 0 %s q%s %s 0 %sZ" fill="%s" opacity="%.2f"/>' % [_f(x),_f(y-step*0.25),_f(step*0.22),_f(step*0.22),_f(step*0.5),_f(-step*0.22),_f(-step*0.22),_f(-step*0.5),dk,0.6*o]
					x += step; col += 1
				y += step*0.9; row += 1
		"spots":
			for i in range(5):
				var r: float = maxf(1.6,minf(w,h)*(0.06+0.05*_rand(seed,i)))
				out += _dot(x0+w*(0.15+0.7*_rand(seed,i+11)),y0+h*(0.12+0.6*_rand(seed,i+23)),r,r*0.78,"#fff3dc",0.9*o,dk,0.5)
		"facets":
			out += '<path d="M%s %s L%s %s L%s %sZ" fill="#ffffff" opacity="%.2f"/>' % [_f(x0+w*0.18),_f(y0+h*0.22),_f(cx),_f(y0+h*0.06),_f(cx-w*0.06),_f(cy),0.28*o]
			out += _line("M%s %s L%s %s L%s %s M%s %s L%s %s L%s %s" % [_f(x0+w*0.1),_f(cy),_f(cx-w*0.06),_f(cy),_f(cx+w*0.12),_f(y0+h*0.12),_f(cx-w*0.06),_f(cy),_f(cx+w*0.05),_f(y1-h*0.12),_f(x1-w*0.1),_f(cy+h*0.08)],"#ffffff",1.1,0.7*o)
		"flames", "lava":
			if pattern == "flames":
				for i in range(4):
					var x: float = x0+w*(0.15+0.23*i)
					var tall: float = h*(0.32+0.2*_rand(seed,i))
					out += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %sZ" fill="#ff8a3d" opacity="%.2f"/>' % [_f(x-w*0.09),_f(y1),_f(x-w*0.1),_f(y1-tall*0.6),_f(x),_f(y1-tall),_f(x+w*0.1),_f(y1-tall*0.5),_f(x+w*0.09),_f(y1),0.6*o]
					out += '<path d="M%s %s Q%s %s %s %s Q%s %s %s %sZ" fill="#ffe08a" opacity="%.2f"/>' % [_f(x-w*0.04),_f(y1),_f(x-w*0.04),_f(y1-tall*0.35),_f(x),_f(y1-tall*0.6),_f(x+w*0.05),_f(y1-tall*0.3),_f(x+w*0.04),_f(y1),0.7*o]
			else:
				var d := "M%s %s l%s %s l%s %s l%s %s M%s %s l%s %s l%s %s M%s %s l%s %s" % [_f(x0+w*0.15),_f(y0+h*0.3),_f(w*0.15),_f(h*0.1),_f(w*0.05),_f(h*0.2),_f(w*0.18),_f(h*0.05),_f(x0+w*0.33),_f(y0+h*0.4),_f(w*0.2),_f(-h*0.15),_f(w*0.2),_f(h*0.05),_f(x0+w*0.42),_f(y0+h*0.66),_f(-w*0.1),_f(h*0.2)]
				out += _line(d,"#ff7a2a",2.4,0.75*o)+_line(d,"#ffe08a",1.0,0.95*o)
		"spines":
			for i in range(9):
				var x: float = x0+w*(0.1+0.8*_rand(seed,i))
				var y: float = y0+h*(0.1+0.8*_rand(seed,i+31))
				out += _line("M%s %s l%s -2.6" % [_f(x),_f(y),_f(2.6 if x > cx else -2.6)],"#f0e6b4",1.2,0.95*o)
		"rings", "zigzag":
			for i in range(4):
				var y: float = y0+h*(i+0.6)/4.4
				if pattern == "rings": out += _line("M%s %s Q%s %s %s %s" % [_f(x0),_f(y),_f(cx),_f(y+2.4),_f(x1),_f(y)],lt,1.6,0.7*o)
				else:
					var d := "M%s %s" % [_f(x0),_f(y)]
					for k in range(8): d += " L%s %s" % [_f(x0+w*(k+1)/8.0),_f(y+(2.2 if k%2 == 0 else -0.6))]
					out += _line(d,lt,1.3,0.7*o)
		"stars":
			for i in range(5):
				var x: float = x0+w*(0.12+0.76*_rand(seed,i))
				var y: float = y0+h*(0.1+0.7*_rand(seed,i+5))
				var r: float = 1.6+1.6*_rand(seed,i+9)
				out += '<path d="M%s %s L%s %s L%s %s L%s %s L%s %s L%s %s L%s %s L%s %sZ" fill="#fff6c8" opacity="%.2f"/>' % [_f(x),_f(y-r),_f(x+r*0.3),_f(y-r*0.3),_f(x+r),_f(y),_f(x+r*0.3),_f(y+r*0.3),_f(x),_f(y+r),_f(x-r*0.3),_f(y+r*0.3),_f(x-r),_f(y),_f(x-r*0.3),_f(y-r*0.3),0.9*o]
		"swirl":
			var r: float = minf(w,h)*0.22
			var d := "M%s %s" % [_f(cx),_f(cy)]
			for k in range(1,22):
				var a: float = k*0.55
				var rr: float = r*k/21.0
				d += " L%s %s" % [_f(cx+cos(a)*rr),_f(cy-h*0.12+sin(a)*rr)]
			out += _line(d,"#a64fc2",1.6,0.7*o)+_line(d,lt,0.6,0.6*o)
		"circuit":
			for i in range(3):
				var y: float = y0+h*(0.25+0.25*i)
				var x: float = x0+w*(0.1+0.2*_rand(seed,i))
				out += _line("M%s %s h%s v%s h%s" % [_f(x),_f(y),_f(w*0.25),_f(-h*0.08 if i%2 == 0 else h*0.08),_f(w*0.25)],"#7fe8ff",1.1,0.8*o)
				out += _dot(x,y,1.3,1.3,"#e8fdff",o)+_dot(x+w*0.5,y+(-h*0.08 if i%2 == 0 else h*0.08),1.3,1.3,"#e8fdff",o)
		"scales":
			var step: float = clampf(minf(w,h)/5.0,4.0,7.0)
			var yy: float = y0+step
			var row := 0
			while yy < y1 and row < 8:
				var xx: float = x0+step*(0.5*(row%2))
				while xx < x1:
					out += _line("M%s %s q%s %s %s 0" % [_f(xx),_f(yy),_f(step*0.5),_f(step*0.55),_f(step)],dk,0.9,0.5*o)
					xx += step
				yy += step*0.8; row += 1
		"veins":
			out += _line("M%s %s Q%s %s %s %s" % [_f(cx),_f(y1-h*0.08),_f(cx-w*0.05),_f(cy),_f(cx+w*0.02),_f(y0+h*0.12)],lt,1.4,0.7*o)
			for i in range(3):
				var y: float = y0+h*(0.3+0.2*i)
				out += _line("M%s %s q%s %s %s %s M%s %s q%s %s %s %s" % [_f(cx),_f(y),_f(-w*0.12),_f(-2),_f(-w*0.28),_f(-5),_f(cx),_f(y),_f(w*0.12),_f(-2),_f(w*0.28),_f(-5)],lt,1.0,0.6*o)
		"bubbles":
			for i in range(5):
				var r: float = 1.6+minf(w,h)*0.05*_rand(seed,i)
				var x: float = x0+w*(0.15+0.7*_rand(seed,i+3)); var y: float = y0+h*(0.15+0.7*_rand(seed,i+13))
				out += _dot(x,y,r,r,"none",0.8*o,lt,1.0)+_line("M%s %s q0 %s %s %s" % [_f(x-r*0.5),_f(y),_f(-r*0.5),_f(r*0.5),_f(-r*0.6)],"#ffffff",0.8,0.8*o)
		"speckle":
			for i in range(9):
				var r: float = 0.8+1.4*_rand(seed,i)
				out += _dot(x0+w*(0.1+0.8*_rand(seed,i+2)),y0+h*(0.1+0.8*_rand(seed,i+17)),r,r*0.75,dk if i%3 else lt,0.65*o)
		"bricks":
			var step: float = clampf(h/6.0,4.0,7.0)
			var y: float = y0+step
			var row := 0
			while y < y1:
				out += _line("M%s %s H%s" % [_f(x0),_f(y),_f(x1)],dk,0.9,0.55*o)
				var x: float = x0+(step*0.9 if row%2 else step*1.8)
				while x < x1:
					out += _line("M%s %s v%s" % [_f(x),_f(y-step),_f(step)],dk,0.9,0.55*o)
					x += step*1.8
				y += step; row += 1
		"frost":
			var d := "M%s %s" % [_f(x0),_f(y1-h*0.22)]
			for k in range(7): d += " Q%s %s %s %s" % [_f(x0+w*(k+0.5)/7.0),_f(y1-h*(0.3 if k%2 else 0.14)),_f(x0+w*(k+1)/7.0),_f(y1-h*0.22)]
			out += '<path d="%s L%s %s L%s %sZ" fill="#effcff" opacity="%.2f"/>' % [d,_f(x1),_f(y1),_f(x0),_f(y1),0.55*o]
			for i in range(4):
				out += _dot(x0+w*(0.15+0.7*_rand(seed,i)),y0+h*(0.15+0.45*_rand(seed,i+4)),1.2,1.2,"#ffffff",0.85*o)
		"fluff":
			for i in range(10):
				var x: float = x0+w*(0.1+0.8*_rand(seed,i)); var y: float = y0+h*(0.1+0.8*_rand(seed,i+6))
				out += _line("M%s %s l%s %s" % [_f(x),_f(y),_f(-1.5+3*_rand(seed,i+9)),_f(-2.4)],"#ffffff",0.9,0.85*o)
		"porcelain":
			var y: float = cy+h*0.08
			out += _line("M%s %s q%s %s %s 0 q%s %s %s 0 q%s %s %s 0" % [_f(x0+w*0.12),_f(y),_f(w*0.06),_f(-5),_f(w*0.13),_f(w*0.06),_f(5),_f(w*0.13),_f(w*0.06),_f(-5),_f(w*0.13)],"#4f7fb4",1.3,0.85*o)
			out += _line("M%s %s q3 -3 6 0 M%s %s q3 -3 6 0" % [_f(x0+w*0.2),_f(y+h*0.18),_f(x1-w*0.3),_f(y+h*0.18)],"#4f7fb4",1.0,0.8*o)
		"drip":
			var d := "M%s %s" % [_f(x0),_f(y0+h*0.1)]
			for k in range(5):
				var x: float = x0+w*(k+0.5)/5.0
				d += " L%s %s Q%s %s %s %s" % [_f(x-w*0.06),_f(y0+h*0.12),_f(x),_f(y0+h*(0.3+0.12*_rand(seed,k))),_f(x+w*0.06),_f(y0+h*0.12)]
			out += '<path d="%s L%s %s L%s %sZ" fill="#fffdf5" opacity="%.2f"/>' % [d,_f(x1),_f(y0),_f(x0),_f(y0),0.8*o]
		"glyph":
			for i in range(6):
				out += '<rect x="%s" y="%s" width="%s" height="2.2" fill="%s" opacity="%.2f"/>' % [_f(x0+w*(0.1+0.75*_rand(seed,i))),_f(y0+h*(0.1+0.8*_rand(seed,i+8))),_f(2+4*_rand(seed,i+2)),"#737dbf" if i%2 else "#bcffea",0.8*o]
		"petals":
			for i in range(4):
				var x: float = x0+w*(0.2+0.6*_rand(seed,i)); var y: float = y0+h*(0.15+0.6*_rand(seed,i+5))
				out += '<path d="M%s %s q-2.2 -3 0 -5.4 q2.2 2.4 0 5.4Z" fill="%s" opacity="%.2f"/>' % [_f(x),_f(y),lt,0.8*o]
		"honey":
			var r: float = clampf(minf(w,h)/8.0,2.6,4.4)
			for i in range(5):
				var x: float = x0+w*(0.18+0.64*_rand(seed,i)); var y: float = y0+h*(0.18+0.6*_rand(seed,i+3))
				var d := ""
				for k in range(6):
					var a: float = k*PI/3.0
					d += ("M" if k == 0 else " L")+"%s %s" % [_f(x+cos(a)*r),_f(y+sin(a)*r)]
				out += _line(d+"Z",dk,0.9,0.6*o)
		"waves":
			for i in range(3):
				var y: float = y0+h*(0.25+0.22*i)
				out += _line("M%s %s q%s %s %s 0 q%s %s %s 0" % [_f(x0),_f(y),_f(w*0.25),_f(-4),_f(w*0.5),_f(w*0.25),_f(4),_f(w*0.5)],["#9fe8d8","#d9b8ff","#bfe8ff"][i],2.0,0.6*o)
		"rays":
			for i in range(8):
				var a: float = i*PI/4.0+0.2
				out += _line("M%s %s L%s %s" % [_f(cx+cos(a)*w*0.12),_f(cy+sin(a)*h*0.12),_f(cx+cos(a)*w*0.42),_f(cy+sin(a)*h*0.42)],"#fff6c8",1.4,0.55*o)
		"wisps":
			for i in range(3):
				var x: float = x0+w*(0.2+0.3*i); var y: float = y0+h*(0.3+0.2*_rand(seed,i))
				out += _line("M%s %s q-4 -3 -1 -7 q4 -2 3 2 q-1 3 -3 1" % [_f(x),_f(y)],"#cbb8f2",1.2,0.75*o)
	return out
