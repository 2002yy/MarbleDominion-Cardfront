extends CardfrontSharedAiBalanceMatchSimulator
class_name CardfrontB1BalanceMatchSimulator

const B1ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const B1GateRulesScript = preload("res://scripts/cardfront/gates/CardfrontGateRules.gd")
const B1HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const B1MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const B1UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const B1ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

const VIRTUAL_CELL_COUNT: int = 40
const CONTACT_FRONT_CELL_COUNT: int = 5
const MAX_CAPTURE_UPDATES_PER_VOLLEY: int = 8

var _b1_map_definition: Dictionary = {}
var _b1_side_variant: int = 0
var _b1_seed_value: int = 0
var _b1_gate_passes: int = 0
var _b1_gate_reflections: int = 0
var _b1_river_bank_reflections: int = 0
var _b1_gate_state_crossings: Dictionary = {}
var _b1_lane_traffic: Dictionary = {}
var _b1_virtual_captures: int = 0
var _b1_virtual_recaptures: int = 0
var _b1_card_appearances: Dictionary = {}
var _b1_card_selections: Dictionary = {}
var _b1_card_applications: Dictionary = {}
var _b1_card_waste: Dictionary = {}
var _b1_card_by_hero: Dictionary = {}
var _b1_projectile_fired: Dictionary = {}
var _b1_projectile_chamber_contacts: Dictionary = {}
var _b1_projectile_damage_units: Dictionary = {}
var _b1_projectile_defense_pierce: Dictionary = {}


func simulate(
	hero_a: String,
	hero_b: String,
	map_id: String,
	side_variant: int,
	seed_value: int,
	simulation_mode: String = B1ConfigScript.SIMULATION_MODE_PARITY_UNCOMPENSATED
) -> Dictionary:
	_b1_map_definition = B1MapRegistryScript.get_map_definition(map_id, B1ConfigScript.GRID_SIZE)
	_b1_side_variant = int(side_variant) % 2
	_b1_seed_value = int(seed_value)
	_reset_b1_metrics()
	var result: Dictionary = super.simulate(
		hero_a,
		hero_b,
		map_id,
		_b1_side_variant,
		seed_value,
		simulation_mode
	)
	var metrics: Dictionary = result.get("metrics", {}) as Dictionary
	metrics["gate_passes"] = _b1_gate_passes
	metrics["gate_reflections"] = _b1_gate_reflections
	metrics["river_bank_reflections"] = _b1_river_bank_reflections
	metrics["gate_state_crossings"] = _b1_gate_state_crossings.duplicate(true)
	metrics["lane_traffic"] = _b1_lane_traffic.duplicate(true)
	metrics["virtual_captures"] = _b1_virtual_captures
	metrics["virtual_recaptures"] = _b1_virtual_recaptures
	metrics["projectile_fired"] = _b1_projectile_fired.duplicate(true)
	metrics["projectile_chamber_contacts"] = _b1_projectile_chamber_contacts.duplicate(true)
	metrics["projectile_damage_units"] = _b1_projectile_damage_units.duplicate(true)
	metrics["projectile_defense_pierce"] = _b1_projectile_defense_pierce.duplicate(true)
	result["metrics"] = metrics
	result["b1_model"] = true
	result["side_rerun_mode"] = "actual_simulation_call"
	result["position_signature"] = _position_signature(map_id, _b1_side_variant)
	result["route_layout"] = (_b1_map_definition.get("route_layout", {}) as Dictionary).duplicate(true)
	result["card_metrics"] = {
		"appearances": _b1_card_appearances.duplicate(true),
		"selections": _b1_card_selections.duplicate(true),
		"applications": _b1_card_applications.duplicate(true),
		"wasted_units": _b1_card_waste.duplicate(true),
		"by_hero": _b1_card_by_hero.duplicate(true),
	}
	return result


func make_virtual_state_for_test(hero_id: String, owner_id: int = 1) -> Dictionary:
	return _make_state(hero_id, owner_id)


func repair_virtual_state_for_test(state: Dictionary, amount: int) -> Dictionary:
	var applied: int = _repair_virtual_cells(state, amount)
	return {"applied": applied, "wasted": maxi(0, amount - applied)}


func apply_upgrade_for_test(state: Dictionary, upgrade_id: String) -> bool:
	return _resolve_upgrade_fast(state, upgrade_id)


func build_and_consume_volley_for_test(state: Dictionary) -> Dictionary:
	return _build_and_consume_volley_fast(state)


func gate_snapshot_for_test(
	map_id: String,
	lane_index: int,
	territory_a: float,
	territory_b: float,
	side_variant: int,
	round_number: int = 1
) -> Dictionary:
	_b1_map_definition = B1MapRegistryScript.get_map_definition(map_id, B1ConfigScript.GRID_SIZE)
	_b1_side_variant = int(side_variant) % 2
	return _lane_gate_snapshot(lane_index, {SLOT_A: territory_a, SLOT_B: territory_b}, round_number)


func _make_state(hero_id: String, owner_id: int) -> Dictionary:
	var state: Dictionary = super._make_state(hero_id, owner_id)
	var definition: Dictionary = B1HeroRegistryScript.get_definition(hero_id)
	var ordinary_defense: int = maxi(0, int(definition.get("starting_territory_defense", 1)))
	var contact_defense: int = maxi(
		ordinary_defense,
		int(definition.get("starting_contact_front_defense", ordinary_defense))
	)
	var defense_cells: Array = []
	var owned_cells: Array = []
	var initial_front: Array = []
	for index in range(VIRTUAL_CELL_COUNT):
		var is_front: bool = index < CONTACT_FRONT_CELL_COUNT
		defense_cells.append(contact_defense if is_front else ordinary_defense)
		owned_cells.append(true)
		initial_front.append(is_front)
	state["virtual_defense_cells"] = defense_cells
	state["virtual_owned_cells"] = owned_cells
	state["virtual_initial_contact_front"] = initial_front
	state["starting_contact_front_defense"] = contact_defense
	state["base_projectile_mix"] = (definition.get("base_projectile_mix", {}) as Dictionary).duplicate(true)
	state["captured_frontline_defense"] = clampi(int(definition.get("captured_frontline_defense", 0)), 0, int(state.get("territory_defense_cap", 1)))
	state["frontline_repair_bonus"] = maxi(0, int(definition.get("frontline_repair_bonus", 0)))
	state["pending_repair_points"] = 0
	return state


func _draw_offer_ids_fast(state: Dictionary, offer_size: int, seed_value: int) -> Array:
	var offer_ids: Array = super._draw_offer_ids_fast(state, offer_size, seed_value)
	for raw_id in offer_ids:
		_increment_metric(_b1_card_appearances, str(raw_id), 1.0)
		_increment_hero_card_metric(state, "appearances", str(raw_id), 1.0)
	return offer_ids


func _choose_upgrade_id_fast(offer_ids: Array, state: Dictionary) -> String:
	var chosen_id: String = super._choose_upgrade_id_fast(offer_ids, state)
	if chosen_id != "":
		_increment_metric(_b1_card_selections, chosen_id, 1.0)
		_increment_hero_card_metric(state, "selections", chosen_id, 1.0)
		for raw_entry in get_last_choice_report():
			var entry: Dictionary = raw_entry as Dictionary
			if str(entry.get("upgrade_id", entry.get("id", ""))) != chosen_id:
				continue
			var waste: float = (
				float(entry.get("wasted_shots", 0))
				+ float(entry.get("wasted_repair_points", 0))
			)
			_increment_metric(_b1_card_waste, chosen_id, waste)
			_increment_hero_card_metric(state, "wasted_units", chosen_id, waste)
			break
	return chosen_id


func _record_upgrade_fast(state: Dictionary, upgrade_id: String) -> void:
	super._record_upgrade_fast(state, upgrade_id)
	_increment_metric(_b1_card_applications, upgrade_id, 1.0)
	_increment_hero_card_metric(state, "applications", upgrade_id, 1.0)


func _apply_upgrade_once_fast(state: Dictionary, upgrade_id: String) -> bool:
	if upgrade_id == B1UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
		var definition: Dictionary = B1UpgradeManifestScript.get_definition(upgrade_id)
		var params: Dictionary = definition.get("params", {}) as Dictionary
		var amount: int = maxi(0, int(params.get("amount", 0))) + maxi(0, int(state.get("frontline_repair_bonus", 0)))
		var applied: int = _repair_virtual_cells(state, amount)
		state["last_repair_applied"] = applied
		state["last_repair_wasted"] = maxi(0, amount - applied)
		return true
	return super._apply_upgrade_once_fast(state, upgrade_id)


func _build_and_consume_volley_fast(state: Dictionary) -> Dictionary:
	var bonus: int = maxi(0, int(state.get("next_volley_bonus", 0)))
	var multiplier: int = maxi(1, int(state.get("next_volley_multiplier", 1)))
	var sequence: Array = B1ProjectileTypeScript.build_sequence(state.get("base_projectile_mix", {}) as Dictionary, bonus, multiplier, 24)
	var result: Dictionary = {"shot_count": sequence.size(), "projectile_sequence": sequence, "projectile_counts": B1ProjectileTypeScript.count_types(sequence), "attack_level": clampi(int(state.get("attack_level", 0)), 0, 3), "armor_pierce_contacts": maxi(0, int(state.get("next_volley_armor_pierce_contacts", 0)))}
	state["next_volley_bonus"] = 0
	state["next_volley_multiplier"] = 1
	state["next_volley_armor_pierce_contacts"] = 0
	return result


func _proxy_value_context(state: Dictionary) -> Dictionary:
	var context: Dictionary = super._proxy_value_context(state)
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var cap: int = maxi(1, int(state.get("territory_defense_cap", 1)))
	var owned_count: int = 0
	var defended_count: int = 0
	var repairable_count: int = 0
	for index in range(mini(defense_cells.size(), owned_cells.size())):
		if not bool(owned_cells[index]):
			continue
		owned_count += 1
		var defense: int = int(defense_cells[index])
		if defense > 0:
			defended_count += 1
		if defense < cap:
			repairable_count += 1
	context["source"] = "b1_virtual_cells"
	context["repairable_frontline_cells"] = mini(6, repairable_count)
	context["owned_cell_count"] = owned_count
	context["defended_cell_count"] = defended_count
	context["enemy_defense_points"] = float(_sum_owned_defense(state))
	context["route_pressure"] = _route_pressure_for_state(state)
	return context


func _resolve_volley(attacker_slot: String, target_slot: String, plan_data: Dictionary, states: Dictionary, territory: Dictionary, _defense_pool: Dictionary, profile: Dictionary, seed_value: int, round_number: int, simulation_mode: String) -> Dictionary:
	var plan: Dictionary = plan_data["plan"] as Dictionary
	var rng: RandomNumberGenerator = _rng_a if attacker_slot == SLOT_A else _rng_b
	rng.seed = _b1_stream_seed(seed_value, round_number, attacker_slot, _b1_side_variant)
	var projectile_sequence: Array = (plan.get("projectile_sequence", []) as Array).duplicate()
	if projectile_sequence.is_empty():
		B1ProjectileTypeScript.append_standard(projectile_sequence, int(plan.get("shot_count", 0)))
	var shot_count: int = projectile_sequence.size()
	for raw_type in projectile_sequence:
		_increment_metric(_b1_projectile_fired, B1ProjectileTypeScript.sanitize(str(raw_type)), 1.0)
	var route_result: Dictionary = _resolve_routes(projectile_sequence, attacker_slot, target_slot, territory, round_number, rng)
	var allowed_projectiles: Array = route_result.get("allowed_projectiles", []) as Array
	var target_state: Dictionary = states[target_slot] as Dictionary
	var defense_chance: float = clampf(float(profile.get("defense_contact_chance", 0.13)) + float(target_state.get("territory_defense_cap", 1)) * 0.045 + float(territory[target_slot]) * 0.035, 0.0, 0.7)
	var expected_contacts: float = float(allowed_projectiles.size()) * defense_chance
	var defense_contacts: int = clampi(roundi(expected_contacts + rng.randfn(0.0, sqrt(maxf(0.01, expected_contacts * (1.0 - defense_chance))))), 0, allowed_projectiles.size())
	var contact_indices: Dictionary = _sample_index_set(allowed_projectiles.size(), defense_contacts, rng)
	var armor_remaining: int = maxi(0, int(plan.get("armor_pierce_contacts", 0)))
	var defense_absorbed: int = 0
	var survivors: Array = []
	for index in range(allowed_projectiles.size()):
		var projectile_type: String = B1ProjectileTypeScript.sanitize(str(allowed_projectiles[index]))
		if not contact_indices.has(index):
			survivors.append(projectile_type)
			continue
		var pierce_layers: int = B1ProjectileTypeScript.defense_pierce_layers(projectile_type)
		if armor_remaining > 0:
			pierce_layers += 1
			armor_remaining -= 1
		var defense_result: Dictionary = _resolve_projectile_defense_contact(target_state, pierce_layers, rng)
		var pierced_layers: int = int(defense_result.get("pierced_layers", 0))
		if pierced_layers > 0:
			_increment_metric(_b1_projectile_defense_pierce, projectile_type, float(pierced_layers))
		if bool(defense_result.get("absorbed", false)):
			defense_absorbed += 1
		else:
			survivors.append(projectile_type)
	var territory_to_chamber_hit: float = float(profile.get("territory_to_chamber_hit", 0.0))
	var hit_chance: float = clampf(
		float(profile.get("chamber_hit_chance", 0.17))
		+ float(territory[attacker_slot] - territory[target_slot]) * territory_to_chamber_hit,
		0.08,
		0.65
	)
	hit_chance *= pow(6.0 / float(maxi(1, shot_count)), 0.18)
	hit_chance *= float(route_result.get("average_route_quality", 1.0))
	hit_chance = adjust_hit_chance_for_mode(hit_chance, int((states[attacker_slot] as Dictionary).get("base_volley_count", 6)), simulation_mode)
	var expected_hits: float = float(survivors.size()) * hit_chance
	var chamber_contact_count: int = clampi(roundi(expected_hits + rng.randfn(0.0, sqrt(maxf(0.01, expected_hits * (1.0 - hit_chance))))), 0, survivors.size())
	var chamber_indices: Dictionary = _sample_index_set(survivors.size(), chamber_contact_count, rng)
	var chamber_hits: int = 0
	var damage_units: float = 0.0
	var territory_contacts: float = 0.0
	for index in range(survivors.size()):
		var projectile_type: String = B1ProjectileTypeScript.sanitize(str(survivors[index]))
		if chamber_indices.has(index):
			chamber_hits += 1
			_increment_metric(_b1_projectile_chamber_contacts, projectile_type, 1.0)
			var units: float = B1ProjectileTypeScript.direct_damage_units(projectile_type)
			damage_units += units
			_increment_metric(_b1_projectile_damage_units, projectile_type, units)
		else:
			territory_contacts += B1ProjectileTypeScript.territory_pressure_units(projectile_type)
	var attacker_state: Dictionary = states[attacker_slot] as Dictionary
	var recaptured: int = _recapture_virtual_cells(attacker_state, mini(MAX_CAPTURE_UPDATES_PER_VOLLEY, floori(territory_contacts * 0.25)), rng)
	var captured: int = _capture_virtual_cells(target_state, mini(MAX_CAPTURE_UPDATES_PER_VOLLEY, maxi(0, floori(territory_contacts) - recaptured)), rng)
	_grant_captured_frontline_cells(attacker_state, captured)
	_b1_virtual_recaptures += recaptured
	_b1_virtual_captures += captured
	var average_cells: float = float(profile.get("average_cells_crossed", 19.0))
	var reflected_shots: int = shot_count - allowed_projectiles.size()
	var cells_crossed: float = maxf(float(shot_count) * 3.0, float(allowed_projectiles.size()) * average_cells + float(reflected_shots) * average_cells * 0.35 + rng.randfn(0.0, sqrt(float(maxi(1, shot_count))) * 2.0))
	return {"shot_count": shot_count, "chamber_hits": chamber_hits, "damage_quarters": roundi(damage_units * float(4 + int(plan_data.get("attack_level", 0)))), "defense_absorbed": defense_absorbed, "territory_contacts": territory_contacts, "cells_crossed": cells_crossed, "gate_passes": int(route_result.get("gate_passes", 0)), "gate_reflections": int(route_result.get("gate_reflections", 0)), "river_bank_reflections": int(route_result.get("river_bank_reflections", 0)), "virtual_captures": captured, "virtual_recaptures": recaptured}

func _resolve_routes(projectile_sequence: Array, attacker_slot: String, _target_slot: String, territory: Dictionary, round_number: int, rng: RandomNumberGenerator) -> Dictionary:
	var route_layout: Dictionary = _b1_map_definition.get("route_layout", {}) as Dictionary
	var lanes: Array = route_layout.get("lanes", []) as Array
	var off_bridge_rate: float = clampf(float(route_layout.get("off_bridge_rate", 0.08)), 0.0, 0.5)
	var allowed_projectiles: Array = []
	var gate_passes: int = 0
	var gate_reflections: int = 0
	var river_reflections: int = 0
	var route_quality_sum: float = 0.0
	for serial in range(projectile_sequence.size()):
		var projectile_type: String = B1ProjectileTypeScript.sanitize(str(projectile_sequence[serial]))
		if lanes.is_empty() or rng.randf() < off_bridge_rate:
			river_reflections += 1
			_b1_river_bank_reflections += 1
			continue
		var lane_index: int = _choose_lane_index(lanes, rng)
		_increment_metric(_b1_lane_traffic, str(lane_index), 1.0)
		var snapshot: Dictionary = _lane_gate_snapshot(lane_index, territory, round_number)
		var state_id: String = str(snapshot.get("state", B1GateRulesScript.STATE_OPEN))
		_increment_metric(_b1_gate_state_crossings, state_id, 1.0)
		var pass_gate: bool = B1GateRulesScript.is_projectile_allowed(
			attacker_slot,
			lane_index,
			snapshot,
			serial + round_number,
			""
		)
		if pass_gate:
			allowed_projectiles.append(projectile_type)
			gate_passes += 1
			_b1_gate_passes += 1
			route_quality_sum += float((lanes[lane_index] as Dictionary).get("route_quality", 1.0))
		else:
			gate_reflections += 1
			_b1_gate_reflections += 1
	return {"allowed_shots": allowed_projectiles.size(), "allowed_projectiles": allowed_projectiles, "gate_passes": gate_passes, "gate_reflections": gate_reflections, "river_bank_reflections": river_reflections, "average_route_quality": route_quality_sum / float(maxi(1, allowed_projectiles.size()))}

func _lane_gate_snapshot(lane_index: int, territory: Dictionary, round_number: int) -> Dictionary:
	var lanes: Array = ((_b1_map_definition.get("route_layout", {}) as Dictionary).get("lanes", []) as Array)
	if lane_index < 0 or lane_index >= lanes.size():
		return {"state": B1GateRulesScript.STATE_OPEN, "owner_slot": "", "control_percent": 50}
	var lane: Dictionary = lanes[lane_index] as Dictionary
	var blue_slot: String = SLOT_A if _b1_side_variant == 0 else SLOT_B
	var blue_sign_for_a: float = 1.0 if blue_slot == SLOT_A else -1.0
	var share_a: float = 0.5 + float(territory[SLOT_A] - territory[SLOT_B]) * 1.15
	share_a += float(lane.get("blue_side_bias", 0.0)) * blue_sign_for_a
	share_a += (_b1_hash_unit(_b1_seed_value, lane_index * 97 + round_number * 31) - 0.5) * 0.035
	share_a = clampf(share_a, 0.0, 1.0)
	var owner_slot: String = SLOT_A if share_a >= 0.5 else SLOT_B
	var control_ratio: float = maxf(share_a, 1.0 - share_a)
	var resolved: Dictionary = B1GateRulesScript.state_from_control(
		owner_slot,
		roundi(control_ratio * 1000.0),
		1000,
		""
	)
	return {
		"state": str(resolved.get("state", B1GateRulesScript.STATE_OPEN)),
		"owner": str(resolved.get("owner", "")),
		"owner_slot": str(resolved.get("owner", "")),
		"control_percent": int(resolved.get("control_percent", 0)),
		"openness": float(resolved.get("openness", 1.0)),
		"lane_index": lane_index,
	}


func _choose_lane_index(lanes: Array, rng: RandomNumberGenerator) -> int:
	var total_weight: float = 0.0
	for raw_lane in lanes:
		total_weight += maxf(0.001, float((raw_lane as Dictionary).get("traffic_weight", 1.0)))
	var cursor: float = rng.randf() * total_weight
	for index in range(lanes.size()):
		cursor -= maxf(0.001, float((lanes[index] as Dictionary).get("traffic_weight", 1.0)))
		if cursor <= 0.0:
			return index
	return maxi(0, lanes.size() - 1)


func _resolve_projectile_defense_contact(state: Dictionary, pierce_layers: int, rng: RandomNumberGenerator) -> Dictionary:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var chosen_index: int = _choose_defended_cell_index(state, rng)
	if chosen_index < 0 or chosen_index >= defense_cells.size():
		return {"absorbed": false, "pierced_layers": 0}
	var pierced: int = 0
	for _index in range(maxi(0, pierce_layers)):
		if int(defense_cells[chosen_index]) <= 0:
			break
		defense_cells[chosen_index] = int(defense_cells[chosen_index]) - 1
		pierced += 1
	if int(defense_cells[chosen_index]) <= 0:
		return {"absorbed": false, "pierced_layers": pierced}
	defense_cells[chosen_index] = maxi(0, int(defense_cells[chosen_index]) - 1)
	return {"absorbed": true, "pierced_layers": pierced}

func _choose_defended_cell_index(state: Dictionary, rng: RandomNumberGenerator) -> int:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var candidates: Array[int] = []
	for index in range(mini(defense_cells.size(), owned_cells.size())):
		if bool(owned_cells[index]) and int(defense_cells[index]) > 0:
			candidates.append(index)
	return -1 if candidates.is_empty() else candidates[rng.randi_range(0, candidates.size() - 1)]

func _sample_index_set(total: int, count: int, rng: RandomNumberGenerator) -> Dictionary:
	var indices: Array[int] = []
	for index in range(maxi(0, total)):
		indices.append(index)
	for index in range(indices.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var temp: int = indices[index]
		indices[index] = indices[swap_index]
		indices[swap_index] = temp
	var result: Dictionary = {}
	for index in range(mini(maxi(0, count), indices.size())):
		result[indices[index]] = true
	return result

func _grant_captured_frontline_cells(state: Dictionary, amount: int) -> void:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var initial_front: Array = state.get("virtual_initial_contact_front", []) as Array
	var captured_defense: int = clampi(int(state.get("captured_frontline_defense", 0)), 0, int(state.get("territory_defense_cap", 1)))
	for _index in range(maxi(0, amount)):
		defense_cells.append(captured_defense)
		owned_cells.append(true)
		initial_front.append(true)


func _consume_virtual_defense(
	state: Dictionary,
	contacts: int,
	armor_contacts: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var absorbed: int = 0
	var pierced: int = mini(contacts, maxi(0, armor_contacts))
	for _contact in range(maxi(0, contacts - pierced)):
		var candidates: Array[int] = []
		for index in range(mini(defense_cells.size(), owned_cells.size())):
			if bool(owned_cells[index]) and int(defense_cells[index]) > 0:
				candidates.append(index)
		if candidates.is_empty():
			break
		var chosen_index: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		defense_cells[chosen_index] = maxi(0, int(defense_cells[chosen_index]) - 1)
		absorbed += 1
	return {"absorbed": absorbed, "pierced": pierced}


func _repair_virtual_cells(state: Dictionary, amount: int) -> int:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var initial_front: Array = state.get("virtual_initial_contact_front", []) as Array
	var cap: int = maxi(1, int(state.get("territory_defense_cap", 1)))
	var candidates: Array[int] = []
	for index in range(mini(defense_cells.size(), owned_cells.size())):
		if bool(owned_cells[index]) and int(defense_cells[index]) < cap:
			candidates.append(index)
	candidates.sort_custom(func(left: int, right: int) -> bool:
		var left_front: bool = left < initial_front.size() and bool(initial_front[left])
		var right_front: bool = right < initial_front.size() and bool(initial_front[right])
		if left_front != right_front:
			return left_front
		if int(defense_cells[left]) != int(defense_cells[right]):
			return int(defense_cells[left]) < int(defense_cells[right])
		return left < right
	)
	var applied: int = 0
	for index in range(mini(maxi(0, amount), candidates.size())):
		var cell_index: int = candidates[index]
		defense_cells[cell_index] = mini(cap, int(defense_cells[cell_index]) + 1)
		applied += 1
	return applied


func _capture_virtual_cells(state: Dictionary, amount: int, rng: RandomNumberGenerator) -> int:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var captured: int = 0
	for _index in range(maxi(0, amount)):
		var candidates: Array[int] = []
		for cell_index in range(mini(defense_cells.size(), owned_cells.size())):
			if bool(owned_cells[cell_index]) and int(defense_cells[cell_index]) <= 0:
				candidates.append(cell_index)
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
	var recaptured: int = 0
	for _index in range(maxi(0, amount)):
		var candidates: Array[int] = []
		for cell_index in range(owned_cells.size()):
			if not bool(owned_cells[cell_index]):
				candidates.append(cell_index)
		if candidates.is_empty():
			break
		var chosen: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		owned_cells[chosen] = true
		defense_cells[chosen] = clampi(int(state.get("captured_frontline_defense", 0)), 0, int(state.get("territory_defense_cap", 1)))
		recaptured += 1
	return recaptured


func _sum_owned_defense(state: Dictionary) -> int:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var total: int = 0
	for index in range(mini(defense_cells.size(), owned_cells.size())):
		if bool(owned_cells[index]):
			total += maxi(0, int(defense_cells[index]))
	return total


func _route_pressure_for_state(state: Dictionary) -> float:
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var owned_count: int = 0
	for owned in owned_cells:
		if bool(owned):
			owned_count += 1
	return clampf(1.0 + float(VIRTUAL_CELL_COUNT - owned_count) / 20.0, 0.75, 2.5)


func _reset_b1_metrics() -> void:
	_b1_gate_passes = 0
	_b1_gate_reflections = 0
	_b1_river_bank_reflections = 0
	_b1_gate_state_crossings = {
		B1GateRulesScript.STATE_OPEN: 0,
		B1GateRulesScript.STATE_HALF_OPEN: 0,
		B1GateRulesScript.STATE_CLOSED: 0,
	}
	_b1_lane_traffic = {"0": 0, "1": 0}
	_b1_virtual_captures = 0
	_b1_virtual_recaptures = 0
	_b1_card_appearances = {}
	_b1_card_selections = {}
	_b1_card_applications = {}
	_b1_card_waste = {}
	_b1_card_by_hero = {}
	for hero_id in B1HeroRegistryScript.get_hero_ids():
		_b1_card_by_hero[str(hero_id)] = {"appearances": {}, "selections": {}, "applications": {}, "wasted_units": {}}
	for raw_id in B1UpgradeManifestScript.get_upgrade_ids():
		var upgrade_id: String = str(raw_id)
		_b1_card_appearances[upgrade_id] = 0
		_b1_card_selections[upgrade_id] = 0
		_b1_card_applications[upgrade_id] = 0
		_b1_card_waste[upgrade_id] = 0.0
	_b1_projectile_fired.clear()
	_b1_projectile_chamber_contacts.clear()
	_b1_projectile_damage_units.clear()
	_b1_projectile_defense_pierce.clear()

func _increment_metric(target: Dictionary, key: String, amount: float) -> void:
	var current = target.get(key, 0)
	if current is int and is_equal_approx(amount, roundf(amount)):
		target[key] = int(current) + int(roundi(amount))
	else:
		target[key] = float(current) + amount


func _increment_hero_card_metric(state: Dictionary, category: String, upgrade_id: String, amount: float) -> void:
	var hero_id: String = str(state.get("hero_id", "unknown"))
	if not _b1_card_by_hero.has(hero_id):
		_b1_card_by_hero[hero_id] = {"appearances": {}, "selections": {}, "applications": {}, "wasted_units": {}}
	var hero_metrics: Dictionary = _b1_card_by_hero[hero_id] as Dictionary
	var category_metrics: Dictionary = hero_metrics.get(category, {}) as Dictionary
	_increment_metric(category_metrics, upgrade_id, amount)
	hero_metrics[category] = category_metrics


func _position_signature(map_id: String, side_variant: int) -> String:
	var blue_slot: String = SLOT_A if side_variant == 0 else SLOT_B
	return "%s:blue=%s" % [map_id, blue_slot]


func _b1_stream_seed(seed_value: int, round_number: int, slot: String, _side_variant: int) -> int:
	return abs(
		int(seed_value) * 1103515245
		+ int(round_number) * 12345
		+ str(slot).hash() * 97
		+ str(_b1_map_definition.get("id", "")).hash()
	)


func _b1_hash_unit(seed_value: int, salt: int) -> float:
	var value: int = abs(int(seed_value) * 1664525 + int(salt) * 1013904223 + 69069)
	return float(value % 1000003 + 1) / 1000004.0
