extends Control
class_name CardfrontBattleHeroHud

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")
const HeroRegistry = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const Catalog = preload("res://scripts/cardfront/ui/CardfrontPresentationCatalog.gd")

@onready var player_icon: Control = $PlayerPlate/Row/Icon
@onready var player_name: Label = $PlayerPlate/Row/Text/Name
@onready var player_stats: Label = $PlayerPlate/Row/Text/Stats
@onready var ai_icon: Control = $AiPlate/Row/Icon
@onready var ai_name: Label = $AiPlate/Row/Text/Name
@onready var ai_stats: Label = $AiPlate/Row/Text/Stats
var _hero_ids: Dictionary = {}
var _turrets: Dictionary = {}
var _refresh_elapsed: float = 0.0


func configure(assignments: Dictionary, new_turrets: Dictionary = {}) -> void:
	var player_id: String = HeroRegistry.sanitize_hero_id(str(assignments.get(Rules.PLAYER_FACTION, HeroRegistry.DEFAULT_PLAYER_HERO_ID)))
	var ai_id: String = HeroRegistry.sanitize_hero_id(str(assignments.get(Rules.AI_FACTION, HeroRegistry.DEFAULT_AI_HERO_ID)))
	_hero_ids = {
		Rules.PLAYER_FACTION: player_id,
		Rules.AI_FACTION: ai_id,
	}
	_turrets = new_turrets.duplicate(false)
	_configure_side(player_icon, player_name, player_stats, player_id, "玩家")
	_configure_side(ai_icon, ai_name, ai_stats, ai_id, "AI")
	_refresh_health()
	set_process(not _turrets.is_empty())
	player_icon.modulate.a = 0.0
	ai_icon.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(player_icon, "modulate:a", 1.0, 0.25)
	tween.tween_property(ai_icon, "modulate:a", 1.0, 0.25).set_delay(0.08)


func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed < 0.12:
		return
	_refresh_elapsed = 0.0
	_refresh_health()


func _configure_side(icon: Control, title: Label, stats: Label, hero_id: String, side_name: String) -> void:
	var presentation: Dictionary = Catalog.hero(hero_id)
	var definition: Dictionary = HeroRegistry.get_definition(hero_id)
	icon.configure(hero_id)
	title.text = "%s  %s" % [side_name, str(presentation.get("short_name", ""))]
	stats.text = "齐射%d · 舱体%d" % [
		int(definition.get("base_volley_count", 0)),
		int(definition.get("command_chamber_health", 0)),
	]
	var plate: Control = icon.get_parent().get_parent()
	plate.tooltip_text = "%s｜%s" % [
		str(presentation.get("role", "")),
		str(presentation.get("description", "")),
	]


func _refresh_health() -> void:
	_refresh_side_stats(Rules.PLAYER_FACTION, player_stats)
	_refresh_side_stats(Rules.AI_FACTION, ai_stats)


func _refresh_side_stats(owner_id: int, stats: Label) -> void:
	var hero_id: String = str(_hero_ids.get(owner_id, ""))
	if hero_id.is_empty():
		return
	var definition: Dictionary = HeroRegistry.get_definition(hero_id)
	var max_health: int = maxi(1, int(definition.get("command_chamber_health", 0)))
	var health: int = max_health
	var turret = _turrets.get(owner_id, null)
	if turret != null and is_instance_valid(turret):
		health = maxi(0, int(turret.health))
		max_health = maxi(1, int(turret.max_health))
	stats.text = "\u751f\u547d %d/%d  \u00b7  \u9f50\u5c04%d" % [
		health,
		max_health,
		int(definition.get("base_volley_count", 0)),
	]
	stats.add_theme_color_override(
		"font_color",
		Color(1.0, 0.56, 0.48) if health * 3 < max_health else Color(0.84, 0.88, 0.86)
	)


func get_plate_rect_for_test(owner_id: int) -> Rect2:
	var plate: Control = $PlayerPlate if owner_id == Rules.PLAYER_FACTION else $AiPlate
	return Rect2(plate.position, plate.size)
