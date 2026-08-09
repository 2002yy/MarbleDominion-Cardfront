extends RefCounted
class_name DeploymentSupportContext

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const GridExtentScript = preload("res://scripts/GridExtent.gd")


static func core_only(map_definition: Dictionary, side: int) -> Dictionary:
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
	return {
		"side": side,
		"core_source": {
			"support_id": core_support_id,
			"candidate_cells": candidate_cells,
		},
		"support_sources": [],
	}


static func _core_support_id(side: int) -> String:
	if side == RulesScript.PLAYER_FACTION:
		return SupportIdsScript.CORE_PLAYER
	if side == RulesScript.AI_FACTION:
		return SupportIdsScript.CORE_AI
	return ""
