extends RefCounted
# Presentation themes for the Touhou bosses outside Mountain of Faith: the
# colours and sigil glyph used by their spell seals, magic circles, auras and
# declaration banners. Wind God themes stay in wind_god_fx.gd.

const CANON := {
	"rumia_boss": {"main": Color("7d62b8"), "accent": Color("e2475c"), "glyph": "moon"},
	"daiyousei_boss": {"main": Color("7fdc9a"), "accent": Color("f4f0a8"), "glyph": "flower"},
	"cirno_boss": {"main": Color("7fd8ff"), "accent": Color("e8fbff"), "glyph": "snow"},
	"meiling_boss": {"main": Color("5fd08a"), "accent": Color("f0645a"), "glyph": "rainbow"},
	"koakuma_boss": {"main": Color("d0566e"), "accent": Color("f4d6e2"), "glyph": "book"},
	"patchouli_boss": {"main": Color("b48be8"), "accent": Color("f0d27a"), "glyph": "element"},
	"sakuya_boss": {"main": Color("9fd4ec"), "accent": Color("eef2fa"), "glyph": "clock"},
	"remilia_boss": {"main": Color("e5485e"), "accent": Color("b48cf0"), "glyph": "bat"},
	"flandre_boss": {"main": Color("f2584a"), "accent": Color("f6d86a"), "glyph": "crystal"},
	"letty_boss": {"main": Color("b8dcff"), "accent": Color("ffffff"), "glyph": "snow"},
	"chen_boss": {"main": Color("f0a050"), "accent": Color("7ccc7a"), "glyph": "pentagram"},
	"alice_boss": {"main": Color("8ab0f0"), "accent": Color("f0d080"), "glyph": "doll"},
	"lily_white_boss": {"main": Color("f8eed0"), "accent": Color("f0a0b8"), "glyph": "flower"},
	"prismriver_boss": {"main": Color("c8a0f0"), "accent": Color("f0e0a0"), "glyph": "note"},
	"youmu_boss": {"main": Color("a8f0d8"), "accent": Color("f0b8cc"), "glyph": "sword"},
	"yuyuko_boss": {"main": Color("f2a0c8"), "accent": Color("a8d8f0"), "glyph": "butterfly"},
	"ran_boss": {"main": Color("f0cf6a"), "accent": Color("f08040"), "glyph": "fox"},
	"yukari_boss": {"main": Color("b080f0"), "accent": Color("f070a0"), "glyph": "gap"},
	"wriggle_boss": {"main": Color("90e070"), "accent": Color("f4f480"), "glyph": "firefly"},
	"mystia_boss": {"main": Color("d090e0"), "accent": Color("f0c070"), "glyph": "feather"},
	"keine_boss": {"main": Color("80c8e0"), "accent": Color("a0e090"), "glyph": "scroll"},
	"hakutaku_boss": {"main": Color("a0e090"), "accent": Color("80c0e0"), "glyph": "scroll"},
	"tewi_boss": {"main": Color("f0b8c8"), "accent": Color("a0e090"), "glyph": "clover"},
	"reimu_boss": {"main": Color("f05a6a"), "accent": Color("f8f0e8"), "glyph": "yinyang"},
	"marisa_boss": {"main": Color("f8d060"), "accent": Color("80c0ff"), "glyph": "star"},
	"reisen_boss": {"main": Color("f06090"), "accent": Color("a8a8f8"), "glyph": "eye"},
	"eirin_boss": {"main": Color("f08898"), "accent": Color("88a8f0"), "glyph": "arrow"},
	"kaguya_boss": {"main": Color("f0b0d0"), "accent": Color("f0e090"), "glyph": "jewel"},
	"mokou_boss": {"main": Color("ff8050"), "accent": Color("ffd070"), "glyph": "flame"},
	"suika_boss": {"main": Color("f0a060"), "accent": Color("d8b080"), "glyph": "gourd"},
}

static func has(kind: String) -> bool:
	return CANON.has(kind)
