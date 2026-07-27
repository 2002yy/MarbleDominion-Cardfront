extends CardfrontB1HeroCandidateAudit
class_name CardfrontB1HeroFinalistAudit

const FinalistHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

const REFERENCE_CANDIDATE_ID: String = "normalize_eng38_gun38"
const FINALISTS: Dictionary = {
	"normalize_eng38_gun38": {
		FinalistHeroRegistryScript.HERO_RAPID_GUNNER: {
			"base_volley_count": 6,
			"command_chamber_health": 38,
		},
		FinalistHeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {
			"base_volley_count": 6,
			"command_chamber_health": 38,
		},
	},
	"normalize_eng38_gun38_opening_1": {
		FinalistHeroRegistryScript.HERO_RAPID_GUNNER: {
			"base_volley_count": 6,
			"command_chamber_health": 38,
			"next_volley_bonus": 1,
		},
		FinalistHeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {
			"base_volley_count": 6,
			"command_chamber_health": 38,
		},
	},
	"normalize_eng40_gun38_opening_1": {
		FinalistHeroRegistryScript.HERO_RAPID_GUNNER: {
			"base_volley_count": 6,
			"command_chamber_health": 38,
			"next_volley_bonus": 1,
		},
		FinalistHeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {
			"base_volley_count": 6,
			"command_chamber_health": 40,
		},
	},
	"normalize_eng40_gun40": {
		FinalistHeroRegistryScript.HERO_RAPID_GUNNER: {
			"base_volley_count": 6,
			"command_chamber_health": 40,
		},
		FinalistHeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {
			"base_volley_count": 6,
			"command_chamber_health": 40,
		},
	},
}


func run(seeds_per_case: int = 100) -> Dictionary:
	var safe_seeds: int = maxi(1, int(seeds_per_case))
	var reports: Dictionary = {}
	var finalist_ids: Array = FINALISTS.keys()
	finalist_ids.sort()
	for raw_candidate_id in finalist_ids:
		var candidate_id: String = str(raw_candidate_id)
		reports[candidate_id] = _run_candidate(candidate_id, FINALISTS[candidate_id] as Dictionary, safe_seeds)
	var reference_rates: Dictionary = (reports[REFERENCE_CANDIDATE_ID] as Dictionary).get("hero_rates", {}) as Dictionary
	for raw_candidate_id in reports.keys():
		var candidate: Dictionary = reports[raw_candidate_id] as Dictionary
		candidate["hero_rate_delta_vs_reference"] = _rate_delta(
			candidate.get("hero_rates", {}) as Dictionary,
			reference_rates
		)
		candidate["all_heroes_45_to_55"] = _all_hero_rates_in_range(
			candidate.get("hero_rates", {}) as Dictionary,
			45.0,
			55.0
		)
	return {
		"audit_id": "b1_hero_finalist_confirmation",
		"reference_candidate_id": REFERENCE_CANDIDATE_ID,
		"seeds_per_case": safe_seeds,
		"candidate_count": reports.size(),
		"matches_per_candidate": 54 * safe_seeds,
		"total_matches": reports.size() * 54 * safe_seeds,
		"candidates": reports,
		"ranked_by_balance_error": _rank_candidates(reports),
	}


func format_summary(report: Dictionary) -> String:
	var lines: Array[String] = [
		"B1 hero finalist confirmation seeds=%d finalists=%d total_matches=%d reference=%s" % [
			int(report.get("seeds_per_case", 0)),
			int(report.get("candidate_count", 0)),
			int(report.get("total_matches", 0)),
			str(report.get("reference_candidate_id", "")),
		],
	]
	for raw_entry in report.get("ranked_by_balance_error", []) as Array:
		var entry: Dictionary = raw_entry as Dictionary
		var candidate_id: String = str(entry.get("candidate_id", ""))
		var candidate: Dictionary = (report.get("candidates", {}) as Dictionary).get(candidate_id, {}) as Dictionary
		lines.append(
			"finalist %s error=%.2f spread=%.2f all45_55=%s rates=%s delta=%s maps=%s timeout=%.2f%%" % [
				candidate_id,
				float(candidate.get("balance_error", 0.0)),
				float(candidate.get("hero_rate_spread", 0.0)),
				str(bool(candidate.get("all_heroes_45_to_55", false))),
				JSON.stringify(candidate.get("hero_rates", {})),
				JSON.stringify(candidate.get("hero_rate_delta_vs_reference", {})),
				JSON.stringify(candidate.get("map_hero_rates", {})),
				float((candidate.get("pacing", {}) as Dictionary).get("timeout_rate", 0.0)),
			]
		)
	return "\n".join(lines)


func _all_hero_rates_in_range(rates: Dictionary, minimum: float, maximum: float) -> bool:
	if rates.size() != FinalistHeroRegistryScript.get_hero_ids().size():
		return false
	for value in rates.values():
		var rate: float = float(value)
		if rate < minimum or rate > maximum:
			return false
	return true
