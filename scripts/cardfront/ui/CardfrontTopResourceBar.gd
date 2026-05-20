extends CanvasLayer
class_name CardfrontTopResourceBar

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

var resource_states: Dictionary = {}
var economy_system = null
var last_energy: int = -1
var last_parts: int = -1

var _energy_box: Panel
var _parts_box: Panel
var _energy_value: Label
var _parts_value: Label
var _yield_label: Label


func _init() -> void:
	name = "CardfrontTopResourceBar"
	layer = 17


func setup(new_economy_system, new_resource_states: Dictionary, mode_name: String) -> void:
	economy_system = new_economy_system
	resource_states = new_resource_states.duplicate(false)
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	if not visible:
		return
	_ensure_ui()
	_connect_economy_signals()
	refresh(true)


func _ensure_ui() -> void:
	var container := MarginContainer.new()
	container.name = "Margin"
	container.add_theme_constant_override("margin_left", 18)
	container.add_theme_constant_override("margin_top", 4)
	container.position = Vector2(0, 98)
	container.size = Vector2(360, 36)
	add_child(container)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 10)
	container.add_child(hbox)

	_energy_box = _make_resource_box(hbox, "⚡ 能量", Color(0.62, 0.90, 1.0))
	_parts_box = _make_resource_box(hbox, "⚙ 零件", Color(1.0, 0.82, 0.36))
	_energy_value = _energy_box.get_node("Value") as Label
	_parts_value = _parts_box.get_node("Value") as Label

	_yield_label = Label.new()
	_yield_label.name = "YieldLabel"
	_yield_label.text = ""
	_yield_label.add_theme_font_size_override("font_size", 11)
	_yield_label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
	hbox.add_child(_yield_label)


func _make_resource_box(parent: HBoxContainer, title: String, accent: Color) -> Panel:
	var box := Panel.new()
	box.name = title
	box.size = Vector2(160, 28)
	box.self_modulate = Color(0.06, 0.10, 0.18, 0.88)
	parent.add_child(box)

	var bg := ColorRect.new()
	bg.name = "Bg"
	bg.color = Color(0.04, 0.07, 0.13, 0.95)
	bg.size = box.size
	bg.position = Vector2.ZERO
	box.add_child(bg)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	box.add_child(margin)

	var inner := HBoxContainer.new()
	inner.name = "Inner"
	inner.add_theme_constant_override("separation", 6)
	margin.add_child(inner)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", accent)
	inner.add_child(name_label)

	var value_label := Label.new()
	value_label.name = "Value"
	value_label.text = "0"
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	value_label.add_theme_constant_override("outline_size", 1)
	inner.add_child(value_label)

	return box


func _connect_economy_signals() -> void:
	if economy_system == null:
		return
	var c := Callable(self, "_on_resources_changed")
	if economy_system.has_signal("resources_changed") and not economy_system.resources_changed.is_connected(c):
		economy_system.resources_changed.connect(c)
	var y := Callable(self, "_on_yield_tick")
	if economy_system.has_signal("yield_tick") and not economy_system.yield_tick.is_connected(y):
		economy_system.yield_tick.connect(y)


func _on_resources_changed(owner_id: int, _snapshot: Dictionary) -> void:
	if int(owner_id) != CardfrontRulesScript.PLAYER_FACTION:
		return
	refresh()


func _on_yield_tick(owner_id: int, yield_data: Dictionary) -> void:
	if int(owner_id) != CardfrontRulesScript.PLAYER_FACTION:
		return
	var total: Dictionary = yield_data.get("total_yield", {})
	var energy_yield: int = int(total.get("energy", 0))
	var parts_yield: int = int(total.get("parts", 0))
	if _yield_label != null and is_instance_valid(_yield_label):
		_yield_label.text = "+%d/s" % (energy_yield + parts_yield)


func refresh(force: bool = false) -> void:
	var state = resource_states.get(CardfrontRulesScript.PLAYER_FACTION, null)
	if state == null:
		return
	var e := int(state.energy)
	var p := int(state.parts)
	if force or e != last_energy:
		if _energy_value != null and is_instance_valid(_energy_value):
			_energy_value.text = str(e)
		last_energy = e
	if force or p != last_parts:
		if _parts_value != null and is_instance_valid(_parts_value):
			_parts_value.text = str(p)
		last_parts = p
