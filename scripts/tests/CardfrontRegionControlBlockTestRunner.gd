extends SceneTree

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontRegionControlBlockTest] Starting region block readability tests")
	await process_frame
	var main = _make_main(GameConfig.GAME_MODE_CARDFRONT)
	await _flush()
	_test_cardfront_blocks(main)
	_test_dirty_refresh(main)
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)

	var basic_main = _make_main(GameConfig.GAME_MODE_BASIC)
	await _flush()
	_assert.eq(basic_main.runtime.region_control_block_layer, null, "region blocks: BallWar should not create Cardfront control blocks")
	basic_main._cleanup_game_layer()
	TestFixtures.cleanup_node(basic_main)
	await _flush()
	_assert.report("[CardfrontRegionControlBlockTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _make_main(mode_name: String):
	GameConfig.reset_runtime_defaults()
	GameConfig.set_game_mode_by_name(mode_name)
	var main = load("res://scripts/Main.gd").new()
	get_root().add_child(main)
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	return main


func _test_cardfront_blocks(main) -> void:
	var layer = main.runtime.region_control_block_layer
	_assert.that(layer != null, "region blocks: Cardfront should create the control block layer")
	if layer == null:
		return
	_assert.that(not layer.visible, "region blocks: legacy 2D badges should stay hidden behind the orthographic presentation")
	_assert.eq(layer.z_index, 3, "region blocks: layer should sit above static region art and below target preview")
	var visuals: Array = layer.get_region_visuals_for_test()
	_assert.eq(visuals.size(), main.runtime.region_map.get_controllable_region_ids().size(), "region blocks: every controllable region needs one large block")
	for visual in visuals:
		_assert.that(str(visual.label).contains("%"), "region blocks: each block label should contain an explicit percentage")
		_assert.that(str(visual.type_label).length() > 0, "region blocks: each badge should have a dedicated region-type line")
		_assert.that(str(visual.owner_label).contains("%"), "region blocks: each badge should have a dedicated owner-percentage line")
		_assert.that(int(visual.percent) >= 0 and int(visual.percent) <= 100, "region blocks: percentages should stay in range")
		_assert.gte((visual.bounds as Rect2).size.x, float(layer.cell_size) * 2.0, "region blocks: badge region should span multiple cells")
		_assert.gte((visual.bounds as Rect2).size.y, float(layer.cell_size) * 2.0, "region blocks: badge region should span multiple rows")


func _test_dirty_refresh(main) -> void:
	var layer = main.runtime.region_control_block_layer
	if layer == null:
		return
	var visuals: Array = layer.get_region_visuals_for_test()
	if visuals.is_empty():
		return
	var target = visuals[0]
	var cell: Vector2i = target.cells[0]
	main.runtime.battlefield.apply_owner_change(cell, GameConfig.Faction.RED, "test")
	main.runtime.battlefield.scores_changed.emit(main.runtime.battlefield.count_cells_by_team())
	var refreshed: Array = layer.get_region_visuals_for_test()
	_assert.eq(refreshed.size(), visuals.size(), "region blocks: score changes should rebuild without losing blocks")
	_assert.that(layer._dirty, "region blocks: score changes should mark the layer dirty")


func _flush() -> void:
	await process_frame
	await process_frame
