extends CardfrontSharedAiHeroBalanceAudit
class_name CardfrontB1HeroBalanceAudit

const B1AuditConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const B1AuditHeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const B1AuditMapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const B1AuditSimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1ParityMatchSimulator.gd")
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
	var totals: Dictionary = _empty_match_totals()
	var b1_totals: Dictionary = _empty_b1_totals()
	var map_accumulators: Dictionary = {}
	for raw_map_id in map_ids:
		map_accumulators[str(raw_map_id)] = _empty_map_accumulator(hero_ids)

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
						_accumulate_map(result, map_accumulators[str(map_id)] as Dictionary)

	var expected_matches: int = hero_ids.size() * hero_ids.size() * map_ids.size() * 2 * safe_seed_count
	var expected_matches_per_map: int = hero_ids.size() * hero_ids.size() * 2 * safe_seed_count
	var map_reports: Dictionary = _finalize_map_reports(map_accumulators, expected_matches_per_map)
	var report: Dictionary = {
		"audit_id": "b1_route_gate_virtual_defense",
		"b1_model": true,
		"simulation_mode": safe_mode,
		"upgrade_valuation_mode": B1AuditValuePolicyScript.MODE_MARGINAL,
		"hidden_hit_compensation": B1AuditConfigScript.uses_hidden_hit_compensation(safe_mode),
		"resolved_attack_level_cap": B1AuditConfigScript.resolved_attack_level_cap(safe_mode),
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
	var map_reports: Dictionary = report.get("map_reports", {}) as Dictionary
	var map_ids: Array = map_reports.keys()
	map_ids.sort()
	for raw_map_id in map_ids:
		var map_id: String = str(raw_map_id)
		var map_report: Dictionary = map_reports[raw_map_id] as Dictionary
		var pacing: Dictionary = map_report.get("pacing", {}) as Dictionary
		var route: Dictionary = map_report.get("route_metrics", {}) as Dictionary
		lines.append(
			"map %s matches=%d median=%.1f p90=%.1f timeout=%.2f%% blue=%.2f%% gate_pass=%.2f%% river=%.2f%% lane0=%.2f%%" % [
				map_id,
				int(map_report.get("matches", 0)),
				float(pacing.get("median_round", 0.0)),
				float(pacing.get("p90_round", 0.0)),
				float(pacing.get("timeout_rate", 0.0)),
				float(map_report.get("blue_point_rate", 0.0)),
				float(route.get("gate_pass_rate", 0.0)),
				float(route.get("river_reflection_rate", 0.0)),
				float((route.get("lane_share", {}) as Dictionary).get("0", 0.0)),
			]
		)
		lines.append("map %s heroes=%s" % [map_id, JSON.stringify(map_report.get("hero_rates", {}))])
	lines.append("card_by_hero=%s" % JSON.stringify(b1.get("card_by_hero", {})))
	return "\n".join(lines)


func _empty_match_totals() -> Dictionary:
	return {
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


func _empty_b1_totals() -> Dictionary:
	return {
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


func _empty_map_accumulator(hero_ids: Array) -> Dictionary:
	var heroes: Dictionary = {}
	var mirrors: Dictionary = {}
	var matchups: Dictionary = {}
	for raw_hero_id in hero_ids:
		var hero_id: String = str(raw_hero_id)
		heroes[hero_id] = _empty_score_stats()
		mirrors[hero_id] = _empty_score_stats()
	for raw_hero_a in hero_ids:
		for raw_hero_b in hero_ids:
			matchups[_matchup_key(str(raw_hero_a), str(raw_hero_b))] = _empty_score_stats()
	return {
		"hero_stats": heroes,
		"matchup_stats": matchups,
		"mirror_stats": mirrors,
		"rounds": [],
		"totals": _empty_match_totals(),
		"b1_totals": _empty_b1_totals(),
		"blue_games": 0,
		"blue_points": 0.0,
	}


func _accumulate_map(result: Dictionary, accumulator: Dictionary) -> void:
	if not bool(result.get("success", false)):
		return
	var totals: Dictionary = accumulator["totals"] as Dictionary
	var rounds: Array = accumulator["rounds"] as Array
	totals["matches"] = int(totals["matches"]) + 1
	if bool(result.get("timed_out", false)):
		totals["timeouts"] = int(totals["timeouts"]) + 1
	rounds.append(int(result.get("round_count", 0)))
	var hero_a: String = str(result.get("hero_a", ""))
	var hero_b: String = str(result.get("hero_b", ""))
	var winner_slot: String = str(result.get("winner_slot", ""))
	var draw: bool = bool(result.get("draw", false))
	var hero_stats: Dictionary = accumulator["hero_stats"] as Dictionary
	var matchup_stats: Dictionary = accumulator["matchup_stats"] as Dictionary
	var mirror_stats: Dictionary = accumulator["mirror_stats"] as Dictionary
	_add_score(hero_stats[hero_a] as Dictionary, winner_slot == "a", draw)
	_add_score(hero_stats[hero_b] as Dictionary, winner_slot == "b", draw)
	_add_score(matchup_stats[_matchup_key(hero_a, hero_b)] as Dictionary, winner_slot == "a", draw)
	if hero_a == hero_b:
		_add_score(mirror_stats[hero_a] as Dictionary, str(result.get("winner_side", "")) == "blue", draw)
	var metrics: Dictionary = result.get("metrics", {}) as Dictionary
	for key in ["invalid_offers", "shot_count", "chamber_hits", "volleys", "defense_absorbed"]:
		totals[key] = int(totals[key]) + int(metrics.get(key, 0))
	totals["cells_crossed"] = float(totals["cells_crossed"]) + float(metrics.get("cells_crossed", 0.0))
	totals["shared_upgrade_choices"] = int(totals["shared_upgrade_choices"]) + int(result.get("shared_upgrade_choice_count", 0))
	for first_round in (result.get("first_stronghold_round", {}) as Dictionary).values():
		if int(first_round) > 0:
			totals["first_stronghold_sum"] = int(totals["first_stronghold_sum"]) + int(first_round)
			totals["first_stronghold_samples"] = int(totals["first_stronghold_samples"]) + 1
	_accumulate_b1(result, accumulator["b1_totals"] as Dictionary)
	accumulator["blue_games"] = int(accumulator["blue_games"]) + 1
	if draw:
		accumulator["blue_points"] = float(accumulator["blue_points"]) + 0.5
	elif str(result.get("winner_side", "")) == "blue":
		accumulator["blue_points"] = float(accumulator["blue_points"]) + 1.0


func _finalize_map_reports(accumulators: Dictionary, expected_matches_per_map: int) -> Dictionary:
	var reports: Dictionary = {}
	var map_ids: Array = accumulators.keys()
	map_ids.sort()
	for raw_map_id in map_ids:
		var map_id: String = str(raw_map_id)
		var accumulator: Dictionary = accumulators[raw_map_id] as Dictionary
		var totals: Dictionary = accumulator["totals"] as Dictionary
		var b1: Dictionary = accumulator["b1_totals"] as Dictionary
		var blue_games: int = int(accumulator["blue_games"])
		reports[map_id] = {
			"matches": int(totals["matches"]),
			"expected_matches": expected_matches_per_map,
			"hero_rates": _finalize_stats(accumulator["hero_stats"] as Dictionary),
			"matchup_rates": _finalize_stats(accumulator["matchup_stats"] as Dictionary),
			"mirror_blue_rates": _finalize_stats(accumulator["mirror_stats"] as Dictionary),
			"blue_point_rate": 100.0 * float(accumulator["blue_points"]) / float(maxi(1, blue_games)),
			"pacing": _map_pacing_report(accumulator["rounds"] as Array, totals),
			"metrics": _metrics_report(totals),
			"route_metrics": _route_metrics_report(b1, totals),
			"b1_metrics": b1,
		}
	return reports


func _map_pacing_report(rounds: Array, totals: Dictionary) -> Dictionary:
	var sorted_rounds: Array = rounds.duplicate()
	sorted_rounds.sort()
	var count: int = sorted_rounds.size()
	var median_round: float = 0.0
	if count > 0:
		if count % 2 == 0:
			median_round = (float(sorted_rounds[count / 2 - 1]) + float(sorted_rounds[count / 2])) * 0.5
		else:
			median_round = float(sorted_rounds[count / 2])
	var p90_index: int = clampi(ceili(float(count) * 0.9) - 1, 0, maxi(0, count - 1))
	return {
		"median_round": median_round,
		"p90_round": float(sorted_rounds[p90_index]) if count > 0 else 0.0,
		"timeout_rate": 100.0 * float(totals["timeouts"]) / float(maxi(1, int(totals["matches"]))),
	}


func _route_metrics_report(b1: Dictionary, totals: Dictionary) -> Dictionary:
	var gate_passes: int = int(b1.get("gate_passes", 0))
	var gate_reflections: int = int(b1.get("gate_reflections", 0))
	var river_reflections: int = int(b1.get("river_bank_reflections", 0))
	var gate_attempts: int = gate_passes + gate_reflections
	var shot_count: int = int(totals.get("shot_count", 0))
	var lane_traffic: Dictionary = b1.get("lane_traffic", {}) as Dictionary
	var lane_total: float = 0.0
	for value in lane_traffic.values():
		lane_total += float(value)
	var lane_share: Dictionary = {}
	for raw_lane in lane_traffic.keys():
		lane_share[str(raw_lane)] = 100.0 * float(lane_traffic[raw_lane]) / maxf(1.0, lane_total)
	return {
		"gate_pass_rate": 100.0 * float(gate_passes) / float(maxi(1, gate_attempts)),
		"gate_reflection_rate": 100.0 * float(gate_reflections) / float(maxi(1, gate_attempts)),
		"river_reflection_rate": 100.0 * float(river_reflections) / float(maxi(1, shot_count)),
		"route_rejection_rate": 100.0 * float(gate_reflections + river_reflections) / float(maxi(1, shot_count)),
		"captures_per_volley": float(b1.get("virtual_captures", 0)) / float(maxi(1, int(totals.get("volleys", 0)))),
		"recaptures_per_volley": float(b1.get("virtual_recaptures", 0)) / float(maxi(1, int(totals.get("volleys", 0)))),
		"recapture_to_capture_ratio": 100.0 * float(b1.get("virtual_recaptures", 0)) / float(maxi(1, int(b1.get("virtual_captures", 0)))),
		"lane_share": lane_share,
		"gate_state_share": _percentage_share(b1.get("gate_state_crossings", {}) as Dictionary),
		"card_selection_share": _percentage_share(b1.get("card_selections", {}) as Dictionary),
	}


func _percentage_share(values: Dictionary) -> Dictionary:
	var total: float = 0.0
	for value in values.values():
		total += float(value)
	var result: Dictionary = {}
	for raw_key in values.keys():
		result[str(raw_key)] = 100.0 * float(values[raw_key]) / maxf(1.0, total)
	return result


func _all_map_reports_complete(reports: Dictionary, expected_matches_per_map: int) -> bool:
	for raw_report in reports.values():
		var map_report: Dictionary = raw_report as Dictionary
		if int(map_report.get("matches", 0)) != expected_matches_per_map:
			return false
		if int(((map_report.get("metrics", {}) as Dictionary).get("invalid_offers", -1))) != 0:
			return false
		if int(((map_report.get("b1_metrics", {}) as Dictionary).get("gate_passes", 0))) <= 0:
			return false
	return true


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
