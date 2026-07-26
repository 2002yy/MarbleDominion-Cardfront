extends CardfrontBalanceMatchSimulator
class_name CardfrontSharedAiBalanceMatchSimulator

const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const AiUpgradePolicyScript = preload("res://scripts/cardfront/run/CardfrontAiUpgradePolicy.gd")
const UpgradeValuePolicyScript = preload("res://scripts/cardfront/run/CardfrontUpgradeValuePolicy.gd")

var _shared_ai_policy = AiUpgradePolicyScript.new()
var _active_simulation_mode: String = ConfigScript.DEFAULT_SIMULATION_MODE
var _last_choice_report: Array = []


func simulate(
	hero_a: String,
	hero_b: String,
	map_id: String,
	side_variant: int,
	seed_value: int,
	simulation_mode: String = ConfigScript.DEFAULT_SIMULATION_MODE
) -> Dictionary:
	_active_simulation_mode = ConfigScript.sanitize_simulation_mode(simulation_mode)
	_last_choice_report.clear()
	var result: Dictionary = super.simulate(
		hero_a,
		hero_b,
		map_id,
		side_variant,
		seed_value,
		_active_simulation_mode
	)
	result["upgrade_valuation_mode"] = _valuation_mode_for_simulation(_active_simulation_mode)
	return result


func choose_upgrade_id_for_test(
	offer_ids: Array,
	state: Dictionary,
	context: Dictionary = {},
	simulation_mode: String = ConfigScript.DEFAULT_SIMULATION_MODE
) -> String:
	_active_simulation_mode = ConfigScript.sanitize_simulation_mode(simulation_mode)
	var resolved_context: Dictionary = _proxy_value_context(state)
	resolved_context.merge(context, true)
	var chosen_id: String = _shared_ai_policy.choose_id(
		offer_ids,
		state,
		resolved_context,
		_valuation_mode_for_simulation(_active_simulation_mode)
	)
	_last_choice_report = _shared_ai_policy.get_last_ranked_evaluations()
	return chosen_id


func get_last_choice_report() -> Array:
	return _last_choice_report.duplicate(true)


func _choose_upgrade_id_fast(offer_ids: Array, state: Dictionary) -> String:
	var chosen_id: String = _shared_ai_policy.choose_id(
		offer_ids,
		state,
		_proxy_value_context(state),
		_valuation_mode_for_simulation(_active_simulation_mode)
	)
	_last_choice_report = _shared_ai_policy.get_last_ranked_evaluations()
	return chosen_id


func _valuation_mode_for_simulation(simulation_mode: String) -> String:
	if ConfigScript.sanitize_simulation_mode(simulation_mode) == ConfigScript.SIMULATION_MODE_HISTORICAL_COMPENSATED:
		return UpgradeValuePolicyScript.MODE_HISTORICAL_FIXED
	return UpgradeValuePolicyScript.MODE_MARGINAL


func _proxy_value_context(state: Dictionary) -> Dictionary:
	var cap: int = maxi(1, int(state.get("territory_defense_cap", 1)))
	var pending_repair: int = maxi(0, int(state.get("pending_repair_points", 0)))
	var proxy_repairable: int = clampi(2 + maxi(0, cap - 1) * 2 - pending_repair, 0, 6)
	return {
		"source": "fast_simulation_proxy",
		"round_number": 1,
		"rounds_remaining": 18,
		"pre_multiplier_shot_bonus": 0,
		"post_multiplier_shot_bonus": 0,
		"temporary_attack_level_bonus": 0,
		"estimated_chamber_hit_chance": 0.17,
		"enemy_defense_contact_chance": 0.13 + float(cap) * 0.02,
		"enemy_defense_points": 18.0,
		"repairable_frontline_cells": proxy_repairable,
		"owned_cell_count": 18,
		"defended_cell_count": 18,
		"own_health_ratio": 1.0,
		"enemy_health_ratio": 1.0,
		"route_pressure": 1.0,
		"future_offer_size": 3,
	}
