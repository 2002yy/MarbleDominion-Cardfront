extends SceneTree

const CardfrontContentManifestScript = preload("res://scripts/cardfront/content/CardfrontContentManifest.gd")
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
		for card_id in definition.get("allowed_card_pool", []):
			_assert.that(CardfrontContentManifestScript.has_card(int(card_id)), "map registry: allowed card should exist %d" % int(card_id))


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
