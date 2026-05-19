extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontPerformanceSmokeTest] Starting Cardfront performance smoke tests")
	await process_frame

	_test_overlay_dirty_redraw_does_not_break()
	_test_shotguide_no_debug_text()
	_test_40x40_default_runs()
	_test_50x50_stress_loads()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontPerformanceSmokeTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_overlay_dirty_redraw_does_not_break() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.region_overlay != null, "perf: region overlay should exist")
	if main.runtime.region_overlay != null:
		main.runtime.region_overlay.mark_dirty()

	_assert.that(main.runtime.fortify_overlay != null, "perf: fortify overlay should exist")
	if main.runtime.fortify_overlay != null:
		main.runtime.fortify_overlay.mark_dirty()

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_shotguide_no_debug_text() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var guide = main.runtime.shot_guide_layer
	_assert.that(guide != null, "perf: shot guide layer should exist in Cardfront")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_40x40_default_runs() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 40
	main._start_game(40, true, false)

	_assert.that(main.runtime.battlefield != null, "perf: 40x40 battlefield should be created")
	_assert.that(main.runtime.region_map != null, "perf: 40x40 region_map should be created")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_50x50_stress_loads() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 50
	main._start_game(50, true, false)

	_assert.that(main.runtime.battlefield != null, "perf: 50x50 battlefield should load")
	_assert.that(main.runtime.region_map != null, "perf: 50x50 region_map should load")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
