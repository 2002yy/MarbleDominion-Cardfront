extends Node
class_name CardfrontTargetBiasSystem

var region_map = null
var _biases: Dictionary = {}


func _init() -> void:
	name = "CardfrontTargetBiasSystem"


func setup(new_region_map = null) -> void:
	region_map = new_region_map
	_biases.clear()
	set_process(true)


func apply_region_bias(owner_id: int, region_id: int, duration: float) -> bool:
	var safe_region_id: int = int(region_id)
	var safe_duration: float = maxf(0.0, float(duration))
	if safe_region_id < 0 or safe_duration <= 0.0:
		return false
	if not _region_exists(safe_region_id):
		return false

	_biases[int(owner_id)] = {
		"region_id": safe_region_id,
		"duration": safe_duration,
		"remaining": safe_duration,
	}
	return true


func tick(delta: float) -> void:
	if _biases.is_empty():
		return

	var expired_owner_ids: Array = []
	var safe_delta: float = maxf(0.0, float(delta))
	for owner_id in _biases.keys():
		var entry: Dictionary = _biases[owner_id]
		entry["remaining"] = maxf(0.0, float(entry.get("remaining", 0.0)) - safe_delta)
		if float(entry.get("remaining", 0.0)) <= 0.0:
			expired_owner_ids.append(owner_id)
		else:
			_biases[owner_id] = entry

	for owner_id in expired_owner_ids:
		_biases.erase(owner_id)


func clear(owner_id: int) -> void:
	_biases.erase(int(owner_id))


func get_biased_region(owner_id: int) -> int:
	if not _biases.has(int(owner_id)):
		return -1
	return int((_biases[int(owner_id)] as Dictionary).get("region_id", -1))


func get_biased_target_cell(owner_id: int) -> Vector2i:
	var region_id: int = get_biased_region(owner_id)
	if region_id < 0:
		return Vector2i(-1, -1)
	if region_map == null or not region_map.has_method("get_region_cells"):
		return Vector2i(-1, -1)

	var cells: Array = region_map.get_region_cells(region_id)
	if cells.is_empty():
		return Vector2i(-1, -1)
	return cells[0]


func _process(delta: float) -> void:
	tick(delta)


func _region_exists(region_id: int) -> bool:
	if region_map == null or not region_map.has_method("get_region_cells"):
		return true
	return not region_map.get_region_cells(int(region_id)).is_empty()
