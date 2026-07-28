extends RefCounted
class_name CardfrontB1ArchetypeGrowthEvaluator

const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

const LEAD_MIN: float = 20.0
const LEAD_MAX: float = 35.0
const FINAL_RATE_MIN: float = 47.0
const FINAL_RATE_MAX: float = 53.0


static func evaluate(report: Dictionary) -> Dictionary:
	var performance: Dictionary = report.get("hero_performance", {}) as Dictionary
	var card_by_hero: Dictionary = ((report.get("b1_metrics", {}) as Dictionary).get("card_by_hero", {}) as Dictionary)
	var hero_rates: Dictionary = report.get("hero_rates", {}) as Dictionary
	var indicators: Dictionary = {
		HeroRegistryScript.HERO_RAPID_GUNNER: {
			"shot_volume": _lead(
				performance,
				HeroRegistryScript.HERO_RAPID_GUNNER,
				"shots_per_match"
			),
			"route_pressure": _lead(
				performance,
				HeroRegistryScript.HERO_RAPID_GUNNER,
				"territory_contacts_per_match"
			),
		},
		HeroRegistryScript.HERO_FORTIFICATION_ENGINEER: {
			"defense_absorption": _lead(
				performance,
				HeroRegistryScript.HERO_FORTIFICATION_ENGINEER,
				"defense_absorbed_per_match"
			),
			"bridgehead_hold": _lead(
				performance,
				HeroRegistryScript.HERO_FORTIFICATION_ENGINEER,
				"recaptures_per_match"
			),
			"repair_selection_share": _card_selection_share(
				card_by_hero,
				HeroRegistryScript.HERO_FORTIFICATION_ENGINEER,
				UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR
			),
		},
		HeroRegistryScript.HERO_BALANCED_COMMANDER: {
			"rarity_selection_share": _card_selection_share(
				card_by_hero,
				HeroRegistryScript.HERO_BALANCED_COMMANDER,
				UpgradeManifestScript.UPGRADE_RARITY_PLUS_1
			),
			"echo_selection_share": _card_selection_share(
				card_by_hero,
				HeroRegistryScript.HERO_BALANCED_COMMANDER,
				UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE
			),
			"build_diversity": _selection_diversity(
				card_by_hero,
				HeroRegistryScript.HERO_BALANCED_COMMANDER
			),
		},
	}
	var final_rate_failures: Array[String] = []
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		var row: Dictionary = hero_rates.get(hero_id, {}) as Dictionary
		var rate: float = float(row.get("rate", 0.0))
		if rate < FINAL_RATE_MIN or rate > FINAL_RATE_MAX:
			final_rate_failures.append("%s:%.2f" % [hero_id, rate])
	return {
		"indicator_target_range": [LEAD_MIN, LEAD_MAX],
		"final_rate_target_range": [FINAL_RATE_MIN, FINAL_RATE_MAX],
		"indicators": indicators,
		"final_rate_failures": final_rate_failures,
		"hard_gate_enabled": false,
	}


static func format_summary(evaluation: Dictionary) -> String:
	return "B1 archetype growth diagnostic hard_gate=%s indicators=%s final_rate_failures=%s" % [
		str(evaluation.get("hard_gate_enabled", false)),
		JSON.stringify(evaluation.get("indicators", {})),
		JSON.stringify(evaluation.get("final_rate_failures", [])),
	]


static func _lead(performance: Dictionary, hero_id: String, key: String) -> Dictionary:
	var hero_value: float = float((performance.get(hero_id, {}) as Dictionary).get(key, 0.0))
	var comparison_sum: float = 0.0
	var comparison_count: int = 0
	for raw_other_id in HeroRegistryScript.get_hero_ids():
		var other_id: String = str(raw_other_id)
		if other_id == hero_id:
			continue
		comparison_sum += float((performance.get(other_id, {}) as Dictionary).get(key, 0.0))
		comparison_count += 1
	var baseline: float = comparison_sum / float(maxi(1, comparison_count))
	var lead_percent: float = 100.0 * (hero_value - baseline) / maxf(0.001, baseline)
	return {
		"value": hero_value,
		"peer_average": baseline,
		"lead_percent": lead_percent,
		"in_target_range": lead_percent >= LEAD_MIN and lead_percent <= LEAD_MAX,
	}


static func _card_selection_share(card_by_hero: Dictionary, hero_id: String, card_id: String) -> float:
	var selections: Dictionary = ((card_by_hero.get(hero_id, {}) as Dictionary).get("selections", {}) as Dictionary)
	var total: float = 0.0
	for value in selections.values():
		total += float(value)
	return 100.0 * float(selections.get(card_id, 0.0)) / maxf(1.0, total)


static func _selection_diversity(card_by_hero: Dictionary, hero_id: String) -> float:
	var selections: Dictionary = ((card_by_hero.get(hero_id, {}) as Dictionary).get("selections", {}) as Dictionary)
	var total: float = 0.0
	for value in selections.values():
		total += float(value)
	if total <= 0.0:
		return 0.0
	var entropy: float = 0.0
	for value in selections.values():
		var share: float = float(value) / total
		if share > 0.0:
			entropy -= share * log(share)
	return entropy / maxf(0.001, log(float(maxi(2, selections.size()))))
