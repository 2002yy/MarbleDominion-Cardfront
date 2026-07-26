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
	_test_strategic_route_profiles_are_distinct()
	_test_invalid_route_and_strategy_data_is_rejected()
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


func _test_strategic_route_profiles_are_distinct() -> void:
	var route_snapshots: Dictionary = {}
	var identities: Dictionary = {}
	var lane_spacings: Dictionary = {}
	for map_id in CardfrontMapRegistryScript.get_registered_map_ids():
		var definition: Dictionary = CardfrontMapRegistryScript.get_map_definition(str(map_id), 40)
		var route_layout: Dictionary = CardfrontMapDefinitionScript.route_layout_snapshot(definition)
		var strategy_profile: Dictionary = CardfrontMapDefinitionScript.strategy_profile_snapshot(definition)
		var centers: Array = route_layout.get("lane_center_ratios", []) as Array
		_assert.eq(centers.size(), 2, "map strategy: first-stage maps should expose exactly two bridge lanes: %s" % str(map_id))
		if centers.size() == 2:
			_assert.that(absf(float(centers[0]) + float(centers[1]) - 1.0) < 0.0001, "map strategy: competitive bridge lanes should remain rotationally symmetric: %s" % str(map_id))
			lane_spacings[str(map_id)] = float(centers[1]) - float(centers[0])
		_assert.that(absf(float(route_layout.get("river_y_ratio", 0.0)) - 0.5) < 0.0001, "map strategy: first-stage river should stay on the center line: %s" % str(map_id))
		_assert.that(str(strategy_profile.get("identity", "")) != "", "map strategy: identity should be player-readable: %s" % str(map_id))
		_assert.that(str(strategy_profile.get("summary", "")) != "", "map strategy: summary should explain the route question: %s" % str(map_id))
		_assert.that(str(strategy_profile.get("opening_hint", "")) != "", "map strategy: opening hint should be actionable: %s" % str(map_id))
		route_snapshots[str(map_id)] = JSON.stringify(route_layout, "", true, true)
		identities[str(strategy_profile.get("identity", ""))] = true

	_assert.eq(identities.size(), 3, "map strategy: all three registered maps should have different strategic identities")
	_assert.eq(route_snapshots.size(), 3, "map strategy: route snapshots should be recorded for all maps")
	_assert.that(float(lane_spacings[CardfrontMapRegistryScript.CROSS_RESOURCE_MAP_ID]) < float(lane_spacings[CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID]), "map strategy: Cross Strongholds should pull its bridges inward")
	_assert.gt(float(lane_spacings[CardfrontMapRegistryScript.CENTRAL_LAB_MAP_ID]), float(lane_spacings[CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID]), "map strategy: Central Lab should push its bridges outward")
	_assert.neq(route_snapshots[CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID], route_snapshots[CardfrontMapRegistryScript.CROSS_RESOURCE_MAP_ID], "map strategy: default and cross route layouts should differ")
	_assert.neq(route_snapshots[CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID], route_snapshots[CardfrontMapRegistryScript.CENTRAL_LAB_MAP_ID], "map strategy: default and central-lab route layouts should differ")


func _test_invalid_route_and_strategy_data_is_rejected() -> void:
	var definition: Dictionary = CardfrontMapRegistryScript.get_map_definition(CardfrontMapRegistryScript.DEFAULT_DUEL_MAP_ID, 40)
	var overlapping: Dictionary = definition.duplicate(true)
	overlapping["route_layout"]["lane_center_ratios"] = [0.45, 0.50]
	overlapping["route_layout"]["lane_half_width_ratio"] = 0.05
	var overlap_errors: Array = CardfrontMapDefinitionScript.validate(overlapping)
	_assert.that("overlapping_route_lanes" in overlap_errors, "map validation: overlapping bridge lanes should be rejected")

	var out_of_bounds: Dictionary = definition.duplicate(true)
	out_of_bounds["route_layout"]["lane_center_ratios"] = [0.10, 0.90]
	out_of_bounds["route_layout"]["control_zone_half_width_ratio"] = 0.15
	var bounds_errors: Array = CardfrontMapDefinitionScript.validate(out_of_bounds)
	_assert.that("route_control_zone_out_of_bounds:0" in bounds_errors, "map validation: left control zone should stay inside the board")
	_assert.that("route_control_zone_out_of_bounds:1" in bounds_errors, "map validation: right control zone should stay inside the board")

	var missing_hint: Dictionary = definition.duplicate(true)
	missing_hint["strategy_profile"]["opening_hint"] = ""
	var hint_errors: Array = CardfrontMapDefinitionScript.validate(missing_hint)
	_assert.that("missing_strategy_profile:opening_hint" in hint_errors, "map validation: every strategic map should explain an opening decision")


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
