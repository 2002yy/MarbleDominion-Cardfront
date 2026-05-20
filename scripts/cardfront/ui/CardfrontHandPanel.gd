extends CanvasLayer
class_name CardfrontHandPanel

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontCardViewScript = preload("res://scripts/cardfront/ui/CardfrontCardView.gd")

var card_system = null
var resource_states: Dictionary = {}
var _card_views: Array[CardfrontCardView] = []
var _panel_bg: ColorRect
var _hbox: HBoxContainer
var selection_controller = null
var economy_system = null

const PANEL_HEIGHT: float = 110.0
const CARD_GAP: float = 6.0
const CARD_W: float = 180.0


func _init() -> void:
	name = "CardfrontHandPanel"
	layer = 17


func setup(new_card_system, new_resource_states: Dictionary, new_economy_system, mode_name: String, view_size: Vector2) -> void:
	card_system = new_card_system
	resource_states = new_resource_states.duplicate(false)
	economy_system = new_economy_system
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if not visible:
		return
	_ensure_ui(view_size)
	_populate_cards()
	_connect_economy_signals()
	refresh()


func _ensure_ui(view_size: Vector2) -> void:
	var panel_w: float = CARD_W * 4 + CARD_GAP * 3 + 24.0
	var panel_x: float = (view_size.x - panel_w) * 0.5
	var panel_y: float = view_size.y - PANEL_HEIGHT - 8.0

	_panel_bg = ColorRect.new()
	_panel_bg.name = "PanelBg"
	_panel_bg.position = Vector2(panel_x, panel_y)
	_panel_bg.size = Vector2(panel_w, PANEL_HEIGHT)
	_panel_bg.color = Color(0.04, 0.07, 0.12, 0.90)
	add_child(_panel_bg)

	_hbox = HBoxContainer.new()
	_hbox.name = "CardHBox"
	_hbox.position = Vector2(panel_x + 12.0, panel_y + 5.0)
	_hbox.size = Vector2(panel_w - 24.0, PANEL_HEIGHT - 10.0)
	_hbox.add_theme_constant_override("separation", int(CARD_GAP))
	add_child(_hbox)


func _populate_cards() -> void:
	for view in _card_views:
		if is_instance_valid(view):
			view.queue_free()
	_card_views.clear()

	for i in range(4):
		var view: CardfrontCardView = CardfrontCardViewScript.new()
		view.name = "CardView_%d" % i
		_hbox.add_child(view)
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
		view.clicked_callback = func():
			if selection_controller != null and selection_controller.has_method("on_card_clicked"):
				selection_controller.on_card_clicked(view.card_id, view.card_data)


func get_card_view(card_id: int) -> CardfrontCardView:
	for view in _card_views:
		if view.card_id == card_id:
			return view
	return null


func set_card_selected(card_id: int) -> void:
	for view in _card_views:
		if view.card_id == card_id:
			view.set_state("selected")
		elif view.current_state == "selected":
			view.set_state("idle")


func clear_selection() -> void:
	for view in _card_views:
		if view.current_state == "selected":
			view.set_state("idle")


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
