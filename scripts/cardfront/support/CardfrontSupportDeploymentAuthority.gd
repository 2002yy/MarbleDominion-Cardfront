extends RefCounted
class_name CardfrontSupportDeploymentAuthority

signal presentation_snapshots_changed(snapshots)

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SupportTopologyContractScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")
const SupportTopologyValidatorScript = preload("res://scripts/cardfront/support/graph/SupportTopologyValidator.gd")
const SupportConnectivityCacheScript = preload("res://scripts/cardfront/support/graph/SupportConnectivityCache.gd")
const DeploymentSupportContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")
const PresentationSnapshotBuilderScript = preload(
	"res://scripts/cardfront/support/presentation/SupportPresentationSnapshotBuilder.gd"
)

var map_definition: Dictionary = {}
var topology: Dictionary = {}
var validation_errors: Array = []
var _claim_owner_by_support: Dictionary = {}
var _operational_by_support: Dictionary = {}
var _connectivity_cache = SupportConnectivityCacheScript.new()
var _presentation_state_provider: Callable


func setup(new_map_definition: Dictionary) -> bool:
	map_definition = new_map_definition.duplicate(true)
	topology.clear()
	validation_errors.clear()
	_claim_owner_by_support.clear()
	_operational_by_support.clear()
	_connectivity_cache = SupportConnectivityCacheScript.new()
	_presentation_state_provider = Callable()

	var definitions = map_definition.get("deployment_supports", [])
	if not definitions is Array or (definitions as Array).is_empty():
		validation_errors = ["missing_deployment_supports"]
		return false

	topology = SupportTopologyContractScript.from_support_definitions(definitions as Array)
	validation_errors = SupportTopologyValidatorScript.validate(topology)
	if not validation_errors.is_empty():
		return false

	for raw_node in topology.get("nodes", []) as Array:
		var node: Dictionary = raw_node as Dictionary
		var support_id: String = str(node.get("support_id", ""))
		if support_id == SupportIdsScript.CORE_PLAYER:
			_claim_owner_by_support[support_id] = RulesScript.PLAYER_FACTION
			_operational_by_support[support_id] = true
		elif support_id == SupportIdsScript.CORE_AI:
			_claim_owner_by_support[support_id] = RulesScript.AI_FACTION
			_operational_by_support[support_id] = true
		else:
			_claim_owner_by_support[support_id] = RulesScript.NEUTRAL_OWNER
			_operational_by_support[support_id] = false

	_connectivity_cache.load_topology(topology)
	_connectivity_cache.load_states(_claim_owner_by_support, _operational_by_support)
	return true


func deployment_context(side: int) -> Dictionary:
	if topology.is_empty() or not validation_errors.is_empty():
		return {}
	var connectivity: Dictionary = _connectivity_cache.resolve_for_side(side)
	if not bool(connectivity.get("valid", false)):
		return {}
	return DeploymentSupportContextScript.with_online_supports(
		map_definition,
		side,
		connectivity.get("connected_support_ids", []) as Array,
		_depth_by_support(connectivity),
		int(connectivity.get("revision", _connectivity_cache.revision))
	)


func deployment_revision(_side: int = -1) -> int:
	return _connectivity_cache.revision


func set_claim_owner(support_id: String, claim_owner: int) -> bool:
	var safe_id: String = str(support_id)
	if not _is_mutable_support(safe_id):
		return false
	if int(_claim_owner_by_support.get(safe_id, RulesScript.NEUTRAL_OWNER)) == int(claim_owner):
		return false
	_claim_owner_by_support[safe_id] = int(claim_owner)
	var changed: bool = _connectivity_cache.load_states(_claim_owner_by_support, _operational_by_support)
	_emit_presentation_snapshots()
	return changed


func set_operational(support_id: String, operational: bool) -> bool:
	var safe_id: String = str(support_id)
	if not _is_mutable_support(safe_id):
		return false
	if bool(_operational_by_support.get(safe_id, false)) == bool(operational):
		return false
	_operational_by_support[safe_id] = bool(operational)
	var changed: bool = _connectivity_cache.load_states(_claim_owner_by_support, _operational_by_support)
	_emit_presentation_snapshots()
	return changed


func set_support_state(support_id: String, claim_owner: int, operational: bool) -> bool:
	var safe_id: String = str(support_id)
	if not _is_mutable_support(safe_id):
		return false
	var changed: bool = false
	if int(_claim_owner_by_support.get(safe_id, RulesScript.NEUTRAL_OWNER)) != int(claim_owner):
		_claim_owner_by_support[safe_id] = int(claim_owner)
		changed = true
	if bool(_operational_by_support.get(safe_id, false)) != bool(operational):
		_operational_by_support[safe_id] = bool(operational)
		changed = true
	if not changed:
		return false
	var cache_changed: bool = _connectivity_cache.load_states(_claim_owner_by_support, _operational_by_support)
	_emit_presentation_snapshots()
	return cache_changed


func presentation_snapshots() -> Array:
	var definitions_by_id: Dictionary = {}
	for raw_definition in map_definition.get("deployment_supports", []) as Array:
		var definition: Dictionary = raw_definition as Dictionary
		definitions_by_id[str(definition.get("support_id", ""))] = definition
	var connected_by_side: Dictionary = {}
	for side in RulesScript.get_duel_factions():
		var resolved: Dictionary = _connectivity_cache.resolve_for_side(int(side))
		connected_by_side[int(side)] = resolved.get("connected_support_ids", []) as Array

	var result: Array = []
	var ordered_ids: Array = definitions_by_id.keys()
	ordered_ids.sort()
	for raw_support_id in ordered_ids:
		var support_id: String = str(raw_support_id)
		var claim_owner: int = int(_claim_owner_by_support.get(support_id, RulesScript.NEUTRAL_OWNER))
		var connected: bool = (
			claim_owner != RulesScript.NEUTRAL_OWNER
			and support_id in (connected_by_side.get(claim_owner, []) as Array)
		)
		var public_state: Dictionary = {
			"support_id": support_id,
			"claim_owner": claim_owner,
			"operational": bool(_operational_by_support.get(support_id, false)),
			"network_connected": connected,
			"capture_side": RulesScript.NEUTRAL_OWNER,
			"capture_progress": 0.0,
			"contested": false,
		}
		if _presentation_state_provider.is_valid():
			var provided = _presentation_state_provider.call(support_id)
			if provided is Dictionary and not (provided as Dictionary).is_empty():
				public_state.merge(provided as Dictionary, true)
				public_state["network_connected"] = connected
		var snapshot = PresentationSnapshotBuilderScript.build(
			definitions_by_id[support_id] as Dictionary,
			public_state,
			RulesScript.NEUTRAL_OWNER
		)
		if snapshot != null:
			result.append(snapshot.to_dictionary())
	return result


func configure_presentation_state_provider(provider: Callable) -> void:
	_presentation_state_provider = provider
	_emit_presentation_snapshots()


func notify_presentation_state_changed() -> void:
	_emit_presentation_snapshots()


func _emit_presentation_snapshots() -> void:
	presentation_snapshots_changed.emit(presentation_snapshots())


func debug_snapshot() -> Dictionary:
	return {
		"map_id": str(map_definition.get("id", "")),
		"topology": topology.duplicate(true),
		"validation_errors": validation_errors.duplicate(),
		"claim_owner_by_support": _claim_owner_by_support.duplicate(true),
		"operational_by_support": _operational_by_support.duplicate(true),
		"cache": _connectivity_cache.debug_snapshot(),
	}


func _is_mutable_support(support_id: String) -> bool:
	return support_id != "" and _claim_owner_by_support.has(support_id) and not SupportIdsScript.is_core_id(support_id)


func _depth_by_support(connectivity: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var parents: Dictionary = connectivity.get("reachable_parent", {}) as Dictionary
	var connected: Array = connectivity.get("connected_support_ids", []) as Array
	for raw_support_id in connected:
		var support_id: String = str(raw_support_id)
		var depth: int = 0
		var cursor: String = support_id
		var seen: Dictionary = {}
		while parents.has(cursor) and not seen.has(cursor):
			seen[cursor] = true
			cursor = str(parents[cursor])
			depth += 1
		result[support_id] = depth
	return result
