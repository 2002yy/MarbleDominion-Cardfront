extends RefCounted

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const RegionMoraleRulesScript = preload("res://scripts/cardfront/morale/RegionMoraleRules.gd")


func resolve(req, card, context: Dictionary):
	var morale_system = context.get("morale_system", null)
	if morale_system == null or not morale_system.has_method("apply_morale"):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)

	var applied: bool = bool(morale_system.apply_morale(
		int(req.target_region_id),
		int(req.owner_id),
		RegionMoraleRulesScript.SUPPORT_PLAYER
	))
	if not applied:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)

	return CardPlayResultScript.ok(card.card_name)
