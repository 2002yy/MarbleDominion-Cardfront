extends RefCounted
class_name CardfrontDeckUpgradeValuePolicy

const BaseValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")

const MODE_MARGINAL: String = BaseValuePolicyScript.MODE_MARGINAL
const MODE_HISTORICAL_FIXED: String = BaseValuePolicyScript.MODE_HISTORICAL_FIXED

const SHOT_VALUE: float = 9.0
const PIERCE_CONTACT_VALUE: float = 14.0
const ECHO_REPLAY_DISCOUNT: float = 0.68
const BUILD_REPEAT_PENALTY: float = 0.10
const BUILD_TAG_SYNERGY: float = 0.04


static func evaluate(
	upgrade_id: String,
	state = null,
	context: Dictionary = {},
	valuation_mode: String = MODE_MARGINAL
) -> Dictionary:
	var safe_id: String = str(upgrade_id)
	if valuation_mode == MODE_HISTORICAL_FIXED:
		return BaseValuePolicyScript.evaluate(safe_id, state, context, valuation_mode)
	if not UpgradeManifestScript.has_upgrade(safe_id):
		return _empty_result(safe_id, "unknown_upgrade")

	var model: Dictionary = _state_model(state)
	var normalized_context: Dictionary = _normalize_context(context)
	var definition: Dictionary = UpgradeManifestScript.get_definition(safe_id)
	var effect_id: String = str(definition.get("effect_id", ""))
	var result: Dictionary
	match effect_id:
		"convert_next_volley":
			result = _score_conversion(safe_id, definition, model, normalized_context)
		"queue_entity_action", "increase_building_volley", "arm_heavy_charge":
			result = _score_entity_upgrade(safe_id, definition, model, normalized_context)
		"echo_next_choice":
			result = BaseValuePolicyScript.evaluate(safe_id, state, normalized_context, valuation_mode)
			result = _extend_echo_value(result, model, normalized_context)
		_:
			result = BaseValuePolicyScript.evaluate(safe_id, state, normalized_context, valuation_mode)

	if not bool(result.get("eligible", false)):
		return result
	return _apply_build_adjustments(safe_id, result, model)


static func _score_conversion(
	upgrade_id: String,
	definition: Dictionary,
	model: Dictionary,
	context: Dictionary
) -> Dictionary:
	var result: Dictionary = _empty_result(upgrade_id, "")
	result["eligible"] = true
	var params: Dictionary = definition.get("params", {}) as Dictionary
	var target_type: String = ProjectileTypeScript.sanitize(str(params.get("projectile_type", ProjectileTypeScript.STANDARD)))
	if target_type == ProjectileTypeScript.STANDARD:
		result["eligible"] = false
		result["reason"] = "invalid_conversion_target"
		return result
	var amount: int = maxi(0, int(params.get("amount", 0)))
	var before_sequence: Array = _resolved_sequence(model, context)
	var after_sequence: Array = before_sequence.duplicate()
	var converted: int = ProjectileTypeScript.convert_standard(after_sequence, target_type, amount)
	if converted <= 0:
		result["score"] = 0.0
		result["reason"] = "no_standard_projectiles_to_convert"
		return result

	var direct_delta: float = (
		ProjectileTypeScript.direct_damage_units_for_sequence(after_sequence)
		- ProjectileTypeScript.direct_damage_units_for_sequence(before_sequence)
	)
	var pressure_delta: float = _territory_units(after_sequence) - _territory_units(before_sequence)
	var attack_level: int = clampi(
		int(model.get("attack_level", 0)) + maxi(0, int(context.get("temporary_attack_level_bonus", 0))),
		0,
		4
	)
	var hit_chance: float = clampf(float(context.get("estimated_chamber_hit_chance", 0.17)), 0.02, 0.75)
	var route_pressure: float = clampf(float(context.get("route_pressure", 1.0)), 0.25, 3.0)
	var direct_value: float = direct_delta * SHOT_VALUE * (float(4 + attack_level) / 4.0) * clampf(hit_chance * 2.0, 0.25, 1.0)
	var pressure_value: float = pressure_delta * SHOT_VALUE * clampf(0.75 + route_pressure * 0.35, 0.8, 1.8) * 2.5
	var pierce_value: float = 0.0
	if target_type == ProjectileTypeScript.SIEGE:
		var expected_contacts: float = minf(
			float(converted) * clampf(float(context.get("enemy_defense_contact_chance", 0.13)), 0.0, 0.75),
			maxf(0.0, float(context.get("enemy_defense_points", 0.0)))
		)
		pierce_value = expected_contacts * PIERCE_CONTACT_VALUE
		result["expected_pierced_contacts"] = expected_contacts

	result["converted_projectiles"] = converted
	result["conversion_target"] = target_type
	result["actual_added_direct_damage_units"] = direct_delta
	result["actual_added_territory_units"] = pressure_delta
	result["immediate_value"] = direct_value + pressure_value + pierce_value
	result["score"] = float(result["immediate_value"])
	result["reason"] = "typed_conversion_marginal_value"
	return result


static func _score_entity_upgrade(
	upgrade_id: String,
	definition: Dictionary,
	model: Dictionary,
	context: Dictionary
) -> Dictionary:
	var result: Dictionary = _empty_result(upgrade_id, "")
	result["eligible"] = true
	var params: Dictionary = definition.get("params", {}) as Dictionary
	var route_pressure: float = clampf(float(context.get("route_pressure", 1.0)), 0.25, 3.0)
	var own_health_ratio: float = clampf(float(context.get("own_health_ratio", 1.0)), 0.0, 1.0)
	var enemy_towers: int = maxi(0, int(context.get("enemy_defense_tower_count", 0)))
	match str(definition.get("effect_id", "")):
		"queue_entity_action":
			match str(params.get("action", "")):
				"summon_repair_units":
					var capacity: int = maxi(0, 3 - int(model.get("owned_creature_count", 0)))
					var spawned: int = mini(capacity, maxi(0, int(params.get("amount", 2))))
					result["persistent_value"] = float(spawned) * (9.0 + (1.0 - own_health_ratio) * 5.0)
					result["reason"] = "repair_unit_frontline_value"
				"summon_armored_guard":
					var capacity: int = maxi(0, 3 - int(model.get("owned_creature_count", 0)))
					var spawned: int = mini(capacity, maxi(0, int(params.get("amount", 1))))
					result["persistent_value"] = float(spawned) * (24.0 + route_pressure * 8.0)
					result["reason"] = "armored_guard_route_block_value"
				"summon_sapper_unit":
					var capacity: int = maxi(0, 3 - int(model.get("owned_creature_count", 0)))
					var spawned: int = mini(capacity, maxi(0, int(params.get("amount", 1))))
					var defense_points: float = maxf(0.0, float(context.get("enemy_defense_points", 0.0)))
					result["persistent_value"] = float(spawned) * (
						18.0 + float(enemy_towers) * 18.0 + minf(12.0, defense_points)
					)
					result["reason"] = "sapper_structure_demolition_value"
				"build_or_upgrade_tower":
					var tower_id: String = str(params.get("tower_id", ""))
					var current_level: int = int((model.get("tower_levels", {}) as Dictionary).get(tower_id, 0))
					result["persistent_value"] = 25.0 + float(current_level) * 5.0
					if tower_id == "interceptor_tower":
						result["persistent_value"] += route_pressure * 7.0
					else:
						result["persistent_value"] += float(context.get("rounds_remaining", 8)) * 0.8
					result["reason"] = "tower_build_or_upgrade_value"
		"increase_building_volley":
			var towers: int = maxi(0, int(model.get("owned_defense_tower_count", 0)))
			var level: int = clampi(int(model.get("building_volley_level", 0)), 0, 3)
			result["persistent_value"] = float(towers * (level + 2)) * 6.0 * minf(8.0, float(context.get("rounds_remaining", 8))) / 8.0
			result["reason"] = "powered_tower_volley_growth"
		"arm_heavy_charge":
			result["immediate_value"] = 10.0 + float(enemy_towers) * 22.0
			result["reason"] = "enemy_tower_demolition_window"
	result["score"] = float(result["persistent_value"]) + float(result["immediate_value"])
	return result


static func _extend_echo_value(
	base_result: Dictionary,
	model: Dictionary,
	context: Dictionary
) -> Dictionary:
	if not bool(base_result.get("eligible", false)):
		return base_result
	var best_new_value: float = 0.0
	var future_context: Dictionary = context.duplicate(true)
	future_context["round_number"] = int(future_context.get("round_number", 1)) + 1
	future_context["rounds_remaining"] = maxi(1, int(future_context.get("rounds_remaining", 1)) - 1)
	for raw_upgrade_id in DeckRegistryScript.get_upgrade_ids(str(model.get("deck_id", DeckRegistryScript.DEFAULT_DECK_ID))):
		var candidate_id: String = str(raw_upgrade_id)
		if candidate_id not in [
			UpgradeManifestScript.UPGRADE_SIEGE_CALIBRATION,
			UpgradeManifestScript.UPGRADE_SUPPRESSION_SCREEN,
			UpgradeManifestScript.UPGRADE_REPAIR_UNITS,
			UpgradeManifestScript.UPGRADE_FIRE_CONTROL_BEACON,
			UpgradeManifestScript.UPGRADE_INTERCEPTOR_TOWER,
			UpgradeManifestScript.UPGRADE_BUILDING_VOLLEY,
			UpgradeManifestScript.UPGRADE_HEAVY_CHARGE,
			UpgradeManifestScript.UPGRADE_ARMORED_GUARD,
			UpgradeManifestScript.UPGRADE_SAPPER_UNIT,
		]:
			continue
		var candidate: Dictionary = evaluate(candidate_id, model, future_context, MODE_MARGINAL)
		if bool(candidate.get("eligible", false)):
			best_new_value = maxf(best_new_value, maxf(0.0, float(candidate.get("score", 0.0))))
	var extended_replay: float = best_new_value * ECHO_REPLAY_DISCOUNT
	if extended_replay > float(base_result.get("echo_replay_value", 0.0)):
		base_result["echo_replay_value"] = extended_replay
		base_result["delayed_value"] = extended_replay
		base_result["score"] = extended_replay
		base_result["reason"] = "deck_aware_best_future_replay"
	return base_result


static func _apply_build_adjustments(
	upgrade_id: String,
	result: Dictionary,
	model: Dictionary
) -> Dictionary:
	var score: float = float(result.get("score", -INF))
	if is_inf(score) or is_nan(score):
		return result
	var counts: Dictionary = model.get("applied_upgrade_counts", {}) as Dictionary
	var same_count: int = maxi(0, int(counts.get(upgrade_id, 0)))
	var repeat_multiplier: float = maxf(0.70, 1.0 - float(same_count) * BUILD_REPEAT_PENALTY)
	var candidate_tags: Array = (UpgradeManifestScript.get_definition(upgrade_id).get("tags", []) as Array)
	var matching_tags: Dictionary = {}
	for raw_previous_id in counts.keys():
		var previous_id: String = str(raw_previous_id)
		if previous_id == upgrade_id or int(counts.get(previous_id, 0)) <= 0:
			continue
		var previous_tags: Array = (UpgradeManifestScript.get_definition(previous_id).get("tags", []) as Array)
		for raw_tag in candidate_tags:
			var tag: String = str(raw_tag)
			if tag in previous_tags:
				matching_tags[tag] = true
	var synergy_multiplier: float = 1.0 + float(mini(3, matching_tags.size())) * BUILD_TAG_SYNERGY
	result["score_before_build_adjustment"] = score
	result["build_repeat_multiplier"] = repeat_multiplier
	result["build_synergy_multiplier"] = synergy_multiplier
	result["build_matching_tags"] = matching_tags.keys()
	result["score"] = score * repeat_multiplier * synergy_multiplier
	return result


static func _state_model(state) -> Dictionary:
	var model: Dictionary = {
		"deck_id": DeckRegistryScript.DEFAULT_DECK_ID,
		"base_volley_count": 6,
		"base_projectile_mix": {
			ProjectileTypeScript.STANDARD: 6,
			ProjectileTypeScript.SIEGE: 0,
			ProjectileTypeScript.SUPPRESSION: 0,
		},
		"captured_frontline_defense": 0,
		"next_volley_bonus": 0,
		"next_volley_multiplier": 1,
		"next_volley_conversions": {},
		"attack_level": 0,
		"territory_defense_cap": 1,
		"owned_creature_count": 0,
		"owned_defense_tower_count": 0,
		"tower_levels": {},
		"building_volley_level": 0,
		"applied_upgrade_counts": {},
	}
	if state != null:
		for key in model.keys():
			if state is Dictionary:
				model[key] = (state as Dictionary).get(key, model[key])
			else:
				var value = state.get(str(key))
				if value != null:
					model[key] = value
	model["deck_id"] = DeckRegistryScript.sanitize_deck_id(str(model["deck_id"]))
	model["base_volley_count"] = maxi(1, int(model["base_volley_count"]))
	model["base_projectile_mix"] = _normalized_mix(model.get("base_projectile_mix", {}) as Dictionary, int(model["base_volley_count"]))
	model["next_volley_bonus"] = maxi(0, int(model["next_volley_bonus"]))
	model["next_volley_multiplier"] = clampi(int(model["next_volley_multiplier"]), 1, 2)
	model["next_volley_conversions"] = (model["next_volley_conversions"] as Dictionary).duplicate(true)
	model["attack_level"] = clampi(int(model["attack_level"]), 0, 3)
	model["territory_defense_cap"] = maxi(1, int(model["territory_defense_cap"]))
	model["captured_frontline_defense"] = maxi(0, int(model["captured_frontline_defense"]))
	model["owned_creature_count"] = maxi(0, int(model["owned_creature_count"]))
	model["owned_defense_tower_count"] = maxi(0, int(model["owned_defense_tower_count"]))
	model["tower_levels"] = (model["tower_levels"] as Dictionary).duplicate(true)
	model["building_volley_level"] = clampi(int(model["building_volley_level"]), 0, 3)
	model["applied_upgrade_counts"] = (model["applied_upgrade_counts"] as Dictionary).duplicate()
	return model


static func _normalize_context(context: Dictionary) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	result["round_number"] = maxi(1, int(result.get("round_number", 1)))
	result["rounds_remaining"] = maxi(1, int(result.get("rounds_remaining", 18)))
	result["pre_multiplier_shot_bonus"] = maxi(0, int(result.get("pre_multiplier_shot_bonus", 0)))
	result["post_multiplier_shot_bonus"] = maxi(0, int(result.get("post_multiplier_shot_bonus", 0)))
	result["temporary_attack_level_bonus"] = maxi(0, int(result.get("temporary_attack_level_bonus", 0)))
	result["estimated_chamber_hit_chance"] = clampf(float(result.get("estimated_chamber_hit_chance", 0.17)), 0.02, 0.75)
	result["enemy_defense_contact_chance"] = clampf(float(result.get("enemy_defense_contact_chance", 0.13)), 0.0, 0.75)
	result["enemy_defense_points"] = maxf(0.0, float(result.get("enemy_defense_points", 0.0)))
	result["own_health_ratio"] = clampf(float(result.get("own_health_ratio", 1.0)), 0.0, 1.0)
	result["route_pressure"] = clampf(float(result.get("route_pressure", 1.0)), 0.25, 3.0)
	result["expected_frontline_captures"] = clampf(float(result.get("expected_frontline_captures", 0.0)), 0.0, 6.0)
	result["enemy_defense_tower_count"] = maxi(0, int(result.get("enemy_defense_tower_count", 0)))
	return result


static func _resolved_sequence(model: Dictionary, context: Dictionary) -> Array:
	var sequence: Array = ProjectileTypeScript.build_sequence(
		model.get("base_projectile_mix", {}) as Dictionary,
		maxi(0, int(model.get("next_volley_bonus", 0))) + maxi(0, int(context.get("pre_multiplier_shot_bonus", 0))),
		clampi(int(model.get("next_volley_multiplier", 1)), 1, 2),
		VolleyResolverScript.NORMAL_MAX_VOLLEY_COUNT
	)
	ProjectileTypeScript.append_standard(
		sequence,
		maxi(0, int(context.get("post_multiplier_shot_bonus", 0))),
		VolleyResolverScript.MAX_VOLLEY_COUNT
	)
	ProjectileTypeScript.apply_conversions(sequence, model.get("next_volley_conversions", {}) as Dictionary)
	return sequence


static func _territory_units(sequence: Array) -> float:
	var total: float = 0.0
	for raw_type in sequence:
		total += ProjectileTypeScript.territory_pressure_units(str(raw_type))
	return total


static func _normalized_mix(raw_mix: Dictionary, base_count: int) -> Dictionary:
	var safe_count: int = maxi(1, int(base_count))
	var siege: int = clampi(int(raw_mix.get(ProjectileTypeScript.SIEGE, 0)), 0, safe_count)
	var suppression: int = clampi(int(raw_mix.get(ProjectileTypeScript.SUPPRESSION, 0)), 0, maxi(0, safe_count - siege))
	return {
		ProjectileTypeScript.STANDARD: maxi(0, safe_count - siege - suppression),
		ProjectileTypeScript.SIEGE: siege,
		ProjectileTypeScript.SUPPRESSION: suppression,
	}


static func _empty_result(upgrade_id: String, reason: String) -> Dictionary:
	return {
		"upgrade_id": str(upgrade_id),
		"valuation_mode": MODE_MARGINAL,
		"eligible": false,
		"score": -INF,
		"immediate_value": 0.0,
		"persistent_value": 0.0,
		"delayed_value": 0.0,
		"actual_added_shots": 0,
		"actual_added_direct_damage_units": 0.0,
		"actual_added_territory_units": 0.0,
		"wasted_shots": 0,
		"actual_repair_cells": 0,
		"wasted_repair_points": 0,
		"expected_pierced_contacts": 0.0,
		"converted_projectiles": 0,
		"conversion_target": "",
		"expected_bridgehead_cells": 0.0,
		"effective_bridgehead_defense": 0,
		"build_repeat_multiplier": 1.0,
		"build_synergy_multiplier": 1.0,
		"reason": str(reason),
	}
