extends RefCounted
class_name RegionYieldCalculator

const RegionControlCalculatorScript = preload("res://scripts/cardfront/regions/RegionControlCalculator.gd")
const RegionYieldRulesScript = preload("res://scripts/cardfront/economy/RegionYieldRules.gd")


static func calculate_for_owner(region_map, battlefield, owner_id: int) -> Dictionary:
	var total_yield: Dictionary = _empty_yield()
	var region_details: Array = []
	if region_map == null:
		return _owner_yield_result(owner_id, total_yield, region_details)

	for region_id in region_map.get_controllable_region_ids():
		var detail: Dictionary = calculate_region_yield(region_map, battlefield, int(region_id), owner_id)
		region_details.append(detail)
		var region_yield: Dictionary = detail.get("yield", {})
		total_yield["energy"] = int(total_yield.get("energy", 0)) + int(region_yield.get("energy", 0))
		total_yield["parts"] = int(total_yield.get("parts", 0)) + int(region_yield.get("parts", 0))

	return _owner_yield_result(owner_id, total_yield, region_details)


static func calculate_region_yield(region_map, battlefield, region_id: int, owner_id: int) -> Dictionary:
	if region_map == null:
		return {
			"region_id": region_id,
			"region_type": "",
			"owner_id": owner_id,
			"owner_percent": 0,
			"yield_tier": 0,
			"yield": _empty_yield(),
			"control": {},
		}

	var control: Dictionary = RegionControlCalculatorScript.calculate(region_map, battlefield, region_id)
	var region_type: String = region_map.get_region_type_by_id(region_id)
	var owner_percent: int = RegionControlCalculatorScript.get_owner_percent(control, owner_id)
	var yield_tier: int = RegionControlCalculatorScript.get_yield_tier(control, owner_id)
	return {
		"region_id": region_id,
		"region_type": region_type,
		"owner_id": owner_id,
		"owner_percent": owner_percent,
		"yield_tier": yield_tier,
		"yield": RegionYieldRulesScript.get_yield(region_type, yield_tier),
		"control": control,
	}


static func _owner_yield_result(owner_id: int, total_yield: Dictionary, regions: Array) -> Dictionary:
	return {
		"owner_id": owner_id,
		"total_yield": total_yield,
		"regions": regions,
	}


static func _empty_yield() -> Dictionary:
	return {
		"energy": 0,
		"parts": 0,
	}
