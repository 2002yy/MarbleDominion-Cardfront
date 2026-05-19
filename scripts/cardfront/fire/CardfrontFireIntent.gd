extends RefCounted
class_name CardfrontFireIntent

var owner_id: int = 0
var target_region_id: int = -1
var target_cell: Vector2i = Vector2i(-1, -1)
var angle: float = 0.0
var shot_count: int = 1
var spread: float = 0.0
var reason: String = ""


func snapshot() -> Dictionary:
	return {
		"owner_id": owner_id,
		"target_region_id": target_region_id,
		"target_cell": target_cell,
		"angle": angle,
		"shot_count": shot_count,
		"spread": spread,
		"reason": reason,
	}
