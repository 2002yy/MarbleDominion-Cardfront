extends SceneTree

const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardPlaySystemScript = preload("res://scripts/cardfront/cards/CardPlaySystem.gd")
const CardTargetRuleRegistryScript = preload("res://scripts/cardfront/targets/CardTargetRuleRegistry.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionMoraleSystemScript = preload("res://scripts/cardfront/morale/RegionMoraleSystem.gd")
const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontTargetValidatorTest] Starting Cardfront target validator tests")
	await process_frame

	_test_registry_rejects_invalid_rule()
	_test_card_play_system_registers_current_rules()
	_test_owned_border_rule_accepts_valid_cell()
	_test_owned_border_rule_rejects_internal_cell()
	_test_region_rule_rejects_missing_region()

	GameConfig.reset_runtime_defaults()
	await process_frame

	_assert.report("[CardfrontTargetValidatorTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _test_registry_rejects_invalid_rule() -> void:
	var registry = CardTargetRuleRegistryScript.new()
	registry.register("bad", RefCounted.new())
	_assert.that(not registry.has_rule("bad"), "target registry: object without validate should not register")


func _test_card_play_system_registers_current_rules() -> void:
	var system = CardPlaySystemScript.new()
	_assert.that(system.has_target_rule(CardTargetTypeScript.OWNED_BORDER), "target registry: owned_border should be registered")
	_assert.that(system.has_target_rule(CardTargetTypeScript.ENEMY_REGION), "target registry: enemy_region should be registered")
	_assert.that(system.has_target_rule(CardTargetTypeScript.OWNED_REGION), "target registry: owned_region should be registered")


func _test_owned_border_rule_accepts_valid_cell() -> void:
	var fixture = _make_fixture()
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, Vector2i(9, 5))
	var result = fixture.system.can_play(req)
	_assert.that(result.success, "target validator: owned border should accept known player border")
	_cleanup_fixture(fixture)


func _test_owned_border_rule_rejects_internal_cell() -> void:
	var fixture = _make_fixture()
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5))
	var result = fixture.system.can_play(req)
	_assert.that(not result.success, "target validator: internal owned cell should not count as owned border")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INVALID_TARGET, "target validator: internal owned cell should be invalid")
	_cleanup_fixture(fixture)


func _test_region_rule_rejects_missing_region() -> void:
	var fixture = _make_fixture()
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_CALIBRATED_SHOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, 999999)
	var result = fixture.system.can_play(req)
	_assert.that(not result.success, "target validator: unknown region should fail")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INVALID_TARGET, "target validator: unknown region should be invalid")
	_cleanup_fixture(fixture)


func _make_fixture() -> Dictionary:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var fortify_layer = FortifyLayerScript.new()
	fortify_layer.configure(20)

	var morale_system = RegionMoraleSystemScript.new()
	morale_system.setup(rm, bf)

	var target_bias_system = CardfrontTargetBiasSystemScript.new()
	target_bias_system.setup(rm)

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(100)
	player_state.add_parts(100)
	var ai_state = CardfrontResourceStateScript.new()
	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
		CardfrontRulesScript.AI_FACTION: ai_state,
	}

	var system = CardPlaySystemScript.new()
	system.setup(resource_states, rm, bf, fortify_layer, morale_system, null, target_bias_system)
	return {
		"system": system,
		"bf": bf,
		"morale_system": morale_system,
		"target_bias_system": target_bias_system,
	}


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bf", null))
	TestFixtures.cleanup_node(fixture.get("morale_system", null))
	TestFixtures.cleanup_node(fixture.get("target_bias_system", null))
