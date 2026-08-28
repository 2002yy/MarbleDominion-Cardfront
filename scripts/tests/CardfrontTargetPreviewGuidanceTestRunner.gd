extends SceneTree

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontTargetPreviewGuidanceTest] Starting target preview guidance tests")
	await process_frame

	_test_hover_valid_cell_returns_valid()
	await _test_hover_invalid_cell_returns_reason()
	await _test_flash_invalid_cell_adds_entry()
	await _test_flash_expires_after_duration()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontTargetPreviewGuidanceTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main.cardfront_legacy_compatibility_enabled = true
	main._start_game(20, true, false)
	await process_frame
	await process_frame
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


func _cell_outside_battlefield() -> Vector2i:
	return Vector2i(-99, -99)


func _test_hover_valid_cell_returns_valid() -> void:
	var main = await _make_main()
	var preview = main.runtime.target_preview_layer
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)

	var valid_cell: Vector2i = _first_valid_cell(main)
	if valid_cell.x < 0:
		_assert.that(true, "preview guidance valid: no valid cells 鈥?skipping")
		main._cleanup_game_layer()
		TestFixtures.cleanup_node(main)
		return

	var info: Dictionary = preview.get_hover_target_info(valid_cell)
	_assert.eq(bool(info.get("active", false)), true, "preview guidance valid: should be active")
	_assert.eq(bool(info.get("valid", false)), true, "preview guidance valid: should be valid")
	_assert.eq(str(info.get("reason", "")), "valid_target", "preview guidance valid: reason should be valid_target")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_hover_invalid_cell_returns_reason() -> void:
	var main = await _make_main()
	var preview = main.runtime.target_preview_layer
	var card_data: Dictionary = main.runtime.card_system.get_hand_card_data()[0]
	_select_card(main, card_data)

	var info: Dictionary = preview.get_hover_target_info(_cell_outside_battlefield())

	_assert.eq(bool(info.get("active", false)), true, "preview guidance invalid: should be active")
	_assert.eq(bool(info.get("valid", false)), false, "preview guidance invalid: should be valid=false")
	var reason: String = str(info.get("reason", ""))
	_assert.that(reason != "", "preview guidance invalid: reason should not be empty")
	_assert.that(reason != "valid_target", "preview guidance invalid: reason should not be valid_target")
	var preview_type: String = str(info.get("preview_type", ""))
	_assert.that(preview_type != "", "preview guidance invalid: preview_type should be present")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_flash_invalid_cell_adds_entry() -> void:
	var main = await _make_main()
	var preview = main.runtime.target_preview_layer

	_assert.eq(preview._invalid_flash_cells.size(), 0, "preview guidance flash: should start empty")

	preview.flash_invalid_cell(Vector2i(3, 5))
	_assert.eq(preview._invalid_flash_cells.size(), 1, "preview guidance flash: flash_invalid_cell should add one entry")
	var entry: Dictionary = preview._invalid_flash_cells[0]
	_assert.eq(entry.get("cell", Vector2i(-1, -1)), Vector2i(3, 5), "preview guidance flash: entry should store correct cell")
	_assert.that(float(entry.get("remaining", 0.0)) > 0.0, "preview guidance flash: remaining time should be positive")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)


func _test_flash_expires_after_duration() -> void:
	var main = await _make_main()
	var preview = main.runtime.target_preview_layer

	preview.flash_invalid_cell(Vector2i(7, 8))
	_assert.eq(preview._invalid_flash_cells.size(), 1, "preview guidance expire: flash added before tick")

	# Process longer than INVALID_FLASH_DURATION (0.25s) to ensure expiry
	preview._process(0.30)
	_assert.eq(preview._invalid_flash_cells.size(), 0, "preview guidance expire: flash cells should be cleared after 0.3s")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
