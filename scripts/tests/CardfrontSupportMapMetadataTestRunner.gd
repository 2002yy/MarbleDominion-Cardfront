extends SceneTree

const CardfrontMapDefinitionScript = preload("res://scripts/cardfront/maps/CardfrontMapDefinition.gd")
const DefaultDuelMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const SupportDefinitionScript = preload("res://scripts/cardfront/support/DeploymentSupportDefinition.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SupportMapMetadataScript = preload("res://scripts/cardfront/support/DeploymentSupportMapMetadata.gd")
const SupportRegionMapperScript = preload("res://scripts/cardfront/support/DeploymentSupportRegionMapper.gd")
const SupportTopologyContractScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")
const SupportDeploymentAuthorityScript = preload("res://scripts/cardfront/support/CardfrontSupportDeploymentAuthority.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontSupportMapMetadataTest] Checking authored topology metadata and runtime binding")
	await process_frame

	_test_default_duel_metadata()
	_test_supported_extent_anchors()
	_test_invalid_topology_fails_map_setup()
	_test_structurally_valid_but_frozen_wrong_topology_fails()
	_test_metadata_contains_no_runtime_or_bonus_truth()
	_test_runtime_authority_binds_default_map_metadata()
	_test_runtime_branch_failure_matrix()

	_assert.report("[CardfrontSupportMapMetadataTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_default_duel_metadata() -> void:
	var definition: Dictionary = DefaultDuelMapScript.make(Vector2i(40, 40))
	var supports: Array = definition.get(SupportMapMetadataScript.METADATA_KEY, []) as Array
	var by_id: Dictionary = _by_id(supports)
	_assert.eq(CardfrontMapDefinitionScript.validate(definition), [], "support metadata: default_duel map should validate")
	_assert.eq(supports.size(), 7, "support metadata: seven authored nodes")
	_assert.eq(_sorted_strings(by_id.keys()), _sorted_strings(SupportIdsScript.DEFAULT_DUEL_ALL), "support metadata: exact frozen IDs")
	_assert.eq(_undirected_edges(supports), _expected_edges(), "support metadata: exact ten frozen edges")
	_assert.eq(str(by_id[SupportIdsScript.SUPPORT_LEFT_SOUTH].route_role), SupportDefinitionScript.ROUTE_ROLE_LEFT, "support metadata: left route role")
	_assert.eq(str(by_id[SupportIdsScript.SUPPORT_RIGHT_NORTH].route_role), SupportDefinitionScript.ROUTE_ROLE_RIGHT, "support metadata: right route role")
	_assert.eq(str(by_id[SupportIdsScript.SUPPORT_CENTER].route_role), SupportDefinitionScript.ROUTE_ROLE_CENTER_TRANSFER, "support metadata: center transfer role")

	var region_map = RegionMapScript.new()
	region_map.configure_extent(Vector2i(40, 40))
	region_map.generate_from_definition(definition)
	var mapping: Dictionary = SupportRegionMapperScript.bind(supports, region_map)
	_assert.that(bool(mapping.ok), "support metadata: authored default anchors bind to current regions")
	_assert.eq((mapping.bindings as Dictionary).size(), 5, "support metadata: cores remain outside legacy region binding")


func _test_supported_extent_anchors() -> void:
	var expected: Dictionary = {
		Vector2i(40, 40): [Vector2i(7, 9), Vector2i(32, 9), Vector2i(20, 20), Vector2i(7, 30), Vector2i(32, 30)],
		Vector2i(50, 50): [Vector2i(9, 11), Vector2i(40, 11), Vector2i(25, 25), Vector2i(9, 38), Vector2i(40, 38)],
		Vector2i(40, 50): [Vector2i(7, 11), Vector2i(32, 11), Vector2i(20, 25), Vector2i(7, 38), Vector2i(32, 38)],
		Vector2i(40, 60): [Vector2i(7, 13), Vector2i(32, 13), Vector2i(20, 30), Vector2i(7, 46), Vector2i(32, 46)],
	}
	var ordered_ids: Array[String] = [
		SupportIdsScript.SUPPORT_LEFT_NORTH,
		SupportIdsScript.SUPPORT_RIGHT_NORTH,
		SupportIdsScript.SUPPORT_CENTER,
		SupportIdsScript.SUPPORT_LEFT_SOUTH,
		SupportIdsScript.SUPPORT_RIGHT_SOUTH,
	]
	for extent in expected.keys():
		var by_id: Dictionary = _by_id(DefaultDuelMapScript.make(extent).deployment_supports)
		var actual: Array = []
		for support_id in ordered_ids:
			actual.append(by_id[support_id].anchor_cell)
		_assert.eq(actual, expected[extent], "support metadata: authored anchors for %s" % str(extent))


func _test_invalid_topology_fails_map_setup() -> void:
	var invalid: Dictionary = DefaultDuelMapScript.make(Vector2i(40, 40))
	var supports: Array = (invalid.deployment_supports as Array).duplicate(true)
	supports[1].authored_neighbors = ["missing_support"]
	invalid.deployment_supports = supports
	var errors: Array = CardfrontMapDefinitionScript.validate(invalid)
	_assert.that(_has_error_prefix(errors, "unknown_neighbor:"), "support metadata: unknown neighbor validation")

	var region_map = RegionMapScript.new()
	region_map.configure_extent(Vector2i(40, 40))
	region_map.generate_from_definition(invalid)
	_assert.eq(region_map.get_controllable_region_ids(), [], "support metadata: invalid authored topology fails map setup")
	_assert.eq(region_map.map_definition, {}, "support metadata: invalid map definition is not retained")


func _test_structurally_valid_but_frozen_wrong_topology_fails() -> void:
	var invalid: Dictionary = DefaultDuelMapScript.make(Vector2i(40, 40))
	var supports: Array = (invalid.deployment_supports as Array).duplicate(true)
	for index in range(supports.size()):
		var support: Dictionary = supports[index] as Dictionary
		var support_id: String = str(support.support_id)
		var neighbors: Array = (support.authored_neighbors as Array).duplicate()
		if support_id == SupportIdsScript.SUPPORT_CENTER:
			neighbors.erase(SupportIdsScript.SUPPORT_LEFT_NORTH)
			support.authored_neighbors = neighbors
			supports[index] = support
		elif support_id == SupportIdsScript.SUPPORT_LEFT_NORTH:
			neighbors.erase(SupportIdsScript.SUPPORT_CENTER)
			support.authored_neighbors = neighbors
			supports[index] = support
	invalid.deployment_supports = supports
	var errors: Array = CardfrontMapDefinitionScript.validate(invalid)
	_assert.that(errors.has("default_duel_topology_mismatch"), "support metadata: self-consistent but frozen-wrong topology should fail")


func _test_metadata_contains_no_runtime_or_bonus_truth() -> void:
	for definition in DefaultDuelMapScript.make(Vector2i(40, 40)).deployment_supports as Array:
		for forbidden_key in [
			"region_id", "runtime_region_id", "claim_owner", "operational", "network_connected", "online",
			"shot_bonus", "attack_bonus", "draft_choice_bonus", "resource_income", "rarity_bonus",
		]:
			_assert.that(not (definition as Dictionary).has(forbidden_key), "support metadata: %s excludes %s" % [definition.support_id, forbidden_key])


func _test_runtime_authority_binds_default_map_metadata() -> void:
	var definition: Dictionary = DefaultDuelMapScript.make(Vector2i(40, 40))
	var supports: Array = definition.deployment_supports as Array
	var by_id: Dictionary = _by_id(supports)
	var authority = SupportDeploymentAuthorityScript.new()

	_assert.that(authority.setup(definition), "support runtime: default_duel authored graph should configure authority")
	var debug: Dictionary = authority.debug_snapshot()
	_assert.eq(debug.validation_errors, [], "support runtime: authored topology should validate before live use")
	_assert.eq(debug.topology, SupportTopologyContractScript.from_support_definitions(supports), "support runtime: topology must be projected from the real default map definitions")

	var core_only: Dictionary = authority.deployment_context(CardfrontRulesScript.PLAYER_FACTION)
	_assert.eq(str(core_only.core_source.support_id), SupportIdsScript.CORE_PLAYER, "support runtime: player core remains the fallback source")
	_assert.eq(core_only.online_support_ids, [], "support runtime: non-core Supports begin offline until authoritative state says otherwise")

	_assert.that(
		authority.set_support_state(SupportIdsScript.SUPPORT_LEFT_SOUTH, CardfrontRulesScript.PLAYER_FACTION, true),
		"support runtime: activating an authored left-route Support should invalidate connectivity once"
	)
	var left_online: Dictionary = authority.deployment_context(CardfrontRulesScript.PLAYER_FACTION)
	var left_source: Dictionary = _source_by_id(left_online.support_sources as Array, SupportIdsScript.SUPPORT_LEFT_SOUTH)
	var authored_left: Dictionary = by_id[SupportIdsScript.SUPPORT_LEFT_SOUTH] as Dictionary
	_assert.eq(left_source.anchor_cell, authored_left.anchor_cell, "support runtime: deployment anchor comes from DefaultDuelMap metadata")
	_assert.eq(left_source.forward, authored_left.player_deploy_direction, "support runtime: player deploy direction comes from authored metadata")
	_assert.eq(str(left_source.profile_id), str(authored_left.deployment_profile_id), "support runtime: deployment profile comes from authored metadata")
	_assert.eq(str(left_source.route_role), str(authored_left.route_role), "support runtime: route role comes from authored metadata")
	_assert.eq(int(left_source.graph_depth), 1, "support runtime: first left-route Support resolves one edge from player Core")

	# Connectivity must gate authored data: a downstream Claim can stay owned while an
	# upstream operational cut removes it from deployment authority, then reconnect
	# without recapturing that downstream Support.
	authority.set_support_state(SupportIdsScript.SUPPORT_LEFT_NORTH, CardfrontRulesScript.PLAYER_FACTION, true)
	_assert.that(
		SupportIdsScript.SUPPORT_LEFT_NORTH in authority.deployment_context(CardfrontRulesScript.PLAYER_FACTION).online_support_ids,
		"support runtime: connected downstream authored Support should become online"
	)
	authority.set_operational(SupportIdsScript.SUPPORT_LEFT_SOUTH, false)
	var cut_context: Dictionary = authority.deployment_context(CardfrontRulesScript.PLAYER_FACTION)
	_assert.that(SupportIdsScript.SUPPORT_LEFT_SOUTH not in cut_context.online_support_ids, "support runtime: disabled upstream Support leaves deployment authority")
	_assert.that(SupportIdsScript.SUPPORT_LEFT_NORTH not in cut_context.online_support_ids, "support runtime: downstream Claim is offline while disconnected")
	authority.set_operational(SupportIdsScript.SUPPORT_LEFT_SOUTH, true)
	_assert.that(
		SupportIdsScript.SUPPORT_LEFT_NORTH in authority.deployment_context(CardfrontRulesScript.PLAYER_FACTION).online_support_ids,
		"support runtime: reconnect restores downstream deployment authority without recapture"
	)


func _test_runtime_branch_failure_matrix() -> void:
	# The frozen map exposes two equal physical branches (LEFT / RIGHT), not a hidden
	# main-route priority. Run the same six failure/recovery truths from both Core roots
	# so side-specific graph direction cannot accidentally pass on only one faction.
	_run_branch_failure_matrix(
		CardfrontRulesScript.PLAYER_FACTION,
		SupportIdsScript.CORE_PLAYER,
		SupportIdsScript.SUPPORT_LEFT_SOUTH,
		SupportIdsScript.SUPPORT_LEFT_NORTH,
		SupportIdsScript.SUPPORT_RIGHT_SOUTH,
		SupportIdsScript.SUPPORT_RIGHT_NORTH,
		"player"
	)
	_run_branch_failure_matrix(
		CardfrontRulesScript.AI_FACTION,
		SupportIdsScript.CORE_AI,
		SupportIdsScript.SUPPORT_LEFT_NORTH,
		SupportIdsScript.SUPPORT_LEFT_SOUTH,
		SupportIdsScript.SUPPORT_RIGHT_NORTH,
		SupportIdsScript.SUPPORT_RIGHT_SOUTH,
		"ai"
	)


func _run_branch_failure_matrix(
	side: int,
	core_id: String,
	left_upstream: String,
	left_downstream: String,
	right_upstream: String,
	right_downstream: String,
	label: String
) -> void:
	var authority = SupportDeploymentAuthorityScript.new()
	_assert.that(authority.setup(DefaultDuelMapScript.make(Vector2i(40, 40))), "branch failure %s: runtime authority setup" % label)
	for support_id in [left_upstream, left_downstream, right_upstream, right_downstream]:
		authority.set_support_state(str(support_id), side, true)

	# 1. Both authored branches connected.
	var both_online: Dictionary = authority.deployment_context(side)
	_assert.that(_contains_all(both_online.online_support_ids as Array, [left_upstream, left_downstream, right_upstream, right_downstream]), "branch failure %s: both routes online" % label)

	# 2. Left branch upstream offline while right branch survives.
	authority.set_operational(left_upstream, false)
	var left_cut: Dictionary = authority.deployment_context(side)
	_assert.that(left_upstream not in left_cut.online_support_ids and left_downstream not in left_cut.online_support_ids, "branch failure %s: left upstream cut removes left downstream authority" % label)
	_assert.that(right_upstream in left_cut.online_support_ids and right_downstream in left_cut.online_support_ids, "branch failure %s: right branch survives left cut" % label)

	# Restore left, then 3. cut the right branch instead.
	authority.set_operational(left_upstream, true)
	authority.set_operational(right_upstream, false)
	var right_cut: Dictionary = authority.deployment_context(side)
	_assert.that(right_upstream not in right_cut.online_support_ids and right_downstream not in right_cut.online_support_ids, "branch failure %s: right upstream cut removes right downstream authority" % label)
	_assert.that(left_upstream in right_cut.online_support_ids and left_downstream in right_cut.online_support_ids, "branch failure %s: left branch survives right cut" % label)

	# 4. Both frontline paths offline.
	authority.set_operational(left_upstream, false)
	var both_cut: Dictionary = authority.deployment_context(side)
	_assert.eq(both_cut.online_support_ids, [], "branch failure %s: both route cuts remove all non-Core deployment sources" % label)

	# 5. Core fallback remains authored and available while every non-Core source is offline.
	_assert.eq(str((both_cut.core_source as Dictionary).get("support_id", "")), core_id, "branch failure %s: Core fallback survives both route cuts" % label)

	# 6. Downstream Claims remain owned while disconnected; reconnecting each upstream
	# restores the downstream source without re-applying its Claim.
	var cut_debug: Dictionary = authority.debug_snapshot()
	_assert.eq(int((cut_debug.claim_owner_by_support as Dictionary).get(left_downstream, CardfrontRulesScript.NEUTRAL_OWNER)), side, "branch failure %s: disconnected left downstream Claim is retained" % label)
	_assert.eq(int((cut_debug.claim_owner_by_support as Dictionary).get(right_downstream, CardfrontRulesScript.NEUTRAL_OWNER)), side, "branch failure %s: disconnected right downstream Claim is retained" % label)

	authority.set_operational(left_upstream, true)
	var left_reconnected: Dictionary = authority.deployment_context(side)
	_assert.that(left_downstream in left_reconnected.online_support_ids, "branch failure %s: left reconnect restores downstream without recapture" % label)
	_assert.that(right_downstream not in left_reconnected.online_support_ids, "branch failure %s: right branch stays offline until its own upstream reconnects" % label)

	authority.set_operational(right_upstream, true)
	var fully_reconnected: Dictionary = authority.deployment_context(side)
	_assert.that(_contains_all(fully_reconnected.online_support_ids as Array, [left_upstream, left_downstream, right_upstream, right_downstream]), "branch failure %s: both branches recover without downstream recapture" % label)


func _contains_all(values: Array, required: Array) -> bool:
	for item in required:
		if item not in values:
			return false
	return true


func _source_by_id(sources: Array, support_id: String) -> Dictionary:
	for raw_source in sources:
		var source: Dictionary = raw_source as Dictionary
		if str(source.get("support_id", "")) == support_id:
			return source
	return {}


func _by_id(supports: Array) -> Dictionary:
	var result: Dictionary = {}
	for definition in supports:
		result[str((definition as Dictionary).support_id)] = definition
	return result


func _undirected_edges(supports: Array) -> Array[String]:
	var edges: Dictionary = {}
	for definition in supports:
		var support_id: String = str((definition as Dictionary).support_id)
		for raw_neighbor_id in (definition as Dictionary).authored_neighbors as Array:
			var pair: Array[String] = [support_id, str(raw_neighbor_id)]
			pair.sort()
			edges["%s<->%s" % pair] = true
	return _sorted_strings(edges.keys())


func _expected_edges() -> Array[String]:
	return _sorted_strings([
		"core_player<->support_left_south",
		"core_player<->support_right_south",
		"support_left_north<->support_left_south",
		"support_right_north<->support_right_south",
		"support_center<->support_left_south",
		"support_center<->support_right_south",
		"support_center<->support_left_north",
		"support_center<->support_right_north",
		"core_ai<->support_left_north",
		"core_ai<->support_right_north",
	])


func _sorted_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(str(value))
	result.sort()
	return result


func _has_error_prefix(errors: Array, prefix: String) -> bool:
	for error in errors:
		if str(error).begins_with(prefix):
			return true
	return false
