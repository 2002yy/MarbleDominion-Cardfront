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


func _consume_virtual_defense(
	state: Dictionary,
	contacts: int,
	armor_contacts: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var initial_front: Array = state.get("virtual_initial_contact_front", []) as Array
	var absorbed: int = 0
	var pierced: int = mini(contacts, maxi(0, armor_contacts))
	for _contact in range(maxi(0, contacts - pierced)):
		var candidates: Array[int] = _eligible_indices(defense_cells, owned_cells, initial_front, true, true)
		if candidates.is_empty():
			candidates = _eligible_indices(defense_cells, owned_cells, initial_front, true, false)
		if candidates.is_empty():
			break
		var chosen_index: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		defense_cells[chosen_index] = maxi(0, int(defense_cells[chosen_index]) - 1)
		absorbed += 1
	return {"absorbed": absorbed, "pierced": pierced}


func _capture_virtual_cells(state: Dictionary, amount: int, rng: RandomNumberGenerator) -> int:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var initial_front: Array = state.get("virtual_initial_contact_front", []) as Array
	var captured: int = 0
	for _index in range(maxi(0, amount)):
		var candidates: Array[int] = _capturable_indices(defense_cells, owned_cells, initial_front, true)
		if candidates.is_empty():
			candidates = _capturable_indices(defense_cells, owned_cells, initial_front, false)
		if candidates.is_empty():
			break
		var chosen: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		owned_cells[chosen] = false
		defense_cells[chosen] = 0
		captured += 1
	return captured


func _recapture_virtual_cells(state: Dictionary, amount: int, rng: RandomNumberGenerator) -> int:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var initial_front: Array = state.get("virtual_initial_contact_front", []) as Array
	var recaptured: int = 0
	for _index in range(maxi(0, amount)):
		var candidates: Array[int] = _lost_indices(owned_cells, initial_front, true)
		if candidates.is_empty():
			candidates = _lost_indices(owned_cells, initial_front, false)
		if candidates.is_empty():
			break
		var chosen: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		owned_cells[chosen] = true
		defense_cells[chosen] = 0
		recaptured += 1
	return recaptured


func _eligible_indices(
	defense_cells: Array,
	owned_cells: Array,
	initial_front: Array,
	require_defense: bool,
	front_only: bool
) -> Array[int]:
	var result: Array[int] = []
	for index in range(mini(defense_cells.size(), owned_cells.size())):
		if not bool(owned_cells[index]):
			continue
		if require_defense and int(defense_cells[index]) <= 0:
			continue
		var is_front: bool = index < initial_front.size() and bool(initial_front[index])
		if front_only != is_front:
			continue
		result.append(index)
	return result


func _capturable_indices(
	defense_cells: Array,
	owned_cells: Array,
	initial_front: Array,
	front_only: bool
) -> Array[int]:
	var result: Array[int] = []
	for index in range(mini(defense_cells.size(), owned_cells.size())):
		if not bool(owned_cells[index]) or int(defense_cells[index]) > 0:
			continue
		var is_front: bool = index < initial_front.size() and bool(initial_front[index])
		if front_only != is_front:
			continue
		result.append(index)
	return result


func _lost_indices(owned_cells: Array, initial_front: Array, front_only: bool) -> Array[int]:
	var result: Array[int] = []
	for index in range(owned_cells.size()):
		if bool(owned_cells[index]):
			continue
		var is_front: bool = index < initial_front.size() and bool(initial_front[index])
		if front_only != is_front:
			continue
		result.append(index)
	return result


func _owned_cell_count(state: Dictionary) -> int:
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var total: int = 0
	for owned in owned_cells:
		if bool(owned):
			total += 1
	return total
