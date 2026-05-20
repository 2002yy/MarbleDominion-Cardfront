extends Panel
class_name CardfrontCardView

var card_id: int = -1
var card_data: Dictionary = {}
var current_state: String = "idle"

@onready var _bg: ColorRect = $Bg
@onready var _name_label: Label = $NameLabel
@onready var _cost_label: Label = $CostLabel
@onready var _icon_rect: ColorRect = $IconRect
@onready var _status_label: Label = $StatusLabel
@onready var _hover_border: ColorRect = $HoverBorder
@onready var _selected_border: ColorRect = $SelectedBorder

const CARD_SIZE := Vector2(180, 100)
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


func _init() -> void:
	size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	name = "CardView"
	_create_children()


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)


func bind(data: Dictionary, resource_state) -> void:
	card_data = data.duplicate(false)
	card_id = int(data.get("id", -1))
	_name_label.text = str(data.get("card_name", "???"))
	var energy_cost: int = int(data.get("energy_cost", 0))
	var parts_cost: int = int(data.get("parts_cost", 0))
	var used: bool = bool(data.get("used", false))
	var can_pay: bool = true
	if resource_state != null and resource_state.has_method("can_pay"):
		can_pay = resource_state.can_pay(energy_cost, parts_cost)
	_cost_label.text = "E%d P%d" % [energy_cost, parts_cost]
	_cost_label.add_theme_color_override("font_color", COST_COLORS["affordable"] if can_pay else COST_COLORS["expensive"])

	var target_desc: String = _target_description(str(data.get("target_type", "")))
	_status_label.text = target_desc

	if used:
		set_state("used")
	elif not can_pay:
		set_state("disabled_resource")
	elif current_state in ["used", "disabled_resource"]:
		set_state("idle")


func _target_description(target_type: String) -> String:
	match target_type:
		"owned_border":
			return "目标：己方边界格"
		"enemy_region":
			return "目标：敌方控制区"
		"owned_region":
			return "目标：己方控制区"
		_:
			return ""


func set_state(state: String) -> void:
	current_state = state
	_bg.color = STATE_COLORS.get(state, STATE_COLORS["idle"])
	match state:
		"idle":
			_hover_border.color = Color(0.62, 0.90, 1.0, 0.0)
			_selected_border.color = Color(0.62, 0.90, 1.0, 0.0)
		"hover":
			_hover_border.color = Color(0.62, 0.90, 1.0, 0.25)
			_selected_border.color = Color(0.62, 0.90, 1.0, 0.0)
		"selected":
			_hover_border.color = Color(0.62, 0.90, 1.0, 0.0)
			_selected_border.color = Color(0.62, 0.90, 1.0, 0.45)
		"disabled_resource":
			_name_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
			_status_label.text = "资源不足"
		"used":
			_name_label.add_theme_color_override("font_color", Color(0.35, 0.38, 0.42))
			_status_label.text = "已使用"


func is_playable() -> bool:
	return current_state in ["idle", "hover"]


func _on_mouse_entered() -> void:
	if current_state == "idle":
		set_state("hover")


func _on_mouse_exited() -> void:
	if current_state == "hover":
		set_state("idle")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_playable():
			_on_clicked()


func _on_clicked() -> void:
	pass
