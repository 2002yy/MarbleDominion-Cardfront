extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const AiPolicyScript = preload("res://scripts/cardfront/run/CardfrontAiUpgradePolicy.gd")
const ValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")
const SharedSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontSharedAiBalanceMatchSimulator.gd")
const SimulationConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontUpgradeValuePolicyTest] Starting shared marginal-value AI tests")
	await process_frame

	_test_hero_volley_margins()
	_test_existing_multiplier_and_caps_reduce_value()
	_test_repair_uses_actual_distinct_cells()
	_test_armor_pierce_requires_enemy_defense()
	_test_rarity_is_early_value()
	_test_echo_contract()
	_test_object_and_dictionary_states_match()
	_test_historical_mode_is_frozen()
	_test_shared_simulator_switches_valuation_modes()
	await _test_live_director_emits_marginal_report()

	GameConfig.reset_runtime_defaults()
	paused = false
	_assert.report("[CardfrontUpgradeValuePolicyTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_hero_volley_margins() -> void:
	var policy = AiPolicyScript.new()
	var offer: Array = [
		UpgradeManifestScript.UPGRADE_VOLLEY_X2,
		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5,
	]
	var engineer = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	var gunner = _hero_state(HeroRegistryScript.HERO_RAPID_GUNNER)
	var context: Dictionary = _base_context()

	var engineer_plus: Dictionary = policy.evaluate_id(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, engineer, context)
	var engineer_x2: Dictionary = policy.evaluate_id(UpgradeManifestScript.UPGRADE_VOLLEY_X2, engineer, context)
	var gunner_plus: Dictionary = policy.evaluate_id(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, gunner, context)
	var gunner_x2: Dictionary = policy.evaluate_id(UpgradeManifestScript.UPGRADE_VOLLEY_X2, gunner, context)

	_assert.eq(int(engineer_plus.get("actual_added_shots", -1)), 5, "marginal volley: Engineer +5 should add five real shots")
	_assert.eq(int(engineer_x2.get("actual_added_shots", -1)), 5, "marginal volley: Engineer x2 should add five real shots")
	_assert.eq(policy.choose_id(offer, engineer, context), UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, "marginal volley: equal Engineer gains should prefer reliable +5")
	_assert.eq(int(gunner_plus.get("actual_added_shots", -1)), 5, "marginal volley: Gunner +5 should add five real shots")
	_assert.eq(int(gunner_x2.get("actual_added_shots", -1)), 7, "marginal volley: Gunner x2 should add seven real shots")
	_assert.eq(policy.choose_id(offer, gunner, context), UpgradeManifestScript.UPGRADE_VOLLEY_X2, "marginal volley: Gunner should prefer the larger real x2 gain")


func _test_existing_multiplier_and_caps_reduce_value() -> void:
	var policy = AiPolicyScript.new()
	var state = _hero_state(HeroRegistryScript.HERO_RAPID_GUNNER)
	state.next_volley_multiplier = 2
	var x2_result: Dictionary = policy.evaluate_id(UpgradeManifestScript.UPGRADE_VOLLEY_X2, state, _base_context())
	var plus_result: Dictionary = policy.evaluate_id(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, state, _base_context())
	_assert.eq(int(x2_result.get("actual_added_shots", -1)), 0, "marginal cap: repeated x2 should add no shots")
	_assert.gt(int(plus_result.get("actual_added_shots", 0)), 0, "marginal cap: +5 should still add shots when x2 is already armed")
	_assert.gt(float(plus_result.get("score", 0.0)), float(x2_result.get("score", 0.0)), "marginal cap: useful additive shots should beat a wasted multiplier")

	var capped = _hero_state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	capped.base_volley_count = 22
	var capped_result: Dictionary = policy.evaluate_id(UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, capped, _base_context())
	_assert.eq(int(capped_result.get("actual_added_shots", -1)), 2, "marginal cap: +5 near the limit should report only two real shots")
	_assert.eq(int(capped_result.get("wasted_shots", -1)), 3, "marginal cap: +5 near the limit should report three wasted shots")


func _test_repair_uses_actual_distinct_cells() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	var empty_context: Dictionary = _base_context()
	empty_context["repairable_frontline_cells"] = 0
	var two_context: Dictionary = _base_context()
	two_context["repairable_frontline_cells"] = 2
	var six_context: Dictionary = _base_context()
	six_context["repairable_frontline_cells"] = 6
	var empty_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR, state, empty_context)
	var two_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR, state, two_context)
	var six_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR, state, six_context)
	_assert.eq(int(empty_result.get("actual_repair_cells", -1)), 0, "marginal repair: no eligible cells should produce zero repair value")
	_assert.eq(int(two_result.get("actual_repair_cells", -1)), 2, "marginal repair: two eligible cells should produce two real repairs")
	_assert.eq(int(two_result.get("wasted_repair_points", -1)), 4, "marginal repair: unused repair points should be reported")
	_assert.eq(int(six_result.get("actual_repair_cells", -1)), 6, "marginal repair: six eligible cells should consume the full card")
	_assert.gt(float(six_result.get("score", 0.0)), float(two_result.get("score", 0.0)), "marginal repair: six real cells should be worth more than two")


func _test_armor_pierce_requires_enemy_defense() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var empty_context: Dictionary = _base_context()
	empty_context["enemy_defense_points"] = 0
	empty_context["enemy_defense_contact_chance"] = 0.5
	var defended_context: Dictionary = _base_context()
	defended_context["enemy_defense_points"] = 12
	defended_context["enemy_defense_contact_chance"] = 0.5
	var empty_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_ARMOR_PIERCING, state, empty_context)
	var defended_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_ARMOR_PIERCING, state, defended_context)
	_assert.eq(float(empty_result.get("expected_pierced_contacts", -1.0)), 0.0, "marginal AP: no enemy defense should produce zero contacts")
	_assert.gt(float(defended_result.get("expected_pierced_contacts", 0.0)), 0.0, "marginal AP: defended routes should produce real expected contacts")
	_assert.gt(float(defended_result.get("score", 0.0)), float(empty_result.get("score", 0.0)), "marginal AP: defended routes should raise AP value")


func _test_rarity_is_early_value() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var early: Dictionary = _base_context()
	early["rounds_remaining"] = 18
	var late: Dictionary = _base_context()
	late["rounds_remaining"] = 1
	var early_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_RARITY_PLUS_1, state, early)
	var late_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_RARITY_PLUS_1, state, late)
	_assert.gt(float(early_result.get("score", 0.0)), float(late_result.get("score", 0.0)), "marginal rarity: early future offers should be worth more than the final draft")
	_assert.eq(int(late_result.get("future_drafts", -1)), 0, "marginal rarity: final draft should have no future-draft value")


func _test_echo_contract() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_BALANCED_COMMANDER)
	var echo_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE, state, _base_context())
	_assert.gt(float(echo_result.get("echo_replay_value", 0.0)), 0.0, "marginal echo: an unarmed Echo should estimate a discounted future replay")
	state.echo_next_choice_armed = true
	var armed_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE, state, _base_context())
	_assert.that(not bool(armed_result.get("eligible", true)), "marginal echo: already armed Echo should be ineligible")


func _test_object_and_dictionary_states_match() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_RAPID_GUNNER)
	state.attack_level = 1
	state.next_volley_bonus = 3
	var snapshot: Dictionary = state.snapshot()
	var context: Dictionary = _base_context()
	var object_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_VOLLEY_X2, state, context)
	var dictionary_result: Dictionary = ValuePolicyScript.evaluate(UpgradeManifestScript.UPGRADE_VOLLEY_X2, snapshot, context)
	_assert.eq(float(object_result.get("score", -1.0)), float(dictionary_result.get("score", -2.0)), "shared policy: live object and simulator dictionary should receive the same score")
	_assert.eq(int(object_result.get("actual_added_shots", -1)), int(dictionary_result.get("actual_added_shots", -2)), "shared policy: both state adapters should report the same real shot gain")


func _test_historical_mode_is_frozen() -> void:
	var state = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER)
	var result: Dictionary = ValuePolicyScript.evaluate(
		UpgradeManifestScript.UPGRADE_VOLLEY_X2,
		state,
		{},
		ValuePolicyScript.MODE_HISTORICAL_FIXED
	)
	_assert.eq(float(result.get("score", 0.0)), 92.0, "historical policy: x2 score should remain exactly 92 for audit reproduction")
	_assert.eq(str(result.get("valuation_mode", "")), ValuePolicyScript.MODE_HISTORICAL_FIXED, "historical policy: report should disclose the frozen valuation mode")


func _test_shared_simulator_switches_valuation_modes() -> void:
	var simulator = SharedSimulatorScript.new()
	var state: Dictionary = _hero_state(HeroRegistryScript.HERO_FORTIFICATION_ENGINEER).snapshot()
	var offer: Array = [
		UpgradeManifestScript.UPGRADE_VOLLEY_X2,
		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5,
	]
	var historical_choice: String = str(simulator.call(
		"choose_upgrade_id_for_test",
		offer,
		state,
		_base_context(),
		SimulationConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
	))
	var marginal_choice: String = str(simulator.call(
		"choose_upgrade_id_for_test",
		offer,
		state,
		_base_context(),
		SimulationConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	))
	_assert.eq(historical_choice, UpgradeManifestScript.UPGRADE_VOLLEY_X2, "shared simulator: historical mode should preserve fixed x2 priority")
	_assert.eq(marginal_choice, UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, "shared simulator: parity mode should use the same Engineer marginal choice as live AI")
	var result: Dictionary = simulator.call(
		"simulate",
		HeroRegistryScript.HERO_BALANCED_COMMANDER,
		HeroRegistryScript.HERO_RAPID_GUNNER,
		"default_duel",
		0,
		19,
		SimulationConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	) as Dictionary
	_assert.eq(str(result.get("upgrade_valuation_mode", "")), ValuePolicyScript.MODE_MARGINAL, "shared simulator: parity match output should disclose marginal valuation")


func _test_live_director_emits_marginal_report() -> void:
	GameConfig.reset_runtime_defaults()
	paused = false
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	main.selected_game_mode_name = GameConfig.GAME_MODE_CARDFRONT
	main.selected_grid_size = 20
	main.selected_cardfront_ai_hero_id = HeroRegistryScript.HERO_RAPID_GUNNER
	main._start_game(20, true, false)
	await _flush()
	var director = main.runtime.round_director
	director.set_seed_for_tests(411)
	director.force_open_draft_for_test()
	var report: Array = director.get_last_ai_value_report()
	_assert.that(not report.is_empty(), "live AI: opening draft should expose ranked marginal evaluations")
	for raw_entry in report:
		var entry: Dictionary = raw_entry as Dictionary
		_assert.eq(str(entry.get("valuation_mode", "")), ValuePolicyScript.MODE_MARGINAL, "live AI: every ranked card should disclose marginal valuation")
		_assert.that(entry.has("score"), "live AI: every ranked card should expose its score")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await _flush()


func _hero_state(hero_id: String):
	var state = RunStateScript.new()
	state.setup_from_hero(RulesScript.PLAYER_FACTION, hero_id)
	return state


func _base_context() -> Dictionary:
	return {
		"round_number": 1,
		"rounds_remaining": 18,
		"estimated_chamber_hit_chance": 0.17,
		"enemy_defense_contact_chance": 0.20,
		"enemy_defense_points": 12,
		"repairable_frontline_cells": 4,
		"owned_cell_count": 18,
		"defended_cell_count": 12,
		"own_health_ratio": 1.0,
		"enemy_health_ratio": 1.0,
		"route_pressure": 1.0,
		"future_offer_size": 3,
	}


func _flush() -> void:
	await process_frame
	await process_frame
