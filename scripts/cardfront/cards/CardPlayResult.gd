extends RefCounted

var success: bool = false
var reason: String = ""
var card_name: String = ""
var consumed_energy: int = 0
var consumed_parts: int = 0


const REASON_SUCCESS: String = "success"
const REASON_UNKNOWN_CARD: String = "unknown_card"
const REASON_INSUFFICIENT_RESOURCES: String = "insufficient_resources"
const REASON_INVALID_TARGET: String = "invalid_target"
const REASON_MISSING_SYSTEM: String = "missing_system"
const REASON_STUB: String = "stub"
const REASON_CARD_ALREADY_USED: String = "card_already_used"


static func ok(card_name: String, energy: int = 0, parts: int = 0):
	var CardPlayResultScript = load("res://scripts/cardfront/cards/CardPlayResult.gd")
	var r = CardPlayResultScript.new()
	r.success = true
	r.reason = REASON_SUCCESS
	r.card_name = str(card_name)
	r.consumed_energy = int(energy)
	r.consumed_parts = int(parts)
	return r


static func fail(reason: String, card_name: String = ""):
	var CardPlayResultScript = load("res://scripts/cardfront/cards/CardPlayResult.gd")
	var r = CardPlayResultScript.new()
	r.success = false
	r.reason = str(reason)
	r.card_name = str(card_name)
	return r
