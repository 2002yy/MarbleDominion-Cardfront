extends SceneTree

# Dedicated cloud evidence runner for the provisional B0 parity model.
# This file intentionally lives outside the historical merge-blocking audit.
const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontHeroBalanceAudit.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	var seed_override: String = OS.get_environment("CARDFRONT_BALANCE_SEEDS")
	var seeds_per_case: int = (
		maxi(1, int(seed_override))
		if seed_override.is_valid_int()
		else ConfigScript.FULL_SEEDS_PER_CASE
	)
	print("[CardfrontParityBalanceAudit] Starting B0 parity audit with %d seeds per case" % seeds_per_case)
	var audit = AuditScript.new()
	var report: Dictionary = audit.run(
		seeds_per_case,
		ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	)
	var summary: String = audit.format_summary(report)
	print(summary)
	print("PARITY_AUDIT_JSON=" + JSON.stringify(report))
	_write_artifacts(report, summary)

	_assert.eq(
		str(report.get("simulation_mode", "")),
		ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED,
		"parity audit: report must use the uncompensated mode"
	)
	_assert.eq(
		bool(report.get("hidden_hit_compensation", true)),
		false,
		"parity audit: hidden hero hit compensation must be disabled"
	)
	_assert.eq(
		int(report.get("resolved_attack_level_cap", 0)),
		4,
		"parity audit: temporary attack must resolve up to level four"
	)
	_assert.eq(
		int(report.get("matches", 0)),
		54 * seeds_per_case,
		"parity audit: complete hero-map-side matrix must finish"
	)
	if seeds_per_case == ConfigScript.FULL_SEEDS_PER_CASE:
		_assert.eq(
			int(report.get("matches", 0)),
			54000,
			"parity audit: cloud audit must execute all 54,000 matches"
		)
	_assert.eq(
		int((report.get("metrics", {}) as Dictionary).get("invalid_offers", -1)),
		0,
		"parity audit: draft offers must remain valid"
	)

	# B0 is an evidence run, not a merge-blocking final balance gate. The report
	# intentionally prints threshold failures without asserting them until gates,
	# true side reruns, and route metrics are represented by the simulator.
	var thresholds: Dictionary = report.get("thresholds", {}) as Dictionary
	print("[CardfrontParityBalanceAudit] provisional_threshold_passed=%s failures=%s" % [
		str(thresholds.get("passed", false)),
		str(thresholds.get("failures", [])),
	])

	_assert.report("[CardfrontParityBalanceAudit]")
	quit(0 if _assert.failures.is_empty() else 1)


func _write_artifacts(report: Dictionary, summary: String) -> void:
	var artifact_dir: String = ProjectSettings.globalize_path("res://artifacts")
	var make_error: Error = DirAccess.make_dir_recursive_absolute(artifact_dir)
	_assert.that(make_error == OK or make_error == ERR_ALREADY_EXISTS, "parity audit: artifact directory should be writable")

	var json_file := FileAccess.open(artifact_dir.path_join("cardfront-parity-audit.json"), FileAccess.WRITE)
	_assert.that(json_file != null, "parity audit: JSON artifact should open for writing")
	if json_file != null:
		json_file.store_string(JSON.stringify(report, "\t"))
		json_file.close()

	var summary_file := FileAccess.open(artifact_dir.path_join("cardfront-parity-audit.txt"), FileAccess.WRITE)
	_assert.that(summary_file != null, "parity audit: summary artifact should open for writing")
	if summary_file != null:
		summary_file.store_string(summary + "\n")
		summary_file.close()
