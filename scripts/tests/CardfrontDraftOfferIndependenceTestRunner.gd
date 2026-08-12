extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const OfferContextScript = preload("res://scripts/cardfront/draft/CardfrontDraftOfferContext.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontDraftOfferIndependenceTest] Starting P0-08B1-B3 Offer tests")
	await process_frame

	_test_context_envelope()
	_test_context_and_legacy_api_parity()
	_test_offer_containers_are_deeply_independent()
	_test_round_director_getters_return_deep_copies()
	_test_coincidental_overlap_remains_allowed()

	GameConfig.reset_runtime_defaults()
	paused = false
	_assert.report("[CardfrontDraftOfferIndependenceTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_context_envelope() -> void:
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	state.deck_id = DeckRegistryScript.DECK_BARRAGE_CONTROL
	var context = OfferContextScript.create(RulesScript.PLAYER_FACTION, state)
	_assert.eq(context.owner_id, RulesScript.PLAYER_FACTION, "context: owner identity is explicit")
	_assert.that(context.run_state == state, "context: existing run-state read model is retained")
	_assert.eq(context.deck_id, DeckRegistryScript.DECK_BARRAGE_CONTROL, "context: deck resolves from run state")
	_assert.eq(context.snapshot(), {"owner_id": RulesScript.PLAYER_FACTION, "deck_id": DeckRegistryScript.DECK_BARRAGE_CONTROL}, "context: public snapshot exposes only owner and deck")
	for forbidden_key in ["route", "profession", "behavior", "reroll"]:
		_assert.that(not context.snapshot().has(forbidden_key), "context: P1 field stays absent: %s" % forbidden_key)


func _test_context_and_legacy_api_parity() -> void:
	var state = RunStateScript.new()
	state.setup(RulesScript.PLAYER_FACTION)
	var legacy = DraftSystemScript.new()
	var contextual = DraftSystemScript.new()
	legacy.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, 8101)
	contextual.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, 8101)
	var legacy_ids: Array = _ids(legacy.draw_offer(state, 3, RulesScript.PLAYER_FACTION))
	var context = OfferContextScript.create(RulesScript.PLAYER_FACTION, state)
	var context_ids: Array = _ids(contextual.draw_offer_for_context(context, 3))
	_assert.eq(context_ids, legacy_ids, "context: migration preserves draw semantics")


func _test_offer_containers_are_deeply_independent() -> void:
	var draft = DraftSystemScript.new()
	draft.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, 77)
	draft.set_side_seed_for_tests(RulesScript.AI_FACTION, 77)
	var player_context = OfferContextScript.create(RulesScript.PLAYER_FACTION)
	var ai_context = OfferContextScript.create(RulesScript.AI_FACTION)
	var player_offer: Array = draft.draw_offer_for_context(player_context, 3)
	var ai_offer: Array = draft.draw_offer_for_context(ai_context, 3)
	_assert.eq(_ids(player_offer), _ids(ai_offer), "containers: same side seeds may produce coincidental overlap")
	_assert.that(not is_same(player_offer, ai_offer), "containers: Player and AI arrays are distinct objects")
	var original_ai_name: String = str((ai_offer[0] as Dictionary).get("name", ""))
	var original_ai_params: Dictionary = ((ai_offer[0] as Dictionary).get("params", {}) as Dictionary).duplicate(true)
	(player_offer[0] as Dictionary)["name"] = "mutated player view"
	(player_offer[0] as Dictionary)["params"] = {"mutated": true}
	player_offer.append({"id": "player_only"})
	_assert.eq(ai_offer.size(), 3, "containers: Player array mutation does not change AI array")
	_assert.eq(str((ai_offer[0] as Dictionary).get("name", "")), original_ai_name, "containers: Player definition mutation does not change AI definition")
	_assert.eq((ai_offer[0] as Dictionary).get("params", {}), original_ai_params, "containers: nested Player mutation does not change AI definition")
	var manifest_definition: Dictionary = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd").get_definition(str((ai_offer[0] as Dictionary).get("id", "")))
	_assert.eq(str(manifest_definition.get("name", "")), original_ai_name, "containers: view mutation does not change manifest authority")


func _test_round_director_getters_return_deep_copies() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	director.set_seed_for_tests(8112)
	director.force_open_draft_for_test()
	await process_frame
	var first_player: Array = director.get_player_offer()
	var first_ai: Array = director.get_ai_offer()
	var expected_player_ids: Array = _ids(first_player)
	var expected_ai_ids: Array = _ids(first_ai)
	(first_player[0] as Dictionary)["name"] = "external mutation"
	first_player.clear()
	(first_ai[0] as Dictionary)["params"] = {"external": true}
	first_ai.append({"id": "external"})
	_assert.eq(_ids(director.get_player_offer()), expected_player_ids, "getters: Player getter does not expose authoritative array")
	_assert.eq(_ids(director.get_ai_offer()), expected_ai_ids, "getters: AI getter does not expose authoritative array")
	_assert.neq(str((director.get_player_offer()[0] as Dictionary).get("name", "")), "external mutation", "getters: Player definitions are deep copied")
	_assert.that(not ((director.get_ai_offer()[0] as Dictionary).get("params", {}) as Dictionary).has("external"), "getters: AI nested definitions are deep copied")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_coincidental_overlap_remains_allowed() -> void:
	var draft = DraftSystemScript.new()
	draft.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, 8200)
	draft.set_side_seed_for_tests(RulesScript.AI_FACTION, 8200)
	var player_ids: Array = draft.draw_offer_ids_for_context(OfferContextScript.create(RulesScript.PLAYER_FACTION), 3)
	var ai_ids: Array = draft.draw_offer_ids_for_context(OfferContextScript.create(RulesScript.AI_FACTION), 3)
	_assert.eq(player_ids, ai_ids, "overlap: identical independent seeds may produce identical offers")
	_assert.eq(player_ids.size(), 3, "overlap: coincidental equality does not change offer size")


func _ids(offer: Array) -> Array:
	var result: Array = []
	for definition in offer:
		result.append(str((definition as Dictionary).get("id", "")))
	return result


func _start_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
