extends CardfrontB1ArchetypeMatchSimulator
class_name CardfrontB1DeckMatchSimulator

const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const ManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

var _deck_by_owner: Dictionary = {}


func simulate_with_decks(
	hero_a: String,
	hero_b: String,
	map_id: String,
	side_variant: int,
	seed_value: int,
	deck_a: String,
	deck_b: String,
	simulation_mode: String = "parity_uncompensated"
) -> Dictionary:
	_deck_by_owner = {
		1: DeckRegistryScript.sanitize_deck_id(deck_a),
		2: DeckRegistryScript.sanitize_deck_id(deck_b),
	}
	var result: Dictionary = super.simulate(hero_a, hero_b, map_id, side_variant, seed_value, simulation_mode)
	result["deck_a"] = str(_deck_by_owner.get(1, DeckRegistryScript.DEFAULT_DECK_ID))
	result["deck_b"] = str(_deck_by_owner.get(2, DeckRegistryScript.DEFAULT_DECK_ID))
	result["deck_candidate_model"] = true
	return result


func _make_state(hero_id: String, owner_id: int) -> Dictionary:
	var state: Dictionary = super._make_state(hero_id, owner_id)
	state["deck_id"] = str(_deck_by_owner.get(int(owner_id), DeckRegistryScript.DEFAULT_DECK_ID))
	state["next_volley_conversions"] = {}
	state["bridgehead_prefab_charges"] = 0
	state["bridgehead_prefab_defense_bonus"] = 0
	return state


func _draw_offer_ids_fast(state: Dictionary, offer_size: int, seed_value: int) -> Array:
	var ranked: Array = []
	for raw_upgrade_id in DeckRegistryScript.get_upgrade_ids(str(state.get("deck_id", DeckRegistryScript.DEFAULT_DECK_ID))):
		var upgrade_id: String = str(raw_upgrade_id)
		if not _is_upgrade_eligible_fast(upgrade_id, state):
			continue
		var definition: Dictionary = ManifestScript.get_definition(upgrade_id)
		var weight: float = _rarity_weight(str(definition.get("rarity", "")), int(state.get("rarity_level", 0)))
		var uniform: float = maxf(0.000001, _hash_unit(seed_value, upgrade_id.hash()))
		ranked.append({"id": upgrade_id, "rank": -log(uniform) / maxf(0.001, weight)})
	ranked.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return float(left.get("rank", INF)) < float(right.get("rank", INF))
	)
	var result: Array = []
	for index in range(mini(maxi(1, offer_size), ranked.size())):
		result.append(str((ranked[index] as Dictionary).get("id", "")))
	for raw_id in result:
		_increment_metric(_b1_card_appearances, str(raw_id), 1.0)
		_increment_hero_card_metric(state, "appearances", str(raw_id), 1.0)
	return result


func _apply_upgrade_once_fast(state: Dictionary, upgrade_id: String) -> bool:
	var definition: Dictionary = ManifestScript.get_definition(upgrade_id)
	var params: Dictionary = definition.get("params", {}) as Dictionary
	match str(definition.get("effect_id", "")):
		"convert_next_volley":
			var projectile_type: String = ProjectileTypeScript.sanitize(str(params.get("projectile_type", ProjectileTypeScript.STANDARD)))
			if projectile_type == ProjectileTypeScript.STANDARD:
				return false
			var conversions: Dictionary = state.get("next_volley_conversions", {}) as Dictionary
			conversions[projectile_type] = maxi(0, int(conversions.get(projectile_type, 0)) + maxi(0, int(params.get("amount", 0))))
			state["next_volley_conversions"] = conversions
			return true
		"arm_bridgehead_prefabs":
			state["bridgehead_prefab_charges"] = maxi(0, int(state.get("bridgehead_prefab_charges", 0)) + maxi(0, int(params.get("charges", 0))))
			state["bridgehead_prefab_defense_bonus"] = maxi(
				int(state.get("bridgehead_prefab_defense_bonus", 0)),
				maxi(0, int(params.get("defense_bonus", 0)))
			)
			return true
	return super._apply_upgrade_once_fast(state, upgrade_id)


func _build_and_consume_volley_fast(state: Dictionary) -> Dictionary:
	var conversions: Dictionary = (state.get("next_volley_conversions", {}) as Dictionary).duplicate(true)
	var plan: Dictionary = super._build_and_consume_volley_fast(state)
	var sequence: Array = plan.get("projectile_sequence", []) as Array
	plan["projectile_conversions_applied"] = ProjectileTypeScript.apply_conversions(sequence, conversions)
	plan["projectile_sequence"] = sequence
	plan["projectile_counts"] = ProjectileTypeScript.count_types(sequence)
	plan["shot_count"] = sequence.size()
	state["next_volley_conversions"] = {}
	return plan


func _proxy_value_context(state: Dictionary) -> Dictionary:
	var context: Dictionary = super._proxy_value_context(state)
	var route_pressure: float = clampf(float(context.get("route_pressure", 1.0)), 0.5, 2.5)
	var rounds_remaining: int = maxi(1, int(context.get("rounds_remaining", 12)))
	# Bridgehead construction lasts until three qualifying captures. Over a long
	# opening horizon, reaching all three is the normal case rather than an edge.
	context["expected_frontline_captures"] = clampf(
		0.75 + (route_pressure - 0.75) * 1.5 + float(mini(rounds_remaining, 10)) * 0.22,
		0.0,
		3.0
	)
	# Siege conversions explicitly seek defended bottlenecks. Keep this targeted
	# opportunity separate from the generic random-contact probability so Armor
	# Piercing cannot inherit a siege-only targeting guarantee.
	var generic_contact: float = clampf(float(context.get("enemy_defense_contact_chance", 0.13)), 0.0, 0.75)
	context["siege_defense_contact_chance"] = generic_contact
	if float(context.get("enemy_defense_points", 0.0)) > 0.0:
		context["siege_defense_contact_chance"] = maxf(generic_contact, 0.65)
	return context


func _grant_captured_frontline_cells(state: Dictionary, amount: int) -> void:
	var defense_cells: Array = state.get("virtual_defense_cells", []) as Array
	var owned_cells: Array = state.get("virtual_owned_cells", []) as Array
	var initial_front: Array = state.get("virtual_initial_contact_front", []) as Array
	for _index in range(maxi(0, amount)):
		defense_cells.append(_capture_defense_for_state(state))
		owned_cells.append(true)
		initial_front.append(true)


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
		defense_cells[chosen] = _capture_defense_for_state(state)
		recaptured += 1
	return recaptured


func _capture_defense_for_state(state: Dictionary) -> int:
	var cap: int = maxi(1, int(state.get("territory_defense_cap", 1)))
	var passive: int = clampi(int(state.get("captured_frontline_defense", 0)), 0, cap)
	var charges: int = maxi(0, int(state.get("bridgehead_prefab_charges", 0)))
	var bonus: int = maxi(0, int(state.get("bridgehead_prefab_defense_bonus", 0))) if charges > 0 else 0
	if charges > 0 and bonus > 0:
		state["bridgehead_prefab_charges"] = charges - 1
		if int(state["bridgehead_prefab_charges"]) <= 0:
			state["bridgehead_prefab_defense_bonus"] = 0
	return clampi(passive + bonus, 0, cap)
