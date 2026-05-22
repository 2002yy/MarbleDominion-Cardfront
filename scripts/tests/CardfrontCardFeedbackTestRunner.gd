extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

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
