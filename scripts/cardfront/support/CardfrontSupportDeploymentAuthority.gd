extends RefCounted
class_name CardfrontSupportDeploymentAuthority

const RulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const SupportIdsScript = preload("res://scripts/cardfront/support/CardfrontSupportIds.gd")
const SupportTopologyContractScript = preload("res://scripts/cardfront/support/graph/SupportTopologyContract.gd")
const SupportTopologyValidatorScript = preload("res://scripts/cardfront/support/graph/SupportTopologyValidator.gd")
const SupportConnectivityCacheScript = preload("res://scripts/cardfront/support/graph/SupportConnectivityCache.gd")
const DeploymentSupportContextScript = preload("res://scripts/cardfront/deployment/DeploymentSupportContext.gd")

var map_definition: Dictionary = {}
var topology: Dictionary = {}
var validation_errors: Array = []
var _claim_owner_by_support: Dictionary = {}
var _operational_by_support: Dictionary = {}
var _connectivity_cache = SupportConnectivityCacheScript.new()


func setup(new_map_definition: Dictionary) -> bool:
	map_definition = new_map_definition.duplicate(true)
	topology.clear()
	validation_errors.clear()
	_claim_owner_by_support.clear()
	_operational_by_support.clear()
	_connectivity_cache = SupportConnectivityCacheScript.new()

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
	return _connectivity_cache.load_states(_claim_owner_by_support, _operational_by_support)


func set_operational(support_id: String, operational: bool) -> bool:
	var safe_id: String = str(support_id)
	if not _is_mutable_support(safe_id):
		return false
	if bool(_operational_by_support.get(safe_id, false)) == bool(operational):
		return false
	_operational_by_support[safe_id] = bool(operational)
	return _connectivity_cache.load_states(_claim_owner_by_support, _operational_by_support)


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
	return _connectivity_cache.load_states(_claim_owner_by_support, _operational_by_support)


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
