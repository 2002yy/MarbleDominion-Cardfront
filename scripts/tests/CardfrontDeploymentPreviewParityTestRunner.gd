extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const InitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const ContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const QueryScript = preload("res://scripts/cardfront/deployment/DeploymentQuery.gd")
const RuleTypeScript = preload("res://scripts/cardfront/deployment/DeploymentRuleType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const PreviewScript = preload("res://scripts/cardfront/ui/CardfrontTargetPreviewLayer.gd")
const CardDataScript = preload("res://scripts/cardfront/cards/CardData.gd")
const RequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const TargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const TargetRuleScript = preload("res://scripts/cardfront/targets/target_rules/FrontlineDeploymentTargetRule.gd")

var _assert: TestAssert
var _battlefield: Battlefield
var _map_definition: Dictionary
var _authority: Dictionary
var _layer


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDeploymentPreviewParityTest] Checking all-cell authority parity")
	await _setup_fixture()
	_test_all_cell_parity()
	_test_preview_revision_is_not_commit_permission()
	_assert.report("[CardfrontDeploymentPreviewParityTest]")
	TestFixtures.cleanup_node(_layer)
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	InitializerScript.configure_duel(_battlefield)
	_map_definition = DefaultMapScript.make(Vector2i(40, 40))
	_battlefield.owners[7][31] = Rules.PLAYER_FACTION
	_authority = {
		"context": ContextScript.with_online_supports(_map_definition, Rules.PLAYER_FACTION, [Ids.SUPPORT_LEFT_SOUTH]),
		"revision": 1,
	}
	_layer = PreviewScript.new()
	_layer.setup(_battlefield, null, GameConfig.GAME_MODE_CARDFRONT)
	_layer.configure_deployment_authority(
		func(_owner_id: int): return (_authority.context as Dictionary).duplicate(true),
		func(_owner_id: int): return int(_authority.revision)
	)
	_layer.show_for_card(99002, _card_snapshot())


func _test_all_cell_parity() -> void:
	var mismatches: Array[Vector2i] = []
	for x in range(40):
		for y in range(40):
			var cell := Vector2i(x, y)
			if _layer.is_valid_target(cell) != _evaluate(cell).allowed:
				mismatches.append(cell)
	_assert.eq(mismatches.size(), 0, "preview parity: all 1600 cells match DeploymentRules")
	_assert.eq(_layer.get_preview_revision(), 1, "preview parity: records source revision for diagnostics")
	_assert.that(_layer.is_valid_target(Vector2i(7, 31)), "preview parity: fixture Support target is visible while Online")


func _test_preview_revision_is_not_commit_permission() -> void:
	var target := Vector2i(7, 31)
	_authority.context = ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION)
	_authority.revision = 2
	_assert.that(_layer.is_valid_target(target), "preview parity: old rendered preview remains a stale visual until refresh")
	var card = CardDataScript.new()
	card.card_name = "Fixture Frontline Deployment"
	card.target_type = TargetTypeScript.FRONTLINE_DEPLOYMENT
	card.params = (_card_snapshot().params as Dictionary).duplicate(true)
	var req = RequestScript.make(99002, Rules.PLAYER_FACTION, target, -1)
	var provider := func(_owner_id: int): return (_authority.context as Dictionary).duplicate(true)
	var commit_result = TargetRuleScript.new().validate(req, card, {
		"battlefield": _battlefield,
		"region_map": null,
		"deployment_context_provider": provider,
	})
	_assert.that(not commit_result.success, "preview parity: current commit authority rejects stale visual")
	_assert.eq(commit_result.authority_reason, DeploymentRulesScript.REASON_SUPPORT_OFFLINE, "preview parity: stale visual cannot mask current authority reason")
	_layer.show_for_card(99002, _card_snapshot())
	_assert.eq(_layer.get_preview_revision(), 2, "preview parity: refresh records new revision")
	_assert.that(not _layer.is_valid_target(target), "preview parity: refresh removes offline Support target")


func _evaluate(cell: Vector2i):
	var query = QueryScript.new()
	query.owner_id = Rules.PLAYER_FACTION
	query.cell = cell
	query.rule_type = RuleTypeScript.SUPPORT_NETWORK
	query.requested_support_id = Ids.SUPPORT_LEFT_SOUTH
	query.spawn_profile_id = "directional_rear_rect_v1"
	query.support_network_context = (_authority.context as Dictionary).duplicate(true)
	return DeploymentRulesScript.evaluate(null, _battlefield, query)


func _card_snapshot() -> Dictionary:
	return {
		"target_type": TargetTypeScript.FRONTLINE_DEPLOYMENT,
		"params": {
			"requested_support_id": Ids.SUPPORT_LEFT_SOUTH,
			"deployment_profile_id": "directional_rear_rect_v1",
		},
	}
