extends RefCounted

# One combat owner, three bodies. Rendering and every collision query use this
# same geometry; there are no duplicate zombie entries, loot or phase tracks.
const MEMBERS := ["lunasa", "merlin", "lyrica"]
const HEIGHTS := [244.0, 249.0, 236.0]
const COLORS := [Color("ef5474"), Color("8a94ff"), Color("ffc4dc")]
const ART := ["violin_resonance", "trumpet_resonance", "keyboard_resonance"]
static var textures: Dictionary = {}


static func texture(member: int, frame: int) -> Texture2D:
	member = clampi(member, 0, 2)
	frame = clampi(frame, 0, 23)
	var key := "%d:%d" % [member, frame]
	if not textures.has(key):
		var folder: String = "res://art/prismriver" if member == 0 else "res://art/prismriver/" + MEMBERS[member]
		var path := "%s/frame_%02d.png" % [folder, frame]
		textures[key] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return textures[key] as Texture2D


static func bodies(game: Control, boss: Dictionary) -> Array[Dictionary]:
	var rows: Array = game.active_rows
	if rows.is_empty():
		rows = [0, 1, 2, 3, 4]
	var first := maxi(0, rows.find(int(boss.get("row", 2))))
	var clock := float(boss.get("prismriver_time", 0.0))
	var bounds: Dictionary = game._prismriver_boss_bounds()
	var result: Array[Dictionary] = []
	for member in range(3):
		var row := int(rows[(first + member * maxi(1, (rows.size() + 2) / 3)) % rows.size()])
		var offset: float = [-38.0, 24.0, -8.0][member]
		var x := clampf(float(boss.get("x", bounds.max_x)) + offset + sin(clock * (0.64 + member * 0.11) + member * 2.1) * 12.0, float(bounds.min_x), float(bounds.max_x))
		result.append({"member": member, "row": row, "position": Vector2(x, game._row_center_y(row))})
	return result


static func frame(boss: Dictionary, member: int, clock: float) -> int:
	var sequence: Array = [0, 1, 2, 1]
	var pose := String(boss.get("rumia_state", "idle"))
	var solo := ["lunasa", "merlin", "lyrica"].find(pose)
	if float(boss.get("impact_timer", 0.0)) > 0.0:
		sequence = [12, 13, 14]
	elif pose == "shift":
		sequence = [3, 4, 5, 4]
	elif solo == member:
		sequence = [6, 7, 8, 7]
	elif solo >= 0:
		sequence = [9, 10, 11, 10]
	elif pose in ["concerto", "live_poltergeist", "phase", "riverside", "wheel"]:
		sequence = [18, 19, 20, 23]
	elif pose == "phantom_dinning":
		sequence = [15, 16, 17, 16]
	return int(sequence[posmod(int(clock * 7.0 + member), sequence.size())])


static func draw_member(game: Control, center: Vector2, boss: Dictionary, member: int, clock: float) -> void:
	var pose := frame(boss, member, clock)
	var image: Texture2D = game._try_get_boss_frame_texture("prismriver_boss", pose) if member == 0 else texture(member, pose)
	if image == null:
		return
	var scale := 180.0 / float(HEIGHTS[member])
	var bob := sin(clock * 2.6 + member * 2.1) * 3.0
	var foot := center + Vector2(0.0, 54.0 + bob)
	game.draw_texture_rect(image, Rect2(foot - Vector2(256, 320) * scale, image.get_size() * scale), false, Color(1, 1, 1, 1.0 - float(boss.get("flash", 0.0)) * 0.25))
