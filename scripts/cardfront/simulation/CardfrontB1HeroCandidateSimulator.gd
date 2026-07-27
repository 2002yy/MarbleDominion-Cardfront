extends CardfrontB1ParityMatchSimulator
class_name CardfrontB1HeroCandidateSimulator

var _candidate_overrides: Dictionary = {}


func simulate_with_overrides(
	hero_a: String,
	hero_b: String,
	map_id: String,
	side_variant: int,
	seed_value: int,
	overrides: Dictionary,
	simulation_mode: String = "parity_uncompensated"
) -> Dictionary:
	_candidate_overrides = overrides.duplicate(true)
	var result: Dictionary = simulate(hero_a, hero_b, map_id, side_variant, seed_value, simulation_mode)
	result["candidate_overrides"] = _candidate_overrides.duplicate(true)
	_candidate_overrides = {}
	return result


func make_candidate_state_for_test(hero_id: String, owner_id: int, overrides: Dictionary) -> Dictionary:
	_candidate_overrides = overrides.duplicate(true)
	var state: Dictionary = _make_state(hero_id, owner_id)
	_candidate_overrides = {}
	return state


func _make_state(hero_id: String, owner_id: int) -> Dictionary:
	var state: Dictionary = super._make_state(hero_id, owner_id)
	var hero_override: Dictionary = _candidate_overrides.get(hero_id, {}) as Dictionary
	if hero_override.is_empty():
		return state
	if hero_override.has("base_volley_count"):
		state["base_volley_count"] = maxi(1, int(hero_override["base_volley_count"]))
	if hero_override.has("command_chamber_health"):
		state["command_chamber_health"] = maxi(1, int(hero_override["command_chamber_health"]))
	if hero_override.has("next_volley_bonus"):
		state["next_volley_bonus"] = maxi(0, int(hero_override["next_volley_bonus"]))
	var cap: int = clampi(
		int(hero_override.get("territory_defense_cap", state.get("territory_defense_cap", 1))),
		1,
		4
	)
	var ordinary: int = clampi(
		int(hero_override.get("starting_territory_defense", state.get("starting_territory_defense", 1))),
		0,
		cap
	)
	var contact: int = clampi(
		int(hero_override.get("starting_contact_front_defense", state.get("starting_contact_front_defense", ordinary))),
		ordinary,
		cap
	)
	state["territory_defense_cap"] = cap
	state["starting_territory_defense"] = ordinary
	state["starting_contact_front_defense"] = contact
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var initial_front: Array = state.get("virtual_initial_contact_front", []) as Array
	for index in range(defense_cells.size()):
		var is_front: bool = index < CONTACT_FRONT_CELL_COUNT
		defense_cells[index] = contact if is_front else ordinary
		if index < owned_cells.size():
			owned_cells[index] = true
		if index < initial_front.size():
			initial_front[index] = is_front
	state["candidate_override"] = hero_override.duplicate(true)
	return state
