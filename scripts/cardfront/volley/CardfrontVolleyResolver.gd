extends RefCounted
class_name CardfrontVolleyResolver

const VolleyPlanScript = preload("res://scripts/cardfront/volley/CardfrontVolleyPlan.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

const NORMAL_MAX_VOLLEY_COUNT: int = 24
const MAX_VOLLEY_COUNT: int = 32


func build_and_consume(run_state):
	if run_state == null:
		return null
	var modifiers: Dictionary = run_state.consume_next_volley_modifiers()
	var bonus: int = maxi(0, int(modifiers.get("bonus", 0)))
	var multiplier: int = maxi(1, int(modifiers.get("multiplier", 1)))
	var projectile_sequence: Array = ProjectileTypeScript.build_sequence(
		run_state.base_projectile_mix,
		bonus,
		multiplier,
		NORMAL_MAX_VOLLEY_COUNT
	)
	if projectile_sequence.is_empty():
		projectile_sequence.append(ProjectileTypeScript.STANDARD)
	var conversions: Dictionary = modifiers.get("projectile_conversions", {}) as Dictionary
	var applied_conversions: Dictionary = ProjectileTypeScript.apply_conversions(projectile_sequence, conversions)
	var resolved_count: int = clampi(projectile_sequence.size(), 1, NORMAL_MAX_VOLLEY_COUNT)

	var plan = VolleyPlanScript.new()
	plan.owner_id = int(run_state.owner_id)
	plan.shot_count = resolved_count
	plan.projectile_power = maxi(1, int(run_state.projectile_power))
	plan.projectile_sequence = projectile_sequence
	plan.projectile_counts = ProjectileTypeScript.count_types(projectile_sequence)
	plan.projectile_conversions_applied = applied_conversions
	plan.attack_level = clampi(int(run_state.attack_level), 0, run_state.MAX_ATTACK_LEVEL)
	plan.chamber_damage_quarters = 4 + plan.attack_level
	plan.armor_pierce_contacts = maxi(0, int(modifiers.get("armor_pierce_contacts", 0)))
	plan.territory_defense_cap = maxi(1, int(run_state.territory_defense_cap))
	plan.applied_bonus = bonus
	plan.applied_multiplier = multiplier
	return plan
