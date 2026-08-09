extends SceneTree

const DefaultDuelMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const SupportDefinitionScript = preload("res://scripts/cardfront/support/DeploymentSupportDefinition.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SupportRegionMapperScript = preload("res://scripts/cardfront/support/DeploymentSupportRegionMapper.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportRegionMapperTest] Checking anchor-based runtime mapping")
	await process_frame

	_test_default_anchor_mapping_survives_region_reorder()
	_test_normal_anchor_fails_fast()
	_test_duplicate_non_core_region_fails()
	_test_unknown_neighbor_fails()

	_assert.report("[CardfrontSupportRegionMapperTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_default_anchor_mapping_survives_region_reorder() -> void:
	var original_definition: Dictionary = DefaultDuelMapScript.make(Vector2i(40, 40))
	var reordered_definition: Dictionary = original_definition.duplicate(true)
	var reversed_regions: Array = (reordered_definition.regions as Array).duplicate(true)
	reversed_regions.reverse()
	reordered_definition.regions = reversed_regions

	var original_map = _make_region_map(original_definition)
	var reordered_map = _make_region_map(reordered_definition)
	var supports: Array = _five_non_core_definitions()
	var original_result: Dictionary = SupportRegionMapperScript.bind(supports, original_map)
	var reordered_result: Dictionary = SupportRegionMapperScript.bind(supports, reordered_map)

	_assert.that(bool(original_result.ok), "support mapping: original default_duel should bind")
	_assert.that(bool(reordered_result.ok), "support mapping: reordered region definitions should bind")
	_assert.eq((original_result.bindings as Dictionary).size(), 5, "support mapping: five non-core supports bind")
	_assert.eq((reordered_result.bindings as Dictionary).size(), 5, "support mapping: reordered map still binds five supports")
	_assert.neq(int(original_result.bindings[SupportIdsScript.SUPPORT_LEFT_NORTH]), int(reordered_result.bindings[SupportIdsScript.SUPPORT_LEFT_NORTH]), "support mapping: numeric region ID may change after reorder")
	for support in supports:
		var support_id: String = str((support as Dictionary).support_id)
		var anchor: Vector2i = (support as Dictionary).anchor_cell
		_assert.eq(int(original_result.bindings[support_id]), original_map.get_region_id(anchor), "support mapping: original anchor owns %s" % support_id)
		_assert.eq(int(reordered_result.bindings[support_id]), reordered_map.get_region_id(anchor), "support mapping: reordered anchor owns %s" % support_id)


func _test_normal_anchor_fails_fast() -> void:
	var region_map = _make_region_map(DefaultDuelMapScript.make(Vector2i(40, 40)))
	var support: Dictionary = _definition(SupportIdsScript.SUPPORT_CENTER, Vector2i(0, 20), [])
	var result: Dictionary = SupportRegionMapperScript.bind([support], region_map)
	_assert.that(not bool(result.ok), "support mapping: NORMAL-region anchor should fail")
	_assert.that((result.errors as Array).has("anchor_not_controllable:%s" % SupportIdsScript.SUPPORT_CENTER), "support mapping: NORMAL-region reason")
	_assert.eq(result.bindings, {}, "support mapping: failed batch exposes no partial binding")


func _test_duplicate_non_core_region_fails() -> void:
	var region_map = _make_region_map(DefaultDuelMapScript.make(Vector2i(40, 40)))
	var first: Dictionary = _definition(SupportIdsScript.SUPPORT_LEFT_NORTH, Vector2i(7, 9), [])
	var second: Dictionary = _definition(SupportIdsScript.SUPPORT_RIGHT_NORTH, Vector2i(8, 9), [])
	var result: Dictionary = SupportRegionMapperScript.bind([first, second], region_map)
	_assert.that(not bool(result.ok), "support mapping: two Supports cannot share one runtime region")
	_assert.that(_has_error_prefix(result.errors, "duplicate_runtime_region:"), "support mapping: duplicate runtime region reason")


func _test_unknown_neighbor_fails() -> void:
	var region_map = _make_region_map(DefaultDuelMapScript.make(Vector2i(40, 40)))
	var support: Dictionary = _definition(SupportIdsScript.SUPPORT_CENTER, Vector2i(20, 20), ["missing_support"])
	var result: Dictionary = SupportRegionMapperScript.bind([support], region_map)
	_assert.that(not bool(result.ok), "support mapping: unknown authored neighbor should fail")
	_assert.that((result.errors as Array).has("unknown_neighbor:%s:missing_support" % SupportIdsScript.SUPPORT_CENTER), "support mapping: unknown neighbor reason")


func _five_non_core_definitions() -> Array:
	return [
		_definition(SupportIdsScript.SUPPORT_LEFT_NORTH, Vector2i(7, 9), []),
		_definition(SupportIdsScript.SUPPORT_RIGHT_NORTH, Vector2i(32, 9), []),
		_definition(SupportIdsScript.SUPPORT_CENTER, Vector2i(20, 20), []),
		_definition(SupportIdsScript.SUPPORT_LEFT_SOUTH, Vector2i(7, 30), []),
		_definition(SupportIdsScript.SUPPORT_RIGHT_SOUTH, Vector2i(32, 30), []),
	]


func _definition(support_id: String, anchor: Vector2i, neighbors: Array) -> Dictionary:
	var typed_neighbors: Array[String] = []
	for neighbor in neighbors:
		typed_neighbors.append(str(neighbor))
	return SupportDefinitionScript.make(
		support_id,
		anchor,
		false,
		typed_neighbors,
		SupportDefinitionScript.ROUTE_ROLE_CENTER_TRANSFER,
		Vector2i(0, -1),
		Vector2i(0, 1),
		"directional_rear_rect_v1",
		"support_capture_v1",
		"territory_share_v1"
	)


func _make_region_map(definition: Dictionary):
	var region_map = RegionMapScript.new()
	region_map.configure_extent(Vector2i(40, 40))
	region_map.generate_from_definition(definition)
	return region_map


func _has_error_prefix(errors: Array, prefix: String) -> bool:
	for error in errors:
		if str(error).begins_with(prefix):
			return true
	return false
