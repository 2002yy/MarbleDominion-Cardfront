extends RefCounted
class_name CardfrontB1NumericDiagnosis

const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")

const HERO_BALANCED_MIN: float = 45.0
const HERO_BALANCED_MAX: float = 55.0
const HERO_SEVERE_MIN: float = 35.0
const HERO_SEVERE_MAX: float = 65.0
const DEAD_CARD_MIN_APPEARANCES: int = 100
const NEAR_DEAD_SELECTION_RATE: float = 0.5
const DOMINANT_CARD_SHARE: float = 35.0
const CONCENTRATED_TOP_TWO_SHARE: float = 75.0


static func analyze(report: Dictionary) -> Dictionary:
	var hero_balance: Dictionary = _hero_balance(report)
	var card_health: Dictionary = _card_health(report)
	var flags: Array[String] = []
	var hero_rates: Array[float] = []
	for raw_hero_id in hero_balance.keys():
		var hero_id: String = str(raw_hero_id)
		var hero: Dictionary = hero_balance[raw_hero_id] as Dictionary
		var rate: float = float(hero.get("overall_rate", 0.0))
		hero_rates.append(rate)
		var classification: String = str(hero.get("classification", ""))
		if classification != "balanced":
			flags.append("hero:%s:%s:%.2f" % [hero_id, classification, rate])
		if float(hero.get("map_spread", 0.0)) > 8.0:
			flags.append("hero_map_spread:%s:%.2f" % [hero_id, float(hero.get("map_spread", 0.0))])
	for raw_hero_id in card_health.keys():
		var hero_id: String = str(raw_hero_id)
		var cards: Dictionary = card_health[raw_hero_id] as Dictionary
		for raw_card_id in cards.get("dead_cards", []) as Array:
			flags.append("dead_card:%s:%s" % [hero_id, str(raw_card_id)])
		if float(cards.get("top_two_concentration", 0.0)) >= CONCENTRATED_TOP_TWO_SHARE:
			flags.append("concentrated_build:%s:%.2f" % [hero_id, float(cards.get("top_two_concentration", 0.0))])
	var hero_rate_spread: float = 0.0
	if not hero_rates.is_empty():
		hero_rates.sort()
		hero_rate_spread = hero_rates[hero_rates.size() - 1] - hero_rates[0]
	return {
		"hero_balance": hero_balance,
		"hero_rate_spread": hero_rate_spread,
		"card_health": card_health,
		"global_card_health": _global_card_health(report),
		"flags": flags,
		"requires_balance_work": hero_rate_spread > 10.0 or not flags.is_empty(),
	}


static func format_summary(diagnosis: Dictionary) -> String:
	var lines: Array[String] = [
		"B1 numeric diagnosis hero_spread=%.2f requires_balance_work=%s" % [
			float(diagnosis.get("hero_rate_spread", 0.0)),
			str(bool(diagnosis.get("requires_balance_work", false))),
		],
	]
	var hero_balance: Dictionary = diagnosis.get("hero_balance", {}) as Dictionary
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		var hero: Dictionary = hero_balance.get(hero_id, {}) as Dictionary
		var worst: Dictionary = hero.get("worst_matchup", {}) as Dictionary
		var best: Dictionary = hero.get("best_matchup", {}) as Dictionary
		lines.append(
			"hero %s rate=%.2f class=%s maps=%s spread=%.2f worst=%s:%.2f best=%s:%.2f" % [
				hero_id,
				float(hero.get("overall_rate", 0.0)),
				str(hero.get("classification", "")),
				JSON.stringify(hero.get("map_rates", {})),
				float(hero.get("map_spread", 0.0)),
				str(worst.get("opponent_id", "")),
				float(worst.get("rate", 0.0)),
				str(best.get("opponent_id", "")),
				float(best.get("rate", 0.0)),
			]
		)
	var card_health: Dictionary = diagnosis.get("card_health", {}) as Dictionary
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		var cards: Dictionary = card_health.get(hero_id, {}) as Dictionary
		lines.append(
			"cards %s top2=%.2f dead=%s near_dead=%s top=%s" % [
				hero_id,
				float(cards.get("top_two_concentration", 0.0)),
				JSON.stringify(cards.get("dead_cards", [])),
				JSON.stringify(cards.get("near_dead_cards", [])),
				JSON.stringify(cards.get("top_cards", [])),
			]
		)
	lines.append("global_cards=%s" % JSON.stringify(diagnosis.get("global_card_health", {})))
	lines.append("flags=%s" % JSON.stringify(diagnosis.get("flags", [])))
	return "\n".join(lines)


static func _hero_balance(report: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var overall: Dictionary = report.get("hero_rates", {}) as Dictionary
	var matchups: Dictionary = report.get("matchup_rates", {}) as Dictionary
	var map_reports: Dictionary = report.get("map_reports", {}) as Dictionary
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		var rate: float = float((overall.get(hero_id, {}) as Dictionary).get("rate", 0.0))
		var map_rates: Dictionary = {}
		var map_values: Array[float] = []
		for raw_map_id in map_reports.keys():
			var map_id: String = str(raw_map_id)
			var map_report: Dictionary = map_reports[raw_map_id] as Dictionary
			var map_rate: float = float(((map_report.get("hero_rates", {}) as Dictionary).get(hero_id, {}) as Dictionary).get("rate", 0.0))
			map_rates[map_id] = map_rate
			map_values.append(map_rate)
		var direct_matchups: Dictionary = {}
		for raw_opponent_id in HeroRegistryScript.get_hero_ids():
			var opponent_id: String = str(raw_opponent_id)
			if opponent_id == hero_id:
				continue
			var key: String = "%s|%s" % [hero_id, opponent_id]
			direct_matchups[opponent_id] = float((matchups.get(key, {}) as Dictionary).get("rate", 0.0))
		result[hero_id] = {
			"overall_rate": rate,
			"classification": _hero_classification(rate),
			"map_rates": map_rates,
			"map_spread": _spread(map_values),
			"matchup_rates": direct_matchups,
			"worst_matchup": _extreme_matchup(direct_matchups, false),
			"best_matchup": _extreme_matchup(direct_matchups, true),
		}
	return result


static func _card_health(report: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var global_b1: Dictionary = report.get("b1_metrics", {}) as Dictionary
	var by_hero: Dictionary = global_b1.get("card_by_hero", {}) as Dictionary
	var map_reports: Dictionary = report.get("map_reports", {}) as Dictionary
	for raw_hero_id in HeroRegistryScript.get_hero_ids():
		var hero_id: String = str(raw_hero_id)
		var hero_metrics: Dictionary = by_hero.get(hero_id, {}) as Dictionary
		var summary: Dictionary = _card_summary(hero_metrics)
		var map_builds: Dictionary = {}
		for raw_map_id in map_reports.keys():
			var map_id: String = str(raw_map_id)
			var map_report: Dictionary = map_reports[raw_map_id] as Dictionary
			var map_by_hero: Dictionary = ((map_report.get("b1_metrics", {}) as Dictionary).get("card_by_hero", {}) as Dictionary)
			map_builds[map_id] = _card_summary(map_by_hero.get(hero_id, {}) as Dictionary)
		summary["map_builds"] = map_builds
		result[hero_id] = summary
	return result


static func _global_card_health(report: Dictionary) -> Dictionary:
	var b1: Dictionary = report.get("b1_metrics", {}) as Dictionary
	return _card_summary({
		"appearances": b1.get("card_appearances", {}),
		"selections": b1.get("card_selections", {}),
		"applications": b1.get("card_applications", {}),
		"wasted_units": b1.get("card_waste", {}),
	})


static func _card_summary(metrics: Dictionary) -> Dictionary:
	var appearances: Dictionary = metrics.get("appearances", {}) as Dictionary
	var selections: Dictionary = metrics.get("selections", {}) as Dictionary
	var applications: Dictionary = metrics.get("applications", {}) as Dictionary
	var wasted_units: Dictionary = metrics.get("wasted_units", {}) as Dictionary
	var total_selections: float = _sum_values(selections)
	var per_card: Dictionary = {}
	var ranked: Array = []
	var dead_cards: Array[String] = []
	var near_dead_cards: Array[String] = []
	for raw_card_id in UpgradeManifestScript.get_upgrade_ids():
		var card_id: String = str(raw_card_id)
		var appearance_count: float = float(appearances.get(card_id, 0))
		var selection_count: float = float(selections.get(card_id, 0))
		var application_count: float = float(applications.get(card_id, 0))
		var wasted: float = float(wasted_units.get(card_id, 0.0))
		var selection_rate: float = 100.0 * selection_count / maxf(1.0, appearance_count)
		var selection_share: float = 100.0 * selection_count / maxf(1.0, total_selections)
		var row: Dictionary = {
			"appearances": roundi(appearance_count),
			"selections": roundi(selection_count),
			"selection_rate": selection_rate,
			"selection_share": selection_share,
			"applications": roundi(application_count),
			"applications_per_selection": application_count / maxf(1.0, selection_count),
			"wasted_units": wasted,
			"waste_per_selection": wasted / maxf(1.0, selection_count),
			"dominant": selection_share >= DOMINANT_CARD_SHARE,
		}
		per_card[card_id] = row
		ranked.append({"card_id": card_id, "selections": selection_count, "selection_share": selection_share})
		if appearance_count >= DEAD_CARD_MIN_APPEARANCES and selection_count <= 0.0:
			dead_cards.append(card_id)
		elif appearance_count >= DEAD_CARD_MIN_APPEARANCES and selection_rate < NEAR_DEAD_SELECTION_RATE:
			near_dead_cards.append(card_id)
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return float(left.get("selections", 0.0)) > float(right.get("selections", 0.0))
	)
	var top_cards: Array = []
	for index in range(mini(3, ranked.size())):
		top_cards.append((ranked[index] as Dictionary).duplicate(true))
	var top_two_concentration: float = 0.0
	for index in range(mini(2, ranked.size())):
		top_two_concentration += float((ranked[index] as Dictionary).get("selection_share", 0.0))
	return {
		"total_selections": roundi(total_selections),
		"top_cards": top_cards,
		"top_two_concentration": top_two_concentration,
		"dead_cards": dead_cards,
		"near_dead_cards": near_dead_cards,
		"per_card": per_card,
	}


static func _hero_classification(rate: float) -> String:
	if rate < HERO_SEVERE_MIN:
		return "severely_underpowered"
	if rate < HERO_BALANCED_MIN:
		return "underpowered"
	if rate <= HERO_BALANCED_MAX:
		return "balanced"
	if rate <= HERO_SEVERE_MAX:
		return "overpowered"
	return "severely_overpowered"


static func _extreme_matchup(matchups: Dictionary, best: bool) -> Dictionary:
	var selected_id: String = ""
	var selected_rate: float = -INF if best else INF
	for raw_opponent_id in matchups.keys():
		var opponent_id: String = str(raw_opponent_id)
		var rate: float = float(matchups[raw_opponent_id])
		if selected_id == "" or (best and rate > selected_rate) or (not best and rate < selected_rate):
			selected_id = opponent_id
			selected_rate = rate
	return {"opponent_id": selected_id, "rate": selected_rate if selected_id != "" else 0.0}


static func _spread(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted: Array[float] = values.duplicate()
	sorted.sort()
	return sorted[sorted.size() - 1] - sorted[0]


static func _sum_values(values: Dictionary) -> float:
	var total: float = 0.0
	for value in values.values():
		total += float(value)
	return total
