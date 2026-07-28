extends SceneTree

const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontB1ArchetypeHeroBalanceAudit.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const MapTargetEvaluatorScript = preload("res://scripts/cardfront/simulation/CardfrontMapBalanceTargetEvaluator.gd")
const NumericDiagnosisScript = preload("res://scripts/cardfront/simulation/CardfrontB1NumericDiagnosis.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ArchetypeGrowthEvaluatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1ArchetypeGrowthEvaluator.gd")

const ARTIFACT_DIRECTORY: String = "res://artifacts"
const JSON_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-balance-audit.json"
const TEXT_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-balance-audit.txt"
const MAP_TARGET_GATE_SEEDS: int = 100

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	var seed_override: String = OS.get_environment("CARDFRONT_B1_AUDIT_SEEDS")
	var seeds_per_case: int = maxi(1, int(seed_override)) if seed_override.is_valid_int() else 3
	print("[CardfrontB1BalanceAudit] Starting B1 audit with %d seeds per case" % seeds_per_case)
	var audit = AuditScript.new()
	var report: Dictionary = audit.run(seeds_per_case, ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED)
	var target_evaluation: Dictionary = MapTargetEvaluatorScript.evaluate(report.get("map_reports", {}) as Dictionary)
	var numeric_diagnosis: Dictionary = NumericDiagnosisScript.analyze(report)
	var archetype_growth: Dictionary = ArchetypeGrowthEvaluatorScript.evaluate(report)
	report["map_target_evaluation"] = target_evaluation
	report["numeric_diagnosis"] = numeric_diagnosis
	report["archetype_growth"] = archetype_growth
	var summary: String = "%s\n%s\n%s\n%s" % [
		audit.format_b1_summary(report),
		MapTargetEvaluatorScript.format_summary(target_evaluation),
		NumericDiagnosisScript.format_summary(numeric_diagnosis),
		ArchetypeGrowthEvaluatorScript.format_summary(archetype_growth),
	]
	print(summary)
	_write_artifacts(report, summary)
	_assert.that(bool(report.get("passed", false)), "B1 audit should satisfy its structural parity gate")
	_assert.eq(int(report.get("matches", 0)), 54 * seeds_per_case, "B1 audit should execute both real side calls")
	var b1: Dictionary = report.get("b1_metrics", {}) as Dictionary
	_assert.eq(int(b1.get("actual_side_calls", 0)), 54 * seeds_per_case, "B1 should count actual side simulation calls")
	_assert.gt(int(b1.get("gate_passes", 0)), 0, "B1 should record gate passes")
	_assert.gt(int(b1.get("gate_reflections", 0)) + int(b1.get("river_bank_reflections", 0)), 0, "B1 should record route rejection")
	_assert.gt(int(b1.get("shared_upgrade_choice_count", 0)), 0, "B1 should use shared marginal choices")
	var card_by_hero: Dictionary = b1.get("card_by_hero", {}) as Dictionary
	for hero_id in HeroRegistryScript.get_hero_ids():
		var safe_id: String = str(hero_id)
		_assert.that(card_by_hero.has(safe_id), "B1 should aggregate card metrics for %s" % safe_id)
		var hero_cards: Dictionary = card_by_hero.get(safe_id, {}) as Dictionary
		_assert.gt(_sum_numeric(hero_cards.get("selections", {}) as Dictionary), 0.0, "B1 should record selections for %s" % safe_id)
	var map_reports: Dictionary = report.get("map_reports", {}) as Dictionary
	var expected_per_map: int = 18 * seeds_per_case
	_assert.eq(map_reports.size(), MapRegistryScript.get_registered_map_ids().size(), "B1 should emit one report per registered map")
	for map_id in MapRegistryScript.get_registered_map_ids():
		var safe_map_id: String = str(map_id)
		_assert.that(map_reports.has(safe_map_id), "B1 should emit map report for %s" % safe_map_id)
		var map_report: Dictionary = map_reports.get(safe_map_id, {}) as Dictionary
		_assert.eq(int(map_report.get("matches", 0)), expected_per_map, "B1 map report should contain complete matrix for %s" % safe_map_id)
		_assert.eq((map_report.get("hero_rates", {}) as Dictionary).size(), HeroRegistryScript.get_hero_ids().size(), "B1 map report should contain every hero for %s" % safe_map_id)
		var route_metrics: Dictionary = map_report.get("route_metrics", {}) as Dictionary
		_assert.gt(float(route_metrics.get("gate_pass_rate", 0.0)), 0.0, "B1 map report should record gate passage for %s" % safe_map_id)
		_assert.eq((route_metrics.get("lane_share", {}) as Dictionary).size(), 2, "B1 map report should record two lane shares for %s" % safe_map_id)
	var hero_diagnosis: Dictionary = numeric_diagnosis.get("hero_balance", {}) as Dictionary
	var card_diagnosis: Dictionary = numeric_diagnosis.get("card_health", {}) as Dictionary
	_assert.eq((report.get("hero_performance", {}) as Dictionary).size(), HeroRegistryScript.get_hero_ids().size(), "B1 should expose per-hero gameplay indicators")
	_assert.that(not bool(archetype_growth.get("hard_gate_enabled", true)), "archetype growth targets should remain diagnostic during framework calibration")
	_assert.eq(hero_diagnosis.size(), HeroRegistryScript.get_hero_ids().size(), "B1 diagnosis should cover every hero")
	_assert.eq(card_diagnosis.size(), HeroRegistryScript.get_hero_ids().size(), "B1 card diagnosis should cover every hero")
	for hero_id in HeroRegistryScript.get_hero_ids():
		var safe_id: String = str(hero_id)
		var hero_cards: Dictionary = card_diagnosis.get(safe_id, {}) as Dictionary
		_assert.eq((hero_cards.get("per_card", {}) as Dictionary).size(), UpgradeManifestScript.get_upgrade_ids().size(), "B1 diagnosis should cover every card for %s" % safe_id)
		_assert.eq((hero_cards.get("map_builds", {}) as Dictionary).size(), MapRegistryScript.get_registered_map_ids().size(), "B1 diagnosis should split builds by map for %s" % safe_id)
	if seeds_per_case >= MAP_TARGET_GATE_SEEDS:
		_assert.that(bool(target_evaluation.get("passed", false)), "B1 5,400+ audit should satisfy every map balance target")
	if seeds_per_case == ConfigScript.FULL_SEEDS_PER_CASE:
		_assert.eq(int(report.get("matches", 0)), 54000, "B1 full cloud audit should execute 54,000 matches")
	_assert.that(FileAccess.file_exists(JSON_ARTIFACT_PATH), "B1 JSON artifact should exist")
	_assert.that(FileAccess.file_exists(TEXT_ARTIFACT_PATH), "B1 text artifact should exist")
	_assert.report("[CardfrontB1BalanceAudit]")
	quit(0 if _assert.failures.is_empty() else 1)


func _sum_numeric(values: Dictionary) -> float:
	var total: float = 0.0
	for value in values.values():
		total += float(value)
	return total


func _write_artifacts(report: Dictionary, summary: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ARTIFACT_DIRECTORY))
	var json_file := FileAccess.open(JSON_ARTIFACT_PATH, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(report, "  ", true, true))
		json_file.close()
	var text_file := FileAccess.open(TEXT_ARTIFACT_PATH, FileAccess.WRITE)
	if text_file != null:
		text_file.store_string(summary + "\n")
		text_file.close()
