extends RefCounted
class_name CardfrontUpgradeValuePolicy

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

const MODE_MARGINAL: String = "marginal"
const MODE_HISTORICAL_FIXED: String = "historical_fixed"

const DEFAULT_MAX_ROUNDS: int = 34
const MAX_VALUE_HORIZON: int = 18
const DEFAULT_CHAMBER_HIT_CHANCE: float = 0.17
const DEFAULT_DEFENSE_CONTACT_CHANCE: float = 0.13
const ECHO_REPLAY_DISCOUNT: float = 0.68

const SHOT_VALUE: float = 9.0
const ATTACK_LEVEL_VALUE: float = 3.5
const REPAIR_CELL_VALUE: float = 9.0
const PIERCE_CONTACT_VALUE: float = 14.0
const DEFENSE_CAPACITY_VALUE: float = 7.0
const RARITY_QUALITY_VALUE: float = 4.0


static func evaluate(
	upgrade_id: String,
	state = null,
	context: Dictionary = {},
	valuation_mode: String = MODE_MARGINAL
) -> Dictionary:
	var safe_id: String = str(upgrade_id)
	if not UpgradeManifestScript.has_upgrade(safe_id):
		return _empty_result(safe_id, valuation_mode, "unknown_upgrade")
	if valuation_mode == MODE_HISTORICAL_FIXED:
		return _evaluate_historical(safe_id, state)

	var model: Dictionary = _state_model(state)
	var value_context: Dictionary = _normalize_context(context)
	var queued_echo_id: String = str(model.get("queued_echo_upgrade_id", ""))
	if queued_echo_id != "" and UpgradeManifestScript.has_upgrade(queued_echo_id):
		_apply_effect_to_model(model, queued_echo_id)

	var result: Dictionary = _score_once(safe_id, model, value_context)
	if not bool(result.get("eligible", false)):
		result["valuation_mode"] = MODE_MARGINAL
		return result

	var echo_armed: bool = bool(model.get("echo_next_choice_armed", false))
	if echo_armed and safe_id != UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
		var after_first: Dictionary = model.duplicate(true)
		_apply_effect_to_model(after_first, safe_id)
		var future_model: Dictionary = _future_round_model(after_first)
		var future_context: Dictionary = _advance_context(value_context)
		var replay_result: Dictionary = _score_once(safe_id, future_model, future_context)
		if bool(replay_result.get("eligible", false)):
			var replay_value: float = maxf(0.0, float(replay_result.get("score", 0.0))) * ECHO_REPLAY_DISCOUNT
			result["delayed_value"] = float(result.get("delayed_value", 0.0)) + replay_value
			result["score"] = float(result.get("score", 0.0)) + replay_value
			result["echo_replay_value"] = replay_value

	result["valuation_mode"] = MODE_MARGINAL
	return result


static func _score_once(upgrade_id: String, model: Dictionary, context: Dictionary) -> Dictionary:
	if not _is_eligible(upgrade_id, model):
		return _empty_result(upgrade_id, MODE_MARGINAL, "ineligible")

	var result: Dictionary = _empty_result(upgrade_id, MODE_MARGINAL, "")
	result["eligible"] = true
	var definition: Dictionary = UpgradeManifestScript.get_definition(upgrade_id)
	var effect_id: String = str(definition.get("effect_id", ""))
	var params: Dictionary = definition.get("params", {}) as Dictionary
	var planning_rounds: int = mini(MAX_VALUE_HORIZON, maxi(1, int(context.get("rounds_remaining", MAX_VALUE_HORIZON))))
	var route_pressure: float = clampf(float(context.get("route_pressure", 1.0)), 0.25, 3.0)
	var route_factor: float = clampf(0.75 + route_pressure * 0.25, 0.8, 1.5)
	var own_health_ratio: float = clampf(float(context.get("own_health_ratio", 1.0)), 0.0, 1.0)
	var enemy_health_ratio: float = clampf(float(context.get("enemy_health_ratio", 1.0)), 0.0, 1.0)
	var defense_pressure: float = clampf(0.75 + (1.0 - own_health_ratio) * 0.35 + route_pressure * 0.15, 0.8, 1.5)

	match effect_id:
		"add_next_volley", "multiply_next_volley":
			var before_sequence: Array = _resolved_projectile_sequence(model, context)
			var raw_before: int = _raw_shot_count(model, context)
			var after_model: Dictionary = model.duplicate(true)
			_apply_effect_to_model(after_model, upgrade_id)
			var after_sequence: Array = _resolved_projectile_sequence(after_model, context)
			var raw_after: int = _raw_shot_count(after_model, context)
			var actual_added: int = maxi(0, after_sequence.size() - before_sequence.size())
			var wasted: int = maxi(0, maxi(0, raw_after - raw_before) - actual_added)
			var direct_added: float = maxf(0.0, ProjectileTypeScript.direct_damage_units_for_sequence(after_sequence) - ProjectileTypeScript.direct_damage_units_for_sequence(before_sequence))
			var pressure_added: float = maxf(0.0, _territory_units(after_sequence) - _territory_units(before_sequence))
			var attack_factor: float = float(4 + _resolved_attack_level(model, context)) / 4.0
			var reliability_bonus: float = 2.0 if effect_id == "add_next_volley" and actual_added > 0 else 0.0
			result["actual_added_shots"] = actual_added
			result["actual_added_direct_damage_units"] = direct_added
			result["actual_added_territory_units"] = pressure_added
			result["wasted_shots"] = wasted
			result["immediate_value"] = (direct_added * SHOT_VALUE * attack_factor * 0.78 + pressure_added * SHOT_VALUE * 0.22) * route_factor + reliability_bonus
			result["score"] = float(result["immediate_value"])
			result["reason"] = "typed_projectile_marginal_value"

		"increase_attack_level":
			var amount: int = maxi(0, int(params.get("amount", 0)))
			var before_level: int = _resolved_attack_level(model, context)
			var after_model: Dictionary = model.duplicate(true)
			_apply_effect_to_model(after_model, upgrade_id)
			var after_level: int = _resolved_attack_level(after_model, context)
			var actual_levels: int = maxi(0, after_level - before_level)
			var expected_hits: float = float(_resolved_shot_count(model, context)) * clampf(
				float(context.get("estimated_chamber_hit_chance", DEFAULT_CHAMBER_HIT_CHANCE)),
				0.02,
				0.75
			)
			var finish_factor: float = 1.0 + (1.0 - enemy_health_ratio) * 0.20
			result["actual_attack_levels"] = mini(amount, actual_levels)
			result["expected_chamber_hits_per_volley"] = expected_hits
			result["persistent_value"] = expected_hits * float(actual_levels) * float(planning_rounds) * ATTACK_LEVEL_VALUE * finish_factor
			result["score"] = float(result["persistent_value"])
			result["reason"] = "future_chamber_damage"

		"add_armor_pierce":
			var contacts: int = maxi(0, int(params.get("contacts", 0)))
			var current_capacity: int = maxi(0, int(model.get("next_volley_armor_pierce_contacts", 0)))
			var after_capacity: int = maxi(current_capacity, contacts)
			var enemy_defense_points: float = maxf(0.0, float(context.get("enemy_defense_points", 0.0)))
			var expected_contacts: float = minf(
				float(_resolved_shot_count(model, context)) * clampf(
					float(context.get("enemy_defense_contact_chance", DEFAULT_DEFENSE_CONTACT_CHANCE)),
					0.0,
					0.75
				),
				enemy_defense_points
			)
			var before_pierced: float = minf(expected_contacts, float(current_capacity))
			var after_pierced: float = minf(expected_contacts, float(after_capacity))
			var actual_pierced: float = maxf(0.0, after_pierced - before_pierced)
			result["expected_pierced_contacts"] = actual_pierced
			result["immediate_value"] = actual_pierced * PIERCE_CONTACT_VALUE * route_factor
			result["score"] = float(result["immediate_value"])
			result["reason"] = "expected_defense_bypass"

		"repair_territory":
			var amount: int = maxi(0, int(params.get("amount", 0))) + maxi(0, int(model.get("frontline_repair_bonus", 0)))
			var repairable_cells: int = maxi(0, int(context.get("repairable_frontline_cells", 0)))
			var pending_before: int = maxi(0, int(model.get("pending_repair_points", 0)))
			var restored_before: int = mini(repairable_cells, pending_before)
			var restored_after: int = mini(repairable_cells, pending_before + amount)
			var actual_repair_cells: int = maxi(0, restored_after - restored_before)
			result["actual_repair_cells"] = actual_repair_cells
			result["wasted_repair_points"] = maxi(0, amount - actual_repair_cells)
			result["immediate_value"] = float(actual_repair_cells) * REPAIR_CELL_VALUE * defense_pressure
			result["score"] = float(result["immediate_value"])
			result["reason"] = "actual_distinct_repair_cells"

		"increase_defense_cap":
			var amount: int = maxi(0, int(params.get("amount", 0)))
			var before_cap: int = clampi(int(model.get("territory_defense_cap", 1)), 1, RunStateScript.MAX_TERRITORY_DEFENSE_CAP)
			var after_cap: int = clampi(before_cap + amount, 1, RunStateScript.MAX_TERRITORY_DEFENSE_CAP)
			var actual_cap: int = maxi(0, after_cap - before_cap)
			var owned_cells: int = maxi(0, int(context.get("owned_cell_count", 18)))
			var repair_count: int = int((model.get("applied_upgrade_counts", {}) as Dictionary).get(
				UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR,
				0
			))
			var time_factor: float = clampf(float(planning_rounds) / 12.0, 0.25, 1.0)
			var repair_access: float = clampf(0.25 + time_factor * 0.35 + float(mini(repair_count, 3)) * 0.10, 0.25, 0.95)
			var expected_fillable_cells: float = float(mini(6, owned_cells)) * repair_access
			result["actual_defense_cap_levels"] = actual_cap
			result["expected_fillable_cells"] = expected_fillable_cells
			result["persistent_value"] = float(actual_cap) * expected_fillable_cells * DEFENSE_CAPACITY_VALUE * defense_pressure
			result["score"] = float(result["persistent_value"])
			result["reason"] = "future_fillable_capacity"

		"increase_rarity":
			var amount: int = maxi(0, int(params.get("amount", 0)))
			var before_level: int = clampi(int(model.get("rarity_level", 0)), 0, RunStateScript.MAX_RARITY_LEVEL)
			var after_level: int = clampi(before_level + amount, 0, RunStateScript.MAX_RARITY_LEVEL)
			var quality_delta: float = maxf(0.0, _rarity_quality(after_level) - _rarity_quality(before_level))
			var future_drafts: int = maxi(0, planning_rounds - 1)
			var offer_size: int = clampi(int(context.get("future_offer_size", DraftSystemScript.DEFAULT_OFFER_SIZE)), 1, DraftSystemScript.MAX_OFFER_SIZE)
			result["rarity_quality_delta"] = quality_delta
			result["future_drafts"] = future_drafts
			result["persistent_value"] = quality_delta * float(offer_size) * float(future_drafts) * RARITY_QUALITY_VALUE
			result["score"] = float(result["persistent_value"])
			result["reason"] = "future_offer_quality"

		"echo_next_choice":
			var replay_value: float = _best_future_replay_value(model, context)
			result["delayed_value"] = replay_value * ECHO_REPLAY_DISCOUNT
			result["score"] = float(result["delayed_value"])
			result["echo_replay_value"] = float(result["delayed_value"])
			result["reason"] = "best_future_replay"

		_:
			result["eligible"] = false
			result["reason"] = "unknown_effect"
			result["score"] = -INF

	return result


static func _best_future_replay_value(model: Dictionary, context: Dictionary) -> float:
	var best_value: float = 0.0
	var future_context: Dictionary = _advance_context(context)
	for raw_upgrade_id in UpgradeManifestScript.get_upgrade_ids():
		var upgrade_id: String = str(raw_upgrade_id)
		if upgrade_id == UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
			continue
		if not _is_eligible(upgrade_id, model):
			continue
		var after_first: Dictionary = model.duplicate(true)
		_apply_effect_to_model(after_first, upgrade_id)
		var replay_model: Dictionary = _future_round_model(after_first)
		var replay_result: Dictionary = _score_once(upgrade_id, replay_model, future_context)
		if bool(replay_result.get("eligible", false)):
			best_value = maxf(best_value, maxf(0.0, float(replay_result.get("score", 0.0))))
	return best_value


static func _evaluate_historical(upgrade_id: String, state) -> Dictionary:
	var model: Dictionary = _state_model(state)
	if upgrade_id == UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE and bool(model.get("echo_next_choice_armed", false)):
		return _empty_result(upgrade_id, MODE_HISTORICAL_FIXED, "ineligible")
	var base_volley: int = maxi(1, int(model.get("base_volley_count", 6)))
	var attack_level: int = maxi(0, int(model.get("attack_level", 0)))
	var defense_cap: int = maxi(1, int(model.get("territory_defense_cap", 1)))
	var growth: int = 0
	for count in (model.get("applied_upgrade_counts", {}) as Dictionary).values():
		growth += int(count)
	var score: float = 0.0
	match upgrade_id:
		UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1:
			score = 88.0 - float(attack_level) * 7.0
		UpgradeManifestScript.UPGRADE_VOLLEY_X2:
			score = 92.0
		UpgradeManifestScript.UPGRADE_ARMOR_PIERCING:
			score = 82.0
		UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
			score = 78.0
		UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
			score = 74.0 + float(maxi(0, defense_cap - 1)) * 16.0
		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5:
			score = 64.0 + float(maxi(0, 10 - base_volley)) * 1.8
		UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
			score = 62.0 + maxf(0.0, 16.0 - float(growth) * 3.0)
		UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
			score = 68.0 + float(mini(growth, 5))
	var result: Dictionary = _empty_result(upgrade_id, MODE_HISTORICAL_FIXED, "historical_fixed_replay")
	result["eligible"] = true
	result["score"] = score
	return result


static func _state_model(state) -> Dictionary:
	var model: Dictionary = {
		"base_volley_count": 6,
		"base_projectile_mix": {ProjectileTypeScript.STANDARD: 6, ProjectileTypeScript.SIEGE: 0, ProjectileTypeScript.SUPPRESSION: 0},
		"frontline_repair_bonus": 0,
		"next_volley_bonus": 0,
		"next_volley_multiplier": 1,
		"next_volley_armor_pierce_contacts": 0,
		"attack_level": 0,
		"territory_defense_cap": 1,
		"rarity_level": 0,
		"echo_next_choice_armed": false,
		"queued_echo_upgrade_id": "",
		"pending_repair_points": 0,
		"applied_upgrade_counts": {},
	}
	if state == null:
		return model
	for key in model.keys():
		if state is Dictionary:
			model[key] = (state as Dictionary).get(key, model[key])
		else:
			var value = state.get(str(key))
			if value != null:
				model[key] = value
	model["base_volley_count"] = maxi(1, int(model["base_volley_count"]))
	model["next_volley_bonus"] = maxi(0, int(model["next_volley_bonus"]))
	model["next_volley_multiplier"] = clampi(int(model["next_volley_multiplier"]), 1, RunStateScript.MAX_NEXT_VOLLEY_MULTIPLIER)
	model["next_volley_armor_pierce_contacts"] = maxi(0, int(model["next_volley_armor_pierce_contacts"]))
	model["attack_level"] = clampi(int(model["attack_level"]), 0, RunStateScript.MAX_ATTACK_LEVEL)
	model["territory_defense_cap"] = clampi(int(model["territory_defense_cap"]), 1, RunStateScript.MAX_TERRITORY_DEFENSE_CAP)
	model["rarity_level"] = clampi(int(model["rarity_level"]), 0, RunStateScript.MAX_RARITY_LEVEL)
	model["echo_next_choice_armed"] = bool(model["echo_next_choice_armed"])
	model["queued_echo_upgrade_id"] = str(model["queued_echo_upgrade_id"])
	model["pending_repair_points"] = maxi(0, int(model["pending_repair_points"]))
	model["applied_upgrade_counts"] = (model["applied_upgrade_counts"] as Dictionary).duplicate()
	return model


static func _normalize_context(context: Dictionary) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	var round_number: int = maxi(1, int(result.get("round_number", 1)))
	result["round_number"] = round_number
	result["rounds_remaining"] = maxi(1, int(result.get("rounds_remaining", DEFAULT_MAX_ROUNDS - round_number + 1)))
	result["pre_multiplier_shot_bonus"] = maxi(0, int(result.get("pre_multiplier_shot_bonus", 0)))
	result["post_multiplier_shot_bonus"] = maxi(0, int(result.get("post_multiplier_shot_bonus", 0)))
	result["temporary_attack_level_bonus"] = maxi(0, int(result.get("temporary_attack_level_bonus", 0)))
	result["estimated_chamber_hit_chance"] = clampf(float(result.get("estimated_chamber_hit_chance", DEFAULT_CHAMBER_HIT_CHANCE)), 0.02, 0.75)
	result["enemy_defense_contact_chance"] = clampf(float(result.get("enemy_defense_contact_chance", DEFAULT_DEFENSE_CONTACT_CHANCE)), 0.0, 0.75)
	result["enemy_defense_points"] = maxf(0.0, float(result.get("enemy_defense_points", 0.0)))
	result["repairable_frontline_cells"] = maxi(0, int(result.get("repairable_frontline_cells", 0)))
	result["owned_cell_count"] = maxi(0, int(result.get("owned_cell_count", 18)))
	result["defended_cell_count"] = maxi(0, int(result.get("defended_cell_count", 0)))
	result["own_health_ratio"] = clampf(float(result.get("own_health_ratio", 1.0)), 0.0, 1.0)
	result["enemy_health_ratio"] = clampf(float(result.get("enemy_health_ratio", 1.0)), 0.0, 1.0)
	result["route_pressure"] = clampf(float(result.get("route_pressure", 1.0)), 0.25, 3.0)
	result["future_offer_size"] = clampi(int(result.get("future_offer_size", DraftSystemScript.DEFAULT_OFFER_SIZE)), 1, DraftSystemScript.MAX_OFFER_SIZE)
	return result


static func _advance_context(context: Dictionary) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	result["round_number"] = int(result.get("round_number", 1)) + 1
	result["rounds_remaining"] = maxi(1, int(result.get("rounds_remaining", 1)) - 1)
	return result


static func _future_round_model(model: Dictionary) -> Dictionary:
	var result: Dictionary = model.duplicate(true)
	result["next_volley_bonus"] = 0
	result["next_volley_multiplier"] = 1
	result["next_volley_armor_pierce_contacts"] = 0
	result["pending_repair_points"] = 0
	result["queued_echo_upgrade_id"] = ""
	result["echo_next_choice_armed"] = false
	return result


static func _apply_effect_to_model(model: Dictionary, upgrade_id: String) -> void:
	var definition: Dictionary = UpgradeManifestScript.get_definition(upgrade_id)
	if definition.is_empty():
		return
	var params: Dictionary = definition.get("params", {}) as Dictionary
	match str(definition.get("effect_id", "")):
		"add_next_volley":
			model["next_volley_bonus"] = maxi(0, int(model.get("next_volley_bonus", 0)) + maxi(0, int(params.get("amount", 0))))
		"multiply_next_volley":
			model["next_volley_multiplier"] = clampi(
				maxi(int(model.get("next_volley_multiplier", 1)), int(params.get("multiplier", 1))),
				1,
				RunStateScript.MAX_NEXT_VOLLEY_MULTIPLIER
			)
		"increase_attack_level":
			model["attack_level"] = clampi(
				int(model.get("attack_level", 0)) + maxi(0, int(params.get("amount", 0))),
				0,
				RunStateScript.MAX_ATTACK_LEVEL
			)
		"increase_defense_cap":
			model["territory_defense_cap"] = clampi(
				int(model.get("territory_defense_cap", 1)) + maxi(0, int(params.get("amount", 0))),
				1,
				RunStateScript.MAX_TERRITORY_DEFENSE_CAP
			)
		"repair_territory":
			model["pending_repair_points"] = maxi(0, int(model.get("pending_repair_points", 0)) + maxi(0, int(params.get("amount", 0))))
		"add_armor_pierce":
			model["next_volley_armor_pierce_contacts"] = maxi(
				int(model.get("next_volley_armor_pierce_contacts", 0)),
				maxi(0, int(params.get("contacts", 0)))
			)
		"increase_rarity":
			model["rarity_level"] = clampi(
				int(model.get("rarity_level", 0)) + maxi(0, int(params.get("amount", 0))),
				0,
				RunStateScript.MAX_RARITY_LEVEL
			)
		"echo_next_choice":
			model["echo_next_choice_armed"] = true


static func _is_eligible(upgrade_id: String, model: Dictionary) -> bool:
	if upgrade_id == UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
		return int(model.get("rarity_level", 0)) < RunStateScript.MAX_RARITY_LEVEL
	if upgrade_id == UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1:
		return int(model.get("attack_level", 0)) < RunStateScript.MAX_ATTACK_LEVEL
	if upgrade_id == UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
		return int(model.get("territory_defense_cap", 1)) < RunStateScript.MAX_TERRITORY_DEFENSE_CAP
	if upgrade_id == UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
		return not bool(model.get("echo_next_choice_armed", false))
	return true


static func _resolved_projectile_sequence(model: Dictionary, context: Dictionary) -> Array:
	var sequence: Array = ProjectileTypeScript.build_sequence(model.get("base_projectile_mix", {}) as Dictionary, maxi(0, int(model.get("next_volley_bonus", 0))) + maxi(0, int(context.get("pre_multiplier_shot_bonus", 0))), clampi(int(model.get("next_volley_multiplier", 1)), 1, RunStateScript.MAX_NEXT_VOLLEY_MULTIPLIER), VolleyResolverScript.NORMAL_MAX_VOLLEY_COUNT)
	ProjectileTypeScript.append_standard(sequence, maxi(0, int(context.get("post_multiplier_shot_bonus", 0))), VolleyResolverScript.MAX_VOLLEY_COUNT)
	return sequence

static func _territory_units(sequence: Array) -> float:
	var total: float = 0.0
	for raw_type in sequence:
		total += ProjectileTypeScript.territory_pressure_units(str(raw_type))
	return total


static func _raw_shot_count(model: Dictionary, context: Dictionary) -> int:
	return (
		maxi(1, int(model.get("base_volley_count", 6)))
		+ maxi(0, int(model.get("next_volley_bonus", 0)))
		+ maxi(0, int(context.get("pre_multiplier_shot_bonus", 0)))
	) * clampi(int(model.get("next_volley_multiplier", 1)), 1, RunStateScript.MAX_NEXT_VOLLEY_MULTIPLIER)


static func _resolved_shot_count(model: Dictionary, context: Dictionary) -> int:
	var core_count: int = clampi(_raw_shot_count(model, context), 1, VolleyResolverScript.NORMAL_MAX_VOLLEY_COUNT)
	return clampi(
		core_count + maxi(0, int(context.get("post_multiplier_shot_bonus", 0))),
		1,
		VolleyResolverScript.MAX_VOLLEY_COUNT
	)


static func _resolved_attack_level(model: Dictionary, context: Dictionary) -> int:
	return clampi(
		int(model.get("attack_level", 0)) + maxi(0, int(context.get("temporary_attack_level_bonus", 0))),
		0,
		RunStateScript.MAX_RESOLVED_ATTACK_LEVEL
	)


static func _rarity_quality(rarity_level: int) -> float:
	var level: int = clampi(rarity_level, 0, RunStateScript.MAX_RARITY_LEVEL)
	var common_weight: float = maxf(25.0, DraftSystemScript.COMMON_BASE_WEIGHT - float(level) * 12.0)
	var uncommon_weight: float = DraftSystemScript.UNCOMMON_BASE_WEIGHT + float(level) * 10.0
	var rare_weight: float = DraftSystemScript.RARE_BASE_WEIGHT + float(level) * 8.0
	var total: float = maxf(0.001, common_weight + uncommon_weight + rare_weight)
	return (uncommon_weight + rare_weight * 2.2) / total


static func _empty_result(upgrade_id: String, valuation_mode: String, reason: String) -> Dictionary:
	return {
		"upgrade_id": str(upgrade_id),
		"valuation_mode": str(valuation_mode),
		"eligible": false,
		"score": -INF,
		"immediate_value": 0.0,
		"persistent_value": 0.0,
		"delayed_value": 0.0,
		"actual_added_shots": 0,
		"wasted_shots": 0,
		"actual_repair_cells": 0,
		"wasted_repair_points": 0,
		"expected_pierced_contacts": 0.0,
		"reason": str(reason),
	}
