extends SceneTree

const CardfrontModeScript = preload("res://scripts/cardfront/CardfrontMode.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontBattlefieldInitializerScript = preload("res://scripts/cardfront/CardfrontBattlefieldInitializer.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontModeSmokeTest] Starting Cardfront prototype smoke tests")
	await process_frame

	_test_game_mode_registration()
	_test_active_factions()
	_test_battlefield_duel_reset()
	_test_cardfront_win_conditions()
	await _test_main_enters_cardfront_mode()
	await _flush()

	_assert.report("[CardfrontModeSmokeTest]")
	if _assert.failures.is_empty():
		quit(0)
	else:
		quit(1)


func _flush() -> void:
	await process_frame
	await process_frame


func _test_game_mode_registration() -> void:
	var modes: Array = GameConfig.get_game_mode_names()
	_assert.that(GameConfig.GAME_MODE_CARDFRONT in modes, "mode registration: Cardfront mode should be listed")
	GameConfig.set_game_mode_by_name("cardfront")
	_assert.eq(GameConfig.get_game_mode_name(), GameConfig.GAME_MODE_CARDFRONT, "mode registration: ascii alias should select Cardfront")
	_assert.eq(GameConfig.get_gate_multiplier(), 2, "mode registration: Cardfront keeps regular x2 gate multiplier for now")
	GameConfig.reset_runtime_defaults()


func _test_active_factions() -> void:
	var active: Array = CardfrontModeScript.get_active_factions()
	_assert.eq(active.size(), 2, "active factions: Cardfront starts as player vs AI")
	_assert.eq(active[0], GameConfig.Faction.BLUE, "active factions: player is BLUE")
	_assert.eq(active[1], GameConfig.Faction.RED, "active factions: AI is RED")


func _test_battlefield_duel_reset() -> void:
	var bf := Battlefield.new()
	bf.configure(40)
	get_root().add_child(bf)
	_assert.that(not bf.has_method("reset_cardfront_duel"), "battlefield architecture: Battlefield should not expose Cardfront reset")
	var setup: Dictionary = CardfrontModeScript.configure_battlefield(bf)
	_assert.that(bool(setup.get("configured", false)), "battlefield reset: CardfrontMode should configure Battlefield")
	_assert.eq(int(setup.get("spawn_columns", 0)), CardfrontBattlefieldInitializerScript.get_spawn_columns(40), "battlefield reset: initializer should report spawn width")

	var counts: Dictionary = bf.count_cells_by_team()
	var total: int = int(counts.get(CardfrontRulesScript.PLAYER_FACTION, 0)) \
		+ int(counts.get(CardfrontRulesScript.AI_FACTION, 0)) \
		+ int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0))
	_assert.eq(total, 1600, "battlefield reset: 40x40 should account for all cells")
	_assert.gt(int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)), 0, "battlefield reset: neutral center should exist")
	_assert.gt(int(counts.get(CardfrontRulesScript.PLAYER_FACTION, 0)), 0, "battlefield reset: player spawn should exist")
	_assert.gt(int(counts.get(CardfrontRulesScript.AI_FACTION, 0)), 0, "battlefield reset: AI spawn should exist")
	_assert.eq(bf.owners[0][0], CardfrontRulesScript.PLAYER_FACTION, "battlefield reset: left edge belongs to player")
	_assert.eq(bf.owners[39][0], CardfrontRulesScript.AI_FACTION, "battlefield reset: right edge belongs to AI")
	_assert.eq(bf.owners[20][20], CardfrontRulesScript.NEUTRAL_OWNER, "battlefield reset: center starts neutral")
	_assert.eq(CardfrontBattlefieldInitializerScript.duel_owner_for_cell(20, 20, 40), CardfrontRulesScript.NEUTRAL_OWNER, "battlefield reset: initializer owns neutral cell rule")

	var before_neutral: int = int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0))
	var result: String = bf.apply_bullet(Vector2i(20, 20), CardfrontRulesScript.PLAYER_FACTION)
	var after: Dictionary = bf.count_cells_by_team()
	_assert.eq(result, "HIT_ENEMY_CELL", "battlefield capture: player bullet should claim neutral cell")
	_assert.eq(int(after.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)), before_neutral - 1, "battlefield capture: neutral count should decrease")
	TestFixtures.cleanup_node(bf)


func _test_cardfront_win_conditions() -> void:
	var target_counts := {
		CardfrontRulesScript.PLAYER_FACTION: 1120,
		CardfrontRulesScript.AI_FACTION: 100,
		CardfrontRulesScript.NEUTRAL_OWNER: 380,
	}
	var target_result: Dictionary = WinConditionEvaluator.evaluate_cardfront(target_counts, 1600, false)
	_assert.that(bool(target_result.get("ended", false)), "win: 70% player capture should end before timer")
	_assert.eq(int(target_result.get("winner", -1)), CardfrontRulesScript.PLAYER_FACTION, "win: player wins by capture target")

	var ongoing_counts := {
		CardfrontRulesScript.PLAYER_FACTION: 600,
		CardfrontRulesScript.AI_FACTION: 700,
		CardfrontRulesScript.NEUTRAL_OWNER: 300,
	}
	var ongoing_result: Dictionary = WinConditionEvaluator.evaluate_cardfront(ongoing_counts, 1600, false)
	_assert.eq(bool(ongoing_result.get("ended", true)), false, "win: below target before timer should continue")

	var timed_result: Dictionary = WinConditionEvaluator.evaluate_cardfront(ongoing_counts, 1600, true)
	_assert.that(bool(timed_result.get("ended", false)), "win: timer expiry should end Cardfront match")
	_assert.eq(int(timed_result.get("winner", -1)), CardfrontRulesScript.AI_FACTION, "win: AI leads on timer expiry")

	var draw_counts := {
		CardfrontRulesScript.PLAYER_FACTION: 500,
		CardfrontRulesScript.AI_FACTION: 500,
		CardfrontRulesScript.NEUTRAL_OWNER: 600,
	}
	var draw_result: Dictionary = WinConditionEvaluator.evaluate_cardfront(draw_counts, 1600, true)
	_assert.that(bool(draw_result.get("draw", false)), "win: equal player/AI count at timer should draw")


func _test_main_enters_cardfront_mode() -> void:
	GameConfig.reset_runtime_defaults()
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 40
	main._start_game(40, true, false)
	await process_frame

	_assert.that(main.runtime.battlefield != null and is_instance_valid(main.runtime.battlefield), "main entry: Cardfront should create a battlefield")
	_assert.eq(main.runtime.turrets.size(), 2, "main entry: Cardfront should create two turrets")
	_assert.that(main.runtime.turrets.has(CardfrontRulesScript.PLAYER_FACTION), "main entry: player turret should exist")
	_assert.that(main.runtime.turrets.has(CardfrontRulesScript.AI_FACTION), "main entry: AI turret should exist")
	_assert.eq(main.runtime.chambers.size(), 2, "main entry: Cardfront should create two control chambers")
	_assert.eq(main.runtime.event_controller, null, "main entry: Cardfront should skip EventRouletteController")
	_assert.that(main.runtime.target_bias_system != null and is_instance_valid(main.runtime.target_bias_system), "main entry: Cardfront should create target bias system")
	_assert.that(main.runtime.card_system != null, "main entry: Cardfront should create card play system")
	_assert.eq(main.runtime.card_system.target_bias_system, main.runtime.target_bias_system, "main entry: card play system should receive target bias system")
	_assert.that(main.runtime.fire_director != null and is_instance_valid(main.runtime.fire_director), "main entry: Cardfront should create fire director")

	var counts: Dictionary = main.runtime.battlefield.count_cells_by_team()
	_assert.gt(int(counts.get(CardfrontRulesScript.NEUTRAL_OWNER, 0)), 0, "main entry: Cardfront battlefield should retain neutral territory")

	TestFixtures.cleanup_node(main)
	await _flush()
	GameConfig.reset_runtime_defaults()
