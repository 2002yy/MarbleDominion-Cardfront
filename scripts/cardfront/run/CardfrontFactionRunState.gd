extends RefCounted
class_name CardfrontFactionRunState

const TuningScript = preload("res://scripts/cardfront/run/CardfrontRunTuning.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")
const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")
const ProjectileTypeScript = preload("res://scripts/cardfront/volley/CardfrontProjectileType.gd")

const DEFAULT_BASE_VOLLEY_COUNT: int = TuningScript.BASE_VOLLEY_COUNT
const DEFAULT_PROJECTILE_POWER: int = 1
const DEFAULT_TERRITORY_DEFENSE_CAP: int = 1
const MAX_TERRITORY_DEFENSE_CAP: int = TuningScript.MAX_TERRITORY_DEFENSE_CAP
const MAX_ATTACK_LEVEL: int = 3
const MAX_RESOLVED_ATTACK_LEVEL: int = 4
const MAX_RARITY_LEVEL: int = 3
const MAX_NEXT_VOLLEY_MULTIPLIER: int = 2

var owner_id: int = -1
var hero_id: String = HeroRegistryScript.DEFAULT_PLAYER_HERO_ID
var hero_name: String = ""
var deck_id: String = DeckRegistryScript.DEFAULT_DECK_ID
var base_volley_count: int = DEFAULT_BASE_VOLLEY_COUNT
var base_projectile_mix: Dictionary = {}
var command_chamber_health: int = TuningScript.COMMAND_CHAMBER_HEALTH
var starting_territory_defense: int = 1
var starting_contact_front_defense: int = 1
var captured_frontline_defense: int = 0
var frontline_repair_bonus: int = 0
var projectile_power: int = DEFAULT_PROJECTILE_POWER
var attack_level: int = 0
var territory_defense_cap: int = DEFAULT_TERRITORY_DEFENSE_CAP
var rarity_level: int = 0
var echo_next_choice_armed: bool = false
var queued_echo_upgrade_id: String = ""
var next_volley_bonus: int = 0
var next_volley_multiplier: int = 1
var next_volley_armor_pierce_contacts: int = 0
var next_volley_conversions: Dictionary = {}
var pending_repair_points: int = 0
var pending_repair_zone: String = "frontline"
var bridgehead_prefab_charges: int = 0
var bridgehead_prefab_defense_bonus: int = 0
var first_capture_fortified_cells: Dictionary = {}
var applied_upgrade_counts: Dictionary = {}


func setup(new_owner_id: int, new_base_volley_count: int = DEFAULT_BASE_VOLLEY_COUNT) -> void:
	owner_id = int(new_owner_id)
	hero_id = "custom"
	hero_name = ""
	deck_id = DeckRegistryScript.DEFAULT_DECK_ID
	base_volley_count = maxi(1, int(new_base_volley_count))
	base_projectile_mix = {
		ProjectileTypeScript.STANDARD: base_volley_count,
		ProjectileTypeScript.SIEGE: 0,
		ProjectileTypeScript.SUPPRESSION: 0,
	}
	command_chamber_health = TuningScript.COMMAND_CHAMBER_HEALTH
	starting_territory_defense = 1
	starting_contact_front_defense = 1
	captured_frontline_defense = 0
	frontline_repair_bonus = 0
	projectile_power = DEFAULT_PROJECTILE_POWER
	attack_level = 0
	territory_defense_cap = DEFAULT_TERRITORY_DEFENSE_CAP
	rarity_level = 0
	echo_next_choice_armed = false
	queued_echo_upgrade_id = ""
	next_volley_bonus = 0
	next_volley_multiplier = 1
	next_volley_armor_pierce_contacts = 0
	next_volley_conversions = {}
	pending_repair_points = 0
	pending_repair_zone = "frontline"
	bridgehead_prefab_charges = 0
	bridgehead_prefab_defense_bonus = 0
	first_capture_fortified_cells.clear()
	applied_upgrade_counts.clear()


func setup_from_hero(new_owner_id: int, new_hero_id: String) -> void:
	var safe_hero_id: String = HeroRegistryScript.sanitize_hero_id(new_hero_id)
	var definition: Dictionary = HeroRegistryScript.get_definition(safe_hero_id)
	setup(new_owner_id, int(definition.get("base_volley_count", DEFAULT_BASE_VOLLEY_COUNT)))
	hero_id = safe_hero_id
	hero_name = str(definition.get("name", ""))
	base_projectile_mix = (definition.get("base_projectile_mix", base_projectile_mix) as Dictionary).duplicate(true)
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
	starting_contact_front_defense = clampi(
		int(definition.get("starting_contact_front_defense", starting_territory_defense)),
		starting_territory_defense,
		territory_defense_cap
	)
	captured_frontline_defense = clampi(
		int(definition.get("captured_frontline_defense", 0)),
		0,
		territory_defense_cap
	)
	frontline_repair_bonus = maxi(0, int(definition.get("frontline_repair_bonus", 0)))


func set_deck_id(new_deck_id: String) -> void:
	deck_id = DeckRegistryScript.sanitize_deck_id(new_deck_id)


func add_next_volley_bonus(amount: int) -> void:
	next_volley_bonus = maxi(0, next_volley_bonus + maxi(0, int(amount)))


func multiply_next_volley(multiplier: int) -> void:
	if multiplier <= 1:
		return
	next_volley_multiplier = clampi(
		maxi(next_volley_multiplier, int(multiplier)),
		1,
		MAX_NEXT_VOLLEY_MULTIPLIER
	)


func add_next_volley_conversion(projectile_type: String, amount: int) -> void:
	var safe_type: String = ProjectileTypeScript.sanitize(projectile_type)
	if safe_type == ProjectileTypeScript.STANDARD or amount <= 0:
		return
	next_volley_conversions[safe_type] = maxi(0, int(next_volley_conversions.get(safe_type, 0)) + int(amount))


func increase_attack_level(amount: int) -> void:
	attack_level = clampi(attack_level + maxi(0, int(amount)), 0, MAX_ATTACK_LEVEL)


func increase_territory_defense_cap(amount: int) -> void:
	territory_defense_cap = clampi(
		territory_defense_cap + maxi(0, int(amount)),
		1,
		TuningScript.MAX_TERRITORY_DEFENSE_CAP
	)


func increase_rarity_level(amount: int) -> void:
	rarity_level = clampi(rarity_level + maxi(0, int(amount)), 0, MAX_RARITY_LEVEL)


func arm_echo_next_choice() -> void:
	echo_next_choice_armed = true


func consume_echo_next_choice() -> bool:
	var was_armed: bool = echo_next_choice_armed
	echo_next_choice_armed = false
	return was_armed


func queue_echo_upgrade(upgrade_id: String) -> void:
	queued_echo_upgrade_id = str(upgrade_id)


func consume_queued_echo_upgrade() -> String:
	var upgrade_id: String = queued_echo_upgrade_id
	queued_echo_upgrade_id = ""
	return upgrade_id


func add_armor_pierce_contacts(amount: int) -> void:
	next_volley_armor_pierce_contacts = maxi(
		next_volley_armor_pierce_contacts,
		maxi(0, int(amount))
	)


func request_territory_repair(amount: int, zone: String = "frontline") -> void:
	var safe_zone: String = str(zone) if str(zone) != "" else "frontline"
	var resolved_amount: int = maxi(0, int(amount))
	if safe_zone == "frontline" and resolved_amount > 0:
		resolved_amount += frontline_repair_bonus
	pending_repair_points += resolved_amount
	pending_repair_zone = safe_zone


func consume_pending_repair() -> Dictionary:
	var request: Dictionary = {
		"points": pending_repair_points,
		"zone": pending_repair_zone,
	}
	pending_repair_points = 0
	pending_repair_zone = "frontline"
	return request


func arm_bridgehead_prefabs(charges: int, defense_bonus: int) -> void:
	bridgehead_prefab_charges += maxi(0, int(charges))
	bridgehead_prefab_defense_bonus = maxi(bridgehead_prefab_defense_bonus, maxi(0, int(defense_bonus)))


func consume_bridgehead_prefab_bonus() -> int:
	if bridgehead_prefab_charges <= 0 or bridgehead_prefab_defense_bonus <= 0:
		return 0
	bridgehead_prefab_charges -= 1
	var result: int = bridgehead_prefab_defense_bonus
	if bridgehead_prefab_charges <= 0:
		bridgehead_prefab_defense_bonus = 0
	return result


func has_first_capture_fortified(cell: Vector2i) -> bool:
	return first_capture_fortified_cells.has(_cell_history_key(cell))


func mark_first_capture_fortified(cell: Vector2i) -> bool:
	var key: String = _cell_history_key(cell)
	if first_capture_fortified_cells.has(key):
		return false
	first_capture_fortified_cells[key] = true
	return true


func clear_first_capture_fortified_history() -> void:
	first_capture_fortified_cells.clear()


func consume_next_volley_modifiers() -> Dictionary:
	var modifiers: Dictionary = {
		"bonus": next_volley_bonus,
		"multiplier": next_volley_multiplier,
		"armor_pierce_contacts": next_volley_armor_pierce_contacts,
		"projectile_conversions": next_volley_conversions.duplicate(true),
	}
	next_volley_bonus = 0
	next_volley_multiplier = 1
	next_volley_armor_pierce_contacts = 0
	next_volley_conversions.clear()
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
		"deck_id": deck_id,
		"base_volley_count": base_volley_count,
		"base_projectile_mix": base_projectile_mix.duplicate(true),
		"command_chamber_health": command_chamber_health,
		"starting_territory_defense": starting_territory_defense,
		"starting_contact_front_defense": starting_contact_front_defense,
		"captured_frontline_defense": captured_frontline_defense,
		"frontline_repair_bonus": frontline_repair_bonus,
		"projectile_power": projectile_power,
		"attack_level": attack_level,
		"territory_defense_cap": territory_defense_cap,
		"rarity_level": rarity_level,
		"echo_next_choice_armed": echo_next_choice_armed,
		"queued_echo_upgrade_id": queued_echo_upgrade_id,
		"next_volley_bonus": next_volley_bonus,
		"next_volley_multiplier": next_volley_multiplier,
		"next_volley_armor_pierce_contacts": next_volley_armor_pierce_contacts,
		"next_volley_conversions": next_volley_conversions.duplicate(true),
		"pending_repair_points": pending_repair_points,
		"pending_repair_zone": pending_repair_zone,
		"bridgehead_prefab_charges": bridgehead_prefab_charges,
		"bridgehead_prefab_defense_bonus": bridgehead_prefab_defense_bonus,
		"first_capture_fortified_cells": first_capture_fortified_cells.duplicate(true),
		"applied_upgrade_counts": applied_upgrade_counts.duplicate(),
	}


func _cell_history_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
