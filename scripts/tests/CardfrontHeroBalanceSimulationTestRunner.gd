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
	print("[CardfrontHeroBalanceSimulationTest] Starting v0.3.2d audit with %d seeds per case" % seeds_per_case)
	_test_single_match_is_deterministic()
	var report: Dictionary = AuditScript.new().run(seeds_per_case)
	print(AuditScript.new().format_summary(report))
	_test_full_matrix(report, seeds_per_case)
	_test_report_contract(report)
	_test_approved_thresholds(report)
	_assert.report("[CardfrontHeroBalanceSimulationTest]")
	quit(0 if _assert.failures.is_empty() else 1)


func _test_single_match_is_deterministic() -> void:
	var simulator = MatchSimulatorScript.new()
	var first: Dictionary = simulator.simulate(
		"balanced_commander",
		"rapid_gunner",
		"default_duel",
		0,
		913
	)
	var second: Dictionary = simulator.simulate(
		"balanced_commander",
		"rapid_gunner",
		"default_duel",
		0,
		913
	)
	_assert.eq(first, second, "simulation: same inputs must produce the same complete result")
	_assert.that(bool(first.get("success", false)), "simulation: registered heroes and map should resolve")


func _test_full_matrix(report: Dictionary, seeds_per_case: int) -> void:
	var expected_matches: int = 54 * seeds_per_case
	_assert.eq(int(report["expected_matches"]), expected_matches, "matrix: approved dimensions should produce every requested match")
	_assert.eq(int(report["matches"]), expected_matches, "matrix: every requested match should complete")
	if seeds_per_case == ConfigScript.FULL_SEEDS_PER_CASE:
		_assert.eq(int(report["matches"]), 54000, "matrix: CI audit should execute all 54,000 matches")
	_assert.eq((report["hero_rates"] as Dictionary).size(), 3, "matrix: all three heroes should have aggregate rates")
	_assert.eq((report["matchup_rates"] as Dictionary).size(), 9, "matrix: all ordered hero matchups should be reported")
	_assert.eq((report["mirror_blue_rates"] as Dictionary).size(), 3, "matrix: all three mirrors should report blue-side rate")


func _test_report_contract(report: Dictionary) -> void:
	var pacing: Dictionary = report["pacing"] as Dictionary
	var metrics: Dictionary = report["metrics"] as Dictionary
	_assert.gt(float(metrics["average_cells_crossed_per_marble"]), 0.0, "metrics: cells crossed per marble should be recorded")
	_assert.gt(float(metrics["chamber_hits_per_volley"]), 0.0, "metrics: chamber hits per volley should be recorded")
	_assert.gte(float(metrics["defense_absorbed_per_volley"]), 0.0, "metrics: absorbed defense should be recorded")
	_assert.between(float(metrics["average_first_stronghold_round"]), 4.0, 8.0, "metrics: first activation should remain in the approved window")
	_assert.eq(int(metrics["invalid_offers"]), 0, "draft: capped or invalid offers should never enter the audit")
	_assert.gt(float(pacing["median_round"]), 0.0, "pacing: median round should be present")
	_assert.gt(float(pacing["p90_round"]), 0.0, "pacing: P90 round should be present")


func _test_approved_thresholds(report: Dictionary) -> void:
	var thresholds: Dictionary = report["thresholds"] as Dictionary
	_assert.that(
		bool(thresholds["passed"]),
		"balance: approved hero, matchup, mirror, and pacing thresholds should pass: %s" % str(thresholds["failures"])
	)
