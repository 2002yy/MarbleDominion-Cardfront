extends RefCounted
class_name CardfrontEntityUpgradeResolver


static func apply(run_state, effect_id: String, params: Dictionary) -> bool:
	if run_state == null:
		return false
	match str(effect_id):
		"queue_entity_action":
			run_state.queue_entity_action(params)
		"increase_building_volley":
			run_state.increase_building_volley_level(int(params.get("amount", 0)))
		"arm_heavy_charge":
			run_state.arm_heavy_charge(params)
		_:
			return false
	return true
