extends CanvasLayer
class_name CardfrontBattlefieldScaleControl

const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var arena_view = null
var _buttons_by_scale: Dictionary = {}

@onready var _panel: Panel = $Panel
@onready var _title: Label = $Panel/Title
@onready var _scale_100: Button = $Panel/Scale100
@onready var _scale_112: Button = $Panel/Scale112
@onready var _scale_120: Button = $Panel/Scale120


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_buttons_by_scale = {
		1.0: _scale_100,
		1.12: _scale_112,
		1.20: _scale_120,
	}
	_connect_buttons()
	_apply_style()


func setup(new_arena_view, view_size: Vector2) -> bool:
	arena_view = new_arena_view
	if arena_view == null or not is_instance_valid(arena_view):
		visible = false
		return false
	_panel.position = Vector2(view_size.x - 172.0, view_size.y - 40.0)
	_panel.size = Vector2(160.0, 32.0)
	_sync_selected_state()
	visible = true
	return true


func select_scale(scale_value: float, animated: bool = true) -> float:
	if arena_view == null or not is_instance_valid(arena_view):
		return 1.0
	var resolved: float = float(arena_view.set_presentation_scale(scale_value, animated))
	_sync_selected_state()
	return resolved


func get_selected_scale_for_test() -> float:
	if arena_view == null or not is_instance_valid(arena_view):
		return 1.0
	return float(arena_view.get_presentation_scale())


func get_button_count_for_test() -> int:
	return _buttons_by_scale.size()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
		arena_view.step_presentation_scale(-1)
		_sync_selected_state()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
		arena_view.step_presentation_scale(1)
		_sync_selected_state()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_0 or event.keycode == KEY_KP_0:
		select_scale(arena_view.DEFAULT_PRESENTATION_SCALE)
		get_viewport().set_input_as_handled()


func _connect_buttons() -> void:
	for scale_value in _buttons_by_scale.keys():
		var button: Button = _buttons_by_scale[scale_value]
		var callable := Callable(self, "_on_scale_pressed").bind(float(scale_value))
		if not button.pressed.is_connected(callable):
			button.pressed.connect(callable)


func _on_scale_pressed(scale_value: float) -> void:
	select_scale(scale_value)


func _sync_selected_state() -> void:
	var selected: float = get_selected_scale_for_test()
	for scale_value in _buttons_by_scale.keys():
		var button: Button = _buttons_by_scale[scale_value]
		if is_equal_approx(float(scale_value), selected):
			button.button_pressed = true


func _apply_style() -> void:
	_panel.add_theme_stylebox_override(
		"panel",
		CardfrontUiAssetRegistryScript.make_panel_style(
			"resource_panel_bg",
			Color(0.035, 0.060, 0.064, 0.94),
			Color(0.67, 0.76, 0.55, 0.78)
		)
	)
	CardfrontUiAssetRegistryScript.apply_body_font(_title)
	var numeric_font = CardfrontUiAssetRegistryScript.load_font()
	for button in _buttons_by_scale.values():
		if numeric_font != null:
			(button as Button).add_theme_font_override("font", numeric_font)
