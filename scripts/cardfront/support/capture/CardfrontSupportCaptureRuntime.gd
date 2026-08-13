extends Node
class_name CardfrontSupportCaptureRuntime

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const StateScript = preload("res://scripts/cardfront/support/DeploymentSupportState.gd")
const FootprintsScript = preload("res://scripts/cardfront/support/capture/SupportCaptureFootprints.gd")
const SuppressionFootprintsScript = preload("res://scripts/cardfront/support/capture/SupportSuppressionFootprints.gd")
const OccupancyScript = preload("res://scripts/cardfront/support/capture/SupportCaptureOccupancyAdapter.gd")
const AggregatorScript = preload("res://scripts/cardfront/support/capture/SupportCaptureAggregator.gd")
const MachineScript = preload("res://scripts/cardfront/support/capture/SupportCaptureStateMachine.gd")
const CodecScript = preload("res://scripts/cardfront/support/SupportStateSnapshotCodec.gd")

const SUPPRESS_OFF_THRESHOLD: float = 0.40
const RECOVER_ON_THRESHOLD: float = 0.60

var battlefield = null
var entity_registry = null
var support_authority = null
var map_definition: Dictionary = {}
var states_by_support_id: Dictionary = {}
var _capture_idle_seconds_by_support: Dictionary = {}


func setup(new_battlefield, new_entity_registry, new_support_authority, new_map_definition: Dictionary) -> bool:
	if new_battlefield == null or not is_instance_valid(new_battlefield):
		return false
	if new_entity_registry == null or new_support_authority == null:
		return false
	battlefield = new_battlefield
	entity_registry = new_entity_registry
	support_authority = new_support_authority
	map_definition = new_map_definition.duplicate(true)
	states_by_support_id.clear()
	_capture_idle_seconds_by_support.clear()
	for raw_definition in map_definition.get("deployment_supports", []) as Array:
		var definition: Dictionary = raw_definition as Dictionary
		var support_id: String = str(definition.get("support_id", ""))
		if support_id == "" or SupportIdsScript.is_core_id(support_id):
			continue
		var state = StateScript.new()
		state.setup(support_id, RulesScript.NEUTRAL_OWNER, false)
		states_by_support_id[support_id] = state
		_capture_idle_seconds_by_support[support_id] = 0.0
	set_process(true)
	return not states_by_support_id.is_empty()


func _process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if battlefield == null or support_authority == null:
		return
	var connectivity_changed: bool = false
	var presentation_changed: bool = false
	for raw_definition in map_definition.get("deployment_supports", []) as Array:
		var definition: Dictionary = raw_definition as Dictionary
		var support_id: String = str(definition.get("support_id", ""))
		if not states_by_support_id.has(support_id):
			continue
		var state = states_by_support_id[support_id]
		var footprint: Array[Vector2i] = FootprintsScript.cells_for_profile(
			str(definition.get("capture_profile_id", FootprintsScript.PROFILE_NONE)),
			definition.get("anchor_cell", Vector2i.ZERO) as Vector2i,
			battlefield.grid_extent
		)
		if footprint.is_empty():
			continue
		var before: Dictionary = public_state(support_id)
		var suppression_footprint: Array[Vector2i] = SuppressionFootprintsScript.cells_for_profile(
			str(definition.get("suppression_profile_id", SuppressionFootprintsScript.PROFILE_NONE)),
			definition.get("anchor_cell", Vector2i.ZERO) as Vector2i,
			battlefield.grid_extent
		)
		_apply_suppression(state, suppression_footprint)
		var contributors: Array = OccupancyScript.extract(entity_registry, footprint)
		var player_power: float = _power_for(contributors, RulesScript.PLAYER_FACTION)
		var ai_power: float = _power_for(contributors, RulesScript.AI_FACTION)
		var machine_input: Dictionary = state.snapshot()
		machine_input["capture_idle_seconds"] = float(_capture_idle_seconds_by_support.get(support_id, 0.0))
		var next: Dictionary = MachineScript.step(machine_input, player_power, ai_power, delta)
		_capture_idle_seconds_by_support[support_id] = float(next.capture_idle_seconds)
		state.setup(
			support_id,
			int(next.claim_owner),
			bool(next.operational),
			int(next.capture_side),
			float(next.capture_progress)
		)
		state.set_contested(bool(next.contested))
		if bool(next.capture_completed):
			_apply_suppression(state, suppression_footprint)
		connectivity_changed = support_authority.set_support_state(
			support_id,
			state.claim_owner,
			state.operational
		) or connectivity_changed
		presentation_changed = public_state(support_id) != before or presentation_changed
	_refresh_derived_connectivity()
	if presentation_changed and not connectivity_changed:
		support_authority.notify_presentation_state_changed()


func snapshot_states() -> Dictionary:
	return CodecScript.encode(states_by_support_id)


func restore_states(data: Dictionary) -> void:
	var decoded: Dictionary = CodecScript.decode(data)
	for support_id in decoded.keys():
		if states_by_support_id.has(str(support_id)):
			states_by_support_id[str(support_id)] = decoded[support_id]
	for support_id in states_by_support_id.keys():
		var state = states_by_support_id[support_id]
		_capture_idle_seconds_by_support[support_id] = 0.0
		support_authority.set_support_state(str(support_id), int(state.claim_owner), bool(state.operational))
	_refresh_derived_connectivity()
	support_authority.notify_presentation_state_changed()


func public_state(support_id: String) -> Dictionary:
	var state = states_by_support_id.get(str(support_id), null)
	if state == null:
		return {}
	return {
		"support_id": state.support_id,
		"claim_owner": state.claim_owner,
		"operational": state.operational,
		"network_connected": state.network_connected,
		"capture_side": state.capture_side,
		"capture_progress": state.capture_progress,
		"contested": state.contested,
	}


func _apply_suppression(state, footprint: Array[Vector2i]) -> void:
	if int(state.claim_owner) == RulesScript.NEUTRAL_OWNER:
		state.set_operational(false)
		return
	if footprint.is_empty():
		state.set_operational(false)
		return
	var owned: int = 0
	for cell in footprint:
		if int(battlefield.owners[cell.x][cell.y]) == int(state.claim_owner):
			owned += 1
	var share: float = float(owned) / float(footprint.size())
	if state.operational and share < SUPPRESS_OFF_THRESHOLD:
		state.set_operational(false)
	elif not state.operational and share >= RECOVER_ON_THRESHOLD:
		state.set_operational(true)


func _power_for(contributors: Array, owner_id: int) -> float:
	var owned: Array = contributors.filter(func(value): return int(value.owner_id) == owner_id)
	return float(AggregatorScript.aggregate(owned).resolved_capture_power)


func _refresh_derived_connectivity() -> void:
	for side in RulesScript.get_duel_factions():
		var context: Dictionary = support_authority.deployment_context(int(side))
		var online: Array = context.get("online_support_ids", []) as Array
		for support_id in states_by_support_id.keys():
			var state = states_by_support_id[support_id]
			if int(state.claim_owner) == int(side):
				state.set_network_connected(str(support_id) in online)
