extends RefCounted
class_name DeploymentRuleType

const OWNED_CELL: String = "owned_cell"
const OWNED_BORDER: String = "owned_border"
const OWNED_REGION_CONTROLLED: String = "owned_region_controlled"
const CONTESTED_REGION: String = "contested_region"
const ENEMY_REGION: String = "enemy_region"


static func all_types() -> Array[String]:
	return [
		OWNED_CELL,
		OWNED_BORDER,
		OWNED_REGION_CONTROLLED,
		CONTESTED_REGION,
		ENEMY_REGION,
	]


static func is_valid(rule_type: String) -> bool:
	return rule_type in all_types()
