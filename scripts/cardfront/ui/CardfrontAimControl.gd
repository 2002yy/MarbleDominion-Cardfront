extends CanvasLayer
class_name CardfrontAimControl

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var direction_controller = null
var _syncing: bool = false
var _lane_panel: Panel = null
var _lane_slider: HSlider = null
var _lane_label: Label = null

@onready var _panel: Panel = $Panel
@onready var _title: Label = $Panel/Title
@onready var _angle_value: Label = $Panel/AngleValue
@onready var _slider: HSlider = $Panel/DirectionSlider
@onready var _left_button: Button = $Panel/LeftButton
@onready var _right_button: Button = $Panel/RightButton
@onready var _hint: Label = $Panel/Hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_style()


func setup(new_direction_controller, layout: Dictionary, mode_name: String) -> bool:
	direction_controller = new_direction_controller
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if not visible or direction_controller == null or not is_instance_valid(direction_controller):
		visible = false
		return false
	# Aim is contextual, so it lives on the lower edge instead of competing with
	# the left-side battlefield and region information.
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x < 1.0 or viewport_size.y < 1.0:
		viewport_size = Vector2(1152.0, 720.0)
	var compact_mode: bool = viewport_size.x < 680.0
	var battlefield_rect: Rect2 = layout.get("battlefield_rect", Rect2())
	var side_gutter_width: float = battlefield_rect.position.x - 12.0
	var use_side_gutter: bool = battlefield_rect.has_area() and side_gutter_width >= 208.0
	var panel_size := Vector2(
		minf(272.0, viewport_size.x - (20.0 if compact_mode else 32.0)),
		56.0 if compact_mode else 60.0
	)
	if use_side_gutter:
		panel_size.x = clampf(side_gutter_width - 12.0, 196.0, panel_size.x)
	var panel_x: float = 12.0 if use_side_gutter else (viewport_size.x - panel_size.x) * 0.5
	var panel_rect := Rect2(
		Vector2(panel_x, viewport_size.y - panel_size.y - (8.0 if compact_mode else 12.0)),
		panel_size
	)
	_panel.position = panel_rect.position
	_panel.size = panel_rect.size
	_layout_children()
	_connect_controls()
	_set_slider_value(float(direction_controller.get_offset_degrees()))
	_create_lane_split_ui(panel_rect)
	return true


func _create_lane_split_ui(aim_panel_rect: Rect2) -> void:
	if _lane_panel != null and is_instance_valid(_lane_panel):
		return
	if direction_controller == null or not direction_controller.has_method("get_lane_split"):
		return
	_lane_panel = Panel.new()
	_lane_panel.name = "LaneSplitPanel"
	var panel_size := Vector2(aim_panel_rect.size.x, 40.0)
	_lane_panel.position = Vector2(aim_panel_rect.position.x, aim_panel_rect.position.y - panel_size.y - 4.0)
	_lane_panel.size = panel_size
	_lane_panel.add_theme_stylebox_override(
		"panel",
		CardfrontUiAssetRegistryScript.make_panel_style(
			"resource_panel_bg",
			Color(0.025, 0.055, 0.075, 0.96),
			Color(0.30, 0.90, 1.0, 0.55)
		)
	)
	add_child(_lane_panel)

	var lane_title := Label.new()
	lane_title.text = "分桥"
	lane_title.position = Vector2(8.0, 3.0)
	lane_title.size = Vector2(44.0, 16.0)
	lane_title.add_theme_font_size_override("font_size", 13)
	CardfrontUiAssetRegistryScript.apply_body_font(lane_title)
	_lane_panel.add_child(lane_title)

	_lane_label = Label.new()
	_lane_label.position = Vector2(panel_size.x - 92.0, 3.0)
	_lane_label.size = Vector2(84.0, 16.0)
	_lane_label.add_theme_font_size_override("font_size", 13)
	_lane_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_lane_panel.add_child(_lane_label)

	_lane_slider = HSlider.new()
	_lane_slider.position = Vector2(8.0, 21.0)
	_lane_slider.size = Vector2(panel_size.x - 16.0, 16.0)
	_lane_slider.min_value = 0.0
	_lane_slider.max_value = 1.0
	_lane_slider.step = 0.05
	_lane_slider.value = 0.5
	_lane_slider.focus_mode = Control.FOCUS_NONE
	_lane_panel.add_child(_lane_slider)

	_lane_slider.value_changed.connect(_on_lane_slider_changed)
	direction_controller.set_lane_split(0.5)
	_update_lane_label(0.5)


func _on_lane_slider_changed(value: float) -> void:
	if direction_controller == null or not is_instance_valid(direction_controller):
		return
	direction_controller.set_lane_split(value)
	_update_lane_label(value)


func _update_lane_label(ratio: float) -> void:
	if _lane_label == null:
		return
	var left_pct: int = roundi(ratio * 100.0)
	var right_pct: int = 100 - left_pct
	_lane_label.text = "左%d%% 右%d%%" % [left_pct, right_pct]


func get_slider_value_for_test() -> float:
	return float(_slider.value)


func get_angle_text_for_test() -> String:
	return _angle_value.text


func set_offset_for_test(value: float) -> void:
	_slider.value = value


func _connect_controls() -> void:
	var slider_callable := Callable(self, "_on_slider_value_changed")
	if not _slider.value_changed.is_connected(slider_callable):
		_slider.value_changed.connect(slider_callable)
	var left_callable := Callable(self, "_on_left_pressed")
	if not _left_button.pressed.is_connected(left_callable):
		_left_button.pressed.connect(left_callable)
	var right_callable := Callable(self, "_on_right_pressed")
	if not _right_button.pressed.is_connected(right_callable):
		_right_button.pressed.connect(right_callable)
	var angle_callable := Callable(self, "_on_angle_changed")
	if direction_controller.has_signal("angle_changed") and not direction_controller.angle_changed.is_connected(angle_callable):
		direction_controller.angle_changed.connect(angle_callable)


func _on_slider_value_changed(value: float) -> void:
	if _syncing or direction_controller == null:
		return
	direction_controller.set_offset_degrees(value)


func _on_left_pressed() -> void:
	if direction_controller != null:
		direction_controller.nudge(-1)


func _on_right_pressed() -> void:
	if direction_controller != null:
		direction_controller.nudge(1)


func _on_angle_changed(_owner_id: int, _angle: float, offset_degrees: float) -> void:
	_set_slider_value(offset_degrees)


func _set_slider_value(offset_degrees: float) -> void:
	_syncing = true
	_slider.value = offset_degrees
	_syncing = false
	var rounded_offset: int = roundi(offset_degrees)
	if rounded_offset == 0:
		_angle_value.text = "正前方 0°"
	elif rounded_offset < 0:
		_angle_value.text = "左 %d°" % absi(rounded_offset)
	else:
		_angle_value.text = "右 %d°" % rounded_offset


func _layout_children() -> void:
	var width: float = _panel.size.x
	$Panel/Bg.position = Vector2(3.0, 3.0)
	$Panel/Bg.size = _panel.size - Vector2(6.0, 6.0)
	$Panel/Accent.position = Vector2(8.0, 4.0)
	$Panel/Accent.size = Vector2(width - 16.0, 3.0)
	_title.position = Vector2(10.0, 5.0)
	_title.size = Vector2(86.0, 18.0)
	_title.add_theme_font_size_override("font_size", 14)
	_angle_value.position = Vector2(width - 105.0, 4.0)
	_angle_value.size = Vector2(94.0, 20.0)
	_angle_value.add_theme_font_size_override("font_size", 16)
	_left_button.position = Vector2(8.0, 27.0)
	_left_button.size = Vector2(28.0, 25.0)
	_right_button.position = Vector2(width - 36.0, 27.0)
	_right_button.size = Vector2(28.0, 25.0)
	_slider.position = Vector2(41.0, 27.0)
	_slider.size = Vector2(maxf(72.0, width - 82.0), 25.0)
	_hint.visible = false


func _apply_style() -> void:
	_panel.add_theme_stylebox_override(
		"panel",
		CardfrontUiAssetRegistryScript.make_panel_style(
			"resource_panel_bg",
			Color(0.025, 0.055, 0.075, 0.98),
			Color(0.30, 0.90, 1.0, 0.72)
		)
	)
	for label in [_title, _hint]:
		CardfrontUiAssetRegistryScript.apply_body_font(label)
	CardfrontUiAssetRegistryScript.apply_numeric_font(_angle_value)
