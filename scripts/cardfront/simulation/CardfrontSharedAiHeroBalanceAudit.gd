extends CardfrontHeroBalanceAudit
class_name CardfrontSharedAiHeroBalanceAudit

const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const MatchSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontSharedAiBalanceMatchSimulator.gd")
const ValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")


func run(
	seeds_per_case: int = ConfigScript.FULL_SEEDS_PER_CASE,
	simulation_mode: String = ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
) -> Dictionary:
	var safe_seed_count: int = maxi(1, int(seeds_per_case))
	var safe_simulation_mode: String = ConfigScript.sanitize_simulation_mode(simulation_mode)
	var hero_ids: Array = HeroRegistryScript.get_hero_ids()
	var map_ids: Array = MapRegistryScript.get_registered_map_ids()
	var hero_stats: Dictionary = {}
	var matchup_stats: Dictionary = {}
	var mirror_stats: Dictionary = {}
	for hero_id in hero_ids:
		hero_stats[str(hero_id)] = _empty_score_stats()
		mirror_stats[str(hero_id)] = _empty_score_stats()
	for hero_a in hero_ids:
		for hero_b in hero_ids:
			matchup_stats[_matchup_key(str(hero_a), str(hero_b))] = _empty_score_stats()

	var rounds: Array[int] = []
	var totals: Dictionary = {
		"matches": 0,
		"timeouts": 0,
		"invalid_offers": 0,
		"cells_crossed": 0.0,
		"shot_count": 0,
		"chamber_hits": 0,
		"volleys": 0,
		"defense_absorbed": 0,
		"first_stronghold_sum": 0,
		"first_stronghold_samples": 0,
	}
	var simulator = MatchSimulatorScript.new()
	for hero_a in hero_ids:
		for hero_b in hero_ids:
			for map_id in map_ids:
				for seed_index in range(safe_seed_count):
					var result: Dictionary = simulator.simulate(
						str(hero_a),
						str(hero_b),
						str(map_id),
						0,
						seed_index + 1,
						safe_simulation_mode
					)
					_accumulate_match(
						result,
						hero_stats,
						matchup_stats,
						mirror_stats,
						rounds,
						totals
					)
					result["side_variant"] = 1
					if str(result.get("winner_slot", "")) != "":
						result["winner_side"] = (
							"red"
							if str(result.get("winner_side", "")) == "blue"
							else "blue"
						)
					_accumulate_match(
						result,
						hero_stats,
						matchup_stats,
						mirror_stats,
						rounds,
						totals
					)

	var report: Dictionary = {
		"simulation_mode": safe_simulation_mode,
		"upgrade_valuation_mode": (
			ValuePolicyScript.MODE_HISTORICAL_FIXED
			if safe_simulation_mode == ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED
			else ValuePolicyScript.MODE_MARGINAL
		),
		"hidden_hit_compensation": ConfigScript.uses_hidden_hit_compensation(safe_simulation_mode),
		"resolved_attack_level_cap": ConfigScript.resolved_attack_level_cap(safe_simulation_mode),
		"seeds_per_case": safe_seed_count,
		"expected_matches": hero_ids.size() * hero_ids.size() * map_ids.size() * 2 * safe_seed_count,
		"matches": int(totals["matches"]),
		"hero_rates": _finalize_stats(hero_stats),
		"matchup_rates": _finalize_stats(matchup_stats),
		"mirror_blue_rates": _finalize_stats(mirror_stats),
		"pacing": _pacing_report(rounds, totals),
		"metrics": _metrics_report(totals),
	}
	report["thresholds"] = _threshold_report(report)
	report["passed"] = bool((report["thresholds"] as Dictionary)["passed"])
	return report


func format_summary(report: Dictionary) -> String:
	return "valuation=%s\n%s" % [
		str(report.get("upgrade_valuation_mode", "")),
		super.format_summary(report),
	]
