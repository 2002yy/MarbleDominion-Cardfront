extends RefCounted
class_name DeploymentSupportDefinition

const ROUTE_ROLE_CORE: String = "CORE"
const ROUTE_ROLE_LEFT: String = "LEFT"
const ROUTE_ROLE_RIGHT: String = "RIGHT"
const ROUTE_ROLE_CENTER_TRANSFER: String = "CENTER_TRANSFER"

const ROUTE_ROLES: Array[String] = [
	ROUTE_ROLE_CORE,
	ROUTE_ROLE_LEFT,
	ROUTE_ROLE_RIGHT,
	ROUTE_ROLE_CENTER_TRANSFER,
]

const REQUIRED_KEYS: Array[String] = [
	"support_id",
	"anchor_cell",
	"is_core",
	"authored_neighbors",
	"route_role",
	"player_deploy_direction",
	"ai_deploy_direction",
	"deployment_profile_id",
	"capture_profile_id",
	"suppression_profile_id",
]

const FORBIDDEN_LEGACY_BONUS_KEYS: Array[String] = [
	"shot_bonus",
	"attack_bonus",
	"draft_choice_bonus",
	"resource_income",
	"rarity_bonus",
]


static func make(
	support_id: String,
	anchor_cell: Vector2i,
	is_core: bool,
	authored_neighbors: Array[String],
	route_role: String,
	player_deploy_direction: Vector2i,
	ai_deploy_direction: Vector2i,
	deployment_profile_id: String,
	capture_profile_id: String,
	suppression_profile_id: String
) -> Dictionary:
	return {
		"support_id": str(support_id),
		"anchor_cell": anchor_cell,
		"is_core": is_core,
		"authored_neighbors": authored_neighbors.duplicate(),
		"route_role": str(route_role),
		"player_deploy_direction": player_deploy_direction,
		"ai_deploy_direction": ai_deploy_direction,
		"deployment_profile_id": str(deployment_profile_id),
		"capture_profile_id": str(capture_profile_id),
		"suppression_profile_id": str(suppression_profile_id),
	}


static func validate(definition: Dictionary) -> Array:
	var errors: Array = []
	var support_id: String = str(definition.get("support_id", ""))
	for key in REQUIRED_KEYS:
		if not definition.has(key):
			errors.append("missing_key:%s:%s" % [support_id, key])
	for key in FORBIDDEN_LEGACY_BONUS_KEYS:
		if definition.has(key):
			errors.append("forbidden_legacy_bonus:%s:%s" % [support_id, key])

	if support_id == "":
		errors.append("missing_support_id")
	if not definition.get("anchor_cell") is Vector2i:
		errors.append("invalid_anchor_cell:%s" % support_id)
	if not definition.get("is_core") is bool:
		errors.append("invalid_is_core:%s" % support_id)

	var neighbors_value = definition.get("authored_neighbors")
	if not neighbors_value is Array:
		errors.append("invalid_authored_neighbors:%s" % support_id)
	else:
		var seen_neighbors: Dictionary = {}
		for raw_neighbor in neighbors_value as Array:
			var neighbor_id: String = str(raw_neighbor)
			if neighbor_id == "":
				errors.append("empty_neighbor:%s" % support_id)
			elif neighbor_id == support_id:
				errors.append("self_neighbor:%s" % support_id)
			elif seen_neighbors.has(neighbor_id):
				errors.append("duplicate_neighbor:%s:%s" % [support_id, neighbor_id])
			seen_neighbors[neighbor_id] = true

	if str(definition.get("route_role", "")) not in ROUTE_ROLES:
		errors.append("invalid_route_role:%s" % support_id)
	if not definition.get("player_deploy_direction") is Vector2i:
		errors.append("invalid_player_deploy_direction:%s" % support_id)
	if not definition.get("ai_deploy_direction") is Vector2i:
		errors.append("invalid_ai_deploy_direction:%s" % support_id)
	for profile_key in ["deployment_profile_id", "capture_profile_id", "suppression_profile_id"]:
		if str(definition.get(profile_key, "")) == "":
			errors.append("missing_profile:%s:%s" % [support_id, profile_key])
	return errors
