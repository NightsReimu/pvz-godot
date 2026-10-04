extends RefCounted
const Organs = preload("res://scripts/data/fusion_organ_art.gd")

static func svg_for(id: String, data: Dictionary) -> String:
	var weights: Dictionary = data.fusion_weights
	var keys: Array = weights.keys(); keys.sort()
	var seed: int = ("0x"+id.md5_text().substr(0,7)).hex_to_int()
	var tier: int = int(data.fusion_tier)
	var ink := "#354f43"
	var body := '<ellipse cx="0" cy="41" rx="33" ry="4" fill="#263c32"/>'
	body += '<path d="M-26 38 Q-34 20 -17 11 Q0 -3 17 11 Q35 21 26 38 Q0 49 -26 38Z" fill="#89b977" stroke="%s" stroke-width="1.5"/>' % ink
	var slots := [Vector2(-21,-5),Vector2(21,-11),Vector2(0,-30),Vector2(-23,17),Vector2(23,15),Vector2(0,28)]
	var count := mini(6,keys.size())
	for n in range(count):
		var component: String = keys[n]
		var weight: int = int(weights[component])
		var pos: Vector2 = slots[n]+Vector2((seed>>(n*3)&3)-1,(seed>>(n*2)&3)-1)
		var scale: float = (0.58 if count <= 2 else 0.40)+minf(0.035*float(weight-1),0.08)
		body += '<path d="M0 36 Q%.2f 5 %.2f %.2f" fill="none" stroke="#608b58" stroke-width="%.2f"/>' % [pos.x*0.5,pos.x,pos.y+18,4.0+tier*0.2]
		body += '<g transform="translate(%.2f %.2f) scale(%.3f)">%s</g>' % [pos.x,pos.y,scale,String(Organs.BODIES[component])]
		# Actual ingredient weights grow distinct bud/leaf topology around each organ.
		for bud in range(mini(weight,5)):
			var x: float = pos.x+(bud-2)*5.3; var y: float = pos.y+26+(bud%2)*3
			body += '<path d="M%.2f %.2f q-7 -9 -11 -3 q4 8 11 3Z" fill="#b4d58c" stroke="#55754d" stroke-width="0.7"/>' % [x,y]
	# The graft itself has a distinct weapon/defense chassis, not a flat combined badge.
	match String(data.fusion_attack):
		"shooter","spread": body += '<path d="M-5 18 L26 12 L38 17 L38 26 L5 28Z" fill="#9fc58a" stroke="#354f43" stroke-width="1.5"/><ellipse cx="38" cy="21" rx="4" ry="6" fill="#31473c"/>'
		"beam": body += '<path d="M-11 28 L0 5 L11 28 L35 12 L40 21 L12 37Z" fill="#bddcdd" stroke="#637d87" stroke-width="1.4"/><path d="M0 8 L6 24 L0 32 L-6 24Z" fill="#edfaff"/>'
		"lobber": body += '<path d="M-29 33 L-15 12 L-19 -4 L-7 -10 L1 28 L29 34Z" fill="#c8af7d" stroke="#685e43" stroke-width="1.5"/><ellipse cx="-14" cy="-5" rx="7" ry="4" fill="#354f43"/>'
		"blade": body += '<path d="M-27 25 Q-1 -5 32 22 Q9 9 2 29 Q-12 37 -27 25Z" fill="#d7e3ce" stroke="#557264" stroke-width="1.4"/>'
		"guard": body += '<path d="M-33 9 L-16 7 L-14 32 L-25 40 L-36 29Z M18 8 L35 14 L34 33 L23 39 L17 29Z" fill="#bdcbb2" stroke="#61745d" stroke-width="1.4"/>'
		"bomb": body += '<path d="M-13 33 L-9 15 L9 15 L14 33Z" fill="#e6ab91" stroke="#8e655d"/><path d="M0 15 Q-3 2 7 -2" fill="none" stroke="#db945a" stroke-width="2"/>'
		"melee": body += '<path d="M-30 30 Q-14 5 0 26 Q16 6 30 31 L9 35 L2 29 L-5 35Z" fill="#ecdeac" stroke="#667353" stroke-width="1.4"/>'
		_: body += '<path d="M-17 32 Q0 6 17 32 Q0 43 -17 32Z" fill="#e1cea0" stroke="#7e845c"/><path d="M-9 27 L0 21 L9 27 L0 35Z" fill="#fff0c6"/>'
	if String(data.fusion_base) == "lily_pad": body += '<path d="M-36 38 Q-12 29 4 35 Q31 26 38 41 Q6 51 -36 38Z" fill="#81b889" stroke="#477451"/>'
	if String(data.fusion_base) == "flower_pot": body += '<path d="M-30 33 L30 33 L24 48 L-24 48Z" fill="#c49b79" stroke="#806b54"/>'
	for n in range(mini(tier+2,10)):
		var x: float = -30+n*60.0/float(mini(tier+1,9))
		var y: float = 35+float(seed>>(n*2)&3)
		body += '<path d="M%.2f 42 Q%.2f %.2f %.2f 36" fill="none" stroke="#456b4e" stroke-width="0.8"/>' % [x,x+3,y,x+6]
	var signature := body.md5_text()
	return '<svg xmlns="http://www.w3.org/2000/svg" width="192" height="224" viewBox="-48 -60 96 112" data-plant-kind="%s" data-facing="right" data-geometry-signature="%s">%s</svg>' % [id,signature,body]
