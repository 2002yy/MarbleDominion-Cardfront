extends RefCounted
class_name SupportStateSnapshotCodec

const StateScript = preload("res://scripts/cardfront/support/DeploymentSupportState.gd")


static func encode(states_by_id: Dictionary) -> Dictionary:
	var raw: Dictionary = {}
	for key in states_by_id.keys():
		var state = states_by_id[key]
		if state is Dictionary:
			raw[key] = (state as Dictionary).duplicate(true)
		elif state != null and state.has_method("snapshot"):
			raw[key] = state.snapshot()
	return normalize_persistent(raw)


static func normalize_persistent(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = data.keys()
	keys.sort_custom(func(left, right): return str(left) < str(right))
	for key in keys:
		var value = data[key]
		if not value is Dictionary:
			continue
		var record: Dictionary = value as Dictionary
		var support_id: String = str(record.get("support_id", ""))
		if support_id == "" or result.has(support_id):
			continue
		result[support_id] = {
			"support_id": support_id,
			"claim_owner": int(record.get("claim_owner", -1)),
			"operational": bool(record.get("operational", false)),
			"capture_side": int(record.get("capture_side", -1)),
			"capture_progress": clampf(float(record.get("capture_progress", 0.0)), 0.0, 1.0),
		}
	return result


static func decode(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var normalized: Dictionary = normalize_persistent(data)
	for support_id in normalized.keys():
		var state = StateScript.new()
		state.restore_persistent(normalized[support_id])
		result[support_id] = state
	return result
