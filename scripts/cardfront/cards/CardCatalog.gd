extends RefCounted
class_name CardCatalog

const CardDataScript = preload("res://scripts/cardfront/cards/CardData.gd")
const CardfrontContentManifestScript = preload("res://scripts/cardfront/content/CardfrontContentManifest.gd")

const CARD_FRONTLINE_FORTIFY: int = 1001
const CARD_CALIBRATED_SHOT: int = 1002
const CARD_MORALE_FLUCTUATION: int = 1003
const CARD_PIONEER_BEACON: int = 1004

var catalog: Dictionary = {}


func _init() -> void:
	for card_id in CardfrontContentManifestScript.get_card_ids():
		_register(_make_card_from_definition(CardfrontContentManifestScript.get_card_definition(int(card_id))))


func _make_card(id: int, card_name: String, card_type: String, energy_cost: int, parts_cost: int, target_type: String, effect_id: String = ""):
	var card = CardDataScript.new()
	card.id = id
	card.card_name = str(card_name)
	card.card_type = str(card_type)
	card.energy_cost = int(energy_cost)
	card.parts_cost = int(parts_cost)
	card.target_type = str(target_type)
	card.effect_id = str(effect_id)
	return card


func _make_card_from_definition(definition: Dictionary):
	var card = _make_card(
		int(definition.get("id", 0)),
		str(definition.get("name", "")),
		str(definition.get("type", "")),
		int(definition.get("energy_cost", 0)),
		int(definition.get("parts_cost", 0)),
		str(definition.get("target_type", "")),
		str(definition.get("effect_id", ""))
	)
	card.params = (definition.get("params", {}) as Dictionary).duplicate(true)
	card.visual_id = str(definition.get("visual_id", ""))
	return card


func _register(card) -> void:
	catalog[int(card.id)] = card


func get_card(card_id: int):
	return catalog.get(int(card_id), null)


func get_default_hand_ids() -> Array[int]:
	var ids: Array[int] = []
	for card_id in CardfrontContentManifestScript.get_default_hand_ids():
		ids.append(int(card_id))
	return ids
