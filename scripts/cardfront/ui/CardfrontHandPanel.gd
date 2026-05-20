extends CanvasLayer
class_name CardfrontHandPanel

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardViewScene = preload("res://scenes/ui/cardfront/CardfrontCardView.tscn")

var card_system = null
var resource_states: Dictionary = {}
var _card_views: Array[CardfrontCardView] = []
var selection_controller = null
var economy_system = null

const PANEL_HEIGHT: float = 160.0
const CARD_GAP: float = 8.0
const CARD_W: float = 130.0


func setup(new_card_system, new_resource_states: Dictionary, new_economy_system, mode_name: String, view_size: Vector2) -> void:
	card_system = new_card_system
	resource_states = new_resource_states.duplicate(false)
	economy_system = new_economy_system
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if not visible:
		return
	_layout_panel(view_size)
	_populate_cards()
	_connect_economy_signals()
	refresh()


func _layout_panel(view_size: Vector2) -> void:
	var panel_bg: ColorRect = $PanelBg as ColorRect
	var hbox: HBoxContainer = $CardHBox as HBoxContainer
	var panel_w: float = CARD_W * 4 + CARD_GAP * 3 + 24.0
	var panel_x: float = (view_size.x - panel_w) * 0.5
	var panel_y: float = view_size.y - PANEL_HEIGHT - 8.0
	panel_bg.position = Vector2(panel_x, panel_y)
	panel_bg.size = Vector2(panel_w, PANEL_HEIGHT)
	hbox.position = Vector2(panel_x + 12.0, panel_y + 5.0)
	hbox.size = Vector2(panel_w - 24.0, PANEL_HEIGHT - 10.0)


func _populate_cards() -> void:
	for view in _card_views:
		if is_instance_valid(view):
			view.queue_free()
	_card_views.clear()

	for i in range(4):
		var view: CardfrontCardView = CardViewScene.instantiate()
		view.name = "CardView_%d" % i
		var hbox: HBoxContainer = $CardHBox as HBoxContainer
		hbox.add_child(view)
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
