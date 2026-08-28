extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const ResolverScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeResolver.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

const REPEAT_COUNT: int = 7

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontNoDeckInflationTest] Starting P0-09B5 identity tests")
	await process_frame

	_test_formal_identity_sets_are_unique()
	_test_repeated_selection_keeps_one_identity()
	_test_detached_views_cannot_inflate_registries()

	_assert.report("[CardfrontNoDeckInflationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_formal_identity_sets_are_unique() -> void:
	var manifest_ids: Array = ManifestScript.get_all_upgrade_ids()
	_assert.eq(_unique_count(manifest_ids), manifest_ids.size(), "manifest: every authored upgrade has one stable ID")
	for deck_id in DeckRegistryScript.get_deck_ids():
		var deck_ids: Array = DeckRegistryScript.get_upgrade_ids(str(deck_id))
		_assert.eq(_unique_count(deck_ids), deck_ids.size(), "deck %s: no duplicate upgrade IDs" % str(deck_id))
		for upgrade_id in deck_ids:
			_assert.that(ManifestScript.has_upgrade(str(upgrade_id)), "deck %s: %s resolves to one Manifest identity" % [str(deck_id), str(upgrade_id)])


func _test_repeated_selection_keeps_one_identity() -> void:
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var resolver = ResolverScript.new()
	var draft = DraftSystemScript.new()
	var upgrade_id: String = ManifestScript.UPGRADE_VOLLEY_PLUS_5
	var manifest_ids_before: Array = ManifestScript.get_all_upgrade_ids()
	var deck_ids_before: Array = DeckRegistryScript.get_upgrade_ids(state.deck_id)
	var eligible_occurrences_before: int = _eligible_occurrences(draft, deck_ids_before, state, upgrade_id)

	for selection_index in range(REPEAT_COUNT):
		var result: Dictionary = resolver.resolve(state, upgrade_id)
		_assert.that(bool(result.get("success", false)), "repeat %d: stable upgrade resolves" % (selection_index + 1))

	_assert.eq(state.get_selected_upgrade_level(upgrade_id), REPEAT_COUNT, "selection: one ID reaches Level N")
	_assert.eq(state.selected_upgrade_levels.size(), 1, "selection: repeated choice creates one level-map identity")
	_assert.eq(state.get_effect_application_count(upgrade_id), REPEAT_COUNT, "history: effect count records applications without creating cards")
	_assert.eq(state.applied_upgrade_counts.size(), 1, "history: repeated applications retain one history-map identity")
	_assert.eq(ManifestScript.get_all_upgrade_ids(), manifest_ids_before, "manifest: definition ID set is stable after repeated resolve")
	_assert.eq(DeckRegistryScript.get_upgrade_ids(state.deck_id), deck_ids_before, "deck: ID set is stable after repeated resolve")
	_assert.eq(_eligible_occurrences(draft, deck_ids_before, state, upgrade_id), eligible_occurrences_before, "eligibility: repeatable ID remains exactly one candidate identity")


func _test_detached_views_cannot_inflate_registries() -> void:
	var manifest_count_before: int = ManifestScript.get_all_upgrade_ids().size()
	var deck_id: String = DeckRegistryScript.DEFAULT_DECK_ID
	var deck_ids_before: Array = DeckRegistryScript.get_upgrade_ids(deck_id)
	var definition: Dictionary = ManifestScript.get_definition(ManifestScript.UPGRADE_VOLLEY_PLUS_5)
	definition["id"] = "runtime_duplicate"
	deck_ids_before.append("runtime_duplicate")

	_assert.eq(ManifestScript.get_all_upgrade_ids().size(), manifest_count_before, "detached definition: runtime mutation cannot add a Manifest identity")
	_assert.that(not ManifestScript.has_upgrade("runtime_duplicate"), "detached definition: invented runtime ID is not registered")
	_assert.eq(DeckRegistryScript.get_upgrade_ids(deck_id).size(), deck_ids_before.size() - 1, "detached deck IDs: caller mutation cannot inflate the registry")


func _eligible_occurrences(draft, deck_ids: Array, state, target_id: String) -> int:
	var count: int = 0
	for upgrade_id in deck_ids:
		if str(upgrade_id) != target_id:
			continue
		if draft.is_upgrade_eligible(ManifestScript.get_definition(str(upgrade_id)), state):
			count += 1
	return count


func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value in values:
		unique[str(value)] = true
	return unique.size()
