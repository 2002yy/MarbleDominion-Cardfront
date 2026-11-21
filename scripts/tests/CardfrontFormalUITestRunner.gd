extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontFormalUITest] Checking live formal UI")
	await process_frame
	await _test_live_edge_controls()
	GameConfig.reset_runtime_defaults()
	await _flush()
	_assert.report("[CardfrontFormalUITest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_live_edge_controls() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()

	_assert.that(main.runtime.three_choice_panel != null, "live UI: three-choice panel should exist")
	_assert.that(main.runtime.region_info_panel != null, "live UI: region info panel should exist")
	var settings_button = main.runtime.hud.get("settings_button", null)
	var pause_button = main.runtime.hud.get("pause_button", null)
	var exit_button = main.runtime.hud.get("exit_button", null)
	_assert.that(settings_button != null, "live UI: settings button should exist")
	_assert.that(pause_button != null, "live UI: pause button should exist")
	_assert.that(exit_button != null, "live UI: exit button should exist")
	if main.runtime.region_info_panel != null:
		main.runtime.region_info_panel.update_for_cell(Vector2i(-1, -1))
		await _flush()
		var region_panel = main.runtime.region_info_panel._panel
		if region_panel != null and settings_button != null and pause_button != null and exit_button != null:
			var region_rect := Rect2(region_panel.global_position, region_panel.size)
			var settings_rect := Rect2(settings_button.global_position, settings_button.size)
			_assert.that(not settings_rect.intersects(region_rect), "live UI: settings and region panels must not overlap")
			_assert.that(settings_button.size.x <= 58.0 and settings_button.size.y <= 32.0, "live UI: compact settings size")
			_assert.gte(settings_button.global_position.x, 1000.0, "live UI: settings should be at right edge")
			_assert.eq(pause_button.global_position.y, settings_button.global_position.y, "live UI: pause and settings share a row")
			_assert.gt(pause_button.global_position.x, settings_button.global_position.x, "live UI: pause follows settings")
			_assert.that(not exit_button.visible, "live UI: exit stays behind pause menu")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _flush() -> void:
	await process_frame
	await process_frame
