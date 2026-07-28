extends RefCounted
class_name CardfrontVolleyPlan

var owner_id: int = -1
var shot_count: int = 1
var projectile_power: int = 1
var projectile_sequence: Array = []
var projectile_counts: Dictionary = {}
var projectile_conversions_applied: Dictionary = {}
var special_projectile_sequence: Array = []
var standard_projectile_sequence: Array = []
var special_shot_count: int = 0
var standard_shot_count: int = 0
var attack_level: int = 0
var chamber_damage_quarters: int = 4
var armor_pierce_contacts: int = 0
var territory_defense_cap: int = 1
var applied_bonus: int = 0
var applied_multiplier: int = 1
var stronghold_shot_bonus: int = 0
var stronghold_attack_level_bonus: int = 0
var active_stronghold_types: Array = []


func snapshot() -> Dictionary:
	return {
		"owner_id": owner_id,
		"shot_count": shot_count,
		"projectile_power": projectile_power,
		"projectile_sequence": projectile_sequence.duplicate(),
		"projectile_counts": projectile_counts.duplicate(true),
		"projectile_conversions_applied": projectile_conversions_applied.duplicate(true),
		"special_projectile_sequence": special_projectile_sequence.duplicate(),
		"standard_projectile_sequence": standard_projectile_sequence.duplicate(),
		"special_shot_count": special_shot_count,
		"standard_shot_count": standard_shot_count,
		"attack_level": attack_level,
		"chamber_damage_quarters": chamber_damage_quarters,
		"armor_pierce_contacts": armor_pierce_contacts,
		"territory_defense_cap": territory_defense_cap,
		"applied_bonus": applied_bonus,
		"applied_multiplier": applied_multiplier,
		"stronghold_shot_bonus": stronghold_shot_bonus,
		"stronghold_attack_level_bonus": stronghold_attack_level_bonus,
		"active_stronghold_types": active_stronghold_types.duplicate(),
	}
