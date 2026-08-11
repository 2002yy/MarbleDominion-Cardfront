extends RefCounted
class_name SupportPresentationSnapshot

var support_id: String = ""
var anchor_cell: Vector2i = Vector2i.ZERO
var claim_owner: int = -1
var operational: bool = false
var network_connected: bool = false
var capture_side: int = -1
var capture_progress_normalized: float = 0.0
var contested: bool = false
var derived_view_state: String = "DISABLED_NEUTRAL"


func to_dictionary() -> Dictionary:
	return {
		"support_id": support_id,
		"anchor_cell": anchor_cell,
		"claim_owner": claim_owner,
		"operational": operational,
		"network_connected": network_connected,
		"capture_side": capture_side,
		"capture_progress_normalized": capture_progress_normalized,
		"contested": contested,
		"derived_view_state": derived_view_state,
	}
