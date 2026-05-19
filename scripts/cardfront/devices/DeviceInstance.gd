extends RefCounted

var device_id: int = 0
var device_type: String = ""
var owner_id: int = 0
var cell: Vector2i = Vector2i.ZERO
var remaining_lifetime: float = 0.0
var active: bool = true

func snapshot() -> Dictionary:
	return {
		"device_id": device_id,
		"device_type": device_type,
		"owner_id": owner_id,
		"cell_x": cell.x,
		"cell_y": cell.y,
		"remaining_lifetime": remaining_lifetime,
		"active": active,
	}
