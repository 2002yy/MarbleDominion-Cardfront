extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const InitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const QueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const ResultScript = preload("res://scripts/cardfront/deployment/DeploymentResult.gd")
const RuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const ContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")

var _assert: TestAssert
var _battlefield: Battlefield
var _map_definition: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDeploymentCoreFallbackTest] Checking spawn-zone Core authority")
	await _setup_fixture()

	_test_both_sides_keep_legal_core_cells()
	_test_core_still_requires_owned_cell()
	_test_outside_core_zone_is_denied()
	_test_missing_or_wrong_context_fails_closed()

	_assert.report("[CardfrontDeploymentCoreFallbackTest]")
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	InitializerScript.configure_duel(_battlefield)
	_map_definition = DefaultMapScript.make(Vector2i(40, 40))


func _test_both_sides_keep_legal_core_cells() -> void:
	var player_result = _evaluate(Rules.PLAYER_FACTION, Vector2i(0, 39), ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION))
	_assert.that(player_result.allowed, "Core fallback: player retains a legal spawn-zone cell with all Supports offline")
	_assert.eq(player_result.source_kind, ResultScript.SOURCE_CORE, "Core fallback: player resolves Core source")
	_assert.eq(player_result.resolved_support_id, Ids.CORE_PLAYER, "Core fallback: player resolves stable Core ID")
	var ai_result = _evaluate(Rules.AI_FACTION, Vector2i(0, 0), ContextScript.core_only(_map_definition, Rules.AI_FACTION))
	_assert.that(ai_result.allowed, "Core fallback: AI retains a legal spawn-zone cell with all Supports offline")
	_assert.eq(ai_result.resolved_support_id, Ids.CORE_AI, "Core fallback: AI resolves stable Core ID")


func _test_core_still_requires_owned_cell() -> void:
	var cell := Vector2i(2, 39)
	_battlefield.owners[cell.x][cell.y] = Rules.NEUTRAL_OWNER
	var result = _evaluate(Rules.PLAYER_FACTION, cell, ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION))
	_assert.that(not result.allowed, "Core fallback: candidate geometry alone is not final legality")
	_assert.eq(result.reason, DeploymentRulesScript.REASON_NOT_OWNED_CELL, "Core fallback: current owned-cell contract remains authoritative")


func _test_outside_core_zone_is_denied() -> void:
	var result = _evaluate(Rules.PLAYER_FACTION, Vector2i(0, 20), ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION))
	_assert.that(not result.allowed, "Core fallback: middle-map cell is outside authored spawn zone")
	_assert.eq(result.reason, DeploymentRulesScript.REASON_OUTSIDE_DEPLOYMENT_ZONE, "Core fallback: outside-zone reason is explicit")


func _test_missing_or_wrong_context_fails_closed() -> void:
	var missing = _evaluate(Rules.PLAYER_FACTION, Vector2i(0, 39), {})
	_assert.eq(missing.reason, DeploymentRulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE, "Core fallback: missing context fails closed")
	var wrong = _evaluate(Rules.PLAYER_FACTION, Vector2i(0, 39), ContextScript.core_only(_map_definition, Rules.AI_FACTION))
	_assert.eq(wrong.reason, DeploymentRulesScript.REASON_NO_VALID_DEPLOYMENT_SOURCE, "Core fallback: side-mismatched context fails closed")


func _evaluate(side: int, cell: Vector2i, context: Dictionary):
	var query = QueryScript.new()
	query.owner_id = side
	query.cell = cell
	query.rule_type = RuleTypeScript.SUPPORT_NETWORK
	query.support_network_context = context
	return DeploymentRulesScript.evaluate(null, _battlefield, query)
