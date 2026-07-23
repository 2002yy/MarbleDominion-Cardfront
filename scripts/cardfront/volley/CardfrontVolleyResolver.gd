extends RefCounted
class_name CardfrontVolleyResolver

const VolleyPlanScript = preload("res://scripts/cardfront/volley/CardfrontVolleyPlan.gd")

const MAX_VOLLEY_COUNT: int = 512


func build_and_consume(run_state):
	if run_state == null:
		return null
	var modifiers: Dictionary = run_state.consume_next_volley_modifiers()
	var bonus: int = maxi(0, int(modifiers.get("bonus", 0)))
	var multiplier: int = maxi(1, int(modifiers.get("multiplier", 1)))
	var resolved_count: int = clampi(
		(maxi(1, int(run_state.base_volley_count)) + bonus) * multiplier,
		1,
		MAX_VOLLEY_COUNT
	)

	var plan = VolleyPlanScript.new()
	plan.owner_id = int(run_state.owner_id)
	plan.shot_count = resolved_count
	plan.projectile_power = maxi(1, int(run_state.projectile_power))
	plan.territory_defense_cap = maxi(1, int(run_state.territory_defense_cap))
	plan.applied_bonus = bonus
	plan.applied_multiplier = multiplier
	return plan
