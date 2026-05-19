extends SceneTree

const CardPlaySystemScript = preload("res://scripts/cardfront/cards/CardPlaySystem.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const CardDataScript = preload("res://scripts/cardfront/cards/CardData.gd")
const CardTypeScript = preload("res://scripts/cardfront/cards/CardType.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")
const CardHandStateScript = preload("res://scripts/cardfront/cards/CardHandState.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const FortifyLayerScript = preload("res://scripts/cardfront/fortify/FortifyLayer.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const RegionMoraleSystemScript = preload("res://scripts/cardfront/morale/RegionMoraleSystem.gd")
const CardfrontTargetBiasSystemScript = preload("res://scripts/cardfront/effects/CardfrontTargetBiasSystem.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardCoreLiteTest] Starting Cardfront card core lite tests")
	await process_frame

	_test_fixed_hand_has_three_cards()
	_test_card_data_correct()
	_test_fortify_success_on_owned_border()
	_test_insufficient_energy_rejected()
	_test_insufficient_parts_rejected()
	_test_invalid_target_rejected()
	_test_same_card_cannot_play_twice()
	_test_fortify_adds_stacks()
	_test_calibrated_shot_effect_succeeds()
	_test_morale_fluctuation_effect_succeeds()
	_test_hand_state_mark_and_available()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[CardCoreLiteTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _make_system(energy: int = 100, parts: int = 50):
	var system = CardPlaySystemScript.new()

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(energy)
	player_state.add_parts(parts)
	var ai_state = CardfrontResourceStateScript.new()

	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
		CardfrontRulesScript.AI_FACTION: ai_state,
	}
	system.setup(resource_states, null, null, null, null, null)
	return system


func _make_system_with_battlefield(energy: int = 100, parts: int = 50):
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

	var system = CardPlaySystemScript.new()

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(energy)
	player_state.add_parts(parts)
	var ai_state = CardfrontResourceStateScript.new()

	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
		CardfrontRulesScript.AI_FACTION: ai_state,
	}
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


func _test_fixed_hand_has_three_cards() -> void:
	var system = _make_system()
	var available = system.get_available_card_data()
	_assert.eq(available.size(), 3, "card core: fixed hand should have 3 cards")


func _test_card_data_correct() -> void:
	var system = _make_system()
	var available = system.get_available_card_data()

	var fortify_card = _find_by_id(available, CardCatalogScript.CARD_FRONTLINE_FORTIFY)
	_assert.that(fortify_card != null, "card core: should have frontline fortify card")
	if fortify_card != null:
		_assert.eq(str(fortify_card.get("card_name", "")), "前线加固", "card core: fortify card name")
		_assert.eq(int(fortify_card.get("energy_cost", 0)), 10, "card core: fortify energy cost")
		_assert.eq(int(fortify_card.get("parts_cost", 0)), 3, "card core: fortify parts cost")

	var shot_card = _find_by_id(available, CardCatalogScript.CARD_CALIBRATED_SHOT)
	_assert.that(shot_card != null, "card core: should have calibrated shot card")

	var morale_card = _find_by_id(available, CardCatalogScript.CARD_MORALE_FLUCTUATION)
	_assert.that(morale_card != null, "card core: should have morale fluctuation card")


func _test_fortify_success_on_owned_border() -> void:
	var fixture = _make_system_with_battlefield(20, 10)
	var bf = fixture.bf
	var rm = fixture.rm
	var system = fixture.system
	var player_state = fixture.player_state

	var cell = Vector2i(9, 5)
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = system.play(req)

	_assert.that(result.success, "card core: fortify should succeed on owned border cell")
	_assert.eq(result.reason, CardPlayResultScript.REASON_SUCCESS, "card core: fortify reason should be success")
	_assert.eq(int(result.consumed_energy), 10, "card core: fortify should consume 10 energy")
	_assert.eq(int(result.consumed_parts), 3, "card core: fortify should consume 3 parts")
	_assert.eq(int(player_state.energy), 10, "card core: energy should be 10 after paying 10 from 20")
	_assert.eq(int(player_state.parts), 7, "card core: parts should be 7 after paying 3 from 10")

	_cleanup_fixture(fixture)


func _test_insufficient_energy_rejected() -> void:
	var fixture = _make_system_with_battlefield(5, 50)
	var bf = fixture.bf
	var system = fixture.system

	var cell = Vector2i(9, 5)
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = system.play(req)

	_assert.that(not result.success, "card core: should reject when insufficient energy")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INSUFFICIENT_RESOURCES, "card core: reason should be insufficient_resources")

	_cleanup_fixture(fixture)


func _test_insufficient_parts_rejected() -> void:
	var fixture = _make_system_with_battlefield(50, 1)
	var bf = fixture.bf
	var system = fixture.system

	var cell = Vector2i(9, 5)
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, cell)
	var result = system.play(req)

	_assert.that(not result.success, "card core: should reject when insufficient parts")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INSUFFICIENT_RESOURCES, "card core: reason should be insufficient_resources")

	_cleanup_fixture(fixture)


func _test_invalid_target_rejected() -> void:
	var fixture = _make_system_with_battlefield(50, 50)
	var bf = fixture.bf
	var system = fixture.system

	var internal_cell = Vector2i(5, 5)
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, internal_cell)
	var result = system.play(req)

	_assert.that(not result.success, "card core: should reject non-border cell")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INVALID_TARGET, "card core: reason should be invalid_target")

	_cleanup_fixture(fixture)


func _test_same_card_cannot_play_twice() -> void:
	var fixture = _make_system_with_battlefield(50, 50)
	var bf = fixture.bf
	var system = fixture.system

	var cell = Vector2i(9, 5)
	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, cell)
	var r1 = system.play(req)
	_assert.that(r1.success, "card core: first play should succeed")

	var r2 = system.play(req)
	_assert.that(not r2.success, "card core: second play should be rejected (already used)")
	_assert.eq(r2.reason, CardPlayResultScript.REASON_CARD_ALREADY_USED, "card core: reason should be card_already_used")

	_cleanup_fixture(fixture)


func _test_fortify_adds_stacks() -> void:
	var fixture = _make_system_with_battlefield(50, 50)
	var bf = fixture.bf
	var fortify_layer = fixture.fortify_layer
	var system = fixture.system

	var cell = Vector2i(9, 5)
	_assert.eq(fortify_layer.get_fortify_stack(cell), 0, "card core: cell should start with 0 fortify")

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardfrontRulesScript.PLAYER_FACTION, cell)
	system.play(req)

	_assert.eq(fortify_layer.get_fortify_stack(cell), FortifyRulesScript.DEFAULT_FORTIFY_STACKS, "card core: fortify card should add 3 stacks")

	_cleanup_fixture(fixture)


func _test_calibrated_shot_effect_succeeds() -> void:
	var fixture = _make_system_with_battlefield(50, 50)
	var system = fixture.system
	var target_bias_system = fixture.target_bias_system

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_CALIBRATED_SHOT, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, 0)
	var result = system.play(req)

	_assert.that(result.success, "card core: calibrated shot effect should succeed")
	_assert.eq(target_bias_system.get_biased_region(CardfrontRulesScript.PLAYER_FACTION), 0, "card core: calibrated shot should set target bias")
	_assert.eq(result.card_name, "校准射击", "card core: calibrated shot card name")

	_cleanup_fixture(fixture)


func _test_morale_fluctuation_effect_succeeds() -> void:
	var fixture = _make_system_with_battlefield(50, 50)
	var system = fixture.system
	var morale_system = fixture.morale_system

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_MORALE_FLUCTUATION, CardfrontRulesScript.PLAYER_FACTION, Vector2i.ZERO, 0)
	var result = system.play(req)

	_assert.that(result.success, "card core: morale fluctuation effect should succeed")
	_assert.eq(morale_system.active_effects.size(), 1, "card core: morale fluctuation should add active morale effect")
	_assert.eq(result.card_name, "民心起伏", "card core: morale fluctuation card name")

	_cleanup_fixture(fixture)


func _test_hand_state_mark_and_available() -> void:
	var system = _make_system()
	var hand = CardHandStateScript.new()
	hand.initialize_fixed_hand([CardCatalogScript.CARD_FRONTLINE_FORTIFY, CardCatalogScript.CARD_CALIBRATED_SHOT])
	_assert.eq(hand.get_available_card_ids().size(), 2, "hand: both cards available initially")
	_assert.that(hand.can_play_card(CardCatalogScript.CARD_FRONTLINE_FORTIFY), "hand: fortify playable initially")
	hand.mark_used(CardCatalogScript.CARD_FRONTLINE_FORTIFY)
	_assert.that(not hand.can_play_card(CardCatalogScript.CARD_FRONTLINE_FORTIFY), "hand: fortify not playable after mark_used")
	_assert.that(hand.can_play_card(CardCatalogScript.CARD_CALIBRATED_SHOT), "hand: calibrated shot still playable")
	_assert.eq(hand.get_available_card_ids().size(), 1, "hand: 1 card available after marking one used")


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bf", null))
	TestFixtures.cleanup_node(fixture.get("morale_system", null))
	TestFixtures.cleanup_node(fixture.get("target_bias_system", null))


func _find_by_id(data_list: Array, target_id: int):
	for item in data_list:
		if int(item.get("id", -1)) == target_id:
			return item
	return null
