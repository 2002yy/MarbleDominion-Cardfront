extends RefCounted
class_name CardfrontB1DeckCandidateAudit

const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const SimulatorScript = preload("res://scripts/cardfront/simulation/CardfrontB1DeckMatchSimulator.gd")

const SCENARIOS: Dictionary = {
	"core_all": {
		HeroRegistryScript.HERO_BALANCED_COMMANDER: DeckRegistryScript.DECK_CORE_TACTICS,
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: DeckRegistryScript.DECK_CORE_TACTICS,
		HeroRegistryScript.HERO_RAPID_GUNNER: DeckRegistryScript.DECK_CORE_TACTICS,
	},
	"engineer_fortification_only": {
		HeroRegistryScript.HERO_BALANCED_COMMANDER: DeckRegistryScript.DECK_CORE_TACTICS,
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: DeckRegistryScript.DECK_FORTIFICATION_CORPS,
		HeroRegistryScript.HERO_RAPID_GUNNER: DeckRegistryScript.DECK_CORE_TACTICS,
	},
	"recommended_decks": {
		HeroRegistryScript.HERO_BALANCED_COMMANDER: DeckRegistryScript.DECK_CORE_TACTICS,
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: DeckRegistryScript.DECK_FORTIFICATION_CORPS,
		HeroRegistryScript.HERO_RAPID_GUNNER: DeckRegistryScript.DECK_BARRAGE_CONTROL,
	},
}


func run(seeds_per_case: int = 20) -> Dictionary:
	var safe_seeds: int = maxi(1, int(seeds_per_case))
	var reports: Dictionary = {}
	var scenario_ids: Array = SCENARIOS.keys()
	scenario_ids.sort()
	scenario_ids.erase("core_all")
	scenario_ids.push_front("core_all")
	for raw_scenario_id in scenario_ids:
		var scenario_id: String = str(raw_scenario_id)
		reports[scenario_id] = _run_scenario(
			scenario_id,
			SCENARIOS[scenario_id] as Dictionary,
			safe_seeds
		)
	var baseline_rates: Dictionary = (reports.get("core_all", {}) as Dictionary).get("hero_rates", {}) as Dictionary
	for raw_scenario_id in reports.keys():
		var scenario: Dictionary = reports[raw_scenario_id] as Dictionary
		scenario["hero_rate_delta_vs_core"] = _rate_delta(
			scenario.get("hero_rates", {}) as Dictionary,
			baseline_rates
		)
	return {
		"audit_id": "b1_selectable_deck_candidates",
		"seeds_per_case": safe_seeds,
		"scenario_count": reports.size(),
		"matches_per_scenario": 54 * safe_seeds,
		"total_matches": reports.size() * 54 * safe_seeds,
		"scenarios": reports,
		"ranked_by_balance_error": _rank_scenarios(reports),
		"boundary": "candidate_only_not_live_default_not_b1_final",
	}


func format_summary(report: Dictionary) -> String:
	var lines: Array[String] = [
		"B1 selectable deck candidate audit seeds=%d scenarios=%d total_matches=%d" % [
			int(report.get("seeds_per_case", 0)),
			int(report.get("scenario_count", 0)),
			int(report.get("total_matches", 0)),
		],
	]
	for raw_entry in report.get("ranked_by_balance_error", []) as Array:
		var entry: Dictionary = raw_entry as Dictionary
		var scenario_id: String = str(entry.get("scenario_id", ""))
		var scenario: Dictionary = (report.get("scenarios", {}) as Dictionary).get(scenario_id, {}) as Dictionary
		lines.append(
			"scenario %s error=%.2f spread=%.2f rates=%s delta=%s median=%.1f p90=%.1f timeout=%.2f%% invalid=%d" % [
				scenario_id,
				float(scenario.get("balance_error", 0.0)),
				float(scenario.get("hero_rate_spread", 0.0)),
				JSON.stringify(scenario.get("hero_rates", {})),
				JSON.stringify(scenario.get("hero_rate_delta_vs_core", {})),
				float((scenario.get("pacing", {}) as Dictionary).get("median_round", 0.0)),
				float((scenario.get("pacing", {}) as Dictionary).get("p90_round", 0.0)),
				float((scenario.get("pacing", {}) as Dictionary).get("timeout_rate", 0.0)),
				int(scenario.get("invalid_offers", 0)),
			]
		)
		var health: Dictionary = scenario.get("card_health_by_hero", {}) as Dictionary
		for raw_hero_id in HeroRegistryScript.get_hero_ids():
			var hero_id: String = str(raw_hero_id)
			var hero_health: Dictionary = health.get(hero_id, {}) as Dictionary
			lines.append(
				"  hero %s deck=%s selected=%d diversity=%d top2=%.2f%% new=%s" % [
					hero_id,
					str((scenario.get("deck_by_hero", {}) as Dictionary).get(hero_id, "")),
					int(hero_health.get("total_selections", 0)),
					int(hero_health.get("selected_card_count", 0)),
					float(hero_health.get("top_two_concentration", 0.0)),
					JSON.stringify(hero_health.get("candidate_card_selections", {})),
				]
			)
	return "\n".join(lines)


func _run_scenario(
	scenario_id: String,
	deck_by_hero: Dictionary,
	seeds_per_case: int
) -> Dictionary:
	var hero_ids: Array = HeroRegistryScript.get_hero_ids()
	var map_ids: Array = MapRegistryScript.get_registered_map_ids()
	var hero_stats: Dictionary = {}
	var card_appearances: Dictionary = {}
	var card_selections: Dictionary = {}
	for raw_hero_id in hero_ids:
		var hero_id: String = str(raw_hero_id)
		hero_stats[hero_id] = _empty_stats()
		card_appearances[hero_id] = {}
		card_selections[hero_id] = {}
	var rounds: Array[int] = []
	var timeouts: int = 0
	var invalid_offers: int = 0
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
						var result: Dictionary = simulator.simulate_with_decks(
							hero_a,
							hero_b,
							map_id,
							side_variant,
							seed_index + 1,
							str(deck_by_hero.get(hero_a, DeckRegistryScript.DEFAULT_DECK_ID)),
							str(deck_by_hero.get(hero_b, DeckRegistryScript.DEFAULT_DECK_ID)),
							ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
						)
						if not bool(result.get("success", false)):
							continue
						matches += 1
						rounds.append(int(result.get("round_count", 0)))
						if bool(result.get("timed_out", false)):
							timeouts += 1
						invalid_offers += int((result.get("metrics", {}) as Dictionary).get("invalid_offers", 0))
						var winner_slot: String = str(result.get("winner_slot", ""))
						var draw: bool = bool(result.get("draw", false))
						_add_score(hero_stats[hero_a] as Dictionary, winner_slot == "a", draw)
						_add_score(hero_stats[hero_b] as Dictionary, winner_slot == "b", draw)
						_accumulate_card_metrics(
							result.get("card_metrics", {}) as Dictionary,
							card_appearances,
							card_selections
						)
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
	var card_health: Dictionary = {}
	for raw_hero_id in hero_ids:
		var hero_id: String = str(raw_hero_id)
		card_health[hero_id] = _card_health(
			card_appearances[hero_id] as Dictionary,
			card_selections[hero_id] as Dictionary
		)
	return {
		"scenario_id": scenario_id,
		"deck_by_hero": deck_by_hero.duplicate(true),
		"matches": matches,
		"expected_matches": 54 * seeds_per_case,
		"hero_rates": hero_rates,
		"hero_rate_spread": _spread(rate_values),
		"balance_error": balance_error,
		"pacing": _pacing(rounds, timeouts, matches),
		"invalid_offers": invalid_offers,
		"card_health_by_hero": card_health,
	}


func _accumulate_card_metrics(
	card_metrics: Dictionary,
	appearance_target: Dictionary,
	selection_target: Dictionary
) -> void:
	var by_hero: Dictionary = card_metrics.get("by_hero", {}) as Dictionary
	for raw_hero_id in by_hero.keys():
		var hero_id: String = str(raw_hero_id)
		if not appearance_target.has(hero_id):
			appearance_target[hero_id] = {}
			selection_target[hero_id] = {}
		var hero_metrics: Dictionary = by_hero[raw_hero_id] as Dictionary
		_merge_counts(appearance_target[hero_id] as Dictionary, hero_metrics.get("appearances", {}) as Dictionary)
		_merge_counts(selection_target[hero_id] as Dictionary, hero_metrics.get("selections", {}) as Dictionary)


func _merge_counts(target: Dictionary, source: Dictionary) -> void:
	for raw_key in source.keys():
		var key: String = str(raw_key)
		target[key] = int(target.get(key, 0)) + int(source.get(raw_key, 0))


func _card_health(appearances: Dictionary, selections: Dictionary) -> Dictionary:
	var ranked: Array = []
	var total: int = 0
	var selected_count: int = 0
	for raw_upgrade_id in selections.keys():
		var upgrade_id: String = str(raw_upgrade_id)
		var count: int = maxi(0, int(selections.get(raw_upgrade_id, 0)))
		total += count
		if count > 0:
			selected_count += 1
		ranked.append({"upgrade_id": upgrade_id, "count": count})
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("count", 0)) > int(right.get("count", 0))
	)
	var top_two: int = 0
	for index in range(mini(2, ranked.size())):
		top_two += int((ranked[index] as Dictionary).get("count", 0))
	var candidate_selections: Dictionary = {}
	for upgrade_id in [
		ManifestScript.UPGRADE_SIEGE_CALIBRATION,
		ManifestScript.UPGRADE_SUPPRESSION_SCREEN,
		ManifestScript.UPGRADE_REPAIR_UNITS,
		ManifestScript.UPGRADE_FIRE_CONTROL_BEACON,
		ManifestScript.UPGRADE_INTERCEPTOR_TOWER,
		ManifestScript.UPGRADE_BUILDING_VOLLEY,
		ManifestScript.UPGRADE_HEAVY_CHARGE,
		ManifestScript.UPGRADE_ARMORED_GUARD,
	]:
		candidate_selections[upgrade_id] = int(selections.get(upgrade_id, 0))
	return {
		"total_appearances": _sum_counts(appearances),
		"total_selections": total,
		"selected_card_count": selected_count,
		"top_two_concentration": 100.0 * float(top_two) / float(maxi(1, total)),
		"ranked_selections": ranked,
		"candidate_card_selections": candidate_selections,
	}


func _sum_counts(values: Dictionary) -> int:
	var total: int = 0
	for value in values.values():
		total += maxi(0, int(value))
	return total


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


func _rate_delta(candidate: Dictionary, baseline: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		result[hero_id] = float(candidate.get(hero_id, 0.0)) - float(baseline.get(hero_id, 0.0))
	return result


func _rank_scenarios(reports: Dictionary) -> Array:
	var ranked: Array = []
	for raw_scenario_id in reports.keys():
		var scenario: Dictionary = reports[raw_scenario_id] as Dictionary
		ranked.append({
			"scenario_id": str(raw_scenario_id),
			"balance_error": float(scenario.get("balance_error", INF)),
			"hero_rate_spread": float(scenario.get("hero_rate_spread", INF)),
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
	var minimum: float = values[0]
	var maximum: float = values[0]
	for value in values:
		minimum = minf(minimum, value)
		maximum = maxf(maximum, value)
	return maximum - minimum
