extends SceneTree

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const InitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const DefaultMapScript = preload("res://scripts/cardfront/maps/maps/DefaultDuelMap.gd")
const Ids = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const CardPlaySystemScript = preload("res://scripts/cardfront/cards/CardPlaySystem.gd")
const CardDataScript = preload("res://scripts/cardfront/cards/CardData.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const ResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const ContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")

const TEST_CARD_ID: int = 99001

class TestEffect:
	extends RefCounted
	const ResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
	var calls: int = 0
	func resolve(_req, card, _context: Dictionary):
		calls += 1
		return ResultScript.ok(card.card_name)

var _assert: TestAssert
var _battlefield: Battlefield
var _map_definition: Dictionary
var _context_holder: Dictionary


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDeploymentPlayerCommitTest] Checking current-state commit validation")
	await _setup_fixture()

	_test_stale_preview_cannot_bypass_commit()
	_test_legal_commit_pays_after_validation()

	_assert.report("[CardfrontDeploymentPlayerCommitTest]")
	TestFixtures.cleanup_node(_battlefield)
	quit(0 if _assert.failures.is_empty() else 1)


func _setup_fixture() -> void:
	_battlefield = Battlefield.new()
	_battlefield.configure(40)
	get_root().add_child(_battlefield)
	await process_frame
	InitializerScript.configure_duel(_battlefield)
	_map_definition = DefaultMapScript.make(Vector2i(40, 40))
	_context_holder = {"value": ContextScript.with_online_supports(_map_definition, Rules.PLAYER_FACTION, [Ids.SUPPORT_LEFT_SOUTH])}
	_battlefield.owners[7][31] = Rules.PLAYER_FACTION


func _make_system(effect: TestEffect, resource_state):
	var system = CardPlaySystemScript.new()
	var provider := func(_owner_id: int): return (_context_holder.value as Dictionary).duplicate(true)
	system.setup({Rules.PLAYER_FACTION: resource_state}, null, _battlefield, null, null, null, null, provider)
	var card = CardDataScript.new()
	card.id = TEST_CARD_ID
	card.card_name = "Fixture Frontline Deployment"
	card.energy_cost = 7
	card.parts_cost = 3
	card.target_type = CardTargetTypeScript.FRONTLINE_DEPLOYMENT
	card.effect_id = "fixture_frontline_deployment"
	card.params = {"deployment_profile_id": "directional_rear_rect_v1", "requested_support_id": Ids.SUPPORT_LEFT_SOUTH}
	system.catalog.catalog[TEST_CARD_ID] = card
	system.hand.initialize_fixed_hand([TEST_CARD_ID])
	system.register_effect(card.effect_id, effect)
	return system


func _resource_state():
	var state = ResourceStateScript.new()
	state.energy = 20
	state.parts = 20
	return state


func _test_stale_preview_cannot_bypass_commit() -> void:
	var state = _resource_state()
	var effect = TestEffect.new()
	var system = _make_system(effect, state)
	var req = CardPlayRequestScript.make(TEST_CARD_ID, Rules.PLAYER_FACTION, Vector2i(7, 31), -1)
	_assert.that(system.can_play(req).success, "player commit: target is initially legal under Online Support")
	_context_holder.value = ContextScript.core_only(_map_definition, Rules.PLAYER_FACTION)
	var result = system.play(req)
	_assert.that(not result.success, "player commit: current offline Support denies stale target")
	_assert.eq(result.authority_reason, DeploymentRulesScript.REASON_SUPPORT_OFFLINE, "player commit: current authoritative reason is returned")
	_assert.eq(state.energy, 20, "player commit: illegal target is rejected before energy payment")
	_assert.eq(state.parts, 20, "player commit: illegal target is rejected before parts payment")
	_assert.that(system.hand.can_play_card(TEST_CARD_ID), "player commit: illegal target is not consumed")
	_assert.eq(effect.calls, 0, "player commit: illegal target never reaches effect resolver")


func _test_legal_commit_pays_after_validation() -> void:
	_context_holder.value = ContextScript.with_online_supports(_map_definition, Rules.PLAYER_FACTION, [Ids.SUPPORT_LEFT_SOUTH])
	var state = _resource_state()
	var effect = TestEffect.new()
	var system = _make_system(effect, state)
	var req = CardPlayRequestScript.make(TEST_CARD_ID, Rules.PLAYER_FACTION, Vector2i(7, 31), -1)
	var result = system.play(req)
	_assert.that(result.success, "player commit: current legal target succeeds")
	_assert.eq(state.energy, 13, "player commit: legal commit pays energy")
	_assert.eq(state.parts, 17, "player commit: legal commit pays parts")
	_assert.that(not system.hand.can_play_card(TEST_CARD_ID), "player commit: legal commit consumes card")
	_assert.eq(effect.calls, 1, "player commit: legal commit reaches effect once")
