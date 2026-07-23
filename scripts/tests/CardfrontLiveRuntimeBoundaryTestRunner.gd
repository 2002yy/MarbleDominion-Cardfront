extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontLiveRuntimeBoundaryTest] Starting live runtime boundary tests")
	await process_frame

	await _test_default_cardfront_uses_live_runtime_only()
	await _test_legacy_compatibility_is_explicit()
	await _test_ballwar_is_unchanged()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontLiveRuntimeBoundaryTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_default_cardfront_uses_live_runtime_only() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, false)
	var runtime = main.runtime

	_assert.that(runtime.region_map != null, "live: region map should exist")
	_assert.that(runtime.stronghold_system != null, "live: tactical stronghold system should exist")
	_assert.that(runtime.fortify_layer != null, "live: territory defense storage should exist")
	_assert.that(runtime.territory_defense_system != null, "live: territory defense system should exist")
	_assert.that(runtime.fire_director != null, "live: volley fire director should exist")
	_assert.that(runtime.round_director != null, "live: round director should exist")
	_assert.that(runtime.direction_controller != null, "live: direction controller should exist")
	_assert.that(runtime.aim_control != null, "live: aim control should exist")
	_assert.that(runtime.three_choice_panel != null, "live: three-choice panel should exist")

	var retired_refs: Dictionary = {
		"economy": runtime.economy_system,
		"morale": runtime.morale_system,
		"fixed card system": runtime.card_system,
		"target bias": runtime.target_bias_system,
		"devices": runtime.device_layer,
		"legacy target preview": runtime.target_preview_layer,
		"debug panel": runtime.debug_action_panel,
		"fixed hand": runtime.hand_panel,
		"resource minibar": runtime.top_resource_bar,
		"legacy feedback bus": runtime.cardfront_feedback_bus,
	}
	for label in retired_refs.keys():
		_assert.eq(retired_refs[label], null, "live: default path should not construct %s" % label)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_legacy_compatibility_is_explicit() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT, true)
	var runtime = main.runtime

	_assert.that(runtime.economy_system != null, "compatibility: economy should be available when explicitly enabled")
	_assert.that(runtime.morale_system != null, "compatibility: morale should be available when explicitly enabled")
	_assert.that(runtime.card_system != null, "compatibility: fixed card system should be available when explicitly enabled")
	_assert.that(runtime.target_bias_system != null, "compatibility: target bias should be available when explicitly enabled")
	_assert.that(runtime.device_layer != null, "compatibility: devices should be available when explicitly enabled")
	_assert.that(runtime.hand_panel != null, "compatibility: fixed hand should be available when explicitly enabled")
	_assert.that(runtime.top_resource_bar != null, "compatibility: resource minibar should be available when explicitly enabled")
	_assert.that(runtime.round_director != null, "compatibility: the current round director should still exist")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_is_unchanged() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC, false)
	_assert.eq(main.runtime.round_director, null, "BallWar: should not create Cardfront round director")
	_assert.eq(main.runtime.stronghold_system, null, "BallWar: should not create Cardfront strongholds")
	_assert.eq(main.runtime.territory_defense_system, null, "BallWar: should not create Cardfront territory defense")
	_assert.eq(main.runtime.three_choice_panel, null, "BallWar: should not create Cardfront choice panel")

	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String, compatibility_enabled: bool):
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.cardfront_legacy_compatibility_enabled = compatibility_enabled
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
