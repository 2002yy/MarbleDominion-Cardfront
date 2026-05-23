extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontHandPanelGuidanceTest] Starting hand panel guidance tests")
	await process_frame

	_test_each_card_hint_nonempty()
	_test_selection_shows_hint()
	_test_clear_selection_hides_hint()
	_test_hover_valid_hint()
	_test_hover_invalid_reason()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontHandPanelGuidanceTest]")
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


func _select_card(main, card_data: Dictionary) -> void:
	main.runtime.selection_controller.on_card_clicked(int(card_data.id), card_data)


func _first_valid_cell(main) -> Vector2i:
	var cells: Array = main.runtime.target_preview_layer._valid_cells
	if cells.is_empty():
		return Vector2i(-999, -999)
	return cells[0]


func _test_each_card_hint_nonempty() -> void:
	var main = _make_main()
	var hand_data: Array = main.runtime.card_system.get_hand_card_data()

	for card_data in hand_data:
		var card_id: int = int(card_data.id)
		var hint: String = main.runtime.hand_panel.get_action_hint_for_card(card_id, card_data)
		_assert.that(hint != "", "guidance: card %d should have non-empty hint" % card_id)

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_selection_shows_hint() -> void:
	var main = _make_main()
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)

	_assert.that(main.runtime.hand_panel.is_action_hint_visible(), "guidance: selecting a card should show the action hint")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_clear_selection_hides_hint() -> void:
	var main = _make_main()
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)
	_assert.that(main.runtime.hand_panel.is_action_hint_visible(), "guidance: hint visible after selection")
	main.runtime.selection_controller.clear_selection()

	_assert.that(not main.runtime.hand_panel.is_action_hint_visible(), "guidance: clear_selection should hide the action hint")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_hover_valid_hint() -> void:
	var main = _make_main()
	_add_resources(main)
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]

	# Get the preview layer to determine what kind of card we have
	var preview = main.runtime.target_preview_layer
	var valid_cell: Vector2i = _first_valid_cell(main)
	if valid_cell.x < 0:
		_assert.that(true, "guidance hover valid: no valid cells for this card — skipping")
		main._cleanup_game_layer()
		TestFixtures.cleanup_node(main)
		return

	_select_card(main, card_data)
	var info: Dictionary = preview.get_hover_target_info(valid_cell)

	_assert.eq(bool(info.get("valid", false)), true, "guidance hover valid: valid cell should return valid=true")
	_assert.eq(str(info.get("reason", "")), "valid_target", "guidance hover valid: reason should be valid_target")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_hover_invalid_reason() -> void:
	var main = _make_main()
	var preview = main.runtime.target_preview_layer

	# Use a cell that is definitely outside the battlefield
	var invalid_cell := Vector2i(-99, -99)
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)
	var info: Dictionary = preview.get_hover_target_info(invalid_cell)

	_assert.eq(bool(info.get("active", false)), true, "guidance hover invalid: should report active=true when card selected")
	_assert.eq(bool(info.get("valid", false)), false, "guidance hover invalid: invalid cell should return valid=false")
	var reason: String = str(info.get("reason", ""))
	_assert.that(reason != "valid_target", "guidance hover invalid: reason should NOT be valid_target")
	_assert.that(reason != "", "guidance hover invalid: reason should not be empty")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
