extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const BattlefieldInitializer = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SupportDefinitionScript = preload("res://scripts/cardfront/support/DeploymentSupportDefinition.gd")
const ContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const ResolverScript = preload("res://scripts/cardfront/deployment/DeploymentPlacementResolver.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeploymentResultScript = preload("res://scripts/cardfront/deployment/DeploymentResult.gd")
const RuntimeScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntityLiveRuntime.gd")
const BattlefieldEntityScript = preload("res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

const PRODUCTION_ROOT: String = "res://scripts/cardfront"
const PLAYER_COMMIT_RULE_PATH: String = "res://scripts/cardfront/targets/target_rules/FrontlineDeploymentTargetRule.gd"
const PREVIEW_PATH: String = "res://scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd"
const AI_PLANNER_PATH: String = "res://scripts/cardfront/ai/CardfrontAiDeploymentPlanner.gd"
const PLACEMENT_RESOLVER_PATH: String = "res://scripts/cardfront/deployment/DeploymentPlacementResolver.gd"
const AUTOMATIC_SPAWN_PATH: String = "res://scripts/cardfront/entities/CardfrontAutomaticSpawnCoordinator.gd"
const RUNTIME_PATH: String = "res://scripts/cardfront/entities/CardfrontBattlefieldEntityRuntime.gd"
const AUTHORITATIVE_CREATURE_PATH: String = "res://scripts/cardfront/entities/CardfrontAuthoritativeCreatureActionCoordinator.gd"
const BASE_CREATURE_PATH: String = "res://scripts/cardfront/entities/CardfrontCreatureActionCoordinator.gd"
const DIRECT_EVALUATE_NEEDLE: String = "DeploymentRulesScript.evaluate("
const BASE_CREATURE_REFERENCE_NEEDLE: String = "CardfrontCreatureActionCoordinator.gd"

var _assert: TestAssert
var _battlefields: Array = []
var _map_definition: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	_map_definition = DefaultMapScript.make(Vector2i(40, 40))
	print("[CardfrontDeploymentAutomaticSpawnTest] Checking deterministic resolver, spawn cutover, and four-consumer authority convergence")
	_test_authority_convergence_source_contract()
	await _test_source_ranking()
	await _test_core_fallback()
	await _test_upgrade_spawn_uses_online_support()
	await _test_runtime_default_is_authoritative_core()
	await _test_no_legacy_route_origin_fallback()
	_test_legacy_helper_compatibility_routes_through_resolver()
	_assert.report("[CardfrontDeploymentAutomaticSpawnTest]")
	for battlefield in _battlefields:
		TestFixtures.cleanup_node(battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _test_authority_convergence_source_contract() -> void:
	var production_paths: Array[String] = []
	_collect_gd_files(PRODUCTION_ROOT, production_paths)
	production_paths.sort()
	_assert.that(not production_paths.is_empty(), "authority convergence: production Cardfront scripts are discoverable")

	var direct_evaluate_consumers: Array[String] = []
	var base_coordinator_references: Array[String] = []
	for path in production_paths:
		var source: String = _read_source(path)
		if source.contains(DIRECT_EVALUATE_NEEDLE):
			direct_evaluate_consumers.append(path)
		if source.contains(BASE_CREATURE_REFERENCE_NEEDLE):
			base_coordinator_references.append(path)

	direct_evaluate_consumers.sort()
	var expected_direct_consumers: Array[String] = [
		AI_PLANNER_PATH,
		PLACEMENT_RESOLVER_PATH,
		PLAYER_COMMIT_RULE_PATH,
		PREVIEW_PATH,
	]
	expected_direct_consumers.sort()
	_assert.eq(
		direct_evaluate_consumers,
		expected_direct_consumers,
		"authority convergence: only Commit, Preview, AI and placement resolver call DeploymentRules.evaluate in production"
	)

	base_coordinator_references.sort()
	var expected_base_references: Array[String] = [AUTHORITATIVE_CREATURE_PATH]
	_assert.eq(
		base_coordinator_references,
		expected_base_references,
		"authority convergence: legacy creature coordinator is only inherited by the authoritative adapter"
	)

	var commit_source: String = _read_source(PLAYER_COMMIT_RULE_PATH)
	_assert.that(commit_source.contains("DeploymentRuleTypeScript.SUPPORT_NETWORK"), "authority convergence: player Commit uses SUPPORT_NETWORK")
	_assert.that(commit_source.contains(DIRECT_EVALUATE_NEEDLE), "authority convergence: player Commit delegates to DeploymentRules")

	var preview_source: String = _read_source(PREVIEW_PATH)
	_assert.that(preview_source.contains("DeploymentRuleTypeScript.SUPPORT_NETWORK"), "authority convergence: Preview uses SUPPORT_NETWORK")
	_assert.that(preview_source.contains(DIRECT_EVALUATE_NEEDLE), "authority convergence: Preview delegates to DeploymentRules")

	var ai_source: String = _read_source(AI_PLANNER_PATH)
	_assert.that(ai_source.contains("DeploymentRuleTypeScript.SUPPORT_NETWORK"), "authority convergence: AI uses SUPPORT_NETWORK")
	_assert.that(ai_source.contains(DIRECT_EVALUATE_NEEDLE), "authority convergence: AI delegates to DeploymentRules")

	var resolver_source: String = _read_source(PLACEMENT_RESOLVER_PATH)
	_assert.that(resolver_source.contains("DeploymentRuleTypeScript.SUPPORT_NETWORK"), "authority convergence: automatic placement resolver uses SUPPORT_NETWORK")
	_assert.that(resolver_source.contains(DIRECT_EVALUATE_NEEDLE), "authority convergence: automatic placement resolver delegates to DeploymentRules")

	var automatic_source: String = _read_source(AUTOMATIC_SPAWN_PATH)
	_assert.that(automatic_source.contains("DeploymentPlacementResolver.gd"), "authority convergence: automatic spawn delegates placement to resolver")
	_assert.that(not automatic_source.contains("DeploymentRules.gd"), "authority convergence: automatic spawn does not become a second legality authority")

	var runtime_source: String = _read_source(RUNTIME_PATH)
	_assert.that(runtime_source.contains("CardfrontAutomaticSpawnCoordinator.gd"), "authority convergence: entity runtime delegates automatic spawn orchestration")
	_assert.that(not runtime_source.contains("DeploymentRules.gd"), "authority convergence: entity runtime does not directly own deployment legality")

	var authoritative_source: String = _read_source(AUTHORITATIVE_CREATURE_PATH)
	_assert.that(authoritative_source.contains("func find_owner_spawn_cell"), "authority convergence: inherited legacy owner-spawn helper is explicitly overridden")
	_assert.that(authoritative_source.contains("func find_adjacent_spawn_cell"), "authority convergence: inherited legacy adjacent-spawn helper is explicitly overridden")
	_assert.that(authoritative_source.contains("resolve_automatic_spawn_cell"), "authority convergence: compatibility helper resolves through current placement authority")
	_assert.that(not authoritative_source.contains("_route_slot_id"), "authority convergence: authoritative creature adapter contains no route-slot spawn fallback")
	_assert.that(not authoritative_source.contains("building_slots"), "authority convergence: authoritative creature adapter contains no building-slot spawn fallback")

	var base_source: String = _read_source(BASE_CREATURE_PATH)
	_assert.that(base_source.contains("find_owner_spawn_cell"), "authority convergence: legacy helper remains identifiable for compatibility audit")
	_assert.that(base_source.contains("_route_slot_id"), "authority convergence: legacy route-slot implementation remains isolated in dormant base implementation")


func _test_source_ranking() -> void:
	var battlefield = await _make_battlefield(true)
	var depths := {
		Ids.SUPPORT_LEFT_SOUTH: 1,
		Ids.SUPPORT_RIGHT_SOUTH: 1,
		Ids.SUPPORT_CENTER: 2,
	}
	var context: Dictionary = ContextScript.with_online_supports(
		_map_definition,
		Rules.PLAYER_FACTION,
		[Ids.SUPPORT_LEFT_SOUTH, Ids.SUPPORT_RIGHT_SOUTH, Ids.SUPPORT_CENTER],
		depths,
		17
	)
	var deepest: Dictionary = ResolverScript.resolve(
		null,
		battlefield,
		Rules.PLAYER_FACTION,
		context
	)
	_assert.that(bool(deepest.allowed), "auto placement: deepest Online Support resolves")
	_assert.eq(deepest.resolved_support_id, Ids.SUPPORT_CENTER, "auto placement: deeper authored graph depth wins")
	_assert.eq(deepest.cell, Vector2i(20, 20), "auto placement: support cell ranking starts at legal anchor")
	_assert.eq(deepest.deployment_revision, 17, "auto placement: trace preserves deployment revision")

	var preferred_route: Dictionary = ResolverScript.resolve(
		null,
		battlefield,
		Rules.PLAYER_FACTION,
		context,
		{"preferred_route_role": SupportDefinitionScript.ROUTE_ROLE_LEFT}
	)
	_assert.eq(preferred_route.resolved_support_id, Ids.SUPPORT_LEFT_SOUTH, "auto placement: preferred route precedes deeper unrelated Support")

	var preferred_support: Dictionary = ResolverScript.resolve(
		null,
		battlefield,
		Rules.PLAYER_FACTION,
		context,
		{"preferred_support_id": Ids.SUPPORT_RIGHT_SOUTH}
	)
	_assert.eq(preferred_support.resolved_support_id, Ids.SUPPORT_RIGHT_SOUTH, "auto placement: explicit preferred Support has first opportunity")

	var tied_context: Dictionary = ContextScript.with_online_supports(
		_map_definition,
		Rules.PLAYER_FACTION,
		[Ids.SUPPORT_LEFT_SOUTH, Ids.SUPPORT_RIGHT_SOUTH],
		{Ids.SUPPORT_LEFT_SOUTH: 1, Ids.SUPPORT_RIGHT_SOUTH: 1}
	)
	var lexical: Dictionary = ResolverScript.resolve(null, battlefield, Rules.PLAYER_FACTION, tied_context)
	_assert.eq(lexical.resolved_support_id, Ids.SUPPORT_LEFT_SOUTH, "auto placement: equal depth ties by stable support_id")


func _test_core_fallback() -> void:
	var battlefield = await _make_battlefield(true)
	var context: Dictionary = ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION, 5)
	var result: Dictionary = ResolverScript.resolve(null, battlefield, Rules.PLAYER_FACTION, context)
	_assert.that(bool(result.allowed), "auto placement: Core remains legal when Supports are absent")
	_assert.eq(result.source_kind, DeploymentResultScript.SOURCE_CORE, "auto placement: Core fallback reports Core source")
	_assert.eq(result.resolved_support_id, Ids.CORE_PLAYER, "auto placement: Core fallback reports stable Core ID")
	_assert.eq(result.cell, Vector2i(0, 32), "auto placement: Core tie break is deterministic y then x")


func _test_upgrade_spawn_uses_online_support() -> void:
	var battlefield = await _make_battlefield(false)
	BattlefieldInitializer.configure_duel(battlefield)
	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield, _map_definition), "auto spawn runtime: setup")
	var context: Dictionary = ContextScript.with_online_supports(
		_map_definition,
		Rules.PLAYER_FACTION,
		[Ids.SUPPORT_LEFT_SOUTH],
		{Ids.SUPPORT_LEFT_SOUTH: 1},
		23
	)
	runtime.configure_deployment_context_provider(
		func(_owner_id: int): return context.duplicate(true)
	)
	var run_state = RunStateScript.new()
	run_state.setup(Rules.PLAYER_FACTION)
	run_state.queue_entity_action({"action": "summon_armored_guard"})
	var results: Array = runtime.apply_pending_upgrade_actions(Rules.PLAYER_FACTION, run_state)
	_assert.eq(results.size(), 1, "auto spawn runtime: one queued action yields one result")
	var action_result: Dictionary = results[0] as Dictionary
	_assert.that(bool(action_result.allowed), "auto spawn runtime: legal Support summon succeeds")
	_assert.eq(action_result.spawned, 1, "auto spawn runtime: legal Support summon creates one creature")
	var placement: Dictionary = (action_result.placements as Array)[0] as Dictionary
	_assert.eq(placement.resolved_support_id, Ids.SUPPORT_LEFT_SOUTH, "auto spawn runtime: summon reports resolved Support")
	_assert.eq(placement.cell, Vector2i(7, 32), "auto spawn runtime: summon chooses nearest legal rear-zone cell")
	_assert.eq(placement.deployment_revision, 23, "auto spawn runtime: structured trace reports current revision")
	var creatures: Array = _owner_creatures(runtime, Rules.PLAYER_FACTION)
	_assert.eq(creatures.size(), 1, "auto spawn runtime: creature registry contains exactly one player creature")
	if not creatures.is_empty():
		_assert.eq(creatures[0].cell, placement.cell, "auto spawn runtime: actual entity cell equals authoritative placement")


func _test_runtime_default_is_authoritative_core() -> void:
	var battlefield = await _make_battlefield(false)
	BattlefieldInitializer.configure_duel(battlefield)
	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield, _map_definition), "auto spawn Core runtime: setup")
	var run_state = RunStateScript.new()
	run_state.setup(Rules.PLAYER_FACTION)
	run_state.queue_entity_action({"action": "summon_sapper_unit"})
	var results: Array = runtime.apply_pending_upgrade_actions(Rules.PLAYER_FACTION, run_state)
	var result: Dictionary = results[0] as Dictionary
	_assert.that(bool(result.allowed), "auto spawn Core runtime: missing live provider uses explicit Core context")
	_assert.eq(result.spawned, 1, "auto spawn Core runtime: Core fallback still spawns upgrade creature")
	var placement: Dictionary = (result.placements as Array)[0] as Dictionary
	_assert.eq(placement.source_kind, DeploymentResultScript.SOURCE_CORE, "auto spawn Core runtime: fallback is reported as Core, not hidden route slot")
	_assert.eq(placement.resolved_support_id, Ids.CORE_PLAYER, "auto spawn Core runtime: fallback uses stable Core source")


func _test_no_legacy_route_origin_fallback() -> void:
	var battlefield = await _make_battlefield(false)
	_paint_owner(battlefield, Rules.AI_FACTION)
	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield, _map_definition), "auto spawn failure runtime: setup")
	var old_route_slot_id: String = "%d_route_0" % Rules.PLAYER_FACTION
	var old_route_slot: Dictionary = runtime.registry.building_slots.get(old_route_slot_id, {}) as Dictionary
	var old_origin: Vector2i = old_route_slot.get("cell", Vector2i(-1, -1)) as Vector2i
	_assert.that(old_origin.x >= 0, "auto spawn failure runtime: legacy route origin exists in fixture")
	_assert.eq(int(battlefield.owners[old_origin.x][old_origin.y]), Rules.AI_FACTION, "auto spawn failure runtime: old origin is deliberately illegal for player")

	var run_state = RunStateScript.new()
	run_state.setup(Rules.PLAYER_FACTION)
	run_state.queue_entity_action({"action": "summon_sapper_unit"})
	var results: Array = runtime.apply_pending_upgrade_actions(Rules.PLAYER_FACTION, run_state)
	var result: Dictionary = results[0] as Dictionary
	_assert.that(not bool(result.allowed), "auto spawn failure runtime: no legal deployment source fails closed")
	_assert.eq(result.reason, DeploymentRulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE, "auto spawn failure runtime: failure reason is explicit")
	_assert.eq(result.spawned, 0, "auto spawn failure runtime: illegal action spawns nothing")
	_assert.eq(_owner_creatures(runtime, Rules.PLAYER_FACTION).size(), 0, "auto spawn failure runtime: registry has no hidden player creature")
	_assert.eq(runtime.registry.get_entities_at(old_origin).size(), 0, "auto spawn failure runtime: old route origin is not used as fallback")


func _test_legacy_helper_compatibility_routes_through_resolver() -> void:
	var battlefield = Battlefield.new()
	battlefield.configure(40)
	get_root().add_child(battlefield)
	_battlefields.append(battlefield)
	_paint_owner(battlefield, Rules.AI_FACTION)
	var runtime = RuntimeScript.new()
	battlefield.add_child(runtime)
	_assert.that(runtime.setup(battlefield, _map_definition), "legacy helper compatibility: runtime setup")
	var resolved: Vector2i = runtime._creature_action_coordinator.find_owner_spawn_cell(Rules.PLAYER_FACTION, 0)
	_assert.eq(resolved, Vector2i(-1, -1), "legacy helper compatibility: illegal battlefield fails closed instead of returning route origin")
	var adjacent: Vector2i = runtime._creature_action_coordinator.find_adjacent_spawn_cell(Rules.PLAYER_FACTION, Vector2i(12, 12))
	_assert.eq(adjacent, Vector2i(-1, -1), "legacy adjacent helper compatibility: arbitrary origin cannot bypass deployment authority")


func _make_battlefield(fill_player: bool):
	var battlefield = Battlefield.new()
	battlefield.configure(40)
	get_root().add_child(battlefield)
	_battlefields.append(battlefield)
	await process_frame
	if fill_player:
		_paint_owner(battlefield, Rules.PLAYER_FACTION)
	return battlefield


func _paint_owner(battlefield, owner_id: int) -> void:
	for x in range(40):
		for y in range(40):
			battlefield.owners[x][y] = owner_id


func _owner_creatures(runtime, owner_id: int) -> Array:
	var result: Array = []
	for entity in runtime.registry.entities_by_id.values():
		if (
			entity != null
			and entity.is_alive()
			and int(entity.owner_id) == owner_id
			and str(entity.entity_kind) == BattlefieldEntityScript.KIND_CREATURE
		):
			result.append(entity)
	return result


func _collect_gd_files(root_path: String, out_paths: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var child_path: String = root_path.path_join(entry)
			if dir.current_is_dir():
				_collect_gd_files(child_path, out_paths)
			elif entry.ends_with(".gd"):
				out_paths.append(child_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _read_source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()
