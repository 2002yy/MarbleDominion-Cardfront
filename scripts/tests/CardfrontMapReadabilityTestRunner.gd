extends SceneTree

const CardfrontMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontMapReadabilityTest] Starting five-stronghold map tests")
	await process_frame
	_test_definition_declares_readable_layout()
	_test_regions_are_large_separate_and_symmetric(20)
	_test_regions_are_large_separate_and_symmetric(40)
	_assert.report("[CardfrontMapReadabilityTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_definition_declares_readable_layout() -> void:
	var definition: Dictionary = CardfrontMapRegistryScript.get_map_definition(CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID, 40)
	_assert.eq(str(definition.get("layout_style", "")), "symmetric_five_strongholds", "map readability: default map should declare the five-stronghold layout")
	_assert.eq(str(definition.get("display_name", "")), "Five Strongholds", "map readability: default map should expose a clear display name")
	_assert.eq((definition.get("regions", []) as Array).size(), 5, "map readability: default map should have five strategic blocks")


func _test_regions_are_large_separate_and_symmetric(grid_size: int) -> void:
	var region_map = RegionMapScript.new()
	region_map.configure(grid_size)
	region_map.generate_layout(CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID)
	var ids: Array = region_map.get_controllable_region_ids()
	_assert.eq(ids.size(), 5, "map readability: %dx%d should build five independent regions" % [grid_size, grid_size])
	_assert.eq(region_map.get_region_ids_by_type(RegionTypeScript.ENERGY).size(), 2, "map readability: layout should have two energy strongholds")
	_assert.eq(region_map.get_region_ids_by_type(RegionTypeScript.FACTORY).size(), 2, "map readability: layout should have two factory strongholds")
	_assert.eq(region_map.get_region_ids_by_type(RegionTypeScript.LAB).size(), 1, "map readability: layout should have one central lab")
	_assert.eq(region_map.get_region_type(Vector2i(grid_size >> 1, grid_size >> 1)), RegionTypeScript.LAB, "map readability: central objective should be the lab")

	for region_id_value in ids:
		var region_id: int = int(region_id_value)
		var cells: Array = region_map.get_region_cells(region_id)
		_assert.gte(cells.size(), 9, "map readability: every stronghold should be a visibly large block")
		for cell_value in cells:
			var cell: Vector2i = cell_value
			for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var neighbor: Vector2i = cell + direction
				if region_map.is_inside(neighbor):
					var neighbor_id: int = int(region_map.get_region_id(neighbor))
					_assert.that(neighbor_id == 0 or neighbor_id == region_id, "map readability: strongholds should not touch or visually merge")

	for x in range(grid_size):
		for y in range(grid_size):
			var cell := Vector2i(x, y)
			var mirror := Vector2i(grid_size - x - 1, grid_size - y - 1)
			_assert.eq(region_map.get_region_type(cell), region_map.get_region_type(mirror), "map readability: strategic types should be rotationally symmetric")
