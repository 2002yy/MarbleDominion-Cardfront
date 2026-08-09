extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const TopologyScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")
const ValidatorScript = preload("res://scripts/cardfront/support/graph/SupportTopologyValidator.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportTopologyValidatorTest] Checking fail-fast graph validation")
	await process_frame

	_test_default_duel_is_valid()
	_test_identity_and_edge_failures()
	_test_core_and_direction_failures()
	_test_single_path_is_rejected()

	_assert.report("[CardfrontSupportTopologyValidatorTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _valid_topology() -> Dictionary:
	return TopologyScript.from_support_definitions(DefaultMapScript.make(Vector2i(40, 40)).deployment_supports)


func _test_default_duel_is_valid() -> void:
	_assert.eq(ValidatorScript.validate(_valid_topology()), [], "topology validation: default_duel passes")


func _test_identity_and_edge_failures() -> void:
	var duplicate_node: Dictionary = _valid_topology()
	duplicate_node.nodes.append((duplicate_node.nodes[0] as Dictionary).duplicate(true))
	_assert.that(_has_prefix(ValidatorScript.validate(duplicate_node), "duplicate_support_id:"), "topology validation: duplicate stable ID fails")

	var unknown_endpoint: Dictionary = _valid_topology()
	unknown_endpoint.edges.append({"a": "missing", "b": str(unknown_endpoint.nodes[0].support_id)})
	_assert.that(_has_prefix(ValidatorScript.validate(unknown_endpoint), "unknown_edge_endpoint:"), "topology validation: unknown endpoint fails")

	var self_edge: Dictionary = _valid_topology()
	self_edge.edges.append({"a": "self", "b": "self"})
	_assert.that(_has_prefix(ValidatorScript.validate(self_edge), "self_edge:"), "topology validation: self-edge fails")

	var duplicate_edge: Dictionary = _valid_topology()
	var first: Dictionary = duplicate_edge.edges[0]
	duplicate_edge.edges.append({"a": first.b, "b": first.a})
	_assert.that(_has_prefix(ValidatorScript.validate(duplicate_edge), "duplicate_edge:"), "topology validation: reversed duplicate edge fails deterministically")


func _test_core_and_direction_failures() -> void:
	var bad_root: Dictionary = _valid_topology()
	bad_root.core_roots.erase(RulesScript.PLAYER_FACTION)
	_assert.that(_has_prefix(ValidatorScript.validate(bad_root), "missing_core_root:"), "topology validation: each duel side requires Core root")

	var bad_direction: Dictionary = _valid_topology()
	bad_direction.nodes[0].player_deploy_direction = Vector2i(1, 1)
	bad_direction.nodes[0].deployment_profile_id = ""
	var errors: Array = ValidatorScript.validate(bad_direction)
	_assert.that(_has_prefix(errors, "invalid_player_deploy_direction:"), "topology validation: diagonal direction fails")
	_assert.that(_has_prefix(errors, "missing_deployment_profile:"), "topology validation: missing deployment profile fails")


func _test_single_path_is_rejected() -> void:
	var topology: Dictionary = {
		"nodes": [
			_node("core_player", true),
			_node("middle", false),
			_node("core_ai", true),
		],
		"core_roots": {
			RulesScript.PLAYER_FACTION: "core_player",
			RulesScript.AI_FACTION: "core_ai",
		},
		"edges": [
			{"a": "core_player", "b": "middle"},
			{"a": "middle", "b": "core_ai"},
		],
	}
	_assert.that(ValidatorScript.validate(topology).has("missing_alternate_core_path"), "topology validation: a single Core-to-Core path is not a branch topology")


func _node(support_id: String, is_core: bool) -> Dictionary:
	return {
		"support_id": support_id,
		"is_core": is_core,
		"route_role": "fixture",
		"player_deploy_direction": Vector2i.UP,
		"ai_deploy_direction": Vector2i.DOWN,
		"deployment_profile_id": "fixture_profile",
	}


func _has_prefix(errors: Array, prefix: String) -> bool:
	for error in errors:
		if str(error).begins_with(prefix):
			return true
	return false
