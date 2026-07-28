extends CardfrontB1HeroBalanceAudit
class_name CardfrontB1ArchetypeHeroBalanceAudit

const ArchetypeAuditConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const ArchetypeAuditHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const ArchetypeAuditMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const ArchetypeAuditSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1ArchetypeMatchSimulator.gd")
const ArchetypeAuditValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")


func run(
	seeds_per_case: int = ArchetypeAuditConfigScript.FULL_SEEDS_PER_CASE,
	simulation_mode: String = ArchetypeAuditConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
) -> Dictionary:
	var safe_seed_count: int = maxi(1, int(seeds_per_case))
	var safe_mode: String = ArchetypeAuditConfigScript.sanitize_simulation_mode(simulation_mode)
	var hero_ids: Array = ArchetypeAuditHeroRegistryScript.get_hero_ids()
	var map_ids: Array = ArchetypeAuditMapRegistryScript.get_registered_map_ids()
	var hero_stats: Dictionary = {}
	var matchup_stats: Dictionary = {}
	var mirror_stats: Dictionary = {}
	var hero_performance: Dictionary = {}
	for hero_id in hero_ids:
		hero_stats[str(hero_id)] = _empty_score_stats()
		mirror_stats[str(hero_id)] = _empty_score_stats()
		hero_performance[str(hero_id)] = _empty_hero_performance()
	for hero_a in hero_ids:
		for hero_b in hero_ids:
			matchup_stats[_matchup_key(str(hero_a), str(hero_b))] = _empty_score_stats()

	var rounds: Array[int] = []
	var totals: Dictionary = _empty_match_totals()
	var b1_totals: Dictionary = _empty_b1_totals()
	var map_accumulators: Dictionary = {}
	for raw_map_id in map_ids:
		map_accumulators[str(raw_map_id)] = _empty_map_accumulator(hero_ids)

	var simulator = ArchetypeAuditSimulatorScript.new()
	for hero_a in hero_ids:
		for hero_b in hero_ids:
			for map_id in map_ids:
				for seed_index in range(safe_seed_count):
					for side_variant in [0, 1]:
						var result: Dictionary = simulator.simulate(
							str(hero_a),
							str(hero_b),
							str(map_id),
							side_variant,
							seed_index + 1,
							safe_mode
						)
						_accumulate_match(result, hero_stats, matchup_stats, mirror_stats, rounds, totals)
						_accumulate_b1(result, b1_totals)
						_accumulate_map(result, map_accumulators[str(map_id)] as Dictionary)
						_accumulate_hero_performance(result, str(hero_a), "a", hero_performance)
						_accumulate_hero_performance(result, str(hero_b), "b", hero_performance)

	var expected_matches: int = hero_ids.size() * hero_ids.size() * map_ids.size() * 2 * safe_seed_count
	var expected_matches_per_map: int = hero_ids.size() * hero_ids.size() * 2 * safe_seed_count
	var map_reports: Dictionary = _finalize_map_reports(map_accumulators, expected_matches_per_map)
	var report: Dictionary = {
		"audit_id": "b1_archetype_route_gate_virtual_defense",
		"b1_model": true,
		"archetype_composition_model": true,
		"simulation_mode": safe_mode,
		"upgrade_valuation_mode": ArchetypeAuditValuePolicyScript.MODE_MARGINAL,
		"hidden_hit_compensation": ArchetypeAuditConfigScript.uses_hidden_hit_compensation(safe_mode),
		"resolved_attack_level_cap": ArchetypeAuditConfigScript.resolved_attack_level_cap(safe_mode),
		"seeds_per_case": safe_seed_count,
		"expected_matches": expected_matches,
		"expected_matches_per_map": expected_matches_per_map,
		"matches": int(totals["matches"]),
		"hero_rates": _finalize_stats(hero_stats),
		"matchup_rates": _finalize_stats(matchup_stats),
		"mirror_blue_rates": _finalize_stats(mirror_stats),
		"pacing": _pacing_report(rounds, totals),
		"metrics": _metrics_report(totals),
		"b1_metrics": b1_totals,
		"hero_performance": _finalize_hero_performance(hero_performance),
		"map_reports": map_reports,
	}
	report["passed"] = (
		int(report["matches"]) == expected_matches
		and int(b1_totals["actual_side_calls"]) == expected_matches
		and int((report["metrics"] as Dictionary)["invalid_offers"]) == 0
		and int(b1_totals["gate_passes"]) > 0
		and int(b1_totals["shared_upgrade_choice_count"]) > 0
		and (b1_totals["position_signatures"] as Dictionary).size() == map_ids.size() * 2
		and (b1_totals["card_by_hero"] as Dictionary).size() == hero_ids.size()
		and map_reports.size() == map_ids.size()
		and _all_map_reports_complete(map_reports, expected_matches_per_map)
	)
	return report


func _empty_hero_performance() -> Dictionary:
	return {
		"appearances": 0,
		"shots_fired": 0.0,
		"territory_contacts": 0.0,
		"defense_absorbed": 0.0,
		"gate_passes": 0.0,
		"route_rejections": 0.0,
		"virtual_captures": 0.0,
		"virtual_recaptures": 0.0,
		"chamber_damage_dealt_quarters": 0.0,
	}


func _accumulate_hero_performance(
	result: Dictionary,
	hero_id: String,
	slot: String,
	all_performance: Dictionary
) -> void:
	var totals: Dictionary = all_performance[hero_id] as Dictionary
	var slot_metrics: Dictionary = (result.get("slot_metrics", {}) as Dictionary).get(slot, {}) as Dictionary
	totals["appearances"] = int(totals["appearances"]) + 1
	for key in [
		"shots_fired",
		"territory_contacts",
		"defense_absorbed",
		"gate_passes",
		"route_rejections",
		"virtual_captures",
		"virtual_recaptures",
		"chamber_damage_dealt_quarters",
	]:
		totals[key] = float(totals[key]) + float(slot_metrics.get(key, 0.0))


func _finalize_hero_performance(raw: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_hero_id in raw.keys():
		var hero_id: String = str(raw_hero_id)
		var totals: Dictionary = raw[raw_hero_id] as Dictionary
		var appearances: float = float(maxi(1, int(totals.get("appearances", 0))))
		result[hero_id] = {
			"appearances": int(totals.get("appearances", 0)),
			"shots_per_match": float(totals.get("shots_fired", 0.0)) / appearances,
			"territory_contacts_per_match": float(totals.get("territory_contacts", 0.0)) / appearances,
			"defense_absorbed_per_match": float(totals.get("defense_absorbed", 0.0)) / appearances,
			"gate_passes_per_match": float(totals.get("gate_passes", 0.0)) / appearances,
			"route_rejections_per_match": float(totals.get("route_rejections", 0.0)) / appearances,
			"captures_per_match": float(totals.get("virtual_captures", 0.0)) / appearances,
			"recaptures_per_match": float(totals.get("virtual_recaptures", 0.0)) / appearances,
			"chamber_damage_per_match": float(totals.get("chamber_damage_dealt_quarters", 0.0)) / appearances / 4.0,
		}
	return result
