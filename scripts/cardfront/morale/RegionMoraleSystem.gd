extends Node
class_name RegionMoraleSystem

signal morale_tick(region_id, changed_cell, old_owner, new_owner)
signal morale_finished(region_id, mode)

const CardfrontRulesScript = preload("res://scripts/cardfront/CardfrontRules.gd")
const RegionMoraleRulesScript = preload("res://scripts/cardfront/morale/RegionMoraleRules.gd")

var tick_interval: float = RegionMoraleRulesScript.TICK_INTERVAL
var region_map = null
var battlefield = null
var active_effects: Array = []
var _rng := RandomNumberGenerator.new()
var _elapsed: float = 0.0


func _init() -> void:
	name = "RegionMoraleSystem"
	_rng.seed = 1


func setup(new_region_map, new_battlefield) -> void:
	region_map = new_region_map
	battlefield = new_battlefield
	active_effects.clear()
	_elapsed = 0.0
	set_process(true)


func set_seed(seed_value: int) -> void:
	_rng.seed = int(seed_value)


func apply_morale(region_id: int, source_owner: int, mode: String, points: int = RegionMoraleRulesScript.DEFAULT_POINTS) -> bool:
	if region_map == null or battlefield == null:
		return false
	if not RegionMoraleRulesScript.is_valid_mode(mode):
		return false
	var safe_points: int = maxi(0, int(points))
	if safe_points <= 0:
		return false
	active_effects.append({
		"region_id": int(region_id),
		"source_owner": int(source_owner),
		"mode": mode,
		"points": safe_points,
	})
	return true


func tick_once() -> void:
	if region_map == null or battlefield == null:
		return
	if active_effects.is_empty():
		return

	var next_effects: Array = []
	for effect in active_effects:
		var region_id: int = int(effect.get("region_id", -1))
		var mode: String = str(effect.get("mode", ""))
		var remaining_points: int = int(effect.get("points", 0))
		var should_finish: bool = _apply_effect_tick(effect)
		remaining_points -= 1
		if should_finish or remaining_points <= 0:
			morale_finished.emit(region_id, mode)
		else:
			effect["points"] = remaining_points
			next_effects.append(effect)
	active_effects = next_effects


func _process(delta: float) -> void:
	if tick_interval <= 0.0:
		return
	_elapsed += maxf(0.0, delta)
	while _elapsed >= tick_interval:
		_elapsed -= tick_interval
		tick_once()


func _apply_effect_tick(effect: Dictionary) -> bool:
	var region_id: int = int(effect.get("region_id", -1))
	var source_owner: int = int(effect.get("source_owner", CardfrontRulesScript.PLAYER_FACTION))
	var mode: String = str(effect.get("mode", ""))
	match mode:
		RegionMoraleRulesScript.SUPPORT_PLAYER:
			return _apply_support_player(region_id, source_owner)
		RegionMoraleRulesScript.UNREST_ENEMY:
			return _apply_unrest_enemy(region_id)
		_:
			return true


func _apply_support_player(region_id: int, source_owner: int) -> bool:
	var neutral_cells: Array = _candidate_cells(region_id, CardfrontRulesScript.NEUTRAL_OWNER)
	if not neutral_cells.is_empty():
		_apply_owner_change(region_id, _pick_cell(neutral_cells), source_owner)
		return false

	var ai_cells: Array = _candidate_cells(region_id, CardfrontRulesScript.AI_FACTION)
	if not ai_cells.is_empty():
		_apply_owner_change(region_id, _pick_cell(ai_cells), CardfrontRulesScript.NEUTRAL_OWNER)
		return false

	return true


func _apply_unrest_enemy(region_id: int) -> bool:
	var ai_cells: Array = _candidate_cells(region_id, CardfrontRulesScript.AI_FACTION)
	if ai_cells.is_empty():
		return true
	_apply_owner_change(region_id, _pick_cell(ai_cells), CardfrontRulesScript.NEUTRAL_OWNER)
	return false


func _candidate_cells(region_id: int, owner_id: int) -> Array:
	var candidates: Array = []
	if region_map == null or not region_map.has_method("get_region_cells"):
		return candidates
	for cell in region_map.get_region_cells(region_id):
		if _owner_at(cell) == owner_id:
			candidates.append(cell)
	return candidates


func _pick_cell(candidates: Array) -> Vector2i:
	if candidates.is_empty():
		return Vector2i(-1, -1)
	var index: int = _rng.randi_range(0, candidates.size() - 1)
	return candidates[index]


func _apply_owner_change(region_id: int, cell: Vector2i, new_owner: int) -> void:
	if cell.x < 0 or cell.y < 0:
		return
	var old_owner: int = _owner_at(cell)
	if old_owner == new_owner:
		return
	if battlefield != null and battlefield.has_method("apply_bullet"):
		battlefield.apply_bullet(cell, new_owner)
		morale_tick.emit(region_id, cell, old_owner, new_owner)


func _owner_at(cell: Vector2i) -> int:
	if battlefield == null:
		return CardfrontRulesScript.NEUTRAL_OWNER
	if not battlefield.has_method("is_inside") or not battlefield.is_inside(cell):
		return CardfrontRulesScript.NEUTRAL_OWNER
	if not (battlefield.owners is Array):
		return CardfrontRulesScript.NEUTRAL_OWNER
	if cell.x < 0 or cell.y < 0 or cell.x >= battlefield.owners.size():
		return CardfrontRulesScript.NEUTRAL_OWNER
	var col = battlefield.owners[cell.x]
	if not (col is Array) or cell.y >= (col as Array).size():
		return CardfrontRulesScript.NEUTRAL_OWNER
	return int((col as Array)[cell.y])
