extends Button
class_name CardfrontHeroChoiceCard

const Catalog = preload("res://scripts/cardfront/ui/CardfrontPresentationCatalog.gd")
const HeroRegistry = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

signal hero_chosen(hero_id: String)

@onready var silhouette: Control = $Content/HeroSilhouette
@onready var name_label: Label = $Content/Name
@onready var role_label: Label = $Content/Role
@onready var stats_label: Label = $Content/Stats
@onready var trait_label: Label = $Content/Trait

var hero_id: String = ""
var selected: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_hovered)
	mouse_exited.connect(_on_unhovered)


func configure(new_hero_id: String) -> void:
	hero_id = new_hero_id
	var presentation: Dictionary = Catalog.hero(hero_id)
	var definition: Dictionary = HeroRegistry.get_definition(hero_id)
	name_label.text = str(presentation.get("display_name", hero_id))
	role_label.text = str(presentation.get("role", ""))
	stats_label.text = "齐射 %d   舱体 %d   防御 %d" % [
		int(definition.get("base_volley_count", 0)),
		int(definition.get("command_chamber_health", 0)),
		int(definition.get("territory_defense_cap", 0)),
	]
	trait_label.text = str(presentation.get("trait", ""))
	silhouette.configure(hero_id)
	_refresh_style()


func set_selected(value: bool) -> void:
	selected = value
	_refresh_style()


func _on_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.94, 0.94), 0.07)
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.10)
	tween.tween_property(self, "scale", Vector2.ONE, 0.10)
	hero_chosen.emit(hero_id)


func _on_hovered() -> void:
	if not selected:
		create_tween().tween_property(self, "scale", Vector2(1.025, 1.025), 0.10)


func _on_unhovered() -> void:
	if not selected:
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.10)


func _refresh_style() -> void:
	var accent: Color = Catalog.hero(hero_id).get("accent", Color(0.25, 0.62, 0.82))
	self_modulate = accent.lightened(0.22) if selected else Color.WHITE
	add_theme_color_override("font_color", Color.WHITE)
