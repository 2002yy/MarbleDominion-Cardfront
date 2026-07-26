extends RefCounted
class_name CardfrontHeroRegistry

const HeroDefinitionScript = preload("res://scripts/cardfront/heroes/CardfrontHeroDefinition.gd")

const HERO_BALANCED_COMMANDER: String = "balanced_commander"
const HERO_RAPID_GUNNER: String = "rapid_gunner"
const HERO_FORTIFICATION_ENGINEER: String = "fortification_engineer"

const DEFAULT_PLAYER_HERO_ID: String = HERO_BALANCED_COMMANDER
const DEFAULT_AI_HERO_ID: String = HERO_BALANCED_COMMANDER

const DEFINITIONS: Dictionary = {
	HERO_BALANCED_COMMANDER: {
		"id": HERO_BALANCED_COMMANDER,
		"name": "均衡指挥官",
		"base_volley_count": 6,
		"command_chamber_health": 40,
		"starting_territory_defense": 1,
		"territory_defense_cap": 1,
		"strategic_identity": "卡牌兼容性",
	},
	HERO_RAPID_GUNNER: {
		"id": HERO_RAPID_GUNNER,
		"name": "连射炮手",
		"base_volley_count": 7,
		"command_chamber_health": 36,
		"starting_territory_defense": 1,
		"territory_defense_cap": 1,
		"strategic_identity": "齐射倍率收益",
	},
	HERO_FORTIFICATION_ENGINEER: {
		"id": HERO_FORTIFICATION_ENGINEER,
		"name": "筑垒工程师",
		"base_volley_count": 5,
		"command_chamber_health": 42,
		"starting_territory_defense": 1,
		"territory_defense_cap": 2,
		"strategic_identity": "防御容量与阵地经营",
	},
}


static func get_hero_ids() -> Array:
	var ids: Array = DEFINITIONS.keys()
	ids.sort()
	return ids


static func has_hero(hero_id: String) -> bool:
	return DEFINITIONS.has(str(hero_id))


static func get_definition(hero_id: String) -> Dictionary:
	return (DEFINITIONS.get(str(hero_id), {}) as Dictionary).duplicate(true)


static func sanitize_hero_id(hero_id: String, fallback_id: String = DEFAULT_PLAYER_HERO_ID) -> String:
	var requested: String = str(hero_id)
	if has_hero(requested):
		return requested
	return str(fallback_id) if has_hero(fallback_id) else DEFAULT_PLAYER_HERO_ID


static func assignments_from_config(config: Dictionary) -> Dictionary:
	return {
		GameConfig.Faction.BLUE: sanitize_hero_id(
			str(config.get("player_hero_id", DEFAULT_PLAYER_HERO_ID)),
			DEFAULT_PLAYER_HERO_ID
		),
		GameConfig.Faction.RED: sanitize_hero_id(
			str(config.get("ai_hero_id", DEFAULT_AI_HERO_ID)),
			DEFAULT_AI_HERO_ID
		),
	}


static func validate_all() -> Array:
	var errors: Array = []
	for hero_id in get_hero_ids():
		var definition: Dictionary = DEFINITIONS[str(hero_id)]
		if str(definition.get("id", "")) != str(hero_id):
			errors.append("id_mismatch:%s" % str(hero_id))
		errors.append_array(HeroDefinitionScript.validate(definition))
	return errors
