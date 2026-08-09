extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const TopologyScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportTopologyContractTest] Checking pure topology projection")
	await process_frame

	_test_default_duel_projection()
	_test_projection_is_deterministic()
	_test_topology_excludes_runtime_and_gameplay_truth()

	_assert.report("[CardfrontSupportTopologyContractTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_default_duel_projection() -> void:
	var topology: Dictionary = TopologyScript.from_support_definitions(DefaultMapScript.make(Vector2i(40, 40)).deployment_supports)
	_assert.eq((topology.nodes as Array).size(), 7, "topology contract: seven stable nodes")
	_assert.eq((topology.edges as Array).size(), 10, "topology contract: ten normalized authored edges")
	_assert.eq(str(topology.core_roots[RulesScript.PLAYER_FACTION]), SupportIdsScript.CORE_PLAYER, "topology contract: player Core root")
	_assert.eq(str(topology.core_roots[RulesScript.AI_FACTION]), SupportIdsScript.CORE_AI, "topology contract: AI Core root")
	var node_ids: Array = (topology.nodes as Array).map(func(node): return str(node.support_id))
	var sorted_ids: Array = SupportIdsScript.DEFAULT_DUEL_ALL.duplicate()
	sorted_ids.sort()
	_assert.eq(node_ids, sorted_ids, "topology contract: nodes sort by stable support_id")
	for edge in topology.edges as Array:
		_assert.that(str(edge.a) <= str(edge.b), "topology contract: every edge is normalized")


func _test_projection_is_deterministic() -> void:
	var definitions: Array = DefaultMapScript.make(Vector2i(40, 40)).deployment_supports
	var reversed: Array = definitions.duplicate(true)
	reversed.reverse()
	for definition in reversed:
		(definition.authored_neighbors as Array).reverse()
	_assert.eq(TopologyScript.from_support_definitions(definitions), TopologyScript.from_support_definitions(reversed), "topology contract: definition/neighbor order does not affect projection")


func _test_topology_excludes_runtime_and_gameplay_truth() -> void:
	var topology: Dictionary = TopologyScript.from_support_definitions(DefaultMapScript.make(Vector2i(40, 40)).deployment_supports)
	var forbidden_keys: Array[String] = [
		"capture_progress", "capture_side", "claim_owner", "operational", "network_connected", "online",
		"region_id", "runtime_region_id", "bonus", "shot_bonus", "gate_openness", "rarity", "route_tendency", "ai_profile",
	]
	for node in topology.nodes as Array:
		_assert.eq((node as Dictionary).keys().size(), 6, "topology contract: node has exact structural fields")
		for key in forbidden_keys:
			_assert.that(not (node as Dictionary).has(key), "topology contract: node excludes %s" % key)
	for key in forbidden_keys:
		_assert.that(not topology.has(key), "topology contract: root excludes %s" % key)
