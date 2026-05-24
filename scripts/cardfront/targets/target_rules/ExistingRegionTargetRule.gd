extends RefCounted
class_name ExistingRegionTargetRule

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")


func validate(req, card, context: Dictionary):
	if int(req.target_region_id) < 0:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)
	var region_map = context.get("region_map", null)
	if region_map == null or not region_map.has_method("get_region_cells"):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)
	if region_map.get_region_cells(int(req.target_region_id)).is_empty():
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)
	return CardPlayResultScript.ok(card.card_name)
