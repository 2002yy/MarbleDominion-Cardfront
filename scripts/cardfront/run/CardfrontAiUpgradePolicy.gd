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
	var score_by_id: Dictionary = {
		UpgradeManifestScript.UPGRADE_PROJECTILE_POWER_PLUS_1: 100.0,
		UpgradeManifestScript.UPGRADE_VOLLEY_X2: 92.0,
		UpgradeManifestScript.UPGRADE_DEFENSE_CAP_PLUS_1: 84.0,
		UpgradeManifestScript.UPGRADE_VOLLEY_PLUS_5: 76.0,
		UpgradeManifestScript.UPGRADE_RARITY_PLUS_1: 70.0,
		UpgradeManifestScript.UPGRADE_MIRROR_NEXT_CHOICE: 66.0,
	}
	var score: float = float(score_by_id.get(upgrade_id, 0.0))
	if run_state != null:
		var round_growth: int = int(run_state.applied_upgrade_counts.size())
		if upgrade_id == UpgradeManifestScript.UPGRADE_RARITY_PLUS_1:
			score += maxf(0.0, 12.0 - float(round_growth) * 3.0)
		if upgrade_id == UpgradeManifestScript.UPGRADE_MIRROR_NEXT_CHOICE and bool(run_state.duplicate_next_choice):
			score = -INF
	return score
