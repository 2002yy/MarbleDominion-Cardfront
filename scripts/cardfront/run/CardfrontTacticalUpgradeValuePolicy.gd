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
	var result: Dictionary = DeckValuePolicyScript.evaluate(
		upgrade_id,
		state,
		context,
		valuation_mode
	)
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
			var pierced: float = maxf(0.0, float(result.get("expected_pierced_contacts", 0.0)))
			var converted: int = maxi(0, int(result.get("converted_projectiles", 0)))
			tactical_bonus = (
				pierced * 9.0
				+ minf(24.0, float(value_context["enemy_defense_points"])) * 0.35
				+ float(value_context["enemy_defense_contact_chance"]) * 12.0
				+ maxf(0.0, float(value_context["route_pressure"]) - 0.75) * 8.0
				+ float(converted) * 3.0
			)
			reason = "defended_route_siege_opportunity"

		UpgradeManifestScript.UPGRADE_BRIDGEHEAD_PREFABS:
			var covered: float = maxf(0.0, float(result.get("expected_bridgehead_cells", 0.0)))
			tactical_bonus = (
				covered * (6.0 + float(value_context["route_pressure"]) * 3.0)
				+ (1.0 - float(value_context["own_health_ratio"])) * 8.0
			)
			reason = "capture_window_bridgehead_opportunity"

		UpgradeManifestScript.UPGRADE_SUPPRESSION_SCREEN:
			var converted: int = maxi(0, int(result.get("converted_projectiles", 0)))
			tactical_bonus = (
				float(converted) * (6.0 + float(value_context["route_pressure"]) * 7.0)
				+ maxf(0.0, float(value_context["route_pressure"]) - 0.75) * 12.0
				+ float(value_context["expected_frontline_captures"]) * 3.0
			)
			reason = "route_pressure_suppression_opportunity"

		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5, UpgradeManifestScript.UPGRADE_VOLLEY_X2:
			var repeat_count: int = maxi(0, int((model["applied_upgrade_counts"] as Dictionary).get(upgrade_id, 0)))
			tactical_multiplier = maxf(0.45, 0.84 - float(repeat_count) * 0.13)
			var added: int = maxi(0, int(result.get("actual_added_shots", 0)))
			var wasted: int = maxi(0, int(result.get("wasted_shots", 0)))
			if wasted > 0:
				var efficiency: float = float(added) / float(maxi(1, added + wasted))
				tactical_multiplier *= lerpf(0.68, 1.0, efficiency)
			if str(model["deck_id"]) != DeckRegistryScript.DECK_CORE_TACTICS and float(value_context["route_pressure"]) >= 1.35:
				tactical_multiplier *= 0.90
			reason = "flat_volley_opportunity_cost"

		UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
			var rarity_level: int = clampi(int(model["rarity_level"]), 0, RunStateScript.MAX_RARITY_LEVEL)
			var horizon: int = maxi(1, int(value_context["rounds_remaining"]))
			tactical_bonus = float(mini(horizon, 18)) * 0.55 + float(RunStateScript.MAX_RARITY_LEVEL - rarity_level) * 3.0
			reason = "early_draft_growth_window"

		UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
			var cap: int = clampi(int(model["territory_defense_cap"]), 1, RunStateScript.MAX_TERRITORY_DEFENSE_CAP)
			tactical_bonus = (
				float(value_context["repairable_frontline_cells"]) * 3.0
				+ float(value_context["route_pressure"]) * 5.0
				+ float(maxi(0, RunStateScript.MAX_TERRITORY_DEFENSE_CAP - cap)) * 4.0
			)
			reason = "fillable_defense_capacity_window"

		UpgradeManifestScript.UPGRADE_ARMOR_PIERCING:
			tactical_bonus = (
				minf(24.0, float(value_context["enemy_defense_points"])) * 0.45
				+ float(value_context["enemy_defense_contact_chance"]) * 18.0
				+ float(value_context["route_pressure"]) * 4.0
			)
			reason = "heavy_defense_bypass_window"

		UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
			tactical_bonus = (
				float(value_context["repairable_frontline_cells"]) * 1.5
				+ (1.0 - float(value_context["own_health_ratio"])) * 12.0
			)
			reason = "damaged_frontline_recovery_window"

	var build_factor: float = (
		float(result.get("build_repeat_multiplier", 1.0))
		* float(result.get("build_synergy_multiplier", 1.0))
	)
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


static func _state_model(state) -> Dictionary:
	return {
		"deck_id": DeckRegistryScript.sanitize_deck_id(str(_read(state, "deck_id", DeckRegistryScript.DEFAULT_DECK_ID))),
		"rarity_level": clampi(int(_read(state, "rarity_level", 0)), 0, RunStateScript.MAX_RARITY_LEVEL),
		"territory_defense_cap": clampi(
			int(_read(state, "territory_defense_cap", 1)),
			1,
			RunStateScript.MAX_TERRITORY_DEFENSE_CAP
		),
		"applied_upgrade_counts": (_read(state, "applied_upgrade_counts", {}) as Dictionary).duplicate(),
	}


static func _normalized_context(context: Dictionary) -> Dictionary:
	return {
		"rounds_remaining": maxi(1, int(context.get("rounds_remaining", 18))),
		"enemy_defense_points": maxf(0.0, float(context.get("enemy_defense_points", 0.0))),
		"enemy_defense_contact_chance": clampf(float(context.get("enemy_defense_contact_chance", 0.13)), 0.0, 0.75),
		"repairable_frontline_cells": maxi(0, int(context.get("repairable_frontline_cells", 0))),
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
