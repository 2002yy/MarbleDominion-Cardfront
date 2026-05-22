extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontCardViewScene = preload("res://scenes/ui/cardfront/CardfrontCardView.tscn")
const CardfrontFeedbackBusScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackBus.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontCardFeedbackTest] Starting card feedback signal tests")
	await process_frame

	_test_selected_signal()
	_test_invalid_target_signal()
	_test_success_signal()
	_test_fail_signal()
	await _test_card_view_scene_input_routes_to_feedback_bus()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontCardFeedbackTest]")
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


func _first_card(main) -> Dictionary:
	return main.runtime.card_system.get_hand_card_data()[0]


func _first_valid_cell(main) -> Vector2i:
	var cells: Array = main.runtime.target_preview_layer._valid_cells
	if cells.is_empty():
		return Vector2i(-999, -999)
	return cells[0]


func _sample_card_view_data() -> Dictionary:
	return {
		"id": 1001,
		"card_name": "Frontline Fortify",
		"type": "structure",
		"target_type": "owned_border",
		"energy_cost": 0,
		"parts_cost": 0,
		"used": false,
	}


func _test_selected_signal() -> void:
	var main = _make_main()
	var signal_counts := {"selected": 0}
	main.runtime.cardfront_feedback_bus.card_selected.connect(func(_card_id: int, _card_data: Dictionary) -> void:
		signal_counts["selected"] += 1
	)
	var card: Dictionary = _first_card(main)
	main.runtime.selection_controller.on_card_clicked(int(card.id), card)
	_assert.eq(signal_counts.selected, 1, "feedback: card_selected should fire once")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_invalid_target_signal() -> void:
	var main = _make_main()
	var signal_counts := {"invalid": 0}
	main.runtime.cardfront_feedback_bus.target_invalid.connect(func(_card_id: int, _card_data: Dictionary, _cell: Vector2i, reason: String) -> void:
		if reason == "invalid_target":
			signal_counts["invalid"] += 1
	)
	var card: Dictionary = _first_card(main)
	main.runtime.selection_controller.on_card_clicked(int(card.id), card)
	main.runtime.selection_controller.on_battlefield_clicked(Vector2i(-5, -5))
	_assert.eq(signal_counts.invalid, 1, "feedback: target_invalid should fire for invalid click")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_success_signal() -> void:
	var main = _make_main()
	_add_resources(main)
	var signal_counts := {"success": 0}
	main.runtime.cardfront_feedback_bus.card_play_succeeded.connect(func(_card_id: int, _card_data: Dictionary, result: Dictionary) -> void:
		if bool(result.get("success", false)):
			signal_counts["success"] += 1
	)
	var card: Dictionary = _first_card(main)
	main.runtime.selection_controller.on_card_clicked(int(card.id), card)
	var result: Dictionary = main.runtime.selection_controller.on_battlefield_clicked(_first_valid_cell(main))
	_assert.that(result.success, "feedback: valid card play should succeed")
	_assert.eq(signal_counts.success, 1, "feedback: card_play_succeeded should fire once")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_fail_signal() -> void:
	var main = _make_main()
	var signal_counts := {"fail": 0}
	main.runtime.cardfront_feedback_bus.card_play_failed.connect(func(_card_id: int, _card_data: Dictionary, result: Dictionary) -> void:
		if str(result.get("reason", "")) != "":
			signal_counts["fail"] += 1
	)
	var card: Dictionary = _first_card(main)
	main.runtime.selection_controller.on_card_clicked(int(card.id), card)
	var result: Dictionary = main.runtime.selection_controller.on_battlefield_clicked(_first_valid_cell(main))
	_assert.that(not result.success, "feedback: resource-poor card play should fail")
	_assert.eq(signal_counts.fail, 1, "feedback: card_play_failed should fire once")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_card_view_scene_input_routes_to_feedback_bus() -> void:
	var view = CardfrontCardViewScene.instantiate()
	get_root().add_child(view)
	await _flush()

	var bus = CardfrontFeedbackBusScript.new()
	get_root().add_child(bus)
	var signal_counts := {"hovered": 0, "clicked": 0, "callback": 0}
	bus.card_hovered.connect(func(card_id: int, _card_data: Dictionary, card_view: Control) -> void:
		if card_id == 1001 and card_view == view:
			signal_counts["hovered"] += 1
	)
	bus.card_clicked.connect(func(card_id: int, _card_data: Dictionary, card_view: Control) -> void:
		if card_id == 1001 and card_view == view:
			signal_counts["clicked"] += 1
	)
	view.set_feedback_bus(bus)
	view.clicked_callback = func() -> void:
		signal_counts["callback"] += 1
	view.bind(_sample_card_view_data(), null)

	_assert.eq(view.mouse_filter, Control.MOUSE_FILTER_STOP, "feedback: card view root should receive mouse input")
	for node_name in ["CardBorder", "Bg", "CardArt", "CardName", "CostEnergy", "StatusLabel"]:
		var child = view.get_node_or_null(node_name)
		_assert.that(child is Control, "feedback: %s should be a Control" % node_name)
		if child is Control:
			_assert.eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "feedback: %s should not intercept card input" % node_name)
	_assert.that(view.mouse_entered.is_connected(Callable(view, "_on_mouse_entered")), "feedback: card view mouse_entered should be connected")
	_assert.that(view.gui_input.is_connected(Callable(view, "_on_gui_input")), "feedback: card view gui_input should be connected")

	view.emit_signal("mouse_entered")
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	view.emit_signal("gui_input", event)

	_assert.eq(signal_counts.hovered, 1, "feedback: CardView hover should emit through feedback bus")
	_assert.eq(signal_counts.clicked, 1, "feedback: CardView click should emit through feedback bus")
	_assert.eq(signal_counts.callback, 1, "feedback: CardView click should preserve clicked_callback")

	TestFixtures.cleanup_node(view)
	TestFixtures.cleanup_node(bus)
