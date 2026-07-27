extends "res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd"
class_name CardfrontDefenseTowerState

var tower_id: String = ""
var building_slot_id: String = ""
var intercept_capacity: int = 0
var intercepts_remaining: int = 0
var summon_creature_id: String = ""
var summon_interval_rounds: int = 0
var summon_cooldown_rounds: int = 0
var guidance_capacity: int = 0
var guidance_remaining: int = 0
var guidance_lane_center_ratio: float = 0.5
var guidance_strength: float = 0.0
var guidance_radius_cells: int = 0
var tower_level: int = 1


func setup_tower(
	new_entity_id: String,
	new_tower_id: String,
	new_owner_id: int,
	new_cell: Vector2i,
	new_max_hp: int,
	new_building_slot_id: String
) -> void:
	setup(
		new_entity_id,
		KIND_DEFENSE_TOWER,
		new_owner_id,
		new_cell,
		new_max_hp,
		-1
	)
	tower_id = str(new_tower_id)
	building_slot_id = str(new_building_slot_id)
	intercept_capacity = 0
	intercepts_remaining = 0
	summon_creature_id = ""
	summon_interval_rounds = 0
	summon_cooldown_rounds = 0
	guidance_capacity = 0
	guidance_remaining = 0
	guidance_lane_center_ratio = 0.5
	guidance_strength = 0.0
	guidance_radius_cells = 0
	tower_level = 1


func configure_interceptor(capacity: int) -> void:
	intercept_capacity = maxi(0, int(capacity))
	intercepts_remaining = intercept_capacity


func configure_summoner(creature_id: String, interval_rounds: int) -> void:
	summon_creature_id = str(creature_id)
	summon_interval_rounds = maxi(0, int(interval_rounds))
	summon_cooldown_rounds = summon_interval_rounds


func configure_guidance(
	capacity: int,
	lane_center_ratio: float,
	strength: float = 0.35,
	radius_cells: int = 3
) -> void:
	guidance_capacity = maxi(0, int(capacity))
	guidance_remaining = guidance_capacity
	guidance_lane_center_ratio = clampf(float(lane_center_ratio), 0.0, 1.0)
	guidance_strength = clampf(float(strength), 0.0, 1.0)
	guidance_radius_cells = maxi(0, int(radius_cells))


func set_tower_level(level: int) -> void:
	tower_level = clampi(int(level), 1, 3)


func can_intercept() -> bool:
	return can_act() and intercepts_remaining > 0


func consume_intercept() -> bool:
	if not can_intercept():
		return false
	intercepts_remaining -= 1
	return true


func can_guide() -> bool:
	return can_act() and guidance_remaining > 0 and guidance_radius_cells > 0 and guidance_strength > 0.0


func consume_guidance() -> bool:
	if not can_guide():
		return false
	guidance_remaining -= 1
	return true


func should_summon() -> bool:
	return can_act() and summon_creature_id != "" and summon_interval_rounds > 0 and summon_cooldown_rounds <= 0


func acknowledge_summon() -> void:
	summon_cooldown_rounds = summon_interval_rounds


func begin_volley() -> void:
	intercepts_remaining = intercept_capacity if can_act() else 0
	guidance_remaining = guidance_capacity if can_act() else 0


func tick_round() -> void:
	super.tick_round()
	if summon_cooldown_rounds > 0:
		summon_cooldown_rounds -= 1


func snapshot() -> Dictionary:
	var result: Dictionary = super.snapshot()
	result["tower_id"] = tower_id
	result["building_slot_id"] = building_slot_id
	result["intercept_capacity"] = intercept_capacity
	result["intercepts_remaining"] = intercepts_remaining
	result["summon_creature_id"] = summon_creature_id
	result["summon_interval_rounds"] = summon_interval_rounds
	result["summon_cooldown_rounds"] = summon_cooldown_rounds
	result["guidance_capacity"] = guidance_capacity
	result["guidance_remaining"] = guidance_remaining
	result["guidance_lane_center_ratio"] = guidance_lane_center_ratio
	result["guidance_strength"] = guidance_strength
	result["guidance_radius_cells"] = guidance_radius_cells
	result["tower_level"] = tower_level
	return result
