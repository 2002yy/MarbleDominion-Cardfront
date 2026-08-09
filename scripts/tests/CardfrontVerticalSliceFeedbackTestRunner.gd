extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontVerticalSliceFeedbackTest] Starting vertical-slice feedback tests")
	await process_frame

	await _test_chamber_tuning_and_hit_feedback()
	await _test_upgrade_application_feedback()
	GameConfig.reset_runtime_defaults()
	paused = false

	_assert.report("[CardfrontVerticalSliceFeedbackTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_chamber_tuning_and_hit_feedback() -> void:
	var main = await _start_main()
	var player_turret = main.runtime.turrets.get(RulesScript.PLAYER_FACTION, null)
	var ai_turret = main.runtime.turrets.get(RulesScript.AI_FACTION, null)
	var player_chamber = main.runtime.command_chambers.get(RulesScript.PLAYER_FACTION, null)

	_assert.that(player_turret != null and ai_turret != null, "chamber: both duel turrets should exist")
	_assert.eq(int(player_turret.max_health), TuningScript.COMMAND_CHAMBER_HEALTH, "chamber: player health should use live tuning")
	_assert.eq(int(ai_turret.max_health), TuningScript.COMMAND_CHAMBER_HEALTH, "chamber: AI health should use live tuning")
	_assert.eq(int(player_turret.health), TuningScript.COMMAND_CHAMBER_HEALTH, "chamber: player should start at full health")
	_assert.that(player_chamber != null and is_instance_valid(player_chamber), "chamber: player chamber view should exist")

	player_turret.take_damage(3)
	await process_frame
	_assert.eq(int(player_turret.health), TuningScript.COMMAND_CHAMBER_HEALTH - 3, "feedback: damage should reduce chamber health")
	_assert.that(player_chamber.is_hit_feedback_active_for_test(), "feedback: chamber damage should activate hit feedback")
	_assert.eq(player_chamber.get_last_damage_for_test(), 3, "feedback: floating damage should show the applied amount")

	player_chamber._process(player_chamber.HIT_FEEDBACK_SECONDS + 0.1)
	_assert.that(not player_chamber.is_hit_feedback_active_for_test(), "feedback: chamber hit feedback should expire")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _test_upgrade_application_feedback() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	var panel = main.runtime.three_choice_panel

	_assert.eq(
		int(director.FIRST_DRAFT_COUNTDOWN),
		int(TuningScript.FIRST_AIM_SECONDS),
		"cadence: first aim should use tuned duration"
	)
	_assert.between(
		director.phase_controller.time_remaining,
		0.01,
		TuningScript.FIRST_AIM_SECONDS,
		"cadence: the live first-aim countdown should start inside the tuned window"
	)
	_assert.eq(
		int(director.phase_controller.battle_interval),
		int(TuningScript.AIM_SECONDS),
		"cadence: later aim phases should use tuned duration"
	)
	_assert.eq(
		int(director.get_run_state(RulesScript.PLAYER_FACTION).base_volley_count),
		TuningScript.BASE_VOLLEY_COUNT,
		"cadence: base volley should use tuned projectile count"
	)

	director.force_open_draft_for_test()
	_assert.that(panel.choose_index_for_test(0), "feedback: player should select a visible upgrade")
	director.complete_reveal_for_test()
	_assert.that(panel.is_upgrade_toast_visible_for_test(), "feedback: volley launch should show applied upgrade")
	_assert.that(
		panel.get_upgrade_toast_text_for_test().contains("强化生效"),
		"feedback: applied-upgrade toast should use explicit action copy"
	)

	panel._process(TuningScript.UPGRADE_FEEDBACK_SECONDS + 0.1)
	_assert.that(not panel.is_upgrade_toast_visible_for_test(), "feedback: applied-upgrade toast should expire")

	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _start_main():
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	# Main loads persisted menu preferences during _ready(). Pin the baseline hero so
	# this regression test cannot inherit a developer's last local hero selection.
	main.selected_cardfront_player_hero_id = HeroRegistryScript.DEFAULT_PLAYER_HERO_ID
	main.selected_cardfront_ai_hero_id = HeroRegistryScript.DEFAULT_AI_HERO_ID
	main._start_game(20, true, false)
	await _flush()
	return main


func _flush() -> void:
	await process_frame
	await process_frame
