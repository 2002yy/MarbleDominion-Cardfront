extends RefCounted

const CardPlayResultScript = preload("res://scripts/cardfront/cards/CardPlayResult.gd")
const FortifyRulesScript = preload("res://scripts/cardfront/fortify/FortifyRules.gd")


func resolve(req, card, context: Dictionary):
	var fortify_layer = context.get("fortify_layer", null)
	if fortify_layer == null:
		return CardPlayResultScript.fail(CardPlayResultScript.REASON_MISSING_SYSTEM, card.card_name)

	var cell: Vector2i = req.target_cell
	fortify_layer.add_fortify_stack(cell, FortifyRulesScript.DEFAULT_FORTIFY_STACKS)

	var region_overlay = context.get("region_overlay", null)
	if region_overlay != null and is_instance_valid(region_overlay) and region_overlay.has_method("mark_dirty"):
		region_overlay.mark_dirty()

	return CardPlayResultScript.ok(card.card_name)
