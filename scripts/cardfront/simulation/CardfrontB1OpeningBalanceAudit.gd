extends CardfrontSharedAiHeroBalanceAudit
class_name CardfrontB1OpeningBalanceAudit

const OpeningConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const OpeningHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const OpeningMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const OpeningSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1OpeningMatchSimulator.gd")

const TARGET_HERO_RATE_MIN: float = 48.0
const TARGET_HERO_RATE_MAX: float = 52.0
const TARGET_MIRROR_BLUE_MIN: float = 49.0
const TARGET_MIRROR_BLUE_MAX: float = 51.0


func run(
	seeds_per_case: int = 20,
	simulation_mode: String = OpeningConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
) -> Dictionary:
	var safe_seed_count: int = maxi(1, int(seeds_per_case))
	var safe_mode: String = OpeningConfigScript.sanitize_simulation_mode(simulation_mode)
	var hero_ids: Array = OpeningHeroRegistryScript.get_hero_ids()
	var map_ids: Array = OpeningMapRegistryScript.get_registered_map_ids()
	var hero_stats: Dictionary = {}
	var mirror_stats: Dictionary = {}
	var performance: Dictionary = {}
	for raw_hero_id in hero_ids:
		var hero_id: String = str(raw_hero_id)
		hero_stats[hero_id] = _empty_score_stats()
		mirror_stats[hero_id] = _empty_score_stats()
		performance[hero_id] = _empty_performance()

	var matches: int = 0
	var invalid_results: int = 0
	var upgrade_choices: int = 0
	var simulator = OpeningSimulatorScript.new()
	for raw_hero_a in hero_ids:
		for raw_hero_b in hero_ids:
			for raw_map_id in map_ids:
				for seed_index in range(safe_seed_count):
					for side_variant in [0, 1]:
						var hero_a: String = str(raw_hero_a)
						var hero_b: String = str(raw_hero_b)
						var result: Dictionary = simulator.simulate_opening(
							hero_a,
							hero_b,
							str(raw_map_id),
							side_variant,
							seed_index + 1,
							safe_mode
						)
						if not bool(result.get("success", false)):
							invalid_results += 1
							continue
						matches += 1
						upgrade_choices += int(result.get("shared_upgrade_choice_count", 0))
						_accumulate_points(result, hero_a, hero_b, hero_stats, mirror_stats)
						_accumulate_performance(result, hero_a, "a", performance)
						_accumulate_performance(result, hero_b, "b", performance)

	var hero_rates: Dictionary = _finalize_stats(hero_stats)
	var mirror_rates: Dictionary = _finalize_stats(mirror_stats)
	var expected_matches: int = hero_ids.size() * hero_ids.size() * map_ids.size() * 2 * safe_seed_count
	var target_evaluation: Dictionary = _evaluate_targets(hero_rates, mirror_rates)
	var report: Dictionary = {
		"audit_id": "b1_opening_strength_rounds_1_to_5",
		"model": "b1_spatial_approximation_with_shared_rules",
		"opening_rounds": OpeningSimulatorScript.OPENING_ROUNDS,
		"upgrades_enabled": false,
		"strongholds_enabled": false,
		"seeds_per_case": safe_seed_count,
		"expected_matches": expected_matches,
		"matches": matches,
		"invalid_results": invalid_results,
		"upgrade_choices": upgrade_choices,
		"hero_rates": hero_rates,
		"mirror_blue_rates": mirror_rates,
		"hero_performance": _finalize_performance(performance),
		"target_evaluation": target_evaluation,
		"balance_targets_met": bool(target_evaluation.get("passed", false)),
		"hard_balance_gate_enabled": false,
	}
	report["passed"] = (
		matches == expected_matches
		and invalid_results == 0
		and upgrade_choices == 0
		and hero_rates.size() == hero_ids.size()
		and mirror_rates.size() == hero_ids.size()
		and (report["hero_performance"] as Dictionary).size() == hero_ids.size()
	)
	return report


func format_summary(report: Dictionary) -> String:
	var lines: Array[String] = [
		"B1 opening audit: matches=%d/%d rounds=%d structural=%s balance_targets=%s hard_gate=%s" % [
			int(report.get("matches", 0)),
			int(report.get("expected_matches", 0)),
			int(report.get("opening_rounds", 0)),
			str(report.get("passed", false)),
			str(report.get("balance_targets_met", false)),
			str(report.get("hard_balance_gate_enabled", false)),
		],
		"hero_rates=%s" % JSON.stringify(report.get("hero_rates", {})),
		"mirror_blue_rates=%s" % JSON.stringify(report.get("mirror_blue_rates", {})),
		"hero_performance=%s" % JSON.stringify(report.get("hero_performance", {})),
	]
	return "\n".join(lines)


func _accumulate_points(
	result: Dictionary,
	hero_a: String,
	hero_b: String,
	hero_stats: Dictionary,
	mirror_stats: Dictionary
) -> void:
	var winner_slot: String = str(result.get("winner_slot", ""))
	var draw: bool = bool(result.get("draw", false))
	_record_score(hero_stats[hero_a] as Dictionary, winner_slot == "a", draw)
	_record_score(hero_stats[hero_b] as Dictionary, winner_slot == "b", draw)
	if hero_a != hero_b:
		return
	var blue_slot: String = "a" if int(result.get("side_variant", 0)) == 0 else "b"
	_record_score(mirror_stats[hero_a] as Dictionary, winner_slot == blue_slot, draw)


func _record_score(stats: Dictionary, won: bool, draw: bool) -> void:
	stats["games"] = int(stats.get("games", 0)) + 1
	if draw:
		stats["draws"] = int(stats.get("draws", 0)) + 1
		stats["points"] = float(stats.get("points", 0.0)) + 0.5
	elif won:
		stats["wins"] = int(stats.get("wins", 0)) + 1
		stats["points"] = float(stats.get("points", 0.0)) + 1.0
	else:
		stats["losses"] = int(stats.get("losses", 0)) + 1


func _empty_performance() -> Dictionary:
	return {
		"appearances": 0,
		"shots_fired": 0.0,
		"chamber_damage_dealt": 0.0,
		"territory_contacts": 0.0,
		"defense_absorbed": 0.0,
		"gate_passes": 0.0,
		"route_rejections": 0.0,
		"virtual_captures": 0.0,
		"ending_territory": 0.0,
	}


func _accumulate_performance(
	result: Dictionary,
	hero_id: String,
	slot: String,
	performance: Dictionary
) -> void:
	var totals: Dictionary = performance[hero_id] as Dictionary
	var slot_metrics: Dictionary = (result.get("slot_metrics", {}) as Dictionary).get(slot, {}) as Dictionary
	totals["appearances"] = int(totals["appearances"]) + 1
	for key in [
		"shots_fired",
		"territory_contacts",
		"defense_absorbed",
		"gate_passes",
		"route_rejections",
		"virtual_captures",
	]:
		totals[key] = float(totals[key]) + float(slot_metrics.get(key, 0.0))
	totals["chamber_damage_dealt"] = float(totals["chamber_damage_dealt"]) + float(
		slot_metrics.get("chamber_damage_dealt_quarters", 0.0)
	) / 4.0
	totals["ending_territory"] = float(totals["ending_territory"]) + float(
		(result.get("territory", {}) as Dictionary).get(slot, 0.0)
	)


func _finalize_performance(raw: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_hero_id in raw.keys():
		var hero_id: String = str(raw_hero_id)
		var totals: Dictionary = raw[raw_hero_id] as Dictionary
		var appearances: float = float(maxi(1, int(totals.get("appearances", 0))))
		result[hero_id] = {
			"appearances": int(totals.get("appearances", 0)),
			"shots_per_match": float(totals.get("shots_fired", 0.0)) / appearances,
			"chamber_damage_per_match": float(totals.get("chamber_damage_dealt", 0.0)) / appearances,
			"territory_contacts_per_match": float(totals.get("territory_contacts", 0.0)) / appearances,
			"defense_absorbed_per_match": float(totals.get("defense_absorbed", 0.0)) / appearances,
			"gate_passes_per_match": float(totals.get("gate_passes", 0.0)) / appearances,
			"route_rejections_per_match": float(totals.get("route_rejections", 0.0)) / appearances,
			"captures_per_match": float(totals.get("virtual_captures", 0.0)) / appearances,
			"ending_territory": float(totals.get("ending_territory", 0.0)) / appearances,
		}
	return result


func _evaluate_targets(hero_rates: Dictionary, mirror_rates: Dictionary) -> Dictionary:
	var failures: Array[String] = []
	for raw_hero_id in hero_rates.keys():
		var hero_id: String = str(raw_hero_id)
		var hero_row: Dictionary = hero_rates[raw_hero_id] as Dictionary
		var rate: float = float(hero_row.get("rate", hero_row.get("point_rate", 0.0)))
		if rate < TARGET_HERO_RATE_MIN or rate > TARGET_HERO_RATE_MAX:
			failures.append("hero_rate:%s:%.2f" % [hero_id, rate])
	for raw_hero_id in mirror_rates.keys():
		var hero_id: String = str(raw_hero_id)
		var mirror_row: Dictionary = mirror_rates[raw_hero_id] as Dictionary
		var rate: float = float(mirror_row.get("rate", mirror_row.get("point_rate", 0.0)))
		if rate < TARGET_MIRROR_BLUE_MIN or rate > TARGET_MIRROR_BLUE_MAX:
			failures.append("mirror_blue:%s:%.2f" % [hero_id, rate])
	return {
		"passed": failures.is_empty(),
		"failures": failures,
		"hero_rate_range": [TARGET_HERO_RATE_MIN, TARGET_HERO_RATE_MAX],
		"mirror_blue_range": [TARGET_MIRROR_BLUE_MIN, TARGET_MIRROR_BLUE_MAX],
	}
