extends RefCounted
class_name CardfrontBattlefieldInitializer

const Rules = preload("res://scripts/cardfront/CardfrontRules.gd")


static func configure_duel(battlefield) -> Dictionary:
	if battlefield == null or not is_instance_valid(battlefield):
		return {"configured": false, "reason": "missing_battlefield"}
	if not battlefield.has_method("replace_owners"):
		return {"configured": false, "reason": "missing_replace_owners"}

	var owner_grid: Array = build_duel_owner_grid(int(battlefield.grid_size))
	if battlefield.has_method("set_owner_color_override"):
		battlefield.set_owner_color_override(Rules.NEUTRAL_OWNER, Rules.NEUTRAL_COLOR, false)

	var applied: bool = bool(battlefield.replace_owners(owner_grid, true))
	if not applied:
		return {"configured": false, "reason": "owner_grid_rejected"}

	return {
		"configured": true,
		"grid_size": int(battlefield.grid_size),
		"spawn_columns": get_spawn_columns(int(battlefield.grid_size)),
	}


static func build_duel_owner_grid(grid_size: int) -> Array:
	var result: Array = []
	for x in range(grid_size):
		var col: Array = []
		for y in range(grid_size):
			col.append(duel_owner_for_cell(x, y, grid_size))
		result.append(col)
	return result


static func get_spawn_columns(grid_size: int) -> int:
	var safe_size: int = maxi(4, grid_size)
	var desired: int = int(round(float(safe_size) * 0.20))
	return clampi(desired, 2, maxi(2, (safe_size / 2) - 1))


static func duel_owner_for_cell(x: int, _y: int, grid_size: int) -> int:
	var spawn_columns: int = get_spawn_columns(grid_size)
	if x < spawn_columns:
		return Rules.PLAYER_FACTION
	if x >= grid_size - spawn_columns:
		return Rules.AI_FACTION
	return Rules.NEUTRAL_OWNER
