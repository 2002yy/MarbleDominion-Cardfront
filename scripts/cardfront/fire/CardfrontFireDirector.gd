extends Node
class_name CardfrontFireDirector

signal fire_tick(owner_id, intent)
signal fire_requested(owner_id, intent)
signal fire_issued(owner_id, intent)
signal fire_skipped(owner_id, reason)

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const FireRulesScript = preload("res://scripts/cardfront/fire/CardfrontFireRules.gd")
const FireIntentScript = preload("res://scripts/cardfront/fire/CardfrontFireIntent.gd")
const TargetScorerScript = preload("res://scripts/cardfront/fire/CardfrontTargetScorer.gd")

var region_map = null
var battlefield = null
var turrets: Dictionary = {}
var target_bias_system = null
var active_factions: Array = []

var shot_interval: float = FireRulesScript.BASE_SHOT_INTERVAL
var base_shot_count: int = FireRulesScript.BASE_SHOT_COUNT
var max_total_shots_per_second: int = FireRulesScript.MAX_TOTAL_SHOTS_PER_SECOND
var max_owner_shots_per_second: int = FireRulesScript.MAX_OWNER_SHOTS_PER_SECOND
var base_spread: float = FireRulesScript.BASE_SPREAD_RADIANS

var _owner_timers: Dictionary = {}
var _shot_window_elapsed: float = 0.0
var _total_shots_in_window: int = 0
var _owner_shots_in_window: Dictionary = {}
var _last_intents: Dictionary = {}


func _init() -> void:
	name = "CardfrontFireDirector"


func setup(new_region_map, new_battlefield, new_turrets: Dictionary, new_target_bias_system = null, new_active_factions: Array = []) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	turrets = new_turrets.duplicate(false)
	target_bias_system = new_target_bias_system
	active_factions = new_active_factions.duplicate(false)
	if active_factions.is_empty():
		active_factions = CardfrontRulesScript.get_duel_factions()
	_owner_timers.clear()
	_owner_shots_in_window.clear()
	for owner_id in active_factions:
		var safe_owner_id: int = int(owner_id)
		_owner_timers[safe_owner_id] = 0.0
		_owner_shots_in_window[safe_owner_id] = 0
	_shot_window_elapsed = 0.0
	_total_shots_in_window = 0
	_last_intents.clear()
	set_process(true)


func tick(delta: float) -> Array:
	var issued: Array = []
	_advance_shot_window(delta)
	if region_map == null or battlefield == null:
		return issued

	for owner_id in active_factions:
		var safe_owner_id: int = int(owner_id)
		var timer: float = maxf(0.0, float(_owner_timers.get(safe_owner_id, 0.0)) - maxf(0.0, delta))
		if timer > 0.0:
			_owner_timers[safe_owner_id] = timer
			continue

		var remaining_budget: int = _remaining_shot_budget(safe_owner_id)
		if remaining_budget <= 0:
			_owner_timers[safe_owner_id] = 0.0
			fire_skipped.emit(safe_owner_id, "budget_exceeded")
			continue

		var intent = build_intent(safe_owner_id, mini(maxi(1, int(base_shot_count)), remaining_budget))
		if intent == null:
			_owner_timers[safe_owner_id] = maxf(0.0, float(shot_interval))
			fire_skipped.emit(safe_owner_id, "no_target")
			continue

		fire_tick.emit(safe_owner_id, intent)
		fire_requested.emit(safe_owner_id, intent)

		if _request_fire(safe_owner_id, intent):
			issued.append(intent)
			_last_intents[safe_owner_id] = intent
			_total_shots_in_window += int(intent.shot_count)
			_owner_shots_in_window[safe_owner_id] = int(_owner_shots_in_window.get(safe_owner_id, 0)) + int(intent.shot_count)
			_owner_timers[safe_owner_id] = maxf(0.0, float(shot_interval))
			fire_issued.emit(safe_owner_id, intent)
		else:
			_owner_timers[safe_owner_id] = 0.1
			fire_skipped.emit(safe_owner_id, "turret_unavailable")

	return issued


func build_intent(owner_id: int, shot_count: int = -1):
	var target: Dictionary = _select_target(owner_id)
	if not bool(target.get("success", false)):
		return null

	var intent = FireIntentScript.new()
	intent.owner_id = int(owner_id)
	intent.target_region_id = int(target.get("target_region_id", -1))
	intent.target_cell = target.get("target_cell", Vector2i(-1, -1))
	intent.shot_count = clampi(int(shot_count if shot_count > 0 else base_shot_count), 1, _max_intent_shots())
	intent.spread = maxf(0.0, float(base_spread))
	intent.reason = str(target.get("reason", FireRulesScript.REASON_BASE))
	intent.angle = _angle_to_cell(owner_id, intent.target_cell)
	return intent


func get_last_intent(owner_id: int):
	return _last_intents.get(int(owner_id), null)


func _process(delta: float) -> void:
	tick(delta)


func _select_target(owner_id: int) -> Dictionary:
	var biased_region_id: int = -1
	if target_bias_system != null and is_instance_valid(target_bias_system) and target_bias_system.has_method("get_biased_region"):
		biased_region_id = int(target_bias_system.get_biased_region(owner_id))
	if biased_region_id >= 0:
		var biased_target: Dictionary = TargetScorerScript.select_region_target(region_map, battlefield, owner_id, biased_region_id, FireRulesScript.REASON_TARGET_BIAS)
		if bool(biased_target.get("success", false)):
			return biased_target
	return TargetScorerScript.select_base_target(region_map, battlefield, owner_id)


func _request_fire(owner_id: int, intent) -> bool:
	var turret = turrets.get(int(owner_id), null)
	if turret == null:
		return false
	if turret.get("is_destroyed") == true:
		return false
	if turret.has_method("request_directed_burst"):
		return bool(turret.request_directed_burst(intent))
	if turret.has_method("fire_directed"):
		return bool(turret.fire_directed(int(intent.shot_count), float(intent.angle), float(intent.spread)))
	return false


func _remaining_shot_budget(owner_id: int) -> int:
	var total_budget: int = maxi(0, int(max_total_shots_per_second) - _total_shots_in_window)
	var owner_budget: int = maxi(0, int(max_owner_shots_per_second) - int(_owner_shots_in_window.get(int(owner_id), 0)))
	return mini(total_budget, owner_budget)


func _max_intent_shots() -> int:
	return maxi(1, mini(maxi(1, int(max_total_shots_per_second)), maxi(1, int(max_owner_shots_per_second))))


func _angle_to_cell(owner_id: int, cell: Vector2i) -> float:
	var turret = turrets.get(int(owner_id), null)
	if turret == null:
		return 0.0
	var target_world: Vector2 = _cell_world_center(cell)
	var origin: Vector2 = turret.get("global_position") if turret is Object else Vector2.ZERO
	if target_world == origin:
		return float(turret.get("rotation")) if turret is Object else 0.0
	return (target_world - origin).angle()


func _cell_world_center(cell: Vector2i) -> Vector2:
	if battlefield == null:
		return Vector2.ZERO
	var cell_size: float = float(battlefield.get("cell_size"))
	var battlefield_position: Vector2 = battlefield.get("global_position") if battlefield is Object else Vector2.ZERO
	return battlefield_position + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * cell_size


func _advance_shot_window(delta: float) -> void:
	_shot_window_elapsed += maxf(0.0, delta)
	while _shot_window_elapsed >= 1.0:
		_shot_window_elapsed -= 1.0
		_total_shots_in_window = 0
		_owner_shots_in_window.clear()
		for owner_id in active_factions:
			_owner_shots_in_window[int(owner_id)] = 0
