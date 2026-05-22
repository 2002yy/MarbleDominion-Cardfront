extends Panel
class_name CardfrontCardView

const CardVisualRegistryScript = preload("res://scripts/cardfront/ui/CardVisualRegistry.gd")

var card_id: int = -1
var card_data: Dictionary = {}
var current_state: String = "idle"
var clicked_callback: Callable = func(): pass
var feedback_bus = null

const CARD_SIZE := Vector2(130, 150)
const HOVER_SCALE := Vector2(1.035, 1.035)
const STATE_COLORS := {
	"idle": Color(0.06, 0.10, 0.18, 0.92),
	"hover": Color(0.08, 0.14, 0.24, 0.94),
	"selected": Color(0.10, 0.18, 0.32, 0.95),
	"disabled_resource": Color(0.04, 0.05, 0.08, 0.80),
	"used": Color(0.03, 0.04, 0.07, 0.70),
}
const COST_COLORS := {
	"affordable": Color(0.72, 0.88, 1.0),
	"expensive": Color(1.0, 0.48, 0.36),
}

const CARD_PLACEHOLDERS := {
	1001: {"icon": "🛡", "color": Color(0.24, 0.52, 0.88), "label": "加固"},
	1002: {"icon": "◎", "color": Color(0.20, 0.70, 0.72), "label": "校准"},
	1003: {"icon": "〰", "color": Color(0.72, 0.45, 1.0), "label": "民心"},
	1004: {"icon": "✦", "color": Color(0.90, 0.72, 0.18), "label": "信标"},
}
const DEFAULT_PLACEHOLDER := {"icon": "?", "color": Color(0.35, 0.40, 0.50), "label": "?"}
const TARGET_ICONS := {
	"owned_border": "▣ 己方边界格",
	"enemy_region": "◆ 敌方控制区",
	"owned_region": "◎ 己方控制区",
}


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	pivot_offset = size * 0.5


func set_feedback_bus(new_feedback_bus) -> void:
	feedback_bus = new_feedback_bus


func bind(data: Dictionary, resource_state) -> void:
	card_data = data.duplicate(false)
	card_id = int(data.get("id", -1))

	var ph: Dictionary = CARD_PLACEHOLDERS.get(card_id, DEFAULT_PLACEHOLDER)
	var icon_color: Color = ph.color

	var card_icon: ColorRect = $CardIcon as ColorRect
	card_icon.color = Color(icon_color.r * 0.22, icon_color.g * 0.22, icon_color.b * 0.22, 0.85)
	var icon_border: ColorRect = $CardIconBorder as ColorRect
	icon_border.color = Color(icon_color.r, icon_color.g, icon_color.b, 0.30)
	var icon_label: Label = $CardIconLabel as Label
	icon_label.text = str(ph.icon)

	var card_art: TextureRect = $CardArt as TextureRect
	var texture_path: String = CardVisualRegistryScript.get_texture_path(card_id)
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		if tex != null:
			card_art.texture = tex
			card_art.visible = true
			card_icon.visible = false
			icon_border.visible = false
			icon_label.visible = false
		else:
			card_art.visible = false
			card_icon.visible = true
			icon_border.visible = true
			icon_label.visible = true
	else:
		card_art.visible = false
		card_icon.visible = true
		icon_border.visible = true
		icon_label.visible = true

	var name_label: Label = $CardName as Label
	name_label.text = str(data.get("card_name", "???"))

	var energy_cost: int = int(data.get("energy_cost", 0))
	var parts_cost: int = int(data.get("parts_cost", 0))
	var used: bool = bool(data.get("used", false))
	var can_pay: bool = true
	if resource_state != null and resource_state.has_method("can_pay"):
		can_pay = resource_state.can_pay(energy_cost, parts_cost)

	var cost_energy: Label = $CostEnergy as Label
	cost_energy.text = "⚡%d" % energy_cost
	cost_energy.add_theme_color_override("font_color", COST_COLORS["affordable"] if can_pay else COST_COLORS["expensive"])
	var cost_parts: Label = $CostParts as Label
	cost_parts.text = "⚙%d" % parts_cost
	cost_parts.add_theme_color_override("font_color", COST_COLORS["affordable"] if can_pay else COST_COLORS["expensive"])

	var target_type: String = str(data.get("target_type", ""))
	var target_label: Label = $TargetLabel as Label
	target_label.text = TARGET_ICONS.get(target_type, "")

	var status_label: Label = $StatusLabel as Label

	if used:
		set_state("used")
		status_label.text = "已使用"
	elif not can_pay:
		set_state("disabled_resource")
		status_label.text = "资源不足"
	elif current_state in ["used", "disabled_resource"]:
		set_state("idle")
		status_label.text = ""
	elif current_state != "selected":
		status_label.text = ""


func set_state(state: String) -> void:
	current_state = state
	pivot_offset = size * 0.5
	var bg: ColorRect = $Bg as ColorRect
	bg.color = STATE_COLORS.get(state, STATE_COLORS["idle"])
	var card_border: ColorRect = $CardBorder as ColorRect
	var hover_border: ColorRect = $HoverBorder as ColorRect
	var selected_border: ColorRect = $SelectedBorder as ColorRect
	match state:
		"idle":
			card_border.color = Color(0.12, 0.18, 0.30, 0.0)
			hover_border.color = Color(0.62, 0.90, 1.0, 0.0)
			selected_border.color = Color(0.62, 0.90, 1.0, 0.0)
			_restore_text_colors()
		"hover":
			card_border.color = Color(0.62, 0.90, 1.0, 0.20)
			hover_border.color = Color(0.62, 0.90, 1.0, 0.20)
			selected_border.color = Color(0.62, 0.90, 1.0, 0.0)
			_restore_text_colors()
		"selected":
			card_border.color = Color(0.62, 0.90, 1.0, 0.40)
			hover_border.color = Color(0.62, 0.90, 1.0, 0.0)
			selected_border.color = Color(0.62, 0.90, 1.0, 0.35)
			_restore_text_colors()
		"disabled_resource":
			card_border.color = Color(0.08, 0.08, 0.10, 0.6)
			hover_border.color = Color(0.3, 0.2, 0.2, 0.0)
			selected_border.color = Color(0.62, 0.90, 1.0, 0.0)
		"used":
			card_border.color = Color(0.05, 0.05, 0.08, 0.6)
			hover_border.color = Color(0.62, 0.90, 1.0, 0.0)
			selected_border.color = Color(0.62, 0.90, 1.0, 0.0)
	_apply_feedback_transform()


func is_playable() -> bool:
	return current_state in ["idle", "hover"]


func is_clickable() -> bool:
	return current_state in ["idle", "hover", "selected"]


func _restore_text_colors() -> void:
	var name_label: Label = $CardName as Label
	name_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	var status_label: Label = $StatusLabel as Label
	status_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.80))


func _on_mouse_entered() -> void:
	if feedback_bus != null and feedback_bus.has_method("emit_card_hovered"):
		feedback_bus.emit_card_hovered(card_id, card_data, self)
	if current_state == "idle":
		set_state("hover")


func _on_mouse_exited() -> void:
	if feedback_bus != null and feedback_bus.has_method("emit_card_unhovered"):
		feedback_bus.emit_card_unhovered(card_id, card_data, self)
	if current_state == "hover":
		set_state("idle")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_clickable():
			if feedback_bus != null and feedback_bus.has_method("emit_card_clicked"):
				feedback_bus.emit_card_clicked(card_id, card_data, self)
			clicked_callback.call()


func _apply_feedback_transform() -> void:
	if current_state in ["hover", "selected"]:
		scale = HOVER_SCALE
		z_index = 20
	else:
		scale = Vector2.ONE
		z_index = 0
