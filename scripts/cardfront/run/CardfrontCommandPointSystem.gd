extends RefCounted
class_name CardfrontCommandPointSystem

signal points_changed(owner_id, remaining)
signal fortify_used(owner_id, cell)

const DEFAULT_POINTS: int = 3
const MAX_POINTS: int = 5

var _points: Dictionary = {}


func setup(owner_ids: Array, starting_points: int = DEFAULT_POINTS) -> void:
	_points.clear()
	for owner_id in owner_ids:
		_points[int(owner_id)] = clampi(int(starting_points), 0, MAX_POINTS)


func get_points(owner_id: int) -> int:
	return int(_points.get(int(owner_id), 0))


func has_points(owner_id: int) -> bool:
	return get_points(owner_id) > 0


func spend_point(owner_id: int) -> bool:
	var current: int = get_points(owner_id)
	if current <= 0:
		return false
	_points[int(owner_id)] = current - 1
	points_changed.emit(int(owner_id), current - 1)
	return true


func add_point(owner_id: int, amount: int = 1) -> void:
	var current: int = get_points(owner_id)
	_points[int(owner_id)] = clampi(current + maxi(0, int(amount)), 0, MAX_POINTS)
	points_changed.emit(int(owner_id), _points[int(owner_id)])


func snapshot() -> Dictionary:
	var result: Dictionary = {}
	for owner_id in _points:
		result[int(owner_id)] = int(_points[owner_id])
	return result


func restore(data: Dictionary) -> void:
	_points.clear()
	for owner_id in data:
		_points[int(owner_id)] = clampi(int(data[owner_id]), 0, MAX_POINTS)
