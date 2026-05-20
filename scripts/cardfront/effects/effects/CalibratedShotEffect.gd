extends RefCounted

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")

const BIAS_DURATION: float = 6.0


func resolve(req, card, context: Dictionary):
	var target_bias_system = context.get("target_bias_system", null)
	if target_bias_system == null or not target_bias_system.has_method("apply_region_bias"):
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)

	var applied: bool = bool(target_bias_system.apply_region_bias(
		int(req.owner_id),
		int(req.target_region_id),
		BIAS_DURATION
	))
	if not applied:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)

	return CardPlayResultScript.ok(card.card_name)
