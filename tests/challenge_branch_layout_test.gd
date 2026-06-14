extends SceneTree

# Verifies the 42 challenge branches (6 per world) fork from a mainline level and that
# their map nodes don't overlap other nodes in the same world.

const GameDefs = preload("res://scripts/game_defs.gd")

func _initialize():
	print("challenge_branch_layout_test start")

	var expected_fork = {
		"1-S1": "1-5", "1-S2": "1-3", "1-S3": "1-7", "1-S4": "1-10", "1-S5": "1-13", "1-S6": "1-16", "1-S7": "1-8",
		"2-S1": "2-8", "2-S2": "2-3", "2-S3": "2-5", "2-S4": "2-9", "2-S5": "2-12", "2-S6": "2-15", "2-S7": "2-16",
		"3-S1": "3-8", "3-S2": "3-3", "3-S3": "3-5", "3-S4": "3-9", "3-S5": "3-11", "3-S6": "3-14", "3-S7": "3-16",
		"4-S1": "4-8", "4-S2": "4-3", "4-S3": "4-6", "4-S4": "4-9", "4-S5": "4-11", "4-S6": "4-14", "4-S7": "4-16",
		"5-S1": "5-8", "5-S2": "5-3", "5-S3": "5-6", "5-S4": "5-9", "5-S5": "5-12", "5-S6": "5-14", "5-S7": "5-16",
		"6-S1": "6-8", "6-S2": "6-3", "6-S3": "6-6", "6-S4": "6-9", "6-S5": "6-12", "6-S6": "6-15", "6-S7": "6-18",
	}

	var by_id = {}
	for lv in GameDefs.LEVELS:
		by_id[String(lv.get("id", ""))] = lv

	for cid in expected_fork.keys():
		assert(by_id.has(cid), "challenge level %s should exist" % cid)
		var level = by_id[cid]
		# branch_from present and correct
		assert(String(level.get("branch_from", "")) == expected_fork[cid], "%s should branch_from %s, got '%s'" % [cid, expected_fork[cid], String(level.get("branch_from", ""))])
		# branch_from target exists
		var src_id = String(level["branch_from"])
		assert(by_id.has(src_id), "%s branch_from target %s should exist" % [cid, src_id])
		# branch_from target is a MAINLINE level (no unlock_requirements => not a branch)
		var src = by_id[src_id]
		assert(not src.has("unlock_requirements"), "%s fork source %s should be a mainline level (no unlock_requirements)" % [cid, src_id])
		# unlock_requirements aligns with branch_from
		var reqs = level.get("unlock_requirements", [])
		assert(reqs is Array and reqs.size() == 1 and String(reqs[0]) == expected_fork[cid], "%s unlock_requirements should be [%s]" % [cid, expected_fork[cid]])
		print("%s: forks from %s - OK" % [cid, src_id])

	# No node overlap within each world (challenge node vs every other node in same world).
	var world_of = func(level: Dictionary) -> String:
		return String(level.get("id", "")).split("-")[0]
	for cid in expected_fork.keys():
		var level = by_id[cid]
		var cnode = Vector2(level["node_pos"])
		var cworld = world_of.call(level)
		for lv in GameDefs.LEVELS:
			if String(lv.get("id", "")) == cid:
				continue
			if world_of.call(lv) != cworld:
				continue
			var d = cnode.distance_to(Vector2(lv["node_pos"]))
			assert(d > 80.0, "%s node too close to %s (%.1fpx, need >80)" % [cid, String(lv.get("id", "")), d])

	print("challenge_branch_layout_test PASS")
	quit(0)
