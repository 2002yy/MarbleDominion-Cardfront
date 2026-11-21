extends Control
class_name EventRouletteView

signal presentation_finished(payload)

const DROP_DURATION: float = 0.50
const COLOR_SPIN_DURATION: float = 1.80
const COLOR_CONFIRM_DURATION: float = 0.40
const EFFECT_SPIN_DURATION: float = 1.80
const EFFECT_CONFIRM_DURATION: float = 0.40
const REROLL_SPIN_DURATION: float = 1.20
const RESULT_HOLD_DURATION: float = 2.00
const LIFT_DURATION: float = 0.50

var current_layout: Dictionary = {}
var mobile_mode: bool = false
var stage_panel: Panel = null
var header_label: Label = null
var left_title_label: Label = null
var right_title_label: Label = null
var left_value_label: Label = null
var right_value_label: Label = null
var result_label: Label = null
var left_pointer: ColorRect = null
var right_pointer: ColorRect = null

var _is_playing: bool = false
var _timeline: float = 0.0
var _payload: Dictionary = {}
var _color_items: Array = []
var _effect_items: Array = []
var _effect_round_starts: Array = []
var _effect_round_durations: Array = []
var _effect_sequence: Array = []
var _color_target_index: int = 0
var _final_effect_index: int = 0
var _stage_hidden_y: float = -220.0
var _stage_shown_y: float = 96.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_bind_scene_nodes()

func setup(view_size: Vector2, new_current_layout: Dictionary, is_mobile: bool) -> void:
	size = view_size
	current_layout = new_current_layout.duplicate(true)
	mobile_mode = is_mobile
	_bind_scene_nodes()
	_layout_stage()

func play_event(payload: Dictionary) -> void:
	if stage_panel == null:
		_bind_scene_nodes()

	_payload = payload.duplicate(true)
	_effect_sequence = payload.get("effect_sequence", []).duplicate(true)
	_color_items = payload.get("faction_items", ["蓝方", "红方", "绿方", "黄方"]).duplicate(true)
	_effect_items = payload.get("effect_items", ["重转", "本次 +10", "本次 x2", "本次 x3", "加 1 球", "控制仓短路"]).duplicate(true)
	_color_target_index = clampi(int(payload.get("faction_id", 0)), 0, max(_color_items.size() - 1, 0))
	_final_effect_index = int(payload.get("final_effect_index", 0))
	_compute_effect_rounds()
	_layout_stage()

	_timeline = 0.0
	_is_playing = true
	visible = true
	stage_panel.visible = true
	stage_panel.position.y = _stage_hidden_y
	result_label.visible = false
	result_label.modulate = Color.WHITE
	header_label.text = "事件转盘"
	left_title_label.text = "阵营"
	right_title_label.text = "效果"
	left_value_label.text = _color_items[0]
	right_value_label.text = "待命"
	_set_pointer_strength(left_pointer, false)
	_set_pointer_strength(right_pointer, false)

func _process(delta: float) -> void:
	if not _is_playing:
		return

	_timeline += delta
	_update_stage_motion()
	_update_color_wheel()
	_update_effect_wheel()
	_update_result_text()

	if _timeline >= _total_duration():
		_finish_presentation()

func _bind_scene_nodes() -> void:
	if not has_node("StagePanel"):
		return

	stage_panel = get_node("StagePanel") as Panel
	if stage_panel == null:
		return

	header_label = stage_panel.get_node_or_null("HeaderLabel") as Label
	left_title_label = stage_panel.get_node_or_null("LeftTitleLabel") as Label
	right_title_label = stage_panel.get_node_or_null("RightTitleLabel") as Label
	left_value_label = stage_panel.get_node_or_null("LeftValueLabel") as Label
	right_value_label = stage_panel.get_node_or_null("RightValueLabel") as Label
	result_label = stage_panel.get_node_or_null("ResultLabel") as Label
	left_pointer = stage_panel.get_node_or_null("LeftPointer") as ColorRect
	right_pointer = stage_panel.get_node_or_null("RightPointer") as ColorRect

func _layout_stage() -> void:
	var stage_rect: Rect2 = current_layout.get("roulette_stage_rect", Rect2(Vector2((size.x - 448.0) * 0.5, 96.0), Vector2(448.0, 168.0)))
	var stage_size: Vector2 = stage_rect.size
	stage_panel.size = stage_size
	_stage_shown_y = stage_rect.position.y
	_stage_hidden_y = -stage_size.y - 20.0
	stage_panel.position = Vector2(stage_rect.position.x, _stage_hidden_y)

	var bg: ColorRect = stage_panel.get_node("Bg") as ColorRect
	bg.position = Vector2(4.0, 4.0)
	bg.size = stage_size - Vector2(8.0, 8.0)

	header_label.position = Vector2(0.0, 8.0)
	header_label.size = Vector2(stage_size.x, 28.0)
	left_title_label.position = Vector2(34.0, 44.0)
	left_title_label.size = Vector2(150.0, 20.0)
	right_title_label.position = Vector2(stage_size.x - 184.0, 44.0)
	right_title_label.size = Vector2(150.0, 20.0)

	var wheel_w: float = (stage_size.x - 72.0) * 0.5
	var wheel_h: float = 58.0
	left_value_label.position = Vector2(24.0, 66.0)
	left_value_label.size = Vector2(wheel_w, wheel_h)
	right_value_label.position = Vector2(stage_size.x - 24.0 - wheel_w, 66.0)
	right_value_label.size = Vector2(wheel_w, wheel_h)

	left_pointer.position = Vector2(left_value_label.position.x + 12.0, left_value_label.position.y + wheel_h + 4.0)
	left_pointer.size = Vector2(wheel_w - 24.0, 4.0)
	right_pointer.position = Vector2(right_value_label.position.x + 12.0, right_value_label.position.y + wheel_h + 4.0)
	right_pointer.size = Vector2(wheel_w - 24.0, 4.0)

	result_label.position = Vector2(18.0, stage_size.y - 48.0)
	result_label.size = Vector2(stage_size.x - 36.0, 30.0)

func _compute_effect_rounds() -> void:
	_effect_round_starts.clear()
	_effect_round_durations.clear()

	var cursor: float = DROP_DURATION + COLOR_SPIN_DURATION + COLOR_CONFIRM_DURATION
	for i in range(_effect_sequence.size()):
		_effect_round_starts.append(cursor)
		var duration: float = EFFECT_SPIN_DURATION if i == 0 else REROLL_SPIN_DURATION
		_effect_round_durations.append(duration)
		cursor += duration + EFFECT_CONFIRM_DURATION

func _update_stage_motion() -> void:
	if _timeline <= DROP_DURATION:
		var t: float = clampf(_timeline / DROP_DURATION, 0.0, 1.0)
		stage_panel.position.y = lerpf(_stage_hidden_y, _stage_shown_y, _ease_out_back(t))
		return

	var lift_start: float = _total_duration() - LIFT_DURATION
	if _timeline >= lift_start:
		var t2: float = clampf((_timeline - lift_start) / LIFT_DURATION, 0.0, 1.0)
		stage_panel.position.y = lerpf(_stage_shown_y, _stage_hidden_y, _ease_in_quad(t2))
		return

	stage_panel.position.y = _stage_shown_y

func _update_color_wheel() -> void:
	var start: float = DROP_DURATION
	var finish: float = DROP_DURATION + COLOR_SPIN_DURATION

	if _timeline < start:
		left_value_label.text = _color_items[0]
		return
	if _timeline <= finish:
		_set_pointer_strength(left_pointer, true)
		var local_t: float = clampf((_timeline - start) / COLOR_SPIN_DURATION, 0.0, 1.0)
		var index: int = _spin_index(_color_items.size(), 15, _color_target_index, local_t)
		left_value_label.text = _color_items[index]
		return

	_set_pointer_strength(left_pointer, false)
	left_value_label.text = _color_items[_color_target_index]

func _update_effect_wheel() -> void:
	if _effect_sequence.is_empty():
		right_value_label.text = "无"
		return

	var active_round: int = -1
	for i in range(_effect_round_starts.size()):
		var round_start: float = float(_effect_round_starts[i])
		var round_end: float = round_start + float(_effect_round_durations[i])
		if _timeline >= round_start and _timeline <= round_end:
			active_round = i
			break

	if active_round != -1:
		_set_pointer_strength(right_pointer, true)
		var local_t: float = clampf((_timeline - float(_effect_round_starts[active_round])) / float(_effect_round_durations[active_round]), 0.0, 1.0)
		var target_effect: String = str(_effect_sequence[active_round])
		var target_index: int = _effect_item_index(target_effect)
		var cycles: int = 18 if active_round == 0 else 12
		var index: int = _spin_index(_effect_items.size(), cycles, target_index, local_t)
		right_value_label.text = _effect_items[index]
		return

	_set_pointer_strength(right_pointer, false)
	var settled_index: int = _final_effect_index
	for i in range(_effect_round_starts.size()):
		var round_finish: float = float(_effect_round_starts[i]) + float(_effect_round_durations[i]) + EFFECT_CONFIRM_DURATION
		if _timeline >= round_finish:
			settled_index = _effect_item_index(str(_effect_sequence[i]))
	right_value_label.text = _effect_items[settled_index]

func _update_result_text() -> void:
	var result_start: float = _total_duration() - LIFT_DURATION - RESULT_HOLD_DURATION
	if _timeline < result_start:
		result_label.visible = false
		return

	result_label.visible = true
	result_label.text = str(_payload.get("result_text", ""))
	var alpha: float = clampf((_timeline - result_start) / 0.22, 0.0, 1.0)
	result_label.modulate = Color(1.0, 1.0, 1.0, alpha)

func _spin_index(item_count: int, extra_cycles: int, target_index: int, t: float) -> int:
	var total_steps: int = extra_cycles * item_count + target_index
	var p: float = _inertial_progress(t)
	var step: int = clampi(floori(p * float(total_steps)), 0, total_steps)
	return posmod(step, item_count)

func _inertial_progress(t: float) -> float:
	if t <= 0.18:
		var local_a: float = t / 0.18
		return 0.18 * local_a * local_a
	if t <= 0.72:
		return 0.18 + (t - 0.18) * 1.08
	var local_d: float = (t - 0.72) / 0.28
	return lerpf(0.76, 1.0, 1.0 - pow(1.0 - local_d, 3.0))

func _effect_item_index(effect_name: String) -> int:
	match effect_name:
		"reroll":
			return 0
		"bonus_10":
			return 1
		"x2":
			return 2
		"x3":
			return 3
		"add_ball":
			return 4
		"jam":
			return 5
		_:
			return 1

func _set_pointer_strength(pointer: ColorRect, active: bool) -> void:
	if pointer == null:
		return
	pointer.color = Color(1.0, 0.84, 0.18, 1.0 if active else 0.58)

func _total_duration() -> float:
	var total: float = DROP_DURATION + COLOR_SPIN_DURATION + COLOR_CONFIRM_DURATION
	for duration in _effect_round_durations:
		total += float(duration) + EFFECT_CONFIRM_DURATION
	total += RESULT_HOLD_DURATION + LIFT_DURATION
	return total

func _ease_out_back(t: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0)

func _ease_in_quad(t: float) -> float:
	return t * t

func _finish_presentation() -> void:
	_is_playing = false
	visible = false
	presentation_finished.emit(_payload.duplicate(true))
