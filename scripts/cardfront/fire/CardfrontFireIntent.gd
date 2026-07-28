extends RefCounted
class_name CardfrontFireIntent

var owner_id: int = 0
var target_region_id: int = -1
var target_cell: Vector2i = Vector2i(-1, -1)
var angle: float = 0.0
var shot_count: int = 1
var projectile_power: int = 1
var projectile_sequence: Array = []
var projectile_counts: Dictionary = {}
var chamber_damage_quarters: int = 4
var armor_pierce_contacts: int = 0
var spread: float = 0.0
var reason: String = ""


func snapshot() -> Dictionary:
	return {
		"owner_id": owner_id,
		"target_region_id": target_region_id,
		"target_cell": target_cell,
		"angle": angle,
		"shot_count": shot_count,
		"projectile_power": projectile_power,
		"projectile_sequence": projectile_sequence.duplicate(),
		"projectile_counts": projectile_counts.duplicate(true),
		"chamber_damage_quarters": chamber_damage_quarters,
		"armor_pierce_contacts": armor_pierce_contacts,
		"spread": spread,
		"reason": reason,
	}
