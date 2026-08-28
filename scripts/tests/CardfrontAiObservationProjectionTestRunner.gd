extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ObservationBuilderScript = preload("res://scripts/cardfront/ai/CardfrontAiObservationBuilder.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontAiObservationProjectionTest] Starting P0-10A6-A7 projection tests")
	await process_frame
	_test_own_state_projection_is_detached()
	await _test_live_context_is_observation_derived()
	_assert.report("[CardfrontAiObservationProjectionTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_own_state_projection_is_detached() -> void:
	var state = RunStateScript.new()
	state.setup_from_hero(RulesScript.AI_FACTION, "fortification_engineer")
	state.selected_upgrade_levels["volley_plus_5"] = 2
	state.applied_upgrade_counts["volley_plus_5"] = 3
	var projected: Dictionary = ObservationBuilderScript.project_own_state(state)
	_assert.eq(str(projected.get("hero_id", "")), "fortification_engineer", "own projection: hero is explicit")
	_assert.eq(int((projected.get("selected_upgrade_levels", {}) as Dictionary).get("volley_plus_5", 0)), 2, "own projection: selected levels are explicit")
	_assert.that(not projected.has("owner_id"), "own projection: unneeded owner identity defaults invisible")
	_assert.that(not projected.has("command_chamber_health"), "own projection: unneeded health object field defaults invisible")
	_assert.that(not projected.has("pending_entity_actions"), "own projection: mutable action queue defaults invisible")
	state.selected_upgrade_levels["volley_plus_5"] = 9
	_assert.eq(int((projected.get("selected_upgrade_levels", {}) as Dictionary).get("volley_plus_5", 0)), 2, "own projection: nested values are detached")
	_assert.that(ObservationBuilderScript.is_pure_observation({ObservationBuilderScript.OWN_PRIVATE_STATE: projected}), "own projection: no RunState object escapes")


func _test_live_context_is_observation_derived() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var observation: Dictionary = director.get_ai_observation(RulesScript.AI_FACTION)
	var context: Dictionary = director.get_upgrade_value_context(RulesScript.AI_FACTION)
	var expected: Dictionary = ObservationBuilderScript.valuation_context(observation)
	_assert.eq(context, expected, "context facade: output is derived exclusively from observation")
	_assert.that(ObservationBuilderScript.is_pure_observation(observation), "live observation: runtime output is recursively pure")
	_assert.that(not _contains_key_recursive(observation, "run_state"), "live observation: full RunState reference is absent")
	_assert.that(not _contains_key_recursive(observation, "source"), "live observation: obsolete free-form source key is absent")
	_assert.that(context.has("round_number") and context.has("enemy_defense_points"), "context facade: approved live valuation fields survive")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await process_frame


func _start_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await process_frame
	await process_frame
	return main


func _contains_key_recursive(value, target_key: String) -> bool:
	if value is Dictionary:
		for key in (value as Dictionary).keys():
			if str(key) == target_key or _contains_key_recursive((value as Dictionary)[key], target_key):
				return true
	elif value is Array:
		for item in value as Array:
			if _contains_key_recursive(item, target_key):
				return true
	return false
