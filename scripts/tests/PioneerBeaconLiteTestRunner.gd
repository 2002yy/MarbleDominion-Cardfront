extends SceneTree

const CardPlaySystemScript = preload("res://scripts/cardfront/cards/CardPlaySystem.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")
const CardfrontResourceStateScript = preload("res://scripts/cardfront/economy/CardfrontResourceState.gd")
const RegionMapScript = preload("res://scripts/cardfront/regions/RegionMap.gd")
const PioneerBeaconLiteEffectScript = preload("res://scripts/cardfront/effects/PioneerBeaconLiteEffect.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[PioneerBeaconLiteTest] Starting Cardfront pioneer beacon lite tests")
	await process_frame

	_test_card_catalog_contains_pioneer_beacon()
	_test_success_converts_up_to_three_neutral_neighbors()
	_test_no_neutral_neighbor_fails_and_rolls_back()
	_test_non_border_target_rejected()
	_test_missing_system_fails_without_payment()
	_test_effect_direct_result_reports_converted_cells()

	GameConfig.reset_runtime_defaults()
	await _flush()

	_assert.report("[PioneerBeaconLiteTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_card_catalog_contains_pioneer_beacon() -> void:
	var catalog = CardCatalogScript.new()
	var card = catalog.get_card(CardCatalogScript.CARD_PIONEER_BEACON)

	_assert.that(card != null, "pioneer beacon: catalog should include card 1004")
	if card != null:
		_assert.eq(card.card_name, "拓荒信标", "pioneer beacon: card name")
		_assert.eq(card.energy_cost, 8, "pioneer beacon: energy cost")
		_assert.eq(card.parts_cost, 4, "pioneer beacon: parts cost")
		_assert.eq(card.target_type, "owned_border", "pioneer beacon: target type")
		_assert.eq(card.effect_id, "pioneer_beacon_lite", "pioneer beacon: effect id")
	_assert.eq(catalog.get_default_hand_ids().size(), 4, "pioneer beacon: default hand should now have 4 cards")


func _test_success_converts_up_to_three_neutral_neighbors() -> void:
	var fixture: Dictionary = _make_fixture(20, 20, CardfrontRulesScript.NEUTRAL_OWNER)
	var bf: Battlefield = fixture.bf
	var target := Vector2i(5, 5)
	_set_owner(bf, target, CardfrontRulesScript.PLAYER_FACTION)

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, target)
	var result = fixture.system.play(req)

	_assert.that(result.success, "pioneer beacon: should succeed on owned border with neutral neighbors")
	_assert.eq(int(result.consumed_energy), 8, "pioneer beacon: success result should report 8 energy")
	_assert.eq(int(result.consumed_parts), 4, "pioneer beacon: success result should report 4 parts")
	_assert.eq(int(fixture.player_state.energy), 12, "pioneer beacon: success should consume energy")
	_assert.eq(int(fixture.player_state.parts), 16, "pioneer beacon: success should consume parts")
	_assert.eq(_count_owner(bf, CardfrontRulesScript.PLAYER_FACTION), 4, "pioneer beacon: target plus 3 neutral neighbors should be player-owned")
	_assert.eq(_count_converted_neighbors(bf, target), 3, "pioneer beacon: should convert exactly 3 nearby neutral cells when available")
	_assert.that(not fixture.system.hand.can_play_card(CardCatalogScript.CARD_PIONEER_BEACON), "pioneer beacon: success should mark card used")

	_cleanup_fixture(fixture)


func _test_no_neutral_neighbor_fails_and_rolls_back() -> void:
	var fixture: Dictionary = _make_fixture(20, 20, CardfrontRulesScript.AI_FACTION)
	var bf: Battlefield = fixture.bf
	var target := Vector2i(5, 5)
	_set_owner(bf, target, CardfrontRulesScript.PLAYER_FACTION)

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, target)
	var result = fixture.system.play(req)

	_assert.that(not result.success, "pioneer beacon: should fail when border has no neutral neighbor")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INVALID_TARGET, "pioneer beacon: no neutral neighbor should report invalid_target")
	_assert.eq(int(fixture.player_state.energy), 20, "pioneer beacon: failed effect should roll back energy")
	_assert.eq(int(fixture.player_state.parts), 20, "pioneer beacon: failed effect should roll back parts")
	_assert.eq(_count_owner(bf, CardfrontRulesScript.PLAYER_FACTION), 1, "pioneer beacon: failed effect should not convert cells")
	_assert.that(fixture.system.hand.can_play_card(CardCatalogScript.CARD_PIONEER_BEACON), "pioneer beacon: failed effect should roll back used hand state")

	_cleanup_fixture(fixture)


func _test_non_border_target_rejected() -> void:
	var fixture: Dictionary = _make_fixture(20, 20, CardfrontRulesScript.PLAYER_FACTION)
	var target := Vector2i(5, 5)

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, target)
	var result = fixture.system.play(req)

	_assert.that(not result.success, "pioneer beacon: non-border owned target should fail")
	_assert.eq(result.reason, CardPlayResultScript.REASON_INVALID_TARGET, "pioneer beacon: non-border should report invalid_target")
	_assert.eq(int(fixture.player_state.energy), 20, "pioneer beacon: non-border should not consume energy")
	_assert.eq(int(fixture.player_state.parts), 20, "pioneer beacon: non-border should not consume parts")
	_assert.that(fixture.system.hand.can_play_card(CardCatalogScript.CARD_PIONEER_BEACON), "pioneer beacon: non-border should leave card playable")

	_cleanup_fixture(fixture)


func _test_missing_system_fails_without_payment() -> void:
	var system = CardPlaySystemScript.new()
	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(20)
	player_state.add_parts(20)
	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
	}
	system.setup(resource_states, null, null, null, null, null, null)

	var req = CardPlayRequestScript.make(CardCatalogScript.CARD_PIONEER_BEACON, CardfrontRulesScript.PLAYER_FACTION, Vector2i(5, 5))
	var result = system.play(req)

	_assert.that(not result.success, "pioneer beacon: missing region/battlefield should fail")
	_assert.eq(result.reason, CardPlayResultScript.REASON_MISSING_SYSTEM, "pioneer beacon: missing system should report missing_system")
	_assert.eq(int(player_state.energy), 20, "pioneer beacon: missing system should not consume energy")
	_assert.eq(int(player_state.parts), 20, "pioneer beacon: missing system should not consume parts")
	_assert.that(system.hand.can_play_card(CardCatalogScript.CARD_PIONEER_BEACON), "pioneer beacon: missing system should leave card playable")


func _test_effect_direct_result_reports_converted_cells() -> void:
	var fixture: Dictionary = _make_fixture(20, 20, CardfrontRulesScript.NEUTRAL_OWNER)
	var bf: Battlefield = fixture.bf
	var target := Vector2i(5, 5)
	_set_owner(bf, target, CardfrontRulesScript.PLAYER_FACTION)

	var effect_result: Dictionary = PioneerBeaconLiteEffectScript.apply(fixture.rm, bf, CardfrontRulesScript.PLAYER_FACTION, target)
	var converted_cells: Array = effect_result.get("converted_cells", [])

	_assert.that(bool(effect_result.get("success", false)), "pioneer beacon effect: direct apply should succeed")
	_assert.eq(str(effect_result.get("reason", "")), PioneerBeaconLiteEffectScript.REASON_SUCCESS, "pioneer beacon effect: direct apply reason")
	_assert.eq(converted_cells.size(), 3, "pioneer beacon effect: direct apply should report 3 converted cells")
	for cell in converted_cells:
		_assert.eq(_owner_at(bf, cell), CardfrontRulesScript.PLAYER_FACTION, "pioneer beacon effect: reported cell should now be player-owned")

	_cleanup_fixture(fixture)


func _make_fixture(energy: int, parts: int, fill_owner: int) -> Dictionary:
	var bf = Battlefield.new()
	bf.configure(12)
	get_root().add_child(bf)
	bf.replace_owners(_make_owner_grid(12, fill_owner), false)

	var rm = RegionMapScript.new()
	rm.configure(12)
	rm.generate_default_layout()

	var player_state = CardfrontResourceStateScript.new()
	player_state.add_energy(energy)
	player_state.add_parts(parts)
	var ai_state = CardfrontResourceStateScript.new()
	var resource_states: Dictionary = {
		CardfrontRulesScript.PLAYER_FACTION: player_state,
		CardfrontRulesScript.AI_FACTION: ai_state,
	}

	var system = CardPlaySystemScript.new()
	system.setup(resource_states, rm, bf, null, null, null, null)

	return {
		"system": system,
		"bf": bf,
		"rm": rm,
		"player_state": player_state,
	}


func _make_owner_grid(grid_size: int, owner_id: int) -> Array:
	var owners: Array = []
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(owner_id)
		owners.append(col)
	return owners


func _set_owner(battlefield: Battlefield, cell: Vector2i, owner_id: int) -> void:
	var owners: Array = battlefield.owners.duplicate(true)
	owners[cell.x][cell.y] = owner_id
	battlefield.replace_owners(owners, false)


func _owner_at(battlefield: Battlefield, cell: Vector2i) -> int:
	return int(battlefield.owners[cell.x][cell.y])


func _count_owner(battlefield: Battlefield, owner_id: int) -> int:
	var total: int = 0
	for x in range(int(battlefield.grid_size)):
		for y in range(int(battlefield.grid_size)):
			if _owner_at(battlefield, Vector2i(x, y)) == owner_id:
				total += 1
	return total


func _count_converted_neighbors(battlefield: Battlefield, target: Vector2i) -> int:
	var total: int = 0
	for offset in PioneerBeaconLiteEffectScript.NEIGHBOR_OFFSETS:
		var cell: Vector2i = target + offset
		if battlefield.is_inside(cell) and _owner_at(battlefield, cell) == CardfrontRulesScript.PLAYER_FACTION:
			total += 1
	return total


func _cleanup_fixture(fixture: Dictionary) -> void:
	TestFixtures.cleanup_node(fixture.get("bf", null))
