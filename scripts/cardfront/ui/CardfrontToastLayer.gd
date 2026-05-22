extends CanvasLayer
class_name CardfrontToastLayer

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const CardfrontFeedbackTextScript = preload("res://scripts/cardfront/ui/CardfrontFeedbackText.gd")
const CardfrontUiAssetRegistryScript = preload("res://scripts/cardfront/ui/CardfrontUiAssetRegistry.gd")

const MAX_TOASTS: int = 3
const DEFAULT_TTL: float = 2.2

var feedback_bus = null
var _toast_items: Array = []

@onready var _box: VBoxContainer = $ToastBox


func _ready() -> void:
	set_process(false)


func setup(new_feedback_bus, mode_name: String, view_size: Vector2 = Vector2(1120, 720)) -> void:
	feedback_bus = new_feedback_bus
	visible = CardfrontRulesScript.is_cardfront_mode(mode_name)
	_layout(view_size)
	if not visible or feedback_bus == null:
		return
	_connect_bus()


func show_toast(message: String, tone: String = "info", ttl: float = DEFAULT_TTL) -> Label:
	if str(message) == "":
		return null
	var label := Label.new()
	label.name = "Toast_%d" % _toast_items.size()
	label.text = str(message)
	label.custom_minimum_size = Vector2(260.0, 30.0)
	label.size = Vector2(260.0, 30.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	var font = CardfrontUiAssetRegistryScript.load_font()
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", _tone_color(tone))
	label.add_theme_stylebox_override("normal", _make_style(tone))
	_box.add_child(label)
	_toast_items.append({"label": label, "remaining": maxf(0.1, ttl)})
	_trim_to_max()
	set_process(true)
	return label


func get_toast_count_for_test() -> int:
	return _toast_items.size()


func get_toast_texts_for_test() -> Array[String]:
	var result: Array[String] = []
	for item in _toast_items:
		var label: Label = item.get("label", null)
		if label != null and is_instance_valid(label):
			result.append(label.text)
	return result


func _process(delta: float) -> void:
	var alive: Array = []
	for item in _toast_items:
		var label: Label = item.get("label", null)
		var remaining: float = float(item.get("remaining", 0.0)) - maxf(0.0, delta)
		if remaining > 0.0 and label != null and is_instance_valid(label):
			item["remaining"] = remaining
			alive.append(item)
		else:
			_remove_label(label)
	_toast_items = alive
	if _toast_items.is_empty():
		set_process(false)


func _connect_bus() -> void:
	var invalid_callable := Callable(self, "_on_target_invalid")
	if feedback_bus.has_signal("target_invalid") and not feedback_bus.target_invalid.is_connected(invalid_callable):
		feedback_bus.target_invalid.connect(invalid_callable)
	var success_callable := Callable(self, "_on_card_play_succeeded")
	if feedback_bus.has_signal("card_play_succeeded") and not feedback_bus.card_play_succeeded.is_connected(success_callable):
		feedback_bus.card_play_succeeded.connect(success_callable)
	var fail_callable := Callable(self, "_on_card_play_failed")
	if feedback_bus.has_signal("card_play_failed") and not feedback_bus.card_play_failed.is_connected(fail_callable):
		feedback_bus.card_play_failed.connect(fail_callable)


func _layout(view_size: Vector2) -> void:
	_box.position = Vector2(16.0, minf(292.0, maxf(120.0, view_size.y - 250.0)))
	_box.size = Vector2(272.0, 124.0)


func _trim_to_max() -> void:
	while _toast_items.size() > MAX_TOASTS:
		var oldest: Dictionary = _toast_items.pop_front()
		_remove_label(oldest.get("label", null))


func _remove_label(label) -> void:
	if label != null and is_instance_valid(label):
		label.queue_free()


func _tone_color(tone: String) -> Color:
	match str(tone):
		"success":
			return Color(0.62, 1.0, 0.72, 1.0)
		"warn":
			return Color(1.0, 0.82, 0.42, 1.0)
		"fail":
			return Color(1.0, 0.58, 0.50, 1.0)
		_:
			return Color(0.78, 0.90, 1.0, 1.0)


func _make_style(tone: String) -> StyleBox:
	return CardfrontUiAssetRegistryScript.make_panel_style(
		"toast_panel",
		Color(0.03, 0.06, 0.11, 0.92),
		Color(_tone_color(tone).r, _tone_color(tone).g, _tone_color(tone).b, 0.45)
	)


func _on_target_invalid(card_id: int, card_data: Dictionary, _cell: Vector2i, reason: String) -> void:
	var card_name: String = str(card_data.get("card_name", ""))
	if card_name == "" and card_id >= 0:
		card_name = "当前卡牌"
	show_toast(CardfrontFeedbackTextScript.reason_to_text(reason, card_name), "warn")


func _on_card_play_succeeded(_card_id: int, card_data: Dictionary, result: Dictionary) -> void:
	var card_name: String = str(result.get("card_name", card_data.get("card_name", "")))
	show_toast(CardfrontFeedbackTextScript.success_to_text(card_name), "success")


func _on_card_play_failed(_card_id: int, card_data: Dictionary, result: Dictionary) -> void:
	var card_name: String = str(result.get("card_name", card_data.get("card_name", "")))
	show_toast(CardfrontFeedbackTextScript.reason_to_text(str(result.get("reason", "unknown")), card_name), "fail")
