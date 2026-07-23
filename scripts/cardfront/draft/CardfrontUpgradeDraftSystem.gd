extends RefCounted
class_name CardfrontUpgradeDraftSystem

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")
const RunStateScript = preload("res://scripts/cardfront/run/CardfrontFactionRunState.gd")

const OFFER_SIZE: int = 3
const COMMON_BASE_WEIGHT: float = 100.0
const UNCOMMON_BASE_WEIGHT: float = 42.0
const RARE_BASE_WEIGHT: float = 12.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func set_seed(seed_value: int) -> void:
	_rng.seed = int(seed_value)


func randomize_seed() -> void:
	_rng.randomize()


func draw_three(run_state = null, guarantee_uncommon_or_better: bool = false) -> Array:
	var candidate_ids: Array = []
	for raw_upgrade_id in UpgradeManifestScript.get_upgrade_ids():
		var definition: Dictionary = UpgradeManifestScript.get_definition(str(raw_upgrade_id))
		if is_upgrade_eligible(definition, run_state):
			candidate_ids.append(str(raw_upgrade_id))
	var result: Array = []
	if guarantee_uncommon_or_better:
		var guaranteed_ids: Array = _filter_uncommon_or_better(candidate_ids)
		var guaranteed_index: int = _weighted_index(guaranteed_ids, run_state)
		if guaranteed_index >= 0:
			var guaranteed_id: String = str(guaranteed_ids[guaranteed_index])
			result.append(UpgradeManifestScript.get_definition(guaranteed_id))
			candidate_ids.erase(guaranteed_id)
	while result.size() < OFFER_SIZE and not candidate_ids.is_empty():
		var selected_index: int = _weighted_index(candidate_ids, run_state)
		if selected_index < 0:
			break
		var upgrade_id: String = str(candidate_ids[selected_index])
		result.append(UpgradeManifestScript.get_definition(upgrade_id))
		candidate_ids.remove_at(selected_index)
	return result


func _filter_uncommon_or_better(candidate_ids: Array) -> Array:
	var result: Array = []
	for raw_upgrade_id in candidate_ids:
		var definition: Dictionary = UpgradeManifestScript.get_definition(str(raw_upgrade_id))
		if str(definition.get("rarity", "")) in [
			UpgradeManifestScript.RARITY_UNCOMMON,
			UpgradeManifestScript.RARITY_RARE,
		]:
			result.append(str(raw_upgrade_id))
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
	if upgrade_id == UpgradeManifestScript.UPGRADE_MIRROR_NEXT_CHOICE:
		return not bool(run_state.get("duplicate_next_choice"))
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
