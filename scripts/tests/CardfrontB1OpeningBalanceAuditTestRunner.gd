extends SceneTree

const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontB1OpeningBalanceAudit.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

const ARTIFACT_DIRECTORY: String = "res://artifacts"
const JSON_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-opening-balance.json"
const TEXT_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-opening-balance.txt"

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	var seed_override: String = OS.get_environment("CARDFRONT_B1_OPENING_AUDIT_SEEDS")
	var seeds_per_case: int = maxi(1, int(seed_override)) if seed_override.is_valid_int() else 20
	var audit = AuditScript.new()
	var report: Dictionary = audit.run(seeds_per_case)
	var summary: String = audit.format_summary(report)
	print(summary)
	_write_artifacts(report, summary)

	_assert.that(bool(report.get("passed", false)), "opening audit should satisfy structural gates")
	_assert.eq(int(report.get("matches", 0)), 54 * seeds_per_case, "opening audit should execute both actual positions")
	_assert.eq(int(report.get("opening_rounds", 0)), 5, "opening audit should stop after five rounds")
	_assert.eq(int(report.get("upgrade_choices", -1)), 0, "opening audit should isolate base hero strength")
	_assert.that(not bool(report.get("upgrades_enabled", true)), "opening audit should disable upgrades")
	_assert.that(not bool(report.get("strongholds_enabled", true)), "opening audit should disable stronghold bonuses")
	_assert.that(not bool(report.get("hard_balance_gate_enabled", true)), "balance ranges should remain diagnostic during framework calibration")
	var hero_rates: Dictionary = report.get("hero_rates", {}) as Dictionary
	var mirror_rates: Dictionary = report.get("mirror_blue_rates", {}) as Dictionary
	var performance: Dictionary = report.get("hero_performance", {}) as Dictionary
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		_assert.that(hero_rates.has(hero_id), "opening audit should report hero rate: %s" % hero_id)
		_assert.that(mirror_rates.has(hero_id), "opening audit should report mirror rate: %s" % hero_id)
		_assert.that(performance.has(hero_id), "opening audit should report performance: %s" % hero_id)
		var hero_performance: Dictionary = performance.get(hero_id, {}) as Dictionary
		_assert.gt(float(hero_performance.get("shots_per_match", 0.0)), 0.0, "opening audit should measure shots: %s" % hero_id)
		_assert.that(hero_performance.has("chamber_damage_per_match"), "opening audit should measure chamber damage: %s" % hero_id)
		_assert.that(hero_performance.has("defense_absorbed_per_match"), "opening audit should measure defense absorption: %s" % hero_id)
		_assert.that(hero_performance.has("ending_territory"), "opening audit should measure territory: %s" % hero_id)
	_assert.that(FileAccess.file_exists(JSON_ARTIFACT_PATH), "opening JSON artifact should exist")
	_assert.that(FileAccess.file_exists(TEXT_ARTIFACT_PATH), "opening text artifact should exist")
	_assert.report("[CardfrontB1OpeningBalanceAudit]")
	quit(0 if _assert.failures.is_empty() else 1)


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
