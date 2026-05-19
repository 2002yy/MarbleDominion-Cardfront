extends RefCounted

const CardCatalogScript = preload("res://scripts/cardfront/cards/CardCatalog.gd")

var card_ids: Array[int] = []
var used_card_ids: Dictionary = {}


func initialize_fixed_hand(card_ids_list: Array) -> void:
	card_ids.clear()
	used_card_ids.clear()
	for raw_id in card_ids_list:
		var id: int = int(raw_id)
		card_ids.append(id)
		used_card_ids[id] = false


func has_card(card_id: int) -> bool:
	return int(card_id) in card_ids


func is_used(card_id: int) -> bool:
	return bool(used_card_ids.get(int(card_id), true))


func mark_used(card_id: int) -> void:
	if has_card(card_id):
		used_card_ids[int(card_id)] = true


func can_play_card(card_id: int) -> bool:
	return has_card(card_id) and not is_used(card_id)


func get_available_card_ids() -> Array[int]:
	var result: Array[int] = []
	for id in card_ids:
		if not bool(used_card_ids.get(int(id), true)):
			result.append(int(id))
	return result


func snapshot() -> Dictionary:
	var used_map: Dictionary = {}
	for id in card_ids:
		used_map[str(id)] = bool(used_card_ids.get(int(id), false))
	return {
		"card_ids": card_ids.duplicate(false),
		"used_card_ids": used_map,
	}
