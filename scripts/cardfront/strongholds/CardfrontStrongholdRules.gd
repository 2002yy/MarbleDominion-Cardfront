extends RefCounted
class_name CardfrontStrongholdRules

const RegionTypeScript = preload("res://scripts/cardfront/regions/RegionType.gd")

const RULESET_ID: String = "tactical_v1"
const ACTIVATION_PERCENT: int = 80
# Historical P0 baseline values. These are retained for migration evidence only;
# P0-05B1/B2 removed their gameplay authority and producer output.
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
			return "工业据点"
		RegionTypeScript.LAB:
			return "战术实验室"
	return "战术据点"


# P0-05B3 compatibility formatter. It must not promise a retired numeric
# reward. Live UI should prefer status/badge wording instead of treating this
# as an ability description; the function remains until the B5 legacy gate.
static func effect_text(region_type: String) -> String:
	if not is_stronghold_type(region_type):
		return ""
	return "%s控制状态" % badge_name(region_type)


static func badge_name(region_type: String) -> String:
	match region_type:
		RegionTypeScript.ENERGY:
			return "能源"
		RegionTypeScript.FACTORY:
			return "工厂"
		RegionTypeScript.LAB:
			return "实验室"
	return "据点"


# P0-05B3 compatibility formatter: identity only, never +3/+1/四选一.
static func compact_effect_text(region_type: String) -> String:
	return badge_name(region_type) if is_stronghold_type(region_type) else ""
