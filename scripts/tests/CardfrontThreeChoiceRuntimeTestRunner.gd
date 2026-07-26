extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const MatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontThreeChoiceRuntimeTest] Starting three-choice runtime tests")
	await process_frame

	await _test_player_choice_pauses_resolves_and_launches()
	await _test_strongholds_modify_draft_and_volley()
	await _test_timeout_selects_player_fallback()
	await _test_ballwar_is_isolated()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontThreeChoiceRuntimeTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_player_choice_pauses_resolves_and_launches() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT)
	var director = main.runtime.round_director
	var panel = main.runtime.three_choice_panel

	_assert.that(director != null and is_instance_valid(director), "runtime: Cardfront should create round director")
	_assert.that(panel != null and is_instance_valid(panel), "runtime: Cardfront should create formal three-choice panel")
	_assert.that(not main.runtime.fire_director.is_processing(), "runtime: legacy continuous fire director should be disabled")
	_assert.eq(main.runtime.hand_panel, null, "runtime: legacy four-card hand should not be constructed")
	_assert.eq(main.runtime.top_resource_bar, null, "runtime: legacy resource minibar should not be constructed")
	_assert.that(main.runtime.territory_defense_system != null, "runtime: live territory defense should replace legacy card fortification")
	_assert.eq(panel.get_visible_choice_count(), 0, "runtime: choice cards should stay hidden during battle countdown")

	director.set_seed_for_tests(303)
	director.force_open_draft_for_test()
	_assert.that(paused, "draft: the world should pause when three choices open")
	_assert.eq(director.get_phase(), MatchPhaseScript.DRAFT_PAUSED, "draft: phase should be paused draft")
	_assert.that(panel.draft_root.visible, "draft: formal choice overlay should be visible")
	_assert.eq(panel.get_visible_choice_count(), 3, "draft: exactly three player choices should be visible")
	_assert.that(director.phase_controller.get_selected_upgrade_id(RulesScript.AI_FACTION) != "", "draft: AI should lock a choice")
	_assert.that(not main.runtime.direction_controller.is_processing_unhandled_input(), "draft: direction hotkeys should be disabled")

	var chosen_id: String = str(panel.get_choice_cards()[0].upgrade_id)
	_assert.that(panel.choose_index_for_test(0), "draft: clicking an offered upgrade should lock it")
	_assert.eq(director.phase_controller.get_selected_upgrade_id(RulesScript.PLAYER_FACTION), chosen_id, "draft: selected player upgrade should be recorded")
	_assert.eq(director.get_phase(), MatchPhaseScript.RESOLVE_CHOICES, "draft: both choices should advance to reveal")
	_assert.that(paused, "draft: world should remain paused during reveal")
	_assert.that(not director.current_plans.is_empty(), "draft: choice resolution should build volley plans")

	var player_plan = director.current_plans.get(RulesScript.PLAYER_FACTION, null)
	var ai_plan = director.current_plans.get(RulesScript.AI_FACTION, null)
	var player_base: int = int(director.get_run_state(RulesScript.PLAYER_FACTION).base_volley_count)
	var ai_base: int = int(director.get_run_state(RulesScript.AI_FACTION).base_volley_count)
	director.complete_reveal_for_test()
	_assert.that(not paused, "volley: world should resume before launch")
	_assert.eq(director.get_phase(), MatchPhaseScript.BATTLE_COUNTDOWN, "volley: launch should begin the next countdown")
	_assert.that(main.runtime.direction_controller.is_processing_unhandled_input(), "volley: direction hotkeys should return")
	_assert.that(player_plan != null and int(player_plan.shot_count) >= player_base, "volley: player plan should preserve its hero base volley")
	_assert.that(ai_plan != null and int(ai_plan.shot_count) >= ai_base, "volley: AI plan should preserve its hero base volley")
	_assert.that(int(main.runtime.turrets[RulesScript.PLAYER_FACTION].burst_remaining) > 0, "volley: player turret should receive the planned burst")
	_assert.that(int(main.runtime.turrets[RulesScript.AI_FACTION].burst_remaining) > 0, "volley: AI turret should receive the planned burst")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_timeout_selects_player_fallback() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT)
	var director = main.runtime.round_director
	director.set_seed_for_tests(707)
	director.force_open_draft_for_test()
	var offered_ids: Array = []
	for definition in director.get_player_offer():
		offered_ids.append(str((definition as Dictionary).get("id", "")))

	director._process(director.phase_controller.draft_timeout)
	var selected_id: String = director.phase_controller.get_selected_upgrade_id(RulesScript.PLAYER_FACTION)
	_assert.that(selected_id != "", "timeout: player should receive an automatic choice")
	_assert.that(offered_ids.has(selected_id), "timeout: automatic choice should come from the visible offer")
	_assert.eq(director.get_phase(), MatchPhaseScript.RESOLVE_CHOICES, "timeout: fallback should advance to reveal")
	_assert.that(paused, "timeout: reveal should remain paused")

	director.complete_reveal_for_test()
	_assert.that(not paused, "timeout: automatic choice should still resume and launch")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_strongholds_modify_draft_and_volley() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_CARDFRONT)
	var director = main.runtime.round_director
	_paint_all_strongholds(main, RulesScript.PLAYER_FACTION)
	director.set_seed_for_tests(91)
	director.force_open_draft_for_test()
	await process_frame

	var player_bonus: Dictionary = director.get_stronghold_bonus(RulesScript.PLAYER_FACTION)
	_assert.eq(int(player_bonus.get("shot_count_bonus", 0)), StrongholdRulesScript.FACTORY_SHOT_BONUS, "runtime stronghold: factory should grant +3 once")
	_assert.eq(int(player_bonus.get("temporary_attack_level_bonus", 0)), StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS, "runtime stronghold: energy should grant one temporary attack level")
	_assert.eq(int(player_bonus.get("draft_choice_count", 0)), StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT, "runtime stronghold: lab should enable four choices")
	_assert.eq(director.get_player_offer().size(), 4, "runtime stronghold: lab should expose four player choices")
	_assert.eq(main.runtime.three_choice_panel.get_visible_choice_count(), 4, "runtime stronghold: formal panel should render all four choices")
	var shell_rect: Rect2 = main.runtime.three_choice_panel.choice_shell.get_global_rect()
	var previous_x: float = -INF
	for card in main.runtime.three_choice_panel.get_choice_cards():
		var card_rect: Rect2 = card.get_global_rect()
		_assert.that(shell_rect.encloses(card_rect), "runtime stronghold: every laboratory choice should remain inside the choice shell")
		_assert.gt(card_rect.position.x, previous_x, "runtime stronghold: four choices should remain horizontally ordered")
		previous_x = card_rect.position.x
	_assert.that(str(main.runtime.three_choice_panel.stronghold_label.text).contains("工厂"), "runtime stronghold: battle HUD should name active bonuses")
	_assert.that(str(main.runtime.three_choice_panel.result_label.text).contains("额外出现 1 张"), "runtime stronghold: draft should explain the fourth choice")

	_assert.that(main.runtime.three_choice_panel.choose_index_for_test(0), "runtime stronghold: player should still choose normally")
	var plan = director.current_plans.get(RulesScript.PLAYER_FACTION, null)
	_assert.that(plan != null, "runtime stronghold: resolution should build a player plan")
	if plan != null:
		_assert.eq(int(plan.stronghold_shot_bonus), StrongholdRulesScript.FACTORY_SHOT_BONUS, "runtime stronghold: plan should record +3 factory shots")
		_assert.eq(int(plan.stronghold_attack_level_bonus), StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS, "runtime stronghold: plan should record the temporary energy level")
	director.complete_reveal_for_test()

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_ballwar_is_isolated() -> void:
	var main = await _start_main(GameConfig.GAME_MODE_BASIC)
	_assert.eq(main.runtime.round_director, null, "BallWar: should not create Cardfront round director")
	_assert.eq(main.runtime.three_choice_panel, null, "BallWar: should not create Cardfront choice panel")
	_assert.eq(main.runtime.hand_panel, null, "BallWar: should not create Cardfront legacy hand")
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main(mode_name: String):
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = mode_name
	main.selected_grid_size = 20
	main._start_game(20, true, false)
	await _flush()
	return main


func _paint_all_strongholds(main, owner_id: int) -> void:
	var owners: Array = main.runtime.battlefield.owners.duplicate(true)
	for raw_region_id in main.runtime.region_map.get_controllable_region_ids():
		for raw_cell in main.runtime.region_map.get_region_cells(int(raw_region_id)):
			var cell: Vector2i = raw_cell
			owners[cell.x][cell.y] = owner_id
	main.runtime.battlefield.replace_owners(owners, false)


func _flush() -> void:
	await process_frame
	await process_frame
