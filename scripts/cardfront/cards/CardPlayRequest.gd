extends RefCounted

var card_id: int = 0
var owner_id: int = 0
var target_cell: Vector2i = Vector2i.ZERO
var target_region_id: int = -1


static func make(card_id: int, owner_id: int, target_cell: Vector2i = Vector2i.ZERO, target_region_id: int = -1):
	var CardPlayRequestScript = load("res://scripts/cardfront/cards/CardPlayRequest.gd")
	var req = CardPlayRequestScript.new()
	req.card_id = int(card_id)
	req.owner_id = int(owner_id)
	req.target_cell = target_cell
	req.target_region_id = int(target_region_id)
	return req
