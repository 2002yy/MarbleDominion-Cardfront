extends RefCounted

var success: bool = false
var reason: String = ""
var instance = null


const REASON_SUCCESS: String = "success"
const REASON_OUTSIDE_MAP: String = "outside_map"
const REASON_NOT_OWNED_CELL: String = "not_owned_cell"
const REASON_DUPLICATE_CELL: String = "duplicate_cell"
const REASON_MAX_PER_OWNER_TYPE: String = "max_per_owner_type"
const REASON_MISSING_SYSTEM: String = "missing_system"
const REASON_UNKNOWN_TYPE: String = "unknown_type"


static func ok(instance):
	var DevicePlacementResultScript = load("res://scripts/cardfront/devices/DevicePlacementResult.gd")
	var r = DevicePlacementResultScript.new()
	r.success = true
	r.reason = REASON_SUCCESS
	r.instance = instance
	return r


static func fail(reason: String):
	var DevicePlacementResultScript = load("res://scripts/cardfront/devices/DevicePlacementResult.gd")
	var r = DevicePlacementResultScript.new()
	r.success = false
	r.reason = str(reason)
	r.instance = null
	return r
