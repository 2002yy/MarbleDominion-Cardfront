extends CanvasLayer
class_name CardfrontCardDetailPopup

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontFeedbackTextScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackText.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

var feedback_bus = null
var resource_state = null

@onready var _panel: Panel = $Panel
@onready var _name_label: Label = $Panel/CardName
@onready var _type_label: Label = $Panel/CardType
@onready var _cost_label: Label = $Panel/Cost
@onready var _summary_label: Label = $Panel/Summary
@onready var _status_label: Label = $Panel/Status


func _ready() -> void:
	visible = false
	_ignore_mouse_recursive(_panel)
	_apply_style()


func setup(new_feedback_bus, new_resource_state, mode_name: String) -> void:
	feedback_bus = new_feedback_bus
	resource_state = new_resource_state
	visible = false
	if not CardfrontRulesScript.is_cardfront_mode(mode_name):
		return
	if feedback_bus == null:
		return
	if feedback_bus.has_signal("card_hovered"):
		var hover_callable := Callable(self, "_on_card_hovered")
		if not feedback_bus.card_hovered.is_connected(hover_callable):
			feedback_bus.card_hovered.connect(hover_callable)
	if feedback_bus.has_signal("card_unhovered"):
		var unhover_callable := Callable(self, "_on_card_unhovered")
		if not feedback_bus.card_unhovered.is_connected(unhover_callable):
			feedback_bus.card_unhovered.connect(unhover_callable)


func show_card(card_data: Dictionary, card_view: Control = null) -> void:
	_name_label.text = str(card_data.get("card_name", "未知卡牌"))
	_type_label.text = "类型 %s / 目标 %s" % [
		CardfrontFeedbackTextScript.card_type_to_text(str(card_data.get("card_type", ""))),
		CardfrontFeedbackTextScript.target_type_to_text(str(card_data.get("target_type", ""))),
	]
	_cost_label.text = "消耗 能量 %d / 零件 %d" % [
		int(card_data.get("energy_cost", 0)),
		int(card_data.get("parts_cost", 0)),
	]
	_summary_label.text = CardfrontFeedbackTextScript.effect_summary(str(card_data.get("effect_id", "")))
	_status_label.text = "当前状态：%s" % _status_text(card_data)
	_position_near_card(card_view)
	visible = true


func hide_card() -> void:
	visible = false


func get_status_text_for_test() -> String:
	return _status_label.text


func _status_text(card_data: Dictionary) -> String:
	if bool(card_data.get("used", false)):
		return "已使用"
	if not _can_pay(card_data):
		return "资源不足"
	return "可使用"


func _can_pay(card_data: Dictionary) -> bool:
	if resource_state == null or not resource_state.has_method("can_pay"):
		return true
	return resource_state.can_pay(int(card_data.get("energy_cost", 0)), int(card_data.get("parts_cost", 0)))


func _position_near_card(card_view: Control) -> void:
	if card_view == null or not is_instance_valid(card_view):
		_panel.position = Vector2(310.0, 420.0)
		return
	var viewport_size: Vector2 = card_view.get_viewport_rect().size
	var target_pos: Vector2 = card_view.global_position + Vector2(0.0, -float(_panel.size.y) - 12.0)
	target_pos.x = clampf(target_pos.x, 12.0, maxf(12.0, viewport_size.x - _panel.size.x - 12.0))
	target_pos.y = clampf(target_pos.y, 86.0, maxf(86.0, viewport_size.y - _panel.size.y - 12.0))
	_panel.position = target_pos


func _apply_style() -> void:
	var style = CardfrontUiAssetRegistryScript.make_panel_style(
		"detail_popup_panel",
		Color(0.03, 0.06, 0.11, 0.96),
		Color(0.45, 0.78, 1.0, 0.55)
	)
	_panel.add_theme_stylebox_override("panel", style)
	var font = CardfrontUiAssetRegistryScript.load_font()
	if font == null:
		return
	for label in [_name_label, _type_label, _cost_label, _summary_label, _status_label]:
		if label != null and is_instance_valid(label):
			label.add_theme_font_override("font", font)


func _ignore_mouse_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse_recursive(child)


func _on_card_hovered(_card_id: int, card_data: Dictionary, card_view: Control) -> void:
	show_card(card_data, card_view)


func _on_card_unhovered(_card_id: int, _card_data: Dictionary, _card_view: Control) -> void:
	hide_card()
