extends SceneTree

const CardPlaySystemScript = preload("res://scripts/cardfront/cards/CardPlaySystem.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionMoraleRulesScript = preload("res://scripts/cardfront/morale/RegionMoraleRules.gd")
const RegionMoraleSystemScript = preload("res://scripts/cardfront/morale/RegionMoraleSystem.gd")
const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardFirstEffectsTest] Starting Cardfront first card effects tests")
	await process_frame

	_test_morale_fluctuation_success_adds_active_effect()
	_test_morale_fluctuation_missing_system_rolls_back()
	_test_morale_fluctuation_invalid_region_rejected()
	_test_morale_fluctuation_apply_false_rolls_back()
	_test_calibrated_shot_success_sets_target_bias()
	_test_calibrated_shot_missing_bias_system_rolls_back()
	_test_fortify_border_still_adds_stacks()
	_test_effect_registry_covers_current_catalog()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardFirstEffectsTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_morale_fluctuation_success_adds_active_effect() -> void:
	var fixture = _make_fixture(50, 20)
	var region_id: int = _first_target_region_id(fixture.rm)
	var morale_system = fixture.morale_system
	var player_state = fixture.player_state

	var before_effects: int = morale_system.active_effects.size()
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_MORALE_FLUCTUATION, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, region_id)
	var result = fixture.system.play(req)

	_assert.that(result.success, "first effects: morale fluctuation should succeed with morale system")
	_assert.eq(morale_system.active_effects.size(), before_effects + 1, "first effects: morale fluctuation should add active morale effect")
	_assert.eq(int((morale_system.active_effects[0] as Dictionary).get("region_id", -1)), region_id, "first effects: morale effect should target requested region")
	_assert.eq(str((morale_system.active_effects[0] as Dictionary).get("mode", "")), RegionMoraleRulesScript.SUPPORT_PLAYER, "first effects: morale effect should use support player mode")
	_assert.eq(int(player_state.energy), 45, "first effects: morale success should consume 5 energy")
	_assert.eq(int(player_state.parts), 18, "first effects: morale success should consume 2 parts")
	_assert.that(not fixture.system.hand.can_play_card(CardCatalogScript.CARD_MORALE_FLUCTUATION), "first effects: morale success should mark card used")

	_cleanup_fixture(fixture)


func _test_morale_fluctuation_missing_system_rolls_back() -> void:
	var fixture = _make_fixture(30, 10, false, true)
	var region_id: int = _first_target_region_id(fixture.rm)

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_MORALE_FLUCTUATION, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, region_id)
	var result = fixture.system.play(req)

	_assert.that(not result.success, "first effects: morale should fail without morale system")
	_assert.eq(result.reason, CardPlayResultScript.REASON_MISSING_SYSTEM, "first effects: missing morale system should report missing_system")
	_assert.eq(int(fixture.player_state.energy), 30, "first effects: missing morale system should roll back energy")
	_assert.eq(int(fixture.player_state.parts), 10, "first effects: missing morale system should roll back parts")
	_assert.that(fixture.system.hand.can_play_card(CardCatalogScript.CARD_MORALE_FLUCTUATION), "first effects: missing morale system should roll back used hand state")

	_cleanup_fixture(fixture)


func _test_morale_fluctuation_invalid_region_rejected() -> void:
	var fixture = _make_fixture(30, 10)
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_MORALE_FLUCTUATION, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, 999999)
	var result = fixture.system.play(req)

	_assert.that(not result.success, "first effects: morale should reject invalid region id")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INVALID_TARGET, "first effects: invalid morale region should report invalid_target")
	_assert.eq(int(fixture.player_state.energy), 30, "first effects: invalid morale region should not consume energy")
	_assert.eq(int(fixture.player_state.parts), 10, "first effects: invalid morale region should not consume parts")
	_assert.that(fixture.system.hand.can_play_card(CardCatalogScript.CARD_MORALE_FLUCTUATION), "first effects: invalid morale region should leave card playable")

	_cleanup_fixture(fixture)


func _test_morale_fluctuation_apply_false_rolls_back() -> void:
	var fixture = _make_fixture(30, 10, true, true, false)
	var region_id: int = _first_target_region_id(fixture.rm)
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_MORALE_FLUCTUATION, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, region_id)
	var result = fixture.system.play(req)

	_assert.that(not result.success, "first effects: morale should fail when apply_morale returns false")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INVALID_TARGET, "first effects: failed morale application should report invalid_target")
	_assert.eq(int(fixture.player_state.energy), 30, "first effects: failed morale application should roll back energy")
	_assert.eq(int(fixture.player_state.parts), 10, "first effects: failed morale application should roll back parts")
	_assert.that(fixture.system.hand.can_play_card(CardCatalogScript.CARD_MORALE_FLUCTUATION), "first effects: failed morale application should roll back used hand state")

	_cleanup_fixture(fixture)


func _test_calibrated_shot_success_sets_target_bias() -> void:
	var fixture = _make_fixture(40, 20)
	var region_id: int = _first_target_region_id(fixture.rm)
	var target_bias_system = fixture.target_bias_system

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_CALIBRATED_SHOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, region_id)
	var result = fixture.system.play(req)

	_assert.that(result.success, "first effects: calibrated shot should succeed with target bias system")
	_assert.eq(target_bias_system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), region_id, "first effects: calibrated shot should register biased region")
	_assert.eq(int(fixture.player_state.energy), 32, "first effects: calibrated shot should consume 8 energy")
	_assert.eq(int(fixture.player_state.parts), 15, "first effects: calibrated shot should consume 5 parts")
	_assert.that(not fixture.system.hand.can_play_card(CardCatalogScript.CARD_CALIBRATED_SHOT), "first effects: calibrated shot success should mark card used")

	_cleanup_fixture(fixture)


func _test_calibrated_shot_missing_bias_system_rolls_back() -> void:
	var fixture = _make_fixture(40, 20, true, false)
	var region_id: int = _first_target_region_id(fixture.rm)

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_CALIBRATED_SHOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, region_id)
	var result = fixture.system.play(req)

	_assert.that(not result.success, "first effects: calibrated shot should fail without target bias system")
	_assert.eq(result.reason, CardPlayResultScript.REASON_MISSING_SYSTEM, "first effects: missing target bias system should report missing_system")
	_assert.eq(int(fixture.player_state.energy), 40, "first effects: missing target bias should roll back energy")
	_assert.eq(int(fixture.player_state.parts), 20, "first effects: missing target bias should roll back parts")
	_assert.that(fixture.system.hand.can_play_card(CardCatalogScript.CARD_CALIBRATED_SHOT), "first effects: missing target bias should roll back used hand state")

	_cleanup_fixture(fixture)


func _test_fortify_border_still_adds_stacks() -> void:
	var fixture = _make_fixture(40, 20)
	var cell = Vector2i(9, 5)
	var fortify_layer = fixture.fortify_layer
	_assert.eq(fortify_layer.get_fortify_stack(cell), 0, "first effects: fortify cell should start unfortified")

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = fixture.system.play(req)

	_assert.that(result.success, "first effects: fortify should still succeed")
	_assert.eq(fortify_layer.get_fortify_stack(cell), FortifyRulesScript.DEFAULT_FORTIFY_STACKS, "first effects: fortify should still add default stacks")

	_cleanup_fixture(fixture)


func _test_effect_registry_covers_current_catalog() -> void:
	var system = CardPlaySystemScript.new()
	var expected_ids: Array = [
		"calibrated_shot",
		"fortify_border",
		"morale_fluctuation",
		"pioneer_beacon_lite",
	]
	_assert.eq(system.get_registered_effect_ids(), expected_ids, "effect registry: current catalog effects should be registered")

	var catalog = CardCatalogScript.new()
	for card_id in catalog.get_default_hand_ids():
		var card = catalog.get_card(int(card_id))
		_assert.that(system.has_effect_handler(str(card.effect_id)), "effect registry: card %s effect should have handler" % int(card_id))


func _make_fixture(energy: int = 100, parts: int = 50, with_morale_system: bool = true, with_target_bias_system: bool = true, setup_morale_system: bool = true) -> Dictionary:
	var bf = Battlefield.new()
	bf.configure(20)
	get_root().add_child(bf)
	bf.reset_quadrants()

	var rm = RegionMapScript.new()
	rm.configure(20)
	rm.generate_default_layout()

	var fortify_layer = FortifyLayerScript.new()
	fortify_layer.configure(20)

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(energy)
	player_state.add_parts(parts)
	var ai_state = CardfrontResourceStateScript.new()
	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
		CardfrontRulesScript.AI_FACTION: ai_state,
	}

	var morale_system = null
	if with_morale_system:
		morale_system = RegionMoraleSystemScript.new()
		if setup_morale_system:
			morale_system.setup(rm, bf)

	var target_bias_system = null
	if with_target_bias_system:
		target_bias_system = CardfrontTargetBiasSystemScript.new()
		target_bias_system.setup(rm)

	var system = CardPlaySystemScript.new()
	system.setup(resource_states, rm, bf, fortify_layer, morale_system, null, target_bias_system)

	return {
		"system": system,
		"bf": bf,
		"rm": rm,
		"fortify_layer": fortify_layer,
		"morale_system": morale_system,
		"target_bias_system": target_bias_system,
		"player_state": player_state,
	}


func _first_target_region_id(region_map) -> int:
	var ids: Array = region_map.get_controllable_region_ids()
	if ids.is_empty():
		return 0
	return int(ids[0])


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bf", null))
	TestFixtures.cleanup_node(fixture.get("morale_system", null))
	TestFixtures.cleanup_node(fixture.get("target_bias_system", null))
