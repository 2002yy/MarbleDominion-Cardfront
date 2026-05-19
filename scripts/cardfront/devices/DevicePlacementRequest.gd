extends RefCounted

var device_type: String = ""
var owner_id: int = 0
var target_cell: Vector2i = Vector2i.ZERO


static func make(device_type: String, owner_id: int, target_cell: Vector2i):
	var DevicePlacementRequestScript = load("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
	var req = DevicePlacementRequestScript.new()
	req.device_type = str(device_type)
	req.owner_id = int(owner_id)
	req.target_cell = target_cell
	return req
