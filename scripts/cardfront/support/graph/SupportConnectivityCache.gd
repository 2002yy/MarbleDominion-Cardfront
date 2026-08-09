extends RefCounted
class_name SupportConnectivityCache

const ResolverScript = preload("res://scripts/cardfront/support/graph/SupportConnectivityResolver.gd")

var revision: int = 0
var recompute_count: int = 0

var _topology: Dictionary = {}
var _claim_owner_by_support: Dictionary = {}
var _operational_by_support: Dictionary = {}
var _results_by_side: Dictionary = {}


func load_topology(topology: Dictionary) -> void:
	_topology = topology.duplicate(true)
	_invalidate()


func load_states(claim_owner_by_support: Dictionary, operational_by_support: Dictionary) -> bool:
	if _claim_owner_by_support == claim_owner_by_support and _operational_by_support == operational_by_support:
		return false
	_claim_owner_by_support = claim_owner_by_support.duplicate(true)
	_operational_by_support = operational_by_support.duplicate(true)
	_invalidate()
	return true


func set_claim_owner(support_id: String, claim_owner: int) -> bool:
	var safe_id: String = str(support_id)
	if int(_claim_owner_by_support.get(safe_id, -1)) == int(claim_owner):
		return false
	_claim_owner_by_support[safe_id] = int(claim_owner)
	_invalidate()
	return true


func set_operational(support_id: String, operational: bool) -> bool:
	var safe_id: String = str(support_id)
	if bool(_operational_by_support.get(safe_id, false)) == bool(operational):
		return false
	_operational_by_support[safe_id] = bool(operational)
	_invalidate()
	return true


func resolve_for_side(side: int) -> Dictionary:
	if not _results_by_side.has(side):
		var result: Dictionary = ResolverScript.resolve(
			_topology,
			side,
			_claim_owner_by_support,
			_operational_by_support
		)
		result["revision"] = revision
		_results_by_side[side] = result
		recompute_count += 1
	return (_results_by_side[side] as Dictionary).duplicate(true)


func debug_snapshot() -> Dictionary:
	return {
		"revision": revision,
		"recompute_count": recompute_count,
		"cached_sides": _results_by_side.keys().duplicate(),
	}


func _invalidate() -> void:
	revision += 1
	_results_by_side.clear()
