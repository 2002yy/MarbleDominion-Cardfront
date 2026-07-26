extends RefCounted
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
					_accumulate_match(result, hero_stats, matchup_stats, mirror_stats, rounds, totals)
					result["side_variant"] = 1
					if str(result.get("winner_slot", "")) != "":
						result["winner_side"] = (
							"red"
							if str(result.get("winner_side", "")) == "blue"
							else "blue"
						)
					_accumulate_match(result, hero_stats, matchup_stats, mirror_stats, rounds, totals)

	var expected_matches: int = hero_ids.size() * hero_ids.size() * map_ids.size() * 2 * safe_seed_count
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
		"expected_matches": expected_matches,
		"matches": int(totals["matches"]),
		"hero_rates": _finalize_stats(hero_stats),
		"matchup_rates": _finalize_stats(matchup_stats),
		"mirror_blue_rates": _finalize_stats(mirror_stats),
		"pacing": _pacing_report(rounds, totals),
		"metrics": _metrics_report(totals),
	}
	report["passed"] = (
		int(report["matches"]) == expected_matches
		and int((report["metrics"] as Dictionary)["invalid_offers"]) == 0
	)
	return report


func format_summary(report: Dictionary) -> String:
	var pacing: Dictionary = report.get("pacing", {}) as Dictionary
	var metrics: Dictionary = report.get("metrics", {}) as Dictionary
	var lines: Array[String] = [
		"valuation=%s mode=%s hidden_compensation=%s resolved_attack_cap=%d matches=%d passed=%s median_round=%.1f p90_round=%.1f timeout=%.2f%%" % [
			str(report.get("upgrade_valuation_mode", "")),
			str(report.get("simulation_mode", "")),
			str(report.get("hidden_hit_compensation", false)),
			int(report.get("resolved_attack_level_cap", 0)),
			int(report.get("matches", 0)),
			str(report.get("passed", false)),
			float(pacing.get("median_round", 0.0)),
			float(pacing.get("p90_round", 0.0)),
			float(pacing.get("timeout_rate", 0.0)),
		],
	]
	for hero_id in (report.get("hero_rates", {}) as Dictionary).keys():
		var stats: Dictionary = (report["hero_rates"] as Dictionary)[hero_id] as Dictionary
		lines.append("hero %s %.2f%% (%d)" % [str(hero_id), float(stats["rate"]), int(stats["games"])])
	for matchup_key in (report.get("matchup_rates", {}) as Dictionary).keys():
		var stats: Dictionary = (report["matchup_rates"] as Dictionary)[matchup_key] as Dictionary
		lines.append("matchup %s %.2f%%" % [str(matchup_key), float(stats["rate"])])
	lines.append(
		"cells_per_marble=%.2f chamber_hits_per_volley=%.3f defense_absorbed_per_volley=%.3f first_stronghold=%.2f invalid_offers=%d" % [
			float(metrics.get("average_cells_crossed_per_marble", 0.0)),
			float(metrics.get("chamber_hits_per_volley", 0.0)),
			float(metrics.get("defense_absorbed_per_volley", 0.0)),
			float(metrics.get("average_first_stronghold_round", 0.0)),
			int(metrics.get("invalid_offers", 0)),
		]
	)
	return "\n".join(lines)


func _accumulate_match(
	result: Dictionary,
	hero_stats: Dictionary,
	matchup_stats: Dictionary,
	mirror_stats: Dictionary,
	rounds: Array[int],
	totals: Dictionary
) -> void:
	if not bool(result.get("success", false)):
		return
	totals["matches"] = int(totals["matches"]) + 1
	if bool(result.get("timed_out", false)):
		totals["timeouts"] = int(totals["timeouts"]) + 1
	rounds.append(int(result.get("round_count", 0)))
	var hero_a: String = str(result.get("hero_a", ""))
	var hero_b: String = str(result.get("hero_b", ""))
	var winner_slot: String = str(result.get("winner_slot", ""))
	var draw: bool = bool(result.get("draw", false))
	_add_score(hero_stats[hero_a] as Dictionary, winner_slot == "a", draw)
	_add_score(hero_stats[hero_b] as Dictionary, winner_slot == "b", draw)
	_add_score(matchup_stats[_matchup_key(hero_a, hero_b)] as Dictionary, winner_slot == "a", draw)
	if hero_a == hero_b:
		_add_score(
			mirror_stats[hero_a] as Dictionary,
			str(result.get("winner_side", "")) == "blue",
			draw
		)
	var metrics: Dictionary = result.get("metrics", {}) as Dictionary
	for key in ["invalid_offers", "shot_count", "chamber_hits", "volleys", "defense_absorbed"]:
		totals[key] = int(totals[key]) + int(metrics.get(key, 0))
	totals["cells_crossed"] = float(totals["cells_crossed"]) + float(metrics.get("cells_crossed", 0.0))
	for first_round in (result.get("first_stronghold_round", {}) as Dictionary).values():
		if int(first_round) > 0:
			totals["first_stronghold_sum"] = int(totals["first_stronghold_sum"]) + int(first_round)
			totals["first_stronghold_samples"] = int(totals["first_stronghold_samples"]) + 1


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


func _empty_score_stats() -> Dictionary:
	return {"games": 0, "wins": 0, "losses": 0, "draws": 0, "points": 0.0}


func _matchup_key(hero_a: String, hero_b: String) -> String:
	return "%s|%s" % [str(hero_a), str(hero_b)]


func _finalize_stats(raw_stats: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = raw_stats.keys()
	keys.sort()
	for key in keys:
		var stats: Dictionary = raw_stats[key] as Dictionary
		var games: int = int(stats["games"])
		var copy: Dictionary = stats.duplicate()
		copy["rate"] = 100.0 * float(stats["points"]) / float(maxi(1, games))
		result[key] = copy
	return result


func _pacing_report(rounds: Array[int], totals: Dictionary) -> Dictionary:
	rounds.sort()
	var count: int = rounds.size()
	var median_round: float = 0.0
	if count > 0:
		if count % 2 == 0:
			median_round = (float(rounds[count / 2 - 1]) + float(rounds[count / 2])) * 0.5
		else:
			median_round = float(rounds[count / 2])
	var p90_index: int = clampi(ceili(float(count) * 0.9) - 1, 0, maxi(0, count - 1))
	return {
		"median_round": median_round,
		"p90_round": float(rounds[p90_index]) if count > 0 else 0.0,
		"timeout_rate": 100.0 * float(totals["timeouts"]) / float(maxi(1, int(totals["matches"]))),
	}


func _metrics_report(totals: Dictionary) -> Dictionary:
	return {
		"average_cells_crossed_per_marble": float(totals["cells_crossed"]) / float(maxi(1, int(totals["shot_count"]))),
		"chamber_hits_per_volley": float(totals["chamber_hits"]) / float(maxi(1, int(totals["volleys"]))),
		"defense_absorbed_per_volley": float(totals["defense_absorbed"]) / float(maxi(1, int(totals["volleys"]))),
		"average_first_stronghold_round": float(totals["first_stronghold_sum"]) / float(maxi(1, int(totals["first_stronghold_samples"]))),
		"invalid_offers": int(totals["invalid_offers"]),
	}
