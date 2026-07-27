extends "res://scripts/cardfront/entities/CardfrontBattlefieldEntity.gd"
class_name CardfrontCreatureState

const ARMOR_NORMAL: String = "normal"
const ARMOR_ARMORED: String = "armored"

var creature_id: String = ""
var armor_type: String = ARMOR_NORMAL
var movement: int = 1
var behavior_type: String = "hold_frontline"
var size_slots: int = 1


func setup_creature(
	new_entity_id: String,
	new_creature_id: String,
	new_owner_id: int,
	new_cell: Vector2i,
	new_max_hp: int,
	new_armor_type: String = ARMOR_NORMAL,
	new_movement: int = 1,
	new_behavior_type: String = "hold_frontline",
	new_rounds_remaining: int = -1
) -> void:
	setup(
		new_entity_id,
		KIND_CREATURE,
		new_owner_id,
		new_cell,
		new_max_hp,
		new_rounds_remaining
	)
	creature_id = str(new_creature_id)
	armor_type = ARMOR_ARMORED if str(new_armor_type) == ARMOR_ARMORED else ARMOR_NORMAL
	movement = maxi(0, int(new_movement))
	behavior_type = str(new_behavior_type)
	size_slots = 1


func is_armored() -> bool:
	return armor_type == ARMOR_ARMORED


func snapshot() -> Dictionary:
	var result: Dictionary = super.snapshot()
	result["creature_id"] = creature_id
	result["armor_type"] = armor_type
	result["movement"] = movement
	result["behavior_type"] = behavior_type
	result["size_slots"] = size_slots
	return result
