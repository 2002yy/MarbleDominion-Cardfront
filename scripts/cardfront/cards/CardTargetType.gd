extends RefCounted

const CardfrontContentManifestScript = preload("res://scripts/cardfront/content/CardfrontContentManifest.gd")

const OWNED_CELL: String = "owned_cell"
const OWNED_BORDER: String = "owned_border"
const OWNED_REGION: String = "owned_region"
const ENEMY_REGION: String = "enemy_region"
const NEUTRAL_REGION: String = "neutral_region"
const ANY_RESOURCE_REGION: String = "any_resource_region"
const OWNED_DEVICE: String = "owned_device"
const ENEMY_DEVICE: String = "enemy_device"
const TARGET_LINE: String = "target_line"
const TARGET_AREA: String = "target_area"
const FRONTLINE_DEPLOYMENT: String = "frontline_deployment"

static func is_valid(target_type: String) -> bool:
	return CardfrontContentManifestScript.is_target_type_valid(str(target_type))
