extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const TopologyScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")
const ResolverScript = preload("res://scripts/cardfront/support/graph/SupportConnectivityResolver.gd")

var _assert: TestAssert
var _topology: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportConnectivityResolverTest] Checking pure traversal")
	await process_frame
	_topology = TopologyScript.from_support_definitions(DefaultMapScript.make(Vector2i(40, 40)).deployment_supports)

	_test_all_owned_operational_connects()
	_test_claimed_but_disabled_is_reported_offline()
	_test_opponent_claim_never_traverses()
	_test_invalid_topology_fails_closed()

	_assert.report("[CardfrontSupportConnectivityResolverTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_all_owned_operational_connects() -> void:
	var claims: Dictionary = {}
	var operational: Dictionary = {}
	for node in _topology.nodes as Array:
		claims[str(node.support_id)] = RulesScript.PLAYER_FACTION
		operational[str(node.support_id)] = true
	var result: Dictionary = ResolverScript.resolve(_topology, RulesScript.PLAYER_FACTION, claims, operational)
	_assert.that(bool(result.valid), "connectivity resolver: valid topology resolves")
	_assert.eq((result.connected_support_ids as Array).size(), 7, "connectivity resolver: all owned operational nodes connect")
	_assert.eq(result.unconnected_claimed_support_ids, [], "connectivity resolver: no owned nodes remain offline")
	_assert.eq(int(result.revision), 0, "connectivity resolver: pure result has neutral revision before cache owner")


func _test_claimed_but_disabled_is_reported_offline() -> void:
	var claims: Dictionary = {
		SupportIdsScript.CORE_PLAYER: RulesScript.PLAYER_FACTION,
		SupportIdsScript.SUPPORT_LEFT_SOUTH: RulesScript.PLAYER_FACTION,
	}
	var operational: Dictionary = {
		SupportIdsScript.CORE_PLAYER: true,
		SupportIdsScript.SUPPORT_LEFT_SOUTH: false,
	}
	var result: Dictionary = ResolverScript.resolve(_topology, RulesScript.PLAYER_FACTION, claims, operational)
	_assert.eq(result.connected_support_ids, [SupportIdsScript.CORE_PLAYER], "connectivity resolver: Core remains connected")
	_assert.eq(result.unconnected_claimed_support_ids, [SupportIdsScript.SUPPORT_LEFT_SOUTH], "connectivity resolver: disabled claimed node is CapturedOffline/Disabled input")


func _test_opponent_claim_never_traverses() -> void:
	var claims: Dictionary = {
		SupportIdsScript.CORE_PLAYER: RulesScript.PLAYER_FACTION,
		SupportIdsScript.SUPPORT_LEFT_SOUTH: RulesScript.AI_FACTION,
		SupportIdsScript.SUPPORT_LEFT_NORTH: RulesScript.PLAYER_FACTION,
	}
	var operational: Dictionary = {
		SupportIdsScript.CORE_PLAYER: true,
		SupportIdsScript.SUPPORT_LEFT_SOUTH: true,
		SupportIdsScript.SUPPORT_LEFT_NORTH: true,
	}
	var result: Dictionary = ResolverScript.resolve(_topology, RulesScript.PLAYER_FACTION, claims, operational)
	_assert.eq(result.connected_support_ids, [SupportIdsScript.CORE_PLAYER], "connectivity resolver: opponent Claim is not a traversal bridge")
	_assert.eq(result.unconnected_claimed_support_ids, [SupportIdsScript.SUPPORT_LEFT_NORTH], "connectivity resolver: isolated own Claim remains offline")


func _test_invalid_topology_fails_closed() -> void:
	var invalid: Dictionary = _topology.duplicate(true)
	invalid.edges.append({"a": "missing", "b": SupportIdsScript.CORE_PLAYER})
	var result: Dictionary = ResolverScript.resolve(invalid, RulesScript.PLAYER_FACTION, {}, {})
	_assert.that(not bool(result.valid), "connectivity resolver: invalid topology fails closed")
	_assert.eq(result.connected_support_ids, [], "connectivity resolver: invalid topology returns no connectivity")
	_assert.that(not (result.errors as Array).is_empty(), "connectivity resolver: validation errors remain auditable")
