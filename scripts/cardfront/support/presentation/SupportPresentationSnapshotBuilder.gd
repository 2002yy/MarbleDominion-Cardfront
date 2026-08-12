extends RefCounted
class_name SupportPresentationSnapshotBuilder

const SnapshotScript = preload(
	"res://scripts/cardfront/support/presentation/SupportPresentationSnapshot.gd"
)
const ViewStateScript = preload(
	"res://scripts/cardfront/support/presentation/SupportPresentationViewState.gd"
)


static func build(
	definition: Dictionary,
	public_state: Dictionary,
	neutral_owner: int = -1
):
	var definition_id: String = str(definition.get("support_id", ""))
	var state_id: String = str(public_state.get("support_id", ""))
	if definition_id == "" or state_id == "" or definition_id != state_id:
		return null
	var anchor_value = definition.get("anchor_cell", null)
	if not anchor_value is Vector2i:
		return null

	var result = SnapshotScript.new()
	result.support_id = definition_id
	result.anchor_cell = anchor_value as Vector2i
	result.claim_owner = int(public_state.get("claim_owner", neutral_owner))
	result.operational = bool(public_state.get("operational", false))
	result.network_connected = bool(public_state.get("network_connected", false))
	result.capture_side = int(public_state.get("capture_side", neutral_owner))
	result.capture_progress_normalized = clampf(
		float(public_state.get("capture_progress", 0.0)),
		0.0,
		1.0
	)
	result.contested = bool(public_state.get("contested", false))
	result.derived_view_state = ViewStateScript.derive(
		result.claim_owner,
		result.operational,
		result.network_connected,
		result.capture_side,
		result.capture_progress_normalized,
		result.contested,
		neutral_owner
	)
	return result
