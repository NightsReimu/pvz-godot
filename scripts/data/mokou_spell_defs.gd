extends RefCounted

# TH08 Extra 192–205. Last Spell 205 is always available in this adaptation.
const KEINE := [
	["th08-192", "旧史「旧秘境史 -Old History-」", "hakutaku_old", "shot"],
	["th08-193", "转世「一条归桥」", "hakutaku_bridge", "special"],
	["th08-194", "新史「新幻想史 -Next History-」", "hakutaku_next", "final"],
]
const MOKOU := [
	["th08-195", "时效「月之岩笠的诅咒」", "mokou_iwakasa", "shot"],
	["th08-196", "不死「火鸟 -凤翼天翔-」", "mokou_firebird", "special"],
	["th08-197", "藤原「灭罪寺院伤」", "mokou_temple", "shot"],
	["th08-198", "不死「徐福时空」", "mokou_xufu", "phase"],
	["th08-199", "灭罪「正直者之死」", "mokou_honest", "special"],
	["th08-200", "虚人「无」", "mokou_wu", "phase"],
	["th08-201", "不灭「不死鸟之尾」", "mokou_tail", "special"],
	["th08-202", "蓬莱「凯风快晴 -Fujiyama Volcano-」", "mokou_fujiyama", "final", {"duration": 8.4}],
	["th08-203", "「Possessed by Phoenix」", "mokou_possessed", "final", {"duration": 16.0, "survival": true, "last_spell": true}],
	["th08-204", "「蓬莱人形」", "mokou_hourai", "final", {"duration": 10.0, "last_spell": true}],
	["th08-205", "「Imperishable Shooting」", "mokou_imperishable", "final", {"duration": 18.0, "survival": true, "last_spell": true}],
]

static func cards(kind: String) -> Array:
	return (KEINE if kind == "hakutaku_boss" else MOKOU).duplicate(true)

static func phases(kind: String, level: Dictionary) -> Array:
	var result: Array = []
	var plus := String(level.get("touhou_difficulty", "extra")) == "extra_plus"
	for entry in cards(kind):
		var attacks: Array = []
		# Keine's Extra road has three consecutive spells. Mokou's first eight have nonspells.
		if kind == "mokou_boss" and int(String(entry[0]).trim_prefix("th08-")) <= 202:
			attacks.append(["adapted-mokou-nonspell", "非符 · 不死的烟幕", "nonspell_mokou", "shot"])
		attacks.append(entry)
		result.append(attacks)
	if kind == "hakutaku_boss":
		if plus: result.insert(2, [["original-hakutaku-seal", "原创 · 编年「封存的花圃」", "hakutaku_archive", "special", {"duration": 7.0}]])
	else:
		result.insert(3, [["original-mokou-pingpong", "原创 · 炎游「烈焰乒乓」", "mokou_pingpong", "shot", {"duration": 10.0}]])
		result.insert(7, [["original-mokou-embers", "原创 · 灰烬「不熄的种植格」", "mokou_embers", "phase", {"duration": 8.0}]])
		if plus:
			result.insert(result.size()-3, [["original-mokou-double", "原创 · 双炎「左右连打」", "mokou_double_rally", "special", {"duration": 12.0}]])
			result.insert(result.size()-3, [["original-mokou-rebirth", "原创 · 涅槃「火圈再生」", "mokou_rebirth", "final", {"duration": 9.0}]])
	return result
