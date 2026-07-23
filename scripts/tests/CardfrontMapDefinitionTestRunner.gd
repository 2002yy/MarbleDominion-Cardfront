extends SceneTree

const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const CardfrontMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontMapDefinitionTest] Starting Cardfront map definition tests")
	await process_frame

	_test_registered_maps_validate()
	_test_region_map_public_paint_api()
	_test_default_map_builds_region_instances()
	_test_generate_default_layout_uses_default_definition()
	_test_unknown_map_definition_is_empty()

	GameConfig.reset_runtime_defaults()
	await process_frame

	_assert.report("[CardfrontMapDefinitionTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _test_registered_maps_validate() -> void:
	var ids: Array = CardfrontMapRegistryScript.get_registered_map_ids()
	_assert.gte(ids.size(), 3, "map registry: should expose default and future map slots")
	for map_id in ids:
		var definition: Dictionary = CardfrontMapRegistryScript.get_map_definition(str(map_id), 40)
		var errors: Array = CardfrontMapDefinitionScript.validate(definition)
		_assert.eq(errors, [], "map registry: definition should validate: %s" % str(map_id))
		_assert.eq(str(definition.get("objective_rule", "")), CardfrontMapDefinitionScript.OBJECTIVE_DESTROY_COMMAND_CHAMBER, "map registry: chamber destruction should be the explicit objective")
		_assert.that(str(definition.get("stronghold_ruleset", "")) != "", "map registry: tactical stronghold ruleset should be explicit")
		for retired_key in ["win_rule", "resource_multiplier", "allowed_card_pool"]:
			_assert.that(not definition.has(retired_key), "map registry: retired metadata should be absent: %s" % retired_key)


func _test_region_map_public_paint_api() -> void:
	var region_map = RegionMapScript.new()
	region_map.configure(20)
	var rect_region_id: int = int(region_map.paint_region_rect(2, 2, 4, 4, RegionTypeScript.ENERGY))
	var diamond_region_id: int = int(region_map.paint_region_diamond(10, 10, 2, RegionTypeScript.LAB))
	_assert.neq(rect_region_id, RegionMapScript.NORMAL_REGION_ID, "map public API: rect paint should allocate a non-normal region")
	_assert.neq(diamond_region_id, RegionMapScript.NORMAL_REGION_ID, "map public API: diamond paint should allocate a non-normal region")
	_assert.eq(region_map.get_region_type(Vector2i(2, 2)), RegionTypeScript.ENERGY, "map public API: rect paint should assign ENERGY")
	_assert.eq(region_map.get_region_type(Vector2i(10, 10)), RegionTypeScript.LAB, "map public API: diamond paint should assign LAB")
	region_map.clear_regions()
	_assert.eq(region_map.get_controllable_region_ids().size(), 0, "map public API: clear_regions should remove controllable regions")
	_assert.eq(region_map.get_region_type(Vector2i(2, 2)), RegionTypeScript.NORMAL, "map public API: clear_regions should reset painted cells")


func _test_default_map_builds_region_instances() -> void:
	var region_map = RegionMapScript.new()
	region_map.configure(40)
	region_map.generate_layout(CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID)
	_assert.gt(region_map.count_region_cells(RegionTypeScript.ENERGY), 0, "map builder: default map should create ENERGY cells")
	_assert.gt(region_map.count_region_cells(RegionTypeScript.FACTORY), 0, "map builder: default map should create FACTORY cells")
	_assert.gt(region_map.count_region_cells(RegionTypeScript.LAB), 0, "map builder: default map should create LAB cells")
	_assert.gte(region_map.get_controllable_region_ids().size(), 5, "map builder: default map should create independent region instances")


func _test_generate_default_layout_uses_default_definition() -> void:
	var direct_map = RegionMapScript.new()
	direct_map.configure(40)
	direct_map.generate_layout(CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID)

	var default_map = RegionMapScript.new()
	default_map.configure(40)
	default_map.generate_default_layout()

	var direct_snapshot: String = JSON.stringify(direct_map.snapshot(), "", true, true)
	var default_snapshot: String = JSON.stringify(default_map.snapshot(), "", true, true)
	_assert.eq(default_snapshot, direct_snapshot, "map builder: generate_default_layout should delegate to default_duel definition")


func _test_unknown_map_definition_is_empty() -> void:
	var definition: Dictionary = CardfrontMapRegistryScript.get_map_definition("missing_map", 40)
	_assert.that(definition.is_empty(), "map registry: unknown map should return empty definition")
