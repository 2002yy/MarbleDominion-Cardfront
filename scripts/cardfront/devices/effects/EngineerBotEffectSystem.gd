extends Node
class_name EngineerBotEffectSystem

const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

const TICK_INTERVAL: float = 1.0
const REPAIR_RADIUS_CELLS: int = 3
const PER_TICK_CAP: int = 1

var device_layer = null
var fortify_layer = null
var battlefield = null
var region_map = null

var _elapsed: float = 0.0


func _init() -> void:
	name = "EngineerBotEffectSystem"


func setup(new_device_layer, new_fortify_layer, new_battlefield, new_region_map) -> void:
	device_layer = new_device_layer
	fortify_layer = new_fortify_layer
	battlefield = new_battlefield
	region_map = new_region_map
	_elapsed = 0.0
	set_process(true)


func tick(_delta: float) -> void:
	if device_layer == null or fortify_layer == null or battlefield == null:
		return

	for owner_id in _known_owner_ids():
		var devices = device_layer.get_devices_by_owner_type(int(owner_id), DeviceTypeScript.ENGINEER_BOT)
		if devices.is_empty():
			continue
		_repair_for_owner(int(owner_id), devices)


func _known_owner_ids() -> Array[int]:
	return [CardfrontRulesScript.PLAYER_FACTION, CardfrontRulesScript.AI_FACTION]


func _repair_for_owner(owner_id: int, devices: Array) -> void:
	var repaired_this_tick: int = 0
	var visited_cells: Dictionary = {}

	for device_instance in devices:
		if repaired_this_tick >= PER_TICK_CAP:
			return
		if not device_instance.active:
			continue
		var device_cell: Vector2i = device_instance.cell
		for dx in range(-REPAIR_RADIUS_CELLS, REPAIR_RADIUS_CELLS + 1):
			if repaired_this_tick >= PER_TICK_CAP:
				return
			for dy in range(-REPAIR_RADIUS_CELLS, REPAIR_RADIUS_CELLS + 1):
				if repaired_this_tick >= PER_TICK_CAP:
					return
				var cell := Vector2i(device_cell.x + dx, device_cell.y + dy)
				if not _is_inside(cell):
					continue
				if visited_cells.has(cell):
					continue
				visited_cells[cell] = true
				if not _can_repair(cell, owner_id):
					continue
				fortify_layer.add_fortify_stack(cell, 1)
				repaired_this_tick += 1
				break
		if repaired_this_tick >= PER_TICK_CAP:
			return


func _can_repair(cell: Vector2i, owner_id: int) -> bool:
	if fortify_layer.get_fortify_stack(cell) >= FortifyRulesScript.MAX_FORTIFY_STACKS:
		return false
	return DeploymentRulesScript.is_owned_border(region_map, battlefield, cell, owner_id)


func _is_inside(cell: Vector2i) -> bool:
	if battlefield == null:
		return false
	return battlefield.is_inside(cell)


func _process(delta: float) -> void:
	_elapsed += maxf(0.0, delta)
	while _elapsed >= TICK_INTERVAL:
		_elapsed -= TICK_INTERVAL
		tick(TICK_INTERVAL)
