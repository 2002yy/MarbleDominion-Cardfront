extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontActionHintTest] Starting card action hint tests")
	await process_frame

	_test_each_card_shows_distinct_action_hint()
	_test_preview_pulse_is_active()
	_test_valid_target_hides_hint_after_play()
	_test_failed_play_hides_hint()
	_test_invalid_target_keeps_hint_and_selection()
	_test_right_click_cancels_selection()
	_test_escape_cancels_selection()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontActionHintTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_main():
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	return main


func _add_resources(main, energy: int = 999, parts: int = 999) -> void:
	var state = main.runtime.resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	if state != null:
		state.add_energy(energy)
		state.add_parts(parts)


func _first_valid_cell(main) -> Vector2i:
	var cells: Array = main.runtime.target_preview_layer._valid_cells
	if cells.is_empty():
		return Vector2i(-999, -999)
	return cells[0]


func _select_card(main, card_data: Dictionary) -> void:
	main.runtime.selection_controller.on_card_clicked(int(card_data.id), card_data)


func _expected_hint(card_id: int) -> String:
	match int(card_id):
		1001:
			return "前线加固：点击蓝色高亮的己方边界格，添加加固层"
		1002:
			return "校准射击：点击青色高亮的敌方区域，6 秒内优先射击该区域"
		1003:
			return "民心起伏：点击紫色高亮的己方区域，逐步提升区域控制"
		1004:
			return "拓荒信标：点击己方边界格，向周围中立格扩张"
	return ""


func _test_each_card_shows_distinct_action_hint() -> void:
	var main = _make_main()
	var hand_data: Array = main.runtime.card_system.get_hand_card_data()
	var seen: Dictionary = {}

	for card_data in hand_data:
		var card_id: int = int(card_data.id)
		_select_card(main, card_data)
		var hint: String = main.runtime.hand_panel.get_action_hint_text()
		_assert.that(main.runtime.hand_panel.is_action_hint_visible(), "hint: selecting card %d should show action hint" % card_id)
		_assert.eq(hint, _expected_hint(card_id), "hint: card %d should show expected copy" % card_id)
		_assert.that(not seen.has(hint), "hint: card %d should have distinct hint copy" % card_id)
		seen[hint] = true
		main.runtime.selection_controller.clear_selection()

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_preview_pulse_is_active() -> void:
	var main = _make_main()
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)

	var preview = main.runtime.target_preview_layer
	_assert.that(preview._valid_cells.size() > 0, "hint preview: selected card should expose valid target cells")
	_assert.that(preview.is_processing(), "hint preview: target preview should process while active for pulse")
	var alpha_before: float = preview.get_preview_pulse_alpha_for_test()
	preview._process(0.20)
	var alpha_after: float = preview.get_preview_pulse_alpha_for_test()
	_assert.that(not is_equal_approx(alpha_before, alpha_after), "hint preview: pulse alpha should breathe over time")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_valid_target_hides_hint_after_play() -> void:
	var main = _make_main()
	_add_resources(main)
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)
	var result: Dictionary = main.runtime.selection_controller.on_battlefield_clicked(_first_valid_cell(main))

	_assert.that(result.success, "hint: valid target should play card")
	_assert.that(not main.runtime.hand_panel.is_action_hint_visible(), "hint: successful play should hide action hint")
	_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "hint: successful play should clear selection")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_failed_play_hides_hint() -> void:
	var main = _make_main()
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)
	var result: Dictionary = main.runtime.selection_controller.on_battlefield_clicked(_first_valid_cell(main))

	_assert.that(not result.success, "hint: resource-poor valid target should fail")
	_assert.that(not main.runtime.hand_panel.is_action_hint_visible(), "hint: failed play should hide action hint")
	_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "hint: failed play should clear selection")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_invalid_target_keeps_hint_and_selection() -> void:
	var main = _make_main()
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)
	var result: Dictionary = main.runtime.selection_controller.on_battlefield_clicked(Vector2i(-5, -5))

	_assert.that(not result.success, "hint: invalid target should fail")
	_assert.eq(str(result.get("reason", "")), "invalid_target", "hint: invalid target should report invalid_target")
	_assert.that(main.runtime.hand_panel.is_action_hint_visible(), "hint: invalid target should keep action hint visible")
	_assert.eq(main.runtime.selection_controller.get_selected_card_id(), int(card_data.id), "hint: invalid target should keep current selection")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_right_click_cancels_selection() -> void:
	var main = _make_main()
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	main._unhandled_input(event)

	_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "hint: right click should cancel selection")
	_assert.that(not main.runtime.hand_panel.is_action_hint_visible(), "hint: right click should hide action hint")
	_assert.eq(main.runtime.target_preview_layer._valid_cells.size(), 0, "hint: right click should clear preview cells")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_escape_cancels_selection() -> void:
	var main = _make_main()
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	main._unhandled_input(event)

	_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "hint: escape should cancel selection")
	_assert.that(not main.runtime.hand_panel.is_action_hint_visible(), "hint: escape should hide action hint")
	_assert.eq(main.runtime.target_preview_layer._valid_cells.size(), 0, "hint: escape should clear preview cells")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
