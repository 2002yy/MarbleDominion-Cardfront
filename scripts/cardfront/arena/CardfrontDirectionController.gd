extends Node
class_name CardfrontDirectionController

signal angle_changed(owner_id, angle, offset_degrees)

const MIN_OFFSET_DEGREES: float = -60.0
const MAX_OFFSET_DEGREES: float = 60.0
const KEYBOARD_STEP_DEGREES: float = 4.0

var owner_id: int = -1
var turret = null
var fire_director = null
var center_angle: float = -PI * 0.5
var offset_degrees: float = 0.0
var current_angle: float = -PI * 0.5


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
