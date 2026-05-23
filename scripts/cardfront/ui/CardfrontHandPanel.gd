extends CanvasLayer
class_name CardfrontHandPanel

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")
const CardViewScene = preload("res://scenes/ui/cardfront/CardfrontCardView.tscn")

@onready var _action_hint_label: Label = $ActionHintLabel

var card_system = null
var resource_states: Dictionary = {}
var _card_views: Array[CardfrontCardView] = []
var selection_controller = null
var economy_system = null
var feedback_bus = null

const PANEL_HEIGHT: float = 80.0
const CARD_H: float = 150.0
const CARD_GAP: float = 8.0
const CARD_W: float = 130.0
const COLLAPSED_Y_OFFSET: float = 70.0
const MAX_VISIBLE_CARDS: int = 4

const CARD_HINTS: Dictionary = {
	1001: "前线加固：点击蓝色高亮的己方边界格，添加加固层",
	1002: "校准射击：点击青色高亮的敌方区域，6 秒内优先射击该区域",
	1003: "民心起伏：点击紫色高亮的己方区域，逐步提升区域控制",
	1004: "拓荒信标：点击己方边界格，向周围中立格扩张",
}


func setup(new_card_system, new_resource_states: Dictionary, new_economy_system, mode_name: String, view_size: Vector2, new_feedback_bus = null) -> void:
	card_system = new_card_system
	resource_states = new_resource_states.duplicate(false)
	economy_system = new_economy_system
	feedback_bus = new_feedback_bus
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if not visible:
		return
	_layout_panel(view_size)
	_populate_cards()
	_connect_economy_signals()
	refresh()
	_hide_action_hint()


func _layout_panel(view_size: Vector2) -> void:
	var panel_bg: Control = $PanelBg as Control
	var panel_border: Control = $PanelBorder as Control
	var container: Control = $CardHBox as Control
	var panel_w: float = CARD_W * float(MAX_VISIBLE_CARDS) + CARD_GAP * float(MAX_VISIBLE_CARDS - 1) + 24.0
	var panel_x: float = (view_size.x - panel_w) * 0.5
	var panel_y: float = view_size.y - PANEL_HEIGHT - 8.0
	panel_bg.position = Vector2(panel_x, panel_y)
	panel_bg.size = Vector2(panel_w, PANEL_HEIGHT)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_border.position = panel_bg.position
	panel_border.size = panel_bg.size
	panel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_art_assets(panel_bg)
	container.position = Vector2(panel_x + 12.0, view_size.y - CARD_H - 8.0)
	container.size = Vector2(panel_w - 24.0, CARD_H)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	_action_hint_label.position = Vector2(panel_x, container.position.y - 34.0)
	_action_hint_label.size = Vector2(panel_w, 28.0)
	_action_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_hint_style()


func _populate_cards() -> void:
	for view in _card_views:
		if is_instance_valid(view):
			view.queue_free()
	_card_views.clear()

	var container: Control = $CardHBox as Control
	var visible_card_count: int = MAX_VISIBLE_CARDS
	if card_system != null and is_instance_valid(card_system) and card_system.has_method("get_hand_card_data"):
		var hand_data: Array = card_system.get_hand_card_data()
		if not hand_data.is_empty():
			visible_card_count = mini(hand_data.size(), MAX_VISIBLE_CARDS)
	for i in range(visible_card_count):
		var view: CardfrontCardView = CardViewScene.instantiate()
		view.name = "CardView_%d" % i
		view.size = Vector2(CARD_W, CARD_H)
		view.custom_minimum_size = Vector2(CARD_W, CARD_H)
		view.position = Vector2(float(i) * (CARD_W + CARD_GAP), COLLAPSED_Y_OFFSET)
		view.set_feedback_bus(feedback_bus)
		container.add_child(view)
		_card_views.append(view)


func refresh() -> void:
	if card_system == null or not is_instance_valid(card_system):
		return
	if not card_system.has_method("get_hand_card_data"):
		return
	var hand_data: Array = card_system.get_hand_card_data()
	var player_state = resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	for i in range(mini(hand_data.size(), _card_views.size())):
		_card_views[i].bind(hand_data[i], player_state)


func set_selection_controller(controller) -> void:
	selection_controller = controller
	for view in _card_views:
		var card_view := view
		card_view.clicked_callback = func():
			if selection_controller != null and selection_controller.has_method("on_card_clicked"):
				selection_controller.on_card_clicked(card_view.card_id, card_view.card_data)


func get_card_view(card_id: int) -> CardfrontCardView:
	for view in _card_views:
		if view.card_id == card_id:
			return view
	return null


func set_card_selected(card_id: int) -> void:
	var selected_card_data: Dictionary = {}
	for view in _card_views:
		if view.card_id == card_id:
			view.set_state("selected")
			selected_card_data = view.card_data.duplicate(false)
		elif view.current_state == "selected":
			view.set_state("idle")
	if selected_card_data.is_empty():
		_hide_action_hint()
	else:
		_show_action_hint(card_id, selected_card_data)


func clear_selection() -> void:
	for view in _card_views:
		if view.current_state == "selected":
			view.set_state("idle")
	_hide_action_hint()


func get_action_hint_text() -> String:
	if _action_hint_label == null:
		return ""
	return str(_action_hint_label.text)


func is_action_hint_visible() -> bool:
	return _action_hint_label != null and _action_hint_label.visible


func get_action_hint_for_card(card_id: int, card_data: Dictionary = {}) -> String:
	var id_key: int = int(card_id)
	if CARD_HINTS.has(id_key):
		return str(CARD_HINTS[id_key])
	match str(card_data.get("effect_id", "")):
		"fortify_border":
			return str(CARD_HINTS[1001])
		"calibrated_shot":
			return str(CARD_HINTS[1002])
		"morale_fluctuation":
			return str(CARD_HINTS[1003])
		"pioneer_beacon_lite":
			return str(CARD_HINTS[1004])
	return ""


func _connect_economy_signals() -> void:
	if economy_system == null:
		return
	var c := Callable(self, "_on_resources_changed")
	if economy_system.has_signal("resources_changed") and not economy_system.resources_changed.is_connected(c):
		economy_system.resources_changed.connect(c)


func _on_resources_changed(owner_id: int, _snapshot: Dictionary) -> void:
	if int(owner_id) != CardfrontRulesScript.PLAYER_FACTION:
		return
	refresh()


func _apply_art_assets(panel_bg: Control) -> void:
	if panel_bg is Panel:
		var style = CardfrontUiAssetRegistryScript.make_panel_style(
			"hand_panel_bg",
			Color(0.04, 0.07, 0.12, 0.90),
			Color(0.20, 0.35, 0.55, 0.45)
		)
		(panel_bg as Panel).add_theme_stylebox_override("panel", style)


func _show_action_hint(card_id: int, card_data: Dictionary) -> void:
	var hint: String = get_action_hint_for_card(card_id, card_data)
	if hint == "":
		_hide_action_hint()
		return
	_action_hint_label.text = hint
	_action_hint_label.visible = true


func _hide_action_hint() -> void:
	if _action_hint_label == null:
		return
	_action_hint_label.text = ""
	_action_hint_label.visible = false


func _apply_hint_style() -> void:
	var font = CardfrontUiAssetRegistryScript.load_font()
	if font != null:
		_action_hint_label.add_theme_font_override("font", font)
