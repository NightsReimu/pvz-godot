extends SceneTree

# Verifies the 6 challenge branches fork from a mid-world mainline level and that
# their map nodes don't overlap other nodes in the same world.

const GameDefs = preload("res://scripts/game_defs.gd")

func _initialize():
	print("challenge_branch_layout_test start")

	var expected_fork = {
		"1-S1": "1-5",
		"2-S1": "2-8",
		"3-S1": "3-8",
		"4-S1": "4-8",
		"5-S1": "5-8",
		"6-S1": "6-8",
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
