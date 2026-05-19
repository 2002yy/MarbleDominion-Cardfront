extends Node
class_name AbsorberCoreEffectSystem

const DeviceTypeScript = preload("res://scripts/cardfront/devices/DeviceType.gd")

const TICK_INTERVAL: float = 0.5
const ABSORB_RADIUS_CELLS: int = 3
const PER_TICK_CAP: int = 1
const MAX_PER_SECOND: int = 3

var device_layer = null
var bullet_pool = null
var resource_states: Dictionary = {}
var battlefield = null
var vfx_layer = null

var _elapsed: float = 0.0
var _absorbed_this_second: int = 0
var _second_elapsed: float = 0.0

func _init() -> void:
	name = "AbsorberCoreEffectSystem"


func setup(new_device_layer, new_bullet_pool, new_resource_states: Dictionary, new_battlefield, new_vfx_layer = null) -> void:
	device_layer = new_device_layer
	bullet_pool = new_bullet_pool
	resource_states = new_resource_states.duplicate(false)
	battlefield = new_battlefield
	vfx_layer = new_vfx_layer
	_elapsed = 0.0
	_absorbed_this_second = 0
	_second_elapsed = 0.0
	set_process(true)


func tick(delta: float) -> void:
	var safe_delta: float = maxf(0.0, delta)
	if device_layer == null or bullet_pool == null:
		return

	_update_second_window(safe_delta)

	for owner_id in resource_states.keys():
		var devices = device_layer.get_devices_by_owner_type(int(owner_id), DeviceTypeScript.ABSORBER_CORE)
		if devices.is_empty():
			continue
		_absorb_for_owner(int(owner_id), devices)


func _update_second_window(delta: float) -> void:
	_second_elapsed += delta
	while _second_elapsed >= 1.0:
		_second_elapsed -= 1.0
		_absorbed_this_second = 0


func _absorb_for_owner(owner_id: int, devices: Array) -> void:
	var bullets = bullet_pool.get_active_bullets()
	if bullets.is_empty():
		return

	for device_instance in devices:
		if _absorbed_this_second >= MAX_PER_SECOND:
			return
		if not device_instance.active:
			continue
		var cell: Vector2i = device_instance.cell
		for bullet in bullets:
			if _absorbed_this_second >= MAX_PER_SECOND:
				return
			if not _can_absorb(bullet, owner_id):
				continue
			if not _is_in_radius(bullet, cell):
				continue
			bullet_pool.recycle_bullet(bullet)
			_absorbed_this_second += 1
			var state = resource_states.get(owner_id, null)
			if state != null:
				state.add_energy(1)
			if vfx_layer != null and is_instance_valid(vfx_layer) and vfx_layer.has_method("play_energy_ripple"):
				vfx_layer.play_energy_ripple(cell)
			break


func _can_absorb(bullet, owner_id: int) -> bool:
	if bullet == null or not is_instance_valid(bullet) or not bullet.is_active:
		return false
	return int(bullet.faction_id) != int(owner_id)


func _is_in_radius(bullet, cell: Vector2i) -> bool:
	if battlefield == null:
		return false
	var cell_size: float = float(battlefield.cell_size)
	var cell_center: Vector2 = Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * cell_size
	var bullet_pos: Vector2 = bullet.global_position
	var radius: float = float(ABSORB_RADIUS_CELLS) * cell_size
	return cell_center.distance_to(bullet_pos) <= radius


func _process(delta: float) -> void:
	_elapsed += maxf(0.0, delta)
	while _elapsed >= TICK_INTERVAL:
		_elapsed -= TICK_INTERVAL
		tick(TICK_INTERVAL)
