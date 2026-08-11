extends RefCounted
class_name CardfrontUpgradeDraftSystem

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

const DEFAULT_OFFER_SIZE: int = 3
# P0-05B1: the formal gameplay draft is three-choice. Legacy Lab may still
# produce draft_choice_count=4, but the draft consumer no longer accepts it.
const MAX_OFFER_SIZE: int = 3
const COMMON_BASE_WEIGHT: float = 100.0
const UNCOMMON_BASE_WEIGHT: float = 42.0
const RARE_BASE_WEIGHT: float = 12.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func set_seed(seed_value: int) -> void:
	_rng.seed = int(seed_value)


func randomize_seed() -> void:
	_rng.randomize()


func draw_three(run_state = null) -> Array:
	return draw_offer(run_state, DEFAULT_OFFER_SIZE)


func draw_offer(run_state = null, offer_size: int = DEFAULT_OFFER_SIZE) -> Array:
	var result: Array = []
	for upgrade_id in draw_offer_ids(run_state, offer_size):
		result.append(UpgradeManifestScript.get_definition(str(upgrade_id)))
	return result


func draw_offer_ids(run_state = null, offer_size: int = DEFAULT_OFFER_SIZE) -> Array:
	var resolved_offer_size: int = clampi(int(offer_size), 1, MAX_OFFER_SIZE)
	var candidate_ids: Array = []
	for raw_upgrade_id in _deck_upgrade_ids(run_state):
		var upgrade_id: String = str(raw_upgrade_id)
		var definition: Dictionary = UpgradeManifestScript.get_definition(upgrade_id)
		if is_upgrade_eligible(definition, run_state):
			candidate_ids.append(upgrade_id)
	var result: Array = []
	while result.size() < resolved_offer_size and not candidate_ids.is_empty():
		var selected_index: int = _weighted_index(candidate_ids, run_state)
		if selected_index < 0:
			break
		var upgrade_id: String = str(candidate_ids[selected_index])
		result.append(upgrade_id)
		candidate_ids.remove_at(selected_index)
	return result


func choose_timeout_fallback(offer: Array) -> Dictionary:
	if offer.is_empty():
		return {}
	var selected_index: int = _rng.randi_range(0, offer.size() - 1)
	var selected = offer[selected_index]
	if not (selected is Dictionary):
		return {}
	return (selected as Dictionary).duplicate(true)


func is_upgrade_eligible(definition: Dictionary, run_state = null) -> bool:
	if definition.is_empty():
		return false
	if run_state == null:
		return true
	var upgrade_id: String = str(definition.get("id", ""))
	if upgrade_id == UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
		return int(run_state.get("rarity_level")) < RunStateScript.MAX_RARITY_LEVEL
	if upgrade_id == UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1:
		return int(run_state.get("attack_level")) < RunStateScript.MAX_ATTACK_LEVEL
	if upgrade_id == UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
		return int(run_state.get("territory_defense_cap")) < RunStateScript.MAX_TERRITORY_DEFENSE_CAP
	if upgrade_id == UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
		return not bool(run_state.get("echo_next_choice_armed"))
	if upgrade_id == UpgradeManifestScript.UPGRADE_REPAIR_UNITS:
		return int(run_state.get("owned_creature_count")) <= 1
	if upgrade_id == UpgradeManifestScript.UPGRADE_ARMORED_GUARD:
		return int(run_state.get("owned_creature_count")) < 3
	if upgrade_id == UpgradeManifestScript.UPGRADE_SAPPER_UNIT:
		return int(run_state.get("owned_creature_count")) < 3
	if upgrade_id == UpgradeManifestScript.UPGRADE_GATE_COLOSSUS:
		return not bool(run_state.get("neutral_creature_summoned"))
	if upgrade_id == UpgradeManifestScript.UPGRADE_FIRE_CONTROL_BEACON:
		return int(run_state.call("get_tower_level", "fire_control_beacon")) < 3
	if upgrade_id == UpgradeManifestScript.UPGRADE_INTERCEPTOR_TOWER:
		return int(run_state.call("get_tower_level", "interceptor_tower")) < 3
	if upgrade_id == UpgradeManifestScript.UPGRADE_BUILDING_VOLLEY:
		return (
			int(run_state.get("owned_defense_tower_count")) > 0
			and int(run_state.get("building_volley_level")) < RunStateScript.MAX_BUILDING_VOLLEY_LEVEL
		)
	return true


func weight_for_definition(definition: Dictionary, run_state = null) -> float:
	var rarity_level: int = 0
	if run_state != null:
		rarity_level = maxi(0, int(run_state.get("rarity_level")))
	match str(definition.get("rarity", "")):
		UpgradeManifestScript.RARITY_COMMON:
			return maxf(25.0, COMMON_BASE_WEIGHT - float(rarity_level) * 12.0)
		UpgradeManifestScript.RARITY_UNCOMMON:
			return UNCOMMON_BASE_WEIGHT + float(rarity_level) * 10.0
		UpgradeManifestScript.RARITY_RARE:
			return RARE_BASE_WEIGHT + float(rarity_level) * 8.0
	return 0.0


func _deck_upgrade_ids(run_state) -> Array:
	var deck_id: String = DeckRegistryScript.DEFAULT_DECK_ID
	if run_state != null:
		var requested = run_state.get("deck_id")
		if requested != null:
			deck_id = str(requested)
	return DeckRegistryScript.get_upgrade_ids(deck_id)


func _weighted_index(candidate_ids: Array, run_state) -> int:
	var weights: Array[float] = []
	var total_weight: float = 0.0
	for raw_upgrade_id in candidate_ids:
		var definition: Dictionary = UpgradeManifestScript.get_definition(str(raw_upgrade_id))
		var weight: float = maxf(0.0, weight_for_definition(definition, run_state))
		weights.append(weight)
		total_weight += weight
	if total_weight <= 0.0:
		return 0 if not candidate_ids.is_empty() else -1

	var roll: float = _rng.randf() * total_weight
	for index in range(candidate_ids.size()):
		roll -= weights[index]
		if roll <= 0.0:
			return index
	return candidate_ids.size() - 1
