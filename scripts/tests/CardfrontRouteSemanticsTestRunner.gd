extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ResolverScript = preload("res://scripts/cardfront/support/graph/SupportConnectivityResolver.gd")

const PLAYER_CORE := "fixture_player_core"
const LEFT_SOUTH := "fixture_left_south"
const RIGHT_SOUTH := "fixture_right_south"
const CENTER := "fixture_center_transfer"
const LEFT_NORTH := "fixture_left_north"
const RIGHT_NORTH := "fixture_right_north"
const AI_CORE := "fixture_ai_core"

var _assert: TestAssert
var _topology: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	_topology = _branch_fixture_topology()
	print("[CardfrontRouteSemanticsTest] Checking pure branch semantics over SupportConnectivityResolver truth")

	_test_one_route_vs_two_routes()
	_test_deeper_single_route_vs_two_shallow_routes()
	_test_side_specific_roots_produce_different_route_truth()
	_test_isolated_claim_is_not_strategic_online()
	_test_center_transfer_is_not_mandatory_bottleneck()

	_assert.report("[CardfrontRouteSemanticsTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_one_route_vs_two_routes() -> void:
	var one_route := _resolve_player([PLAYER_CORE, LEFT_SOUTH])
	var two_routes := _resolve_player([PLAYER_CORE, LEFT_SOUTH, RIGHT_SOUTH])
	var one_state: Dictionary = _route_state(one_route, RulesScript.PLAYER_FACTION)
	var two_state: Dictionary = _route_state(two_routes, RulesScript.PLAYER_FACTION)

	_assert.eq(one_state.left_depth, 1, "route fixture: one-route advance reaches left stage one")
	_assert.eq(one_state.right_depth, 0, "route fixture: one-route advance leaves right route idle")
	_assert.eq(one_state.active_route_count, 1, "route fixture: one-route advance exposes one active route")
	_assert.eq(two_state.left_depth, 1, "route fixture: split advance reaches left stage one")
	_assert.eq(two_state.right_depth, 1, "route fixture: split advance reaches right stage one")
	_assert.eq(two_state.active_route_count, 2, "route fixture: split advance exposes two active routes")
	_assert.neq(_route_signature(one_state), _route_signature(two_state), "route fixture: advancing both routes is strategically distinct from advancing one")


func _test_deeper_single_route_vs_two_shallow_routes() -> void:
	var deep_left := _route_state(
		_resolve_player([PLAYER_CORE, LEFT_SOUTH, LEFT_NORTH]),
		RulesScript.PLAYER_FACTION
	)
	var shallow_split := _route_state(
		_resolve_player([PLAYER_CORE, LEFT_SOUTH, RIGHT_SOUTH]),
		RulesScript.PLAYER_FACTION
	)

	_assert.eq(deep_left.active_route_count, 1, "route fixture: deeper single route still counts as one route")
	_assert.eq(deep_left.max_depth, 2, "route fixture: deeper single route reaches depth two")
	_assert.eq(shallow_split.active_route_count, 2, "route fixture: split pressure owns more active routes")
	_assert.eq(shallow_split.max_depth, 1, "route fixture: split pressure remains shallow")
	_assert.neq(_route_signature(deep_left), _route_signature(shallow_split), "route fixture: stronger/fewer and weaker/more routes remain separate strategic outputs")


func _test_side_specific_roots_produce_different_route_truth() -> void:
	var claims: Dictionary = _claims_for([
		PLAYER_CORE,
		LEFT_SOUTH,
		LEFT_NORTH,
	])
	claims[AI_CORE] = RulesScript.AI_FACTION
	claims[RIGHT_NORTH] = RulesScript.AI_FACTION
	claims[RIGHT_SOUTH] = RulesScript.AI_FACTION
	var operational: Dictionary = _operational_for(claims.keys())

	var player_result: Dictionary = ResolverScript.resolve(
		_topology,
		RulesScript.PLAYER_FACTION,
		claims,
		operational
	)
	var ai_result: Dictionary = ResolverScript.resolve(
		_topology,
		RulesScript.AI_FACTION,
		claims,
		operational
	)
	var player_state: Dictionary = _route_state(player_result, RulesScript.PLAYER_FACTION)
	var ai_state: Dictionary = _route_state(ai_result, RulesScript.AI_FACTION)

	_assert.eq(player_state.left_depth, 2, "route fixture: player root reaches the physical left route")
	_assert.eq(player_state.right_depth, 0, "route fixture: player root cannot borrow AI-owned right route")
	_assert.eq(ai_state.left_depth, 0, "route fixture: AI root cannot borrow player-owned left route")
	_assert.eq(ai_state.right_depth, 2, "route fixture: AI root reaches the physical right route")
	_assert.neq(player_result.connected_support_ids, ai_result.connected_support_ids, "route fixture: player and AI side roots produce side-specific connectivity truth")


func _test_isolated_claim_is_not_strategic_online() -> void:
	var claims: Dictionary = _claims_for([PLAYER_CORE, LEFT_NORTH])
	var operational: Dictionary = _operational_for(claims.keys())
	var result: Dictionary = ResolverScript.resolve(
		_topology,
		RulesScript.PLAYER_FACTION,
		claims,
		operational
	)
	var state: Dictionary = _route_state(result, RulesScript.PLAYER_FACTION)

	_assert.eq(result.connected_support_ids, [PLAYER_CORE], "route fixture: isolated forward Claim is not connected")
	_assert.that(LEFT_NORTH in result.unconnected_claimed_support_ids, "route fixture: isolated forward Claim stays explicitly offline")
	_assert.eq(state.left_depth, 0, "route fixture: isolated Claim contributes no strategic route depth")
	_assert.eq(state.active_route_count, 0, "route fixture: isolated Claim contributes no active route")


func _test_center_transfer_is_not_mandatory_bottleneck() -> void:
	var claims: Dictionary = _claims_for([PLAYER_CORE, LEFT_SOUTH, LEFT_NORTH, CENTER])
	var operational: Dictionary = _operational_for(claims.keys())
	operational[CENTER] = false
	var result: Dictionary = ResolverScript.resolve(
		_topology,
		RulesScript.PLAYER_FACTION,
		claims,
		operational
	)
	var state: Dictionary = _route_state(result, RulesScript.PLAYER_FACTION)

	_assert.that(LEFT_SOUTH in result.connected_support_ids, "route fixture: left south remains connected with transfer disabled")
	_assert.that(LEFT_NORTH in result.connected_support_ids, "route fixture: vertical left route reaches depth two without center transfer")
	_assert.that(CENTER not in result.connected_support_ids, "route fixture: disabled center transfer stays offline")
	_assert.eq(state.left_depth, 2, "route fixture: center transfer is not a mandatory bottleneck")
	_assert.that(not bool(state.transfer_online), "route fixture: route state records transfer offline independently")


func _resolve_player(owned_ids: Array) -> Dictionary:
	var claims: Dictionary = _claims_for(owned_ids)
	return ResolverScript.resolve(
		_topology,
		RulesScript.PLAYER_FACTION,
		claims,
		_operational_for(claims.keys())
	)


func _claims_for(owned_ids: Array) -> Dictionary:
	var claims: Dictionary = {}
	for support_id in owned_ids:
		claims[str(support_id)] = RulesScript.PLAYER_FACTION
	return claims


func _operational_for(support_ids: Array) -> Dictionary:
	var operational: Dictionary = {}
	for support_id in support_ids:
		operational[str(support_id)] = true
	return operational


func _route_state(connectivity: Dictionary, side: int) -> Dictionary:
	var connected: Array = connectivity.get("connected_support_ids", []) as Array
	# Physical route identity is authored topology truth. Direction of progress is side-specific:
	# player advances south -> north; AI advances north -> south. Counts remain per-route dimensions,
	# deliberately not collapsed into an overall route/power score.
	var left_steps: Array = [LEFT_SOUTH, LEFT_NORTH]
	var right_steps: Array = [RIGHT_SOUTH, RIGHT_NORTH]
	if side == RulesScript.AI_FACTION:
		left_steps.reverse()
		right_steps.reverse()
	var left_depth: int = _contiguous_depth(connected, left_steps)
	var right_depth: int = _contiguous_depth(connected, right_steps)
	return {
		"left_depth": left_depth,
		"right_depth": right_depth,
		"active_route_count": int(left_depth > 0) + int(right_depth > 0),
		"max_depth": maxi(left_depth, right_depth),
		"transfer_online": CENTER in connected,
	}


func _contiguous_depth(connected: Array, ordered_steps: Array) -> int:
	var depth: int = 0
	for support_id in ordered_steps:
		if support_id not in connected:
			break
		depth += 1
	return depth


func _route_signature(state: Dictionary) -> String:
	return "%d|%d|%d|%d|%s" % [
		int(state.left_depth),
		int(state.right_depth),
		int(state.active_route_count),
		int(state.max_depth),
		str(bool(state.transfer_online)),
	]


func _branch_fixture_topology() -> Dictionary:
	var nodes: Array = []
	for spec in [
		[PLAYER_CORE, true, "CORE"],
		[LEFT_SOUTH, false, "LEFT"],
		[RIGHT_SOUTH, false, "RIGHT"],
		[CENTER, false, "CENTER_TRANSFER"],
		[LEFT_NORTH, false, "LEFT"],
		[RIGHT_NORTH, false, "RIGHT"],
		[AI_CORE, true, "CORE"],
	]:
		nodes.append({
			"support_id": str(spec[0]),
			"is_core": bool(spec[1]),
			"route_role": str(spec[2]),
			"player_deploy_direction": Vector2i.UP,
			"ai_deploy_direction": Vector2i.DOWN,
			"deployment_profile_id": "fixture_profile",
		})
	return {
		"nodes": nodes,
		"core_roots": {
			RulesScript.PLAYER_FACTION: PLAYER_CORE,
			RulesScript.AI_FACTION: AI_CORE,
		},
		"edges": [
			{"a": PLAYER_CORE, "b": LEFT_SOUTH},
			{"a": PLAYER_CORE, "b": RIGHT_SOUTH},
			{"a": LEFT_SOUTH, "b": LEFT_NORTH},
			{"a": RIGHT_SOUTH, "b": RIGHT_NORTH},
			{"a": LEFT_SOUTH, "b": CENTER},
			{"a": RIGHT_SOUTH, "b": CENTER},
			{"a": CENTER, "b": LEFT_NORTH},
			{"a": CENTER, "b": RIGHT_NORTH},
			{"a": LEFT_NORTH, "b": AI_CORE},
			{"a": RIGHT_NORTH, "b": AI_CORE},
		],
	}
