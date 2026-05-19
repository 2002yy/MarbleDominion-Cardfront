extends RefCounted
class_name CardCatalog

const CardDataScript = preload("res://scripts/cardfront/cards/CardData.gd")
const CardTypeScript = preload("res://scripts/cardfront/cards/CardType.gd")
const CardTargetTypeScript = preload("res://scripts/cardfront/cards/CardTargetType.gd")

const CARD_FRONTLINE_FORTIFY: int = 1001
const CARD_CALIBRATED_SHOT: int = 1002
const CARD_MORALE_FLUCTUATION: int = 1003

var catalog: Dictionary = {}


func _init() -> void:
	_register(_make_card(CARD_FRONTLINE_FORTIFY, "前线加固", CardTypeScript.FORTIFY, 10, 3, CardTargetTypeScript.OWNED_BORDER, "fortify_border"))
	_register(_make_card(CARD_CALIBRATED_SHOT, "校准射击", CardTypeScript.CALIBRATED_SHOT, 8, 5, CardTargetTypeScript.ENEMY_REGION, "calibrated_shot"))
	_register(_make_card(CARD_MORALE_FLUCTUATION, "民心起伏", CardTypeScript.MORALE_FLUCTUATION, 5, 2, CardTargetTypeScript.OWNED_REGION, "morale_fluctuation"))


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


func _register(card) -> void:
	catalog[int(card.id)] = card


func get_card(card_id: int):
	return catalog.get(int(card_id), null)


func get_default_hand_ids() -> Array[int]:
	return [CARD_FRONTLINE_FORTIFY, CARD_CALIBRATED_SHOT, CARD_MORALE_FLUCTUATION]
