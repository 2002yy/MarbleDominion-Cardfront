extends SceneTree

const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontSharedAiHeroBalanceAudit.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const ValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")

const ARTIFACT_DIRECTORY: String = "res://artifacts"
const JSON_ARTIFACT_PATH: String = "res://artifacts/cardfront-shared-ai-parity-audit.json"
const TEXT_ARTIFACT_PATH: String = "res://artifacts/cardfront-shared-ai-parity-audit.txt"

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	var seed_override: String = OS.get_environment("CARDFRONT_SHARED_AI_AUDIT_SEEDS")
	var seeds_per_case: int = (
		maxi(1, int(seed_override))
		if seed_override.is_valid_int()
		else ConfigScript.FULL_SEEDS_PER_CASE
	)
	print("[CardfrontSharedAiParityAudit] Starting shared-AI parity proxy audit with %d seeds per case" % seeds_per_case)
	var audit = AuditScript.new()
	var report: Dictionary = audit.run(
		seeds_per_case,
		ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	)
	var summary: String = audit.format_summary(report)
	print(summary)
	_write_artifacts(report, summary)

	_assert.eq(str(report.get("simulation_mode", "")), ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED, "shared audit: simulation mode should be parity uncompensated")
	_assert.eq(str(report.get("upgrade_valuation_mode", "")), ValuePolicyScript.MODE_MARGINAL, "shared audit: upgrade valuation should be marginal")
	_assert.eq(bool(report.get("hidden_hit_compensation", true)), false, "shared audit: hidden hero compensation should remain disabled")
	_assert.eq(int(report.get("resolved_attack_level_cap", 0)), 4, "shared audit: temporary attack level four should remain enabled")
	_assert.eq(int(report.get("matches", 0)), 54 * seeds_per_case, "shared audit: every requested hero-map-side match should complete")
	_assert.eq(int((report.get("metrics", {}) as Dictionary).get("invalid_offers", -1)), 0, "shared audit: marginal choices should not create invalid offers")
	if seeds_per_case == ConfigScript.FULL_SEEDS_PER_CASE:
		_assert.eq(int(report.get("matches", 0)), 54000, "shared audit: cloud gate should execute all 54,000 matches")
	_assert.that(FileAccess.file_exists(JSON_ARTIFACT_PATH), "shared audit: JSON artifact should be written")
	_assert.that(FileAccess.file_exists(TEXT_ARTIFACT_PATH), "shared audit: text artifact should be written")

	_assert.report("[CardfrontSharedAiParityAudit]")
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
