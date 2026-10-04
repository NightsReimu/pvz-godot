extends RefCounted
const Organs = preload("res://scripts/data/fusion_organ_art.gd")

static func svg_for(id: String, data: Dictionary) -> String:
	var weights: Dictionary = data.fusion_weights
	var keys: Array = weights.keys(); keys.sort()
	var seed: int = ("0x"+id.md5_text().substr(0,7)).hex_to_int()
	var tier: int = int(data.fusion_tier)
	var ink := "#354f43"
	var body := '<defs><linearGradient id="graft-skin" x2=".7" y2="1"><stop stop-color="#c3df9b"/><stop offset="1" stop-color="#6b9d6e"/></linearGradient></defs><ellipse cx="0" cy="41" rx="33" ry="4" fill="#263c32"/>'
	body += '<path d="M-26 38 Q-34 20 -17 11 Q0 -3 17 11 Q35 21 26 38 Q0 49 -26 38Z" fill="url(#graft-skin)" stroke="%s" stroke-width="1.5"/>' % ink
	var slots := [Vector2(-17,-11),Vector2(18,-13),Vector2(0,-30),Vector2(-23,17),Vector2(23,15),Vector2(0,28)]
	var count := mini(6,keys.size())
	for n in range(count):
		var component: String = keys[n]
		var weight: int = int(weights[component])
		var pos: Vector2 = slots[n]+Vector2((seed>>(n*3)&3)-1,(seed>>(n*2)&3)-1)
		var scale: float = (0.66 if count <= 2 else 0.44)+minf(0.035*float(weight-1),0.08)
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
	body += combat_anatomy(data,seed)
	var signature := body.md5_text()
	return '<svg xmlns="http://www.w3.org/2000/svg" width="192" height="224" viewBox="-48 -60 96 112" data-plant-kind="%s" data-facing="right" data-geometry-signature="%s">%s</svg>' % [id,signature,body]

static func combat_anatomy(data: Dictionary, seed: int) -> String:
	var body := ''
	var styles: Array = []
	var bursts: Array = []
	for channel in data.get("fusion_channels",[]):
		if channel.style == "burst": bursts.append(channel)
		elif not styles.has(channel.style): styles.append(channel.style)
	# Each functional part is attached to the living stem and uses a distinct silhouette.
	if "lobber" in styles:
		body += '<g data-organ="catapult"><path d="M9 31 Q20 13 22 -4 L28 -11 L31 -7 L27 0 Q24 21 16 32Z" fill="#6e9867" stroke="#314f40" stroke-width="1.5"/><path d="M20 -7 Q29 0 40 -10 L38 -15 Q27 -8 21 -12Z" fill="#b8d999" stroke="#3c5f45" stroke-width="1.3"/><ellipse cx="31" cy="-13" rx="6" ry="5" fill="#f1dba4" stroke="#96784b"/><path d="M13 26 Q30 22 31 7" fill="none" stroke="#dac897" stroke-width="2"/><circle cx="15" cy="27" r="4" fill="#d4b975" stroke="#655e3d"/></g>'
	if not bursts.is_empty():
		var burst: Dictionary = bursts[0]
		var hue: String = "#9b8cb7" if burst.source in ["doom_shroom","dream_disc"] else "#d88667"
		body += '<g data-organ="burst-chamber"><path d="M-32 18 Q-37 9 -27 4 Q-11 0 -9 14 L-9 29 Q-20 38 -32 29Z" fill="%s" stroke="#523e40" stroke-width="1.5"/><path d="M-29 8 Q-20 4 -15 11" fill="none" stroke="#ffe0ba" stroke-width="2"/><path d="M-32 20 L-10 20 M-30 27 L-11 27" stroke="#755650" stroke-width="1.3"/><path d="M-24 6 Q-25 -6 -16 -9" fill="none" stroke="#775b44" stroke-width="2"/><path d="M-17 -13 L-20 -8 L-15 -6 L-11 -10Z" fill="#ffc66d"/><circle cx="-20" cy="16" r="4" fill="#fff0a7" stroke="#896445"/><path d="M-20 16 L-18 13" stroke="#8a6651" stroke-width="1"/></g>' % hue
		if burst.blast_shape == "row": body += '<path data-organ="flame-nozzle" d="M-13 10 L-2 8 L2 13 L-11 17Z" fill="#f4c18c" stroke="#76544c"/>'
		if burst.source == "doom_shroom": body += '<path data-organ="doom-cap" d="M-38 6 Q-34 -7 -23 -8 Q-9 -6 -6 6Z" fill="#a68fc4" stroke="#534364"/><path d="M-30 2 L-27 -2 L-24 2 M-20 3 L-16 -1" stroke="#d3c2e6" fill="none"/>'
	if "reflect" in data.fusion_traits:
		body += '<g data-organ="reflector"><path d="M10 29 Q27 18 34 -15" fill="none" stroke="#759c87" stroke-width="3"/><path d="M32 -36 L42 -25 L38 -8 L25 -17Z" fill="#98cdd2" stroke="#3d6973" stroke-width="1.8"/><path d="M32 -32 L38 -24 L35 -13 L29 -18Z" fill="#eaffff"/><path d="M31 -26 L37 -22 M29 -21 L35 -17" stroke="#acdfe8" stroke-width="1.2"/><path d="M27 -29 Q17 -34 13 -21 M18 -23 L13 -21 L14 -27" fill="none" stroke="#9ed3de" stroke-width="1.5"/></g>'
	if "pressure" in data.fusion_traits:
		body += '<g data-organ="pressure-store"><path d="M4 22 L8 6 L17 6 L20 23Z" fill="#b9ca8b" stroke="#556b45"/><path d="M7 17 L18 17 M8 11 L17 11" stroke="#8a9c6a"/><circle cx="13" cy="10" r="2" fill="#f3daa2"/></g>'
	if "umbrella" in data.fusion_traits:
		body += '<g data-organ="canopy"><path d="M-9 -34 Q-14 -49 -28 -42 Q-41 -43 -42 -28 L-31 -33 L-20 -28Z" fill="#afcc90" stroke="#547055"/><path d="M-28 -42 L-29 -33 L-33 1" fill="none" stroke="#699a70" stroke-width="1.4"/></g>'
	if "split" in data.fusion_traits:
		body += '<path data-organ="split-pod" d="M-5 20 L1 10 L7 19 L13 9 L19 18 L15 29 L0 30Z" fill="#c3ddb2" stroke="#698867"/><path d="M3 23 L7 18 L12 23" fill="none" stroke="#eef2c6"/>'
	if "rear" in data.fusion_traits:
		body += '<g data-organ="rear-bud"><path d="M-8 4 L-31 4 L-35 12 L-13 17Z" fill="#a9c488" stroke="#476247"/><ellipse cx="-34" cy="8" rx="3" ry="5" fill="#3b5443"/></g>'
	if "revive" in data.fusion_traits:
		body += '<path data-organ="phoenix-bud" d="M-5 -42 Q-17 -49 -13 -54 Q-7 -53 -3 -49 Q-1 -57 4 -54 Q10 -47 4 -41Z" fill="#f3c785" stroke="#a47756"/>'
	body += '<path d="M-18 31 Q0 24 19 31" fill="none" stroke="#d4dfb5" stroke-width="1.2"/>'
	return '<!-- combat anatomy --><g data-combat-anatomy="%d">%s</g><!-- /combat anatomy -->' % [seed,body]

static func enhance_svg(svg: String, id: String, data: Dictionary) -> String:
	var seed: int = ("0x"+id.md5_text().substr(0,7)).hex_to_int()
	var re := RegEx.new(); re.compile('(?s)<!-- combat anatomy -->.*?<!-- /combat anatomy -->')
	svg = re.sub(svg,'',true)
	re.compile(' data-geometry-signature="[^"]*"')
	svg = re.sub(svg,'',true)
	svg = svg.replace('</svg>',combat_anatomy(data,seed)+'</svg>')
	var mark: String = svg.md5_text()
	return svg.replace('<svg ','<svg data-geometry-signature="%s" ' % mark)
