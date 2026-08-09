extends RefCounted
class_name DeploymentSupportContext

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const GridExtentScript = preload("res://scripts/GridExtent.gd")


static func core_only(
	map_definition: Dictionary,
	side: int,
	deployment_revision: int = 0
) -> Dictionary:
	var extent: Vector2i = GridExtentScript.from_config(map_definition, Vector2i.ZERO)
	var core_support_id: String = _core_support_id(side)
	var candidate_cells: Array[Vector2i] = []
	for raw_zone in map_definition.get("spawn_zones", []) as Array:
		if not raw_zone is Dictionary or int((raw_zone as Dictionary).get("owner", -1)) != side:
			continue
		var zone: Dictionary = raw_zone as Dictionary
		var x0: int = clampi(int(zone.get("x0", 0)), 0, maxi(0, extent.x - 1))
		var x1: int = clampi(int(zone.get("x1", extent.x - 1)), 0, maxi(0, extent.x - 1))
		var y0: int = clampi(int(zone.get("y0", 0)), 0, maxi(0, extent.y - 1))
		var y1: int = clampi(int(zone.get("y1", extent.y - 1)), 0, maxi(0, extent.y - 1))
		for x in range(mini(x0, x1), maxi(x0, x1) + 1):
			for y in range(mini(y0, y1), maxi(y0, y1) + 1):
				candidate_cells.append(Vector2i(x, y))
	var known_support_ids: Array[String] = []
	for definition in map_definition.get("deployment_supports", []) as Array:
		known_support_ids.append(str((definition as Dictionary).get("support_id", "")))
	known_support_ids.sort()
	return {
		"side": side,
		"deployment_revision": maxi(0, int(deployment_revision)),
		"core_source": {
			"support_id": core_support_id,
			"candidate_cells": candidate_cells,
		},
		"support_sources": [],
		"known_support_ids": known_support_ids,
		"online_support_ids": [],
	}


static func with_online_supports(
	map_definition: Dictionary,
	side: int,
	online_support_ids: Array,
	support_depth_by_id: Dictionary = {},
	deployment_revision: int = 0
) -> Dictionary:
	var context: Dictionary = core_only(map_definition, side, deployment_revision)
	var requested_online: Dictionary = {}
	for support_id in online_support_ids:
		requested_online[str(support_id)] = true
	var sources: Array = []
	for raw_definition in map_definition.get("deployment_supports", []) as Array:
		var definition: Dictionary = raw_definition as Dictionary
		var support_id: String = str(definition.get("support_id", ""))
		if bool(definition.get("is_core", false)) or not requested_online.has(support_id):
			continue
		var direction_key: String = "player_deploy_direction" if side == RulesScript.PLAYER_FACTION else "ai_deploy_direction"
		sources.append({
			"support_id": support_id,
			"anchor_cell": definition.get("anchor_cell", Vector2i.ZERO),
			"forward": definition.get(direction_key, Vector2i.ZERO),
			"profile_id": str(definition.get("deployment_profile_id", "")),
			"route_role": str(definition.get("route_role", "")),
			"graph_depth": maxi(0, int(support_depth_by_id.get(support_id, 0))),
		})
	sources.sort_custom(func(left, right): return str(left.support_id) < str(right.support_id))
	context["support_sources"] = sources
	context["online_support_ids"] = sources.map(func(source): return str(source.support_id))
	return context


static func _core_support_id(side: int) -> String:
	if side == RulesScript.PLAYER_FACTION:
		return SupportIdsScript.CORE_PLAYER
	if side == RulesScript.AI_FACTION:
		return SupportIdsScript.CORE_AI
	return ""
