extends SceneTree

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CommanderScript = preload("res://scripts/cardfront/ai/CardfrontAiCommander.gd")
const ObservationBuilderScript = preload("res://scripts/cardfront/ai/CardfrontAiObservationBuilder.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontAiCommanderObservationTest] Starting P0-10B1-B5 adapter tests")
	await process_frame
	_test_decision_strength_freeze()
	_test_secret_injection_metamorphic_contract()
	_test_public_change_sensitivity()
	_test_no_difficulty_cheat_fields()
	await _test_live_runtime_uses_observation_adapter()
	_assert.report("[CardfrontAiCommanderObservationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_decision_strength_freeze() -> void:
	var state = RunStateScript.new()
	state.setup_from_hero(RulesScript.AI_FACTION, "fortification_engineer")
	state.applied_upgrade_counts[ManifestScript.UPGRADE_FRONTLINE_REPAIR] = 1
	var offer: Array = _offer([
		ManifestScript.UPGRADE_VOLLEY_PLUS_5,
		ManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1,
		ManifestScript.UPGRADE_FRONTLINE_REPAIR,
	])
	var context: Dictionary = _public_context()
	var observation: Dictionary = ObservationBuilderScript.build(
		context,
		ObservationBuilderScript.project_own_state(state),
		[]
	)
	var legacy = CommanderScript.new()
	legacy.set_hero(state.hero_id)
	var projected = CommanderScript.new()
	projected.set_hero(state.hero_id)
	var legacy_choice: Dictionary = legacy.choose(offer, state, context)
	var projected_choice: Dictionary = projected.choose_from_observation(offer, observation)
	_assert.eq(str(projected_choice.get("id", "")), str(legacy_choice.get("id", "")), "freeze: projected adapter selects the legacy winner")
	_assert.eq(_ranked_ids(projected.get_last_ranked_evaluations()), _ranked_ids(legacy.get_last_ranked_evaluations()), "freeze: complete ranking order is preserved")
	_assert.eq(_ranked_scores(projected.get_last_ranked_evaluations()), _ranked_scores(legacy.get_last_ranked_evaluations()), "freeze: commander scores are unchanged")


func _test_secret_injection_metamorphic_contract() -> void:
	var public_source: Dictionary = _public_context()
	var own_source: Dictionary = {"deck_id": "core_tactics", "rarity_level": 1}
	var left_public: Dictionary = public_source.duplicate(true)
	left_public.merge({"player_offer": ["secret_a"], "future_offer": ["future_a"], "seed": 11})
	var right_public: Dictionary = public_source.duplicate(true)
	right_public.merge({"player_offer": ["secret_b"], "future_offer": ["future_b"], "seed": 99})
	var left_own: Dictionary = own_source.duplicate(true)
	left_own["hidden_route_tendency_score"] = 0.1
	var right_own: Dictionary = own_source.duplicate(true)
	right_own["hidden_route_tendency_score"] = 0.9
	var left: Dictionary = ObservationBuilderScript.build(left_public, left_own, [])
	var right: Dictionary = ObservationBuilderScript.build(right_public, right_own, [])
	_assert.eq(left, right, "metamorphic: Player Offer, future Offer, RNG seed and hidden route changes cannot alter Observation")


func _test_public_change_sensitivity() -> void:
	var calm_public: Dictionary = _public_context()
	calm_public["enemy_defense_points"] = 2
	calm_public["support_views"] = [{"support_id": "support_center", "owner_id": RulesScript.PLAYER_FACTION, "online": true}]
	var defended_public: Dictionary = calm_public.duplicate(true)
	defended_public["enemy_defense_points"] = 16
	defended_public["support_views"] = [{"support_id": "support_center", "owner_id": RulesScript.PLAYER_FACTION, "online": false}]
	var calm: Dictionary = ObservationBuilderScript.build(calm_public, {"deck_id": "core_tactics"}, [])
	var defended: Dictionary = ObservationBuilderScript.build(defended_public, {"deck_id": "core_tactics"}, [])
	_assert.neq(calm, defended, "sensitivity: approved public battle changes remain observable")
	_assert.neq(ObservationBuilderScript.valuation_context(calm), ObservationBuilderScript.valuation_context(defended), "sensitivity: approved public defense change reaches valuation context")


func _test_no_difficulty_cheat_fields() -> void:
	var observation: Dictionary = ObservationBuilderScript.build(
		{
			"round_number": 3,
			"ai_damage_multiplier": 2.0,
			"ai_hp_multiplier": 3.0,
			"ai_same_frame_reaction": true,
		},
		{
			"deck_id": "core_tactics",
			"ai_resource_multiplier": 2.0,
			"ai_cost_discount": 0.5,
			"ai_hidden_extra_draw": 1,
		},
		[]
	)
	var serialized: String = JSON.stringify(observation)
	for forbidden in ["ai_damage_multiplier", "ai_hp_multiplier", "ai_resource_multiplier", "ai_cost_discount", "ai_hidden_extra_draw", "ai_same_frame_reaction"]:
		_assert.that(not serialized.contains(forbidden), "difficulty: %s is not an observation capability" % forbidden)


func _test_live_runtime_uses_observation_adapter() -> void:
	var main = await _start_main()
	var director = main.runtime.round_director
	director.set_seed_for_tests(10201)
	director.force_open_draft_for_test()
	await process_frame
	var report: Array = director.get_last_ai_value_report()
	_assert.eq(director.get_ai_offer().size(), 3, "live adapter: AI still receives exactly its three-card Offer")
	_assert.eq(report.size(), 3, "live adapter: observation-driven Commander ranks the complete Offer")
	_assert.that(ObservationBuilderScript.is_pure_observation(director.get_ai_observation(RulesScript.AI_FACTION)), "live adapter: current production input is pure Observation")
	main._cleanup_game_layer()
	TestFixtures.cleanup_node(main)
	await process_frame


func _public_context() -> Dictionary:
	return {
		"round_number": 6,
		"rounds_remaining": 12,
		"estimated_chamber_hit_chance": 0.17,
		"enemy_defense_contact_chance": 0.28,
		"enemy_defense_points": 10,
		"repairable_frontline_cells": 3,
		"owned_cell_count": 18,
		"defended_cell_count": 12,
		"own_health_ratio": 0.72,
		"enemy_health_ratio": 0.64,
		"route_pressure": 1.2,
		"future_offer_size": 3,
	}


func _offer(ids: Array) -> Array:
	var result: Array = []
	for upgrade_id in ids:
		result.append(ManifestScript.get_definition(str(upgrade_id)))
	return result


func _ranked_ids(evaluations: Array) -> Array:
	var result: Array = []
	for evaluation in evaluations:
		result.append(str((evaluation as Dictionary).get("upgrade_id", "")))
	return result


func _ranked_scores(evaluations: Array) -> Array:
	var result: Array = []
	for evaluation in evaluations:
		result.append(float((evaluation as Dictionary).get("commander_score", -INF)))
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
	await process_frame
	await process_frame
	return main
