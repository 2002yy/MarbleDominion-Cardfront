extends CardfrontSharedAiHeroBalanceAudit
class_name CardfrontB1HeroBalanceAudit

const B1AuditConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const B1AuditHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const B1AuditMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const B1AuditSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1BalanceMatchSimulator.gd")
const B1AuditValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")


func run(
	seeds_per_case: int = B1AuditConfigScript.FULL_SEEDS_PER_CASE,
	simulation_mode: String = B1AuditConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
) -> Dictionary:
	var safe_seed_count: int = maxi(1, int(seeds_per_case))
	var safe_mode: String = B1AuditConfigScript.sanitize_simulation_mode(simulation_mode)
	var hero_ids: Array = B1AuditHeroRegistryScript.get_hero_ids()
	var map_ids: Array = B1AuditMapRegistryScript.get_registered_map_ids()
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
		"shared_upgrade_choices": 0,
	}
	var b1_totals: Dictionary = {
		"actual_side_calls": 0,
		"gate_passes": 0,
		"gate_reflections": 0,
		"river_bank_reflections": 0,
		"virtual_captures": 0,
		"virtual_recaptures": 0,
		"shared_upgrade_choice_count": 0,
		"gate_state_crossings": {},
		"lane_traffic": {},
		"card_appearances": {},
		"card_selections": {},
		"card_applications": {},
		"card_waste": {},
		"card_by_hero": {},
		"position_signatures": {},
	}
	var simulator = B1AuditSimulatorScript.new()
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

	var expected_matches: int = hero_ids.size() * hero_ids.size() * map_ids.size() * 2 * safe_seed_count
	var report: Dictionary = {
		"audit_id": "b1_route_gate_virtual_defense",
		"b1_model": true,
		"simulation_mode": safe_mode,
		"upgrade_valuation_mode": B1AuditValuePolicyScript.MODE_MARGINAL,
		"hidden_hit_compensation": B1AuditConfigScript.uses_hidden_hit_compensation(safe_mode),
		"resolved_attack_level_cap": B1AuditConfigScript.resolved_attack_level_cap(safe_mode),
		"seeds_per_case": safe_seed_count,
		"expected_matches": expected_matches,
		"matches": int(totals["matches"]),
		"hero_rates": _finalize_stats(hero_stats),
		"matchup_rates": _finalize_stats(matchup_stats),
		"mirror_blue_rates": _finalize_stats(mirror_stats),
		"pacing": _pacing_report(rounds, totals),
		"metrics": _metrics_report(totals),
		"b1_metrics": b1_totals,
	}
	report["passed"] = (
		int(report["matches"]) == expected_matches
		and int(b1_totals["actual_side_calls"]) == expected_matches
		and int((report["metrics"] as Dictionary)["invalid_offers"]) == 0
		and int(b1_totals["gate_passes"]) > 0
		and int(b1_totals["shared_upgrade_choice_count"]) > 0
		and (b1_totals["position_signatures"] as Dictionary).size() == map_ids.size() * 2
		and (b1_totals["card_by_hero"] as Dictionary).size() == hero_ids.size()
	)
	return report


func format_b1_summary(report: Dictionary) -> String:
	var lines: Array[String] = [format_summary(report)]
	var b1: Dictionary = report.get("b1_metrics", {}) as Dictionary
	lines.append(
		"B1 side_calls=%d gate_passes=%d gate_reflections=%d river_reflections=%d captures=%d recaptures=%d shared_choices=%d" % [
			int(b1.get("actual_side_calls", 0)),
			int(b1.get("gate_passes", 0)),
			int(b1.get("gate_reflections", 0)),
			int(b1.get("river_bank_reflections", 0)),
			int(b1.get("virtual_captures", 0)),
			int(b1.get("virtual_recaptures", 0)),
			int(b1.get("shared_upgrade_choice_count", 0)),
		]
	)
	lines.append("gate_states=%s lane_traffic=%s" % [
		JSON.stringify(b1.get("gate_state_crossings", {})),
		JSON.stringify(b1.get("lane_traffic", {})),
	])
	lines.append("card_by_hero=%s" % JSON.stringify(b1.get("card_by_hero", {})))
	return "\n".join(lines)


func _accumulate_b1(result: Dictionary, totals: Dictionary) -> void:
	if not bool(result.get("success", false)):
		return
	totals["actual_side_calls"] = int(totals["actual_side_calls"]) + 1
	totals["shared_upgrade_choice_count"] = int(totals["shared_upgrade_choice_count"]) + int(result.get("shared_upgrade_choice_count", 0))
	var signature: String = str(result.get("position_signature", ""))
	if signature != "":
		_increment_nested(totals["position_signatures"] as Dictionary, signature, 1.0)
	var metrics: Dictionary = result.get("metrics", {}) as Dictionary
	for key in ["gate_passes", "gate_reflections", "river_bank_reflections", "virtual_captures", "virtual_recaptures"]:
		totals[key] = int(totals[key]) + int(metrics.get(key, 0))
	_merge_numeric(totals["gate_state_crossings"] as Dictionary, metrics.get("gate_state_crossings", {}) as Dictionary)
	_merge_numeric(totals["lane_traffic"] as Dictionary, metrics.get("lane_traffic", {}) as Dictionary)
	var cards: Dictionary = result.get("card_metrics", {}) as Dictionary
	_merge_numeric(totals["card_appearances"] as Dictionary, cards.get("appearances", {}) as Dictionary)
	_merge_numeric(totals["card_selections"] as Dictionary, cards.get("selections", {}) as Dictionary)
	_merge_numeric(totals["card_applications"] as Dictionary, cards.get("applications", {}) as Dictionary)
	_merge_numeric(totals["card_waste"] as Dictionary, cards.get("wasted_units", {}) as Dictionary)
	_merge_hero_card_metrics(totals["card_by_hero"] as Dictionary, cards.get("by_hero", {}) as Dictionary)


func _merge_hero_card_metrics(target: Dictionary, source: Dictionary) -> void:
	for raw_hero_id in source.keys():
		var hero_id: String = str(raw_hero_id)
		if not target.has(hero_id):
			target[hero_id] = {
				"appearances": {},
				"selections": {},
				"applications": {},
				"wasted_units": {},
			}
		var target_hero: Dictionary = target[hero_id] as Dictionary
		var source_hero: Dictionary = source[raw_hero_id] as Dictionary
		for category in ["appearances", "selections", "applications", "wasted_units"]:
			var target_category: Dictionary = target_hero.get(category, {}) as Dictionary
			_merge_numeric(target_category, source_hero.get(category, {}) as Dictionary)
			target_hero[category] = target_category


func _merge_numeric(target: Dictionary, source: Dictionary) -> void:
	for raw_key in source.keys():
		_increment_nested(target, str(raw_key), float(source[raw_key]))


func _increment_nested(target: Dictionary, key: String, amount: float) -> void:
	var current = target.get(key, 0)
	if current is int and is_equal_approx(amount, roundf(amount)):
		target[key] = int(current) + roundi(amount)
	else:
		target[key] = float(current) + amount
