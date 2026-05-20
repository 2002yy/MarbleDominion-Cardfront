extends RefCounted

var card_id: int = 0
var owner_id: int = 0
var target_cell: Vector2i = Vector2i.ZERO
var target_region_id: int = -1


static func make(p_card_id: int, p_owner_id: int, p_target_cell: Vector2i = Vector2i.ZERO, p_target_region_id: int = -1):
	var CardPlayRequestScript = load("res://scripts/cardfront/cards/CardPlayRequest.gd")
	var req = CardPlayRequestScript.new()
	req.card_id = int(p_card_id)
	req.owner_id = int(p_owner_id)
	req.target_cell = p_target_cell
	req.target_region_id = int(p_target_region_id)
	return req
