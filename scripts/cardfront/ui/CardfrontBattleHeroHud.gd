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


func configure(assignments: Dictionary) -> void:
	var player_id: String = HeroRegistry.sanitize_hero_id(str(assignments.get(Rules.PLAYER_FACTION, HeroRegistry.DEFAULT_PLAYER_HERO_ID)))
	var ai_id: String = HeroRegistry.sanitize_hero_id(str(assignments.get(Rules.AI_FACTION, HeroRegistry.DEFAULT_AI_HERO_ID)))
	_configure_side(player_icon, player_name, player_stats, player_id, "玩家")
	_configure_side(ai_icon, ai_name, ai_stats, ai_id, "AI")
	player_icon.modulate.a = 0.0
	ai_icon.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(player_icon, "modulate:a", 1.0, 0.25)
	tween.tween_property(ai_icon, "modulate:a", 1.0, 0.25).set_delay(0.08)


func _configure_side(icon: Control, title: Label, stats: Label, hero_id: String, side_name: String) -> void:
	var presentation: Dictionary = Catalog.hero(hero_id)
	var definition: Dictionary = HeroRegistry.get_definition(hero_id)
	icon.configure(hero_id)
	title.text = "%s · %s" % [side_name, str(presentation.get("short_name", ""))]
	stats.text = "齐射 %d  舱体 %d  %s" % [
		int(definition.get("base_volley_count", 0)),
		int(definition.get("command_chamber_health", 0)),
		str(presentation.get("role", "")),
	]
