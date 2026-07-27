extends RefCounted
class_name CardfrontB1HeroCandidateAudit

const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const SimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1HeroCandidateSimulator.gd")

const CANDIDATES: Dictionary = {
	"baseline": {},
	"gunner_health_32": {
		HeroRegistryScript.HERO_RAPID_GUNNER: {"command_chamber_health": 32},
	},
	"gunner_health_30": {
		HeroRegistryScript.HERO_RAPID_GUNNER: {"command_chamber_health": 30},
	},
	"gunner_volley_6": {
		HeroRegistryScript.HERO_RAPID_GUNNER: {"base_volley_count": 6},
	},
	"engineer_health_46": {
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {"command_chamber_health": 46},
	},
	"engineer_health_50": {
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {"command_chamber_health": 50},
	},
	"engineer_front_3": {
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {
			"territory_defense_cap": 3,
			"starting_contact_front_defense": 3,
		},
	},
	"engineer_volley_6": {
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {"base_volley_count": 6},
	},
	"normalize_volley_6": {
		HeroRegistryScript.HERO_RAPID_GUNNER: {"base_volley_count": 6},
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {"base_volley_count": 6},
	},
}


func run(seeds_per_case: int = 10) -> Dictionary:
	var safe_seeds: int = maxi(1, int(seeds_per_case))
	var reports: Dictionary = {}
	var candidate_ids: Array = CANDIDATES.keys()
	candidate_ids.sort()
	candidate_ids.erase("baseline")
	candidate_ids.push_front("baseline")
	for raw_candidate_id in candidate_ids:
		var candidate_id: String = str(raw_candidate_id)
		reports[candidate_id] = _run_candidate(candidate_id, CANDIDATES[candidate_id] as Dictionary, safe_seeds)
	var baseline_rates: Dictionary = (reports["baseline"] as Dictionary).get("hero_rates", {}) as Dictionary
	for raw_candidate_id in reports.keys():
		var candidate: Dictionary = reports[raw_candidate_id] as Dictionary
		candidate["hero_rate_delta_vs_baseline"] = _rate_delta(candidate.get("hero_rates", {}) as Dictionary, baseline_rates)
	return {
		"audit_id": "b1_hero_candidate_sensitivity",
		"seeds_per_case": safe_seeds,
		"candidate_count": reports.size(),
		"matches_per_candidate": 54 * safe_seeds,
		"total_matches": reports.size() * 54 * safe_seeds,
		"candidates": reports,
		"ranked_by_balance_error": _rank_candidates(reports),
	}


func format_summary(report: Dictionary) -> String:
	var lines: Array[String] = [
		"B1 hero candidate sensitivity seeds=%d candidates=%d total_matches=%d" % [
			int(report.get("seeds_per_case", 0)),
			int(report.get("candidate_count", 0)),
			int(report.get("total_matches", 0)),
		],
	]
	for raw_entry in report.get("ranked_by_balance_error", []) as Array:
		var entry: Dictionary = raw_entry as Dictionary
		var candidate_id: String = str(entry.get("candidate_id", ""))
		var candidate: Dictionary = (report.get("candidates", {}) as Dictionary).get(candidate_id, {}) as Dictionary
		lines.append(
			"candidate %s error=%.2f spread=%.2f rates=%s delta=%s timeout=%.2f%%" % [
				candidate_id,
				float(candidate.get("balance_error", 0.0)),
				float(candidate.get("hero_rate_spread", 0.0)),
				JSON.stringify(candidate.get("hero_rates", {})),
				JSON.stringify(candidate.get("hero_rate_delta_vs_baseline", {})),
				float((candidate.get("pacing", {}) as Dictionary).get("timeout_rate", 0.0)),
			]
		)
	return "\n".join(lines)


func _run_candidate(candidate_id: String, overrides: Dictionary, seeds_per_case: int) -> Dictionary:
	var hero_ids: Array = HeroRegistryScript.get_hero_ids()
	var map_ids: Array = MapRegistryScript.get_registered_map_ids()
	var hero_stats: Dictionary = {}
	var matchup_stats: Dictionary = {}
	var map_hero_stats: Dictionary = {}
	for raw_hero_id in hero_ids:
		hero_stats[str(raw_hero_id)] = _empty_stats()
	for raw_hero_a in hero_ids:
		for raw_hero_b in hero_ids:
			matchup_stats[_matchup_key(str(raw_hero_a), str(raw_hero_b))] = _empty_stats()
	for raw_map_id in map_ids:
		var map_id: String = str(raw_map_id)
		map_hero_stats[map_id] = {}
		for raw_hero_id in hero_ids:
			(map_hero_stats[map_id] as Dictionary)[str(raw_hero_id)] = _empty_stats()
	var rounds: Array[int] = []
	var timeouts: int = 0
	var matches: int = 0
	var simulator = SimulatorScript.new()
	for raw_hero_a in hero_ids:
		var hero_a: String = str(raw_hero_a)
		for raw_hero_b in hero_ids:
			var hero_b: String = str(raw_hero_b)
			for raw_map_id in map_ids:
				var map_id: String = str(raw_map_id)
				for seed_index in range(seeds_per_case):
					for side_variant in [0, 1]:
						var result: Dictionary = simulator.simulate_with_overrides(
							hero_a,
							hero_b,
							map_id,
							side_variant,
							seed_index + 1,
							overrides,
							ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
						)
						if not bool(result.get("success", false)):
							continue
						matches += 1
						rounds.append(int(result.get("round_count", 0)))
						if bool(result.get("timed_out", false)):
							timeouts += 1
						var winner_slot: String = str(result.get("winner_slot", ""))
						var draw: bool = bool(result.get("draw", false))
						_add_score(hero_stats[hero_a] as Dictionary, winner_slot == "a", draw)
						_add_score(hero_stats[hero_b] as Dictionary, winner_slot == "b", draw)
						_add_score(matchup_stats[_matchup_key(hero_a, hero_b)] as Dictionary, winner_slot == "a", draw)
						var per_map: Dictionary = map_hero_stats[map_id] as Dictionary
						_add_score(per_map[hero_a] as Dictionary, winner_slot == "a", draw)
						_add_score(per_map[hero_b] as Dictionary, winner_slot == "b", draw)
	var finalized_heroes: Dictionary = _finalize(hero_stats)
	var hero_rates: Dictionary = {}
	var rate_values: Array[float] = []
	var balance_error: float = 0.0
	for raw_hero_id in finalized_heroes.keys():
		var hero_id: String = str(raw_hero_id)
		var rate: float = float((finalized_heroes[raw_hero_id] as Dictionary).get("rate", 0.0))
		hero_rates[hero_id] = rate
		rate_values.append(rate)
		balance_error += absf(rate - 50.0)
	var map_rates: Dictionary = {}
	for raw_map_id in map_hero_stats.keys():
		var map_id: String = str(raw_map_id)
		var finalized_map: Dictionary = _finalize(map_hero_stats[raw_map_id] as Dictionary)
		map_rates[map_id] = {}
		for raw_hero_id in finalized_map.keys():
			(map_rates[map_id] as Dictionary)[str(raw_hero_id)] = float((finalized_map[raw_hero_id] as Dictionary).get("rate", 0.0))
	return {
		"candidate_id": candidate_id,
		"overrides": overrides.duplicate(true),
		"matches": matches,
		"expected_matches": 54 * seeds_per_case,
		"hero_rates": hero_rates,
		"hero_rate_spread": _spread(rate_values),
		"balance_error": balance_error,
		"matchup_rates": _rates_only(_finalize(matchup_stats)),
		"map_hero_rates": map_rates,
		"pacing": _pacing(rounds, timeouts, matches),
	}


func _empty_stats() -> Dictionary:
	return {"games": 0, "wins": 0, "losses": 0, "draws": 0, "points": 0.0}


func _add_score(stats: Dictionary, won: bool, draw: bool) -> void:
	stats["games"] = int(stats["games"]) + 1
	if draw:
		stats["draws"] = int(stats["draws"]) + 1
		stats["points"] = float(stats["points"]) + 0.5
	elif won:
		stats["wins"] = int(stats["wins"]) + 1
		stats["points"] = float(stats["points"]) + 1.0
	else:
		stats["losses"] = int(stats["losses"]) + 1


func _finalize(raw_stats: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_key in raw_stats.keys():
		var stats: Dictionary = raw_stats[raw_key] as Dictionary
		var games: int = int(stats.get("games", 0))
		var copy: Dictionary = stats.duplicate(true)
		copy["rate"] = 100.0 * float(stats.get("points", 0.0)) / float(maxi(1, games))
		result[str(raw_key)] = copy
	return result


func _rates_only(finalized: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_key in finalized.keys():
		result[str(raw_key)] = float((finalized[raw_key] as Dictionary).get("rate", 0.0))
	return result


func _rate_delta(candidate: Dictionary, baseline: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		result[hero_id] = float(candidate.get(hero_id, 0.0)) - float(baseline.get(hero_id, 0.0))
	return result


func _rank_candidates(reports: Dictionary) -> Array:
	var ranked: Array = []
	for raw_candidate_id in reports.keys():
		var candidate: Dictionary = reports[raw_candidate_id] as Dictionary
		ranked.append({
			"candidate_id": str(raw_candidate_id),
			"balance_error": float(candidate.get("balance_error", INF)),
			"hero_rate_spread": float(candidate.get("hero_rate_spread", INF)),
		})
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_error: float = float(left.get("balance_error", INF))
		var right_error: float = float(right.get("balance_error", INF))
		if not is_equal_approx(left_error, right_error):
			return left_error < right_error
		return float(left.get("hero_rate_spread", INF)) < float(right.get("hero_rate_spread", INF))
	)
	return ranked


func _pacing(rounds: Array[int], timeouts: int, matches: int) -> Dictionary:
	var sorted: Array[int] = rounds.duplicate()
	sorted.sort()
	var count: int = sorted.size()
	var median: float = 0.0
	if count > 0:
		median = (
			(float(sorted[count / 2 - 1]) + float(sorted[count / 2])) * 0.5
			if count % 2 == 0
			else float(sorted[count / 2])
		)
	var p90_index: int = clampi(ceili(float(count) * 0.9) - 1, 0, maxi(0, count - 1))
	return {
		"median_round": median,
		"p90_round": float(sorted[p90_index]) if count > 0 else 0.0,
		"timeout_rate": 100.0 * float(timeouts) / float(maxi(1, matches)),
	}


func _spread(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return sorted[sorted.size() - 1] - sorted[0]


func _matchup_key(hero_a: String, hero_b: String) -> String:
	return "%s|%s" % [hero_a, hero_b]
