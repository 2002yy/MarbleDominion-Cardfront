extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const TopologyScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")
const ResolverScript = preload("res://scripts/cardfront/support/graph/SupportConnectivityResolver.gd")

var _assert: TestAssert
var _topology: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportConnectivityTruthTest] Checking eight frozen graph scenarios")
	await process_frame
	_topology = TopologyScript.from_support_definitions(DefaultMapScript.make(Vector2i(40, 40)).deployment_supports)

	_test_1_core_only()
	_test_2_core_to_main_a_online()
	_test_3_core_to_branch_a_online()
	_test_4_main_upstream_disabled()
	_test_5_branch_remains_online()
	_test_6_isolated_backline_claim_offline()
	_test_7_reconnect_without_recapture()
	_test_8_opponent_claim_not_traversed()

	_assert.report("[CardfrontSupportConnectivityTruthTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_1_core_only() -> void:
	var result: Dictionary = _resolve(_states([Ids.CORE_PLAYER]))
	_assert.eq(result.connected_support_ids, [Ids.CORE_PLAYER], "truth 1: Core only")


func _test_2_core_to_main_a_online() -> void:
	var result: Dictionary = _resolve(_states([Ids.CORE_PLAYER, Ids.SUPPORT_LEFT_SOUTH]))
	_assert.eq(result.connected_support_ids, _sorted([Ids.CORE_PLAYER, Ids.SUPPORT_LEFT_SOUTH]), "truth 2: Core to main upstream online")


func _test_3_core_to_branch_a_online() -> void:
	var result: Dictionary = _resolve(_states([Ids.CORE_PLAYER, Ids.SUPPORT_RIGHT_SOUTH]))
	_assert.eq(result.connected_support_ids, _sorted([Ids.CORE_PLAYER, Ids.SUPPORT_RIGHT_SOUTH]), "truth 3: Core to alternate branch upstream online")


func _test_4_main_upstream_disabled() -> void:
	var states: Dictionary = _states([Ids.CORE_PLAYER, Ids.SUPPORT_LEFT_NORTH])
	states.claims[Ids.SUPPORT_LEFT_SOUTH] = RulesScript.PLAYER_FACTION
	states.operational[Ids.SUPPORT_LEFT_SOUTH] = false
	var result: Dictionary = _resolve(states)
	_assert.eq(result.connected_support_ids, [Ids.CORE_PLAYER], "truth 4: disabled main upstream blocks downstream")
	_assert.eq(result.unconnected_claimed_support_ids, _sorted([Ids.SUPPORT_LEFT_SOUTH, Ids.SUPPORT_LEFT_NORTH]), "truth 4: upstream and downstream Claims remain auditable offline")


func _test_5_branch_remains_online() -> void:
	var states: Dictionary = _states([Ids.CORE_PLAYER, Ids.SUPPORT_RIGHT_SOUTH, Ids.SUPPORT_RIGHT_NORTH])
	states.claims[Ids.SUPPORT_LEFT_SOUTH] = RulesScript.PLAYER_FACTION
	states.operational[Ids.SUPPORT_LEFT_SOUTH] = false
	var result: Dictionary = _resolve(states)
	_assert.eq(result.connected_support_ids, _sorted([Ids.CORE_PLAYER, Ids.SUPPORT_RIGHT_SOUTH, Ids.SUPPORT_RIGHT_NORTH]), "truth 5: alternate branch survives main failure")
	_assert.eq(result.unconnected_claimed_support_ids, [Ids.SUPPORT_LEFT_SOUTH], "truth 5: failed main upstream stays offline")


func _test_6_isolated_backline_claim_offline() -> void:
	var result: Dictionary = _resolve(_states([Ids.CORE_PLAYER, Ids.SUPPORT_LEFT_NORTH]))
	_assert.eq(result.connected_support_ids, [Ids.CORE_PLAYER], "truth 6: isolated enemy-backline Claim does not connect")
	_assert.eq(result.unconnected_claimed_support_ids, [Ids.SUPPORT_LEFT_NORTH], "truth 6: isolated Claim is CapturedOffline")


func _test_7_reconnect_without_recapture() -> void:
	var states: Dictionary = _states([Ids.CORE_PLAYER, Ids.SUPPORT_LEFT_NORTH])
	var before: Dictionary = _resolve(states)
	var claim_before: int = int(states.claims[Ids.SUPPORT_LEFT_NORTH])
	states.claims[Ids.SUPPORT_LEFT_SOUTH] = RulesScript.PLAYER_FACTION
	states.operational[Ids.SUPPORT_LEFT_SOUTH] = true
	var after: Dictionary = _resolve(states)
	_assert.that(Ids.SUPPORT_LEFT_NORTH in before.unconnected_claimed_support_ids, "truth 7: downstream begins offline")
	_assert.that(Ids.SUPPORT_LEFT_NORTH in after.connected_support_ids, "truth 7: upstream reconnect restores downstream Online eligibility")
	_assert.eq(int(states.claims[Ids.SUPPORT_LEFT_NORTH]), claim_before, "truth 7: reconnect does not recapture downstream Claim")


func _test_8_opponent_claim_not_traversed() -> void:
	var states: Dictionary = _states([Ids.CORE_PLAYER, Ids.SUPPORT_LEFT_NORTH])
	states.claims[Ids.SUPPORT_LEFT_SOUTH] = RulesScript.AI_FACTION
	states.operational[Ids.SUPPORT_LEFT_SOUTH] = true
	var result: Dictionary = _resolve(states)
	_assert.eq(result.connected_support_ids, [Ids.CORE_PLAYER], "truth 8: opponent Claim never participates in own traversal")
	_assert.eq(result.unconnected_claimed_support_ids, [Ids.SUPPORT_LEFT_NORTH], "truth 8: own downstream remains offline behind opponent")


func _states(online_player_ids: Array) -> Dictionary:
	var claims: Dictionary = {}
	var operational: Dictionary = {}
	for support_id in online_player_ids:
		claims[str(support_id)] = RulesScript.PLAYER_FACTION
		operational[str(support_id)] = true
	return {"claims": claims, "operational": operational}


func _resolve(states: Dictionary) -> Dictionary:
	return ResolverScript.resolve(_topology, RulesScript.PLAYER_FACTION, states.claims, states.operational)


func _sorted(values: Array) -> Array:
	var result: Array = values.duplicate()
	result.sort()
	return result
