extends RefCounted
class_name CardfrontBalanceMatchSimulator

const ConfigScript = preload("res://scripts/cardfront/simulation/CardfrontBalanceSimulationConfig.gd")
const DraftSystemScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDraftSystem.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const MapRegistryScript = preload("res://scripts/cardfront/maps/CardfrontMapRegistry.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")
const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const VolleyResolverScript = preload("res://scripts/cardfront/volley/CardfrontVolleyResolver.gd")

const SLOT_A: String = "a"
const SLOT_B: String = "b"

var _rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
var _rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
var _upgrade_ids: Array = []
var _upgrade_definitions: Dictionary = {}


func _init() -> void:
	_upgrade_ids = UpgradeManifestScript.get_upgrade_ids()
	for upgrade_id in _upgrade_ids:
		_upgrade_definitions[str(upgrade_id)] = UpgradeManifestScript.get_definition(str(upgrade_id))


func _simulation_max_rounds() -> int:
	return ConfigScript.MAX_ROUNDS


func _drafts_enabled() -> bool:
	return true


func _strongholds_enabled() -> bool:
	return true


func simulate(
	hero_a: String,
	hero_b: String,
	map_id: String,
	side_variant: int,
	seed_value: int,
	simulation_mode: String = ConfigScript.DEFAULT_SIMULATION_MODE
) -> Dictionary:
	var safe_simulation_mode: String = ConfigScript.sanitize_simulation_mode(simulation_mode)
	var map_definition: Dictionary = MapRegistryScript.get_map_definition(map_id, ConfigScript.GRID_SIZE)
	if map_definition.is_empty():
		return {"success": false, "reason": "unknown_map", "simulation_mode": safe_simulation_mode}

	var profile: Dictionary = ConfigScript.sanitize_map_profile(
		map_definition.get("simulation_profile", {}) as Dictionary
	)
	if _hash_unit(seed_value, str(map_id).hash()) < 0.17:
		profile["chamber_hit_chance"] = float(profile["chamber_hit_chance"]) * 0.28
	var states: Dictionary = {
		SLOT_A: _make_state(hero_a, 1),
		SLOT_B: _make_state(hero_b, 2),
	}
	var health_quarters: Dictionary = {
		SLOT_A: int((states[SLOT_A] as Dictionary)["command_chamber_health"]) * 4,
		SLOT_B: int((states[SLOT_B] as Dictionary)["command_chamber_health"]) * 4,
	}
	var max_health_quarters: Dictionary = health_quarters.duplicate()
	var territory: Dictionary = {SLOT_A: 0.25, SLOT_B: 0.25}
	var defense_pool: Dictionary = {
		SLOT_A: int((states[SLOT_A] as Dictionary)["starting_territory_defense"]) * 18,
		SLOT_B: int((states[SLOT_B] as Dictionary)["starting_territory_defense"]) * 18,
	}
	var active_strongholds: Dictionary = {SLOT_A: [], SLOT_B: []}
	var first_stronghold_round: Dictionary = {SLOT_A: 0, SLOT_B: 0}
	var activation_rounds: Dictionary = {
		SLOT_A: _first_activation_round(seed_value, SLOT_A, int(profile["stronghold_tempo"])),
		SLOT_B: _first_activation_round(seed_value, SLOT_B, int(profile["stronghold_tempo"])),
	}
	var available_types: Array = _stronghold_types(map_definition)
	var slot_metrics: Dictionary = {
		SLOT_A: _empty_slot_metrics(),
		SLOT_B: _empty_slot_metrics(),
	}
	var metrics: Dictionary = {
		"cells_crossed": 0.0,
		"shot_count": 0,
		"chamber_hits": 0,
		"volleys": 0,
		"defense_absorbed": 0,
		"invalid_offers": 0,
	}
	var winner_slot: String = ""
	var draw: bool = false
	var timed_out: bool = false
	var max_rounds: int = maxi(1, _simulation_max_rounds())
	var resolved_round: int = max_rounds

	for round_number in range(1, max_rounds + 1):
		if _strongholds_enabled():
			for slot in [SLOT_A, SLOT_B]:
				_activate_strongholds(
					slot,
					round_number,
					activation_rounds,
					available_types,
					active_strongholds,
					first_stronghold_round
				)

		var plans: Dictionary = {}
		for slot in [SLOT_A, SLOT_B]:
			var state: Dictionary = states[slot] as Dictionary
			var strongholds: Array = active_strongholds[slot] as Array
			if _drafts_enabled():
				var offer_size: int = (
					StrongholdRulesScript.LAB_DRAFT_CHOICE_COUNT
						if RegionTypeScript.LAB in strongholds
						else DraftSystemScript.DEFAULT_OFFER_SIZE
				)
				var offer_ids: Array = _draw_offer_ids_fast(
					state,
					offer_size,
					_stream_seed(seed_value, round_number, str(slot), 11)
				)
				if offer_ids.size() != offer_size:
					metrics["invalid_offers"] = int(metrics["invalid_offers"]) + 1
				var choice_id: String = _choose_upgrade_id_fast(offer_ids, state)
				if choice_id == "":
					metrics["invalid_offers"] = int(metrics["invalid_offers"]) + 1
				elif not _resolve_upgrade_fast(state, choice_id):
					metrics["invalid_offers"] = int(metrics["invalid_offers"]) + 1

			defense_pool[slot] = int(defense_pool[slot]) + int(state["pending_repair_points"])
			state["pending_repair_points"] = 0
			if RegionTypeScript.FACTORY in strongholds:
				state["next_volley_bonus"] = int(state["next_volley_bonus"]) + StrongholdRulesScript.FACTORY_SHOT_BONUS
			var plan: Dictionary = _build_and_consume_volley_fast(state)
			var temporary_attack_level: int = (
				StrongholdRulesScript.ENERGY_ATTACK_LEVEL_BONUS
				if RegionTypeScript.ENERGY in strongholds
				else 0
			)
			plans[slot] = {
				"plan": plan,
				"attack_level": resolve_attack_level_for_mode(
					int(plan["attack_level"]),
					temporary_attack_level,
					safe_simulation_mode
				),
			}

		var round_results: Dictionary = {}
		round_results[SLOT_A] = _resolve_volley(
			SLOT_A,
			SLOT_B,
			plans[SLOT_A] as Dictionary,
			states,
			territory,
			defense_pool,
			profile,
			seed_value,
			round_number,
			safe_simulation_mode
		)
		round_results[SLOT_B] = _resolve_volley(
			SLOT_B,
			SLOT_A,
			plans[SLOT_B] as Dictionary,
			states,
			territory,
			defense_pool,
			profile,
			seed_value,
			round_number,
			safe_simulation_mode
		)
		for slot in [SLOT_A, SLOT_B]:
			var volley_result: Dictionary = round_results[slot] as Dictionary
			var target_slot: String = SLOT_B if slot == SLOT_A else SLOT_A
			health_quarters[target_slot] = int(health_quarters[target_slot]) - int(volley_result["damage_quarters"])
			metrics["cells_crossed"] = float(metrics["cells_crossed"]) + float(volley_result["cells_crossed"])
			metrics["shot_count"] = int(metrics["shot_count"]) + int(volley_result["shot_count"])
			metrics["chamber_hits"] = int(metrics["chamber_hits"]) + int(volley_result["chamber_hits"])
			metrics["defense_absorbed"] = int(metrics["defense_absorbed"]) + int(volley_result["defense_absorbed"])
			metrics["volleys"] = int(metrics["volleys"]) + 1
			var attacker_metrics: Dictionary = slot_metrics[slot] as Dictionary
			var defender_metrics: Dictionary = slot_metrics[target_slot] as Dictionary
			attacker_metrics["shots_fired"] = int(attacker_metrics["shots_fired"]) + int(volley_result["shot_count"])
			attacker_metrics["chamber_damage_dealt_quarters"] = int(attacker_metrics["chamber_damage_dealt_quarters"]) + int(volley_result["damage_quarters"])
			attacker_metrics["territory_contacts"] = float(attacker_metrics["territory_contacts"]) + float(volley_result["territory_contacts"])
			attacker_metrics["gate_passes"] = int(attacker_metrics["gate_passes"]) + int(volley_result.get("gate_passes", 0))
			attacker_metrics["route_rejections"] = int(attacker_metrics["route_rejections"]) + int(volley_result.get("gate_reflections", 0)) + int(volley_result.get("river_bank_reflections", 0))
			attacker_metrics["virtual_captures"] = int(attacker_metrics["virtual_captures"]) + int(volley_result.get("virtual_captures", 0))
			attacker_metrics["virtual_recaptures"] = int(attacker_metrics["virtual_recaptures"]) + int(volley_result.get("virtual_recaptures", 0))
			defender_metrics["defense_absorbed"] = int(defender_metrics["defense_absorbed"]) + int(volley_result["defense_absorbed"])

		_apply_territory_pressure(territory, round_results, profile)
		var a_destroyed: bool = int(health_quarters[SLOT_A]) <= 0
		var b_destroyed: bool = int(health_quarters[SLOT_B]) <= 0
		if a_destroyed or b_destroyed:
			resolved_round = round_number
			if a_destroyed and b_destroyed:
				draw = true
			else:
				winner_slot = SLOT_B if a_destroyed else SLOT_A
			break

	if winner_slot == "" and not draw:
		timed_out = true
		var score_a: float = _timeout_score(
			int(health_quarters[SLOT_A]),
			int(max_health_quarters[SLOT_A]),
			float(territory[SLOT_A]),
			(active_strongholds[SLOT_A] as Array).size()
		)
		var score_b: float = _timeout_score(
			int(health_quarters[SLOT_B]),
			int(max_health_quarters[SLOT_B]),
			float(territory[SLOT_B]),
			(active_strongholds[SLOT_B] as Array).size()
		)
		if absf(score_a - score_b) < 0.01:
			draw = true
		else:
			winner_slot = SLOT_A if score_a > score_b else SLOT_B

	var blue_slot: String = SLOT_A if int(side_variant) % 2 == 0 else SLOT_B
	var winner_side: String = ""
	if winner_slot != "":
		winner_side = "blue" if winner_slot == blue_slot else "red"
	return {
		"success": true,
		"simulation_mode": safe_simulation_mode,
		"hidden_hit_compensation": ConfigScript.uses_hidden_hit_compensation(safe_simulation_mode),
		"resolved_attack_level_cap": ConfigScript.resolved_attack_level_cap(safe_simulation_mode),
		"hero_a": str(hero_a),
		"hero_b": str(hero_b),
		"map_id": str(map_id),
		"side_variant": int(side_variant) % 2,
		"winner_slot": winner_slot,
		"winner_side": winner_side,
		"draw": draw,
		"timed_out": timed_out,
		"round_count": resolved_round,
		"health_quarters": health_quarters,
		"territory": territory,
		"active_strongholds": active_strongholds,
		"first_stronghold_round": first_stronghold_round,
		"metrics": metrics,
		"slot_metrics": slot_metrics,
		"state_snapshots": {
			SLOT_A: (states[SLOT_A] as Dictionary).duplicate(true),
			SLOT_B: (states[SLOT_B] as Dictionary).duplicate(true),
		},
	}


func _empty_slot_metrics() -> Dictionary:
	return {
		"shots_fired": 0,
		"chamber_damage_dealt_quarters": 0,
		"territory_contacts": 0.0,
		"defense_absorbed": 0,
		"gate_passes": 0,
		"route_rejections": 0,
		"virtual_captures": 0,
		"virtual_recaptures": 0,
	}


func resolve_attack_level_for_mode(
	permanent_attack_level: int,
	temporary_attack_level: int,
	simulation_mode: String = ConfigScript.DEFAULT_SIMULATION_MODE
) -> int:
	return clampi(
		maxi(0, int(permanent_attack_level)) + maxi(0, int(temporary_attack_level)),
		0,
		ConfigScript.resolved_attack_level_cap(simulation_mode)
	)


func adjust_hit_chance_for_mode(
	hit_chance: float,
	base_volley_count: int,
	simulation_mode: String = ConfigScript.DEFAULT_SIMULATION_MODE
) -> float:
	var adjusted: float = float(hit_chance)
	if not ConfigScript.uses_hidden_hit_compensation(simulation_mode):
		return adjusted
	if int(base_volley_count) < 6:
		adjusted *= 1.22
	elif int(base_volley_count) > 6:
		adjusted *= 0.93
	return adjusted


func _make_state(hero_id: String, owner_id: int) -> Dictionary:
	var definition: Dictionary = HeroRegistryScript.get_definition(hero_id)
	return {
		"owner_id": owner_id,
		"hero_id": hero_id,
		"base_volley_count": int(definition.get("base_volley_count", 6)),
		"command_chamber_health": int(definition.get("command_chamber_health", 40)),
		"starting_territory_defense": int(definition.get("starting_territory_defense", 1)),
		"attack_level": 0,
		"territory_defense_cap": int(definition.get("territory_defense_cap", 1)),
		"rarity_level": 0,
		"echo_next_choice_armed": false,
		"queued_echo_upgrade_id": "",
		"next_volley_bonus": 0,
		"next_volley_multiplier": 1,
		"next_volley_armor_pierce_contacts": 0,
		"pending_repair_points": 0,
		"owned_creature_count": 0,
		"owned_defense_tower_count": 0,
		"tower_levels": {},
		"building_volley_level": 0,
		"heavy_charge_armed": false,
		"applied_upgrade_counts": {},
	}


func _resolve_volley(
	attacker_slot: String,
	target_slot: String,
	plan_data: Dictionary,
	states: Dictionary,
	territory: Dictionary,
	defense_pool: Dictionary,
	profile: Dictionary,
	seed_value: int,
	round_number: int,
	simulation_mode: String
) -> Dictionary:
	var plan = plan_data["plan"]
	var rng: RandomNumberGenerator = _rng_a if attacker_slot == SLOT_A else _rng_b
	rng.seed = _stream_seed(seed_value, round_number, attacker_slot, 29)
	var armor_contacts: int = maxi(0, int(plan["armor_pierce_contacts"]))
	var target_state: Dictionary = states[target_slot] as Dictionary
	var defense_chance: float = clampf(
		float(profile["defense_contact_chance"])
		+ float(target_state["territory_defense_cap"]) * 0.045
		+ float(territory[target_slot]) * 0.035,
		0.0,
		0.7
	)
	var shot_count: int = int(plan["shot_count"])
	var hit_chance: float = clampf(
		float(profile["chamber_hit_chance"])
		+ float(territory[attacker_slot] - territory[target_slot]) * 0.10,
		0.08,
		0.65
	)
	hit_chance *= pow(6.0 / float(maxi(1, shot_count)), 0.18)
	var base_volley: int = int((states[attacker_slot] as Dictionary)["base_volley_count"])
	hit_chance = adjust_hit_chance_for_mode(hit_chance, base_volley, simulation_mode)
	var expected_contacts: float = float(shot_count) * defense_chance
	var contact_sigma: float = sqrt(maxf(0.01, expected_contacts * (1.0 - defense_chance)))
	var defense_contacts: int = clampi(
		roundi(expected_contacts + rng.randfn(0.0, contact_sigma)),
		0,
		mini(shot_count, int(defense_pool[target_slot]) + armor_contacts)
	)
	var pierced_contacts: int = mini(defense_contacts, armor_contacts)
	var defense_absorbed: int = mini(
		defense_contacts - pierced_contacts,
		int(defense_pool[target_slot])
	)
	defense_pool[target_slot] = int(defense_pool[target_slot]) - defense_absorbed
	var remaining_shots: int = shot_count - defense_absorbed
	var expected_hits: float = float(remaining_shots) * hit_chance
	var hit_sigma: float = sqrt(maxf(0.01, expected_hits * (1.0 - hit_chance)))
	var chamber_hits: int = clampi(
		roundi(expected_hits + rng.randfn(0.0, hit_sigma)),
		0,
		remaining_shots
	)
	var territory_contacts: int = remaining_shots - chamber_hits
	var cells_crossed: float = maxf(
		float(shot_count) * 4.0,
		float(shot_count) * float(profile["average_cells_crossed"])
		+ rng.randfn(0.0, sqrt(float(maxi(1, shot_count))) * 3.0)
	)
	var attack_level: int = int(plan_data["attack_level"])
	return {
		"shot_count": shot_count,
		"chamber_hits": chamber_hits,
		"damage_quarters": chamber_hits * (4 + attack_level),
		"defense_absorbed": defense_absorbed,
		"territory_contacts": territory_contacts,
		"cells_crossed": cells_crossed,
	}


func _draw_offer_ids_fast(state: Dictionary, offer_size: int, seed_value: int) -> Array:
	var ranked: Array = []
	for raw_upgrade_id in _upgrade_ids:
		var upgrade_id: String = str(raw_upgrade_id)
		if not _is_upgrade_eligible_fast(upgrade_id, state):
			continue
		var definition: Dictionary = _upgrade_definitions[upgrade_id] as Dictionary
		var weight: float = _rarity_weight(str(definition.get("rarity", "")), int(state["rarity_level"]))
		var uniform: float = maxf(0.000001, _hash_unit(seed_value, upgrade_id.hash()))
		ranked.append({"id": upgrade_id, "rank": -log(uniform) / maxf(0.001, weight)})
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["rank"]) < float(right["rank"]))
	var result: Array = []
	for index in range(mini(offer_size, ranked.size())):
		result.append(str((ranked[index] as Dictionary)["id"]))
	return result


func _choose_upgrade_id_fast(offer_ids: Array, state: Dictionary) -> String:
	var best_id: String = ""
	var best_score: float = -INF
	for index in range(offer_ids.size()):
		var upgrade_id: String = str(offer_ids[index])
		var score: float = _upgrade_score_fast(upgrade_id, state) - float(index) * 0.001
		if score > best_score:
			best_score = score
			best_id = upgrade_id
	return best_id


func _upgrade_score_fast(upgrade_id: String, state: Dictionary) -> float:
	var base_volley: int = int(state["base_volley_count"])
	var attack_level: int = int(state["attack_level"])
	var growth: int = 0
	for count in (state["applied_upgrade_counts"] as Dictionary).values():
		growth += int(count)
	match upgrade_id:
		UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1:
			return 88.0 - float(attack_level) * 7.0
		UpgradeManifestScript.UPGRADE_VOLLEY_X2:
			return 92.0
		UpgradeManifestScript.UPGRADE_ARMOR_PIERCING:
			return 82.0
		UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
			return 78.0
		UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
			return 74.0 + float(maxi(0, int(state["territory_defense_cap"]) - 1)) * 16.0
		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5:
			return 64.0 + float(maxi(0, 10 - base_volley)) * 1.8
		UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
			return 62.0 + maxf(0.0, 16.0 - float(growth) * 3.0)
		UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
			return 68.0 + float(mini(growth, 5))
		UpgradeManifestScript.UPGRADE_REPAIR_UNITS:
			return 66.0
		UpgradeManifestScript.UPGRADE_FIRE_CONTROL_BEACON:
			return 72.0 + float(int((state.get("tower_levels", {}) as Dictionary).get("fire_control_beacon", 0))) * 4.0
		UpgradeManifestScript.UPGRADE_INTERCEPTOR_TOWER:
			return 76.0 + float(int((state.get("tower_levels", {}) as Dictionary).get("interceptor_tower", 0))) * 4.0
		UpgradeManifestScript.UPGRADE_BUILDING_VOLLEY:
			return 70.0 + float(int(state.get("owned_defense_tower_count", 0))) * 9.0
		UpgradeManifestScript.UPGRADE_HEAVY_CHARGE:
			return 74.0
	return 0.0


func _resolve_upgrade_fast(state: Dictionary, upgrade_id: String) -> bool:
	var echoed_id: String = str(state["queued_echo_upgrade_id"])
	state["queued_echo_upgrade_id"] = ""
	if echoed_id != "" and not _apply_upgrade_once_fast(state, echoed_id):
		return false
	var should_queue_echo: bool = bool(state["echo_next_choice_armed"])
	state["echo_next_choice_armed"] = false
	if not _apply_upgrade_once_fast(state, upgrade_id):
		return false
	_record_upgrade_fast(state, upgrade_id)
	if echoed_id != "":
		_record_upgrade_fast(state, echoed_id)
	if should_queue_echo:
		state["queued_echo_upgrade_id"] = upgrade_id
	return true


func _apply_upgrade_once_fast(state: Dictionary, upgrade_id: String) -> bool:
	var definition: Dictionary = _upgrade_definitions.get(upgrade_id, {}) as Dictionary
	if definition.is_empty():
		return false
	var params: Dictionary = definition.get("params", {}) as Dictionary
	match str(definition.get("effect_id", "")):
		"add_next_volley":
			state["next_volley_bonus"] = int(state["next_volley_bonus"]) + maxi(0, int(params.get("amount", 0)))
		"multiply_next_volley":
			state["next_volley_multiplier"] = clampi(maxi(int(state["next_volley_multiplier"]), int(params.get("multiplier", 1))), 1, 2)
		"increase_attack_level":
			state["attack_level"] = clampi(int(state["attack_level"]) + int(params.get("amount", 0)), 0, RunStateScript.MAX_ATTACK_LEVEL)
		"increase_defense_cap":
			state["territory_defense_cap"] = clampi(int(state["territory_defense_cap"]) + int(params.get("amount", 0)), 1, RunStateScript.MAX_TERRITORY_DEFENSE_CAP)
		"repair_territory":
			state["pending_repair_points"] = int(state["pending_repair_points"]) + maxi(0, int(params.get("amount", 0)))
		"add_armor_pierce":
			state["next_volley_armor_pierce_contacts"] = maxi(int(state["next_volley_armor_pierce_contacts"]), int(params.get("contacts", 0)))
		"increase_rarity":
			state["rarity_level"] = clampi(int(state["rarity_level"]) + int(params.get("amount", 0)), 0, RunStateScript.MAX_RARITY_LEVEL)
		"echo_next_choice":
			state["echo_next_choice_armed"] = true
		"queue_entity_action":
			match str(params.get("action", "")):
				"summon_repair_units":
					state["owned_creature_count"] = mini(
						3,
						int(state.get("owned_creature_count", 0)) + maxi(0, int(params.get("amount", 2)))
					)
				"build_or_upgrade_tower":
					var tower_id: String = str(params.get("tower_id", ""))
					var levels: Dictionary = state.get("tower_levels", {}) as Dictionary
					var old_level: int = clampi(int(levels.get(tower_id, 0)), 0, 3)
					levels[tower_id] = mini(3, old_level + 1)
					state["tower_levels"] = levels
					if old_level == 0:
						state["owned_defense_tower_count"] = mini(
							2,
							int(state.get("owned_defense_tower_count", 0)) + 1
						)
				_:
					return false
		"increase_building_volley":
			state["building_volley_level"] = mini(
				3,
				int(state.get("building_volley_level", 0)) + maxi(0, int(params.get("amount", 1)))
			)
		"arm_heavy_charge":
			state["heavy_charge_armed"] = true
		_:
			return false
	return true


func _build_and_consume_volley_fast(state: Dictionary) -> Dictionary:
	var bonus: int = maxi(0, int(state["next_volley_bonus"]))
	var multiplier: int = maxi(1, int(state["next_volley_multiplier"]))
	var shot_count: int = clampi(
		(int(state["base_volley_count"]) + bonus) * multiplier,
		1,
		VolleyResolverScript.NORMAL_MAX_VOLLEY_COUNT
	)
	var building_level: int = clampi(int(state.get("building_volley_level", 0)), 0, 3)
	var building_shots: int = 0
	if building_level > 0:
		building_shots = mini(
			int(state.get("owned_defense_tower_count", 0)) * (building_level + 1),
			maxi(0, 32 - shot_count)
		)
	shot_count += building_shots
	var result: Dictionary = {
		"shot_count": shot_count,
		"attack_level": clampi(int(state["attack_level"]), 0, RunStateScript.MAX_ATTACK_LEVEL),
		"armor_pierce_contacts": maxi(0, int(state["next_volley_armor_pierce_contacts"])),
		"building_shot_count": building_shots,
		"heavy_charge_armed": bool(state.get("heavy_charge_armed", false)),
	}
	state["next_volley_bonus"] = 0
	state["next_volley_multiplier"] = 1
	state["next_volley_armor_pierce_contacts"] = 0
	state["heavy_charge_armed"] = false
	return result


func _is_upgrade_eligible_fast(upgrade_id: String, state: Dictionary) -> bool:
	if upgrade_id == UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
		return int(state["rarity_level"]) < RunStateScript.MAX_RARITY_LEVEL
	if upgrade_id == UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1:
		return int(state["attack_level"]) < RunStateScript.MAX_ATTACK_LEVEL
	if upgrade_id == UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
		return int(state["territory_defense_cap"]) < RunStateScript.MAX_TERRITORY_DEFENSE_CAP
	if upgrade_id == UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
		return not bool(state["echo_next_choice_armed"])
	if upgrade_id == UpgradeManifestScript.UPGRADE_REPAIR_UNITS:
		return int(state.get("owned_creature_count", 0)) <= 1
	if upgrade_id == UpgradeManifestScript.UPGRADE_FIRE_CONTROL_BEACON:
		return int((state.get("tower_levels", {}) as Dictionary).get("fire_control_beacon", 0)) < 3
	if upgrade_id == UpgradeManifestScript.UPGRADE_INTERCEPTOR_TOWER:
		return int((state.get("tower_levels", {}) as Dictionary).get("interceptor_tower", 0)) < 3
	if upgrade_id == UpgradeManifestScript.UPGRADE_BUILDING_VOLLEY:
		return (
			int(state.get("owned_defense_tower_count", 0)) > 0
			and int(state.get("building_volley_level", 0)) < 3
		)
	return true


func _rarity_weight(rarity: String, rarity_level: int) -> float:
	match rarity:
		UpgradeManifestScript.RARITY_COMMON:
			return maxf(25.0, DraftSystemScript.COMMON_BASE_WEIGHT - float(rarity_level) * 12.0)
		UpgradeManifestScript.RARITY_UNCOMMON:
			return DraftSystemScript.UNCOMMON_BASE_WEIGHT + float(rarity_level) * 10.0
		UpgradeManifestScript.RARITY_RARE:
			return DraftSystemScript.RARE_BASE_WEIGHT + float(rarity_level) * 8.0
	return 0.0


func _record_upgrade_fast(state: Dictionary, upgrade_id: String) -> void:
	var counts: Dictionary = state["applied_upgrade_counts"] as Dictionary
	counts[upgrade_id] = int(counts.get(upgrade_id, 0)) + 1


func _hash_unit(seed_value: int, salt: int) -> float:
	var value: int = abs(int(seed_value) * 1103515245 + int(salt) * 12345 + 214013)
	return float(value % 1000003 + 1) / 1000004.0


func _apply_territory_pressure(territory: Dictionary, round_results: Dictionary, profile: Dictionary) -> void:
	var pressure_scale: float = float(profile["territory_pressure"]) * 0.0017
	var gain_a: float = float((round_results[SLOT_A] as Dictionary)["territory_contacts"]) * pressure_scale
	var gain_b: float = float((round_results[SLOT_B] as Dictionary)["territory_contacts"]) * pressure_scale
	var swing: float = clampf(gain_a - gain_b, -0.025, 0.025)
	territory[SLOT_A] = clampf(float(territory[SLOT_A]) + swing, 0.08, 0.82)
	territory[SLOT_B] = clampf(float(territory[SLOT_B]) - swing, 0.08, 0.82)
	var occupied: float = float(territory[SLOT_A]) + float(territory[SLOT_B])
	if occupied > 0.92:
		var scale: float = 0.92 / occupied
		territory[SLOT_A] = float(territory[SLOT_A]) * scale
		territory[SLOT_B] = float(territory[SLOT_B]) * scale


func _activate_strongholds(
	slot: String,
	round_number: int,
	activation_rounds: Dictionary,
	available_types: Array,
	active_strongholds: Dictionary,
	first_stronghold_round: Dictionary
) -> void:
	var active: Array = active_strongholds[slot] as Array
	if active.size() >= available_types.size():
		return
	var required_round: int = int(activation_rounds[slot]) + active.size() * 5
	if round_number < required_round:
		return
	active.append(str(available_types[active.size()]))
	if int(first_stronghold_round[slot]) == 0:
		first_stronghold_round[slot] = round_number


func _stronghold_types(map_definition: Dictionary) -> Array:
	var result: Array = []
	for raw_region in map_definition.get("regions", []) as Array:
		var region: Dictionary = raw_region as Dictionary
		var region_type: String = str(region.get("type", ""))
		if StrongholdRulesScript.is_stronghold_type(region_type) and region_type not in result:
			result.append(region_type)
	result.sort()
	return result


func _first_activation_round(seed_value: int, slot: String, tempo: int) -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _stream_seed(seed_value, 0, slot, 47)
	return clampi(4 + rng.randi_range(0, 4) + tempo, 4, 8)


func _stream_seed(seed_value: int, round_number: int, slot: String, salt: int) -> int:
	var slot_salt: int = 1000003 if slot == SLOT_A else 2000003
	return int(seed_value) * 7919 + int(round_number) * 104729 + slot_salt + int(salt) * 15485863


func _timeout_score(
	health_quarters: int,
	max_health_quarters: int,
	territory_share: float,
	stronghold_count: int
) -> float:
	var health_ratio: float = clampf(
		float(maxi(0, health_quarters)) / float(maxi(1, max_health_quarters)),
		0.0,
		1.0
	)
	var stronghold_ratio: float = clampf(
		float(stronghold_count) / float(StrongholdRulesScript.STRONGHOLD_TYPE_COUNT),
		0.0,
		1.0
	)
	return health_ratio * 50.0 + clampf(territory_share, 0.0, 1.0) * 35.0 + stronghold_ratio * 15.0
