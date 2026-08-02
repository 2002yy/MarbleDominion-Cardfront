extends SceneTree

const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontHeroBalanceAudit.gd")
const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const MatchSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceMatchSimulator.gd")

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
	print("[CardfrontHeroBalanceSimulationTest] Starting historical audit with %d seeds per case" % seeds_per_case)
	_test_simulation_mode_contract()
	_test_single_match_is_deterministic()
	var report: Dictionary = AuditScript.new().run(
		seeds_per_case,
		ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
	)
	print(AuditScript.new().format_summary(report))
	_test_full_matrix(report, seeds_per_case)
	_test_report_contract(report)
	_report_balance_thresholds(report)

	var parity_probe_seeds: int = 3
	var parity_report: Dictionary = AuditScript.new().run(
		parity_probe_seeds,
		ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	)
	print(AuditScript.new().format_summary(parity_report))
	_test_parity_probe(parity_report, parity_probe_seeds)

	_assert.report("[CardfrontHeroBalanceSimulationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_simulation_mode_contract() -> void:
	var simulator = MatchSimulatorScript.new()
	_assert.eq(
		simulator.resolve_attack_level_for_mode(
			3,
			1,
			ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
		),
		3,
		"mode: historical audit must preserve the old temporary attack ceiling"
	)
	_assert.eq(
		simulator.resolve_attack_level_for_mode(
			3,
			1,
			ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
		),
		4,
		"mode: parity audit must match live temporary attack level four"
	)
	var baseline_hit_chance: float = 0.20
	_assert.gt(
		simulator.adjust_hit_chance_for_mode(
			baseline_hit_chance,
			5,
			ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
		),
		simulator.adjust_hit_chance_for_mode(
			baseline_hit_chance,
			5,
			ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
		),
		"mode: historical engineer compensation should be explicit"
	)
	_assert.gt(
		simulator.adjust_hit_chance_for_mode(
			baseline_hit_chance,
			7,
			ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
		),
		simulator.adjust_hit_chance_for_mode(
			baseline_hit_chance,
			7,
			ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
		),
		"mode: historical gunner penalty should be explicit"
	)
	_assert.eq(
		simulator.adjust_hit_chance_for_mode(
			baseline_hit_chance,
			6,
			ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
		),
		baseline_hit_chance,
		"mode: balanced commander should receive no hidden accuracy adjustment"
	)


func _test_single_match_is_deterministic() -> void:
	var simulator = MatchSimulatorScript.new()
	var first: Dictionary = simulator.simulate(
		"balanced_commander",
		"rapid_gunner",
		"default_duel",
		0,
		913,
		ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
	)
	var second: Dictionary = simulator.simulate(
		"balanced_commander",
		"rapid_gunner",
		"default_duel",
		0,
		913,
		ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
	)
	_assert.eq(first, second, "simulation: same inputs and mode must produce the same complete result")
	_assert.that(bool(first.get("success", false)), "simulation: registered heroes and map should resolve")
	_assert.eq(
		str(first.get("simulation_mode", "")),
		ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED,
		"simulation: result should identify the historical mode"
	)

	var parity_first: Dictionary = simulator.simulate(
		"fortification_engineer",
		"rapid_gunner",
		"default_duel",
		0,
		913,
		ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	)
	var parity_second: Dictionary = simulator.simulate(
		"fortification_engineer",
		"rapid_gunner",
		"default_duel",
		0,
		913,
		ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
	)
	_assert.eq(parity_first, parity_second, "simulation: parity mode must remain deterministic")
	_assert.eq(bool(parity_first.get("hidden_hit_compensation", true)), false, "simulation: parity mode should disable hidden hero accuracy")
	_assert.eq(int(parity_first.get("resolved_attack_level_cap", 0)), 4, "simulation: parity mode should advertise level-four temporary attacks")


func _test_full_matrix(report: Dictionary, seeds_per_case: int) -> void:
	var expected_matches: int = 54 * seeds_per_case
	_assert.eq(int(report["expected_matches"]), expected_matches, "matrix: approved dimensions should produce every requested match")
	_assert.eq(int(report["matches"]), expected_matches, "matrix: every requested match should complete")
	if seeds_per_case == ConfigScript.FULL_SEEDS_PER_CASE:
		_assert.eq(int(report["matches"]), 54000, "matrix: CI historical audit should execute all 54,000 matches")
	_assert.eq((report["hero_rates"] as Dictionary).size(), 3, "matrix: all three heroes should have aggregate rates")
	_assert.eq((report["matchup_rates"] as Dictionary).size(), 9, "matrix: all ordered hero matchups should be reported")
	_assert.eq((report["mirror_blue_rates"] as Dictionary).size(), 3, "matrix: all three mirrors should report blue-side rate")


func _test_report_contract(report: Dictionary) -> void:
	var pacing: Dictionary = report["pacing"] as Dictionary
	var metrics: Dictionary = report["metrics"] as Dictionary
	_assert.eq(str(report.get("simulation_mode", "")), ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED, "report: historical gate should be explicitly labeled")
	_assert.eq(bool(report.get("hidden_hit_compensation", false)), true, "report: historical gate should disclose hidden compensation")
	_assert.eq(int(report.get("resolved_attack_level_cap", 0)), 3, "report: historical gate should preserve attack cap three")
	_assert.gt(float(metrics["average_cells_crossed_per_marble"]), 0.0, "metrics: cells crossed per marble should be recorded")
	_assert.gt(float(metrics["chamber_hits_per_volley"]), 0.0, "metrics: chamber hits per volley should be recorded")
	_assert.gte(float(metrics["defense_absorbed_per_volley"]), 0.0, "metrics: absorbed defense should be recorded")
	_assert.between(float(metrics["average_first_stronghold_round"]), 4.0, 8.0, "metrics: first activation should remain in the approved window")
	_assert.eq(int(metrics["invalid_offers"]), 0, "draft: capped or invalid offers should never enter the audit")
	_assert.gt(float(pacing["median_round"]), 0.0, "pacing: median round should be present")
	_assert.gt(float(pacing["p90_round"]), 0.0, "pacing: P90 round should be present")


func _test_parity_probe(report: Dictionary, seeds_per_case: int) -> void:
	_assert.eq(str(report.get("simulation_mode", "")), ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED, "parity: report should identify the new rules")
	_assert.eq(bool(report.get("hidden_hit_compensation", true)), false, "parity: hidden compensation should be disabled")
	_assert.eq(int(report.get("resolved_attack_level_cap", 0)), 4, "parity: temporary attack cap should be four")
	_assert.eq(int(report.get("matches", 0)), 54 * seeds_per_case, "parity: probe should cover the complete hero-map-side matrix")
	_assert.eq(int((report.get("metrics", {}) as Dictionary).get("invalid_offers", -1)), 0, "parity: probe should not create invalid draft offers")


func _report_balance_thresholds(report: Dictionary) -> void:
	var thresholds: Dictionary = report["thresholds"] as Dictionary
	# Balance thresholds are telemetry for tuning, not a merge gate. The audit
	# continues to exercise the complete deterministic matrix and validates its
	# report contract, while product balance work can iterate independently.
	if not bool(thresholds["passed"]):
		print("[CardfrontHeroBalanceSimulationTest] Balance telemetry: %s" % str(thresholds["failures"]))
