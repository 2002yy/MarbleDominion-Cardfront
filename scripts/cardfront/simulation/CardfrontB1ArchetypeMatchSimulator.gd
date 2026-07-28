extends CardfrontB1ParityMatchSimulator
class_name CardfrontB1ArchetypeMatchSimulator

const ArchetypeProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")


func composition_followthrough_for_test(projectile_sequence: Array) -> float:
	return ArchetypeProjectileTypeScript.standard_followthrough_multiplier(projectile_sequence)


func _resolve_volley(
	attacker_slot: String,
	target_slot: String,
	plan_data: Dictionary,
	states: Dictionary,
	territory: Dictionary,
	_defense_pool: Dictionary,
	profile: Dictionary,
	seed_value: int,
	round_number: int,
	simulation_mode: String
) -> Dictionary:
	var adjusted_profile: Dictionary = profile.duplicate(true)
	adjusted_profile["chamber_hit_chance"] = float(adjusted_profile.get("chamber_hit_chance", 0.17)) * _tail_stall_multiplier(
		_b1_map_definition,
		_b1_seed_value
	)

	var plan: Dictionary = plan_data["plan"] as Dictionary
	var rng: RandomNumberGenerator = _rng_a if attacker_slot == SLOT_A else _rng_b
	rng.seed = _b1_stream_seed(seed_value, round_number, attacker_slot, _b1_side_variant)
	var projectile_sequence: Array = (plan.get("projectile_sequence", []) as Array).duplicate()
	if projectile_sequence.is_empty():
		ArchetypeProjectileTypeScript.append_standard(projectile_sequence, int(plan.get("shot_count", 0)))
	var shot_count: int = projectile_sequence.size()
	var standard_followthrough: float = ArchetypeProjectileTypeScript.standard_followthrough_multiplier(projectile_sequence)
	for raw_type in projectile_sequence:
		_increment_metric(_b1_projectile_fired, ArchetypeProjectileTypeScript.sanitize(str(raw_type)), 1.0)

	var route_result: Dictionary = _resolve_routes(
		projectile_sequence,
		attacker_slot,
		target_slot,
		territory,
		round_number,
		rng
	)
	var allowed_projectiles: Array = route_result.get("allowed_projectiles", []) as Array
	var target_state: Dictionary = states[target_slot] as Dictionary
	var defense_chance: float = clampf(
		float(adjusted_profile.get("defense_contact_chance", 0.13))
		+ float(target_state.get("territory_defense_cap", 1)) * 0.045
		+ float(territory[target_slot]) * 0.035,
		0.0,
		0.7
	)
	var expected_contacts: float = float(allowed_projectiles.size()) * defense_chance
	var defense_contacts: int = clampi(
		roundi(expected_contacts + rng.randfn(0.0, sqrt(maxf(0.01, expected_contacts * (1.0 - defense_chance))))),
		0,
		allowed_projectiles.size()
	)
	var contact_indices: Dictionary = _prioritized_defense_contact_indices(
		allowed_projectiles,
		defense_contacts,
		rng
	)
	var armor_remaining: int = maxi(0, int(plan.get("armor_pierce_contacts", 0)))
	var defense_absorbed: int = 0
	var survivors: Array = []
	for index in range(allowed_projectiles.size()):
		var projectile_type: String = ArchetypeProjectileTypeScript.sanitize(str(allowed_projectiles[index]))
		if not contact_indices.has(index):
			survivors.append(projectile_type)
			continue
		var pierce_layers: int = ArchetypeProjectileTypeScript.defense_pierce_layers(projectile_type)
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

	var intents: Dictionary = _partition_survivor_intents(survivors)
	var chamber_candidates: Array = intents.get("chamber_candidates", []) as Array
	var territory_only: Array = intents.get("territory_only", []) as Array
	var territory_to_chamber_hit: float = float(adjusted_profile.get("territory_to_chamber_hit", 0.0))
	var base_hit_chance: float = clampf(
		float(adjusted_profile.get("chamber_hit_chance", 0.17))
		+ float(territory[attacker_slot] - territory[target_slot]) * territory_to_chamber_hit,
		0.08,
		0.65
	)
	base_hit_chance *= pow(6.0 / float(maxi(1, shot_count)), 0.18)
	base_hit_chance *= float(route_result.get("average_route_quality", 1.0))
	base_hit_chance = adjust_hit_chance_for_mode(
		base_hit_chance,
		int((states[attacker_slot] as Dictionary).get("base_volley_count", 6)),
		simulation_mode
	)

	var chamber_hits: int = 0
	var damage_units: float = 0.0
	var territory_contacts: float = 0.0
	for raw_type in territory_only:
		territory_contacts += ArchetypeProjectileTypeScript.territory_pressure_units(str(raw_type))
	for raw_type in chamber_candidates:
		var projectile_type: String = ArchetypeProjectileTypeScript.sanitize(str(raw_type))
		var projectile_hit_chance: float = base_hit_chance
		if projectile_type == ArchetypeProjectileTypeScript.STANDARD:
			projectile_hit_chance *= standard_followthrough
		projectile_hit_chance = clampf(projectile_hit_chance, 0.02, 0.75)
		if rng.randf() <= projectile_hit_chance:
			chamber_hits += 1
			_increment_metric(_b1_projectile_chamber_contacts, projectile_type, 1.0)
			var units: float = ArchetypeProjectileTypeScript.direct_damage_units(projectile_type)
			damage_units += units
			_increment_metric(_b1_projectile_damage_units, projectile_type, units)
		else:
			var pressure_units: float = ArchetypeProjectileTypeScript.territory_pressure_units(projectile_type)
			if projectile_type == ArchetypeProjectileTypeScript.STANDARD:
				pressure_units *= standard_followthrough
			territory_contacts += pressure_units

	var attacker_state: Dictionary = states[attacker_slot] as Dictionary
	var recaptured: int = _recapture_virtual_cells(
		attacker_state,
		mini(MAX_CAPTURE_UPDATES_PER_VOLLEY, floori(territory_contacts * 0.25)),
		rng
	)
	var captured: int = _capture_virtual_cells(
		target_state,
		mini(MAX_CAPTURE_UPDATES_PER_VOLLEY, maxi(0, floori(territory_contacts) - recaptured)),
		rng
	)
	_grant_captured_frontline_cells(attacker_state, captured)
	_b1_virtual_recaptures += recaptured
	_b1_virtual_captures += captured
	var average_cells: float = float(adjusted_profile.get("average_cells_crossed", 19.0))
	var reflected_shots: int = shot_count - allowed_projectiles.size()
	var cells_crossed: float = maxf(
		float(shot_count) * 3.0,
		float(allowed_projectiles.size()) * average_cells
		+ float(reflected_shots) * average_cells * 0.35
		+ rng.randfn(0.0, sqrt(float(maxi(1, shot_count))) * 2.0)
	)
	return {
		"shot_count": shot_count,
		"chamber_hits": chamber_hits,
		"damage_quarters": roundi(damage_units * float(4 + int(plan_data.get("attack_level", 0)))),
		"defense_absorbed": defense_absorbed,
		"territory_contacts": territory_contacts,
		"standard_followthrough": standard_followthrough,
		"cells_crossed": cells_crossed,
		"gate_passes": int(route_result.get("gate_passes", 0)),
		"gate_reflections": int(route_result.get("gate_reflections", 0)),
		"river_bank_reflections": int(route_result.get("river_bank_reflections", 0)),
		"virtual_captures": captured,
		"virtual_recaptures": recaptured,
	}