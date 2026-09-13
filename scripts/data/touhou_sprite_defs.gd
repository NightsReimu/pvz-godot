extends RefCounted

# One opaque idle silhouette calibration per character; never rescale each pose.
# Height excludes transparent canvas padding and faint spell glows.
const BODY_HEIGHT := 180.0
const IDLE_HEIGHTS := {
	"kaguya_boss": 208.0,
	"eirin_boss": 216.0,
	"tewi_boss": 222.0,
	"reisen_boss": 247.0,
	"alice_boss": 242.0,
	"chen_boss": 225.0,
	"cirno_boss": 204.0,
	"daiyousei_boss": 178.0,
	"flandre_boss": 210.0,
	"keine_boss": 246.0,
	"koakuma_boss": 205.0,
	"letty_boss": 181.0,
	"lily_white_boss": 210.0,
	"marisa_boss": 232.0,
	"meiling_boss": 200.0,
	"mystia_boss": 223.0,
	"patchouli_boss": 197.0,
	"prismriver_boss": 150.0,
	"ran_boss": 198.0,
	"reimu_boss": 227.0,
	"remilia_boss": 216.0,
	"rumia_boss": 245.0,
	"sakuya_boss": 250.0,
	"wriggle_boss": 228.0,
	"youmu_boss": 219.0,
	"yukari_boss": 210.0,
	"yuyuko_boss": 201.0,
}

const IDLE_BOTTOM := {
	"kaguya_boss": 236.0,
	"eirin_boss": 246.0,
	"tewi_boss": 246.0,
	"reisen_boss": 253.0,
	"alice_boss": 262.0,
	"chen_boss": 243.0,
	"cirno_boss": 230.0,
	"daiyousei_boss": 197.0,
	"flandre_boss": 247.0,
	"keine_boss": 262.0,
	"koakuma_boss": 220.0,
	"letty_boss": 213.0,
	"lily_white_boss": 240.0,
	"marisa_boss": 247.0,
	"meiling_boss": 232.0,
	"mystia_boss": 256.0,
	"patchouli_boss": 231.0,
	"prismriver_boss": 216.0,
	"ran_boss": 226.0,
	"reimu_boss": 249.0,
	"remilia_boss": 240.0,
	"rumia_boss": 259.0,
	"sakuya_boss": 262.0,
	"wriggle_boss": 256.0,
	"youmu_boss": 242.0,
	"yukari_boss": 241.0,
	"yuyuko_boss": 233.0,
}

static func draw_scale(kind: String) -> float:
	return BODY_HEIGHT / float(IDLE_HEIGHTS.get(kind, BODY_HEIGHT))

static func top_offset(kind: String) -> float:
	return 32.0 - float(IDLE_BOTTOM.get(kind, 256.0)) * draw_scale(kind)
