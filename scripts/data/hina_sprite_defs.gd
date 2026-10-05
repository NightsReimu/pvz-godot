extends RefCounted

# Original supplied poses remain upright. Only separately drawn ribbons or
# curse particles may orbit the boss; never rotate the entire sprite canvas.
const KIND := "hina_boss"
const FRAME_FOLDER := "res://art/hina"
const FRAME_COUNT := 24
const CANVAS := Vector2i(512, 384)
const PIVOT := Vector2i(256, 320)
const IDLE_HEIGHT := 233.0
const IDLE_BOTTOM := 319.0
const SOURCE_MANIFEST := "res://art/source_sheets/hina/manifest.json"

# Slots 12–13 are hurt/recovery and 21–22 are kneeling/fallen. Keep these
# reactions out of ongoing spell casts. Rotations use the authored wide-skirt
# poses and trails; they do not rotate, mirror or invert the character's face.
const ACTIONS := {
	"idle": [0, 1, 2, 1],
	"arrival": [3, 4, 5, 4], "walk": [3, 4, 5, 4], "shift": [3, 4, 5, 4],
	"shot": [6, 7, 8, 7], "spin": [6, 7, 8, 7],
	"rotation": [6, 7, 8, 7], "wheel": [18, 19, 20, 23],
	"channel": [9, 10, 11, 10], "purify": [9, 10, 11, 10],
	"ofuda": [9, 10, 11, 10], "doll": [15, 16, 17, 16],
	"curse": [15, 16, 17, 16], "misfortune": [15, 16, 17, 16],
	"drain": [15, 16, 17, 16], "ribbon": [18, 19, 20, 19],
	"phase": [15, 16, 17, 23], "final": [18, 19, 20, 23],
	"hit": [12, 13, 14], "defeat": [21, 22],
}

static func frame_index(boss: Dictionary, time: float) -> int:
	var state := String(boss.get("rumia_state", "idle"))
	if float(boss.get("health", 1.0)) <= 0.0:
		state = "defeat"
	elif float(boss.get("impact_timer", 0.0)) > 0.0:
		state = "hit"
	elif state == "idle" and float(boss.get("special_pause_timer", 0.0)) > 0.0:
		state = "shift"
	var frames: Array = ACTIONS.get(state, ACTIONS.idle)
	var speed := 3.0 if state == "idle" else (10.0 if state == "hit" else 6.0)
	var tick := maxi(0, int(floor(time * speed + float(boss.get("anim_phase", 0.0)) * frames.size())))
	return int(frames[tick % frames.size()])
