extends Node
class_name CardfrontStrongholdSystem

signal status_sampled(snapshot)
# Compatibility signal name retained temporarily for presentation code that has
# not yet crossed P0-05B3. It carries status only, never legacy reward values.
signal bonuses_sampled(snapshot)

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")
const StrongholdRulesScript = preload("res://scripts/cardfront/strongholds/CardfrontStrongholdRules.gd")

var region_map = null
var battlefield = null
var last_snapshot: Dictionary = {}


func _init() -> void:
	name = "CardfrontStrongholdSystem"
	set_process(false)


func setup(new_region_map, new_battlefield) -> bool:
	region_map = new_region_map
	battlefield = new_battlefield
	if region_map == null or battlefield == null or not is_instance_valid(battlefield):
		return false
	last_snapshot = _empty_snapshot()
	return true


# P0-05B2 authoritative producer: this is a status/activation snapshot only.
# Factory/Energy/Lab legacy numeric rewards are intentionally not produced.
func sample_status() -> Dictionary:
	var snapshot: Dictionary = _empty_snapshot()
	var best_by_owner: Dictionary = {}
	for owner_id in CardfrontRulesScript.get_duel_factions():
		best_by_owner[int(owner_id)] = {}

	for raw_region_id in region_map.get_controllable_region_ids():
		var region_id: int = int(raw_region_id)
		var region_type: String = str(region_map.get_region_type_by_id(region_id))
		if not StrongholdRulesScript.is_stronghold_type(region_type):
			continue
		var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
		for owner_id in CardfrontRulesScript.get_duel_factions():
			var safe_owner_id: int = int(owner_id)
			var percent: int = RegionControlCalculatorScript.get_owner_percent(control, safe_owner_id)
			if percent < StrongholdRulesScript.ACTIVATION_PERCENT:
				continue
			var owner_best: Dictionary = best_by_owner[safe_owner_id]
			var current: Dictionary = owner_best.get(region_type, {}) as Dictionary
			if current.is_empty() or percent > int(current.get("percent", -1)) or (
				percent == int(current.get("percent", -1))
				and region_id < int(current.get("region_id", 2147483647))
			):
				owner_best[region_type] = {
					"region_id": region_id,
					"percent": percent,
				}

	for owner_id in CardfrontRulesScript.get_duel_factions():
		_apply_owner_best(snapshot[int(owner_id)], best_by_owner[int(owner_id)])

	last_snapshot = snapshot.duplicate(true)
	status_sampled.emit(last_snapshot.duplicate(true))
	bonuses_sampled.emit(last_snapshot.duplicate(true))
	return last_snapshot.duplicate(true)


# Legacy API shell. The name is retained only to avoid an unrelated caller
# break during the staged cutover. It is explicitly non-authoritative and
# returns the same status-only schema as sample_status().
func sample_bonuses() -> Dictionary:
	return sample_status()


func get_owner_status(owner_id: int) -> Dictionary:
	return (last_snapshot.get(int(owner_id), _empty_owner_status()) as Dictionary).duplicate(true)


# Legacy API shell; status only, no renamed/repackaged reward fields.
func get_owner_bonus(owner_id: int) -> Dictionary:
	return get_owner_status(owner_id)


func get_region_activation(region_id: int) -> Dictionary:
	for owner_id in CardfrontRulesScript.get_duel_factions():
		var status: Dictionary = last_snapshot.get(int(owner_id), {}) as Dictionary
		var active_regions: Dictionary = status.get("active_regions", {}) as Dictionary
		for region_type in active_regions.keys():
			if int(active_regions[region_type]) == int(region_id):
				return {
					"active": true,
					"owner_id": int(owner_id),
					"region_type": str(region_type),
				}
	return {
		"active": false,
		"owner_id": CardfrontRulesScript.NEUTRAL_OWNER,
		"region_type": "",
	}


# Legacy call seam retained until the global legacy search gate. It may attach
# active stronghold identity for diagnostics/presentation, but retired rewards
# are fixed at zero and cannot mutate combat.
func apply_to_volley_plan(owner_id: int, plan, snapshot: Dictionary = {}) -> void:
	if plan == null:
		return
	var source: Dictionary = snapshot if not snapshot.is_empty() else last_snapshot
	var status: Dictionary = source.get(int(owner_id), _empty_owner_status()) as Dictionary
	plan.stronghold_shot_bonus = 0
	plan.stronghold_attack_level_bonus = 0
	plan.active_stronghold_types = (status.get("active_types", []) as Array).duplicate()


func _apply_owner_best(owner_status: Dictionary, owner_best: Dictionary) -> void:
	var ordered_types: Array = [
		RegionTypeScript.FACTORY,
		RegionTypeScript.ENERGY,
		RegionTypeScript.LAB,
	]
	for region_type in ordered_types:
		if not owner_best.has(region_type):
			continue
		var candidate: Dictionary = owner_best[region_type]
		owner_status.active_types.append(region_type)
		owner_status.active_regions[region_type] = int(candidate.get("region_id", -1))
		owner_status.control_percent[region_type] = int(candidate.get("percent", 0))


func _empty_snapshot() -> Dictionary:
	return {
		CardfrontRulesScript.PLAYER_FACTION: _empty_owner_status(),
		CardfrontRulesScript.AI_FACTION: _empty_owner_status(),
	}


func _empty_owner_status() -> Dictionary:
	return {
		"active_types": [],
		"active_regions": {},
		"control_percent": {},
	}
