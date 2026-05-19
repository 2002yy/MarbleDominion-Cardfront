extends Node
class_name DeviceLayer

const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const DeviceRegistryScript = preload("res://scripts/cardfront/devices/DeviceRegistry.gd")
const DeviceInstanceScript = preload("res://scripts/cardfront/devices/DeviceInstance.gd")
const DevicePlacementRequestScript = preload("res://scripts/cardfront/devices/DevicePlacementRequest.gd")
const DevicePlacementResultScript = preload("res://scripts/cardfront/devices/DevicePlacementResult.gd")

var battlefield = null
var region_map = null
var _registry = null
var _devices_by_cell: Dictionary = {}
var _next_device_id: int = 1


func _init() -> void:
	name = "DeviceLayer"
	_registry = DeviceRegistryScript.new()


func setup(new_battlefield, new_region_map) -> void:
	battlefield = new_battlefield
	region_map = new_region_map
	_devices_by_cell.clear()
	_next_device_id = 1
	set_process(false)


func place(req):
	if battlefield == null:
		return DevicePlacementResultScript.fail(DevicePlacementResultScript.REASON_MISSING_SYSTEM)

	var device_type: String = str(req.device_type)
	var owner_id: int = int(req.owner_id)
	var cell: Vector2i = req.target_cell

	if not _registry.is_valid_type(device_type):
		return DevicePlacementResultScript.fail(DevicePlacementResultScript.REASON_UNKNOWN_TYPE)

	if not _is_inside(cell):
		return DevicePlacementResultScript.fail(DevicePlacementResultScript.REASON_OUTSIDE_MAP)

	if not DeploymentRulesScript.is_owned_cell(battlefield, cell, owner_id):
		return DevicePlacementResultScript.fail(DevicePlacementResultScript.REASON_NOT_OWNED_CELL)

	if _devices_by_cell.has(cell):
		return DevicePlacementResultScript.fail(DevicePlacementResultScript.REASON_DUPLICATE_CELL)

	var max_for_type: int = _registry.get_max_per_owner(device_type)
	if max_for_type > 0 and _count_owner_type(owner_id, device_type) >= max_for_type:
		return DevicePlacementResultScript.fail(DevicePlacementResultScript.REASON_MAX_PER_OWNER_TYPE)

	var lifetime: float = _registry.get_default_lifetime(device_type)
	var instance = DeviceInstanceScript.new()
	instance.device_id = _next_device_id
	_next_device_id += 1
	instance.device_type = device_type
	instance.owner_id = owner_id
	instance.cell = cell
	instance.remaining_lifetime = lifetime
	instance.active = true

	_devices_by_cell[cell] = instance

	if not is_processing():
		set_process(true)

	return DevicePlacementResultScript.ok(instance)


func remove_at(cell: Vector2i) -> bool:
	if not _devices_by_cell.has(cell):
		return false
	_devices_by_cell.erase(cell)
	if _devices_by_cell.is_empty():
		set_process(false)
	return true


func get_device_at(cell: Vector2i):
	return _devices_by_cell.get(cell, null)


func get_devices_by_owner(owner_id: int) -> Array:
	var result = []
	for instance in _devices_by_cell.values():
		if int(instance.owner_id) == int(owner_id) and instance.active:
			result.append(instance)
	return result


func get_devices_by_owner_type(owner_id: int, device_type: String) -> Array:
	var result = []
	for instance in _devices_by_cell.values():
		if int(instance.owner_id) == int(owner_id) and str(instance.device_type) == str(device_type) and instance.active:
			result.append(instance)
	return result


func get_all_active_devices() -> Array:
	var result = []
	for instance in _devices_by_cell.values():
		if instance.active:
			result.append(instance)
	return result


func tick(delta: float) -> void:
	var expired_cells: Array = []
	for cell in _devices_by_cell.keys():
		var instance = _devices_by_cell[cell]
		if not instance.active:
			continue
		instance.remaining_lifetime = maxf(0.0, instance.remaining_lifetime - maxf(0.0, delta))
		if instance.remaining_lifetime <= 0.0:
			instance.active = false
			expired_cells.append(cell)

	for cell in expired_cells:
		_devices_by_cell.erase(cell)

	if _devices_by_cell.is_empty():
		set_process(false)


func _process(delta: float) -> void:
	tick(delta)


func snapshot() -> Dictionary:
	var device_list: Array = []
	for cell in _devices_by_cell.keys():
		var instance = _devices_by_cell[cell]
		device_list.append(instance.snapshot())
	return {
		"next_device_id": _next_device_id,
		"devices": device_list,
	}


func restore(data: Dictionary) -> void:
	_devices_by_cell.clear()
	if data.is_empty():
		return
	_next_device_id = int(data.get("next_device_id", 1))
	var device_list: Array = data.get("devices", [])
	for raw in device_list:
		var d: Dictionary = raw
		var instance = DeviceInstanceScript.new()
		instance.device_id = int(d.get("device_id", 0))
		instance.device_type = str(d.get("device_type", ""))
		instance.owner_id = int(d.get("owner_id", 0))
		instance.cell = Vector2i(int(d.get("cell_x", 0)), int(d.get("cell_y", 0)))
		instance.remaining_lifetime = float(d.get("remaining_lifetime", 0.0))
		instance.active = bool(d.get("active", true))
		_devices_by_cell[instance.cell] = instance

	if not _devices_by_cell.is_empty():
		set_process(true)


func _count_owner_type(owner_id: int, device_type: String) -> int:
	return get_devices_by_owner_type(owner_id, device_type).size()


func _is_inside(cell: Vector2i) -> bool:
	if battlefield == null:
		return false
	if battlefield.has_method("is_inside"):
		return battlefield.is_inside(cell)
	return false
