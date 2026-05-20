extends RefCounted

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const PioneerBeaconLiteEffectHelperScript = preload("res://scripts/cardfront/effects/PioneerBeaconLiteEffect.gd")


func resolve(req, card, context: Dictionary):
	var region_map = context.get("region_map", null)
	var battlefield = context.get("battlefield", null)
	var effect_result: Dictionary = PioneerBeaconLiteEffectHelperScript.apply(region_map, battlefield, int(req.owner_id), req.target_cell)
	if not bool(effect_result.get("success", false)):
		var reason: String = str(effect_result.get("reason", PioneerBeaconLiteEffectHelperScript.REASON_INVALID_TARGET))
		if reason == PioneerBeaconLiteEffectHelperScript.REASON_MISSING_SYSTEM:
			return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_INVALID_TARGET, card.card_name)

	var region_overlay = context.get("region_overlay", null)
	if region_overlay != null and is_instance_valid(region_overlay) and region_overlay.has_method("mark_dirty"):
		region_overlay.mark_dirty()

	return CardPlayResultScript.ok(card.card_name)
