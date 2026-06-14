extends SceneTree

# Verifies that the 42 challenge branch levels (6 per world) exist, have objectives, and are
# properly gated via unlock_requirements (the branch infra the game already has).

const GameDefs = preload("res://scripts/game_defs.gd")

func _initialize():
	print("challenge_branch_test start")

	var challenge_ids = [
		"1-S1", "1-S2", "1-S3", "1-S4", "1-S5", "1-S6", "1-S7",
		"2-S1", "2-S2", "2-S3", "2-S4", "2-S5", "2-S6", "2-S7",
		"3-S1", "3-S2", "3-S3", "3-S4", "3-S5", "3-S6", "3-S7",
		"4-S1", "4-S2", "4-S3", "4-S4", "4-S5", "4-S6", "4-S7",
		"5-S1", "5-S2", "5-S3", "5-S4", "5-S5", "5-S6", "5-S7",
		"6-S1", "6-S2", "6-S3", "6-S4", "6-S5", "6-S6", "6-S7",
	]
	var expected_types = {
		"1-S1": "protect_plants", "1-S2": "no_mower", "1-S3": "time_limit", "1-S4": "column_defense", "1-S5": "max_plant_loss", "1-S6": "sun_budget", "1-S7": "protect_plants",
		"2-S1": "sun_budget", "2-S2": "time_limit", "2-S3": "column_defense", "2-S4": "no_mower", "2-S5": "max_plant_loss", "2-S6": "protect_plants", "2-S7": "sun_budget",
		"3-S1": "column_defense", "3-S2": "no_mower", "3-S3": "max_plant_loss", "3-S4": "protect_plants", "3-S5": "sun_budget", "3-S6": "time_limit", "3-S7": "column_defense",
		"4-S1": "no_mower", "4-S2": "max_plant_loss", "4-S3": "protect_plants", "4-S4": "sun_budget", "4-S5": "time_limit", "4-S6": "column_defense", "4-S7": "no_mower",
		"5-S1": "time_limit", "5-S2": "protect_plants", "5-S3": "sun_budget", "5-S4": "time_limit", "5-S5": "column_defense", "5-S6": "no_mower", "5-S7": "max_plant_loss",
		"6-S1": "max_plant_loss", "6-S2": "time_limit", "6-S3": "column_defense", "6-S4": "no_mower", "6-S5": "max_plant_loss", "6-S6": "protect_plants", "6-S7": "sun_budget",
	}

	for cid in challenge_ids:
		var found = false
		var level = null
		for lv in GameDefs.LEVELS:
			if String(lv.get("id", "")) == cid:
				found = true
				level = lv
				break
		assert(found, "challenge level %s should exist" % cid)
		assert(level.has("objective"), "%s should have objective" % cid)
		assert(level.has("unlock_requirements"), "%s should have unlock_requirements (branch gate)" % cid)
		assert(level.has("branch_from"), "%s should have branch_from (forks from a mainline level)" % cid)
		var obj = level["objective"]
		assert(String(obj.get("type", "")) == expected_types[cid], "%s type should be %s" % [cid, expected_types[cid]])
		assert(String(obj.get("title", "")) != "", "%s should have title" % cid)
		print("%s: %s (%s) - OK" % [cid, level["title"], obj["type"]])

	# Verify _is_branch_level recognizes them (unlock_requirements presence)
	# We can't call game._is_branch_level here (no game instance), but we checked unlock_requirements above.

	print("challenge_branch_test PASS")
	quit(0)
