extends CardfrontB1BalanceMatchSimulator
class_name CardfrontB1ParityMatchSimulator

var _parity_states_by_owner: Dictionary = {}


func simulate(
	hero_a: String,
	hero_b: String,
	map_id: String,
	side_variant: int,
	seed_value: int,
	simulation_mode: String = "parity_uncompensated"
) -> Dictionary:
	_parity_states_by_owner = {}
	return super.simulate(hero_a, hero_b, map_id, side_variant, seed_value, simulation_mode)


func _make_state(hero_id: String, owner_id: int) -> Dictionary:
	var state: Dictionary = super._make_state(hero_id, owner_id)
	_parity_states_by_owner[int(owner_id)] = state
	return state


func _proxy_value_context(state: Dictionary) -> Dictionary:
	var context: Dictionary = super._proxy_value_context(state)
	var owner_id: int = int(state.get("owner_id", 0))
	var opponent_id: int = 2 if owner_id == 1 else 1
	var opponent_state: Dictionary = _parity_states_by_owner.get(opponent_id, {}) as Dictionary
	if opponent_state.is_empty():
		return context
	var enemy_defense_points: int = _sum_owned_defense(opponent_state)
	var enemy_owned_cells: int = _owned_cell_count(opponent_state)
	var enemy_cap: int = maxi(1, int(opponent_state.get("territory_defense_cap", 1)))
	context["enemy_defense_points"] = float(enemy_defense_points)
	context["enemy_defense_contact_chance"] = clampf(
		0.08
		+ float(enemy_defense_points) / float(maxi(1, enemy_owned_cells)) * 0.09
		+ float(enemy_cap) * 0.025,
		0.0,
		0.75
	)
	context["opponent_context_source"] = "b1_virtual_opponent_cells"
	return context


func _owned_cell_count(state: Dictionary) -> int:
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var total: int = 0
	for owned in owned_cells:
		if bool(owned):
			total += 1
	return total
