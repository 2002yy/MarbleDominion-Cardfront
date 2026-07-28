extends Button
class_name CardfrontMapChoiceCard

const Catalog = preload("res://scripts/cardfront/ui/CardfrontPresentationCatalog.gd")

signal map_chosen(map_id: String)

@onready var preview: Control = $Content/Preview
@onready var name_label: Label = $Content/Name
@onready var subtitle_label: Label = $Content/Subtitle
@onready var description_label: Label = $Content/Description

var map_id: String = ""
var selected: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)


func configure(new_map_id: String) -> void:
	map_id = new_map_id
	var presentation: Dictionary = Catalog.map(map_id)
	preview.configure(map_id)
	name_label.text = str(presentation.get("display_name", map_id))
	subtitle_label.text = str(presentation.get("subtitle", ""))
	description_label.text = str(presentation.get("description", ""))
	_refresh_style()


func set_selected(value: bool) -> void:
	selected = value
	_refresh_style()


func _on_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.07)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
	map_chosen.emit(map_id)


func _refresh_style() -> void:
	var accent: Color = Catalog.map(map_id).get("accent", Color.WHITE)
	self_modulate = accent.lightened(0.22) if selected else Color(0.90, 0.92, 0.90)
