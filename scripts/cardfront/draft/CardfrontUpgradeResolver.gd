extends RefCounted
class_name CardfrontUpgradeResolver

const UpgradeManifestScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeManifest.gd")


func resolve(run_state, upgrade_id: String) -> Dictionary:
	if run_state == null:
		return _failure(upgrade_id, "missing_run_state")
	var definition: Dictionary = UpgradeManifestScript.get_definition(upgrade_id)
	if definition.is_empty():
		return _failure(upgrade_id, "unknown_upgrade")

	var echoed_upgrade_id: String = run_state.consume_queued_echo_upgrade()
	if echoed_upgrade_id != "":
		var echoed_definition: Dictionary = UpgradeManifestScript.get_definition(echoed_upgrade_id)
		if echoed_definition.is_empty() or not _apply_once(run_state, echoed_definition):
			return _failure(upgrade_id, "invalid_echo")
		run_state.record_upgrade(echoed_upgrade_id)

	var should_queue_echo: bool = run_state.consume_echo_next_choice()
	if not _apply_once(run_state, definition):
			return _failure(upgrade_id, "unknown_effect")
	run_state.record_upgrade(upgrade_id)
	if should_queue_echo:
		run_state.queue_echo_upgrade(upgrade_id)

	return {
		"success": true,
		"upgrade_id": str(upgrade_id),
		"times_applied": 1,
		"echo_repeated_upgrade_id": echoed_upgrade_id,
		"echo_queued_upgrade_id": str(upgrade_id) if should_queue_echo else "",
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
		"increase_attack_level":
			run_state.increase_attack_level(int(params.get("amount", 0)))
		"increase_defense_cap":
			run_state.increase_territory_defense_cap(int(params.get("amount", 0)))
		"repair_territory":
			run_state.request_territory_repair(
				int(params.get("amount", 0)),
				str(params.get("zone", "frontline"))
			)
		"add_armor_pierce":
			run_state.add_armor_pierce_contacts(int(params.get("contacts", 0)))
		"increase_rarity":
			run_state.increase_rarity_level(int(params.get("amount", 0)))
		"echo_next_choice":
			run_state.arm_echo_next_choice()
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
