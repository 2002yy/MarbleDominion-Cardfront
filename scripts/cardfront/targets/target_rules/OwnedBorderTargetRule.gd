extends RefCounted
class_name OwnedBorderTargetRule

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const DeploymentRulesScript = preload("res://scripts/cardfront/deployment/DeploymentRules.gd")


func validate(req, card, context: Dictionary):
	var battlefield = context.get("battlefield", null)
	var region_map = context.get("region_map", null)
	if battlefield == null or region_map == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)
	if not DeploymentRulesScript.is_owned_border(region_map, battlefield, req.target_cell, int(req.owner_id)):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)
	return CardPlayResultScript.ok(card.card_name)
