extends SceneTree

const CardEffectRegistryScript = preload("res://scripts/cardfront/effects/CardEffectRegistry.gd")
const CardEffectResolverScript = preload("res://scripts/cardfront/effects/CardEffectResolver.gd")
const FortifyBorderEffectScript = preload("res://scripts/cardfront/effects/effects/FortifyBorderEffect.gd")
const CalibratedShotEffectScript = preload("res://scripts/cardfront/effects/effects/CalibratedShotEffect.gd")
const MoraleFluctuationEffectScript = preload("res://scripts/cardfront/effects/effects/MoraleFluctuationEffect.gd")
const PioneerBeaconLiteEffectScript = preload("res://scripts/cardfront/effects/effects/PioneerBeaconLiteEffect.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionMoraleRulesScript = preload("res://scripts/cardfront/morale/RegionMoraleRules.gd")
const RegionMoraleSystemScript = preload("res://scripts/cardfront/morale/RegionMoraleSystem.gd")
const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")
const CardfrontBattlefieldInitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardEffectResolverTest] Starting Cardfront card effect resolver tests")
	await process_frame

	_test_registry_rejects_invalid_effects()
	_test_resolver_unknown_effect_returns_stub()
	_test_fortify_border_effect()
	_test_calibrated_shot_effect()
	_test_morale_fluctuation_effect()
	_test_pioneer_beacon_lite_effect()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardEffectResolverTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_registry_rejects_invalid_effects() -> void:
	var registry = CardEffectRegistryScript.new()
	registry.register("bad", RefCounted.new())
	_assert.that(not registry.has_effect("bad"), "effect registry: object without resolve should not register")

	registry.register("fortify_border", FortifyBorderEffectScript.new())
	_assert.that(registry.has_effect("fortify_border"), "effect registry: valid effect should register")
	_assert.eq(registry.get_registered_effect_ids(), ["fortify_border"], "effect registry: registered ids should sort")


func _test_resolver_unknown_effect_returns_stub() -> void:
	var resolver = CardEffectResolverScript.new()
	var card = CardCatalogScript.new().get_card(CardCatalogScript.CARD_FRONTLINE_FORTIFY)
	card.effect_id = "missing_effect"
	var req = CardPlayRequestScript.make(card.id, CardfrontRulesScript.PLAYER_FACTION, Vector2i(9, 5))
	var result = resolver.resolve(req, card)
	_assert.that(not result.success, "effect resolver: unknown effect should fail")
	_assert.eq(result.reason, CardPlayResultScript.REASON_STUB, "effect resolver: unknown effect should report stub")


func _test_fortify_border_effect() -> void:
	var fixture = _make_fixture()
	var resolver = _make_resolver(fixture)
	var card = CardCatalogScript.new().get_card(CardCatalogScript.CARD_FRONTLINE_FORTIFY)
	var cell = Vector2i(9, 5)
	var req = CardPlayRequestScript.make(card.id, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = resolver.resolve(req, card)

	_assert.that(result.success, "fortify effect: should succeed")
	_assert.eq(fixture.fortify_layer.get_fortify_stack(cell), FortifyRulesScript.DEFAULT_FORTIFY_STACKS, "fortify effect: should add default stacks")
	_cleanup_fixture(fixture)


func _test_calibrated_shot_effect() -> void:
	var fixture = _make_fixture()
	var resolver = _make_resolver(fixture)
	var card = CardCatalogScript.new().get_card(CardCatalogScript.CARD_CALIBRATED_SHOT)
	var region_id: int = _first_target_region_id(fixture.region_map)
	var req = CardPlayRequestScript.make(card.id, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, region_id)
	var result = resolver.resolve(req, card)

	_assert.that(result.success, "calibrated shot effect: should succeed")
	_assert.eq(fixture.target_bias_system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), region_id, "calibrated shot effect: should set target bias")
	_cleanup_fixture(fixture)


func _test_morale_fluctuation_effect() -> void:
	var fixture = _make_fixture()
	var resolver = _make_resolver(fixture)
	var card = CardCatalogScript.new().get_card(CardCatalogScript.CARD_MORALE_FLUCTUATION)
	var region_id: int = _first_target_region_id(fixture.region_map)
	var req = CardPlayRequestScript.make(card.id, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, region_id)
	var result = resolver.resolve(req, card)

	_assert.that(result.success, "morale effect: should succeed")
	_assert.eq(fixture.morale_system.active_effects.size(), 1, "morale effect: should add one active effect")
	_assert.eq(str((fixture.morale_system.active_effects[0] as Dictionary).get("mode", "")), RegionMoraleRulesScript.SUPPORT_PLAYER, "morale effect: should use support player mode")
	_cleanup_fixture(fixture)


func _test_pioneer_beacon_lite_effect() -> void:
	var fixture = _make_fixture()
	var resolver = _make_resolver(fixture)
	var card = CardCatalogScript.new().get_card(CardCatalogScript.CARD_PIONEER_BEACON)
	var cell = Vector2i(3, 5)
	var before_neutral: int = int(fixture.battlefield.owner_counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0))
	var req = CardPlayRequestScript.make(card.id, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = resolver.resolve(req, card)
	var after_neutral: int = int(fixture.battlefield.owner_counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0))

	_assert.that(result.success, "pioneer beacon effect: should succeed")
	_assert.gt(before_neutral, after_neutral, "pioneer beacon effect: should convert neutral cells")
	_cleanup_fixture(fixture)


func _make_resolver(fixture: Dictionary):
	var resolver = CardEffectResolverScript.new()
	resolver.setup({
		"region_map": fixture.region_map,
		"battlefield": fixture.battlefield,
		"fortify_layer": fixture.fortify_layer,
		"morale_system": fixture.morale_system,
		"region_overlay": null,
		"target_bias_system": fixture.target_bias_system,
	})
	resolver.register("fortify_border", FortifyBorderEffectScript.new())
	resolver.register("calibrated_shot", CalibratedShotEffectScript.new())
	resolver.register("morale_fluctuation", MoraleFluctuationEffectScript.new())
	resolver.register("pioneer_beacon_lite", PioneerBeaconLiteEffectScript.new())
	return resolver


func _make_fixture() -> Dictionary:
	var battlefield = Battlefield.new()
	battlefield.configure(20)
	get_root().add_child(battlefield)
	CardfrontBattlefieldInitializerScript.configure_duel(battlefield)

	var region_map = RegionMapScript.new()
	region_map.configure(20)
	region_map.generate_default_layout()

	var fortify_layer = FortifyLayerScript.new()
	fortify_layer.configure(20)

	var morale_system = RegionMoraleSystemScript.new()
	morale_system.setup(region_map, battlefield)

	var target_bias_system = CardfrontTargetBiasSystemScript.new()
	target_bias_system.setup(region_map)

	return {
		"battlefield": battlefield,
		"region_map": region_map,
		"fortify_layer": fortify_layer,
		"morale_system": morale_system,
		"target_bias_system": target_bias_system,
	}


func _first_target_region_id(region_map) -> int:
	var ids: Array = region_map.get_controllable_region_ids()
	if ids.is_empty():
		return 0
	return int(ids[0])


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("battlefield", null))
	TestFixtures.cleanup_node(fixture.get("morale_system", null))
	TestFixtures.cleanup_node(fixture.get("target_bias_system", null))
