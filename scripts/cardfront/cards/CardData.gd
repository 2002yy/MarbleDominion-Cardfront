extends RefCounted

var id: int = 0
var card_name: String = ""
var card_type: String = ""
var energy_cost: int = 0
var parts_cost: int = 0
var target_type: String = ""
var effect_id: String = ""

func snapshot() -> Dictionary:
	return {
		"id": id,
		"card_name": card_name,
		"card_type": card_type,
		"energy_cost": energy_cost,
		"parts_cost": parts_cost,
		"target_type": target_type,
		"effect_id": effect_id,
	}
