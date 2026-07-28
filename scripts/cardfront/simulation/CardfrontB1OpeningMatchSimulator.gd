extends CardfrontB1ArchetypeMatchSimulator
class_name CardfrontB1OpeningMatchSimulator

const OPENING_ROUNDS: int = 5


func _simulation_max_rounds() -> int:
	return OPENING_ROUNDS


func _drafts_enabled() -> bool:
	return false


func _strongholds_enabled() -> bool:
	return false


func simulate_opening(
	hero_a: String,
	hero_b: String,
	map_id: String,
	side_variant: int,
	seed_value: int,
	simulation_mode: String = "parity_uncompensated"
) -> Dictionary:
	var result: Dictionary = simulate(
		hero_a,
		hero_b,
		map_id,
		side_variant,
		seed_value,
		simulation_mode
	)
	result["opening_model"] = true
	result["opening_rounds"] = OPENING_ROUNDS
	result["upgrades_enabled"] = false
	result["strongholds_enabled"] = false
	return result
