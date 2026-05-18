extends SceneTree

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionOverlayLayerScript = preload("res://scripts/cardfront/regions/RegionOverlayLayer.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontBattlefieldInitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[RegionMapTest] Starting Cardfront region map tests")
	await process_frame

	_test_region_type_api()
	_test_default_layout_size_and_counts(40, 1600)
	_test_default_layout_size_and_counts(60, 3600)
	_test_spawn_edges_do_not_create_labs(40)
	_test_spawn_edges_do_not_create_labs(60)
	_test_default_layout_is_deterministic(40)
	_test_default_layout_is_deterministic(60)
	_test_region_instances(40)
	_test_region_instance_reverse_lookup(40)
	_test_owned_region_cell_count()
	_test_region_control_calculator()
	_test_overlay_visibility_by_mode()
	await _test_main_region_overlay_integration()
	await _flush()

	_assert.report("[RegionMapTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_region_type_api() -> void:
	_assert.eq(RegionTypeScript.all_types().size(), 4, "region type: all four types should be listed")
	_assert.that(RegionTypeScript.is_valid(RegionTypeScript.NORMAL), "region type: NORMAL should be valid")
	_assert.that(RegionTypeScript.is_valid(RegionTypeScript.ENERGY), "region type: ENERGY should be valid")
	_assert.that(RegionTypeScript.is_valid(RegionTypeScript.FACTORY), "region type: FACTORY should be valid")
	_assert.that(RegionTypeScript.is_valid(RegionTypeScript.LAB), "region type: LAB should be valid")
	_assert.that(not RegionTypeScript.is_valid("economy_tick"), "region type: unknown type should be invalid")


func _test_default_layout_size_and_counts(grid_size: int, expected_total: int) -> void:
	var region_map = _make_region_map(grid_size)
	_assert.eq(_snapshot_cell_total(region_map.snapshot()), expected_total, "region map %dx%d: snapshot should contain every cell" % [grid_size, grid_size])
	_assert.gt(region_map.count_region_cells(RegionTypeScript.ENERGY), 0, "region map %dx%d: ENERGY count should be positive" % [grid_size, grid_size])
	_assert.gt(region_map.count_region_cells(RegionTypeScript.FACTORY), 0, "region map %dx%d: FACTORY count should be positive" % [grid_size, grid_size])
	_assert.gt(region_map.count_region_cells(RegionTypeScript.LAB), 0, "region map %dx%d: LAB count should be positive" % [grid_size, grid_size])
	_assert.eq(_count_all_valid_cells(region_map), expected_total, "region map %dx%d: every cell should have a valid type" % [grid_size, grid_size])


func _test_spawn_edges_do_not_create_labs(grid_size: int) -> void:
	var region_map = _make_region_map(grid_size)
	var spawn_columns: int = CardfrontBattlefieldInitializerScript.get_spawn_columns(grid_size)
	for x in range(spawn_columns):
		for y in range(grid_size):
			_assert.neq(region_map.get_region_type(Vector2i(x, y)), RegionTypeScript.LAB, "region map %d: player spawn edge should not contain LAB" % grid_size)
	for x in range(grid_size - spawn_columns, grid_size):
		for y in range(grid_size):
			_assert.neq(region_map.get_region_type(Vector2i(x, y)), RegionTypeScript.LAB, "region map %d: AI spawn edge should not contain LAB" % grid_size)


func _test_default_layout_is_deterministic(grid_size: int) -> void:
	var first = _make_region_map(grid_size)
	var second = _make_region_map(grid_size)
	var first_snapshot: String = JSON.stringify(first.snapshot(), "", true, true)
	var second_snapshot: String = JSON.stringify(second.snapshot(), "", true, true)
	_assert.eq(first_snapshot, second_snapshot, "region map %d: default layout should be deterministic" % grid_size)


func _test_region_instances(grid_size: int) -> void:
	var region_map = _make_region_map(grid_size)
	var energy_ids: Array = region_map.get_region_ids_by_type(RegionTypeScript.ENERGY)
	var factory_ids: Array = region_map.get_region_ids_by_type(RegionTypeScript.FACTORY)
	var lab_ids: Array = region_map.get_region_ids_by_type(RegionTypeScript.LAB)
	_assert.that(energy_ids is Array, "region instances: ENERGY ids should be an Array")
	_assert.that(factory_ids is Array, "region instances: FACTORY ids should be an Array")
	_assert.that(lab_ids is Array, "region instances: LAB ids should be an Array")
	_assert.gte(energy_ids.size(), 2, "region instances: ENERGY should have at least two independent region ids")
	_assert.gte(factory_ids.size(), 2, "region instances: FACTORY should have at least two independent region ids")
	_assert.eq(lab_ids.size(), 1, "region instances: central LAB should be one independent region")
	_assert.neq(int(lab_ids[0]), RegionMapScript.NORMAL_REGION_ID, "region instances: LAB should not use the NORMAL region id")

	for region_id in energy_ids:
		_assert.eq(region_map.get_region_type_by_id(int(region_id)), RegionTypeScript.ENERGY, "region instances: ENERGY id should resolve to ENERGY")
	for region_id in factory_ids:
		_assert.eq(region_map.get_region_type_by_id(int(region_id)), RegionTypeScript.FACTORY, "region instances: FACTORY id should resolve to FACTORY")
	for region_id in lab_ids:
		_assert.eq(region_map.get_region_type_by_id(int(region_id)), RegionTypeScript.LAB, "region instances: LAB id should resolve to LAB")

	var controllable_ids: Array = region_map.get_controllable_region_ids()
	_assert.eq(controllable_ids.size(), energy_ids.size() + factory_ids.size() + lab_ids.size(), "region instances: controllable ids should include every non-NORMAL region")


func _test_region_instance_reverse_lookup(grid_size: int) -> void:
	var region_map = _make_region_map(grid_size)
	for region_id in region_map.get_all_region_ids():
		var cells: Array = region_map.get_region_cells(int(region_id))
		_assert.gt(cells.size(), 0, "region instances: region %d should own at least one cell" % int(region_id))
		for cell in cells:
			_assert.eq(region_map.get_region_id(cell), int(region_id), "region instances: cell should reverse-map to its region id")


func _test_owned_region_cell_count() -> void:
	var region_map = _make_region_map(40)
	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	var owners: Array = []
	for x in range(40):
		var col: Array = []
		for y in range(40):
			var cell := Vector2i(x, y)
			if region_map.get_region_type(cell) == RegionTypeScript.ENERGY:
				col.append(CardfrontRulesScript.PLAYER_FACTION)
			else:
				col.append(CardfrontRulesScript.AI_FACTION)
		owners.append(col)
	bf.replace_owners(owners, false)

	var energy_cells: int = region_map.count_region_cells(RegionTypeScript.ENERGY)
	_assert.gt(energy_cells, 0, "owned region count: ENERGY fixture should contain cells")
	_assert.eq(region_map.count_owned_region_cells(bf, CardfrontRulesScript.PLAYER_FACTION, RegionTypeScript.ENERGY), energy_cells, "owned region count: player should own all ENERGY cells")
	_assert.eq(region_map.count_owned_region_cells(bf, CardfrontRulesScript.AI_FACTION, RegionTypeScript.ENERGY), 0, "owned region count: AI should own no ENERGY cells")
	TestFixtures.cleanup_node(bf)


func _test_region_control_calculator() -> void:
	var region_map = _make_region_map(40)
	var energy_ids: Array = region_map.get_region_ids_by_type(RegionTypeScript.ENERGY)
	_assert.gte(energy_ids.size(), 2, "region control: fixture should expose multiple ENERGY regions")
	var region_id: int = int(energy_ids[0])
	var cells: Array = region_map.get_region_cells(region_id)
	_assert.gt(cells.size(), 0, "region control: selected region should contain cells")

	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	var owners: Array = _make_owner_grid(40, CardfrontRulesScript.NEUTRAL_OWNER)
	var player_count: int = maxi(1, int(ceil(float(cells.size()) * 0.50)))
	var ai_count: int = maxi(1, int(floor(float(cells.size()) * 0.30)))
	_assign_region_fixture_owners(owners, cells, player_count, ai_count)
	bf.replace_owners(owners, false)

	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, bf, region_id)
	var neutral_count: int = cells.size() - player_count - ai_count
	_assert.eq(int(control["owner_counts"].get(CardfrontRulesScript.PLAYER_FACTION, -1)), player_count, "region control: player cell count should match fixture")
	_assert.eq(int(control["owner_counts"].get(CardfrontRulesScript.AI_FACTION, -1)), ai_count, "region control: AI cell count should match fixture")
	_assert.eq(int(control["owner_counts"].get(CardfrontRulesScript.NEUTRAL_OWNER, -1)), neutral_count, "region control: neutral cell count should match fixture")
	_assert.eq(RegionControlCalculatorScript.get_yield_tier(control, CardfrontRulesScript.PLAYER_FACTION), 1, "region control: 50 percent ownership should be tier 1")
	_assert.eq(RegionControlCalculatorScript.get_yield_tier(control, CardfrontRulesScript.AI_FACTION), 0, "region control: below 50 percent ownership should be tier 0")
	_assert.eq(RegionControlCalculatorScript.get_region_status(control), RegionControlCalculatorScript.STATUS_INFLUENCED, "region control: 50 percent ownership should be influenced, not fully controlled")

	owners = _make_owner_grid(40, CardfrontRulesScript.NEUTRAL_OWNER)
	player_count = maxi(1, int(ceil(float(cells.size()) * 0.80)))
	ai_count = maxi(0, int(floor(float(cells.size()) * 0.10)))
	_assign_region_fixture_owners(owners, cells, player_count, ai_count)
	bf.replace_owners(owners, false)
	control = RegionControlCalculatorScript.calculate(region_map, bf, region_id)
	_assert.eq(RegionControlCalculatorScript.get_yield_tier(control, CardfrontRulesScript.PLAYER_FACTION), 2, "region control: 80 percent ownership should be tier 2")
	_assert.eq(RegionControlCalculatorScript.get_region_status(control), RegionControlCalculatorScript.STATUS_CONTROLLED, "region control: 80 percent ownership should be controlled")

	TestFixtures.cleanup_node(bf)


func _test_overlay_visibility_by_mode() -> void:
	var region_map = _make_region_map(40)
	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	var overlay := RegionOverlayLayerScript.new()
	overlay.setup(region_map, bf, GameConfig.GAME_MODE_BASIC)
	_assert.that(not overlay.visible, "region overlay: old BallWar modes should hide overlay")
	overlay.setup(region_map, bf, GameConfig.GAME_MODE_CARDFRONT)
	_assert.that(overlay.visible, "region overlay: Cardfront mode should show overlay")
	_assert.that(int(overlay.z_index) < 29, "region overlay: overlay should stay below bullet trail and bullets")
	TestFixtures.cleanup_node(overlay)
	TestFixtures.cleanup_node(bf)


func _test_main_region_overlay_integration() -> void:
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = GameConfig.GAME_MODE_BASIC
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame
	_assert.eq(main.runtime.region_overlay, null, "main integration: old BallWar mode should not create RegionOverlay")

	main._cleanup_game_layer()
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame
	_assert.that(main.runtime.region_map != null, "main integration: Cardfront should create RegionMap")
	_assert.that(main.runtime.region_overlay != null and is_instance_valid(main.runtime.region_overlay), "main integration: Cardfront should create RegionOverlay")
	_assert.that(main.runtime.region_overlay.visible, "main integration: Cardfront RegionOverlay should be visible")

	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()


func _make_region_map(grid_size: int):
	var region_map := RegionMapScript.new()
	region_map.configure(grid_size)
	region_map.generate_default_layout()
	return region_map


func _snapshot_cell_total(snapshot: Dictionary) -> int:
	var total: int = 0
	var cells: Array = snapshot.get("regions", [])
	for col in cells:
		if col is Array:
			total += (col as Array).size()
	return total


func _count_all_valid_cells(region_map) -> int:
	var total: int = 0
	for x in range(region_map.grid_size):
		for y in range(region_map.grid_size):
			if RegionTypeScript.is_valid(region_map.get_region_type(Vector2i(x, y))):
				total += 1
	return total


func _make_owner_grid(grid_size: int, owner_id: int) -> Array:
	var owners: Array = []
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(owner_id)
		owners.append(col)
	return owners


func _assign_region_fixture_owners(owners: Array, cells: Array, player_count: int, ai_count: int) -> void:
	for index in range(cells.size()):
		var cell: Vector2i = cells[index]
		if index < player_count:
			owners[cell.x][cell.y] = CardfrontRulesScript.PLAYER_FACTION
		elif index < player_count + ai_count:
			owners[cell.x][cell.y] = CardfrontRulesScript.AI_FACTION
