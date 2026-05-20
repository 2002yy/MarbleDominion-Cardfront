extends SceneTree

const CardfrontTargetPreviewLayerScript = preload("res://scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontTargetPreviewTest] Starting target preview tests")
	await process_frame

	_test_preview_shows_for_owned_border_card()
	_test_preview_shows_for_enemy_region_card()
	_test_preview_shows_for_owned_region_card()
	_test_pioneer_beacon_shows_hint_cells()
	_test_clear_preview_removes_all()
	_test_is_valid_target_after_show()
	_test_ballwar_no_preview_layer()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardfrontTargetPreviewTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_preview_shows_for_owned_border_card() -> void:
	var fixture: Dictionary = _make_fixture()
	var layer = fixture.layer
	var card_data := _make_card_data(1001, "owned_border")

	layer.show_for_card(1001, card_data)

	_assert.that(layer._valid_cells.size() > 0, "preview: owned_border should show valid cells")
	_assert.that(layer._hint_cells.is_empty(), "preview: frontline_fortify should have no hint cells")

	_cleanup_fixture(fixture)


func _test_preview_shows_for_enemy_region_card() -> void:
	var fixture: Dictionary = _make_fixture()
	var layer = fixture.layer
	var card_data := _make_card_data(1002, "enemy_region")

	layer.show_for_card(1002, card_data)

	_assert.that(layer._valid_cells.size() > 0, "preview: enemy_region should show valid cells")

	_cleanup_fixture(fixture)


func _test_preview_shows_for_owned_region_card() -> void:
	var fixture: Dictionary = _make_fixture()
	var layer = fixture.layer
	var card_data := _make_card_data(1003, "owned_region")

	layer.show_for_card(1003, card_data)

	_assert.that(layer._valid_cells.size() > 0, "preview: owned_region should show valid cells")

	_cleanup_fixture(fixture)


func _test_pioneer_beacon_shows_hint_cells() -> void:
	var fixture: Dictionary = _make_fixture()
	var layer = fixture.layer
	var card_data := _make_card_data(1004, "owned_border")

	layer.show_for_card(1004, card_data)

	_assert.that(layer._valid_cells.size() > 0, "preview: pioneer beacon should show border cells")
	_assert.that(layer._hint_cells.size() > 0, "preview: pioneer beacon should show adjacent neutral cells")

	_cleanup_fixture(fixture)


func _test_clear_preview_removes_all() -> void:
	var fixture: Dictionary = _make_fixture()
	var layer = fixture.layer
	var card_data := _make_card_data(1001, "owned_border")

	layer.show_for_card(1001, card_data)
	_assert.that(layer._valid_cells.size() > 0, "preview: should have cells before clear")

	layer.clear_preview()
	_assert.eq(layer._valid_cells.size(), 0, "preview: valid cells should be empty after clear")
	_assert.eq(layer._hint_cells.size(), 0, "preview: hint cells should be empty after clear")

	_cleanup_fixture(fixture)


func _test_is_valid_target_after_show() -> void:
	var fixture: Dictionary = _make_fixture()
	var layer = fixture.layer
	var card_data := _make_card_data(1001, "owned_border")

	layer.show_for_card(1001, card_data)

	_assert.that(layer._valid_cells.size() > 0, "preview: should have cells")
	var first_cell: Vector2i = layer._valid_cells[0]
	_assert.that(layer.is_valid_target(first_cell), "preview: first cell should be valid target")

	layer.clear_preview()
	_assert.that(not layer.is_valid_target(first_cell), "preview: cell should not be valid after clear")

	_cleanup_fixture(fixture)


func _test_ballwar_no_preview_layer() -> void:
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(GameConfig.GAME_MODE_BASIC)

	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await process_frame

	_assert.eq(main.runtime.target_preview_layer, null, "preview: BallWar mode should not create target preview layer")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()


func _make_fixture() -> Dictionary:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var layer = CardfrontTargetPreviewLayerScript.new()
	layer.setup(bf, rm, GameConfig.GAME_MODE_CARDFRONT)

	return {
		"bf": bf,
		"rm": rm,
		"layer": layer,
	}


func _make_card_data(card_id: int, target_type: String) -> Dictionary:
	return {
		"id": card_id,
		"card_name": "test_card",
		"target_type": target_type,
		"energy_cost": 5,
		"parts_cost": 2,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bf", null))
	TestFixtures.cleanup_node(fixture.get("layer", null))
