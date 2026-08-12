extends RefCounted
class_name CardfrontDraftOfferContext

const DeckRegistryScript = preload("res://scripts/cardfront/draft/CardfrontUpgradeDeckRegistry.gd")

var owner_id: int = -1
var run_state = null
var deck_id: String = DeckRegistryScript.DEFAULT_DECK_ID


static func create(new_owner_id: int, new_run_state = null, requested_deck_id: String = ""):
	var context = new()
	context.owner_id = int(new_owner_id)
	context.run_state = new_run_state
	var resolved_deck_id: String = requested_deck_id
	if resolved_deck_id == "" and new_run_state != null:
		var state_deck_id = new_run_state.get("deck_id")
		if state_deck_id != null:
			resolved_deck_id = str(state_deck_id)
	context.deck_id = DeckRegistryScript.sanitize_deck_id(resolved_deck_id)
	return context


func snapshot() -> Dictionary:
	return {
		"owner_id": owner_id,
		"deck_id": deck_id,
	}
