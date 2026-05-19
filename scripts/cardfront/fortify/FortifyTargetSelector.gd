extends RefCounted
class_name FortifyTargetSelector

const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")


static func select_owned_border_cells(region_map, battlefield, owner_id: int, max_cells: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if battlefield == null:
		return result
	var bf_grid_size: int = int(battlefield.grid_size)
	for x in range(bf_grid_size):
		for y in range(bf_grid_size):
			var cell := Vector2i(x, y)
			if not DeploymentRulesScript.is_owned_border(region_map, battlefield, cell, owner_id):
				continue
			result.append(cell)
			if result.size() >= max_cells:
				return result
	return result
