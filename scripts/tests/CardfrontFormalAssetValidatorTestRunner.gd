extends SceneTree

const ValidatorScript = preload("res://scripts/cardfront/environment/CardfrontFormalAssetValidator.gd")
const FIXTURE_ROOT := "res://scripts/tests/fixtures/formal_assets/"
const CURRENT_FORMAL_HQ := "res://assets/cardfront_environment/formal/hq/hq_common.glb"

var _assert: TestAssert
var _validator


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	_validator = ValidatorScript.new()
	print("[CardfrontFormalAssetValidatorTest] Starting D22 validator tests")

	_test_valid_tower_contract_passes()
	_test_root_transform_fails_closed()
	_test_visible_transform_fails_closed()
	_test_unknown_node_prefix_fails_closed()
	_test_unknown_material_role_fails_closed()
	_test_forbidden_authority_nodes_fail_closed()
	_test_missing_required_socket_fails_closed()
	_test_ground_contact_fails_closed()
	_test_socket_forward_fails_closed()
	_test_null_and_missing_resources_fail_closed()
	_test_current_hq_is_importable_but_not_d22_admitted()

	_assert.report("[CardfrontFormalAssetValidatorTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_valid_tower_contract_passes() -> void:
	var result := _validate_fixture("valid_tower_module.tscn")
	_assert.that(bool(result.get("valid", false)), "D22 valid fixture: normalized semantic Tower module should pass")
	_assert.eq(_error_codes(result), PackedStringArray(), "D22 valid fixture: should have no errors")
	var facts: Dictionary = result.get("facts", {})
	_assert.eq(int(facts.get("visible_geometry_count", 0)), 1, "D22 valid fixture: should count visible geometry")
	_assert.eq(int(facts.get("material_slot_count", 0)), 1, "D22 valid fixture: should count material slots")
	_assert.eq(int(facts.get("required_node_count", 0)), 3, "D22 valid fixture: should audit every required Tower node")


func _test_root_transform_fails_closed() -> void:
	var path := FIXTURE_ROOT + "invalid_root_transform.tscn"
	var scene: PackedScene = load(path)
	var instance := scene.instantiate()
	var before := (instance as Node3D).transform
	var result: Dictionary = _validator.validate_instance(instance, ValidatorScript.tower_module_contract())
	_assert.that(not bool(result.get("valid", true)), "D22 root transform: invalid fixture must fail")
	_assert.that(_has_error(result, "ROOT_TRANSFORM_NOT_IDENTITY"), "D22 root transform: should report identity violation")
	_assert.eq((instance as Node3D).transform, before, "D22 root transform: validator must not heal the fixture")
	instance.free()


func _test_visible_transform_fails_closed() -> void:
	var result := _validate_fixture("invalid_visible_transform.tscn")
	_assert.that(not bool(result.get("valid", true)), "D22 visible transform: invalid fixture must fail")
	_assert.that(_has_error(result, "NODE_SCALE_NOT_APPLIED"), "D22 visible transform: should report unapplied scale")
	_assert.that(_has_error(result, "VISIBLE_TRANSFORM_NOT_APPLIED"), "D22 visible transform: should report unapplied mesh basis")


func _test_unknown_node_prefix_fails_closed() -> void:
	var result := _validate_fixture("invalid_node_prefix.tscn")
	_assert.that(not bool(result.get("valid", true)), "D22 node prefix: invalid fixture must fail")
	_assert.that(_has_error(result, "NODE_PREFIX_UNKNOWN"), "D22 node prefix: should reject unknown exported helper")


func _test_unknown_material_role_fails_closed() -> void:
	var result := _validate_fixture("invalid_material_role.tscn")
	_assert.that(not bool(result.get("valid", true)), "D21 material role: invalid fixture must fail")
	_assert.that(_has_error(result, "MATERIAL_ROLE_UNKNOWN"), "D21 material role: MAT_* compatibility name must not enter Formal admission")


func _test_forbidden_authority_nodes_fail_closed() -> void:
	var result := _validate_fixture("invalid_forbidden_nodes.tscn")
	_assert.that(not bool(result.get("valid", true)), "D22 forbidden nodes: invalid fixture must fail")
	_assert.that(_has_error(result, "FORBIDDEN_COLLISION_NODE"), "D22 forbidden nodes: collision authority must be rejected")
	_assert.that(_has_error(result, "FORBIDDEN_CAMERA_NODE"), "D22 forbidden nodes: authoring camera must be rejected")
	_assert.that(_has_error(result, "FORBIDDEN_LIGHT_NODE"), "D22 forbidden nodes: authoring light must be rejected")


func _test_missing_required_socket_fails_closed() -> void:
	var result := _validate_fixture("invalid_missing_socket.tscn")
	_assert.that(not bool(result.get("valid", true)), "D22 required socket: invalid fixture must fail")
	_assert.that(_has_error(result, "REQUIRED_NODE_MISSING"), "D22 required socket: missing SOCKET_Muzzle must be explicit")


func _test_ground_contact_fails_closed() -> void:
	var result := _validate_fixture("invalid_ground_contact.tscn")
	_assert.that(not bool(result.get("valid", true)), "D22 ground contact: invalid fixture must fail")
	_assert.that(_has_error(result, "GROUND_CONTACT_INVALID"), "D22 ground contact: elevated geometry must not be admitted")
	_assert.that(_has_error(result, "GROUND_CENTER_INVALID"), "D22 ground contact: off-center footprint must not be admitted")


func _test_socket_forward_fails_closed() -> void:
	var result := _validate_fixture("invalid_socket_forward.tscn")
	_assert.that(not bool(result.get("valid", true)), "D22 socket direction: invalid fixture must fail")
	_assert.that(_has_error(result, "SOCKET_FORWARD_INVALID"), "D22 socket direction: local +Z must face model +Z")


func _test_null_and_missing_resources_fail_closed() -> void:
	var null_result: Dictionary = _validator.validate_packed_scene(null, ValidatorScript.tower_module_contract())
	_assert.that(_has_error(null_result, "PACKED_SCENE_NULL"), "D22 resource: null scene should fail closed")
	var missing_result: Dictionary = _validator.validate_resource_path("res://missing/formal_asset.glb", ValidatorScript.tower_module_contract())
	_assert.that(_has_error(missing_result, "RESOURCE_MISSING"), "D22 resource: missing path should fail closed")


func _test_current_hq_is_importable_but_not_d22_admitted() -> void:
	_assert.that(ResourceLoader.exists(CURRENT_FORMAL_HQ), "D22 migration evidence: current Formal HQ should remain importable")
	var result: Dictionary = _validator.validate_resource_path(CURRENT_FORMAL_HQ, {"require_visible_geometry": true})
	_assert.that(not bool(result.get("valid", true)), "D22 migration evidence: importable legacy-named HQ must not be silently admitted")
	_assert.that(_has_error(result, "ROOT_PREFIX_INVALID"), "D22 migration evidence: current HQ root naming debt should be explicit")
	_assert.that(_has_error(result, "MATERIAL_ROLE_UNKNOWN"), "D22 migration evidence: current MAT_* material debt should be explicit")


func _validate_fixture(file_name: String) -> Dictionary:
	return _validator.validate_resource_path(
		FIXTURE_ROOT + file_name,
		ValidatorScript.tower_module_contract()
	)


func _has_error(result: Dictionary, code: String) -> bool:
	return _error_codes(result).has(code)


func _error_codes(result: Dictionary) -> PackedStringArray:
	var codes := PackedStringArray()
	for error_value in result.get("errors", []):
		var error: Dictionary = error_value
		codes.append(str(error.get("code", "")))
	return codes
