extends RefCounted
class_name CardfrontBattlefieldEntity

const KIND_CREATURE: String = "creature"
const KIND_DEFENSE_TOWER: String = "defense_tower"
const KIND_COMMAND_CHAMBER: String = "command_chamber"

var entity_id: String = ""
var entity_kind: String = ""
var owner_id: int = -1
var cell: Vector2i = Vector2i.ZERO
var hp: int = 1
var max_hp: int = 1
var active: bool = true
var powered: bool = true
var rounds_remaining: int = -1
var status_effects: Dictionary = {}
var metadata: Dictionary = {}


func setup(
	new_entity_id: String,
	new_entity_kind: String,
	new_owner_id: int,
	new_cell: Vector2i,
	new_max_hp: int,
	new_rounds_remaining: int = -1
) -> void:
	entity_id = str(new_entity_id)
	entity_kind = str(new_entity_kind)
	owner_id = int(new_owner_id)
	cell = new_cell
	max_hp = maxi(1, int(new_max_hp))
	hp = max_hp
	active = true
	powered = true
	rounds_remaining = int(new_rounds_remaining)
	status_effects.clear()
	metadata.clear()


func is_alive() -> bool:
	return active and hp > 0


func can_act() -> bool:
	return is_alive() and powered and get_status_rounds("stunned") <= 0 and get_status_rounds("disabled") <= 0


func apply_damage(amount: int) -> int:
	if not is_alive() or amount <= 0:
		return 0
	var before: int = hp
	hp = maxi(0, hp - maxi(0, int(amount)))
	if hp <= 0:
		active = false
	return before - hp


func heal(amount: int) -> int:
	if not active or amount <= 0:
		return 0
	var before: int = hp
	hp = mini(max_hp, hp + maxi(0, int(amount)))
	return hp - before


func add_status(status_id: String, rounds: int) -> void:
	var safe_id: String = str(status_id)
	if safe_id == "" or rounds <= 0:
		return
	status_effects[safe_id] = maxi(int(status_effects.get(safe_id, 0)), int(rounds))


func get_status_rounds(status_id: String) -> int:
	return maxi(0, int(status_effects.get(str(status_id), 0)))


func clear_status(status_id: String) -> void:
	status_effects.erase(str(status_id))


func tick_round() -> void:
	var expired: Array = []
	for status_id in status_effects.keys():
		var remaining: int = maxi(0, int(status_effects[status_id]) - 1)
		if remaining <= 0:
			expired.append(status_id)
		else:
			status_effects[status_id] = remaining
	for status_id in expired:
		status_effects.erase(status_id)
	if rounds_remaining > 0:
		rounds_remaining -= 1
		if rounds_remaining <= 0:
			active = false


func collision_priority() -> int:
	match entity_kind:
		KIND_CREATURE:
			return 10
		KIND_DEFENSE_TOWER:
			return 20
		KIND_COMMAND_CHAMBER:
			return 30
		_:
			return 100


func snapshot() -> Dictionary:
	return {
		"entity_id": entity_id,
		"entity_kind": entity_kind,
		"owner_id": owner_id,
		"cell": cell,
		"hp": hp,
		"max_hp": max_hp,
		"active": active,
		"powered": powered,
		"rounds_remaining": rounds_remaining,
		"status_effects": status_effects.duplicate(true),
		"metadata": metadata.duplicate(true),
	}
