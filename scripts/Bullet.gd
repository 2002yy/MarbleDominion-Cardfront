extends Node2D
class_name Bullet

const MAX_RESTORE_TRAIL_POINTS: int = 3

var faction_id: int = GameConfig.Faction.BLUE
var direction: Vector2 = Vector2.RIGHT
var speed = GameConfig.BULLET_SPEED
var battlefield
var target_turrets = {}
var last_cell = Vector2i(-999, -999)
var age = 0.0
var trail_points = []
var trail_max_points = 8
var pool
var trail_layer
var _cached_map_size: float = 0.0
var is_active: bool = false
var simple_draw: bool = false
var reduce_visual_effects: bool = false
var turret_hit_check_timer: float = 0.0
var trail_sample_timer: float = 0.0
var last_trail_position: Vector2 = Vector2.INF

func get_trail_segment_count() -> int:
	return maxi(0, trail_points.size() - 1)

func setup(new_faction_id: int, new_position: Vector2, new_direction: Vector2, new_battlefield, new_target_turrets = {}) -> void:
	var previous_segments: int = get_trail_segment_count()
	faction_id = new_faction_id
	global_position = new_position
	direction = new_direction.normalized()
	if direction.length() <= 0.001:
		direction = Vector2.RIGHT
	battlefield = new_battlefield
	if battlefield != null:
		_cached_map_size = float(battlefield.grid_size) * float(battlefield.cell_size)
	target_turrets = new_target_turrets
	speed = GameConfig.BULLET_SPEED
	last_cell = Vector2i(-999, -999)
	age = 0.0
	turret_hit_check_timer = randf_range(0.0, GameConfig.TURRET_HIT_CHECK_INTERVAL)
	trail_sample_timer = 0.0
	last_trail_position = global_position
	trail_points.clear()
	if not simple_draw and trail_max_points > 0:
		trail_points.append(global_position)
	_notify_trail_segments_if_needed(previous_segments)
	_request_trail_redraw()
	queue_redraw()

func set_trail_layer(new_trail_layer) -> void:
	trail_layer = new_trail_layer

func get_visual_radius() -> float:
	return _visual_radius()

func _ready() -> void:
	z_index = 30
	visible = false
	set_process(false)
	set_physics_process(false)
	queue_redraw()

func activate() -> void:
	is_active = true
	visible = true
	set_process(true)
	set_physics_process(true)
	z_index = 30

func deactivate() -> void:
	var previous_segments: int = get_trail_segment_count()
	is_active = false
	visible = false
	set_process(false)
	set_physics_process(false)
	battlefield = null
	target_turrets = {}
	trail_points.clear()
	_notify_trail_segments_if_needed(previous_segments)
	_request_trail_redraw()

func _request_trail_redraw() -> void:
	if trail_layer == null or not is_instance_valid(trail_layer):
		return
	if trail_layer.has_method("mark_bullet_dirty"):
		trail_layer.mark_bullet_dirty(self)
	elif trail_layer.has_method("request_trail_redraw"):
		trail_layer.request_trail_redraw()

func _notify_trail_segments_if_needed(previous_segments: int) -> void:
	var current_segments: int = get_trail_segment_count()
	if current_segments == previous_segments:
		return
	if pool != null and is_instance_valid(pool) and pool.has_method("notify_bullet_trail_changed"):
		pool.notify_bullet_trail_changed(self, current_segments)

func replace_trail_points(points: Array) -> void:
	var previous_segments: int = get_trail_segment_count()
	trail_points.clear()
	for point in points:
		if point is Vector2:
			trail_points.append(point)
	if trail_points.is_empty():
		trail_points.append(global_position)
	last_trail_position = trail_points[0] if trail_points.size() > 0 else global_position
	_notify_trail_segments_if_needed(previous_segments)
	_request_trail_redraw()
	queue_redraw()

func restore_from_state(state: Dictionary, new_battlefield, new_target_turrets = {}) -> void:
	var restored_faction_id: int = clampi(int(state.get("faction_id", 0)), 0, 3)
	var restored_position: Vector2 = SaveGameCodec.arr_to_vec2(state.get("position", [0, 0]), Vector2.ZERO)
	var restored_direction: Vector2 = SaveGameCodec.arr_to_vec2(state.get("direction", [1, 0]), Vector2.RIGHT).normalized()
	if restored_direction.length() <= 0.001:
		restored_direction = Vector2.RIGHT

	setup(restored_faction_id, restored_position, restored_direction, new_battlefield, new_target_turrets)
	age = clampf(float(state.get("age", 0.0)), 0.0, GameConfig.BULLET_MAX_LIFETIME)
	last_cell = SaveGameCodec.arr_to_vec2i(state.get("last_cell", [-999, -999]))

	var restored_trail_points: Array = []
	var trail = state.get("trail_points", [])
	if trail is Array and trail.size() > 0:
		var trail_count: int = mini(trail.size(), MAX_RESTORE_TRAIL_POINTS)
		for i in range(trail_count):
			restored_trail_points.append(SaveGameCodec.arr_to_vec2(trail[i], global_position))
	else:
		restored_trail_points.append(global_position)
	replace_trail_points(restored_trail_points)

func _despawn() -> void:
	if pool != null and is_instance_valid(pool):
		pool.recycle_bullet(self)
	else:
		queue_free()

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	if battlefield == null:
		_despawn()
		return

	age += delta
	if age >= GameConfig.BULLET_MAX_LIFETIME:
		if pool != null and is_instance_valid(pool) and pool.has_method("notify_bullet_expired"):
			pool.notify_bullet_expired()
		_despawn()
		return

	var map_size: float = _cached_map_size
	if map_size <= 0.0 and battlefield != null:
		map_size = float(battlefield.grid_size) * float(battlefield.cell_size)
	var next_position = global_position + direction * speed * delta
	var local_position = battlefield.to_local(next_position)
	var bounced = false

	if local_position.x < 0.0:
		local_position.x = 0.0
		direction.x = abs(direction.x)
		bounced = true
	elif local_position.x > map_size:
		local_position.x = map_size
		direction.x = -abs(direction.x)
		bounced = true

	if local_position.y < 0.0:
		local_position.y = 0.0
		direction.y = abs(direction.y)
		bounced = true
	elif local_position.y > map_size:
		local_position.y = map_size
		direction.y = -abs(direction.y)
		bounced = true

	if bounced:
		direction = _stabilize_bounce_direction(direction).normalized()

	global_position = battlefield.to_global(local_position)
	_update_visual_trace(delta)

	turret_hit_check_timer -= delta
	if turret_hit_check_timer <= 0.0:
		turret_hit_check_timer = GameConfig.TURRET_HIT_CHECK_INTERVAL
		if _try_hit_enemy_turret():
			_despawn()
			return

	var cell = battlefield.world_to_cell(global_position)
	if not battlefield.is_inside(cell):
		return

	if cell == last_cell:
		return

	last_cell = cell
	var result = battlefield.apply_bullet(cell, faction_id)
	if result == "HIT_ENEMY_CELL":
		_despawn()

func _stabilize_bounce_direction(raw_direction: Vector2) -> Vector2:
	# v1.9.28：防止正上/正下/正左/正右方向在边界之间无限来回弹。
	# 初始发射仍然严格跟随炮管方向；只有碰到战场边界后，才给近轴向弹道一点切向分量。
	var fixed_direction: Vector2 = raw_direction
	var tangent_min: float = 0.115
	if absf(fixed_direction.x) < tangent_min:
		fixed_direction.x = _bounce_tangent_sign() * tangent_min
	if absf(fixed_direction.y) < tangent_min:
		fixed_direction.y = _bounce_tangent_sign() * tangent_min
	return fixed_direction

func _bounce_tangent_sign() -> float:
	# 用阵营和当前寿命做一个确定性符号，避免每次随机导致轨迹抖动。
	var seed_value: int = int(age * 1000.0) + faction_id * 37 + int(global_position.x + global_position.y)
	return -1.0 if seed_value % 2 == 0 else 1.0

func configure_visuals(new_simple_draw: bool, new_reduce_visual_effects: bool, new_trail_max_points: int) -> void:
	var previous_segments: int = get_trail_segment_count()
	var changed: bool = simple_draw != new_simple_draw or reduce_visual_effects != new_reduce_visual_effects or trail_max_points != new_trail_max_points
	simple_draw = new_simple_draw
	reduce_visual_effects = new_reduce_visual_effects
	trail_max_points = maxi(0, new_trail_max_points)

	if simple_draw or trail_max_points <= 0:
		if trail_points.size() > 0:
			trail_points.clear()
			_request_trail_redraw()
			changed = true
	else:
		while trail_points.size() > trail_max_points:
			trail_points.pop_back()
			changed = true
		if trail_points.size() == 0:
			trail_points.append(global_position)
			last_trail_position = global_position
			_request_trail_redraw()
			changed = true

	if changed:
		_notify_trail_segments_if_needed(previous_segments)
		queue_redraw()

func _trail_sample_interval() -> float:
	# v1.9.28：拖尾继续增强。
	# 高画质/正常状态更接近每帧采样，中低画质也提高连续度；高压状态仍保留保护。
	if simple_draw:
		return 9999.0
	if reduce_visual_effects:
		return 0.075
	if trail_max_points >= 12:
		return 0.022
	if trail_max_points >= 8:
		return 0.028
	if trail_max_points >= 5:
		return 0.036
	return 0.050

func _trail_min_distance_sq() -> float:
	var radius: float = _visual_radius()
	if reduce_visual_effects:
		return radius * radius * 0.65
	return radius * radius * 0.14

func _update_visual_trace(delta: float) -> void:
	var previous_segments: int = get_trail_segment_count()
	if simple_draw or trail_max_points <= 0:
		if trail_points.size() > 0:
			trail_points.clear()
			_notify_trail_segments_if_needed(previous_segments)
			_request_trail_redraw()
		return

	trail_sample_timer -= delta
	if trail_sample_timer > 0.0:
		return

	if last_trail_position != Vector2.INF and global_position.distance_squared_to(last_trail_position) < _trail_min_distance_sq():
		return

	trail_sample_timer = _trail_sample_interval()
	trail_points.push_front(global_position)
	last_trail_position = global_position
	while trail_points.size() > trail_max_points:
		trail_points.pop_back()
	_notify_trail_segments_if_needed(previous_segments)
	_request_trail_redraw()

func _try_hit_enemy_turret() -> bool:
	for target_faction_id in target_turrets:
		if target_faction_id == faction_id:
			continue
		var turret = target_turrets[target_faction_id]
		if turret == null:
			continue
		if turret.is_destroyed:
			continue
		var hit_radius_sq: float = GameConfig.TURRET_HIT_RADIUS * GameConfig.TURRET_HIT_RADIUS
		if global_position.distance_squared_to(turret.global_position) <= hit_radius_sq:
			turret.take_damage(GameConfig.BULLET_DAMAGE)
			return true
	return false

func _visual_radius() -> float:
	if battlefield != null:
		return minf(GameConfig.BULLET_RADIUS, float(battlefield.cell_size) * 0.42)
	return GameConfig.BULLET_RADIUS

func _draw() -> void:
	var base = GameConfig.faction_color(faction_id)
	var radius: float = _visual_radius()

	# v1.9.29：拖尾已移到 BulletTrailLayer 统一绘制。
	# 子弹节点自身只负责主体圆球，避免每颗子弹各自 queue_redraw()。

	if simple_draw:
		draw_circle(Vector2.ZERO, radius, base)
		return

	if not reduce_visual_effects:
		draw_circle(Vector2(2.8, 2.8), radius + 2.2, Color(0.0, 0.0, 0.0, 0.34))
		draw_circle(Vector2.ZERO, radius + 1.2, Color(0.05, 0.05, 0.05, 0.94))

	draw_circle(Vector2.ZERO, radius, base)
	if not reduce_visual_effects:
		draw_circle(Vector2(1.8, 1.8), radius * 0.64, base.darkened(0.26))
		draw_arc(Vector2.ZERO, radius * 0.88, -0.95, 2.25, 18, Color(1.0, 1.0, 1.0, 0.20), 1.1, true)
		draw_circle(Vector2(-2.2, -2.0), radius * 0.30, Color(1.0, 1.0, 1.0, 0.76))
		draw_circle(Vector2(-3.3, -3.0), radius * 0.13, Color(1.0, 1.0, 1.0, 0.48))
		draw_circle(Vector2.ZERO, radius * 0.25, Color(1.0, 1.0, 1.0, 0.14))
