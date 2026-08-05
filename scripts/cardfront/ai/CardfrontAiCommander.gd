extends RefCounted
class_name CardfrontAiCommander

const AiPolicyScript = preload("res://scripts/cardfront/run/CardfrontAiUpgradePolicy.gd")
const HeroRegistryScript = preload("res://scripts/cardfront/heroes/CardfrontHeroRegistry.gd")

const ARCHETYPE_BALANCED = "balanced"
const ARCHETYPE_AGGRESSIVE = "aggressive"
const ARCHETYPE_DEFENSIVE = "defensive"
const ARCHETYPE_ECONOMIC = "economic"
const ARCHETYPE_RUSH = "rush"

const HERO_ARCHETYPE: Dictionary = {
	"balanced_commander": ARCHETYPE_BALANCED,
	"rapid_gunner": ARCHETYPE_AGGRESSIVE,
	"fortification_engineer": ARCHETYPE_DEFENSIVE,
}

const ARCHETYPE_WEIGHTS: Dictionary = {
	"aggressive": {
		"attack_training": 1.4, "siege_formation": 1.5, "heavy_charge": 1.6,
		"building_volley": 1.3, "sapper_unit": 1.3, "awaken_gate_colossus": 1.3,
		"thicken_position": 0.7, "frontline_repair": 0.7, "interceptor_tower": 0.6,
		"armored_guard": 0.7, "rarity_premonition": 0.8, "delayed_echo": 0.7,
	},
	"defensive": {
		"thicken_position": 1.5, "frontline_repair": 1.4, "interceptor_tower": 1.5,
		"armored_guard": 1.4, "fire_control_beacon": 1.3, "repair_units": 1.3,
		"attack_training": 0.8, "heavy_charge": 0.6, "sapper_unit": 0.7,
		"double_volley": 0.8, "reinforced_volley": 0.9,
	},
	"economic": {
		"rarity_premonition": 1.6, "delayed_echo": 1.5, "building_volley": 1.4,
		"fire_control_beacon": 1.3, "awaken_gate_colossus": 1.2,
		"reinforced_volley": 0.8, "double_volley": 0.8, "armor_piercing_trajectory": 0.8,
	},
	"rush": {
		"reinforced_volley": 1.5, "double_volley": 1.6, "armor_piercing_trajectory": 1.4,
		"attack_training": 1.3, "suppression_formation": 1.3,
		"thicken_position": 0.6, "frontline_repair": 0.6, "rarity_premonition": 0.5,
		"delayed_echo": 0.4, "interceptor_tower": 0.6,
	},
	"balanced": {},
}

const LOW_HEALTH_THRESHOLD: float = 0.4
const EARLY_GAME_ROUND: int = 5
const LATE_GAME_ROUND: int = 15

var _base_policy = AiPolicyScript.new()
var _archetype: String = ARCHETYPE_BALANCED
var _hero_id: String = ""
var _last_context_snapshot: Dictionary = {}
var _last_ranked_evaluations: Array = []

func set_hero(hero_id: String) -> void:
	_hero_id = str(hero_id)
	_archetype = str(HERO_ARCHETYPE.get(_hero_id, ARCHETYPE_BALANCED))

func get_archetype() -> String:
	return _archetype

func get_base_policy() -> RefCounted:
	return _base_policy

func choose(
	offer: Array,
	run_state = null,
	context: Dictionary = {}
) -> Dictionary:
	var offer_ids: Array = []
	var definitions_by_id: Dictionary = {}
	for raw_definition in offer:
		if not (raw_definition is Dictionary):
			continue
		var definition: Dictionary = raw_definition as Dictionary
		var upgrade_id: String = str(definition.get("id", ""))
		if upgrade_id == "":
			continue
		offer_ids.append(upgrade_id)
		definitions_by_id[upgrade_id] = definition
	var chosen_id: String = choose_id(offer_ids, run_state, context)
	if chosen_id == "" or not definitions_by_id.has(chosen_id):
		return {}
	return (definitions_by_id[chosen_id] as Dictionary).duplicate(true)

func choose_id(
	offer_ids: Array,
	run_state = null,
	context: Dictionary = {}
) -> String:
	var ranked: Array = _base_policy.rank_ids(offer_ids, run_state, context)
	if ranked.is_empty():
		_last_ranked_evaluations = []
		return ""
	var resolved_archetype: String = _resolve_archetype(context)
	var weights: Dictionary = ARCHETYPE_WEIGHTS.get(resolved_archetype, {})
	for evaluation in ranked:
		var upgrade_id: String = str(evaluation.get("upgrade_id", ""))
		var weight: float = float(weights.get(upgrade_id, 1.0))
		var base_score: float = float(evaluation.get("tie_broken_score", evaluation.get("score", -INF)))
		evaluation["commander_weight"] = weight
		evaluation["commander_score"] = base_score * weight
		evaluation["commander_archetype"] = resolved_archetype
	ranked.sort_custom(_sort_commander_evaluations)
	_last_ranked_evaluations = ranked
	return str(ranked[0].get("upgrade_id", ""))

func get_last_ranked_evaluations() -> Array:
	return _last_ranked_evaluations.duplicate(true)

func _resolve_archetype(context: Dictionary) -> String:
	var resolved: String = _archetype
	var chamber_hp_ratio: float = float(context.get("own_health_ratio", 1.0))
	var round_number: int = int(context.get("round_number", 0))
	if chamber_hp_ratio < LOW_HEALTH_THRESHOLD and _archetype != ARCHETYPE_DEFENSIVE:
		resolved = ARCHETYPE_DEFENSIVE
	if round_number < EARLY_GAME_ROUND and _archetype == ARCHETYPE_ECONOMIC:
		resolved = ARCHETYPE_BALANCED
	if round_number >= LATE_GAME_ROUND and _archetype == ARCHETYPE_ECONOMIC:
		resolved = ARCHETYPE_AGGRESSIVE
	_last_context_snapshot = {
		"base_archetype": _archetype,
		"resolved_archetype": resolved,
		"chamber_hp_ratio": chamber_hp_ratio,
		"round_number": round_number,
	}
	return resolved

func _sort_commander_evaluations(left: Dictionary, right: Dictionary) -> bool:
	var left_score: float = float(left.get("commander_score", left.get("tie_broken_score", -INF)))
	var right_score: float = float(right.get("commander_score", right.get("tie_broken_score", -INF)))
	if absf(left_score - right_score) < 0.000001:
		return int(left.get("offer_index", 0)) < int(right.get("offer_index", 0))
	return left_score > right_score
