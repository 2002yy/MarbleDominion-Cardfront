extends SceneTree

const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontUpgradeContentTest] Starting v0.3 upgrade content tests")
	await process_frame

	_test_manifest_is_valid()
	_test_cards_are_text_and_symbol_driven()
	_test_seeded_offers_are_unique_and_deterministic()
	_test_legacy_four_choice_request_is_capped_to_three()
	_test_rarity_growth_changes_weights()
	_test_mid_and_late_offer_quality_guarantees()
	_test_capped_or_armed_upgrades_are_not_offered()
	_test_timeout_fallback_comes_from_offer()

	_assert.report("[CardfrontUpgradeContentTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_manifest_is_valid() -> void:
	_assert.eq(UpgradeManifestScript.validate_all(), [], "upgrade manifest: all core and candidate definitions should validate")
	_assert.eq(UpgradeManifestScript.CORE_UPGRADE_IDS.size(), 8, "upgrade manifest: historical audit baseline should stay at eight upgrades")
	_assert.eq(UpgradeManifestScript.get_upgrade_ids().size(), 18, "upgrade manifest: formal live pool should contain eighteen upgrades")
	_assert.eq(UpgradeManifestScript.get_all_upgrade_ids().size(), 18, "upgrade manifest: catalog should contain only implemented upgrades")
	_assert.eq(DeckRegistryScript.validate_all(), [], "upgrade decks: all selectable candidate decks should validate")


func _test_cards_are_text_and_symbol_driven() -> void:
	for upgrade_id in UpgradeManifestScript.get_all_upgrade_ids():
		var definition: Dictionary = UpgradeManifestScript.get_definition(str(upgrade_id))
		_assert.that(str(definition.get("name", "")) != "", "upgrade content: card should have a name")
		var symbol: String = str(definition.get("symbol", ""))
		_assert.that(symbol != "", "upgrade content: card should have a bold symbol")
		_assert.that(not _contains_ascii_letters(symbol), "upgrade content: card symbols should use direct Chinese and numeric language")
		_assert.that(str(definition.get("description", "")) != "", "upgrade content: card should have a direct description")
		_assert.that(not definition.has("texture_path"), "upgrade content: base card should not require generated art")


func _test_seeded_offers_are_unique_and_deterministic() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var first = DraftSystemScript.new()
	var second = DraftSystemScript.new()
	first.set_seed(20260723)
	second.set_seed(20260723)

	var first_offer: Array = first.draw_three(state)
	var second_offer: Array = second.draw_three(state)
	var first_ids: Array = _offer_ids(first_offer)
	var second_ids: Array = _offer_ids(second_offer)

	_assert.eq(first_offer.size(), 3, "draft: an offer should contain three upgrades")
	_assert.eq(first_ids, second_ids, "draft: same seed and state should produce the same offer")
	var unique_ids: Dictionary = {}
	for upgrade_id in first_ids:
		unique_ids[str(upgrade_id)] = true
	_assert.eq(unique_ids.size(), 3, "draft: offer upgrades should be unique")
	for upgrade_id in first_ids:
		_assert.that(upgrade_id in UpgradeManifestScript.get_upgrade_ids(), "draft: default state should only draw the formal live pool")
	_test_formal_pool_exposes_typed_conversions()


func _test_rarity_growth_changes_weights() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	var rare_definition: Dictionary = UpgradeManifestScript.get_definition(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE)
	var common_definition: Dictionary = UpgradeManifestScript.get_definition(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5)
	var base_rare_weight: float = draft.weight_for_definition(rare_definition, state)
	var base_common_weight: float = draft.weight_for_definition(common_definition, state)

	state.increase_rarity_level(3)

	_assert.gt(draft.weight_for_definition(rare_definition, state), base_rare_weight, "rarity: rare weight should increase")
	_assert.that(draft.weight_for_definition(common_definition, state) < base_common_weight, "rarity: common weight should decrease")


func _test_mid_and_late_offer_quality_guarantees() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	state.selected_upgrade_levels[UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5] = 3
	for seed_value in range(1, 21):
		draft.set_seed(seed_value)
		_assert.gte(_highest_rarity_rank(draft.draw_three(state)), 1, "quality floor: after three prior selections every offer has an Uncommon-or-better card")
	state.selected_upgrade_levels[UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5] = 6
	for seed_value in range(21, 41):
		draft.set_seed(seed_value)
		_assert.eq(_highest_rarity_rank(draft.draw_three(state)), 2, "quality floor: after six prior selections every offer has a Rare card")
	state.selected_upgrade_levels[UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5] = 5
	state.increase_rarity_level(1)
	for seed_value in range(41, 61):
		draft.set_seed(seed_value)
		_assert.eq(_highest_rarity_rank(draft.draw_three(state)), 2, "rarity growth: each level advances the Rare guarantee by one prior selection")


func _test_legacy_four_choice_request_is_capped_to_three() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	draft.set_seed(3)
	var offer: Array = draft.draw_offer(state, 4)
	var unique_ids: Dictionary = {}
	for definition in offer:
		unique_ids[str((definition as Dictionary).get("id", ""))] = true
	_assert.eq(offer.size(), 3, "draft: legacy four-choice requests should be capped to the formal three-choice contract")
	_assert.eq(unique_ids.size(), 3, "draft: capped offer should remain unique")


func _test_timeout_fallback_comes_from_offer() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	draft.set_seed(77)
	var offer: Array = draft.draw_three(state)
	var selected: Dictionary = draft.choose_timeout_fallback(offer)

	_assert.that(not selected.is_empty(), "timeout: non-empty offer should produce a selection")
	_assert.that(_offer_ids(offer).has(str(selected.get("id", ""))), "timeout: selection should come from the current offer")
	_assert.eq(draft.choose_timeout_fallback([]), {}, "timeout: empty offer should fail safely")


func _test_formal_pool_exposes_typed_conversions() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	var seen: Dictionary = {}
	for seed_value in range(1, 161):
		draft.set_seed(seed_value)
		for upgrade_id in _offer_ids(draft.draw_three(state)):
			seen[str(upgrade_id)] = true
	_assert.that(seen.has(UpgradeManifestScript.UPGRADE_SIEGE_CALIBRATION), "draft: formal pool should expose siege formation")
	_assert.that(seen.has(UpgradeManifestScript.UPGRADE_SUPPRESSION_SCREEN), "draft: formal pool should expose suppression formation")


func _test_capped_or_armed_upgrades_are_not_offered() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	state.increase_rarity_level(RunStateScript.MAX_RARITY_LEVEL)
	state.increase_attack_level(RunStateScript.MAX_ATTACK_LEVEL)
	state.increase_territory_defense_cap(RunStateScript.MAX_TERRITORY_DEFENSE_CAP)
	state.arm_echo_next_choice()
	var draft = DraftSystemScript.new()
	draft.set_seed(119)
	var offer_ids: Array = _offer_ids(draft.draw_three(state))

	_assert.that(not offer_ids.has(UpgradeManifestScript.UPGRADE_RARITY_PLUS_1), "draft: capped rarity upgrade should not be offered")
	_assert.that(not offer_ids.has(UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1), "draft: capped attack upgrade should not be offered")
	_assert.that(not offer_ids.has(UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1), "draft: capped defense upgrade should not be offered")
	_assert.that(not offer_ids.has(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE), "draft: armed echo should not be offered")
	_assert.eq(offer_ids.size(), 3, "draft: eligibility filters should still leave three choices")


func _offer_ids(offer: Array) -> Array:
	var result: Array = []
	for raw_definition in offer:
		if raw_definition is Dictionary:
			result.append(str((raw_definition as Dictionary).get("id", "")))
	return result


func _highest_rarity_rank(offer: Array) -> int:
	var highest := 0
	for raw_definition in offer:
		if not (raw_definition is Dictionary):
			continue
		match str((raw_definition as Dictionary).get("rarity", "")):
			UpgradeManifestScript.RARITY_RARE:
				highest = maxi(highest, 2)
			UpgradeManifestScript.RARITY_UNCOMMON:
				highest = maxi(highest, 1)
	return highest


func _contains_ascii_letters(value: String) -> bool:
	for index in range(value.length()):
		var codepoint: int = value.unicode_at(index)
		if (codepoint >= 65 and codepoint <= 90) or (codepoint >= 97 and codepoint <= 122):
			return true
	return false
