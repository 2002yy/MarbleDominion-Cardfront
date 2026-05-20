extends RefCounted

var device_type: String = ""
var owner_id: int = 0
var target_cell: Vector2i = Vector2i.ZERO


static func make(p_device_type: String, p_owner_id: int, p_target_cell: Vector2i):
	var DevicePlacementRequestScript = load("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
	var req = DevicePlacementRequestScript.new()
	req.device_type = str(p_device_type)
	req.owner_id = int(p_owner_id)
	req.target_cell = p_target_cell
	return req
