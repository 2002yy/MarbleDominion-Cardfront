extends SceneTree

const AuditScript = preload("res://scripts/cardfront/simulation/CardfrontB1DeckCandidateAudit.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

const ARTIFACT_DIRECTORY: String = "res://artifacts"
const JSON_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-deck-candidates.json"
const TEXT_ARTIFACT_PATH: String = "res://artifacts/cardfront-b1-deck-candidates.txt"

var _assert: TestAssert


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_assert = TestAssert.new()
	var seed_override: String = OS.get_environment("CARDFRONT_B1_DECK_AUDIT_SEEDS")
	var seeds_per_case: int = maxi(1, int(seed_override)) if seed_override.is_valid_int() else 20
	print("[CardfrontB1DeckCandidateAudit] Starting deck audit with %d seeds per case" % seeds_per_case)
	var audit = AuditScript.new()
	var report: Dictionary = audit.run(seeds_per_case)
	var summary: String = audit.format_summary(report)
	print(summary)
	_write_artifacts(report, summary)

	var scenarios: Dictionary = report.get("scenarios", {}) as Dictionary
	_assert.eq(scenarios.size(), AuditScript.SCENARIOS.size(), "deck audit should execute every declared scenario")
	_assert.eq(int(report.get("total_matches", 0)), scenarios.size() * 54 * seeds_per_case, "deck audit should execute the complete matrix")
	for raw_scenario_id in scenarios.keys():
		var scenario_id: String = str(raw_scenario_id)
		var scenario: Dictionary = scenarios[raw_scenario_id] as Dictionary
		_assert.eq(int(scenario.get("matches", 0)), 54 * seeds_per_case, "deck audit should complete every match: %s" % scenario_id)
		_assert.eq(int(scenario.get("invalid_offers", -1)), 0, "deck audit should not produce invalid offers: %s" % scenario_id)
		_assert.eq((scenario.get("hero_rates", {}) as Dictionary).size(), HeroRegistryScript.get_hero_ids().size(), "deck audit should report all heroes: %s" % scenario_id)

	var engineer_only: Dictionary = scenarios.get("engineer_fortification_only", {}) as Dictionary
	var engineer_health: Dictionary = (engineer_only.get("card_health_by_hero", {}) as Dictionary).get(
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER,
		{}
	) as Dictionary
	var engineer_candidates: Dictionary = engineer_health.get("candidate_card_selections", {}) as Dictionary
	_assert.gt(int(engineer_candidates.get(ManifestScript.UPGRADE_SIEGE_CALIBRATION, 0)), 0, "deck audit should show Engineer selecting the approved siege grouping")
	_assert.gt(int(engineer_candidates.get(ManifestScript.UPGRADE_HEAVY_CHARGE, 0)), 0, "deck audit should show Engineer selecting heavy charge")

	var core_all: Dictionary = scenarios.get("core_all", {}) as Dictionary
	var recommended: Dictionary = scenarios.get("recommended_decks", {}) as Dictionary
	_assert.that(is_finite(float(core_all.get("balance_error", INF))), "deck audit should report the core balance error")
	_assert.that(is_finite(float(recommended.get("balance_error", INF))), "deck audit should report the candidate balance error")
	_assert.that(is_finite(float(core_all.get("hero_rate_spread", INF))), "deck audit should report the core hero-rate spread")
	_assert.that(is_finite(float(recommended.get("hero_rate_spread", INF))), "deck audit should report the candidate hero-rate spread")
	_assert.eq(
		(report.get("ranked_by_balance_error", []) as Array).size(),
		scenarios.size(),
		"deck audit should rank every candidate scenario"
	)
	_assert.eq(
		str(report.get("boundary", "")),
		"candidate_only_not_live_default_not_b1_final",
		"deck audit should keep unbalanced candidates out of live defaults"
	)
	_assert.that(FileAccess.file_exists(JSON_ARTIFACT_PATH), "deck audit JSON artifact should exist")
	_assert.that(FileAccess.file_exists(TEXT_ARTIFACT_PATH), "deck audit text artifact should exist")
	_assert.report("[CardfrontB1DeckCandidateAudit]")
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
