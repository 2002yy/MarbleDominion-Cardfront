extends Node
class_name CardfrontDirectionController

signal angle_changed(owner_id, angle, offset_degrees)
signal lane_split_changed(owner_id, ratio)

const MIN_OFFSET_DEGREES: float = -60.0
const MAX_OFFSET_DEGREES: float = 60.0
const KEYBOARD_STEP_DEGREES: float = 4.0
const LaneAllocationScript = preload("res://scripts/cardfront/volley/CardfrontLaneAllocation.gd")
const GateRulesScript = preload("res://scripts/cardfront/gates/CardfrontGateRules.gd")

var owner_id: int = -1
var turret = null
var fire_director = null
var center_angle: float = -PI * 0.5
var offset_degrees: float = 0.0
var current_angle: float = -PI * 0.5
var lane_split_ratio: float = 0.5
var _lane_angles: Array[float] = []
var _grid_extent: Vector2i = Vector2i(40, 50)
var _priority_target_cell: Vector2i = Vector2i(-1, -1)
var _priority_lane_index: int = -1
signal priority_target_set(owner_id, cell, lane_index)


func _init() -> void:
	name = "CardfrontDirectionController"


func setup(new_owner_id: int, new_turret, new_fire_director, new_center_angle: float = -PI * 0.5) -> bool:
	owner_id = int(new_owner_id)
	turret = new_turret
	fire_director = new_fire_director
	center_angle = wrapf(float(new_center_angle), -PI, PI)
	if turret == null or not is_instance_valid(turret):
		return false
	set_process_unhandled_input(true)
	set_offset_degrees(0.0)
	return true


func set_grid_extent(extent: Vector2i) -> void:
	_grid_extent = extent
	_recompute_lane_angles()


func set_lane_split(ratio: float) -> void:
	lane_split_ratio = clampf(float(ratio), 0.0, 1.0)
	lane_split_changed.emit(owner_id, lane_split_ratio)


func get_lane_split() -> float:
	return lane_split_ratio


func get_lane_allocations(total_shots: int) -> Array:
	if _lane_angles.size() < 2:
		return []
	var left_angle: float = _lane_angles[0]
	var right_angle: float = _lane_angles[1]
	if _priority_lane_index >= 0 and _priority_lane_index < _lane_angles.size():
		var target_angle: float = _angle_to_cell(_priority_target_cell)
		if _priority_lane_index == 0:
			left_angle = target_angle
		else:
			right_angle = target_angle
	var allocs: Array = LaneAllocationScript.build_split(total_shots, lane_split_ratio, left_angle, right_angle)
	if _priority_lane_index >= 0 and _priority_lane_index < allocs.size():
		allocs[_priority_lane_index].priority_target_cell = _priority_target_cell
		allocs[_priority_lane_index].has_priority_target = true
	return allocs


func set_priority_target(cell: Vector2i) -> void:
	_priority_target_cell = cell
	_priority_lane_index = _nearest_lane_for_cell(cell)
	priority_target_set.emit(owner_id, cell, _priority_lane_index)


func clear_priority_target() -> void:
	_priority_target_cell = Vector2i(-1, -1)
	_priority_lane_index = -1
	priority_target_set.emit(owner_id, Vector2i(-1, -1), -1)


func get_priority_target() -> Vector2i:
	return _priority_target_cell


func has_priority_target() -> bool:
	return _priority_lane_index >= 0


func _nearest_lane_for_cell(cell: Vector2i) -> int:
	if _lane_angles.size() < 2:
		return -1
	var half_w: float = float(_grid_extent.x) * 0.5
	var cell_x: float = float(cell.x)
	var best_lane: int = 0
	var best_dist: float = absf(cell_x - float(GateRulesScript.LANE_CENTER_RATIOS[0]) * float(_grid_extent.x))
	for i in range(1, GateRulesScript.LANE_COUNT):
		var lane_center_x: float = float(GateRulesScript.LANE_CENTER_RATIOS[i]) * float(_grid_extent.x)
		var dist: float = absf(cell_x - lane_center_x)
		if dist < best_dist:
			best_dist = dist
			best_lane = i
	return best_lane


func _angle_to_cell(cell: Vector2i) -> float:
	var half_w: float = float(_grid_extent.x) * 0.5
	var dx: float = float(cell.x) - half_w + 0.5
	var dy: float = float(cell.y) - float(_grid_extent.y) + 0.5
	if dy > -0.1:
		dy = -0.1
	return atan2(dy, dx)


func _recompute_lane_angles() -> void:
	var half_w: float = float(_grid_extent.x) * 0.5
	var half_h: float = float(_grid_extent.y) * 0.5
	_lane_angles.clear()
	for i in range(GateRulesScript.LANE_COUNT):
		var lane_center_ratio: float = float(GateRulesScript.LANE_CENTER_RATIOS[i])
		var dx: float = (lane_center_ratio * float(_grid_extent.x) - half_w)
		var dy: float = -half_h
		_lane_angles.append(atan2(dy, dx))


func set_offset_degrees(value: float) -> void:
	offset_degrees = clampf(float(value), MIN_OFFSET_DEGREES, MAX_OFFSET_DEGREES)
	current_angle = wrapf(center_angle + deg_to_rad(offset_degrees), -PI, PI)
	if turret != null and is_instance_valid(turret) and turret.has_method("set_manual_aim"):
		turret.set_manual_aim(current_angle)
	if fire_director != null and is_instance_valid(fire_director) and fire_director.has_method("set_owner_manual_angle"):
		fire_director.set_owner_manual_angle(owner_id, current_angle)
	angle_changed.emit(owner_id, current_angle, offset_degrees)


func nudge(direction: int) -> void:
	if direction == 0:
		return
	set_offset_degrees(offset_degrees + signi(direction) * KEYBOARD_STEP_DEGREES)


func get_offset_degrees() -> float:
	return offset_degrees


func get_current_angle() -> float:
	return current_angle


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var direction: int = 0
	if key_event.keycode == KEY_A or key_event.keycode == KEY_LEFT:
		direction = -1
	elif key_event.keycode == KEY_D or key_event.keycode == KEY_RIGHT:
		direction = 1
	if direction == 0:
		return
	nudge(direction)
	get_viewport().set_input_as_handled()
