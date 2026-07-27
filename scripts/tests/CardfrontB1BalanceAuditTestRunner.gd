extends SceneTree

const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontB1HeroBalanceAudit.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")

const ARTIFACT_DIRECTORY: String = "res://artifacts"
const JSON_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-balance-audit.json"
const TEXT_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-balance-audit.txt"

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
	var summary: String = audit.format_b1_summary(report)
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
