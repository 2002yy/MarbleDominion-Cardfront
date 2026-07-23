extends CanvasLayer
class_name CardfrontAimControl

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var direction_controller = null
var _syncing: bool = false

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
	var panel_rect: Rect2 = layout.get("aim_control_rect", Rect2(Vector2(26.0, 420.0), Vector2(292.0, 84.0)))
	_panel.position = panel_rect.position
	_panel.size = panel_rect.size
	_layout_children()
	_connect_controls()
	_set_slider_value(float(direction_controller.get_offset_degrees()))
	return true


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
	$Panel/Bg.position = Vector2(4.0, 4.0)
	$Panel/Bg.size = _panel.size - Vector2(8.0, 8.0)
	$Panel/Accent.position = Vector2(9.0, 5.0)
	$Panel/Accent.size = Vector2(width - 18.0, 3.0)
	_title.position = Vector2(13.0, 9.0)
	_title.size = Vector2(120.0, 22.0)
	_angle_value.position = Vector2(width - 140.0, 8.0)
	_angle_value.size = Vector2(125.0, 23.0)
	_left_button.position = Vector2(11.0, 35.0)
	_left_button.size = Vector2(32.0, 29.0)
	_right_button.position = Vector2(width - 43.0, 35.0)
	_right_button.size = Vector2(32.0, 29.0)
	_slider.position = Vector2(49.0, 35.0)
	_slider.size = Vector2(maxf(80.0, width - 98.0), 29.0)
	_hint.position = Vector2(12.0, 64.0)
	_hint.size = Vector2(width - 24.0, 17.0)


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
