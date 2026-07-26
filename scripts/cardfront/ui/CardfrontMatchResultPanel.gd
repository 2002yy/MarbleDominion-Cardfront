extends Control
class_name CardfrontMatchResultPanel

const CardfrontMatchFlowTextScript = preload("res://scripts/cardfront/ui/CardfrontMatchFlowText.gd")

@onready var _panel: Panel = get_node("Panel")
@onready var _accent: ColorRect = get_node("Panel/Accent")
@onready var _title_label: Label = get_node("Panel/TitleLabel")
@onready var _reason_label: Label = get_node("Panel/ReasonLabel")
@onready var _score_label: Label = get_node("Panel/ScoreLabel")
@onready var _restart_button: Button = get_node("Panel/RestartButton")
@onready var _menu_button: Button = get_node("Panel/MenuButton")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_restart_button.text = "\u518d\u6765\u4e00\u5c40"
	_menu_button.text = "\u8fd4\u56de\u83dc\u5355"
	visible = false


func setup(controller_ref, view_size: Vector2) -> void:
	position = Vector2.ZERO
	size = view_size
	_panel.position = Vector2((view_size.x - _panel.size.x) * 0.5, (view_size.y - _panel.size.y) * 0.5)
	_connect_if_available(_restart_button, controller_ref, "_restart_current_cardfront_match")
	_connect_if_available(_menu_button, controller_ref, "_exit_cardfront_result_to_menu")


func show_result(
	title_text: String,
	reason_text: String,
	owner_counts: Dictionary,
	total_cells: int,
	accent_color: Color,
	score_breakdown: Dictionary = {}
) -> void:
	_title_label.text = title_text
	_reason_label.text = reason_text
	_score_label.text = CardfrontMatchFlowTextScript.score_summary(owner_counts, total_cells, score_breakdown)
	_title_label.add_theme_color_override("font_color", accent_color.lightened(0.18))
	_accent.color = accent_color
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	_panel.scale = Vector2(0.88, 0.88)
	_panel.pivot_offset = _panel.size * 0.5
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.2)
	tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.28)


func hide_result() -> void:
	visible = false


func _connect_if_available(button: Button, controller_ref, method_name: String) -> void:
	if button == null or controller_ref == null or not controller_ref.has_method(method_name):
		return
	var callback := Callable(controller_ref, method_name)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
