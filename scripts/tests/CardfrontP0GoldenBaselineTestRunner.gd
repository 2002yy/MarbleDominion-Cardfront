extends SceneTree

const GOLDEN_PATH: String = "res://docs/cardfront_refactor_checkpoints/P0-00E_golden_baseline.json"

const GameConfigScript = preload("res://scripts/GameConfig.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const GateRulesScript = preload("res://scripts/cardfront/gates/CardfrontGateRules.gd")
const MatchPhaseScript = preload("res://scripts/cardfront/run/CardfrontMatchPhase.gd")
const CommandPointSystemScript = preload("res://scripts/cardfront/run/CardfrontCommandPointSystem.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")
const StrongholdSystemScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdSystem.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const VolleyPlanScript = preload("res://scripts/cardfront/volley/CardfrontVolleyPlan.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	print("[CardfrontP0GoldenBaselineTest] Checking structural P0 baseline")
	await process_frame

	var golden: Dictionary = _load_golden()
	if not golden.is_empty():
		_test_mode_and_duel(golden)
		_test_phase_and_economy(golden)
		_test_lane_metadata(golden)
		_test_legacy_stronghold_retirement(golden)
		_test_exclusions_and_follow_up(golden)

	_assert.report("[CardfrontP0GoldenBaselineTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _load_golden() -> Dictionary:
	_assert.that(FileAccess.file_exists(GOLDEN_PATH), "golden: contract file should exist")
	if not FileAccess.file_exists(GOLDEN_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
	_assert.that(parsed is Dictionary, "golden: contract should parse as a JSON object")
	return parsed as Dictionary if parsed is Dictionary else {}


func _test_mode_and_duel(golden: Dictionary) -> void:
	var mode: Dictionary = golden.get("mode", {}) as Dictionary
	var duel: Dictionary = golden.get("duel", {}) as Dictionary
	_assert.eq(int(golden.get("schema_version", 0)), 2, "golden: schema version should reflect the P0-05B2 contract transition")
	_assert.eq(str(golden.get("transition_checkpoint", "")), "P0-05B2", "golden: stronghold retirement transition checkpoint")
	_assert.eq(str(mode.get("id", "")), GameConfigScript.GAME_MODE_CARDFRONT, "golden: Cardfront mode id")
	_assert.eq(str(mode.get("main_scene", "")), str(ProjectSettings.get_setting("application/run/main_scene", "")), "golden: configured main scene")
	_assert.that(ResourceLoader.exists(str(mode.get("main_scene", ""))), "golden: main scene resource should exist")
	_assert.eq(int(duel.get("player_faction", -1)), CardfrontRulesScript.PLAYER_FACTION, "golden: player duel faction")
	_assert.eq(int(duel.get("ai_faction", -1)), CardfrontRulesScript.AI_FACTION, "golden: AI duel faction")
	_assert.eq(CardfrontRulesScript.get_duel_factions(), [CardfrontRulesScript.PLAYER_FACTION, CardfrontRulesScript.AI_FACTION], "golden: duel side order")


func _test_phase_and_economy(golden: Dictionary) -> void:
	var command_points: Dictionary = golden.get("command_points", {}) as Dictionary
	var offer_size: Dictionary = golden.get("offer_size", {}) as Dictionary
	_assert.eq(golden.get("phase_progression", []), MatchPhaseScript.ALL, "golden: Draft/Aim/Execution/Volley phase structure")
	_assert.eq(int(command_points.get("default", -1)), CommandPointSystemScript.DEFAULT_POINTS, "golden: default Command Points")
	_assert.eq(int(command_points.get("max", -1)), CommandPointSystemScript.MAX_POINTS, "golden: maximum Command Points")
	_assert.eq(int(offer_size.get("player_default", -1)), DraftSystemScript.DEFAULT_OFFER_SIZE, "golden: player default offer size")
	_assert.eq(int(offer_size.get("ai_default", -1)), DraftSystemScript.DEFAULT_OFFER_SIZE, "golden: AI default offer size")
	_assert.eq(int(offer_size.get("legacy_lab", -1)), StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT, "golden: historical Lab offer size should remain identifiable")
	_assert.eq(DraftSystemScript.MAX_OFFER_SIZE, DraftSystemScript.DEFAULT_OFFER_SIZE, "golden: formal draft consumer should remain capped to three")


func _test_lane_metadata(golden: Dictionary) -> void:
	var lanes: Dictionary = golden.get("lanes", {}) as Dictionary
	_assert.eq(int(lanes.get("count", -1)), GateRulesScript.LANE_COUNT, "golden: two-lane count")
	_assert.eq(lanes.get("center_ratios", []), GateRulesScript.LANE_CENTER_RATIOS, "golden: lane center ratios")
	_assert.eq(str(lanes.get("strategy_identity", "")), "two_equal_routes", "golden: route strategy identity")


func _test_legacy_stronghold_retirement(golden: Dictionary) -> void:
	var legacy: Dictionary = golden.get("legacy_stronghold", {}) as Dictionary
	_assert.eq(str(legacy.get("ruleset", "")), StrongholdRulesScript.RULESET_ID, "golden: legacy Stronghold ruleset should remain identifiable")
	_assert.eq(int(legacy.get("activation_percent", -1)), StrongholdRulesScript.ACTIVATION_PERCENT, "golden: stronghold activation threshold remains part of status semantics")
	_assert.eq(int(legacy.get("factory_shot_bonus", -1)), StrongholdRulesScript.FACTORY_SHOT_BONUS, "golden: historical Factory +3 value")
	_assert.eq(int(legacy.get("energy_attack_level_bonus", -1)), StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS, "golden: historical Energy +1 value")
	_assert.eq(int(legacy.get("lab_choice_count", -1)), StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT, "golden: historical Lab four-choice value")
	_assert.that(not bool(legacy.get("runtime_effect_expected", true)), "golden: legacy numeric stronghold effects must be retired after P0-05B2")
	_assert.eq(str(legacy.get("retired_at_checkpoint", "")), "P0-05B2", "golden: retirement checkpoint should be explicit")
	_assert.eq(str(legacy.get("expected_after_support_cutover", "")), "retired", "golden: planned post-cutover state should be retired")

	var plan = VolleyPlanScript.new()
	plan.projectile_sequence = [ProjectileTypeScript.STANDARD]
	plan.shot_count = 1
	plan.attack_level = 0
	plan.chamber_damage_quarters = 4
	var system = StrongholdSystemScript.new()
	system.apply_to_volley_plan(CardfrontRulesScript.PLAYER_FACTION, plan, {
		CardfrontRulesScript.PLAYER_FACTION: {
			"active_types": [RegionTypeScript.FACTORY, RegionTypeScript.ENERGY],
			"shot_count_bonus": StrongholdRulesScript.FACTORY_SHOT_BONUS,
			"temporary_attack_level_bonus": StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS,
			"draft_choice_count": StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT,
		},
	})
	_assert.eq(plan.shot_count, 1, "golden: injected historical Factory value must not change resolved volley count")
	_assert.eq(plan.projectile_sequence.size(), 1, "golden: injected historical Factory value must not append projectiles")
	_assert.eq(plan.attack_level, 0, "golden: injected historical Energy value must not change resolved attack level")
	_assert.eq(plan.chamber_damage_quarters, 4, "golden: injected historical Energy value must not change chamber damage")
	_assert.eq(plan.stronghold_shot_bonus, 0, "golden: retired Factory plan metadata should be neutral")
	_assert.eq(plan.stronghold_attack_level_bonus, 0, "golden: retired Energy plan metadata should be neutral")
	system.free()


func _test_exclusions_and_follow_up(golden: Dictionary) -> void:
	var excluded: Array = golden.get("excluded", []) as Array
	var peek: Dictionary = golden.get("draft_peek", {}) as Dictionary
	for key in ["random_offer_ids", "visual_pixels", "instantaneous_fps"]:
		_assert.that(excluded.has(key), "golden: %s must remain outside the structural contract" % key)
	_assert.eq(str(peek.get("runtime_evidence", "")), "FOLLOW-UP / AUDIT REQUIRED", "golden: unobserved Draft peek behavior must not be marked PASS")
	_assert.eq(str(peek.get("frozen_target", "")), "visibility_only_no_offer_regeneration", "golden: Draft peek target semantics")
	_assert.that(not bool(peek.get("pixel_geometry_frozen", true)), "golden: Draft peek pixel geometry should not be frozen")
