extends SceneTree

# Verifies that the 6 new challenge branch levels exist, have objectives, and are
# properly gated via unlock_requirements (the branch infra the game already has).

const GameDefs = preload("res://scripts/game_defs.gd")

func _initialize():
	print("challenge_branch_test start")

	var challenge_ids = ["1-S1", "2-S1", "3-S1", "4-S1", "5-S1", "6-S1"]
	var expected_types = {
		"1-S1": "protect_plants",
		"2-S1": "sun_budget",
		"3-S1": "column_defense",
		"4-S1": "no_mower",
		"5-S1": "time_limit",
		"6-S1": "max_plant_loss",
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
