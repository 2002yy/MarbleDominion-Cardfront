extends RefCounted
class_name RegionYieldRules

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")


static func get_yield(region_type: String, tier: int) -> Dictionary:
	var safe_tier: int = clampi(int(tier), 0, 2)
	var result: Dictionary = _empty_yield()
	match region_type:
		RegionTypeScript.ENERGY:
			result["energy"] = safe_tier
		RegionTypeScript.FACTORY:
			result["parts"] = safe_tier
		RegionTypeScript.LAB:
			pass
		_:
			pass
	return result


static func _empty_yield() -> Dictionary:
	return {
		"energy": 0,
		"parts": 0,
	}
