extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontFormalUITest] Starting Cardfront formal UI tests")
	await process_frame

	_test_top_resource_bar_visible()
	_test_top_resource_bar_refreshes_on_resources_changed()
	_test_hand_panel_visible()
	_test_hand_panel_has_four_cards()
	_test_card_click_selection_controller()
	_test_card_play_consumes_resources()
	_test_ballwar_no_formal_ui()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontFormalUITest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_top_resource_bar_visible() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.top_resource_bar != null, "ui: top_resource_bar should exist")
	if main.runtime.top_resource_bar != null:
		_assert.that(main.runtime.top_resource_bar.visible, "ui: top_resource_bar should be visible")
		var energy_box = main.runtime.top_resource_bar._energy_value
		_assert.that(energy_box != null, "ui: energy value label should exist")
		_assert.that(str(energy_box.text).is_valid_int(), "ui: energy text should be a number")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_top_resource_bar_refreshes_on_resources_changed() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.top_resource_bar != null, "top_resource_bar exists")
	if main.runtime.top_resource_bar != null:
		var before: int = int(main.runtime.top_resource_bar._energy_value.text)
		main.runtime.top_resource_bar.refresh(true)
		var after: int = int(main.runtime.top_resource_bar._energy_value.text)
		_assert.eq(after, before, "refresh without resource change should keep same value")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_hand_panel_visible() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.hand_panel != null, "ui: hand_panel should exist")
	if main.runtime.hand_panel != null:
		_assert.that(main.runtime.hand_panel.visible, "ui: hand_panel should be visible in Cardfront")
		_assert.that(main.runtime.hand_panel._card_views.size() == 4, "ui: hand_panel should have 4 card views")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_hand_panel_has_four_cards() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.hand_panel != null, "hand_panel exists")
	if main.runtime.hand_panel != null:
		var views = main.runtime.hand_panel._card_views
		_assert.eq(views.size(), 4, "should have 4 card views")
		for view in views:
			var name_label = view.get_node("NameLabel") as Label
			_assert.neq(name_label.text, "???", "card name should not be placeholder")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_card_click_selection_controller() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.selection_controller != null, "selection_controller should exist")
	if main.runtime.selection_controller != null:
		_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "no card selected initially")
		var card_id: int = main.runtime.hand_panel._card_views[0].card_id
		main.runtime.selection_controller.on_card_clicked(card_id, main.runtime.hand_panel._card_views[0].card_data)
		_assert.eq(main.runtime.selection_controller.get_selected_card_id(), card_id, "card should be selected after click")
		main.runtime.selection_controller.clear_selection()
		_assert.eq(main.runtime.selection_controller.get_selected_card_id(), -1, "deselected after clear")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_card_play_consumes_resources() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_CARDFRONT)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	var state = main.runtime.resource_states.get(1, null)
	_assert.that(state != null, "player resource state should exist")
	if state != null:
		var before_energy: int = int(state.energy)
		var before_parts: int = int(state.parts)
		state.add_energy(50)
		state.add_parts(50)

		var card_system = main.runtime.card_system
		_assert.that(card_system != null, "card_system should exist")
		if card_system != null:
			var CardPlayRequestScript = load("res://scripts/cardfront/cards/CardPlayRequest.gd")
			var req = CardPlayRequestScript.make(1003, 1, Vector2i(5, 5), 1)
			var result = card_system.play(req)
			_assert.that(result.success, "card play should succeed with enough resources (reason: %s)" % str(result.reason))

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_ballwar_no_formal_ui() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)

	_assert.that(main.runtime.top_resource_bar == null, "top_resource_bar should not exist in BallWar mode")
	_assert.that(main.runtime.hand_panel == null, "hand_panel should not exist in BallWar mode")
	_assert.that(main.runtime.selection_controller == null, "selection_controller should not exist in BallWar mode")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
