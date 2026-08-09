extends RefCounted
class_name SupportCaptureContributor

var entity_id: String = ""
var owner_id: int = -1
var capture_profile: String = ""
var capture_weight: float = 0.0
var cell: Vector2i = Vector2i(-1, -1)
var eligible: bool = false


func setup(
	new_entity_id: String,
	new_owner_id: int,
	new_capture_profile: String,
	new_capture_weight: float,
	new_cell: Vector2i,
	new_eligible: bool
) -> void:
	entity_id = str(new_entity_id)
	owner_id = int(new_owner_id)
	capture_profile = str(new_capture_profile)
	capture_weight = maxf(0.0, float(new_capture_weight))
	cell = new_cell
	eligible = bool(new_eligible)


func effective_weight() -> float:
	return capture_weight if eligible else 0.0


func snapshot() -> Dictionary:
	return {
		"entity_id": entity_id,
		"owner_id": owner_id,
		"capture_profile": capture_profile,
		"capture_weight": capture_weight,
		"cell": cell,
		"eligible": eligible,
	}
