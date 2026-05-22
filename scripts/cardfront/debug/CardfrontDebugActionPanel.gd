extends CanvasLayer
class_name CardfrontDebugActionPanel

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const CardPlayRequestScript = preload("res://scripts/cardfront/cards/CardPlayRequest.gd")
const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")

var device_layer = null
var card_system = null
var battlefield = null
var region_map = null
var _is_cardfront_panel: bool = false
var _toggle_allowed: bool = false
var _release_mode_override_for_test: int = -1

const BUTTON_H: int = 24
const BUTTON_W: int = 140
const MARGIN: int = 8
const DEBUG_FLAG_SETTING: String = "cardfront/debug_action_panel_enabled"


func _init() -> void:
	name = "CardfrontDebugActionPanel"
	layer = 20
	visible = false
	set_process_unhandled_input(false)


func setup(new_device_layer, new_card_system, new_battlefield, new_region_map, mode_name: String) -> void:
	device_layer = new_device_layer
	card_system = new_card_system
	battlefield = new_battlefield
	region_map = new_region_map
	_is_cardfront_panel = CardfrontRulesScript.is_cardfront_mode(mode_name)
	_toggle_allowed = _is_cardfront_panel and _can_toggle_in_current_build()
	visible = false
	set_process_unhandled_input(_toggle_allowed)
	if _is_cardfront_panel:
		_ensure_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not _toggle_allowed:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		toggle_debug_panel()
		var vp = get_viewport()
		if vp != null:
			vp.set_input_as_handled()


func toggle_debug_panel() -> bool:
	if not _toggle_allowed:
		visible = false
		return false
	visible = not visible
	return visible


func set_debug_panel_visible(should_show: bool) -> void:
	visible = should_show and _toggle_allowed


func is_toggle_allowed_for_test() -> bool:
	return _toggle_allowed


func is_debug_visible_for_test() -> bool:
	return visible


func set_release_mode_override_for_test(is_release: bool) -> void:
	_release_mode_override_for_test = 1 if is_release else 0


func _ensure_ui() -> void:
	for child in get_children():
		child.queue_free()

	var y: int = MARGIN
	y = _add_button("放置吸弹核心", func(): _place_device(DeviceTypeScript.ABSORBER_CORE), y)
	y = _add_button("放置工程机器人", func(): _place_device(DeviceTypeScript.ENGINEER_BOT), y)
	y = _add_button("放置拓荒信标", func(): _place_device(DeviceTypeScript.PIONEER_BEACON), y)
	y = _add_button("触发前线加固", func(): _play_card(CardCatalogScript.CARD_FRONTLINE_FORTIFY, true), y)
	y = _add_button("触发校准射击", func(): _play_card(CardCatalogScript.CARD_CALIBRATED_SHOT, false), y)
	y = _add_button("触发民心起伏", func(): _play_card(CardCatalogScript.CARD_MORALE_FLUCTUATION, false), y)


func _add_button(text: String, callback: Callable, y: int) -> int:
	var btn := Button.new()
	btn.text = text
	btn.position = Vector2(MARGIN, y)
	btn.size = Vector2(BUTTON_W, BUTTON_H)
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(callback)
	add_child(btn)
	return y + BUTTON_H + 2


func _place_device(device_type: String) -> void:
	if device_layer == null or battlefield == null:
		return
	var cell := _pick_default_cell()
	var req = DevicePlacementRequestScript.make(device_type, CardfrontRulesScript.PLAYER_FACTION, cell)
	device_layer.place(req)


func _play_card(card_id: int, needs_border: bool) -> void:
	if card_system == null:
		return
	var cell := _pick_default_border_cell() if needs_border else Vector2i.ZERO
	var req = CardPlayRequestScript.make(card_id, CardfrontRulesScript.PLAYER_FACTION, cell)
	card_system.play(req)


func _pick_default_cell() -> Vector2i:
	if battlefield == null:
		return Vector2i.ZERO
	return Vector2i(1, 1)


func _pick_default_border_cell() -> Vector2i:
	if battlefield == null:
		return Vector2i.ZERO
	var gs: int = int(battlefield.grid_size)
	var half: int = int(float(gs) / 2.0)
	return Vector2i(half - 1, int(float(half) / 2.0))


func get_button_count_for_test() -> int:
	var count: int = 0
	for child in get_children():
		if child is Button:
			count += 1
	return count


func _can_toggle_in_current_build() -> bool:
	if _is_release_build():
		return false
	if ProjectSettings.has_setting(DEBUG_FLAG_SETTING):
		return bool(ProjectSettings.get_setting(DEBUG_FLAG_SETTING))
	return true


func _is_release_build() -> bool:
	if _release_mode_override_for_test >= 0:
		return _release_mode_override_for_test == 1
	return OS.has_feature("release")
