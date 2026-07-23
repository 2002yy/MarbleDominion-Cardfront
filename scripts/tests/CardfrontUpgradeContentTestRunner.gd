extends SceneTree

const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
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
	_test_lab_guarantees_uncommon_or_better()
	_test_rarity_growth_changes_weights()
	_test_capped_or_armed_upgrades_are_not_offered()
	_test_timeout_fallback_comes_from_offer()

	_assert.report("[CardfrontUpgradeContentTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_manifest_is_valid() -> void:
	_assert.eq(UpgradeManifestScript.validate_all(), [], "upgrade manifest: all definitions should validate")
	_assert.eq(UpgradeManifestScript.get_upgrade_ids().size(), 6, "upgrade manifest: first slice should contain six upgrades")


func _test_cards_are_text_and_symbol_driven() -> void:
	for upgrade_id in UpgradeManifestScript.get_upgrade_ids():
		var definition: Dictionary = UpgradeManifestScript.get_definition(str(upgrade_id))
		_assert.that(str(definition.get("name", "")) != "", "upgrade content: card should have a name")
		_assert.that(str(definition.get("symbol", "")) != "", "upgrade content: card should have a bold symbol")
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


func _test_rarity_growth_changes_weights() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	var rare_definition: Dictionary = UpgradeManifestScript.get_definition(UpgradeManifestScript.UPGRADE_MIRROR_NEXT_CHOICE)
	var common_definition: Dictionary = UpgradeManifestScript.get_definition(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5)
	var base_rare_weight: float = draft.weight_for_definition(rare_definition, state)
	var base_common_weight: float = draft.weight_for_definition(common_definition, state)

	state.increase_rarity_level(3)

	_assert.gt(draft.weight_for_definition(rare_definition, state), base_rare_weight, "rarity: rare weight should increase")
	_assert.that(draft.weight_for_definition(common_definition, state) < base_common_weight, "rarity: common weight should decrease")


func _test_lab_guarantees_uncommon_or_better() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	var draft = DraftSystemScript.new()
	draft.set_seed(3)
	var offer: Array = draft.draw_three(state, true)
	var qualifying_count: int = 0
	for definition in offer:
		if str((definition as Dictionary).get("rarity", "")) in [
			UpgradeManifestScript.RARITY_UNCOMMON,
			UpgradeManifestScript.RARITY_RARE,
		]:
			qualifying_count += 1
	_assert.eq(offer.size(), 3, "lab: guaranteed offer should still contain three unique choices")
	_assert.gte(qualifying_count, 1, "lab: guaranteed offer should contain uncommon or rare content")


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


func _test_capped_or_armed_upgrades_are_not_offered() -> void:
	var state = RunStateScript.new()
	state.setup(0)
	state.increase_rarity_level(RunStateScript.MAX_RARITY_LEVEL)
	state.arm_duplicate_next_choice()
	var draft = DraftSystemScript.new()
	draft.set_seed(119)
	var offer_ids: Array = _offer_ids(draft.draw_three(state))

	_assert.that(not offer_ids.has(UpgradeManifestScript.UPGRADE_RARITY_PLUS_1), "draft: capped rarity upgrade should not be offered")
	_assert.that(not offer_ids.has(UpgradeManifestScript.UPGRADE_MIRROR_NEXT_CHOICE), "draft: armed mirror should not be offered")
	_assert.eq(offer_ids.size(), 3, "draft: eligibility filters should still leave three choices")


func _offer_ids(offer: Array) -> Array:
	var result: Array = []
	for raw_definition in offer:
		if raw_definition is Dictionary:
			result.append(str((raw_definition as Dictionary).get("id", "")))
	return result
