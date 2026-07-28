extends Button
class_name CardfrontUpgradeChoiceCard

signal upgrade_chosen(upgrade_id)

const RARITY_COLORS: Dictionary = {
	"common": Color(0.38, 0.80, 1.0),
	"uncommon": Color(1.0, 0.78, 0.24),
	"rare": Color(0.82, 0.48, 1.0),
}

@onready var rarity_label: Label = get_node("RarityLabel")
@onready var symbol_label: Label = get_node("SymbolLabel")
@onready var stats_label: Label = get_node("StatsLabel")
@onready var name_label: Label = get_node("NameLabel")
@onready var description_label: Label = get_node("DescriptionLabel")
@onready var lock_label: Label = get_node("LockLabel")

var definition: Dictionary = {}
var upgrade_id: String = ""
var _motion_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = custom_minimum_size * 0.5
	pressed.connect(_on_pressed)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_style(false)


func setup(new_definition: Dictionary) -> void:
	definition = new_definition.duplicate(true)
	upgrade_id = str(definition.get("id", ""))
	rarity_label.text = _rarity_text(str(definition.get("rarity", "common")))
	symbol_label.text = str(definition.get("symbol", "?"))
	stats_label.text = str(definition.get("display_stats", ""))
	stats_label.visible = not stats_label.text.is_empty()
	name_label.text = str(definition.get("name", upgrade_id))
	description_label.text = str(definition.get("description", ""))
	lock_label.visible = false
	disabled = false
	scale = Vector2.ONE
	modulate = Color.WHITE
	_apply_style(false)


func set_locked(selected: bool) -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	disabled = true
	lock_label.visible = selected
	lock_label.text = "\u5df2\u9009\u62e9" if selected else ""
	scale = Vector2.ONE
	modulate = Color.WHITE if selected else Color(0.58, 0.62, 0.70, 0.72)
	_apply_style(selected)


func _on_pressed() -> void:
	if upgrade_id == "":
		return
	upgrade_chosen.emit(upgrade_id)


func _on_button_down() -> void:
	_animate_to(Vector2(0.94, 0.94), 0.07)


func _on_button_up() -> void:
	_animate_to(Vector2(1.03, 1.03), 0.11)


func _on_mouse_entered() -> void:
	if disabled:
		return
	_animate_to(Vector2(1.035, 1.035), 0.12)
	_apply_style(true)


func _on_mouse_exited() -> void:
	if disabled:
		return
	_animate_to(Vector2.ONE, 0.12)
	_apply_style(false)


func _animate_to(target_scale: Vector2, duration: float) -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_BACK)
	_motion_tween.set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", target_scale, duration)


func _apply_style(highlighted: bool) -> void:
	var rarity: String = str(definition.get("rarity", "common"))
	var accent: Color = RARITY_COLORS.get(rarity, RARITY_COLORS.common)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.105, 0.985)
	style.border_color = accent.lightened(0.16) if highlighted else accent.darkened(0.10)
	style.set_border_width_all(4 if highlighted else 3)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 8
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_stylebox_override("disabled", style)
	if is_instance_valid(symbol_label):
		symbol_label.add_theme_color_override("font_color", accent)
	if is_instance_valid(rarity_label):
		rarity_label.add_theme_color_override("font_color", accent.lightened(0.25))


func _rarity_text(rarity: String) -> String:
	match rarity:
		"rare":
			return "\u7a00\u6709"
		"uncommon":
			return "\u8fdb\u9636"
		_:
			return "\u666e\u901a"
