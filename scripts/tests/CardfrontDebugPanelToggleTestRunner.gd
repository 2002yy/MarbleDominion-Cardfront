extends SceneTree

const CardfrontDebugActionPanelScript = preload("res://scripts/cardfront/debug/CardfrontDebugActionPanel.gd")
const CardfrontTopResourceBarScene = preload("res://scenes/ui/cardfront/CardfrontTopResourceBar.tscn")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDebugPanelToggleTest] Starting debug panel toggle tests")
	await process_frame

	_test_cardfront_debug_panel_default_hidden()
	await _test_f3_routes_through_scene_tree()
	_test_formal_ui_debug_hint()
	_test_release_debug_panel_stays_hidden()
	await _test_release_debug_hint_hidden()
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


func _send_f3_to_tree() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_F3
	event.physical_keycode = KEY_F3
	event.pressed = true
	Input.parse_input_event(event)


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


func _test_f3_routes_through_scene_tree() -> void:
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	var panel = main.runtime.debug_action_panel
	if panel != null:
		_send_f3_to_tree()
		await _flush()
		_assert.that(panel.visible, "debug panel: parsed F3 input should show panel")
		_send_f3_to_tree()
		await _flush()
		_assert.that(not panel.visible, "debug panel: parsed second F3 input should hide panel")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_formal_ui_debug_hint() -> void:
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	var bar = main.runtime.top_resource_bar
	_assert.that(bar != null, "debug panel: Cardfront should create formal top resource bar")
	if bar != null:
		_assert.that(bar.is_debug_hint_visible_for_test(), "debug panel: Cardfront formal UI should show F3 Debug hint in non-release")
		_assert.eq(bar.get_debug_hint_text_for_test(), "F3 Debug", "debug panel: formal UI hint text should be F3 Debug")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_release_debug_panel_stays_hidden() -> void:
	var panel = CardfrontDebugActionPanelScript.new()
	get_root().add_child(panel)
	panel.set_release_mode_override_for_test(true)
	panel.setup(null, null, null, null, GameConfig.GAME_MODE_CARDFRONT)
	_assert.that(not panel.is_toggle_allowed_for_test(), "debug panel: release builds should not allow F3 toggle")
	_assert.that(not panel.visible, "debug panel: release builds should keep debug panel hidden")
	_assert.eq(panel.toggle_debug_panel(), false, "debug panel: release toggle should return false")
	_assert.that(not panel.visible, "debug panel: release toggle should not show panel")
	TestFixtures.cleanup_node(panel)


func _test_release_debug_hint_hidden() -> void:
	var bar = CardfrontTopResourceBarScene.instantiate()
	get_root().add_child(bar)
	await _flush()
	bar.set_release_mode_override_for_test(true)
	var states := {
		CardfrontRulesScript.PLAYER_FACTION: CardfrontResourceStateScript.new(),
		CardfrontRulesScript.AI_FACTION: CardfrontResourceStateScript.new(),
	}
	bar.setup(null, states, GameConfig.GAME_MODE_CARDFRONT)
	_assert.that(bar.visible, "debug panel: release top resource bar should still be visible in Cardfront")
	_assert.that(not bar.is_debug_hint_visible_for_test(), "debug panel: release builds should hide F3 Debug hint")
	TestFixtures.cleanup_node(bar)


func _test_ballwar_has_no_debug_panel() -> void:
	var main = _make_main(GameConfig.GAME_MODE_BASIC)
	_assert.eq(main.runtime.debug_action_panel, null, "debug panel: BallWar mode should not create Cardfront debug panel")
	_assert.eq(main.runtime.top_resource_bar, null, "debug panel: BallWar mode should not create Cardfront top resource bar")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
