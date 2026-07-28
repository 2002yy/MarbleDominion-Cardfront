extends Node2D
class_name CardfrontEntityVisualActor

signal death_finished(entity_id)

const STATE_IDLE: StringName = &"idle"
const STATE_MOVE: StringName = &"move"
const STATE_ATTACK: StringName = &"attack"
const STATE_HIT: StringName = &"hit"
const STATE_DEATH: StringName = &"death"
const MOVE_DURATION_SECONDS: float = 0.28

var entity_id: String = ""
var visual_id: String = ""
var cell_size: float = 16.0
var current_state: StringName = STATE_IDLE
var sprite: AnimatedSprite2D
var _cell: Vector2i = Vector2i.ZERO
var _moving: bool = false
var _dying: bool = false
var _move_tween: Tween = null


func setup(
	new_entity_id: String,
	new_visual_id: String,
	new_cell_size: float,
	frames: SpriteFrames,
	initial_cell: Vector2i
) -> void:
	entity_id = str(new_entity_id)
	visual_id = str(new_visual_id)
	cell_size = maxf(1.0, float(new_cell_size))
	_cell = initial_cell
	position = _cell_center(initial_cell)
	z_index = -1
	_ensure_sprite()
	sprite.sprite_frames = frames
	var display_scale: float = cell_size * 1.63 / 256.0
	sprite.scale = Vector2.ONE * display_scale
	sprite.position.y = -cell_size * 0.335
	_play_state(STATE_IDLE, true)


func sync_cell(target_cell: Vector2i, immediate: bool = false) -> void:
	if target_cell == _cell:
		return
	var previous_cell := _cell
	_cell = target_cell
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	if sprite != null and target_cell.x != previous_cell.x:
		sprite.flip_h = target_cell.x < previous_cell.x
	if immediate or not is_inside_tree():
		position = _cell_center(target_cell)
		_moving = false
		_resume_locomotion()
		return
	_moving = true
	_play_state(STATE_MOVE)
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_SINE)
	_move_tween.set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_property(self, "position", _cell_center(target_cell), MOVE_DURATION_SECONDS)
	_move_tween.tween_callback(_on_move_finished)


func play_attack() -> void:
	play_action(STATE_ATTACK)


func play_action(action_name: StringName) -> void:
	_play_state(action_name)


func play_hit() -> void:
	_play_state(STATE_HIT)


func play_death() -> void:
	if _dying:
		return
	_dying = true
	_moving = false
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_play_state(STATE_DEATH, true)


func play_terminal(action_name: StringName) -> void:
	if _dying:
		return
	_dying = true
	_moving = false
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_play_state(action_name, true)


func is_dying() -> bool:
	return _dying


func _ensure_sprite() -> void:
	if sprite != null and is_instance_valid(sprite):
		return
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	sprite.centered = true
	sprite.animation_finished.connect(_on_animation_finished)
	add_child(sprite)


func _play_state(next_state: StringName, force: bool = false) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(next_state):
		return
	if not force and _state_priority(next_state) < _state_priority(current_state):
		return
	current_state = next_state
	sprite.play(next_state)


func _on_move_finished() -> void:
	_moving = false
	_resume_locomotion()


func _on_animation_finished() -> void:
	if _dying:
		death_finished.emit(entity_id)
		return
	if current_state != STATE_IDLE and current_state != STATE_MOVE:
		_resume_locomotion()


func _resume_locomotion() -> void:
	if _dying:
		return
	_play_state(STATE_MOVE if _moving else STATE_IDLE, true)


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


func _state_priority(state: StringName) -> int:
	match state:
		STATE_DEATH:
			return 5
		STATE_HIT:
			return 4
		STATE_ATTACK:
			return 3
		&"repair", &"block", &"guide", &"detonate":
			return 3
		STATE_MOVE:
			return 2
		_:
			return 1
