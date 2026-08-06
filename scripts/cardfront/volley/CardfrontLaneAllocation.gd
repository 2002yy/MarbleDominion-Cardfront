extends RefCounted
class_name CardfrontLaneAllocation

var lane_index: int = 0
var shot_count: int = 0
var projectile_sequence: Array = []
var angle: float = 0.0
var priority_target_cell: Vector2i = Vector2i.ZERO
var has_priority_target: bool = false


func _init(p_lane_index: int = 0, p_shot_count: int = 0, p_angle: float = 0.0) -> void:
	lane_index = p_lane_index
	shot_count = p_shot_count
	angle = p_angle


func to_dict() -> Dictionary:
	return {
		"lane_index": lane_index,
		"shot_count": shot_count,
		"projectile_sequence": projectile_sequence.duplicate(true),
		"angle": angle,
		"priority_target_cell": [priority_target_cell.x, priority_target_cell.y],
		"has_priority_target": has_priority_target,
	}


static func from_dict(data: Dictionary) -> RefCounted:
	var alloc = load("res://scripts/cardfront/volley/CardfrontLaneAllocation.gd").new()
	alloc.lane_index = int(data.get("lane_index", 0))
	alloc.shot_count = int(data.get("shot_count", 0))
	alloc.angle = float(data.get("angle", 0.0))
	alloc.projectile_sequence = (data.get("projectile_sequence", []) as Array).duplicate(true)
	alloc.has_priority_target = bool(data.get("has_priority_target", false))
	var cell_arr = data.get("priority_target_cell", [0, 0])
	if cell_arr is Array and cell_arr.size() >= 2:
		alloc.priority_target_cell = Vector2i(int(cell_arr[0]), int(cell_arr[1]))
	return alloc


static func build_split(total_shots: int, left_ratio: float, left_angle: float, right_angle: float) -> Array:
	var safe_ratio: float = clampf(left_ratio, 0.0, 1.0)
	var left_count: int = roundi(float(total_shots) * safe_ratio)
	var right_count: int = total_shots - left_count
	var result: Array = []
	if left_count > 0:
		result.append(load("res://scripts/cardfront/volley/CardfrontLaneAllocation.gd").new(0, left_count, left_angle))
	if right_count > 0:
		result.append(load("res://scripts/cardfront/volley/CardfrontLaneAllocation.gd").new(1, right_count, right_angle))
	return result


static func split_sequence(sequence: Array, allocations: Array) -> void:
	var total: int = 0
	for alloc in allocations:
		total += alloc.shot_count
	if total <= 0:
		return
	var index: int = 0
	for alloc in allocations:
		var lane_count: int = alloc.shot_count
		var lane_seq: Array = []
		var count: int = 0
		while count < lane_count and index < sequence.size():
			lane_seq.append(sequence[index])
			index += 1
			count += 1
		alloc.projectile_sequence = lane_seq
