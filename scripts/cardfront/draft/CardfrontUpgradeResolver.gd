extends RefCounted
class_name CardfrontUpgradeResolver

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")


func resolve(run_state, upgrade_id: String) -> Dictionary:
	if run_state == null:
		return _failure(upgrade_id, "missing_run_state")
	var definition: Dictionary = UpgradeManifestScript.get_definition(upgrade_id)
	if definition.is_empty():
		return _failure(upgrade_id, "unknown_upgrade")

	var times_applied: int = 2 if run_state.consume_duplicate_next_choice() else 1
	for _index in range(times_applied):
		if not _apply_once(run_state, definition):
			return _failure(upgrade_id, "unknown_effect")
	run_state.record_upgrade(upgrade_id, times_applied)

	return {
		"success": true,
		"upgrade_id": str(upgrade_id),
		"times_applied": times_applied,
		"definition": definition,
		"state": run_state.snapshot(),
	}

func _apply_once(run_state, definition: Dictionary) -> bool:
	var effect_id: String = str(definition.get("effect_id", ""))
	var params: Dictionary = definition.get("params", {}) as Dictionary
	match effect_id:
		"add_next_volley":
			run_state.add_next_volley_bonus(int(params.get("amount", 0)))
		"multiply_next_volley":
			run_state.multiply_next_volley(int(params.get("multiplier", 1)))
		"increase_projectile_power":
			run_state.increase_projectile_power(int(params.get("amount", 0)))
		"increase_defense_cap":
			run_state.increase_territory_defense_cap(int(params.get("amount", 0)))
		"increase_rarity":
			run_state.increase_rarity_level(int(params.get("amount", 0)))
		"duplicate_next_choice":
			run_state.arm_duplicate_next_choice()
		_:
			return false
	return true


func _failure(upgrade_id: String, reason: String) -> Dictionary:
	return {
		"success": false,
		"upgrade_id": str(upgrade_id),
		"reason": str(reason),
		"times_applied": 0,
	}
