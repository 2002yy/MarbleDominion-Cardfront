extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontLiveRuntimeBoundaryTest] Starting live runtime boundary tests")
	await process_frame

	await _test_default_cardfront_uses_live_runtime_only()
	await _test_ballwar_is_unchanged()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontLiveRuntimeBoundaryTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_default_cardfront_uses_live_runtime_only() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT)
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
	_assert.that(runtime.gate_connectivity_system != null, "live: gate connectivity system should exist")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_is_unchanged() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC)
	_assert.eq(main.runtime.round_director, null, "BallWar: should not create Cardfront round director")
	_assert.eq(main.runtime.stronghold_system, null, "BallWar: should not create Cardfront strongholds")
	_assert.eq(main.runtime.territory_defense_system, null, "BallWar: should not create Cardfront territory defense")
	_assert.eq(main.runtime.three_choice_panel, null, "BallWar: should not create Cardfront choice panel")
	_assert.eq(main.runtime.gate_connectivity_system, null, "BallWar: should not create Cardfront gate connectivity")
	_assert.eq(main.runtime.bullet_pool.route_filter, null, "BallWar: should not attach a Cardfront projectile route filter")

	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String):
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
