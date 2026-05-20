extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontBattlefieldClickSelectionTest] Starting battlefield click selection tests")
	await process_frame

	_test_select_card_shows_preview()
	_test_click_valid_cell_plays_card()
	_test_click_invalid_cell_does_not_consume_resources()
	_test_deselect_clears_preview()
	_test_ballwar_mode_does_not_intercept_clicks()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontBattlefieldClickSelectionTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_select_card_shows_preview() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.selection_controller != null, "selection controller should exist")
	_assert.that(main.runtime.target_preview_layer != null, "target preview layer should exist")

	var hand_data = main.runtime.card_system.get_hand_card_data()
	_assert.that(hand_data.size() >= 1, "should have at least 1 card in hand")
	if hand_data.size() >= 1:
		var card_id: int = int(hand_data[0].id)
		main.runtime.selection_controller.on_card_clicked(card_id, hand_data[0])
		_assert.eq(main.runtime.selection_controller.get_selected_card_id(), card_id, "card should be selected")
		_assert.that(main.runtime.target_preview_layer._valid_cells.size() > 0, "preview should show valid cells")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_click_valid_cell_plays_card() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var state = main.runtime.resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	_assert.that(state != null, "player resource state should exist")
	if state != null:
		state.add_energy(999)
		state.add_parts(999)

	var hand_data = main.runtime.card_system.get_hand_card_data()
	var card_data = hand_data[0]
	var card_id: int = int(card_data.id)
	main.runtime.selection_controller.on_card_clicked(card_id, card_data)

	var preview_cells = main.runtime.target_preview_layer._valid_cells
	_assert.that(preview_cells.size() > 0, "should have preview cells")
	if preview_cells.size() > 0:
		var target_cell: Vector2i = preview_cells[0]
		var result: Dictionary = main.runtime.selection_controller.on_battlefield_clicked(target_cell)
		_assert.that(result.success, "click valid target should succeed (reason: %s)" % str(result.get("reason", "")))

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_click_invalid_cell_does_not_consume_resources() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var state = main.runtime.resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	_assert.that(state != null, "player resource state should exist")
	if state != null:
		state.add_energy(999)
		state.add_parts(999)
	var energy_before: int = int(state.energy)

	var hand_data = main.runtime.card_system.get_hand_card_data()
	var card_data = hand_data[0]
	main.runtime.selection_controller.on_card_clicked(int(card_data.id), card_data)

	var result: Dictionary = main.runtime.selection_controller.on_battlefield_clicked(Vector2i(-5, -5))
	_assert.that(not result.success, "invalid cell should not succeed")
	var energy_after: int = int(state.energy)
	_assert.eq(energy_after, energy_before, "resources should not be consumed on invalid click")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_deselect_clears_preview() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var hand_data = main.runtime.card_system.get_hand_card_data()
	main.runtime.selection_controller.on_card_clicked(int(hand_data[0].id), hand_data[0])
	_assert.that(main.runtime.target_preview_layer._valid_cells.size() > 0, "preview should show cells")

	main.runtime.selection_controller.clear_selection()
	_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "should be deselected")
	_assert.eq(main.runtime.target_preview_layer._valid_cells.size(), 0, "preview should be cleared")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_mode_does_not_intercept_clicks() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.eq(main.runtime.selection_controller, null, "BallWar should have no selection controller")
	_assert.eq(main.runtime.target_preview_layer, null, "BallWar should have no target preview")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
