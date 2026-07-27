extends SceneTree

const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontB1HeroFinalistAudit.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")

const ARTIFACT_DIRECTORY: String = "res://artifacts"
const JSON_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-hero-finalists.json"
const TEXT_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-hero-finalists.txt"

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	var seed_override: String = OS.get_environment("CARDFRONT_B1_AUDIT_SEEDS")
	var seeds_per_case: int = maxi(1, int(seed_override)) if seed_override.is_valid_int() else 100
	print("[CardfrontB1HeroFinalistAudit] Starting finalist audit with %d seeds per case" % seeds_per_case)
	var audit = AuditScript.new()
	var report: Dictionary = audit.run(seeds_per_case)
	var summary: String = audit.format_summary(report)
	print(summary)
	_write_artifacts(report, summary)
	var candidates: Dictionary = report.get("candidates", {}) as Dictionary
	_assert.eq(candidates.size(), AuditScript.FINALISTS.size(), "finalist audit should execute every declared finalist")
	_assert.eq(int(report.get("total_matches", 0)), candidates.size() * 54 * seeds_per_case, "finalist audit should execute every finalist matrix")
	_assert.that(candidates.has(AuditScript.REFERENCE_CANDIDATE_ID), "finalist audit should include its reference candidate")
	for raw_candidate_id in candidates.keys():
		var candidate_id: String = str(raw_candidate_id)
		var candidate: Dictionary = candidates[raw_candidate_id] as Dictionary
		_assert.eq(int(candidate.get("matches", 0)), 54 * seeds_per_case, "finalist should complete every match: %s" % candidate_id)
		_assert.eq((candidate.get("hero_rates", {}) as Dictionary).size(), HeroRegistryScript.get_hero_ids().size(), "finalist should report every hero: %s" % candidate_id)
		_assert.eq((candidate.get("map_hero_rates", {}) as Dictionary).size(), MapRegistryScript.get_registered_map_ids().size(), "finalist should report every map: %s" % candidate_id)
	_assert.eq((report.get("ranked_by_balance_error", []) as Array).size(), candidates.size(), "finalist audit should rank every finalist")
	_assert.that(FileAccess.file_exists(JSON_ARTIFACT_PATH), "finalist JSON artifact should exist")
	_assert.that(FileAccess.file_exists(TEXT_ARTIFACT_PATH), "finalist text artifact should exist")
	_assert.report("[CardfrontB1HeroFinalistAudit]")
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
