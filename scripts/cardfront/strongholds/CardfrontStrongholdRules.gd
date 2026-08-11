extends RefCounted
class_name CardfrontStrongholdRules

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

const RULESET_ID: String = "tactical_v1"
const ACTIVATION_PERCENT: int = 80
const STRONGHOLD_TYPE_COUNT: int = 3


static func is_stronghold_type(region_type: String) -> bool:
	return region_type in [
		RegionTypeScript.ENERGY,
		RegionTypeScript.FACTORY,
		RegionTypeScript.LAB,
	]


static func display_name(region_type: String) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "能源中继站"
		RegionTypeScript.FACTORY:
			return "工业据点"
		RegionTypeScript.LAB:
			return "战术实验室"
	return "战术据点"


static func badge_name(region_type: String) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "能源"
		RegionTypeScript.FACTORY:
			return "工厂"
		RegionTypeScript.LAB:
			return "实验室"
	return "据点"
