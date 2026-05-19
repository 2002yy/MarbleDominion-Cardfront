extends Node
class_name DurablePioneerBeaconEffectSystem

const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")
const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")

const TICK_INTERVAL: float = 2.0
const PER_TICK_CAP: int = 1

const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0),
	Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(-1, 1),
]

var device_layer = null
var battlefield = null
var region_map = null
var vfx_layer = null

var _elapsed: float = 0.0


func _init() -> void:
	name = "DurablePioneerBeaconEffectSystem"


func setup(new_device_layer, new_battlefield, new_region_map, new_vfx_layer = null) -> void:
	device_layer = new_device_layer
	battlefield = new_battlefield
	region_map = new_region_map
	vfx_layer = new_vfx_layer
	device_layer = new_device_layer
	battlefield = new_battlefield
	region_map = new_region_map
	_elapsed = 0.0
	set_process(true)


func tick(_delta: float) -> void:
	if device_layer == null or battlefield == null:
		return

	var converted: int = 0
	for owner_id in [CardfrontRulesScript.PLAYER_FACTION, CardfrontRulesScript.AI_FACTION]:
		if converted >= PER_TICK_CAP:
			return
		var devices = device_layer.get_devices_by_owner_type(int(owner_id), DeviceTypeScript.PIONEER_BEACON)
		if devices.is_empty():
			continue
		converted += _convert_for_owner(int(owner_id), devices, PER_TICK_CAP - converted)


func _convert_for_owner(owner_id: int, devices: Array, max_convert: int) -> int:
	var converted: int = 0
	for device_instance in devices:
		if converted >= max_convert:
			return converted
		if not device_instance.active:
			continue
		var device_cell: Vector2i = device_instance.cell
		for offset in NEIGHBOR_OFFSETS:
			if converted >= max_convert:
				return converted
			var cell: Vector2i = device_cell + offset
			if not _is_inside(cell):
				continue
			if DeploymentRulesScript.get_owner_at(battlefield, cell) != CardfrontRulesScript.NEUTRAL_OWNER:
				continue
			var result: String = str(battlefield.apply_owner_change(cell, owner_id, "durable_pioneer_beacon"))
			if result == "OWNER_CHANGED":
				converted += 1
				if vfx_layer != null and is_instance_valid(vfx_layer) and vfx_layer.has_method("play_energy_ripple"):
					vfx_layer.play_energy_ripple(cell)
	return converted


func _is_inside(cell: Vector2i) -> bool:
	if battlefield == null:
		return false
	return battlefield.is_inside(cell)


func _process(delta: float) -> void:
	_elapsed += maxf(0.0, delta)
	while _elapsed >= TICK_INTERVAL:
		_elapsed -= TICK_INTERVAL
		tick(TICK_INTERVAL)
