extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const ContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const PlannerScript = preload("res://scripts/cardfront/ai/CardfrontAiDeploymentPlanner.gd")
const QueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const RuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")

const PROFILE: String = "directional_rear_rect_v1"

var _assert: TestAssert
var _battlefield: Battlefield
var _map_definition: Dictionary
var _authority: Dictionary
var _planner


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDeploymentAiParityTest] Checking AI uses shared deployment authority")
	await _setup_fixture()
	_test_all_cell_result_parity()
	_test_ai_filters_before_ranking()
	_test_offline_support_has_no_ai_exception()
	_assert.report("[CardfrontDeploymentAiParityTest]")
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	_map_definition = DefaultMapScript.make(Vector2i(40, 40))
	_battlefield.owners[7][29] = Rules.AI_FACTION
	_authority = {"context": ContextScript.with_online_supports(_map_definition, Rules.AI_FACTION, [Ids.SUPPORT_LEFT_SOUTH])}
	var provider := func(_owner_id: int): return (_authority.context as Dictionary).duplicate(true)
	_planner = PlannerScript.new()
	_planner.setup(null, _battlefield, provider)


func _test_all_cell_result_parity() -> void:
	var validity_mismatches: Array[Vector2i] = []
	var reason_mismatches: Array[Vector2i] = []
	for x in range(40):
		for y in range(40):
			var cell := Vector2i(x, y)
			var ai_result = _planner.evaluate_cell(Rules.AI_FACTION, cell, Ids.SUPPORT_LEFT_SOUTH, PROFILE)
			var authority_result = _authority_result(cell)
			if bool(ai_result.allowed) != bool(authority_result.allowed):
				validity_mismatches.append(cell)
			if str(ai_result.reason) != str(authority_result.reason):
				reason_mismatches.append(cell)
	_assert.eq(validity_mismatches.size(), 0, "AI parity: all 1600 cells match validator legality")
	_assert.eq(reason_mismatches.size(), 0, "AI parity: all 1600 cells match validator authority reason")


func _test_ai_filters_before_ranking() -> void:
	var legal: Array[Vector2i] = _planner.legal_cells(
		Rules.AI_FACTION,
		[Vector2i(20, 20), Vector2i(7, 29), Vector2i(-1, -1)],
		Ids.SUPPORT_LEFT_SOUTH,
		PROFILE
	)
	_assert.eq(legal, [Vector2i(7, 29)], "AI parity: only authority-approved candidates reach ranking")


func _test_offline_support_has_no_ai_exception() -> void:
	_authority.context = ContextScript.core_only(_map_definition, Rules.AI_FACTION)
	var ai_result = _planner.evaluate_cell(Rules.AI_FACTION, Vector2i(7, 29), Ids.SUPPORT_LEFT_SOUTH, PROFILE)
	var authority_result = _authority_result(Vector2i(7, 29))
	_assert.that(not ai_result.allowed and not authority_result.allowed, "AI parity: offline Support is illegal for both consumers")
	_assert.eq(ai_result.reason, DeploymentRulesScript.REASON_SUPPORT_OFFLINE, "AI parity: AI receives explicit offline reason")
	_assert.eq(ai_result.reason, authority_result.reason, "AI parity: AI has no offline exception")
	_assert.that(_planner.legal_cells(Rules.AI_FACTION, [Vector2i(7, 29)], Ids.SUPPORT_LEFT_SOUTH, PROFILE).is_empty(), "AI parity: offline candidate never reaches ranking")


func _authority_result(cell: Vector2i):
	var query = QueryScript.new()
	query.owner_id = Rules.AI_FACTION
	query.cell = cell
	query.rule_type = RuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = Ids.SUPPORT_LEFT_SOUTH
	query.spawn_profile_id = PROFILE
	query.support_network_context = (_authority.context as Dictionary).duplicate(true)
	return DeploymentRulesScript.evaluate(null, _battlefield, query)
