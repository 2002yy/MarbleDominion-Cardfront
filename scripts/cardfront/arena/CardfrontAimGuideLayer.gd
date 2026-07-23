extends Node2D
class_name CardfrontAimGuideLayer

const GUIDE_COLOR: Color = Color(0.34, 0.94, 1.0, 0.92)
const GUIDE_OUTLINE: Color = Color(0.01, 0.04, 0.08, 0.82)

var turret = null
var battlefield = null
var current_angle: float = -PI * 0.5


func _init() -> void:
	name = "CardfrontAimGuideLayer"
	z_index = 2
	set_process(false)


func setup(new_turret, new_battlefield) -> bool:
	turret = new_turret
	battlefield = new_battlefield
	visible = turret != null and battlefield != null
	queue_redraw()
	return visible


func set_angle(_owner_id: int, angle: float, _offset_degrees: float = 0.0) -> void:
	current_angle = wrapf(float(angle), -PI, PI)
	queue_redraw()


func get_endpoint_for_test() -> Vector2:
	return _ray_endpoint()


func _draw() -> void:
	if not visible or turret == null or battlefield == null:
		return
	if not is_instance_valid(turret) or not is_instance_valid(battlefield):
		return
	var direction := Vector2.RIGHT.rotated(current_angle).normalized()
	var start: Vector2 = turret.global_position + direction * (GameConfig.TURRET_RADIUS + 13.0)
	var finish: Vector2 = _ray_endpoint()
	draw_line(start, finish, GUIDE_OUTLINE, 7.0, true)
	draw_line(start, finish, GUIDE_COLOR, 3.0, true)
	draw_circle(finish, 8.0, GUIDE_OUTLINE)
	draw_circle(finish, 4.5, GUIDE_COLOR)


func _ray_endpoint() -> Vector2:
	if turret == null or battlefield == null:
		return Vector2.ZERO
	var origin: Vector2 = turret.global_position
	var direction := Vector2.RIGHT.rotated(current_angle).normalized()
	var size: float = float(battlefield.grid_size * battlefield.cell_size)
	var rect := Rect2(battlefield.global_position, Vector2.ONE * size)
	var best_t: float = INF
	if absf(direction.x) > 0.0001:
		for x_value in [rect.position.x, rect.end.x]:
			var tx: float = (float(x_value) - origin.x) / direction.x
			if tx > 0.0:
				var y_at_x: float = origin.y + direction.y * tx
				if y_at_x >= rect.position.y - 0.1 and y_at_x <= rect.end.y + 0.1:
					best_t = minf(best_t, tx)
	if absf(direction.y) > 0.0001:
		for y_value in [rect.position.y, rect.end.y]:
			var ty: float = (float(y_value) - origin.y) / direction.y
			if ty > 0.0:
				var x_at_y: float = origin.x + direction.x * ty
				if x_at_y >= rect.position.x - 0.1 and x_at_y <= rect.end.x + 0.1:
					best_t = minf(best_t, ty)
	if is_inf(best_t):
		return origin + direction * size
	return origin + direction * best_t
