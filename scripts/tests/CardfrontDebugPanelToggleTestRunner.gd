extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDebugPanelToggleTest] Starting debug panel toggle tests")
	await process_frame

	_test_cardfront_debug_panel_default_hidden()
	_test_f3_toggles_debug_panel()
	_test_ballwar_has_no_debug_panel()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontDebugPanelToggleTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_main(mode_name: String):
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(mode_name)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	return main


func _press_f3(panel) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_F3
	event.physical_keycode = KEY_F3
	event.pressed = true
	panel._unhandled_input(event)


func _test_cardfront_debug_panel_default_hidden() -> void:
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	var panel = main.runtime.debug_action_panel
	_assert.that(panel != null, "debug panel: Cardfront should create debug panel node")
	if panel != null:
		_assert.that(not panel.visible, "debug panel: default should be hidden")
		_assert.that(panel.get_button_count_for_test() > 0, "debug panel: hidden panel should keep dev buttons available")
		_assert.that(panel.is_toggle_allowed_for_test(), "debug panel: F3 toggle should be available in non-release test build")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_f3_toggles_debug_panel() -> void:
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	var panel = main.runtime.debug_action_panel
	if panel != null:
		_press_f3(panel)
		_assert.that(panel.visible, "debug panel: F3 should show panel")
		_press_f3(panel)
		_assert.that(not panel.visible, "debug panel: second F3 should hide panel")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_has_no_debug_panel() -> void:
	var main = _make_main(GameConfig.GAME_MODE_BASIC)
	_assert.eq(main.runtime.debug_action_panel, null, "debug panel: BallWar mode should not create Cardfront debug panel")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
