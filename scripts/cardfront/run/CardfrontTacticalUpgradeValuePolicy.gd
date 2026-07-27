extends RefCounted
class_name CardfrontTacticalUpgradeValuePolicy

const DeckValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontDeckUpgradeValuePolicy.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

const MODE_MARGINAL: String = DeckValuePolicyScript.MODE_MARGINAL
const MODE_HISTORICAL_FIXED: String = DeckValuePolicyScript.MODE_HISTORICAL_FIXED


static func evaluate(
	upgrade_id: String,
	state = null,
	context: Dictionary = {},
	valuation_mode: String = MODE_MARGINAL
) -> Dictionary:
	var result: Dictionary = DeckValuePolicyScript.evaluate(upgrade_id, state, context, valuation_mode)
	if valuation_mode == MODE_HISTORICAL_FIXED or not bool(result.get("eligible", false)):
		return result

	var score: float = float(result.get("score", -INF))
	if is_inf(score) or is_nan(score):
		return result

	var model: Dictionary = _state_model(state)
	var value_context: Dictionary = _normalized_context(context)
	var tactical_bonus: float = 0.0
	var tactical_multiplier: float = 1.0
	var reason: String = ""

	match str(upgrade_id):
		UpgradeManifestScript.UPGRADE_SIEGE_CALIBRATION:
			var generic_pierced: float = maxf(0.0, float(result.get("expected_pierced_contacts", 0.0)))
			var siege_converted: int = maxi(0, int(result.get("converted_projectiles", 0)))
			var targeted_pierced: float = minf(
				float(siege_converted) * float(value_context["siege_defense_contact_chance"]),
				float(value_context["enemy_defense_points"])
			)
			var targeted_gain: float = maxf(0.0, targeted_pierced - generic_pierced)
			result["expected_pierced_contacts"] = targeted_pierced
			tactical_bonus = targeted_gain * 22.0 \
				+ targeted_pierced * 4.0 \
				+ maxf(0.0, float(value_context["route_pressure"]) - 0.75) * 6.0 \
				+ float(siege_converted) * 2.0
			reason = "defended_route_siege_opportunity"

		UpgradeManifestScript.UPGRADE_BRIDGEHEAD_PREFABS:
			var covered: float = maxf(0.0, float(result.get("expected_bridgehead_cells", 0.0)))
			tactical_bonus = covered * (6.0 + float(value_context["route_pressure"]) * 3.0) \
				+ (1.0 - float(value_context["own_health_ratio"])) * 8.0
			reason = "capture_window_bridgehead_opportunity"

		UpgradeManifestScript.UPGRADE_SUPPRESSION_SCREEN:
			var suppression_converted: int = maxi(0, int(result.get("converted_projectiles", 0)))
			tactical_bonus = float(suppression_converted) * (6.0 + float(value_context["route_pressure"]) * 7.0) \
				+ maxf(0.0, float(value_context["route_pressure"]) - 0.75) * 12.0 \
				+ float(value_context["expected_frontline_captures"]) * 3.0
			reason = "route_pressure_suppression_opportunity"

		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5:
			var plus_repeat_count: int = maxi(0, int((model["applied_upgrade_counts"] as Dictionary).get(upgrade_id, 0)))
			tactical_multiplier = maxf(0.72, 0.98 - float(plus_repeat_count) * 0.06)
			tactical_multiplier *= _shot_efficiency_multiplier(result)
			if str(model["deck_id"]) != DeckRegistryScript.DECK_CORE_TACTICS and float(value_context["route_pressure"]) >= 1.35:
				tactical_multiplier *= 0.95
			reason = "flat_volley_opportunity_cost"

		UpgradeManifestScript.UPGRADE_VOLLEY_X2:
			var double_repeat_count: int = maxi(0, int((model["applied_upgrade_counts"] as Dictionary).get(upgrade_id, 0)))
			tactical_multiplier = maxf(0.65, 0.90 - float(double_repeat_count) * 0.08)
			tactical_multiplier *= _shot_efficiency_multiplier(result)
			if str(model["deck_id"]) != DeckRegistryScript.DECK_CORE_TACTICS and float(value_context["route_pressure"]) >= 1.35:
				tactical_multiplier *= 0.94
			reason = "double_volley_opportunity_cost"

		UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
			var rarity_level: int = clampi(int(model["rarity_level"]), 0, RunStateScript.MAX_RARITY_LEVEL)
			var horizon: int = maxi(1, int(value_context["rounds_remaining"]))
			tactical_bonus = float(mini(horizon, 18)) * 0.90 \
				+ float(RunStateScript.MAX_RARITY_LEVEL - rarity_level) * 4.0
			reason = "early_draft_growth_window"

		UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
			var cap: int = clampi(int(model["territory_defense_cap"]), 1, RunStateScript.MAX_TERRITORY_DEFENSE_CAP)
			var repairable: int = maxi(0, int(value_context["repairable_frontline_cells"]))
			var saturated_cells: int = maxi(0, int(value_context["defended_cell_count"]) - repairable)
			var readiness: float = clampf(1.0 - float(repairable) / 10.0, 0.35, 1.0)
			tactical_bonus = (
				float(saturated_cells) * 1.2
				+ float(value_context["route_pressure"]) * 3.0
				+ float(maxi(0, RunStateScript.MAX_TERRITORY_DEFENSE_CAP - cap)) * 3.0
			) * readiness
			reason = "saturated_defense_capacity_investment"

		UpgradeManifestScript.UPGRADE_ARMOR_PIERCING:
			var defense_points: float = float(value_context["enemy_defense_points"])
			var contact_chance: float = float(value_context["enemy_defense_contact_chance"])
			var dense_points: float = maxf(0.0, defense_points - 8.0)
			var contact_excess: float = maxf(0.0, contact_chance - 0.18)
			tactical_bonus = minf(16.0, dense_points) * 0.35 \
				+ contact_excess * 20.0 \
				+ maxf(0.0, float(value_context["route_pressure"]) - 1.0) * 3.0
			if defense_points <= 4.0 or contact_chance <= 0.08:
				tactical_multiplier = 0.60
			reason = "heavy_defense_bypass_window"

		UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
			var actual_repair: int = maxi(0, int(result.get("actual_repair_cells", 0)))
			var wasted_repair: int = maxi(0, int(result.get("wasted_repair_points", 0)))
			var repair_efficiency: float = float(actual_repair) / float(maxi(1, actual_repair + wasted_repair))
			tactical_multiplier = lerpf(0.60, 1.0, repair_efficiency)
			tactical_bonus = (1.0 - float(value_context["own_health_ratio"])) * 6.0
			reason = "damaged_frontline_recovery_window"

	var build_factor: float = float(result.get("build_repeat_multiplier", 1.0)) \
		* float(result.get("build_synergy_multiplier", 1.0))
	if upgrade_id in [
		UpgradeManifestScript.UPGRADE_SIEGE_CALIBRATION,
		UpgradeManifestScript.UPGRADE_BRIDGEHEAD_PREFABS,
		UpgradeManifestScript.UPGRADE_SUPPRESSION_SCREEN,
	]:
		tactical_bonus *= build_factor

	result["score_before_tactical_adjustment"] = score
	result["tactical_bonus"] = tactical_bonus
	result["tactical_multiplier"] = tactical_multiplier
	result["tactical_reason"] = reason
	result["score"] = (score + tactical_bonus) * tactical_multiplier
	return result


static func _shot_efficiency_multiplier(result: Dictionary) -> float:
	var added: int = maxi(0, int(result.get("actual_added_shots", 0)))
	var wasted: int = maxi(0, int(result.get("wasted_shots", 0)))
	if wasted <= 0:
		return 1.0
	var efficiency: float = float(added) / float(maxi(1, added + wasted))
	return lerpf(0.78, 1.0, efficiency)


static func _state_model(state) -> Dictionary:
	return {
		"deck_id": DeckRegistryScript.sanitize_deck_id(str(_read(state, "deck_id", DeckRegistryScript.DEFAULT_DECK_ID))),
		"rarity_level": clampi(int(_read(state, "rarity_level", 0)), 0, RunStateScript.MAX_RARITY_LEVEL),
		"territory_defense_cap": clampi(int(_read(state, "territory_defense_cap", 1)), 1, RunStateScript.MAX_TERRITORY_DEFENSE_CAP),
		"applied_upgrade_counts": (_read(state, "applied_upgrade_counts", {}) as Dictionary).duplicate(),
	}


static func _normalized_context(context: Dictionary) -> Dictionary:
	var generic_contact: float = clampf(float(context.get("enemy_defense_contact_chance", 0.13)), 0.0, 0.75)
	return {
		"rounds_remaining": maxi(1, int(context.get("rounds_remaining", 18))),
		"enemy_defense_points": maxf(0.0, float(context.get("enemy_defense_points", 0.0))),
		"enemy_defense_contact_chance": generic_contact,
		"siege_defense_contact_chance": clampf(float(context.get("siege_defense_contact_chance", generic_contact)), 0.0, 0.75),
		"repairable_frontline_cells": maxi(0, int(context.get("repairable_frontline_cells", 0))),
		"owned_cell_count": maxi(0, int(context.get("owned_cell_count", 0))),
		"defended_cell_count": maxi(0, int(context.get("defended_cell_count", 0))),
		"own_health_ratio": clampf(float(context.get("own_health_ratio", 1.0)), 0.0, 1.0),
		"route_pressure": clampf(float(context.get("route_pressure", 1.0)), 0.25, 3.0),
		"expected_frontline_captures": clampf(float(context.get("expected_frontline_captures", 0.0)), 0.0, 6.0),
	}


static func _read(state, key: String, fallback):
	if state == null:
		return fallback
	if state is Dictionary:
		return (state as Dictionary).get(key, fallback)
	var value = state.get(key)
	return fallback if value == null else value
