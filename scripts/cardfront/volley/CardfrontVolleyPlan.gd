extends RefCounted
class_name CardfrontVolleyPlan

var owner_id: int = -1
var shot_count: int = 1
var projectile_power: int = 1
var territory_defense_cap: int = 1
var applied_bonus: int = 0
var applied_multiplier: int = 1
var stronghold_shot_bonus: int = 0
var stronghold_projectile_power_bonus: int = 0
var active_stronghold_types: Array = []


func snapshot() -> Dictionary:
	return {
		"owner_id": owner_id,
		"shot_count": shot_count,
		"projectile_power": projectile_power,
		"territory_defense_cap": territory_defense_cap,
		"applied_bonus": applied_bonus,
		"applied_multiplier": applied_multiplier,
		"stronghold_shot_bonus": stronghold_shot_bonus,
		"stronghold_projectile_power_bonus": stronghold_projectile_power_bonus,
		"active_stronghold_types": active_stronghold_types.duplicate(),
	}
