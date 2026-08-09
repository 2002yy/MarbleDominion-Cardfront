extends RefCounted
class_name SupportCaptureFootprints

const PROFILE_NONE: String = "none"
const PROFILE_SUPPORT_CAPTURE_V1: String = "support_capture_v1"

const OFFSETS_BY_PROFILE: Dictionary = {
	PROFILE_NONE: [],
	PROFILE_SUPPORT_CAPTURE_V1: [
		Vector2i.ZERO,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
	],
}


static func cells_for_profile(profile_id: String, anchor_cell: Vector2i, grid_extent: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in OFFSETS_BY_PROFILE.get(str(profile_id), []) as Array:
		var cell: Vector2i = anchor_cell + (offset as Vector2i)
		if cell.x < 0 or cell.y < 0 or cell.x >= grid_extent.x or cell.y >= grid_extent.y:
			continue
		result.append(cell)
	return result
