extends RefCounted
class_name CardfrontFactionRunState

const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

const DEFAULT_BASE_VOLLEY_COUNT: int = TuningScript.BASE_VOLLEY_COUNT
const DEFAULT_PROJECTILE_POWER: int = 1
const DEFAULT_TERRITORY_DEFENSE_CAP: int = 1
const MAX_RARITY_LEVEL: int = 5
const MAX_NEXT_VOLLEY_MULTIPLIER: int = 16

var owner_id: int = -1
var hero_id: String = HeroRegistryScript.DEFAULT_PLAYER_HERO_ID
var hero_name: String = ""
var base_volley_count: int = DEFAULT_BASE_VOLLEY_COUNT
var command_chamber_health: int = TuningScript.COMMAND_CHAMBER_HEALTH
var starting_territory_defense: int = 1
var projectile_power: int = DEFAULT_PROJECTILE_POWER
var territory_defense_cap: int = DEFAULT_TERRITORY_DEFENSE_CAP
var rarity_level: int = 0
var duplicate_next_choice: bool = false
var next_volley_bonus: int = 0
var next_volley_multiplier: int = 1
var applied_upgrade_counts: Dictionary = {}


func setup(new_owner_id: int, new_base_volley_count: int = DEFAULT_BASE_VOLLEY_COUNT) -> void:
	owner_id = int(new_owner_id)
	hero_id = "custom"
	hero_name = ""
	base_volley_count = maxi(1, int(new_base_volley_count))
	command_chamber_health = TuningScript.COMMAND_CHAMBER_HEALTH
	starting_territory_defense = 1
	projectile_power = DEFAULT_PROJECTILE_POWER
	territory_defense_cap = DEFAULT_TERRITORY_DEFENSE_CAP
	rarity_level = 0
	duplicate_next_choice = false
	next_volley_bonus = 0
	next_volley_multiplier = 1
	applied_upgrade_counts.clear()


func setup_from_hero(new_owner_id: int, new_hero_id: String) -> void:
	var safe_hero_id: String = HeroRegistryScript.sanitize_hero_id(new_hero_id)
	var definition: Dictionary = HeroRegistryScript.get_definition(safe_hero_id)
	setup(new_owner_id, int(definition.get("base_volley_count", DEFAULT_BASE_VOLLEY_COUNT)))
	hero_id = safe_hero_id
	hero_name = str(definition.get("name", ""))
	command_chamber_health = maxi(1, int(definition.get("command_chamber_health", TuningScript.COMMAND_CHAMBER_HEALTH)))
	starting_territory_defense = clampi(
		int(definition.get("starting_territory_defense", 1)),
		0,
		TuningScript.MAX_TERRITORY_DEFENSE_CAP
	)
	territory_defense_cap = clampi(
		int(definition.get("territory_defense_cap", DEFAULT_TERRITORY_DEFENSE_CAP)),
		1,
		TuningScript.MAX_TERRITORY_DEFENSE_CAP
	)
	starting_territory_defense = mini(starting_territory_defense, territory_defense_cap)


func add_next_volley_bonus(amount: int) -> void:
	next_volley_bonus = maxi(0, next_volley_bonus + maxi(0, int(amount)))


func multiply_next_volley(multiplier: int) -> void:
	if multiplier <= 1:
		return
	next_volley_multiplier = clampi(
		next_volley_multiplier * int(multiplier),
		1,
		MAX_NEXT_VOLLEY_MULTIPLIER
	)


func increase_projectile_power(amount: int) -> void:
	projectile_power = maxi(1, projectile_power + maxi(0, int(amount)))


func increase_territory_defense_cap(amount: int) -> void:
	territory_defense_cap = clampi(
		territory_defense_cap + maxi(0, int(amount)),
		1,
		TuningScript.MAX_TERRITORY_DEFENSE_CAP
	)


func increase_rarity_level(amount: int) -> void:
	rarity_level = clampi(rarity_level + maxi(0, int(amount)), 0, MAX_RARITY_LEVEL)


func arm_duplicate_next_choice() -> void:
	duplicate_next_choice = true


func consume_duplicate_next_choice() -> bool:
	var was_armed: bool = duplicate_next_choice
	duplicate_next_choice = false
	return was_armed


func consume_next_volley_modifiers() -> Dictionary:
	var modifiers: Dictionary = {
		"bonus": next_volley_bonus,
		"multiplier": next_volley_multiplier,
	}
	next_volley_bonus = 0
	next_volley_multiplier = 1
	return modifiers


func record_upgrade(upgrade_id: String, times: int = 1) -> void:
	var safe_id: String = str(upgrade_id)
	if safe_id == "" or times <= 0:
		return
	applied_upgrade_counts[safe_id] = int(applied_upgrade_counts.get(safe_id, 0)) + int(times)


func snapshot() -> Dictionary:
	return {
		"owner_id": owner_id,
		"hero_id": hero_id,
		"hero_name": hero_name,
		"base_volley_count": base_volley_count,
		"command_chamber_health": command_chamber_health,
		"starting_territory_defense": starting_territory_defense,
		"projectile_power": projectile_power,
		"territory_defense_cap": territory_defense_cap,
		"rarity_level": rarity_level,
		"duplicate_next_choice": duplicate_next_choice,
		"next_volley_bonus": next_volley_bonus,
		"next_volley_multiplier": next_volley_multiplier,
		"applied_upgrade_counts": applied_upgrade_counts.duplicate(),
	}
