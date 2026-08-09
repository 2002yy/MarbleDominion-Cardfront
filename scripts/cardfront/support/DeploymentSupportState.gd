extends RefCounted
class_name DeploymentSupportState

const STATUS_ONLINE: String = "online"
const STATUS_CAPTURED_OFFLINE: String = "captured_offline"
const STATUS_DISABLED: String = "disabled"
const STATUS_NOT_OWNED: String = "not_owned"

var support_id: String = ""
var claim_owner: int = -1
var operational: bool = false
var capture_side: int = -1
var capture_progress: float = 0.0
var network_connected: bool = false
var contested: bool = false


func setup(
	new_support_id: String,
	new_claim_owner: int,
	new_operational: bool = false,
	new_capture_side: int = -1,
	new_capture_progress: float = 0.0
) -> void:
	support_id = str(new_support_id)
	claim_owner = int(new_claim_owner)
	operational = bool(new_operational)
	capture_side = int(new_capture_side)
	capture_progress = clampf(float(new_capture_progress), 0.0, 1.0)
	# Connectivity and contesting are derived runtime observations. They are
	# intentionally rebuilt by their future owners instead of restored here.
	network_connected = false
	contested = false


func set_claim_owner(new_owner: int) -> void:
	claim_owner = int(new_owner)


func set_operational(new_operational: bool) -> void:
	operational = bool(new_operational)


func set_network_connected(new_connected: bool) -> void:
	network_connected = bool(new_connected)


func set_contested(new_contested: bool) -> void:
	contested = bool(new_contested)


func is_online_for(side: int) -> bool:
	return claim_owner == int(side) and operational and network_connected


func can_contribute_deployment_for(side: int) -> bool:
	return is_online_for(side)


func derived_gameplay_status_for(side: int) -> String:
	if claim_owner != int(side):
		return STATUS_NOT_OWNED
	if not operational:
		return STATUS_DISABLED
	if not network_connected:
		return STATUS_CAPTURED_OFFLINE
	return STATUS_ONLINE


func snapshot() -> Dictionary:
	return {
		"support_id": support_id,
		"claim_owner": claim_owner,
		"operational": operational,
		"capture_side": capture_side,
		"capture_progress": capture_progress,
	}


func restore_persistent(data: Dictionary) -> void:
	setup(
		str(data.get("support_id", "")),
		int(data.get("claim_owner", -1)),
		bool(data.get("operational", false)),
		int(data.get("capture_side", -1)),
		float(data.get("capture_progress", 0.0))
	)
