extends RefCounted
class_name CardfrontAiUpgradePolicy

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")


func choose(offer: Array, run_state = null) -> Dictionary:
	var best_definition: Dictionary = {}
	var best_score: float = -INF
	for index in range(offer.size()):
		var raw_definition = offer[index]
		if not (raw_definition is Dictionary):
			continue
		var definition := raw_definition as Dictionary
		var score: float = _score(definition, run_state) - float(index) * 0.001
		if score > best_score:
			best_score = score
			best_definition = definition
	return best_definition.duplicate(true)


func _score(definition: Dictionary, run_state) -> float:
	var upgrade_id: String = str(definition.get("id", ""))
	if run_state == null:
		return _base_score(upgrade_id, 6, 0, 0)
	var base_volley: int = maxi(1, int(run_state.base_volley_count))
	var attack_level: int = maxi(0, int(run_state.attack_level))
	var round_growth: int = 0
	for count in run_state.applied_upgrade_counts.values():
		round_growth += int(count)
	var score: float = _base_score(upgrade_id, base_volley, attack_level, round_growth)
	if upgrade_id == UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE and bool(run_state.echo_next_choice_armed):
		return -INF
	return score


func _base_score(upgrade_id: String, base_volley: int, attack_level: int, round_growth: int) -> float:
	match upgrade_id:
		UpgradeManifestScript.UPGRADE_ATTACK_LEVEL_PLUS_1:
			return 88.0 - float(attack_level) * 7.0
		UpgradeManifestScript.UPGRADE_VOLLEY_X2:
			return 66.0 + float(mini(base_volley, 12)) * 2.5
		UpgradeManifestScript.UPGRADE_ARMOR_PIERCING:
			return 82.0
		UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1:
			return 78.0
		UpgradeManifestScript.UPGRADE_FRONTLINE_REPAIR:
			return 74.0
		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5:
			return 64.0 + float(maxi(0, 10 - base_volley)) * 1.8
		UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
			return 62.0 + maxf(0.0, 16.0 - float(round_growth) * 3.0)
		UpgradeManifestScript.UPGRADE_ECHO_NEXT_CHOICE:
			return 68.0 + float(mini(round_growth, 5))
	return 0.0
