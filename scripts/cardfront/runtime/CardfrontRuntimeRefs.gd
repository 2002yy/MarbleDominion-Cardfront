extends RefCounted
class_name CardfrontRuntimeRefs

var values: Dictionary = {}


func set_ref(key: String, value) -> void:
	if key == "":
		return
	values[key] = value


func get_ref(key: String, default_value = null):
	return values.get(key, default_value)


func has_ref(key: String) -> bool:
	return values.has(key)


func clear() -> void:
	values.clear()


func merge_result(result: Dictionary) -> void:
	for key in result.keys():
		if key == "configured" or key == "reason" or key == "stage":
			continue
		set_ref(str(key), result[key])


func snapshot() -> Dictionary:
	return values.duplicate(false)
