extends RefCounted

# Supplied pixel-art poses stay upright and unmirrored. Camouflage, rain and
# water rings are separate runtime layers; the sprite canvas is never tinted
# into a different character.
const KIND := "nitori_boss"
const FRAME_FOLDER := "res://art/nitori"
const FRAME_COUNT := 24
const CANVAS := Vector2i(512, 384)
const PIVOT := Vector2i(256, 320)
const IDLE_HEIGHT := 233.0
const IDLE_BOTTOM := 319.0
const SOURCE_MANIFEST := "res://art/source_sheets/nitori/manifest.json"

# 00–02 idle/blink, 03–05 stride, 06–08 water-gun charge and blast, 09–11
# punch/throw, 12–14 water channel, 15–17 hurt/recover, 18–20 grand water
# spells (20 is the full jet), 21–22 kneel/fallen, 23 recovered water stance.
const ACTIONS := {
	"idle": [0, 1, 0, 2],
	"arrival": [3, 4, 5, 4], "walk": [3, 4, 5, 4], "shift": [3, 4, 5, 4],
	"shot": [6, 7, 8, 7], "water": [6, 7, 8, 7], "cannon": [7, 8, 20, 8],
	"punch": [9, 10, 11, 10], "throw": [9, 10, 11, 10], "cucumber": [9, 10, 11, 10],
	"arm": [9, 10, 10, 11],
	"channel": [12, 13, 14, 13], "camouflage": [12, 13, 14, 13],
	"flood": [12, 13, 14, 23], "waterfall": [18, 19, 20, 19],
	"spin": [18, 19, 23, 19], "workshop": [13, 18, 20, 23],
	"phase": [13, 18, 23, 18], "final": [18, 19, 20, 23],
	"hit": [15, 16, 17], "defeat": [21, 22],
}

static func frame_index(boss: Dictionary, time: float) -> int:
	var state := String(boss.get("rumia_state", "idle"))
	if float(boss.get("health", 1.0)) <= 0.0:
		state = "defeat"
	elif float(boss.get("impact_timer", 0.0)) > 0.0 and float(boss.get("touhou_cast_remaining", 0.0)) <= 0.0:
		state = "hit"
	elif state == "idle" and float(boss.get("special_pause_timer", 0.0)) > 0.0:
		state = "shift"
	var frames: Array = ACTIONS.get(state, ACTIONS.idle)
	var speed := 2.6 if state == "idle" else (10.0 if state == "hit" else 6.0)
	var tick := maxi(0, int(floor(time * speed + float(boss.get("anim_phase", 0.0)) * frames.size())))
	return int(frames[tick % frames.size()])
