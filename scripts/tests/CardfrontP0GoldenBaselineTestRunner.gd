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
	var legacy: Dictionary = golden.get("legacy_stronghold", {}) as Dictionary
	_assert.eq(golden.get("phase_progression", []), MatchPhaseScript.ALL, "golden: Draft/Aim/Execution/Volley phase structure")
	_assert.eq(int(command_points.get("default", -1)), CommandPointSystemScript.DEFAULT_POINTS, "golden: default Command Points")
	_assert.eq(int(command_points.get("max", -1)), CommandPointSystemScript.MAX_POINTS, "golden: maximum Command Points")
	_assert.eq(int(offer_size.get("player_default", -1)), DraftSystemScript.DEFAULT_OFFER_SIZE, "golden: player default offer size")
	_assert.eq(int(offer_size.get("ai_default", -1)), DraftSystemScript.DEFAULT_OFFER_SIZE, "golden: AI default offer size")
	_assert.eq(int(offer_size.get("legacy_lab", -1)), int(legacy.get("lab_choice_count", -2)), "golden: historical Lab fixture should stay internally consistent without runtime coupling")
	_assert.eq(DraftSystemScript.MAX_OFFER_SIZE, DraftSystemScript.DEFAULT_OFFER_SIZE, "golden: formal draft consumer should remain capped to three")


func _test_lane_metadata(golden: Dictionary) -> void:
	var lanes: Dictionary = golden.get("lanes", {}) as Dictionary
	_assert.eq(int(lanes.get("count", -1)), GateRulesScript.LANE_COUNT, "golden: two-lane count")
	_assert.eq(lanes.get("center_ratios", []), GateRulesScript.LANE_CENTER_RATIOS, "golden: lane center ratios")
	_assert.eq(str(lanes.get("strategy_identity", "")), "two_equal_routes", "golden: route strategy identity")


func _test_legacy_stronghold_retirement(golden: Dictionary) -> void:
	var legacy: Dictionary = golden.get("legacy_stronghold", {}) as Dictionary
	_assert.eq(str(legacy.get("ruleset", "")), StrongholdRulesScript.RULESET_ID, "golden: historical Stronghold ruleset should remain identifiable")
	_assert.eq(int(legacy.get("activation_percent", -1)), StrongholdRulesScript.ACTIVATION_PERCENT, "golden: activation threshold remains part of current status semantics")
	_assert.that(legacy.has("factory_shot_bonus"), "golden: historical Factory value should remain recorded in the fixture")
	_assert.that(legacy.has("energy_attack_level_bonus"), "golden: historical Energy value should remain recorded in the fixture")
	_assert.that(legacy.has("lab_choice_count"), "golden: historical Lab value should remain recorded in the fixture")
	_assert.that(not bool(legacy.get("runtime_effect_expected", true)), "golden: historical numeric effects must remain retired")
	_assert.eq(str(legacy.get("retired_at_checkpoint", "")), "P0-05B2", "golden: retirement checkpoint should be explicit")
	_assert.eq(str(legacy.get("expected_after_support_cutover", "")), "retired", "golden: planned post-cutover state should remain retired")

	var system = StrongholdSystemScript.new()
	_assert.that(system.has_method("sample_status"), "golden: current Stronghold surface should expose status sampling")
	_assert.that(system.has_method("get_owner_status"), "golden: current Stronghold surface should expose owner status")
	_assert.that(not system.has_method("sample_bonuses"), "golden: retired reward sampling API must not return")
	_assert.that(not system.has_method("get_owner_bonus"), "golden: retired reward getter must not return")
	_assert.that(not system.has_method("apply_to_volley_plan"), "golden: retired volley mutation seam must not return")
	system.free()


func _test_exclusions_and_follow_up(golden: Dictionary) -> void:
	var excluded: Array = golden.get("excluded", []) as Array
	var peek: Dictionary = golden.get("draft_peek", {}) as Dictionary
	for key in ["random_offer_ids", "visual_pixels", "instantaneous_fps"]:
		_assert.that(excluded.has(key), "golden: %s must remain outside the structural contract" % key)
	_assert.eq(str(peek.get("runtime_evidence", "")), "FOLLOW-UP / AUDIT REQUIRED", "golden: unobserved Draft peek behavior must not be marked PASS")
	_assert.eq(str(peek.get("frozen_target", "")), "visibility_only_no_offer_regeneration", "golden: Draft peek target semantics")
	_assert.that(not bool(peek.get("pixel_geometry_frozen", true)), "golden: Draft peek pixel geometry should not be frozen")
