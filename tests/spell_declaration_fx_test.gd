extends "res://tests/touhou_spell_contract_test.gd"

const FX = preload("res://scripts/runtime/spell_declaration_fx.gd")

func _run() -> void:
	for kind in Spells.CARDS:
		check(FX.THEMES.has(kind), "%s must have a themed declaration" % kind)
		for cycle in range(Spells.CARDS[kind].size()):
			var game := make_game(kind, cycle)
			game._trigger_boss_skill(game.zombies[0])
			var runtime = game.touhou_danmaku
			var cast: Dictionary = runtime.casts[0]
			var nonspell: bool = cast.card.origin == "nonspell"
			var before: Dictionary = cast.duplicate(true)
			var bullets: Array = runtime.bullets.duplicate(true)
			var beams: Array = runtime.beams.duplicate(true)
			for age in [0.0, 0.15, 0.5, 1.3, 1.64]:
				var snapshot := cast.duplicate(true)
				snapshot.age = age
				var state := FX.state(snapshot)
				check(state.is_empty() == nonspell, "Only named spell cards receive a declaration")
				if not state.is_empty():
					check(float(state.alpha) >= 0 and float(state.alpha) <= 1, "Declaration opacity must stay bounded")
					check(state.name == cast.card.name, "Declaration must name the actual active card")
					check(FX.state(snapshot) == state, "A paused cast must hold the same visual state")
			check(cast == before and bullets == runtime.bullets and beams == runtime.beams, "Reading the visual effect must not change combat data, timers or damage")
			var expired := cast.duplicate(true)
			expired.age = FX.DURATION
			check(FX.state(expired).is_empty(), "Declaration must expire while the spell continues")
			runtime.clear_owner(int(cast.owner))
			check(runtime.casts.is_empty(), "Phase change/death must remove the declaration owner")
			release(game)
	print("Spell declaration themes, timing, ownership and immutable combat state: %d failure(s)" % failures)
	quit(1 if failures else 0)
