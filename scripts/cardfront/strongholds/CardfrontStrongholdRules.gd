extends RefCounted
class_name CardfrontStrongholdRules

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

const RULESET_ID: String = "tactical_v1"
const ACTIVATION_PERCENT: int = 80
const FACTORY_SHOT_BONUS: int = 3
const ENERGY_ATTACK_LEVEL_BONUS: int = 1
const LAB_DRAFT_CHOICE_COUNT: int = 4
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
			return "齐射工厂"
		RegionTypeScript.LAB:
			return "战术实验室"
	return "战术据点"


static func effect_text(region_type: String) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "下一轮临时攻击等级 +%d" % ENERGY_ATTACK_LEVEL_BONUS
		RegionTypeScript.FACTORY:
			return "下一轮齐射 +%d 发" % FACTORY_SHOT_BONUS
		RegionTypeScript.LAB:
			return "下次四选一"
	return ""


static func badge_name(region_type: String) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "能源"
		RegionTypeScript.FACTORY:
			return "工厂"
		RegionTypeScript.LAB:
			return "实验室"
	return "据点"


static func compact_effect_text(region_type: String) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "能源+%d攻击等级" % ENERGY_ATTACK_LEVEL_BONUS
		RegionTypeScript.FACTORY:
			return "工厂+%d发" % FACTORY_SHOT_BONUS
		RegionTypeScript.LAB:
			return "实验室四选一"
	return ""
