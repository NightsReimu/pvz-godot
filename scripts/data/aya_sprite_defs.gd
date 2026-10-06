extends RefCounted

const KIND := "aya_boss"
const FRAME_FOLDER := "res://art/aya"
const FRAME_COUNT := 24
const CANVAS := Vector2i(512, 384)
const PIVOT := Vector2i(256, 320)
const IDLE_HEIGHT := 236.0
const IDLE_BOTTOM := 319.0
const SOURCE_MANIFEST := "res://art/source_sheets/aya/manifest.json"

# Preserve the supplied upright face and fan. Dash afterimages, wind veiling
# and photographs are separate runtime effects; never rotate the whole canvas.
# 12–13 are hurt, 14 recovers; 21–22 bow/fall, while 23 is upright recovery.
const ACTIONS := {
	"idle": [0, 1, 2, 1],
	"arrival": [3, 4, 5, 4], "walk": [3, 4, 5, 4],
	"shift": [3, 4, 5, 4], "dash": [3, 4, 5, 4],
	"flight": [3, 4, 5, 4], "shot": [6, 7, 8, 7],
	"branch": [6, 7, 8, 7], "cross": [6, 7, 8, 7],
	"channel": [9, 10, 11, 10], "camera": [9, 10, 11, 10],
	"photo": [9, 10, 11, 10], "wind": [15, 16, 17, 16],
	"veil": [15, 16, 17, 16], "cyclone": [15, 16, 17, 16],
	"blockade": [15, 16, 17, 16], "survival": [18, 19, 20, 23],
	"phase": [15, 16, 17, 23], "final": [18, 19, 20, 23],
	"hit": [12, 13, 14], "defeat": [21, 22],
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
