extends Node2D
class_name Turret

signal destroyed(faction_id)
signal burst_lock_changed(faction_id, locked)
signal burst_progress(faction_id, remaining)

var faction_id: int = GameConfig.Faction.BLUE
var battlefield
var bullet_container
var all_turrets = {}

var sweep_phase: float = 0.0
var sweep_speed: float = 0.95
var center_angle: float = 0.0
var sweep_amplitude: float = deg_to_rad(50.0) # total sweep about 100 degrees

var max_health: int = GameConfig.TURRET_MAX_HEALTH
var health: int = GameConfig.TURRET_MAX_HEALTH
var is_destroyed: bool = false
var damage_flash: float = 0.0
var destroy_anim_time: float = -1.0

var burst_remaining: int = 0
var burst_total: int = 0
var burst_interval: float = GameConfig.BURST_FIRE_INTERVAL
var burst_timer: float = 0.0
var burst_locked: bool = false
var burst_index: int = 0
var burst_origin_angle: float = 0.0
var burst_directed: bool = false
var burst_directed_angle: float = 0.0
var burst_directed_spread: float = 0.0
var burst_progress_emit_timer: float = 0.0
var burst_last_reported_remaining: int = -1
var _bullet_container_can_spawn: bool = false

func setup(new_faction_id: int, new_position: Vector2, new_battlefield, new_bullet_container) -> void:
	faction_id = new_faction_id
	global_position = new_position
	battlefield = new_battlefield
	bullet_container = new_bullet_container
	_bullet_container_can_spawn = bullet_container != null and bullet_container.has_method("spawn_bullet")
	if battlefield != null:
		max_health = GameConfig.get_turret_max_health(battlefield.grid_size)
		health = max_health

func set_all_turrets(turret_map: Dictionary) -> void:
	all_turrets = turret_map

func _ready() -> void:
	center_angle = _inward_center_angle()
	sweep_phase = randf_range(0.0, TAU)
	rotation = center_angle
	z_index = 15
	queue_redraw()

func _process(delta: float) -> void:
	if not is_destroyed:
		sweep_phase += delta * sweep_speed
		rotation = center_angle + sin(sweep_phase) * sweep_amplitude

	if burst_remaining > 0 and not is_destroyed:
		burst_timer -= delta
		burst_progress_emit_timer -= delta
		var shots_this_frame: int = 0
		var frame_budget: int = _max_shots_this_frame()
		while burst_remaining > 0 and burst_timer <= 0.0 and shots_this_frame < frame_budget:
			_spawn_bullet()
			burst_remaining -= 1
			burst_index += 1
			shots_this_frame += 1
			if burst_remaining > 0:
				burst_timer += _next_burst_interval()
			else:
				burst_total = 0
				burst_directed = false
				burst_directed_spread = 0.0
				_emit_burst_progress(true)
				_set_burst_locked(false)

		if shots_this_frame > 0 and burst_remaining > 0:
			_emit_burst_progress(false)

		if burst_remaining > 0 and burst_timer < -0.10:
			burst_timer = 0.0

	if damage_flash > 0.0:
		damage_flash = maxf(0.0, damage_flash - delta * 3.0)
		queue_redraw()

	if is_destroyed and destroy_anim_time >= 0.0:
		destroy_anim_time += delta
		queue_redraw()

func _inward_center_angle() -> float:
	match faction_id:
		GameConfig.Faction.BLUE:
			return PI * 0.25
		GameConfig.Faction.RED:
			return PI * 0.75
		GameConfig.Faction.GREEN:
			return -PI * 0.25
		GameConfig.Faction.YELLOW:
			return PI * 1.25
		_:
			return 0.0

func fire_burst(count: int) -> void:
	if is_destroyed:
		return
	if battlefield == null or bullet_container == null:
		return
	if burst_remaining > 0:
		return

	burst_remaining = clampi(count, 1, GameConfig.get_max_pending_count())
	burst_total = burst_remaining
	burst_timer = 0.0
	burst_index = 0
	burst_origin_angle = rotation
	burst_directed = false
	burst_directed_angle = rotation
	burst_directed_spread = 0.0
	burst_progress_emit_timer = 0.0
	burst_last_reported_remaining = burst_remaining
	burst_progress.emit(faction_id, burst_remaining)
	_set_burst_locked(true)

func request_directed_burst(intent) -> bool:
	if intent == null:
		return false
	return fire_directed(int(intent.shot_count), float(intent.angle), float(intent.spread))

func fire_directed(count: int, angle: float, spread: float = 0.0) -> bool:
	if is_destroyed:
		return false
	if battlefield == null or bullet_container == null:
		return false
	if burst_remaining > 0:
		return false

	burst_remaining = clampi(count, 1, GameConfig.get_max_pending_count())
	burst_total = burst_remaining
	burst_timer = 0.0
	burst_index = 0
	burst_origin_angle = float(angle)
	burst_directed = true
	burst_directed_angle = float(angle)
	burst_directed_spread = maxf(0.0, float(spread))
	burst_progress_emit_timer = 0.0
	burst_last_reported_remaining = burst_remaining
	burst_progress.emit(faction_id, burst_remaining)
	_set_burst_locked(true)
	return true

func cancel_burst() -> int:
	var remaining: int = burst_remaining
	burst_remaining = 0
	burst_total = 0
	burst_index = 0
	burst_timer = 0.0
	burst_directed = false
	burst_directed_spread = 0.0
	burst_progress_emit_timer = 0.0
	burst_last_reported_remaining = 0
	burst_progress.emit(faction_id, 0)
	_set_burst_locked(false)
	return remaining

func restore_from_state(state: Dictionary) -> void:
	health = clampi(int(state.get("turret_health", GameConfig.TURRET_MAX_HEALTH)), 0, max_health)
	is_destroyed = bool(state.get("turret_destroyed", false))
	damage_flash = 0.0
	destroy_anim_time = 0.0 if is_destroyed else -1.0

	sweep_phase = float(state.get("turret_sweep_phase", sweep_phase))
	rotation = float(state.get("turret_rotation", rotation))
	burst_origin_angle = rotation
	burst_directed = false
	burst_directed_angle = rotation
	burst_directed_spread = 0.0
	burst_remaining = clampi(int(state.get("turret_burst_remaining", 0)), 0, GameConfig.get_max_pending_count())
	burst_total = clampi(int(state.get("turret_burst_total", burst_remaining)), burst_remaining, GameConfig.get_max_pending_count())
	burst_index = clampi(int(state.get("turret_burst_index", 0)), 0, GameConfig.get_max_pending_count())
	burst_timer = clampf(float(state.get("turret_burst_timer", 0.0)), 0.0, 1.0)
	burst_progress_emit_timer = 0.0
	burst_last_reported_remaining = burst_remaining

	var should_lock: bool = bool(state.get("turret_burst_locked", false)) and burst_remaining > 0 and not is_destroyed
	_set_burst_locked(should_lock)

	if is_destroyed:
		burst_remaining = 0
		burst_total = 0
		burst_index = 0
		burst_timer = 0.0
		burst_directed = false
		burst_directed_spread = 0.0
		burst_last_reported_remaining = 0
		_set_burst_locked(false)

	burst_progress.emit(faction_id, burst_remaining)
	queue_redraw()

func _next_burst_interval() -> float:
	# v1.9.29：高倍率发射队列优化。
	# 基础节拍保留 v1.9.28 的回调值；实际间隔会根据 FPS 和剩余队列自动放慢。
	# 低 FPS 时不再硬追赶发射，避免生成/命中/回收集中在少数帧里把帧率压垮。
	var pulse_pattern: Array = [0.028, 0.032, 0.030, 0.038, 0.031, 0.036, 0.033, 0.040]
	var idx: int = burst_index % pulse_pattern.size()
	return float(pulse_pattern[idx]) * _burst_interval_multiplier()

func _burst_interval_multiplier() -> float:
	var fps: int = floori(Engine.get_frames_per_second())
	var mul: float = 1.0
	var queue_total: int = _current_total_queue()

	if fps > 0:
		if fps < 10:
			mul = 4.25
		elif fps < 16:
			mul = 3.25
		elif fps < 24:
			mul = 2.50
		elif fps < 35:
			mul = 1.70
		elif fps < 50:
			mul = 1.20

	if burst_remaining >= 1536:
		mul *= 1.28
	elif burst_remaining >= 768:
		mul *= 1.18
	elif burst_remaining >= 256:
		mul *= 1.08

	if queue_total >= 1000:
		mul *= 1.22
	elif queue_total >= 500:
		mul *= 1.10

	return clampf(mul, 1.0, 4.50)

func _max_shots_this_frame() -> int:
	var fps: int = floori(Engine.get_frames_per_second())
	var queue_total: int = _current_total_queue()
	if fps > 0:
		if fps < 24:
			return 1
		if fps < 40:
			return 2
	if queue_total >= 1000:
		return 1
	if queue_total >= 500:
		return mini(2, GameConfig.BURST_MAX_SHOTS_PER_FRAME)
	return GameConfig.BURST_MAX_SHOTS_PER_FRAME

func _emit_burst_progress(force: bool = false) -> void:
	var gap: int = abs(burst_last_reported_remaining - burst_remaining)
	var step: int = _burst_progress_emit_step()
	if force or burst_progress_emit_timer <= 0.0 or gap >= step:
		burst_last_reported_remaining = burst_remaining
		burst_progress_emit_timer = _burst_progress_emit_interval()
		burst_progress.emit(faction_id, burst_remaining)

func _burst_progress_emit_interval() -> float:
	if burst_remaining >= 1024:
		return 0.14
	if burst_remaining >= 256:
		return 0.10
	return 0.075

func _burst_progress_emit_step() -> int:
	if burst_remaining >= 1024:
		return 32
	if burst_remaining >= 256:
		return 16
	if burst_remaining >= 64:
		return 8
	return 1

func _set_burst_locked(locked: bool) -> void:
	if burst_locked == locked:
		return
	burst_locked = locked
	burst_lock_changed.emit(faction_id, locked)

func _spawn_bullet() -> void:
	if bullet_container == null:
		return

	var shot_angle: float = _current_burst_shot_angle()
	var shot_direction: Vector2 = Vector2.RIGHT.rotated(shot_angle).normalized()
	# v1.9.27：子弹方向与当前可见炮管方向完全一致。
	# 移除 lateral_wave 出生点横向摆动，避免炮口方向与弹道看起来不一致。
	var muzzle_distance: float = GameConfig.TURRET_RADIUS + 17.0
	var spawn_position: Vector2 = global_position + shot_direction * muzzle_distance

	if _bullet_container_can_spawn:
		bullet_container.spawn_bullet(faction_id, spawn_position, shot_direction, battlefield, all_turrets)
	else:
		var bullet = Bullet.new()
		bullet.setup(faction_id, spawn_position, shot_direction, battlefield, all_turrets)
		bullet_container.add_child(bullet)

func _current_burst_shot_angle() -> float:
	if burst_directed:
		if burst_total <= 1:
			return burst_directed_angle
		var denominator: float = maxf(1.0, float(burst_total - 1))
		var t: float = float(burst_index) / denominator
		return burst_directed_angle + lerpf(-burst_directed_spread * 0.5, burst_directed_spread * 0.5, t)
	# v1.9.6 修正：
	# 子弹方向直接使用当前炮塔可见 rotation。
	# 之前这里用 fan_start/fan_end 重新计算并混合 rotation，
	# 会导致视觉炮塔摆了 90 度，但实际子弹角度偏小。
	return rotation

func _current_total_queue() -> int:
	if bullet_container != null and is_instance_valid(bullet_container) and bullet_container.has_method("get_tracked_queue_total"):
		return bullet_container.get_tracked_queue_total()
	var total: int = burst_remaining
	for turret in all_turrets.values():
		if turret == null or turret == self:
			continue
		if is_instance_valid(turret):
			total += int(turret.burst_remaining)
	return total

func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	health = max(0, health - amount)
	damage_flash = 1.0
	queue_redraw()
	if health <= 0:
		_destroy()

func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	destroy_anim_time = 0.0
	burst_remaining = 0
	burst_total = 0
	burst_last_reported_remaining = 0
	burst_progress_emit_timer = 0.0
	burst_progress.emit(faction_id, 0)
	_set_burst_locked(false)
	destroyed.emit(faction_id)
	queue_redraw()

func _draw() -> void:
	var color: Color = GameConfig.faction_color(faction_id)
	if is_destroyed:
		color = Color(0.28, 0.28, 0.28)

	if damage_flash > 0.0:
		draw_circle(Vector2.ZERO, GameConfig.TURRET_RADIUS + 7.0, Color(1.0, 1.0, 1.0, 0.38 * damage_flash))

	if is_destroyed and destroy_anim_time >= 0.0:
		var pulse: float = minf(1.0, destroy_anim_time / 0.7)
		draw_circle(Vector2.ZERO, GameConfig.TURRET_RADIUS + 24.0 * pulse, Color(1.0, 0.55, 0.18, 0.32 * (1.0 - pulse)))
		draw_circle(Vector2.ZERO, GameConfig.TURRET_RADIUS + 12.0 + 18.0 * pulse, Color(1.0, 0.12, 0.08, 0.22 * (1.0 - pulse)))
		for i in range(8):
			var ang: float = TAU * float(i) / 8.0 + destroy_anim_time * 1.2
			var start: Vector2 = Vector2.RIGHT.rotated(ang) * 10.0
			var finish: Vector2 = Vector2.RIGHT.rotated(ang) * (20.0 + 16.0 * pulse)
			draw_line(start, finish, Color(1.0, 0.72, 0.2, 0.90 * (1.0 - pulse)), 3.0)
		for j in range(5):
			var smoke_ang: float = TAU * float(j) / 5.0 + 0.5
			var smoke_pos: Vector2 = Vector2.RIGHT.rotated(smoke_ang) * (12.0 + 6.0 * pulse)
			draw_circle(smoke_pos, 5.0 + 6.0 * pulse, Color(0.15, 0.15, 0.15, 0.30 * (1.0 - pulse * 0.3)))

	draw_circle(Vector2(2.4, 2.6), GameConfig.TURRET_RADIUS + 1.0, Color(0.0, 0.0, 0.0, 0.22))
	draw_circle(Vector2.ZERO, GameConfig.TURRET_RADIUS, color)
	draw_circle(Vector2(-4.0, -4.0), GameConfig.TURRET_RADIUS * 0.34, Color(1.0, 1.0, 1.0, 0.46))
	draw_circle(Vector2.ZERO, GameConfig.TURRET_RADIUS, Color.BLACK, false, 2.2)

	if not is_destroyed:
		var barrel_poly: PackedVector2Array = PackedVector2Array([
			Vector2(2, -5),
			Vector2(31, -5),
			Vector2(34, -1),
			Vector2(34, 1),
			Vector2(31, 5),
			Vector2(2, 5)
		])
		draw_colored_polygon(barrel_poly, color.lightened(0.14))
		draw_polyline(barrel_poly, Color.BLACK, 1.4, true)
		draw_circle(Vector2(4, 0), 5.5, color.darkened(0.15))
		draw_circle(Vector2(4, 0), 5.5, Color.BLACK, false, 1.2)
	else:
		draw_line(Vector2(-14, -12), Vector2(14, 12), Color.BLACK, 4.0)
		draw_line(Vector2(-14, 12), Vector2(14, -12), Color.BLACK, 4.0)
		draw_arc(Vector2.ZERO, 18.0, 0.1, PI - 0.1, 16, Color(0.05, 0.05, 0.05, 0.9), 3.0)

	var bar_w: float = 48.0
	var bar_h: float = 6.0
	var bar_pos: Vector2 = Vector2(-bar_w * 0.5, GameConfig.TURRET_RADIUS + 10.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.02, 0.02, 0.02, 0.9), true)
	var ratio: float = float(health) / float(max_health)
	var hp_color: Color = Color(0.25, 1.0, 0.25)
	if ratio < 0.35:
		hp_color = Color(1.0, 0.18, 0.18)
	elif ratio < 0.65:
		hp_color = Color(1.0, 0.75, 0.12)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, bar_h)), hp_color, true)
