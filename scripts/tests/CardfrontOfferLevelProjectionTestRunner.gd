extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const OfferContextScript = preload("res://scripts/cardfront/draft/CardfrontDraftOfferContext.gd")
const OfferViewScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeOfferView.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontOfferLevelProjectionTest] Starting P0-09B3 projection tests")
	await process_frame

	_test_projection_reads_selected_level_only()
	_test_projection_never_mutates_manifest()
	_test_side_offers_project_independent_levels()
	_test_timeout_fallback_retains_view_data()
	await _test_runtime_panel_receives_projection()

	GameConfig.reset_runtime_defaults()
	paused = false
	_assert.report("[CardfrontOfferLevelProjectionTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_projection_reads_selected_level_only() -> void:
	var state = _state(RulesScript.PLAYER_FACTION)
	var upgrade_id: String = ManifestScript.UPGRADE_VOLLEY_PLUS_5
	state.selected_upgrade_levels[upgrade_id] = 2
	state.applied_upgrade_counts[upgrade_id] = 9
	var definition: Dictionary = ManifestScript.get_definition(upgrade_id)
	var view: Dictionary = OfferViewScript.project(definition, state)
	_assert.eq(int(view.get("current_level", -1)), 2, "projection: current Level comes from Selected Level authority")
	_assert.eq(int(view.get("next_level", -1)), 3, "projection: next Level is the next successful selection")
	state.selected_upgrade_levels.clear()
	_assert.eq(int(OfferViewScript.project(definition, state).get("current_level", -1)), 0, "projection: application history cannot impersonate Selected Level")
	_assert.eq(int(OfferViewScript.project(definition, null).get("next_level", -1)), 1, "projection: missing run state safely describes a first selection")
	_assert.eq(OfferViewScript.project({}, state), {}, "projection: empty definitions fail safely")


func _test_projection_never_mutates_manifest() -> void:
	var upgrade_id: String = ManifestScript.UPGRADE_VOLLEY_X2
	var before: Dictionary = ManifestScript.get_definition(upgrade_id)
	var view: Dictionary = OfferViewScript.project(before, _state(RulesScript.PLAYER_FACTION))
	(view.get("params", {}) as Dictionary)["external"] = true
	view["name"] = "view-only mutation"
	var after: Dictionary = ManifestScript.get_definition(upgrade_id)
	_assert.that(not after.has("current_level") and not after.has("next_level"), "manifest: runtime Level fields never enter static definitions")
	_assert.neq(str(after.get("name", "")), "view-only mutation", "manifest: projected top-level mutation is detached")
	_assert.that(not (after.get("params", {}) as Dictionary).has("external"), "manifest: projected nested mutation is detached")


func _test_side_offers_project_independent_levels() -> void:
	var player = _state(RulesScript.PLAYER_FACTION)
	var ai = _state(RulesScript.AI_FACTION)
	for upgrade_id in ManifestScript.get_upgrade_ids():
		player.selected_upgrade_levels[str(upgrade_id)] = 2
		ai.selected_upgrade_levels[str(upgrade_id)] = 5
	var draft = DraftSystemScript.new()
	draft.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, 9031)
	draft.set_side_seed_for_tests(RulesScript.AI_FACTION, 9031)
	var player_offer: Array = draft.draw_offer_for_context(OfferContextScript.create(RulesScript.PLAYER_FACTION, player), 3)
	var ai_offer: Array = draft.draw_offer_for_context(OfferContextScript.create(RulesScript.AI_FACTION, ai), 3)
	_assert.eq(_ids(player_offer), _ids(ai_offer), "side projection: identical isolated seeds may produce the same IDs")
	for definition in player_offer:
		_assert.eq(int((definition as Dictionary).get("current_level", -1)), 2, "side projection: Player offer uses Player Selected Level")
		_assert.eq(int((definition as Dictionary).get("next_level", -1)), 3, "side projection: Player next Level is local")
	for definition in ai_offer:
		_assert.eq(int((definition as Dictionary).get("current_level", -1)), 5, "side projection: AI offer uses AI Selected Level")
		_assert.eq(int((definition as Dictionary).get("next_level", -1)), 6, "side projection: AI next Level is local")


func _test_timeout_fallback_retains_view_data() -> void:
	var state = _state(RulesScript.PLAYER_FACTION)
	for upgrade_id in ManifestScript.get_upgrade_ids():
		state.selected_upgrade_levels[str(upgrade_id)] = 3
	var draft = DraftSystemScript.new()
	draft.set_side_seed_for_tests(RulesScript.PLAYER_FACTION, 9041)
	var offer: Array = draft.draw_three(state, RulesScript.PLAYER_FACTION)
	var fallback: Dictionary = draft.choose_timeout_fallback(offer, RulesScript.PLAYER_FACTION)
	_assert.that(_ids(offer).has(str(fallback.get("id", ""))), "timeout: projected fallback still belongs to the current offer")
	_assert.eq(int(fallback.get("current_level", -1)), 3, "timeout: fallback retains projected current Level")
	_assert.eq(int(fallback.get("next_level", -1)), 4, "timeout: fallback retains projected next Level")
	fallback["current_level"] = 99
	_assert.that(not _levels(offer).has(99), "timeout: fallback mutation cannot rewrite the offer view")


func _test_runtime_panel_receives_projection() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var state = director.get_run_state(RulesScript.PLAYER_FACTION)
	for upgrade_id in ManifestScript.get_upgrade_ids():
		state.selected_upgrade_levels[str(upgrade_id)] = 4
	director.set_seed_for_tests(9051)
	director.force_open_draft_for_test()
	await process_frame
	var cards: Array = main.runtime.three_choice_panel.get_choice_cards()
	_assert.eq(cards.size(), 3, "runtime view: formal Draft still presents exactly three cards")
	for card in cards:
		_assert.eq(int(card.definition.get("current_level", -1)), 4, "runtime view: choice card receives projected current Level data")
		_assert.eq(int(card.definition.get("next_level", -1)), 5, "runtime view: choice card receives projected next Level data")
		_assert.that(not ManifestScript.get_definition(str(card.upgrade_id)).has("current_level"), "runtime view: panel binding leaves Manifest static")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _state(owner_id: int):
	var state = RunStateScript.new()
	state.setup(owner_id)
	return state


func _ids(offer: Array) -> Array:
	var result: Array = []
	for definition in offer:
		result.append(str((definition as Dictionary).get("id", "")))
	return result


func _levels(offer: Array) -> Array:
	var result: Array = []
	for definition in offer:
		result.append(int((definition as Dictionary).get("current_level", -1)))
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
