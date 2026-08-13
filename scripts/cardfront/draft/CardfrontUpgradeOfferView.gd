extends RefCounted
class_name CardfrontUpgradeOfferView


static func project(definition: Dictionary, run_state = null) -> Dictionary:
	if definition.is_empty():
		return {}
	var result: Dictionary = definition.duplicate(true)
	var upgrade_id: String = str(result.get("id", ""))
	var current_level: int = 0
	if run_state != null and run_state.has_method("get_selected_upgrade_level"):
		current_level = maxi(0, int(run_state.call("get_selected_upgrade_level", upgrade_id)))
	result["current_level"] = current_level
	result["next_level"] = current_level + 1
	return result
