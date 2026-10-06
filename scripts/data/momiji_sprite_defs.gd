extends RefCounted

const KIND := "momiji_boss"
const FRAME_FOLDER := "res://art/momiji"
const FRAME_COUNT := 24
const CANVAS := Vector2i(512, 384)
const PIVOT := Vector2i(256, 320)
const IDLE_HEIGHT := 245.0
const IDLE_BOTTOM := 320.0
const SOURCE_MANIFEST := "res://art/source_sheets/momiji/manifest.json"

# Source 21 remains an upright, active shield/aura pose. Only 22–23 crouch;
# do not inherit another character's 21–22 defeat slots for this sheet.
# The original direction, weapon reach and white-wolf tail remain unchanged.
const ACTIONS := {
	"idle": [0, 1, 2, 1],
	"arrival": [3, 4, 5, 4], "walk": [3, 4, 5, 4],
	"shift": [3, 4, 5, 4], "guard": [3, 4, 5, 4],
	"shot": [6, 7, 8, 7], "sweep": [6, 7, 8, 7],
	"sword": [9, 10, 11, 10], "cross": [9, 10, 11, 10],
	"patrol": [6, 7, 8, 7], "channel": [15, 16, 17, 16],
	"farsight": [15, 16, 17, 16], "protect": [15, 16, 17, 16],
	"phase": [15, 16, 17, 21], "final": [18, 19, 20, 21],
	"hit": [12, 13, 14], "defeat": [22, 23],
}

static func frame_index(boss: Dictionary, time: float) -> int:
	var state := String(boss.get("tengu_pose", boss.get("rumia_state", "idle")))
	if float(boss.get("health", 1.0)) <= 0.0:
		state = "defeat"
	elif float(boss.get("impact_timer", 0.0)) > 0.0:
		state = "hit"
	var sequence: Array = ACTIONS.get(state, ACTIONS.idle)
	var rate := 3.0 if state == "idle" else (10.0 if state == "hit" else 7.0)
	var tick := maxi(0, int(floor(time * rate + float(boss.get("anim_phase", 0.0)) * sequence.size())))
	return int(sequence[tick % sequence.size()])
