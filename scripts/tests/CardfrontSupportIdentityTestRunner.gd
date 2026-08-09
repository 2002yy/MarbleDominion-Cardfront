extends SceneTree

const SupportDefinitionScript = preload("res://scripts/cardfront/support/DeploymentSupportDefinition.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportIdentityTest] Checking stable Support identity schema")
	await process_frame

	_test_frozen_default_duel_ids()
	_test_definition_schema()
	_test_identity_is_not_runtime_region_id()
	_test_legacy_bonus_fields_are_forbidden()
	_test_structural_validation()

	_assert.report("[CardfrontSupportIdentityTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_frozen_default_duel_ids() -> void:
	var expected: Array[String] = [
		"core_player",
		"support_left_south",
		"support_right_south",
		"support_center",
		"support_left_north",
		"support_right_north",
		"core_ai",
	]
	_assert.eq(SupportIdsScript.DEFAULT_DUEL_ALL, expected, "support ids: default_duel order and values are frozen")
	_assert.eq(SupportIdsScript.DEFAULT_DUEL_ALL.size(), 7, "support ids: default_duel should expose seven stable identities")
	_assert.eq(_unique_count(SupportIdsScript.DEFAULT_DUEL_ALL), 7, "support ids: identities should be unique")
	_assert.that(SupportIdsScript.is_core_id(SupportIdsScript.CORE_PLAYER), "support ids: player core classification")
	_assert.that(SupportIdsScript.is_core_id(SupportIdsScript.CORE_AI), "support ids: AI core classification")
	_assert.that(not SupportIdsScript.is_core_id(SupportIdsScript.SUPPORT_CENTER), "support ids: center is not a core")


func _test_definition_schema() -> void:
	var neighbors: Array[String] = [SupportIdsScript.CORE_PLAYER, SupportIdsScript.SUPPORT_LEFT_NORTH]
	var definition: Dictionary = SupportDefinitionScript.make(
		SupportIdsScript.SUPPORT_LEFT_SOUTH,
		Vector2i(7, 30),
		false,
		neighbors,
		SupportDefinitionScript.ROUTE_ROLE_LEFT,
		Vector2i(0, -1),
		Vector2i(0, 1),
		"directional_rear_rect_v1",
		"support_capture_v1",
		"territory_share_v1"
	)
	neighbors.append("mutation_must_not_leak")

	_assert.eq(SupportDefinitionScript.validate(definition), [], "support definition: complete authored data should validate")
	_assert.eq(str(definition.support_id), SupportIdsScript.SUPPORT_LEFT_SOUTH, "support definition: stable authored string is retained")
	_assert.eq(definition.anchor_cell, Vector2i(7, 30), "support definition: authored anchor is retained")
	_assert.eq((definition.authored_neighbors as Array).size(), 2, "support definition: neighbor input should be copied")
	for required_key in SupportDefinitionScript.REQUIRED_KEYS:
		_assert.that(definition.has(required_key), "support definition: required key %s" % required_key)


func _test_identity_is_not_runtime_region_id() -> void:
	var definition: Dictionary = _valid_definition()
	_assert.that(not definition.has("region_id"), "support identity: runtime region_id must not be part of the static schema")
	_assert.that(not definition.has("runtime_region_id"), "support identity: runtime mapping must not be persisted in the static definition")
	_assert.that(not definition.has("region_type"), "support identity: legacy Stronghold type must not define identity")
	_assert.that(not definition.has("lane_index"), "support identity: lane index must not define identity")


func _test_legacy_bonus_fields_are_forbidden() -> void:
	for forbidden_key in SupportDefinitionScript.FORBIDDEN_LEGACY_BONUS_KEYS:
		var definition: Dictionary = _valid_definition()
		definition[forbidden_key] = 1
		var expected_error: String = "forbidden_legacy_bonus:%s:%s" % [SupportIdsScript.SUPPORT_CENTER, forbidden_key]
		_assert.that(SupportDefinitionScript.validate(definition).has(expected_error), "support definition: reject %s" % forbidden_key)


func _test_structural_validation() -> void:
	var missing_id: Dictionary = _valid_definition()
	missing_id.support_id = ""
	_assert.that(SupportDefinitionScript.validate(missing_id).has("missing_support_id"), "support definition: empty stable id should fail")

	var self_neighbor: Dictionary = _valid_definition()
	self_neighbor.authored_neighbors = [SupportIdsScript.SUPPORT_CENTER]
	_assert.that(SupportDefinitionScript.validate(self_neighbor).has("self_neighbor:%s" % SupportIdsScript.SUPPORT_CENTER), "support definition: self-edge should fail")

	var duplicate_neighbor: Dictionary = _valid_definition()
	duplicate_neighbor.authored_neighbors = [SupportIdsScript.SUPPORT_LEFT_SOUTH, SupportIdsScript.SUPPORT_LEFT_SOUTH]
	_assert.that(SupportDefinitionScript.validate(duplicate_neighbor).has("duplicate_neighbor:%s:%s" % [SupportIdsScript.SUPPORT_CENTER, SupportIdsScript.SUPPORT_LEFT_SOUTH]), "support definition: duplicate edge should fail")


func _valid_definition() -> Dictionary:
	return SupportDefinitionScript.make(
		SupportIdsScript.SUPPORT_CENTER,
		Vector2i(20, 20),
		false,
		[SupportIdsScript.SUPPORT_LEFT_SOUTH, SupportIdsScript.SUPPORT_RIGHT_NORTH],
		SupportDefinitionScript.ROUTE_ROLE_CENTER_TRANSFER,
		Vector2i(0, -1),
		Vector2i(0, 1),
		"directional_rear_rect_v1",
		"support_capture_v1",
		"territory_share_v1"
	)


func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[str(value)] = true
	return unique.size()
